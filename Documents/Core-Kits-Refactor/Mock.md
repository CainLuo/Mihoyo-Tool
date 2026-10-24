# Mock 部分：环境与 Local Service 迁移记录

> 本文件属于 `Documents/Core-Kits-Refactor/`。整个 task 的规划与阶段状态见 [`README.md`](README.md)，完整重构方案见 [`Plan.md`](Plan.md)。
>
> 根目录 `README.md` 暂不更新；等全部整合完成后再统一补充入口。
>
> 更新时间：2026-10-20
> 当前状态：Node `mock-service/` 保留；独立 `mock` product 保留；Core/entry 已无 Mock 适配器；Swift-Vapor local service 尚未开始。
> 用途：记录本次 Mock 清理结果，作为后续 Swift-Vapor local service 的交接文档。

---

## 0. 一句话结论

- **`mock` 环境仍然存在**：独立 `mock` product，包名 `com.cainluo.miyoyo.tools.mock`，`APP_ENV=mock`。
- **`mock/` 源码目录已经删除**：原来的 ArkTS Mock 适配器不在仓库里了。
- **Core/entry 不再包含 Mock 逻辑**：没有 MockService、Mock 工厂分支、注入入口。
- **`mock-service/` 保留**：Node HTTP 服务 + 224 个 fixture，供未来 Swift-Vapor 复用。
- **当前 mock 包不会返回 Mock 数据**：因为客户端没有接 `mock-service`，网络仍然走真实 API。
- **下一步不是恢复 Core Mock 代码**，而是用 Swift-Vapor 实现 local service，并在 App 侧只增加 MOCK 环境的本地 base URL 接入。

---

## 0.1 Mock 部分缺口摘要

- [ ] Swift-Vapor local service 未实现
- [ ] App 未连接 local service，mock 包仍走真实 API
- [ ] 直连路径代理 vs RPC 方案未最终确定
- [ ] App 侧 base URL 覆盖点未实现
- [ ] 真机 / 模拟器 mock 数据联调未做
- [ ] Swift-Vapor 与 Node 的 parity 测试未建立
- [ ] fixture 缺口未补：签到、ZZZ `avatar_compute`、原神/星铁账号级 Widget
- [ ] local service 启动 / 停止脚本未做
- [ ] 最终 README 未更新（等全部整合后统一处理）

详细上下文见第 5.6 节、第 7 节和第 8 节。

---

## 1. 四个容易混淆的概念

| 名称 | 当前状态 | 作用 |
| --- | --- | --- |
| `mock` product / `.mock` 包 | **保留** | 独立可安装 App，Bundle ID `com.cainluo.miyoyo.tools.mock`，`APP_ENV=mock` |
| `mock/` 目录 | **已删除** | 原来存放 ArkTS Mock 适配器（`MockTransport`、`MockServiceBase`、各游戏 MockService） |
| `mock-service/` | **保留** | 本机 Node HTTP 服务 + fixtures；不参与 HAP 构建；App 当前未接入 |
| `buildMode=mock` | **保留，仅测试** | `test-core.sh` / `test-entry.sh` 构建 ohosTest 时使用，不是 App product |

关键区别：

- `product=mock` 决定**打哪个 App 包**。
- `buildMode=mock` 只影响**测试构建模式**，不要用它来运行 mock App。
- `mock/` 是**源码目录**，不是 HAP；HAP 是构建产物。
- `mock-service/` 是**服务端数据源**，不是 HAP，也不打进 App。

---

## 2. 当前构建与运行配置

### 2.1 Products

根目录 `build-profile.json5` 当前有四个 product：

| Product | Bundle ID | App 名称 | `APP_ENV` | 说明 |
| --- | --- | --- | --- | --- |
| `default` | `com.cainluo.miyoyo.tools` | 米悠悠 | `release` | 正式发布 |
| `mock` | `com.cainluo.miyoyo.tools.mock` | 米悠悠-mock | `mock` | 独立 Mock 环境 |
| `debug` | `com.cainluo.miyoyo.tools.debug` | 米悠悠-debug | `debug` | 真实 API 调试 |
| `internal` | `com.cainluo.miyoyo.tools` | 米悠悠-internal | `debug` | 真实 API，正式签名 |

`mock` product 的关键配置：

```json5
{
  name: "mock",
  signingConfig: "default",
  bundleName: "com.cainluo.miyoyo.tools.mock",
  label: "$string:app_name_mock",
  buildOption: {
    arkOptions: {
      buildProfileFields: {
        APP_ENV: "mock",
      },
    },
  },
}
```

### 2.2 entry target

`entry/build-profile.json5` 的 `mock` target 只负责入口显示名：

```json5
{
  name: "mock",
  source: {
    abilities: [
      {
        name: "EntryAbility",
        label: "$string:EntryAbility_label_mock",
      },
    ],
  },
}
```

对应资源：

- `AppScope/resources/base/element/string.json`：`app_name_mock = 米悠悠-mock`
- `entry/src/main/resources/base/element/string.json`：`EntryAbility_label_mock = 米悠悠-mock`

### 2.3 常用命令

```bash
# 构建并安装独立 mock 包
bash run.sh mock

# 等价于
hvigorw assembleHap -p product=mock
```

产物：

```text
entry/build/mock/outputs/mock/entry-mock-unsigned.hap
```

DevEco Studio 中也可以直接选择 `mock` product 运行。

### 2.4 脚本映射

| 脚本 | mock 映射 |
| --- | --- |
| `run.sh mock` | `product=mock`，安装 `.mock` 包 |
| `pull-logs.sh mock` | 拉取 `com.cainluo.miyoyo.tools.mock` 的日志 |
| `test-cookie-refresh.sh` 的 Mock 选项 | 操作 `.mock` 包的数据库 |
| `test-core.sh` / `test-entry.sh` | 使用 `buildMode=mock` 构建 ohosTest，**不安装 mock App** |

`run.sh` 未指定参数时默认 `debug`，不是 `mock`。

### 2.5 当前 mock 包的实际行为

虽然 `APP_ENV=mock`，但 Core/entry 中没有任何分支使用 `AppEnv.MOCK`，所以：

- mock 包会正常启动；
- 使用独立包名，不会覆盖 debug 包；
- 网络请求仍然走真实 API；
- 不会读取本地 fixture；
- 不会自动连接 `mock-service`。

也就是说：**目前它是“独立的 mock 环境壳子”，不是“返回 Mock 数据的版本”。**

---

## 3. 已删除 / 保留 / 迁移

### 3.1 已删除

| 路径 | 说明 |
| --- | --- |
| `mock/` | 独立 ArkTS Mock 适配器目录（`Index.ets`、`MockTransport`、各游戏 MockService 等） |
| `core/src/main/ets/network/MockService.ets` | 旧 Mock 基类 |
| `core/src/main/ets/network/mock/` | Genshin / StarRail / ZZZ / Sign / MihoyoAccount MockService、`MockServiceBase` |
| `core/src/internal/ets/network/mock/MihoyoAccountMockService.ets` | internal overlay 的账号 Mock |
| `core/src/test/MockServiceBase.test.ets` | 旧 Mock 路由纯函数测试 |
| `entry/src/ohosTest/ets/test/core/MockServiceBase.test.ets` | entry 侧旧 Mock 测试 |

同时删除了：

- `MihoyoApiServiceFactory` 的 MOCK 分支
- `CoreInitializer` 的 Mock Service 注入入口；`NetworkFactory` / `HttpService` 也会在 BaseApiService 迁移完成后删除，后续不再有这条注入路径
- entry 启动时按环境选择 Mock Service 的逻辑
- `mock` product 曾经依赖的 `mock` 模块注册

### 3.2 保留

| 内容 | 说明 |
| --- | --- |
| `AppEnv.MOCK` | 枚举值保留 |
| `appEnvFromString('mock')` | 仍返回 `AppEnv.MOCK` |
| `AppEnvManager.isMock()` | API 保留，但当前无调用分支 |
| `mock` product / `.mock` 包 | 独立环境，和 debug 分开 |
| `app_name_mock` / `EntryAbility_label_mock` | mock 包显示名 |
| 脚本里的 mock 选项 | `run.sh` / `pull-logs.sh` / Cookie 测试 |
| `mock-service/` | Node 服务、fixtures、测试 |

### 3.3 fixtures 迁移

原来的 fixture 从：

```text
core/src/mock/resources/rawfile/mock/
```

迁移到：

```text
mock-service/fixtures/
```

当前规模：

- 224 个 JSON
- 约 27 MB
- 2 个账号：
  - `182692936`：214 个文件，角色 `102731382` / `37716744` / `109050292`
  - `348366494`：10 个文件，角色 `250375401` / `111310091`

fixture 已经不再打进产品 HAP。

---

## 4. `mock-service/` 当前契约

这是后续 Swift-Vapor 必须兼容的核心部分。

### 4.1 文件结构

```text
mock-service/
├── package.json
├── README.md
├── server.mjs          # HTTP 层：health / RPC / 参数解析
├── router.mjs          # 路由、fixture 查找、账号/签到 Mock
├── tests/
│   └── router.test.mjs # Node test runner，12 个测试
└── fixtures/
    └── {accountId}/
        ├── {roleId}/
        │   ├── {fileName}.json
        │   └── avatar_compute/{avatarId}.json
        └── {fileName}.json
```

### 4.2 启动参数

```bash
cd mock-service
npm start
# 或
node server.mjs
```

默认：

- 监听 `127.0.0.1:8787`
- 延迟 `300ms`
- fixtures 目录为 `mock-service/fixtures`

可用参数：

```bash
node server.mjs --port 8787
node server.mjs --host 0.0.0.0
node server.mjs --delay 0
node server.mjs --fixtures ./fixtures
```

真机 / 模拟器接入时需要端口映射：

```bash
hdc rport tcp:8787 tcp:8787
```

### 4.3 HTTP 端点

| 方法 | 路径 | 作用 |
| --- | --- | --- |
| `GET` | `/` | 服务信息 |
| `GET` | `/__health` | 健康检查 |
| `POST` | `/__mock/rpc` | 调试用 RPC（fixture / account / sign） |
| `OPTIONS` | 任意 | CORS 预检 |

健康检查响应示例：

```json
{
  "ok": true,
  "fixtures": 224,
  "delayMs": 300,
  "fixturesDir": "/path/to/mock-service/fixtures"
}
```

RPC 请求格式：

```json
{
  "kind": "fixture",
  "path": "/game_record/app/genshin/api/dailyNote",
  "cookie": "account_id=182692936",
  "roleId": "109050292"
}
```

`kind` 支持：

- `fixture`：按路径查找 fixture
- `account`：手机号 / 验证码 / 二维码 / Token
- `sign`：签到

RPC 示例：

```bash
# fixture
curl -s -X POST http://127.0.0.1:8787/__mock/rpc \
  -H 'Content-Type: application/json' \
  -d '{"kind":"fixture","path":"/game_record/app/genshin/api/dailyNote","cookie":"account_id=182692936","roleId":"109050292"}'

# 手机号登录
curl -s -X POST http://127.0.0.1:8787/__mock/rpc \
  -H 'Content-Type: application/json' \
  -d '{"kind":"account","method":"loginByMobileCaptcha","mobile":"13800138000","captcha":"111111"}'
```

> 重要：当前 Node 服务**只提供 RPC，不直接代理真实 API 路径**（例如 `/game_record/...` 直接请求会返回 404）。  
> 旧 App 侧 `MockTransport` 会调用 RPC；该适配器已经删除，所以现在 App 没有可用的 RPC 客户端。

### 4.4 fixture 路径规则

通用规则：

```text
URL 去掉协议、域名、query
去掉开头 /
/ 替换为 _
加 .json
```

例如：

```text
/game_record/app/genshin/api/dailyNote
→ game_record_app_genshin_api_dailyNote.json
```

特殊映射（`router.mjs` 的 `SPECIAL_FILES`）：

| API 路径 | fixture 文件 |
| --- | --- |
| `/app/api/signIn` | `apihub_app_api_signIn.json` |
| `/game_record/app/genshin/api/character/detail` | `game_record_app_genshin_api_character_detail_all.json` |
| `/game_record/app/hkrpg/api/avatar/basic` | `game_record_app_hkrpg_api_avatar_list.json` |
| `/game_record/app/hkrpg/api/avatar/info` | `game_record_app_hkrpg_api_avatar_detail_all.json` |
| `/event/game_record_zzz/api/zzz/buddy/info` | `event_game_record_zzz_api_zzz_buddy_list.json` |
| `/game_record/app/genshin/aapi/widget/v2` | `game_record_app_genshin_api_dailyNote.json` |
| `/game_record/app/hkrpg/aapi/widget` | `game_record_app_hkrpg_api_note.json` |
| `/event/game_record_zzz/api/zzz/widget` | `event_record_app_zzz_widget.json` |
| `/event/e20200928calculate/v3/batch_compute` | `genshin_character_batch_compute.json` |
| `/event/rpgcalc/compute` | `hkrpg_character_compute.json` |
| `/event/nap_cultivate_tool/avatar_calc` | `zzz_character_compute.json` |

查找优先级：

1. `{accountId}/{roleId}/{fileName}`
2. `{accountId}/{fileName}`
3. 找不到 → 空响应

账号提取：

- Cookie 优先 `account_id`
- 其次 `stuid`
- 都没有则使用 `1`

角色提取：

- 优先调用方传入的 `roleId`
- 否则 query 的 `role_id` / `uid`
- 否则 body 的 `role_id` / `uid`

特殊角色：

- 绝区零角色详情从 query 的 `id_list[]` 取第一个作为 `avatarId`
- 养成计算有 `avatarId` 时优先 `avatar_compute/{avatarId}.json`

空响应：

```json
{ "retcode": 0, "message": "success", "data": {} }
```

`fallbackEmptyList=true` 时：

```json
{ "retcode": 0, "message": "OK", "data": { "list": [] } }
```

### 4.5 账号行为

| 手机号 | 账号 |
| --- | --- |
| `13800138000` | `182692936` |
| `13800138001` | `348366494` |

| 方法 | 行为 |
| --- | --- |
| `createLoginCaptcha` | 白名单手机号返回 `sent_new`，否则 `-3101` |
| `loginByMobileCaptcha` | 验证码必须为 `111111`，否则 `-3001` |
| `getLTokenBySToken` | 返回 `mock_ltoken_{aid}` |
| `getCookieTokenBySToken` | 返回 `mock_cookie_token_{aid}` |
| `fetchQRCode` | 返回固定 ticket 和假 URL |
| `queryQRCode` | 固定 `status=init`，不会自动确认 |
| `refreshCookieToken` | 返回 `mock_cookie_token` |
| `refreshLToken` | 返回 `mock_ltoken` |
| `verifyLToken` | 空成功 |

### 4.6 签到行为

- `signBBS`：读取 `fixtures/{accountId}/apihub_app_api_signIn.json`
- `signGame`：读取 `fixtures/account{accountId}/event_luna_{host}_sign.json`
- `getSignInfo`：读取 `..._info.json`
- `getSignReward`：读取 `..._home.json`

`host` 规则：

- `hk4e...` → `hk4e`
- `hkrpg...` → `hkrpg`
- `nap...` / `zzz...` → `zzz`
- 其他：取 `_` 前的部分

当前仓库没有签到 fixture，所以签到接口统一返回空成功响应。

### 4.7 已知 fixture 缺口

- 原神 / 星铁的 Widget 是账号级请求，但 fixture 在角色目录下，因此 Mock 下返回空响应。
- 绝区零没有 `avatar_compute/{avatarId}.json`，角色计算返回空响应。
- 签到 fixture 为空。
- 这些行为与迁移前的旧实现一致，不是本次删除造成的。

### 4.8 测试

```bash
cd mock-service
npm test
```

当前 12 个测试，覆盖：

- 路径 → 文件名通用规则
- 特殊映射
- query 清理
- accountId / roleId / ZZZ avatarId 提取
- fixture 候选优先级
- 三游戏 + 账号路由矩阵
- 缺失 fixture / 空列表兜底
- 账号登录、验证码、Token、二维码
- 签到兜底

---

## 5. Swift-Vapor local service 迁移方案

### 5.1 目标架构

```text
┌─────────────────────────────┐
│ App (mock product)          │
│ APP_ENV=mock                │
│ bundle .mock                │
└──────────────┬──────────────┘
               │ HTTP (127.0.0.1:8787)
               │ 真机先 hdc rport tcp:8787 tcp:8787
┌──────────────▼──────────────┐
│ Swift-Vapor local service   │
│ - 复用 fixtures             │
│ - 复用路由/账号/签到规则    │
│ - 只在本机运行              │
└──────────────┬──────────────┘
               │ 读取
┌──────────────▼──────────────┐
│ fixtures/ (224 JSON)        │
└─────────────────────────────┘
```

### 5.2 先决定：直连路径代理还是 RPC

这是迁移前最重要的设计选择。

#### 方案 A：直连路径代理（推荐）

Swift-Vapor 直接提供与真实 API 相同的路径，例如：

```text
/game_record/app/genshin/api/dailyNote
/binding/api/getUserGameRolesByCookie
/event/rpgcalc/compute
```

App 在 `APP_ENV=mock` 时只把 API base URL 指向：

```text
http://127.0.0.1:8787
```

优点：

- App 侧不需要重新引入 `MockTransport` / 各游戏 MockService；
- 不需要改 Repository / ApiService 的调用方式；
- 最接近真实 API，后续切换 local service 成本低；
- fixture 路由规则可以直接复用。

需要处理：

- 真实 API 的域名不止一个，App 侧要能把多个域名统一映射到 local service；
- query / body / Cookie / Header 需要按真实请求解析；
- 本地 HTTP 明文配置（HarmonyOS `network_config.json`）可能需要补；
- 404 / 非 0 retcode 的行为要和真实 API 对齐。

#### 方案 B：保留 RPC + App 侧适配器

Swift-Vapor 继续提供：

```text
POST /__mock/rpc
```

App 重新实现类似旧 `MockTransport` 的客户端适配器，按环境调用 RPC。

优点：

- 与当前 Node 服务的 RPC 契约完全一致；
- 可以精确控制每个 API 返回什么。

缺点：

- 需要重新往 App 里加 Mock 适配层；
- 各游戏 Service 方法签名不同，容易回到以前那套复杂注入；
- 与“Core/entry 不再包含 Mock 逻辑”的目标冲突。

**建议：优先方案 A。**  
RPC 可以保留为调试接口，但不要作为 App 的唯一接入方式。

### 5.3 推荐迁移阶段

#### Phase 0：冻结契约

- 保留当前 Node `mock-service/` 作为参考实现。
- 记录 `npm test` 12 个测试全部通过。
- 记录 health、RPC、fixture 路由样例。
- 确认 224 个 fixture、两个账号、五个角色的数据完整。

#### Phase 1：Swift 路由核心

先不接 HTTP，先实现可单测的纯函数/结构：

- `FixturePathMapper`：URL → 文件名
- `FixtureResolver`：候选优先级、accountId / roleId / avatarId
- `AccountMock`：手机号 / 验证码 / Token / 二维码
- `SignMock`：签到 fixture 路径与兜底
- `EmptyResponse`：`success` / `OK + list` 两种语义

验收：用 Node 现有测试用例做 golden test，逐条对齐。

#### Phase 2：Vapor HTTP 层

实现：

- `GET /__health`
- `POST /__mock/rpc`（如果保留）
- 方案 A 所需的真实 API 路径
- `OPTIONS` / CORS
- 300ms 延迟（可配置）
- 8 MB body 上限
- JSON Content-Type / no-store
- 404 JSON

验收：curl 能命中健康检查、fixture、账号、签到；错误路径返回预期。

#### Phase 3：双实现对比

在 Node 和 Swift-Vapor 同时运行的情况下，对同一批请求比较响应：

- 路径映射
- 账号/角色候选
- 空响应字段
- 账号和签到行为

验收：路由矩阵全部一致；fixture 缺失时响应一致。

#### Phase 4：App 接入

只在 `APP_ENV=mock` 时启用本地 base URL：

- 不改 debug / release 行为；
- 不把 fixture 打进 HAP；
- 不恢复 Core Mock 适配器；
- 通过 `hdc rport` 连接开发机；
- 需要时补 HarmonyOS 明文 HTTP 配置。

验收：mock 包能完成登录、便笺、角色、签到、计算等主要流程；debug 包仍走真实 API。

#### Phase 5：切换与归档

- Swift-Vapor 达到 parity 后，Node 服务可保留为测试参考或归档。
- 更新 `run.sh` / 文档，增加 local service 启动说明（如果确定由脚本管理）。
- 保留 `mock` product 和 `.mock` bundle。
- 不恢复 `mock/` 源码目录。

### 5.4 App 侧接入点（设计，不在本文档实现）

当前已具备：

- `RuntimeConfig.APP_ENV` 能从 `BuildProfile.APP_ENV` 得到 `AppEnv.MOCK`。
- `AppEnvManager.isMock()` 可用，但目前没有调用方。

未来建议：

- 在 API base URL 配置处判断 `APP_ENV=mock`，把域名替换为 `http://127.0.0.1:8787`。
- 具体落点优先评估 `core` 的 `ApiConfig` / `MihoyoDomain` / 具体 API 调用点，不要在 entry 页面里散落判断。
- 不要改真实 API 的 header、DS、Cookie 逻辑；local service 应接受并忽略不需要的签名。
- 如果必须按域名分别配置，做一个集中映射表，不要在多个 Repository 里重复判断。

### 5.5 Swift 实现注意事项

- **路径安全**：fixture 路径必须限制在 fixtures 根目录内，防止 `../` 路径穿越。
- **JSON 解析**：fixture 原样返回，不要重新编码改变字段顺序/数值类型。
- **query 解析**：保留 `id_list[]` 的重复参数语义。
- **body 解析**：支持 `role_id` / `uid`，并设置 body 大小上限。
- **Cookie 解析**：优先 `account_id`，其次 `stuid`，缺失回退 `1`。
- **空响应**：区分 `message=success` 和 `message=OK, data.list=[]`。
- **延迟**：默认 300ms，方便观察 loading；允许关闭。
- **端口**：默认 8787；被占用时给出明确错误。
- **日志**：记录请求路径、命中的 fixture、耗时，方便和 App 日志对齐。
- **明文 HTTP**：如果设备拦截 127.0.0.1 明文请求，再补 `network_config.json`；不要提前猜配置。
- **RPC 安全**：RPC 只用于本地调试，不要暴露到局域网/公网。

### 5.6 迁移前待确认

1. 采用直连路径代理，还是继续 RPC？
2. Swift-Vapor 服务目录名（建议 `local-service/` 或 `mock-service-vapor/`）。
3. fixtures 放在 Swift Package resource 还是共享目录。
4. Node `mock-service/` 是否保留为 parity 测试参考。
5. App 侧 base URL 覆盖的准确落点（`ApiConfig` / `MihoyoDomain` / `BaseApiService` / 具体 API 调用点）。Phase 1.1 **保持 `RequestOptions.baseUrlType` 原样，不删除、不改造**；等这里方案确定后再决定删除或改造。
6. 是否需要脚本自动启动 Swift-Vapor。
7. 真机明文 HTTP 是否需要额外配置。

---

## 6. 命令速查

```bash
# 构建并安装 mock 包
bash run.sh mock

# 只构建
hvigorw assembleHap -p product=mock

# 拉 mock 包日志
bash pull-logs.sh mock

# Cookie 刷新测试（菜单选 Mock）
bash test-cookie-refresh.sh

# 启动 Node mock service
cd mock-service
npm start

# 健康检查
curl http://127.0.0.1:8787/__health

# Node 测试
cd mock-service
npm test

# 真机/模拟器端口映射
hdc rport tcp:8787 tcp:8787
```

---

## 7. 本次验证基线

已完成：

- `mock` product 构建成功，`APP_ENV=mock`
- `debug` product 构建成功，`APP_ENV=debug`
- `default` product 构建成功，`APP_ENV=release`
- `internal` product 构建成功，`APP_ENV=debug`
- mock HAP 内部 `bundleName` 为 `com.cainluo.miyoyo.tools.mock`
- mock HAP 内部 label 为 `$string:app_name_mock`
- `test-core.sh` 通过
- `test-entry.sh` 通过
- `mock-service` 测试 12/12 通过

尚未完成：

- 真机 / 模拟器上的实际 mock 数据联调
- App 连接 `mock-service` 或 Swift-Vapor
- Swift-Vapor 实现

---

## 8. 规则与禁止事项

- **不要**把 Mock 适配器重新放回 `core` 或 `entry`。
- **不要**恢复已删除的 `mock/` 源码目录。
- **不要**把 fixture JSON 放进 App 的 rawfile / HAP。
- **不要**让 mock product 复用 debug 的 Bundle ID；mock 必须是 `.mock`。
- **不要**把 `buildMode=mock` 当成 App product；它只用于测试构建。
- **不要**在 release / default 包中启用本地 service。
- **不要**在 local service 中发起真实外部 HTTP 请求。
- **不要**把 RPC 或 local service 暴露到公网。

---

## 9. 相关文档

- [`README.md`](README.md)：整个 Core Kits 重构任务的规划与阶段状态
- [`Plan.md`](Plan.md)：Core Kits 重构完整方案
- [`mock-service/README.md`](../../mock-service/README.md)：Node 服务启动、fixture、RPC、账号/签到说明
- [`07-env-and-mock.md`](../../.kiro/steering/07-env-and-mock.md)：环境与 Mock 规范
- [`build-profile.json5`](../../build-profile.json5)：product / buildMode 配置
- [`run.sh`](../../run.sh)、[`pull-logs.sh`](../../pull-logs.sh)、[`test-cookie-refresh.sh`](../../test-cookie-refresh.sh)：本地运行与调试脚本

---

## 10. 决策记录

| 日期 | 决策 |
| --- | --- |
| 2026-10-20 | 删除 `mock/` ArkTS 源码目录；不恢复 Core/entry Mock 适配器 |
| 2026-10-20 | 保留 `AppEnv.MOCK` / `AppEnvManager.isMock()`，但当前无逻辑使用 |
| 2026-10-20 | 保留独立 `mock` product / `.mock` 包，和 debug 包区分 |
| 2026-10-20 | 保留 `mock-service/` 与 224 个 fixtures，供 Swift-Vapor 复用 |
| 2026-10-20 | mock 包当前走真实 API；App 尚未接入 local service |
| 2026-10-20 | 后续优先评估直连路径代理方案，避免重新引入 App 侧 Mock 适配器 |
