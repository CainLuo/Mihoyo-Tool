# 设计文档：API 日志收集系统（api-log-system）

## 概述

为 HarmonyOS NEXT 米游社工具箱新增 API 日志收集系统，专门收集 API 请求/响应及业务层错误等运行时事件，将日志完整持久化到本地 NDJSON 文件，并提供导出、清理等管理能力。

系统在现有 `Logger`（hilog 封装）基础上扩展，两者并行工作、互不干扰：`Logger` 继续输出到 hilog 控制台，`ApiLogSystem` 负责持久化到文件。日志完整记录所有信息，不做任何脱敏处理。

### 设计目标

- **零侵入**：HttpClient 和 Repository 层通过最小改动接入，不破坏现有业务逻辑
- **高可靠**：日志写入失败不影响主业务流程，初始化前的日志缓存到内存队列
- **完整记录**：所有信息原样写入，包括 Cookie、Token 等，方便完整复现问题
- **可调试**：NDJSON 格式支持命令行工具直接分析，导出后在电脑上分析

---

## 架构

### 模块分层

```
entry 模块
└── components/my/AboutSection.ets   ← 新增「导出日志」「清理缓存」Cell

core 模块
├── log/
│   ├── ApiLogSystem.ets             ← 单例入口，对外暴露 log() 方法
│   ├── ApiLogEntry.ets              ← 数据模型（LogLevel、LogEventType、ApiLogEntry）
│   ├── LogFileManager.ets           ← 文件管理（创建/轮转/大小/清理）
│   └── LogExporter.ets              ← 导出逻辑（ZIP 打包 + DocumentViewPicker）
└── network/HttpClient.ets           ← 注入日志采集点（改动最小）
```

### 数据流

```
HttpClient / Repository
        │ log(entry)
        ▼
ApiLogSystem.getInstance()
        │
        ├─ 未初始化 → 缓存到 pendingQueue[]
        │
        └─ 已初始化 → LogFileManager.append(entry)
                              │
                              ├─ 当前文件 < 5MB → 追加写入
                              └─ 当前文件 ≥ 5MB → 轮转新文件后写入
```

### 初始化时序

```
EntryAbility.onCreate()
    └─ CoreInitializer.initCore()
            ├─ AppEnvManager.setup(env)
            ├─ RdbManager.init()
            └─ ApiLogSystem.init(context)   ← 新增，在 DB 初始化之后
                    └─ LogFileManager.init()
                            └─ 刷新 pendingQueue → 批量写入文件
```

---

## 组件与接口

### ApiLogEntry（数据模型）

```typescript
// core/src/main/ets/log/ApiLogEntry.ets

export enum LogLevel {
  DEBUG = "DEBUG",
  INFO = "INFO",
  WARNING = "WARNING",
  ERROR = "ERROR",
}

export enum LogEventType {
  API_REQUEST = "API_REQUEST",
  API_RESPONSE = "API_RESPONSE",
  API_ERROR = "API_ERROR",
  LIFECYCLE = "LIFECYCLE",
  GENERAL = "GENERAL",
}

export class ApiLogEntry {
  id: number = 0;
  timestamp: number = Date.now();
  level: LogLevel = LogLevel.DEBUG;
  eventType: LogEventType = LogEventType.GENERAL;
  tag: string = "";
  message: string = "";
  extraJson: string = "";
}
```

**设计决策**：`id` 由 `LogFileManager` 在写入时赋值（同一文件内自增），不在构造时赋值，避免内存队列中的 id 与文件内 id 冲突。

### Sanitizer（脱敏处理器）

```typescript
// core/src/main/ets/log/Sanitizer.ets

export class Sanitizer {
  /**
   * 对日志字符串执行脱敏。
   * 纯函数，无副作用，可独立单元测试。
   * 幂等：sanitize(sanitize(s)) === sanitize(s)
   */
  static sanitize(input: string): string { ... }

  /** 对请求头 Map 执行脱敏，返回新 Map */
  static sanitizeHeaders(headers: Map<string, string>): Map<string, string> { ... }

  /** 对响应体 JSON 字符串执行脱敏 */
  static sanitizeResponseBody(body: string): string { ... }
}
```

**脱敏规则**：

- Cookie 请求头：将每个 `key=value` 中的 value 替换为 `***`，保留 key
- 特定键名（`stoken`、`ltoken`、`cookie_token`）：值替换为 `***`
- `account_id`：保留前 3 位，其余替换为 `***`（如 `123***`）
- 响应体 JSON 中的 `cookie`、`stoken`、`ltoken`、`cookie_token` 字段值替换为 `***`
- 异常时返回 `[sanitize_error]`，不抛出异常

### ApiLogSystem（单例入口）

```typescript
// core/src/main/ets/log/ApiLogSystem.ets

export class ApiLogSystem {
  private static instance: ApiLogSystem | null = null;
  private initialized: boolean = false;
  private pendingQueue: ApiLogEntry[] = [];

  static getInstance(): ApiLogSystem { ... }

  /** 由 CoreInitializer 调用，完成文件系统初始化并刷新队列 */
  async init(context: common.UIAbilityContext): Promise<void> { ... }

  /** 写入一条日志（线程安全，初始化前缓存） */
  log(entry: ApiLogEntry): void { ... }

  /** 便捷方法 */
  debug(tag: string, message: string, eventType?: LogEventType, extraJson?: string): void { ... }
  info(tag: string, message: string, eventType?: LogEventType, extraJson?: string): void { ... }
  warning(tag: string, message: string, eventType?: LogEventType, extraJson?: string): void { ... }
  error(tag: string, message: string, eventType?: LogEventType, extraJson?: string): void { ... }
}
```

### LogFileManager（文件管理器）

```typescript
// core/src/main/ets/log/LogFileManager.ets

export interface IFileSystem {
  appendLine(filePath: string, line: string): Promise<void>;
  getFileSize(filePath: string): Promise<number>;
  listFiles(dirPath: string): Promise<string[]>;
  deleteFile(filePath: string): Promise<void>;
  getTotalSize(dirPath: string): Promise<number>;
}

export class LogFileManager {
  static readonly MAX_FILE_SIZE_BYTES: number = 5 * 1024 * 1024; // 5MB
  static readonly LOG_DIR: string = 'files/logs';
  static readonly FILE_PREFIX: string = 'api_log_';

  constructor(private fs: IFileSystem) {}

  async init(context: common.UIAbilityContext): Promise<void> { ... }
  async append(entry: ApiLogEntry): Promise<void> { ... }
  async getTotalLogSize(): Promise<number> { ... }
  async deleteAllLogs(): Promise<DeleteResult> { ... }
  async listLogFiles(): Promise<string[]> { ... }

  /** 格式化字节数为人类可读字符串（纯函数，可独立测试） */
  static formatSize(bytes: number): string { ... }

  /** 获取当前日期对应的日志文件名（纯函数） */
  static getCurrentFileName(): string { ... }
}

export interface DeleteResult {
  deletedCount: number;
  failedCount: number;
  freedBytes: number;
}
```

**文件路径规则**：`{context.filesDir}/logs/api_log_YYYY-MM-DD.txt`

> **权限说明**：日志文件写入应用沙箱目录（`context.filesDir`），属于应用私有存储，**无需任何用户权限**，不需要在 `module.json5` 中声明权限。导出时通过 `DocumentViewPicker.save()` 由用户主动选择保存位置，系统通过 Picker 授权，同样无需额外权限声明。

**轮转规则**：写入前检查当前文件大小，若 ≥ 5MB 则创建新文件（文件名追加 `_2`、`_3` 等后缀）。

### LogExporter（导出器）

```typescript
// core/src/main/ets/log/LogExporter.ets

export class LogExporter {
  /**
   * 将所有日志文件打包为 ZIP，通过 DocumentViewPicker.save() 让用户选择保存位置。
   * 导出文件名格式：mihoyo_tool_log_<version>_<timestamp>.zip
   */
  static async export(context: common.UIAbilityContext): Promise<void> { ... }
}
```

**导出流程**：

1. 获取所有日志文件列表
2. 使用 `@kit.CoreFileKit` 的 `zlib` 打包为 ZIP，临时存放在 `cache/` 目录
3. 调用 `DocumentViewPicker.save()` 弹出系统文件管理器
4. 用户确认后写入目标位置，删除临时 ZIP
5. 任何步骤失败：通过 `HdsSnackBar` 提示错误，清理临时文件

### HttpClient 改动（最小侵入）

在 `HttpClient.get()` 和 `HttpClient.post()` 中注入日志采集：

```typescript
// 请求前
ApiLogSystem.getInstance().debug(
  "HttpClient",
  `${method} ${url}`,
  LogEventType.API_REQUEST,
  JSON.stringify({
    method,
    headers: Object.fromEntries(headers), // 完整记录，含 Cookie 明文
    bodySize,
  }),
);

// 响应后（成功）
ApiLogSystem.getInstance().debug(
  "HttpClient",
  `${method} ${url} → ${statusCode} (${durationMs}ms)`,
  LogEventType.API_RESPONSE,
  JSON.stringify({
    statusCode,
    durationMs,
    bodyPreview: body.substring(0, 500), // 完整记录响应体前 500 字符
  }),
);

// 业务错误（retcode ≠ 0）
ApiLogSystem.getInstance().warning(
  "HttpClient",
  `${method} ${url} → retcode=${retcode}: ${message}`,
  LogEventType.API_ERROR,
  JSON.stringify({ retcode, message }),
);

// 网络异常
ApiLogSystem.getInstance().error(
  "HttpClient",
  `${method} ${url} → ${errorType}: ${errorMessage}`,
  LogEventType.API_ERROR,
  JSON.stringify({ errorType, errorMessage }),
);
```

### LogViewModel（entry 层）

entry 层不需要 LogViewModel，只需在 `AboutSection.ets` 里直接调用 `LogExporter` 和 `LogFileManager` 的方法，通过 `@Local` 状态持有日志大小字符串即可。

---

## 数据模型

### ApiLogEntry 字段说明

| 字段        | 类型           | 默认值       | 说明                                                           |
| ----------- | -------------- | ------------ | -------------------------------------------------------------- |
| `id`        | `number`       | `0`          | 同一文件内自增整数，由 LogFileManager 写入时赋值               |
| `timestamp` | `number`       | `Date.now()` | Unix 毫秒时间戳，构造时自动设置                                |
| `level`     | `LogLevel`     | `DEBUG`      | 日志级别枚举                                                   |
| `eventType` | `LogEventType` | `GENERAL`    | 事件类型枚举                                                   |
| `tag`       | `string`       | `''`         | 调用方标识，由代码手动传入（如 `HttpClient`、`BBSRepository`） |
| `message`   | `string`       | `''`         | 日志主体描述                                                   |
| `extraJson` | `string`       | `''`         | 附加结构化数据（JSON 字符串），无附加数据时为空字符串          |

### 日志文件格式（NDJSON）

每个日志文件是纯文本，每行一条 JSON，按时间顺序追加：

```
{"id":1,"timestamp":1744700400100,"level":"DEBUG","eventType":"LIFECYCLE","tag":"CoreInitializer","message":"initCore started, env=DEBUG","extraJson":""}
{"id":2,"timestamp":1744700400200,"level":"DEBUG","eventType":"API_REQUEST","tag":"HttpClient","message":"POST https://api-takumi.mihoyo.com/auth/api/webLoginByMobile","extraJson":"{\"headers\":{\"Cookie\":\"account_id=123***\"}}"}
```

### 文件命名规则

- 主文件：`api_log_YYYY-MM-DD.txt`
- 轮转文件：`api_log_YYYY-MM-DD_2.txt`、`api_log_YYYY-MM-DD_3.txt`……
- 导出 ZIP：`mihoyo_tool_log_<version>_<timestamp>.zip`

### 大小格式化规则

| 条件              | 格式      | 示例       |
| ----------------- | --------- | ---------- |
| bytes < 1MB       | `X.X KB`  | `512.0 KB` |
| 1MB ≤ bytes < 1GB | `X.X MB`  | `3.2 MB`   |
| bytes ≥ 1GB       | `X.XX GB` | `1.25 GB`  |
| bytes = 0         | `0 KB`    | `0 KB`     |

---

## 正确性属性

_属性（Property）是在系统所有有效执行中都应成立的特征或行为——本质上是关于系统应做什么的形式化陈述。_

### 属性 1：ApiLogEntry 序列化往返一致性

*对任意*有效的 `ApiLogEntry` 对象 `entry`，`JSON.parse(JSON.stringify(entry))` 产生的对象的所有字段值（`id`、`timestamp`、`level`、`eventType`、`tag`、`message`、`extraJson`）SHALL 与原始 `entry` 相同。

**验证：需求 1.1、4.7、8.1**

### 属性 2：日志大小格式化正确性

*对任意*非负整数字节数 `bytes`，`LogFileManager.formatSize(bytes)` SHALL 满足：

- `bytes < 1024 * 1024` 时，结果以 `KB` 结尾，数值为 `bytes / 1024` 保留一位小数
- `1024 * 1024 ≤ bytes < 1024 * 1024 * 1024` 时，结果以 `MB` 结尾，数值为 `bytes / (1024 * 1024)` 保留一位小数
- `bytes ≥ 1024 * 1024 * 1024` 时，结果以 `GB` 结尾，数值为 `bytes / (1024 * 1024 * 1024)` 保留两位小数

**验证：需求 6.1、8.3**

---

## 错误处理

### 日志写入失败

- 磁盘满、权限不足等 I/O 错误：记录到 hilog 控制台（`Logger.error`），跳过本次写入，**不影响主业务流程**
- 脱敏异常：`Sanitizer` 返回 `[sanitize_error]`，日志仍然写入（含脱敏错误标记）

### 导出失败

- ZIP 打包失败：通过 `HdsSnackBar` 展示错误提示，清理临时文件
- `DocumentViewPicker` 用户取消：静默处理，清理临时文件
- 写入目标位置失败：通过 `HdsSnackBar` 展示错误提示，清理临时文件

### 清理失败

- 单个文件删除失败：继续删除其余文件，完成后汇总报告失败数量
- 通过 `HdsSnackBar` 展示"已释放 X MB，X 个文件删除失败"

### 初始化前的日志

- `ApiLogSystem.getInstance()` 在初始化完成前被调用：日志条目缓存到 `pendingQueue[]`
- 初始化完成后：批量将 `pendingQueue` 中的条目写入文件，清空队列

### 环境差异处理

| 环境    | 日志级别过滤 | LogViewer 入口 | 说明                                  |
| ------- | ------------ | -------------- | ------------------------------------- |
| MOCK    | DEBUG 及以上 | 可见           | 本地 Mock 数据调试                    |
| DEBUG   | DEBUG 及以上 | 可见           | 真实 API 抓包调试                     |
| RELEASE | DEBUG 及以上 | 默认隐藏       | 连续点击版本号 5 次可通过隐藏入口访问 |

---

## 测试策略

### 单元测试（core/src/test/）

纯函数逻辑，不依赖设备，放 `core/src/test/`：

**ApiLogEntry.test.ets**

- 属性 1：序列化往返一致性（生成随机 ApiLogEntry，验证 JSON round-trip）
- Example：枚举值与字符串一一对应（LogLevel 4 个值、LogEventType 5 个值）
- Example：默认 timestamp 在合理范围内，extraJson 默认为空字符串

**LogFileManager.test.ets**（纯函数部分）

- 属性 2：formatSize 格式化正确性（生成随机字节数，验证格式规则）
- Example：formatSize(0) === '0 KB'
- Example：getCurrentFileName() 返回今日日期格式

### 设备端测试（core/src/ohosTest/）

需要真实文件系统：

**ApiLogSystem.test.ets**

- Integration：写入日志后文件存在且内容正确（NDJSON 格式）
- Integration：文件超过 5MB 后自动轮转创建新文件
- Integration：初始化前写入的日志在初始化后批量写入文件
- Integration：HttpClient 发起请求后 ApiLogSystem 收到 API_REQUEST 日志（含完整请求头）

**LogFileManager.test.ets**（设备端）

- Integration：deleteAllLogs 删除所有文件，getTotalLogSize 返回 0
- Integration：多文件场景下 getTotalLogSize 正确累加

### UI 测试（entry/src/ohosTest/）

- AboutSection：「导出日志」和「清理缓存」Cell 可见，大小显示正确
- 清理确认对话框：点击取消不执行删除，点击确认后大小更新为 `0 KB`

### 测试文件注册

新增到 `core/src/test/List.test.ets`：

```typescript
import apiLogEntryTest from "./ApiLogEntry.test";
import logFileManagerTest from "./LogFileManager.test";
```
