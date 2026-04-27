# 实现计划：API 日志收集系统（api-log-system）

## 概述

在 core 模块新增 `log/` 目录，实现日志条目模型、单例系统、文件管理器和导出器；在 HttpClient 注入采集点；在 BBSRepository 注入业务错误日志；在 CoreInitializer 完成初始化；在 AboutSection 新增「导出日志」和「清理缓存」两个 Cell。

## 任务

- [x] 1. 创建 ApiLogEntry 数据模型
  - 新建 `core/src/main/ets/log/ApiLogEntry.ets`
  - 定义 `LogLevel` 枚举（DEBUG / INFO / WARNING / ERROR），枚举值与字符串一一对应
  - 定义 `LogEventType` 枚举（API_REQUEST / API_RESPONSE / API_ERROR / LIFECYCLE / GENERAL），枚举值与字符串一一对应
  - 定义 `ApiLogEntry` 类，包含 id / timestamp / level / eventType / tag / message / extraJson 字段，timestamp 默认 `Date.now()`，extraJson 默认空字符串
  - _需求：1.1、1.2、1.3、1.4、1.5_

  - [ ]\* 1.1 为 ApiLogEntry 编写单元测试（`core/src/test/ApiLogEntry.test.ets`）
    - **属性 1：序列化往返一致性**——对任意有效 ApiLogEntry，`JSON.parse(JSON.stringify(entry))` 所有字段与原始值相同
    - **验证：需求 1.1、4.7、8.1**
    - Example：LogLevel 4 个枚举值与字符串一一对应
    - Example：LogEventType 5 个枚举值与字符串一一对应
    - Example：默认 timestamp 在合理范围内，extraJson 默认为空字符串
    - 在 `core/src/test/List.test.ets` 中注册 `apiLogEntryTest`
    - _需求：8.1_

- [x] 2. 创建 LogFileManager 文件管理器
  - 新建 `core/src/main/ets/log/LogFileManager.ets`
  - 定义 `IFileSystem` 接口（appendLine / getFileSize / listFiles / deleteFile / getTotalSize）
  - 定义 `DeleteResult` 接口（deletedCount / failedCount / freedBytes）
  - 实现 `LogFileManager` 类，包含：
    - 常量：`MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024`、`LOG_DIR = 'files/logs'`、`FILE_PREFIX = 'api_log_'`
    - 纯函数 `static formatSize(bytes: number): string`，按 KB/MB/GB 规则格式化
    - 纯函数 `static getCurrentFileName(): string`，返回 `api_log_YYYY-MM-DD.txt`
    - `async init(context): Promise<void>`，创建日志目录，初始化当前文件路径
    - `async append(entry: ApiLogEntry): Promise<void>`，写入前检查文件大小，超过 5MB 则轮转新文件，赋值 id（同文件内自增），追加 NDJSON 行；写入失败时 `Logger.error` 记录并跳过，不抛出异常
    - `async getTotalLogSize(): Promise<number>`，累加所有日志文件大小
    - `async deleteAllLogs(): Promise<DeleteResult>`，逐个删除，失败继续，汇总结果
    - `async listLogFiles(): Promise<string[]>`，列出所有日志文件路径
  - _需求：4.1、4.2、4.3、4.5、4.6、6.1_

  - [ ]\* 2.1 为 LogFileManager 纯函数编写单元测试（`core/src/test/LogFileManager.test.ets`）
    - **属性 2：formatSize 格式化正确性**——对任意非负整数字节数，返回符合 KB/MB/GB 换算规则的字符串
    - **验证：需求 6.1、8.3**
    - Example：`formatSize(0) === '0 KB'`
    - Example：`getCurrentFileName()` 返回今日日期格式 `api_log_YYYY-MM-DD.txt`
    - 在 `core/src/test/List.test.ets` 中注册 `logFileManagerTest`
    - _需求：8.3_

- [x] 3. 创建 ApiLogSystem 单例入口
  - 新建 `core/src/main/ets/log/ApiLogSystem.ets`
  - 实现单例 `ApiLogSystem` 类：
    - `private static instance: ApiLogSystem | null = null`
    - `private initialized: boolean = false`
    - `private pendingQueue: ApiLogEntry[] = []`
    - `static getInstance(): ApiLogSystem`
    - `async init(context): Promise<void>`：初始化 LogFileManager，将 pendingQueue 批量写入文件，清空队列；写入 LIFECYCLE 日志标记初始化完成
    - `log(entry: ApiLogEntry): void`：已初始化则调用 `LogFileManager.append()`，否则推入 pendingQueue；任何异常均捕获并 `Logger.error` 记录，不影响主流程
    - 便捷方法：`debug / info / warning / error(tag, message, eventType?, extraJson?)`，内部构造 ApiLogEntry 后调用 `log()`
  - _需求：7.1、7.2、7.3、7.4、7.5、7.6_

- [x] 4. 创建 LogExporter 导出器
  - 新建 `core/src/main/ets/log/LogExporter.ets`
  - 实现 `LogExporter` 类：
    - `static async export(context): Promise<void>`
    - 获取所有日志文件列表（通过 `LogFileManager`）
    - 使用 `@kit.CoreFileKit` 的 `zlib` 将日志文件打包为 ZIP，临时存放在 `context.cacheDir`
    - 导出文件名格式：`mihoyo_tool_log_<version>_<timestamp>.zip`（version 从 `BuildProfile.VERSION_NAME` 读取）
    - 调用 `DocumentViewPicker.save()` 弹出系统文件管理器，让用户选择保存位置
    - 用户确认后写入目标位置，删除临时 ZIP
    - 任何步骤失败：通过 `HdsSnackBar` 提示错误，清理临时文件，不崩溃
    - 用户取消（picker 返回空）：静默处理，清理临时文件
  - _需求：5.1、5.2、5.3、5.4_

- [x] 5. 在 CoreInitializer 中初始化 ApiLogSystem
  - 修改 `core/src/main/ets/CoreInitializer.ets`
  - 在 `initCore()` 中，`RdbManager.init()` 之后调用 `await ApiLogSystem.getInstance().init(config.context)`
  - 写入 LIFECYCLE 日志：`ApiLogSystem.getInstance().info('CoreInitializer', 'initCore started, env=...')`（在 `AppEnvManager.setup()` 之后、DB 初始化之前写入，此时 ApiLogSystem 尚未初始化，日志进入 pendingQueue）
  - _需求：7.1、7.5_

- [x] 6. 在 HttpClient 注入日志采集点
  - 修改 `core/src/main/ets/network/HttpClient.ets`
  - 在 `get()` 和 `post()` 方法中注入日志采集（最小侵入，不改变现有逻辑）：
    - 请求前：`ApiLogSystem.getInstance().debug('HttpClient', '${method} ${url}', LogEventType.API_REQUEST, JSON.stringify({method, headers: ..., bodySize}))`，完整记录请求头（含 Cookie 明文）
    - 响应后（成功）：记录 API_RESPONSE，包含 statusCode、durationMs、bodyPreview（前 500 字符）
    - 业务错误（retcode ≠ 0）：记录 WARNING 级别 API_ERROR，包含 retcode 和 message
    - 网络异常（catch 块）：记录 ERROR 级别 API_ERROR，包含 errorType 和 errorMessage
  - 日志采集代码用 try-catch 包裹，任何异常不影响原有请求逻辑
  - _需求：2.1、2.2、2.3、2.4、2.5_

- [x] 7. 在 BBSRepository 注入业务错误日志
  - 修改 `core/src/main/ets/repository/BBSRepository.ets`
  - 在 `login()` 方法的 catch 块中，捕获到 `AuthExpiredError` 时记录 WARNING 日志（tag: 'BBSRepository'，标注 Cookie 失效的账号 ID）
  - 在 `login()` 方法的 catch 块中，捕获到 `GeetestRequiredError` 或 `GeetestSignRequiredError` 时记录 WARNING 日志（标注触发 Geetest 的接口路径）
  - 在 sync 方法（`getUserGameRoles`、`getBbsAccountDetail`、`getGameRecordCard`）的 catch 块中，捕获到 Error 时记录 ERROR 日志（包含操作类型和错误消息）
  - _需求：3.1、3.2、3.3_

- [x] 8. 在 core/Index.ets 导出新增类
  - 修改 `core/Index.ets`，新增以下导出：
    ```
    export * from './src/main/ets/log/ApiLogEntry';
    export * from './src/main/ets/log/ApiLogSystem';
    export * from './src/main/ets/log/LogFileManager';
    export * from './src/main/ets/log/LogExporter';
    ```
  - _需求：7.2_

- [x] 9. 检查点——确保 core 模块编译通过
  - 确保所有测试通过，ask the user if questions arise.

- [x] 10. 新增 string 资源并更新 AboutSection
  - 在 `entry/src/main/resources/base/element/string.json`、`zh_HK/element/string.json`、`en/element/string.json` 中新增以下 key：
    - `my_export_logs`：「导出日志」
    - `my_clear_cache`：「清理缓存」
    - `my_clear_cache_confirm_title`：「确认清理」
    - `my_clear_cache_confirm_msg`：「将删除所有本地日志文件，此操作不可撤销」
    - `my_clear_cache_success`：「已释放 %s」
    - `my_clear_cache_failed`：「清理完成，%d 个文件删除失败」
    - `my_export_logs_failed`：「导出失败，请重试」
  - 修改 `entry/src/main/ets/components/my/AboutSection.ets`：
    - 新增 `@Local private logSize: string = '0 KB'` 状态字段
    - 在 `aboutToAppear()` 中异步读取 `LogFileManager.getTotalLogSize()` 并格式化更新 `logSize`
    - 在版本号 Cell 上方新增「导出日志」Cell（点击调用 `LogExporter.export(context)`）
    - 在「导出日志」Cell 下方新增「清理缓存」Cell，右侧显示 `logSize`（点击弹出 `AlertDialog` 确认，确认后调用 `LogFileManager.deleteAllLogs()`，通过 `HdsSnackBar` 展示结果，更新 `logSize` 为 `'0 KB'`）
    - 更新 `@Preview` 结构体，覆盖新增的两个 Cell
  - _需求：6.1、6.2、6.3、6.4、6.5_

- [x] 11. 最终检查点——确保所有测试通过
  - 确保所有测试通过，ask the user if questions arise.

## 备注

- 标有 `*` 的子任务为可选测试任务，可跳过以加快 MVP 进度
- 每个任务引用了具体的需求条款，便于追溯
- 属性测试验证设计文档中定义的正确性属性（属性 1、属性 2）
- LogFileManager 的文件操作通过 `IFileSystem` 接口抽象，支持 Mock 测试
- 日志写入失败不影响主业务流程（所有写入操作均有 try-catch 保护）
