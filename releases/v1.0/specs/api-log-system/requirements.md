# 需求文档

## 简介

为 HarmonyOS NEXT 米游社工具箱（Mihoyo-Tool）新增 API 日志收集系统（api-log-system）。

该系统专门收集 API 请求、响应及业务层错误等运行时事件，将日志完整持久化到本地文件，并提供导出、清理等管理能力，方便开发者调试和排查问题。

系统在现有 `Logger` 工具类（hilog 封装）的基础上扩展，不破坏现有日志输出行为。日志完整记录所有信息，不做任何脱敏处理。

---

## 与 AGC APMS 异常管理的关系

> **重要备忘**：华为 AppGallery Connect 提供了官方的线上崩溃分析平台 **APMS（性能监测）异常管理**，是 HarmonyOS NEXT 版的 Bugly 替代方案。
>
> 文档地址：https://developer.huawei.com/consumer/cn/doc/app/agc-help-apms-crash-0000002236333918
>
> **APMS 的工作方式**：无需在应用代码中集成任何 SDK，系统层面自动采集崩溃数据（CPP CRASH、JS ERROR、OOM、PROCESS KILL、APP FREEZE、RESOURCE LEAK 六类），应用上架华为应用市场后，崩溃数据自动上报到 AGC 后台，开发者在控制台查看。
>
> **本系统（ApiLogSystem）与 APMS 的定位不同，两者互补：**
>
> | 能力                              | APMS 异常管理                        | ApiLogSystem（本系统） |
> | --------------------------------- | ------------------------------------ | ---------------------- |
> | Crash 捕获                        | 系统自动，无需代码，**由 APMS 负责** | 不负责                 |
> | 数据位置                          | AGC 云端后台                         | 本地文件               |
> | API 请求/响应日志                 | 不支持                               | 支持                   |
> | 业务层错误（AuthExpiredError 等） | 不支持                               | 支持                   |
> | 适用场景                          | 线上用户崩溃统计                     | 开发调试、API 问题排查 |
> | 需要上架应用市场                  | 是                                   | 否                     |
>
> **结论**：Crash 收集完全交给 APMS，本系统只负责 API 请求/响应和业务层错误日志。应用上架后启用 APMS（零成本，系统自动），两者不重叠。

---

## 词汇表

- **ApiLogSystem**：本功能的日志收集系统，负责持久化日志条目的写入和管理。
- **ApiLogEntry**：单条日志记录，包含时间戳、日志级别、事件类型、标签、消息体等字段。
- **LogLevel**：日志级别枚举，包含 DEBUG、INFO、WARNING、ERROR 四个值。
- **LogEventType**：日志事件类型枚举，包含 API_REQUEST、API_RESPONSE、API_ERROR、LIFECYCLE、GENERAL 五个值。
- **LogFileManager**：日志文件管理器，负责日志文件的创建、轮转、大小控制和清理。
- **LogExporter**：日志导出器，负责 ZIP 打包和 DocumentViewPicker 调用。
- **HttpClient**：现有网络请求客户端（`core/src/main/ets/network/HttpClient.ets`），是 API 日志的主要采集点。
- **AppEnv**：应用运行环境枚举（MOCK / DEBUG / RELEASE），三个环境均完整记录所有级别日志，行为完全一致。

---

## 需求

### 需求 1：日志条目数据模型

**用户故事：** 作为开发者，我希望每条日志都包含足够的上下文信息，以便在不连接设备的情况下复现和定位问题。

#### 验收标准

1. THE ApiLogEntry SHALL 包含以下字段：唯一 ID（自增整数）、时间戳（Unix 毫秒）、日志级别（LogLevel）、事件类型（LogEventType）、标签（tag 字符串）、消息体（message 字符串）、可选的附加数据（extraJson 字符串）。
2. THE LogLevel SHALL 包含 DEBUG、INFO、WARNING、ERROR 四个枚举值，且枚举值与字符串表示一一对应。
3. THE LogEventType SHALL 包含 API_REQUEST、API_RESPONSE、API_ERROR、LIFECYCLE、GENERAL 五个枚举值，且枚举值与字符串表示一一对应。
4. WHEN 创建 ApiLogEntry 时，THE ApiLogEntry SHALL 将 timestamp 默认设置为当前 Unix 毫秒时间戳。
5. THE ApiLogEntry SHALL 将 extraJson 字段默认值设置为空字符串，以兼容无附加数据的场景。

---

### 需求 2：API 请求与响应日志采集

**用户故事：** 作为开发者，我希望每次 API 调用都被自动完整记录，无需在每个 ApiService 中手动添加日志代码。

#### 验收标准

1. WHEN HttpClient 发起 GET 或 POST 请求时，THE ApiLogSystem SHALL 自动记录一条 LogEventType 为 API_REQUEST 的日志，包含请求 URL、HTTP 方法、完整请求头（含 Cookie 明文）。
2. WHEN HttpClient 收到成功响应时，THE ApiLogSystem SHALL 自动记录一条 LogEventType 为 API_RESPONSE 的日志，包含 HTTP 状态码、响应耗时（毫秒）、完整响应体（前 500 字符）。
3. WHEN HttpClient 收到业务错误响应（retcode ≠ 0）时，THE ApiLogSystem SHALL 自动记录一条 LogLevel 为 WARNING、LogEventType 为 API_ERROR 的日志，包含 retcode 和 message 字段。
4. WHEN HttpClient 发生网络异常（超时、连接失败等）时，THE ApiLogSystem SHALL 自动记录一条 LogLevel 为 ERROR、LogEventType 为 API_ERROR 的日志，包含异常类型和异常消息。
5. THE ApiLogSystem SHALL 在 mock、debug 和 release 三个环境下均完整记录所有 API 日志，不做任何过滤或脱敏。

---

### 需求 3：业务层错误日志采集

**用户故事：** 作为开发者，我希望业务层的关键错误（Cookie 失效、Geetest 触发、同步失败等）被自动记录，方便排查 API 调用链路问题。

#### 验收标准

1. WHEN Repository 层的 sync 方法捕获到 Error 时，THE ApiLogSystem SHALL 记录一条 LogLevel 为 ERROR 的日志，包含操作类型（syncAvatarList / syncDailyNote 等）和错误消息。
2. WHEN AuthExpiredError 被捕获时，THE ApiLogSystem SHALL 记录一条 LogLevel 为 WARNING 的日志，标注 Cookie 已失效的账号 ID。
3. WHEN GeetestRequiredError 或 GeetestSignRequiredError 被捕获时，THE ApiLogSystem SHALL 记录一条 LogLevel 为 WARNING 的日志，标注触发 Geetest 验证的接口路径。

---

### 需求 4：日志持久化存储

**用户故事：** 作为开发者，我希望日志能持久化到本地文件，除非手动清理或卸载应用，否则日志永久保留。

#### 验收标准

1. THE ApiLogSystem SHALL 将日志条目持久化到应用沙箱目录下的日志文件（路径：`files/logs/api_log_<日期>.txt`，日期格式 `YYYY-MM-DD`）。
2. WHEN 日志文件大小超过 5MB 时，THE LogFileManager SHALL 创建新的日志文件，旧文件保留不删除。
3. THE LogFileManager SHALL 不自动删除任何日志文件，日志文件永久保留，直到用户手动清理或卸载应用。
4. WHEN 应用启动时，THE ApiLogSystem SHALL 完成日志文件初始化，初始化完成前的日志条目 SHALL 缓存在内存队列中，初始化完成后批量写入。
5. THE ApiLogSystem SHALL 以追加写入（append）方式写入日志文件，每条日志占一行，格式为 JSON 序列化的 ApiLogEntry。
6. IF 日志文件写入失败（磁盘满、权限不足等），THEN THE ApiLogSystem SHALL 记录错误到控制台并跳过本次写入，不得影响主业务流程。
7. FOR ALL 有效的 ApiLogEntry 对象 entry，JSON.parse(JSON.stringify(entry)) SHALL 产生与 entry 字段值相同的对象（序列化往返一致性）。

---

### 需求 5：日志导出

**用户故事：** 作为开发者，我希望能将日志文件导出保存到设备本地，以便后续分析或分享给他人。

> **导出流程说明**：HarmonyOS NEXT 提供 `DocumentViewPicker`（`@kit.CoreFileKit`），相当于 iOS 的 `UIDocumentBrowserViewController`。调用 `DocumentViewPicker.save()` 会弹出系统文件管理器，用户选择保存位置（如下载文件夹），ZIP 文件保存到该位置后可通过文件管理器 App 进一步分享（微信、邮件、华为分享等）。

#### 验收标准

1. WHEN 用户在 My 页「关于」区域点击「导出日志」时，THE ApiLogSystem SHALL 将所有日志文件打包为 ZIP 压缩包，临时存放在应用缓存目录，然后通过 `DocumentViewPicker.save()` 弹出系统文件管理器，让用户选择保存位置。
2. WHEN 用户在文件管理器中确认保存位置后，THE ApiLogSystem SHALL 将 ZIP 文件写入用户选择的目录，写入完成后删除临时 ZIP 文件。
3. THE ApiLogSystem SHALL 在导出文件名中包含应用版本号和导出时间戳，格式为 `mihoyo_tool_log_<version>_<timestamp>.zip`，该文件名作为 `DocumentViewPicker.save()` 的默认文件名建议。
4. IF 打包或保存过程中发生错误，THEN THE ApiLogSystem SHALL 通过 HdsSnackBar 向用户展示错误提示，并清理临时文件，不得崩溃。

---

### 需求 6：日志清理

**用户故事：** 作为用户，我希望能手动清理日志文件以释放存储空间。

#### 验收标准

1. THE My 页「关于」区域 SHALL 在版本号 Cell 上方提供「导出日志」和「清理缓存」两个 Cell，所有环境均可见。「清理缓存」Cell 右侧 SHALL 实时显示当前日志文件的总占用大小，格式规则如下：
   - 小于 1 MB 时显示 KB，保留一位小数，例如 `512.0 KB`
   - 1 MB 至 1 GB 之间显示 MB，保留一位小数，例如 `3.2 MB`
   - 1 GB 及以上显示 GB，保留两位小数，例如 `1.25 GB`
   - 日志为空时显示 `0 KB`
2. WHEN 用户点击「清理缓存」时，THE LogFileManager SHALL 向用户展示确认对话框，用户确认后才执行删除操作。
3. WHEN 用户确认清理时，THE LogFileManager SHALL 删除所有日志文件，并通过 HdsSnackBar 展示已释放的存储空间大小，「清理缓存」Cell 右侧大小更新为 `0 KB`。
4. IF 清理过程中某个文件删除失败，THEN THE LogFileManager SHALL 继续删除其余文件，并在完成后汇总报告失败数量。
5. 日志文件 SHALL 仅在以下两种情况下被删除：用户手动触发清理操作，或用户卸载应用。系统不得自动删除日志文件。

---

### 需求 7：日志系统初始化与生命周期

**用户故事：** 作为开发者，我希望日志系统随应用启动自动初始化，无需手动管理生命周期。

#### 验收标准

1. WHEN CoreInitializer.initCore() 被调用时，THE ApiLogSystem SHALL 作为初始化步骤之一完成自身初始化，初始化顺序在数据库初始化之后。
2. THE ApiLogSystem SHALL 提供单例访问方式（ApiLogSystem.getInstance()），保证全局只有一个实例。
3. WHEN ApiLogSystem.getInstance() 在初始化完成前被调用时，THE ApiLogSystem SHALL 将日志条目缓存到内存队列，不得抛出异常。
4. THE ApiLogSystem SHALL 与现有 Logger 工具类协同工作：ApiLogSystem 写入持久化文件，Logger 继续输出到 hilog 控制台，两者互不干扰。
5. WHEN AppEnvManager.isMock() 为 true 时，THE ApiLogSystem SHALL 同样完成初始化并正常工作，以支持 Mock 环境下的调试。
6. THE ApiLogSystem SHALL 在 MOCK、DEBUG、RELEASE 三个环境下行为完全一致：记录 DEBUG 及以上所有级别，完整记录所有信息，日志永久保留直到手动清理。

---

### 需求 8：日志系统测试覆盖

**用户故事：** 作为开发者，我希望日志系统的核心逻辑有充分的测试覆盖，以保证序列化的正确性。

#### 验收标准

1. THE ApiLogEntry 序列化与反序列化 SHALL 满足往返一致性：FOR ALL 有效 ApiLogEntry 对象 entry，反序列化（JSON.parse）序列化（JSON.stringify）结果的所有字段值 SHALL 与原始 entry 相同。
2. THE LogFileManager SHALL 提供可测试的文件大小检查和文件轮转逻辑，文件操作通过接口抽象以支持 Mock。
3. THE LogFileManager.formatSize() SHALL 满足格式化正确性：对任意非负整数字节数，返回符合 KB/MB/GB 换算规则的字符串。

---

## 附录：日志格式示例

每条日志在文件中占一行，格式为 JSON 序列化的 `ApiLogEntry`。

### 字段说明

| 字段        | 类型   | 说明                                                                             |
| ----------- | ------ | -------------------------------------------------------------------------------- |
| `id`        | number | 自增整数，同一文件内唯一                                                         |
| `timestamp` | number | Unix 毫秒时间戳                                                                  |
| `level`     | string | 日志级别：`DEBUG` / `INFO` / `WARNING` / `ERROR`                                 |
| `eventType` | string | 事件类型：`API_REQUEST` / `API_RESPONSE` / `API_ERROR` / `LIFECYCLE` / `GENERAL` |
| `tag`       | string | 调用方标识，由代码手动传入，例如 `BBSRepository` / `MockService`                 |
| `message`   | string | 日志主体描述                                                                     |
| `extraJson` | string | 附加结构化数据（JSON 字符串），无附加数据时为空字符串 `""`                       |

> **关于文件名和行号**：ArkTS 在编译后不保留源码位置信息，运行时无法获取源文件名和行号。`tag` 字段由开发者手动传入，用于标识日志来源模块，是定位问题的主要依据。

---

### 示例一：Cookie 登录 API（debug / release 环境）

用户在 Login 页输入 Cookie 点击登录，触发 `BBSRepository.login()` → `MihoyoAccountApiService.post()`。

**1. 请求发出（API_REQUEST）**

```json
{
  "id": 1,
  "timestamp": 1744700400123,
  "level": "DEBUG",
  "eventType": "API_REQUEST",
  "tag": "HttpClient",
  "message": "POST https://api-takumi.mihoyo.com/binding/api/getUserGameRolesByCookie",
  "extraJson": "{\"method\":\"POST\",\"headers\":{\"Cookie\":\"account_id=123***\",\"x-rpc-app_version\":\"2.71.1\"},\"bodySize\":0}"
}
```

**2. 响应成功（API_RESPONSE）**

```json
{
  "id": 2,
  "timestamp": 1744700400456,
  "level": "DEBUG",
  "eventType": "API_RESPONSE",
  "tag": "HttpClient",
  "message": "POST https://api-takumi.mihoyo.com/binding/api/getUserGameRolesByCookie → 200 (333ms)",
  "extraJson": "{\"statusCode\":200,\"durationMs\":333,\"bodyPreview\":\"{\\\"retcode\\\":0,\\\"message\\\":\\\"OK\\\",\\\"data\\\":{\\\"list\\\":[{\\\"game_id\\\":2,\\\"game_biz\\\":\\\"hk4e_cn\\\"\"}]}}\"}"
}
```

**3. 业务错误（API_ERROR，retcode ≠ 0）**

```json
{
  "id": 3,
  "timestamp": 1744700401000,
  "level": "WARNING",
  "eventType": "API_ERROR",
  "tag": "HttpClient",
  "message": "POST https://api-takumi.mihoyo.com/binding/api/getUserGameRolesByCookie → retcode=-100: Not logged in",
  "extraJson": "{\"retcode\":-100,\"message\":\"Not logged in\"}"
}
```

**4. Cookie 失效被捕获（业务层）**

```json
{
  "id": 4,
  "timestamp": 1744700401050,
  "level": "WARNING",
  "eventType": "GENERAL",
  "tag": "BBSRepository",
  "message": "AuthExpiredError: Cookie expired for accountId=123",
  "extraJson": ""
}
```

---

### 示例二：Cookie 登录 API（mock 环境）

mock 环境下 `MihoyoAccountMockService` 读取本地 JSON 文件，不发起真实网络请求。日志结构相同，但 tag 和 message 会体现 mock 来源。

**1. Mock 请求（API_REQUEST）**

```json
{
  "id": 1,
  "timestamp": 1744700400123,
  "level": "DEBUG",
  "eventType": "API_REQUEST",
  "tag": "MockService",
  "message": "[MOCK] POST /binding/api/getUserGameRolesByCookie → binding_api_getUserGameRolesByCookie.json",
  "extraJson": "{\"method\":\"POST\",\"mockFile\":\"mock/123456/binding_api_getUserGameRolesByCookie.json\"}"
}
```

**2. Mock 响应（API_RESPONSE）**

```json
{
  "id": 2,
  "timestamp": 1744700400173,
  "level": "DEBUG",
  "eventType": "API_RESPONSE",
  "tag": "MockService",
  "message": "[MOCK] POST /binding/api/getUserGameRolesByCookie → 200 (50ms)",
  "extraJson": "{\"statusCode\":200,\"durationMs\":50,\"bodyPreview\":\"{\\\"retcode\\\":0,\\\"message\\\":\\\"OK\\\",\\\"data\\\":{\\\"list\\\":[...]}}\"}"
}
```

**3. Mock 文件不存在（API_ERROR）**

```json
{
  "id": 3,
  "timestamp": 1744700400180,
  "level": "WARNING",
  "eventType": "API_ERROR",
  "tag": "MockService",
  "message": "[MOCK] File not found: mock/123456/binding_api_getUserGameRolesByCookie.json → returning empty response",
  "extraJson": "{\"mockFile\":\"mock/123456/binding_api_getUserGameRolesByCookie.json\"}"
}
```

---

### 示例三：业务层错误（Cookie 失效）

Cookie 失效时 `BBSRepository` 捕获 `AuthExpiredError` 并写入日志。

```json
{
  "id": 4,
  "timestamp": 1744700401050,
  "level": "WARNING",
  "eventType": "GENERAL",
  "tag": "BBSRepository",
  "message": "AuthExpiredError: Cookie expired for accountId=123",
  "extraJson": ""
}
```

> **关于 Crash**：应用崩溃由 APMS（AGC 性能监测）在系统层面自动收集，本日志系统不负责 Crash 捕获。

---

## 附录：日志文件结构与分析方法

### 日志文件实际内容

每个日志文件是纯文本，每行一条 JSON，按时间顺序追加。以下是一次完整的"Cookie 登录 → 拉取游戏角色 → Cookie 失效"流程在文件中的实际样子：

```
{"id":1,"timestamp":1744700400100,"level":"DEBUG","eventType":"LIFECYCLE","tag":"CoreInitializer","message":"initCore started, env=DEBUG","extraJson":""}
{"id":2,"timestamp":1744700400200,"level":"DEBUG","eventType":"API_REQUEST","tag":"HttpClient","message":"POST https://api-takumi.mihoyo.com/auth/api/webLoginByMobile","extraJson":"{\"headers\":{\"Cookie\":\"account_id=123***\"}}"}
{"id":3,"timestamp":1744700400550,"level":"DEBUG","eventType":"API_RESPONSE","tag":"HttpClient","message":"POST https://api-takumi.mihoyo.com/auth/api/webLoginByMobile → 200 (350ms)","extraJson":"{\"statusCode\":200,\"durationMs\":350,\"bodyPreview\":\"{\\\"retcode\\\":0,\\\"message\\\":\\\"OK\\\"}\"}"}
{"id":4,"timestamp":1744700400600,"level":"DEBUG","eventType":"API_REQUEST","tag":"HttpClient","message":"GET https://api-takumi.mihoyo.com/binding/api/getUserGameRolesByCookie","extraJson":"{\"headers\":{\"Cookie\":\"account_id=123***\"}}"}
{"id":5,"timestamp":1744700401200,"level":"WARNING","eventType":"API_ERROR","tag":"HttpClient","message":"GET https://api-takumi.mihoyo.com/binding/api/getUserGameRolesByCookie → retcode=-100: Not logged in","extraJson":"{\"retcode\":-100,\"message\":\"Not logged in\"}"}
{"id":6,"timestamp":1744700401210,"level":"WARNING","eventType":"GENERAL","tag":"BBSRepository","message":"AuthExpiredError: Cookie expired for accountId=123","extraJson":""}
```

可以看到：

- 每行独立，可以用任何文本工具逐行处理
- `id` 是连续的，可以快速定位某条日志前后的上下文
- `timestamp` 可以计算两条日志之间的耗时（第 4 条到第 5 条：600ms）

---

### 在应用内查看（LogViewer）

LogViewer 提供两种查看方式：

**列表视图**：按时间倒序展示，每行显示 `时间 | 级别 | tag | message 前 100 字符`，可按 `level` 和 `eventType` 筛选。例如只看 `WARNING` 以上的条目，就能快速定位所有错误，忽略大量 DEBUG 请求日志。

**详情视图**：点击某条日志展开完整内容，包括 `extraJson` 里的请求头、响应体摘要等。

---

### 导出后在电脑上分析

导出的 ZIP 解压后是若干 `.txt` 文件，每个文件对应一天。在 macOS/Linux 上可以用命令行快速分析：

**只看 WARNING 及以上的错误：**

```bash
grep '"level":"WARNING"\|"level":"ERROR"' api_log_2026-04-15.txt
```

**找所有 Cookie 失效事件：**

```bash
grep 'AuthExpiredError' api_log_2026-04-15.txt
```

**统计某个接口被调用了多少次：**

```bash
grep 'getUserGameRolesByCookie' api_log_2026-04-15.txt | grep 'API_REQUEST' | wc -l
```

**找响应时间超过 2 秒的请求（durationMs > 2000）：**

```bash
grep 'API_RESPONSE' api_log_2026-04-15.txt | grep -E '"durationMs":[2-9][0-9]{3}'
```

**用 Python 解析并按 tag 分组统计错误数：**

```python
import json
from collections import Counter

errors = Counter()
with open('api_log_2026-04-15.txt') as f:
    for line in f:
        entry = json.loads(line)
        if entry['level'] in ('WARNING', 'ERROR'):
            errors[entry['tag']] += 1

for tag, count in errors.most_common():
    print(f"{tag}: {count}")
```

---

### 排查问题的典型流程

**场景：用户反馈"同步失败"**

1. 导出日志，用 `grep 'ERROR\|WARNING'` 过滤出所有错误
2. 找到时间点附近的 `API_ERROR` 条目，查看 `retcode` 和 `message`
3. 往前找同一时间段的 `API_REQUEST`，确认请求参数是否正确
4. 如果是 `retcode=-100`（Cookie 失效），结合 `AuthExpiredError` 日志确认账号 ID
5. 如果是网络超时，查看 `durationMs` 是否异常大

**场景：mock 环境某个接口返回空数据**

1. 在 LogViewer 里筛选 `eventType=API_ERROR`，找 `[MOCK] File not found` 的条目
2. `extraJson` 里的 `mockFile` 字段直接告诉你缺少哪个 JSON 文件
3. 补充对应的 mock 文件即可
