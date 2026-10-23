# Core Kits 已知问题与暂缓项

> 状态：**Phase 1.2 / Phase 2 / Phase 3 / Phase 5 代码层完成；S-01 已解决；公共 Header 合并已完成；UAT / Mock 签名与运行时迁移验证延后**
> 更新时间：2026-10-23
> 原则：当前构建和既有功能可运行；header / retcode 未采集项保持现状，不用静态推断修改行为。任何修复必须等真机、抓包或明确需求，不把“参考项目这样做”直接当成线上结论。
>
> 相关文档：[`API-Baseline.md`](API-Baseline.md) §2.2 静态参考矩阵、[`APIService.md`](APIService.md) §8.6 / §8.7、[`Mock.md`](Mock.md)。

---

## 1. 运行时未采集（不阻塞 Phase 1.2）

| ID | 项目 | 当前状态 | 为什么暂不改 | 后续动作 |
| --- | --- | --- | --- | --- |
| R-01 | header / DS / retcode 实际抓包 | 只有静态参考；`API-Baseline.md` 仍为“运行时未采集” | 当前代码可运行，静态参考存在冲突 | 任务完成后用 Proxyman + debug 包补采；见 `APIService.md` §8.6 |
| R-02 | BBS 账号 / 角色 / 战绩卡片 header | `client_type=1` + DS v2 + `Referer: app.mihoyo.com` | 本项目历史 App 抓包支持 `client_type=1`；TeyvatGuide / Pizza 用 `5` + X4 | 真机确认 `getUserFullInfo` / `getGameRoles` / `getGameRecordCard`；不要仅凭 SDK 推断 |
| R-03 | 二维码登录 header / token | 已切到 TeyvatGuide 变体：`bll8iq97cem8` + Capture/2.2.0 + `client_type=3` + X4 DS；确认后调用 `getLTokenBySToken` 再取 `cookie_token` | 静态 header 和 token 流程已对齐；扫码得到的 stoken 能否用于米游社尚未真机验证 | 真机扫码验证；不要再混用 Pizza / HYPContainer 变体 |
| R-04 | `cookie_token` 的 client_type | 当前 `getCookieAccountInfoBySToken` 用 `5` | TeyvatGuide 默认 `2`，Pizza 用 `5`；两边都有依据 | 失败时再对比；暂不改 |
| R-05 | 便笺 / Widget header | `buildPizza`：app 2.40.1、UA 2.40.1、page `3.1.3_#/rpg` | 与 Pizza 一致；历史 App 抓包是 2.102.0 / 2.115.0 + tool_verison / 按游戏 page + device_name | 真机确认便笺和 Widget；`addNoteCaptureHeaders` 当前未调用，不要顺手启用 |
| R-06 | HTTP 非 200 / 超时 | `HttpError` 已实现；`statusCode=0` 表示无响应 | 没有真实 401/500/断网记录 | 在真机或本地代理制造 401/500/超时各一次 |
| R-07 | Mock 数据链路 | `mock` product 可构建；`MihoyoDomain` 已切到 `http://127.0.0.1:8787`，但 `mock-service` 只有 `/__health`、`/`、`POST /__mock/rpc` | 直接 REST 路由未实现，App 请求会 404；UAT / Mock 签名也未配置 | 先补签名，再实现 local service 直连路由并做真机 / 模拟器回归；见 `Mock.md`，不要误判为已可用 |
| R-08 | 真机功能回归 | 登录、便笺、角色、养成计算、签到未在本轮真机验证 | 只有构建和 grep 验收 | 有 `hdc` target 时按第 5 节清单跑一轮 |

---

## 2. 已知参考差异（当前保持原样）

| ID | 项目 | 差异 | 当前决定 |
| --- | --- | --- | --- |
| D-01 | `getSignInfo` / `getSignReward` 参数 | 当前没有 `lang` / `act_id` 等参数，与 TeyvatGuide 不同；目前无业务调用方 | 保持原样，不修改；等签到功能真正接入时再处理 |
| D-02 | `10307` 服务器维护 | PizzaHelperUnited 有专门映射；当前按普通业务错误处理 | 暂不加常量 / 分支，避免无调用方代码 |
| D-03 | `-1002` / `1008` | `ACCOUNT_NOT_FOUND=-1002` 表示游戏账号未绑定，不是 `1008` 用户信息不匹配；当前无调用方 | 常量值和注释已纠正，不新增行为 |
| D-04 | 指纹错误类型 | `ApiErrorHandler` 没有专门的指纹错误类型；`FingerprintReporter` + `SyncQueueRunner` 已处理 5003 / 10041 | 保持现状；不在迁移收尾阶段扩展错误体系 |
| D-05 | `getGameRecordCard` 路径 | 当前用 SDK 的 `/game_record/app/card/wapi/...`；历史 App 抓包是 `/game_record/card/api/...` | 保留 SDK 路径；只记录，不改 |
| D-06 | `addNoteCaptureHeaders` | 方法存在但未被调用 | 保留为后续真机对照项；不要因静态参考直接启用 |
| D-07 | `HttpService` 默认 header / Cookie 覆盖 | 旧 transport 已删除；现在由 `MihoyoApiService` 按 profile 合并公共 header，具体 API 只提供专属 header | 以合并后的最终 header 为准；真机验证账号 / BBS 路径 |

> 这些问题只记录，不在 Phase 1.2 目录重组时顺手修改。目录重组必须保持请求行为不变。

### 2.1 构建环境已知问题

| ID | 项目 | 当前状态 | 当前决定 |
| --- | --- | --- | --- |
| E-01 | 旧开发签名证书过期 / `internal` 已移除 | `Certificates/dev/miyoyo-dev.cer` 与 `miyoyo-profileDebug.p7b` 于 `2026-10-21 13:15:20 CST` 过期；`core/src/internal` / `entry/src/internal` 已合并删除；release 证书有效期到 `2029-04-24` | 不再使用旧 dev 材料；`internal` product 已移除。不要通过修改证书或复用 release 来绕过签名 |
| E-02 | UAT / Mock 签名未配置 | `build-profile.json5` 中 `uat` / `mock` 引用了 `signingConfigs`，但当前只有 release 配置；两者构建产物为 unsigned HAP，不能安装 | 在 AGC 为 `com.cainluo.miyoyo.tools.uat` / `.mock` 创建独立调试证书和调试 Profile，填入 `signingConfigs`；禁止复用 release 或共享同一环境的签名 |

### 2.2 结构性暂缓（Phase 1.2 搬位置后暴露）

| ID | 项目 | 当前状态 | 当前决定 |
| --- | --- | --- | --- |
| S-01 | 基础层反向依赖（已解决） | Phase 5 后 `base/` 到各 Kit / `CoreInitializer` 的依赖为 0；`CookieRefreshCoordinator` / `ColdStartCookieChecker` 已迁入 `MihoyoKit/cookie`；`GeetestService` 改为由 `CoreInitializer` 注册游戏配置和 `ZZZRecordRequest` handler；`ApiConfig` 不再 import `ZZZRecordRequest`；`SyncQueueRunner` 改为通过 `sync/SyncPorts` 注入 `BBSRepository` / 三个游戏 Repository。`sync/SyncPorts` 仍引用 `AccountRow` / `GameRoleRow` / `ZZZAvatarBasicRow` 行模型，`base/` 仍引用 `common/constants`（`MihoyoRetcode` / `AppEnvManager` / `GameId`）——均不构成对 Kit 控制层的反向依赖 | 已通过 `node scripts/check-architecture.mjs`：0 import cycle、0 `base → Kit` 边；后续新增 `base` 代码继续遵守该守卫 |

---

## 3. Phase 1.2 进度（第一批完成，不改业务行为）

### 3.1 已完成

1. 用 `git mv` 迁移 32 个共享文件：
   - `base/network` 14 个：`APIs`、`BaseApiService`、`HttpTypes`、`MihoyoApiService`、`ApiConfig`、`MihoyoDomain`、`MihoyoHeaderKey`、`MihoyoHeaderBuilder`、`DSUtil`、`CookieManager`（Phase 5 已删除）、`DeviceFpService`、`GeetestService`、`GeetestReporter`、`FingerprintReporter`；
   - `base/log` 4 个、`base/errors` 1 个、`base/utils` 4 个、`base/cookie` 2 个；
   - `common/constants` 7 个：`AppEnv`、`AppEnvManager`、`GameId`、`GameServer`、`ApiConstants`、`ApiErrorCodes`、`SyncDataType`。
2. 更新 169 处相对 import、`core/Index.ets` 导出和 `core/src/internal` overlay import；只改路径，不改业务逻辑。
3. 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因 E-01 失败；524 个相对 import 解析检查 0 缺失。
4. 旧顶层 `log/`、`errors/`、`utils/`、`cookie/` 空目录已移除；当时 `network/` 仅余游戏 / 账号专属 Service、Path 和 `MihoyoApiServiceFactory`，Phase 2 已全部迁走并删除该目录。

### 3.2 当时剩余（Phase 2 已完成）

- `db/`、`sync/`、`common/material` 不单独提交空目录，随 Phase 2/3 的对应文件迁移落位。
- 游戏 / 账号专属 Service、Path 和 `MihoyoApiServiceFactory` 已在 Phase 2 迁走，`network/` 目录已删除。
- internal overlay 的 `MihoyoKit/api`、`MihoyoKit/model`、`MihoyoKit/repository` 镜像路径已在 Phase 2 同步调整。
- E-01 证书续签后再补跑 `internal` 构建与安装验证。

### 3.3 边界

- 不动 `entry` 页面 / ViewModel / 路由。
- 不动业务 Service 的 URL / header / DS / Cookie / 上报逻辑。
- 不动 `Mock.md` 涉及的 base URL 方案；Phase 5 已删除无读取方的 `RequestOptions.baseUrlType`，Mock 仅通过 `MihoyoDomain` 切换域名。
- 根目录 `internal/core` 历史副本不动。
- 已知问题 R-01 ~ R-08、D-01 ~ D-07、E-01、S-01 继续挂起，不阻塞后续 Kit。

### 3.4 Phase 2 GenshinKit（已完成）

1. 13 个 Genshin 专属文件已迁入 `GenshinKit/`：
   - `api`（GenshinApiPath / GenshinApiService）；
   - `model`（GenshinRows / GenshinCalcModels / GenshinCharacterDetailRaw）；
   - `parser`（GenshinDailyNoteParser / GenshinComputeParser）；
   - `constants`（GenshinElement / GenshinPropertyType）；
   - `db`（GenshinDao + RdbMigrationV4 / V5）；
   - `repository`（GenshinRepository）。
2. 53 处相对 import、`core/Index.ets`、`MihoyoApiServiceFactory`、`CoreInitializer` 和测试 import 已更新；只改路径，不改请求行为。
3. 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因 E-01 失败；相对 import 解析检查 0 缺失。
4. `base/network/GeetestService` 现在 import `GenshinKit/api/GenshinApiPath`，已并入 S-01；`database/RdbManager` 曾 import GenshinKit migrations，该反向依赖已在 Phase 3C 移除。
5. Genshin 的 `TableSchema` 片段、`GenshinMaterialBagDao` / `GenshinMaterialTargetConfigDao` 子类、material model/repository；V4 还包含星铁 material target config 的跨 Kit 迁移，均已在 Phase 3 完成。

### 3.5 Phase 2 StarRailKit（已完成）

1. 11 个 StarRail 专属文件已迁入 `StarRailKit/`：
   - `api`（StarRailApiPath / StarRailApiService）；
   - `model`（StarRailRows / StarRailAvatarDetailRaw）；
   - `parser`（StarRailDailyNoteParser / StarRailComputeParser）；
   - `constants`（StarRailElement / StarRailPropertyType）；
   - `db`（StarRailDao / StarRailDBManager）；
   - `repository`（StarRailRepository）。
2. 63 处相对 import、`core/Index.ets`、`MihoyoApiServiceFactory`、`CoreInitializer` 和测试 import 已更新；只改路径，不改请求行为。
3. 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因 E-01 失败；相对 import 解析检查 0 缺失。
4. `base/network/GeetestService` 现在同时 import `GenshinKit/api/GenshinApiPath` 和 `StarRailKit/api/StarRailApiPath`，已并入 S-01；ZZZKit 迁移后也加入了 `ZZZApiPath`，剩余项在 Phase 5 收口。
5. StarRail 的 `TableSchema` 片段、`StarRailMaterialBagDao` / `StarRailMaterialTargetConfigDao` 子类、material model/repository 已在 Phase 3 完成。

### 3.6 Phase 2 ZZZKit（已完成）

1. 14 个 ZZZ 专属文件已迁入 `ZZZKit/`：
   - `api`（ZZZApiPath / ZZZApiService / ZZZRecordRequest）；
   - `model`（ZZZRows / ZZZAvatarDetailRaw）；
   - `parser`（ZZZDailyNoteParser / ZZZComputeParser）；
   - `constants`（ZZZElement / ZZZEnums / ZZZPropertyId）；
   - `db`（ZZZDao + RdbMigrationV2 / V6）；
   - `repository`（ZZZRepository）。
2. 67 处相对 import、`core/Index.ets`、`MihoyoApiServiceFactory`、`CoreInitializer` 和测试 import 已更新；只改路径，不改请求行为。
3. 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因 E-01 失败；相对 import 解析检查 0 缺失。
4. `base/network/ApiConfig` / `GeetestService` 现在 import `ZZZKit/api/ZZZRecordRequest` / `ZZZApiPath`，已并入 S-01；`database/RdbManager` 曾 import ZZZKit 的 V2/V6 migrations，该反向依赖已在 Phase 3C 移除；MihoyoKit 迁移后又加入 `MihoyoAccountApiPath`、`BBSRepository` / `AccountRow` 等反向依赖，剩余项在 Phase 5 收口。
5. ZZZ 的 `TableSchema` 片段、`ZZZMaterialBagDao` / `ZZZMaterialTargetConfigDao` 子类、material model/repository 已在 Phase 3 完成。

### 3.7 Phase 2 MihoyoKit（已完成）

1. Mihoyo 账号域 18 个主文件已迁移，其中 17 个迁入 `MihoyoKit/`：
   - `api`（MihoyoAccountApiPath / MihoyoAccountApiService / PassportApiPath / QRCodeApiPath / SignApiPath / SignApiService，6）；
   - `model`（AccountRow / GameRoleRow / BbsAccountModels / GameRoleModels / TokenModels / PhoneLoginModels / QRCodeLoginModels，7）；
   - `db`（BBSDao，1）；
   - `repository`（AuthRepository / BBSRepository / SignRepository，3）。
2. `network/MihoyoApiServiceFactory.ets` 迁为根 `ApiServiceFactory.ets`，是第 18 个主文件；Phase 5 已将类名统一为 `ApiServiceFactory`，并更新 `CoreInitializer` 调用。
3. 3 个 internal overlay（MihoyoAccountApiService / AuthRepository / PhoneLoginModels）已镜像到 `internal/ets/MihoyoKit/{api,repository,model}/`；overlay import 按 main 路径计算，保持同路径 fallback。
4. 123 处相对 import、`core/Index.ets`、`CoreInitializer`、Genshin / StarRail / ZZZ 三个 Repository、base cookie / network 和测试 import 已更新；只改路径，不改 URL、header、DS、Cookie、retcode 或上报逻辑。
5. 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因 E-01 失败；相对 import 解析检查 0 缺失。
6. 反向依赖：`base/cookie` → `MihoyoKit/repository/BBSRepository` / `MihoyoKit/model/AccountRow`；`base/network/GeetestService` → `MihoyoKit/api/MihoyoAccountApiPath`；`sync/SyncQueueRunner` → `MihoyoKit/model/GameRoleRow`；Genshin / StarRail / ZZZ 三个 Repository → `MihoyoKit/repository/BBSRepository`（Kit → MihoyoKit 是既定单向例外）。`MihoyoKit/db/BBSDao` 已改为依赖 `db/TableSchema` / `db/RdbManager` / `db/RsReader`（Kit → 共享底层），`BBSRepository` 已改为依赖 `sync/SyncQueueRunner`。
7. `TableSchema` 中的账号 / role 片段、material DAO 子类、material model/repository 已在 Phase 3 完成；Phase 2 代码层完成。

### 3.8 Phase 3A — sync / material 路径迁移（已完成，`5aff4e4`）

1. `GameRepository` / `SyncQueueRunner` 迁入 `sync/`；sync 模型迁入 `sync/model/`，`SyncMetaDao` 迁入 `sync/db/`。
2. material 模型迁入 `common/material/model/`，`MaterialBagRepository` / `MaterialTargetConfigRepository` 迁入 `common/material/repository/`；空的顶层 `models/` / `repository/` 移除。
3. 更新 53 处相对 import、`core/Index.ets` 和测试路径；未改 URL、header、DS、Cookie、retcode、表结构或迁移。
4. 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因 E-01 失败；524 个相对 import 解析 0 缺失。

### 3.9 Phase 3B — material DAO 拆分（已完成，`1fd097e`）

1. `BaseMaterialBagDao` / `BaseMaterialTargetConfigDao` 留 `common/material/db/`；GenshinKit / StarRailKit / ZZZKit 各新增两个 material DAO 子类。
2. material repository、`MaterialBagDao.test` 和 `core/Index.ets` 改为从基类 / 对应 Kit 子类导入；删除旧 `database/MaterialBagDao.ets` / `MaterialTargetConfigDao.ets`。
3. 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因 E-01 失败；550 个相对 import 解析 0 缺失。

### 3.10 Phase 3C — TableSchema 拆分与 SchemaRegistry（已完成代码层，`47135c1`）

1. `RdbManager` / `RsReader` 迁入 `db/`；V3 / V7 跨 Kit 迁移迁入 `db/migrations/cross/`。
2. `TableSchema` 拆为 `db/TableName.ets`、`db/TableSchema.ets`（通用 `TableDef` / `IndexDef` / `ColumnDef` / `CommonCol` / `ComputeStateCol` / `FK_ACCOUNT`）、各 Kit `db/schema.ets`、`sync/db/schema.ets` 和 `common/material/db/schema.ets`（material 列枚举）。
3. 根 `SchemaRegistry.ets` 聚合 24 张表、30 个索引和 V2~V7 迁移；`RdbManager.init(context, SchemaRegistry)` 改为接收注册表，`db/` 不再 import 任何 Kit；`CoreInitializer` 和 11 个测试调用同步更新。
4. 静态等价：`ALL_TABLES` / `ALL_INDEXES` 顺序与旧 `TableSchema` 一致；24 个表定义、23 个列枚举、30 个索引定义逐项比对无差异；V4 / V5 使用 `GENSHIN_INDEXES` 按原条件筛选，执行的 DDL 与顺序不变。
5. 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因 E-01 失败；621 个相对 import 解析 0 缺失。
6. 未验证：`RdbManager.test` / DAO 测试实际运行、旧版本 DB 文件升级路径、真机与 Mock 回归。两个测试脚本只构建 ohosTest HAP，不是运行测试。

### 3.11 Phase 5 — 依赖反转与清理（代码层完成，2026-10-22）

1. **Cookie 归属下沉**：`ColdStartCookieChecker` / `CookieRefreshCoordinator` 从 `base/cookie` 迁入 `MihoyoKit/cookie`；`CookieRefreshCoordinator.init(BBSRepository)` 由 `CoreInitializer` 注入，三个游戏 Repository 不再 import 根 `CoreInitializer`。删除无引用的 `base/network/CookieManager`。
2. **同步队列依赖反转**：新增 `sync/SyncPorts.ets`（`SyncAccountStore` / `GenshinSyncPort` / `StarRailSyncPort` / `ZZYSyncPort` / `SyncDependencies`）；`SyncQueueRunner.init(SyncDependencies)` 由 `CoreInitializer` 注入，四个 Repository 显式 implement 对应端口。`sync/` 不再 import 根 `CoreInitializer`。
3. **Geetest 注入**：`GeetestService` 删除对 `MihoyoAccountApiPath` / `GenshinApiPath` / `StarRailApiPath` / `ZZZApiPath` / `ZZZRecordRequest` 的 import；游戏配置由 `CoreInitializer.registerGame()` 注册，绝区零战绩 handler 通过 `GeetestRecordHandler` 注入。
4. **设备指纹收口**：`GameFpBiz` 从 `DeviceFpService` 移到 `base/network/GameFpBiz.ets`；`ApiConfig.regenerateDeviceFp()` 不再 import `ZZZRecordRequest`，ZZZ 指纹清理改由 entry `DeviceFpCenter.regenerate()` 调用 `ZZZRecordRequest.clearAll()`。
5. **命名 / 死字段**：`MihoyoApiServiceFactory` 类名改为 `ApiServiceFactory`；删除 `RequestOptions.baseUrlType`；移除 `core/Index.ets` 中重复的 `GenshinPropertyType` 导出；`core/BuildProfile.ets` 改为 Hvigor 生成物，从 Git 移除并加入 `.gitignore`。
6. **删除未使用文件**：`CookieManager`、12 个不可达 entry 组件 / 工具文件、`core/src/main/ets/{constants,database,parsers}` 空目录；`entry/src/main/ets/components/main` 空目录一并移除。根目录历史 `internal/core` 未动。
7. **验证**：`core@default assembleHar`、`entry@ohosTest`、`mock` debug、`uat` debug、`release` release 构建通过；`bash test-core.sh` 编译通过（只构建 HAP，不执行测试）；新增 `MihoyoDomain.test.ets` / `HeaderBuilder.test.ets`；`node scripts/check-architecture.mjs` 输出 0 import cycle、0 `base → Kit` 边、业务 Service 无直接 header builder 调用。
8. **公共 Header 合并已完成**：`HeaderContext` + `prepareOptions` / `getWithProfile` / `postWithProfile`；raw / passport / QR / 设备指纹 / Geetest 路径保持原 header。**仍延后**：UAT / Mock 签名与安装、Mock REST 路由 / Swift-Vapor、真机 header / retcode 与 DB 升级回归。

---

## 4. Phase 1.2 / Phase 2 / Phase 3 检查

- [x] 本批共享文件只在 `base/` / `common/constants/` 出现，没有重复副本
- [x] `core/Index.ets` 导出符号不变
- [x] `default` / `debug` / `mock` 构建通过；`internal` 编译通过，`SignHap` 因 E-01 失败
- [x] `test-core.sh` / `test-entry.sh` 通过
- [x] 524 个相对 import 解析检查 0 缺失；无旧路径 / 旧 transport 引用
- [x] diff 仅包含路径和 import 变更，没有修改业务请求行为
- [x] 已知问题仍保留在本文件，未因搬文件而丢失

### 4.1 Phase 2 GenshinKit 检查

- [x] 13 个 Genshin 专属文件只在 `GenshinKit/` 出现，没有重复副本
- [x] `core/Index.ets` 导出的 Genshin 符号不变
- [x] `default` / `debug` / `mock` 构建通过；`internal` 编译通过，`SignHap` 因 E-01 失败
- [x] `test-core.sh` / `test-entry.sh` 通过
- [x] 相对 import 解析检查 0 缺失
- [x] diff 仅包含路径和 import 变更，没有修改业务请求行为
- [x] `TableSchema` / material DAO / material model/repository 的延后项已记录

### 4.2 Phase 2 StarRailKit 检查

- [x] 11 个 StarRail 专属文件只在 `StarRailKit/` 出现，没有重复副本
- [x] `core/Index.ets` 导出的 StarRail 符号不变
- [x] `default` / `debug` / `mock` 构建通过；`internal` 编译通过，`SignHap` 因 E-01 失败
- [x] `test-core.sh` / `test-entry.sh` 通过
- [x] 相对 import 解析检查 0 缺失
- [x] diff 仅包含路径和 import 变更，没有修改业务请求行为
- [x] `TableSchema` / material DAO / material model/repository 的延后项已记录

### 4.3 Phase 2 ZZZKit 检查

- [x] 14 个 ZZZ 专属文件只在 `ZZZKit/` 出现，没有重复副本
- [x] `core/Index.ets` 导出的 ZZZ 符号不变
- [x] `default` / `debug` / `mock` 构建通过；`internal` 编译通过，`SignHap` 因 E-01 失败
- [x] `test-core.sh` / `test-entry.sh` 通过
- [x] 相对 import 解析检查 0 缺失
- [x] diff 仅包含路径和 import 变更，没有修改业务请求行为
- [x] `TableSchema` / material DAO / material model/repository 的延后项已记录

### 4.4 Phase 2 MihoyoKit 检查

- [x] 18 个 Mihoyo 主文件（17 个在 `MihoyoKit/`，工厂在根）和 3 个 internal overlay 只在对应相对路径出现，没有重复副本
- [x] `core/Index.ets` 导出的账号域符号保持；工厂文件在 Phase 2 改名，Phase 5 类名统一为 `ApiServiceFactory`
- [x] `default` / `debug` / `mock` 构建通过；`internal` 编译通过，`SignHap` 因 E-01 失败
- [x] `test-core.sh` / `test-entry.sh` 通过
- [x] 相对 import 解析检查 0 缺失
- [x] diff 仅包含路径、import 和工厂文件改名，没有修改业务请求行为
- [x] `TableSchema` / material DAO / material model/repository 的延后项已记录

### 4.5 Phase 3A 检查

- [x] `sync/`、`common/material/model/`、`common/material/repository/` 路径落位，没有重复副本
- [x] `core/Index.ets` 和 53 处 import 更新，业务请求行为未改
- [x] `default` / `debug` / `mock` 构建通过；`internal` 编译通过，`SignHap` 因 E-01 失败
- [x] `test-core.sh` / `test-entry.sh` 通过；524 个相对 import 解析 0 缺失
- [x] 空的顶层 `models/` / `repository/` 已移除

### 4.6 Phase 3B 检查

- [x] material 基类只在 `common/material/db/`，三个 Kit 子类只在各自 `db/`，没有重复副本
- [x] material repository 签名保持不变，测试与 `Index.ets` 导出更新
- [x] `default` / `debug` / `mock` 构建通过；`internal` 编译通过，`SignHap` 因 E-01 失败
- [x] `test-core.sh` / `test-entry.sh` 通过；550 个相对 import 解析 0 缺失
- [x] 旧 `database/MaterialBagDao.ets` / `MaterialTargetConfigDao.ets` 已删除

### 4.7 Phase 3C 检查

- [x] `db/RdbManager` / `db/RsReader` / `db/migrations/cross/` 落位；`db/` 不 import 任何 Kit
- [x] 根 `SchemaRegistry.ets` 聚合 24 张表、30 个索引和 V2~V7 迁移，`RdbManager.init` 接收注册表
- [x] `ALL_TABLES` / `ALL_INDEXES` 顺序、24 个表定义、23 个列枚举、30 个索引定义与旧 `TableSchema` 静态比对无差异
- [x] `default` / `debug` / `mock` 构建通过；`internal` 编译通过，`SignHap` 因 E-01 失败
- [x] `test-core.sh` / `test-entry.sh` 通过；621 个相对 import 解析 0 缺失
- [ ] `RdbManager.test` / DAO 测试实际运行
- [ ] 旧版本 DB 文件 → 新包首启升级路径手测
- [ ] 真机与 Mock 回归

### 4.8 Phase 5 检查

- [x] `base/` 不再 import 任何 Kit / 根 `CoreInitializer`；`sync/` 不再 import `CoreInitializer`
- [x] `CookieRefreshCoordinator` / `ColdStartCookieChecker` 位于 `MihoyoKit/cookie`，`CoreInitializer` 完成注入
- [x] `SyncQueueRunner` 通过 `SyncPorts` 获取账号 / 三游戏能力；`base -> Kit` 边为 0
- [x] `GeetestService` 游戏配置与 ZZZ handler 均由 `CoreInitializer` 注册；`ApiConfig` 不再 import ZZZKit
- [x] `GameFpBiz` 独立文件；`ZZZRecordRequest.clearAll()` 由 entry `DeviceFpCenter` 调用
- [x] `ApiServiceFactory` 命名统一；`RequestOptions.baseUrlType` 已删除；`MihoyoDomain` Mock 契约测试已注册
- [x] `core@default assembleHar`、`entry@ohosTest`、`mock` / `uat` / `release` 构建通过
- [x] `node scripts/check-architecture.mjs`：0 import cycle、0 `base → Kit` 边
- [x] 公共 Header 合并（5 个业务 Service；raw / passport / QR 保留原路径）
- [ ] UAT / Mock 签名、安装与 Mock REST 数据链路
- [ ] 真机 header / retcode、DB 升级与三环境回归

---

## 5. 真机回归清单（有设备时执行）

> 详细步骤、勾选项和待填结果见 [`Runtime-Acceptance-Checklist.md`](Runtime-Acceptance-Checklist.md)。

- [ ] 手机号登录 / 二维码登录 / Cookie 登录
- [ ] 账号详情、游戏角色列表、战绩卡片
- [ ] 原神 / 星铁 / 绝区零便笺与 Widget
- [ ] 原神 / 星铁 / 绝区零角色列表与详情
- [ ] 原神 / 星铁 / 绝区零养成计算
- [ ] 签到信息 / 签到（当前有调用方时）
- [ ] HTTP 401 / 500 / 断网 / 超时各一次
- [ ] 1034 / 10035 的 Geetest 提示，5003 / 10041 的指纹提示

> 回归结果只记录脱敏摘要；Cookie、token、`device_fp`、`device_id`、完整 HAR 不进入仓库。
