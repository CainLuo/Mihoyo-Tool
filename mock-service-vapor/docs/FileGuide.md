# 文件说明

逐文件说明职责与改动时需要注意的点。共 16 个源文件（1 个 CLI + 15 个核心文件）、
9 个测试文件（204 例）。

## 包与工具链

### `Package.swift`
- tools 5.9，平台 macOS 13。
- 唯一依赖是 Vapor 4（`from: "4.92.0"`；Vapor 5 当时只有 alpha）。
- 产物：可执行 `mock-server`（`MockServerCLI`）与库 `MockServerCore`。
- 测试目标 `MockServerCoreTests` 只依赖 `MockServerCore`，不依赖 Vapor。

### `.gitignore`
忽略 `.build/`、`Package.resolved`、`.swiftpm/`、`*.xcodeproj`、`DerivedData/`、`.DS_Store`。

## CLI

### `Sources/MockServerCLI/main.swift`
- `--help` / `-h` 打印 `ServerConfiguration.usage`。
- 解析参数 → 构造 `FixtureStore` → 目录不存在则 stderr 报错并 `exit(1)`。
- 一切正常时调用 `MockServerApplication.run`（阻塞）。
- 不含业务逻辑；要加参数应改 `ServerConfiguration`。

## Configuration

### `Sources/MockServerCore/Configuration/ServerConfiguration.swift`
- 字段：`host` / `port` / `delayMilliseconds` / `fixturesDirectory` / `maxBodyBytes`。
- 默认值：`127.0.0.1` / `8787` / `300ms` / `8 MiB`。
- `defaultFixturesDirectory(startingAt:)` 从当前目录向上最多 6 层查找
  `mock-service/fixtures`，所以从仓库根或 `mock-service-vapor/` 启动都能命中。
- `from(arguments:environment:)` 优先级：命令行 > 环境变量 > 默认值；
  非法数值静默回退默认值，负延迟按 0 处理。
- 改端口/延迟语义时同步更新 `usage` 与 README 的表格。

## Domain

### `Domain/JSONValue.swift`
- 框架无关的 JSON 枚举：`null/bool/int/number/string/array/object`。
- `init(parsing:)` 用 `JSONSerialization`；`init(any:)` 用 `CFBoolean` 区分布尔，
  并把整数值的 `Double` 收回 `.int`（避免 `retcode` 变成 `0.0`）。
- `encoded(sortedKeys:)` 默认排序键，保证合成响应字节稳定。
- 访问器：下标、`intValue` / `stringValue` / `boolValue` / `arrayValue` /
  `objectValue` / `isNull` / `anyValue`。
- 只用于**合成**响应；fixture 原样返回不经过它。

### `Domain/MockResponse.swift`
- `MockEnvelope`：`{retcode, message, data}`；`ok` / `error` / `empty(fallbackEmptyList:)`。
- `empty()` 默认 `message=success`、`data={}`；列表兜底为 `message=OK`、`data={"list":[]}`。
- `MockHTTPResponse`：`status` / `headers` / `body`；工厂 `envelope` / `json` / `raw` / `failure`。
- `defaultJSONHeaders` 是 CORS 与 Content-Type 的唯一来源，改这里会同时影响所有响应。

### `Domain/MockRequest.swift`
- 框架无关的请求快照；Vapor `Request` 只在 `App` 层转换一次。
- `path` 走 `FixturePathMapper.cleanPath`；`bodyText` 用 UTF-8；
  `header(_:)` 大小写不敏感；`cookie` / `query` / `dynamicSecret` 是便捷视图。

### `Domain/AccountModels.swift`
- `AccountMethod`（9 个）与 `SignMethod`（4 个）枚举，字符串与 RPC 请求一致。
- `AccountMock`：手机号白名单、验证码 `111111`、`mock_stoken_` 前缀、二维码账号。
- 错误码：未注册 `-3101`、验证码错 `-3001`、未知方法 `-1`。
- 改文案或字段名会直接破坏 App 登录流程，务必与 Node 版对照。

## Fixtures

### `Fixtures/FixturePathMapper.swift`
- `specialFiles` 11 条精确映射，是 Node 版的 parity 契约；测试锁定数量。
- `normalizePath` 去协议/域名；`cleanPath` 再去 query/fragment。
- `fileName(for:)` 先查特殊表；通用规则是 `/` → `_` 再追加 `.json`（根路径得到 `.json`）。

### `Fixtures/FixtureResolver.swift`
- `FixtureQuery` 是查询输入，`FixtureResolution` 是解析结果（含候选路径，便于日志）。
- `extractAccountId` 委托 `CookieParser`。
- `extractRoleId` 顺序：query `role_id` → query `uid` → body `role_id` → body `uid`。
- `extractZZZAvatarId` 取 `id_list[]` 第一个；`isZZZAvatarInfo` 判断绝区零详情路径。
- `resolve` 决定文件名：养成计算 → `avatar_compute/{avatarId}.json`；
  其他带 avatarId → `{avatarId}.json`；否则走 `FixturePathMapper`。
  候选固定两级：角色目录 → 账号目录。

### `Fixtures/FixtureStore.swift`
- `Fixture` 保存相对路径 + 原始字节；`json` 按需解析。
- `FixtureLookup` 带上 `resolution`，未命中时仍能看出「找过哪些路径」。
- `load(relativePath:)` 拒绝空路径、绝对路径与 `..` 穿越，只读。
- `find(candidates:)` 按顺序返回第一个存在项；`lookup` 是两者的组合。
- `count()` / `allRelativePaths()` 递归统计，忽略隐藏文件，只收 `.json`。

## Routing

### `Routing/RequestParsing.swift`
- `QueryParameters` 保留重复键与出现顺序（`id_list[]` 依赖它）；
  `first` / `all` / `contains` / `merged`；`rawQuery(fromURL:)` 接受完整 URL 或裸路径。
- `decode` 把 `+` 当空格，非法百分号转义保留原文。
- `CookieParser.accountId` 顺序 `account_id` → `stuid` → 回退 `1`，
  数字只取连续前缀（对齐 `parseInt`）。

### `Routing/RequestRouter.swift`
- `MockRoute` 六种：serverInfo / health / rpc / preflight / proxy / unsupported。
- 纯路径分类：`OPTIONS` 一律 preflight；`GET /` 与空路径为 serverInfo；
  `GET /__health`；`POST /__mock/rpc`；其余 GET/POST 为 proxy；其他方法 404。

### `Routing/FixtureRouter.swift`
- `FixtureRouter.query(for:)` 由请求构造查询（body 为空则传 nil，不启用列表兜底）。
- `respond(to:)` 命中返回 `raw`，未命中返回 `empty()` 信封。
- `SignMock.host(forGameBiz:)` 把 `hk4e_*` → `hk4e`、`hkrpg_*` → `hkrpg`、
  `nap_*`/`zzz_*` → `zzz`，其余取第一个 `_` 前的部分。
- `SignMock.relativePath`：大别野 `{aid}/apihub_app_signIn.json`；
  游戏签到 `account{aid}/event_luna_{host}_{sign|info|home}.json`；未知方法 nil。
- `SignMock.result` 命中返回原始字节，未命中返回空成功信封，未知方法返回错误。

## Validation

### `Validation/DynamicSecret.swift`
- `DynamicSecret`：`{timestamp},{nonce},{md5}` 三段解析与结构校验
  （纯数字时间戳/随机数、32 位**小写**十六进制摘要）。
- `DynamicSecretGenerator`：`salt={salt}&{query}&t={ts}&r={n}` 的 MD5，标准公式。
- **已知差异**：需求给出的样本摘要 `ea56f3c…` 无法用该公式复现，
  生成侧金标为 `e73e9e44da8e2c0a832a481d085aba5b`，详见 `Design.md`。
- mock 本身不校验签名；要改公式只改 `canonicalInput`。

### `Validation/RequestValidator.swift`
- `maximumBodyBytes` = 8 MiB；`isBodyWithinLimit` 含等号。
- `isSafeRelativePath` 拒绝空串、绝对路径、`..` 段、反斜杠、NUL。
- `isJSONContentType` 接受 `application/json` 与带参数形式，大小写不敏感。
- `isSupportedMethod` / `normalizedMethod` / `bodyLimitFailure`（返回可直接写进 400 的消息）。

## App

### `App/MockRPCService.swift`
- `MockRPCResult`：`envelope` 与 `rawJSON`，`body` 输出实际字节。
- `MockRPCError`：`invalidBody` / `unknownKind` / `unknownMethod` / `missingField`，带 `message`。
- `handle(body:store:)`：解析 JSON 对象 → 按 `kind` 分发：
  `fixture`（`path` 必填）→ lookup；`account` → `AccountMock.handle`；`sign` → `SignMock.result`。
- 空 body 或非对象 → `invalidBody`；未知 `kind` → `unknownKind`。

### `App/MockServerApplication.swift`
- `respond(to:configuration:store:)` 是**纯分发**，不依赖 Vapor，测试直接调用。
- `serverInfo(delayMilliseconds:)` 与 `healthPayload(configuration:store:)` 定义两个内置端点。
- `make(configuration:store:)` 装配 Vapor：设置 host/port、`defaultMaxBodySize`，
  注册 `/`、GET/POST/OPTIONS catchall。
- 每个请求：可选 sleep → 快照 → `respond` → 日志一行 → 转 `Response`。
- `run` 打印监听地址、fixture 数量、延迟，并提示 `hdc rport`。
- `makeSnapshot` / `makeVaporResponse` / `fixtureLogDescription` 是 internal，测试用 `@testable`。

## Tests（9 文件 / 204 例）

| 文件 | 用例 | 覆盖 |
| --- | --- | --- |
| `FixturePathMapperTests.swift` | 30 | 路径归一化、通用命名规则、11 条特殊映射、大小写 |
| `FixtureResolverTests.swift` | 32 | 账号/角色/avatarId 提取优先级、候选路径、计算目录 |
| `FixtureStoreTests.swift` | 18 | 共享 `TestFixtures`、224 份计数、读取/穿越/回退/JSON |
| `RequestParsingTests.swift` | 26 | query 解析（重复键、编码、`+`）、Cookie、MockRequest 视图 |
| `AccountMockTests.swift` | 30 | 9 个账号方法的成功分支、`-3101` / `-3001` / `-1` |
| `SignMockTests.swift` | 18 | host 归一化、四种签到路径、无 fixture 的兜底 |
| `DynamicSecretTests.swift` | 20 | 样例头解析、规范化输入、MD5 金标、自洽校验 |
| `MockResponseTests.swift` | 16 | 信封三种形态、编码稳定性、默认响应头、原始字节 |
| `MockServerApplicationTests.swift` | 14 | 六条路由分支、RPC 三种 kind、404 与 body 上限 |

`TestFixtures`（定义在 `FixtureStoreTests.swift`）用 `#filePath` 向上 4 层定位仓库根，
再指向 `mock-service/fixtures`；`cookie182` / `cookie348` 是两份测试 Cookie。
测试直接断言仓库真实 fixture（如树脂 152、绝区零角色「柏妮思」），
所以修改 fixtures 内容时部分断言需要同步。

## 扩展指引

- 新增特殊接口映射：只改 `FixturePathMapper.specialFiles`，并同步数量断言与 `Design.md` 表。
- 新增账号/签到方法：在 `AccountMethod` / `SignMethod` 加 case，再补 `handle` / `relativePath` 分支。
- 新增 RPC kind：在 `MockRPCService.handle` 的 switch 增加分支，并在 README 记录字段。
- 真实 DS 算法确认后：只改 `DynamicSecretGenerator.canonicalInput` 与金标测试。
