# Core Kits 已知问题与暂缓项

> 状态：**已记录，暂不改代码；Phase 1.2 第一批完成，Phase 2 GenshinKit / StarRailKit / ZZZKit / MihoyoKit 完成**
> 更新时间：2026-10-21
> 原则：当前构建和既有功能可运行；header / retcode 未采集项保持现状，不用静态推断修改行为。任何修复必须等真机、抓包或明确需求，不把“参考项目这样做”直接当成线上结论。
>
> 相关文档：[`API-Baseline.md`](API-Baseline.md) §2.2 静态参考矩阵、[`APIService.md`](APIService.md) §8.6 / §8.7、[`Mock.md`](Mock.md)。

---

## 1. 运行时未采集（不阻塞 Phase 1.2）

| ID | 项目 | 当前状态 | 为什么暂不改 | 后续动作 |
| --- | --- | --- | --- | --- |
| R-01 | header / DS / retcode 实际抓包 | 只有静态参考；`API-Baseline.md` 仍为“运行时未采集” | 当前代码可运行，静态参考存在冲突 | 任务完成后用 Proxyman + debug 包补采；见 `APIService.md` §8.6 |
| R-02 | BBS 账号 / 角色 / 战绩卡片 header | `client_type=1` + DS v2 + `Referer: app.mihoyo.com` | 本项目历史 App 抓包支持 `client_type=1`；TeyvatGuide / Pizza 用 `5` + X4 | 真机确认 `getUserFullInfo` / `getGameRoles` / `getGameRecordCard`；不要仅凭 SDK 推断 |
| R-03 | 二维码登录 header | `ddxf5dufpuyo` + `HYPContainer/1.3.3.182` + `client_type=3`、无 DS | Pizza / 当前实现与 TeyvatGuide 当前源码（`bll8iq97cem8` + Capture/2.2.0 + X4）冲突 | 真机扫码验证；两组不要混用 |
| R-04 | `cookie_token` 的 client_type | 当前 `getCookieAccountInfoBySToken` 用 `5` | TeyvatGuide 默认 `2`，Pizza 用 `5`；两边都有依据 | 失败时再对比；暂不改 |
| R-05 | 便笺 / Widget header | `buildPizza`：app 2.40.1、UA 2.40.1、page `3.1.3_#/rpg` | 与 Pizza 一致；历史 App 抓包是 2.102.0 / 2.115.0 + tool_verison / 按游戏 page + device_name | 真机确认便笺和 Widget；`addNoteCaptureHeaders` 当前未调用，不要顺手启用 |
| R-06 | HTTP 非 200 / 超时 | `HttpError` 已实现；`statusCode=0` 表示无响应 | 没有真实 401/500/断网记录 | 在真机或本地代理制造 401/500/超时各一次 |
| R-07 | Mock 数据链路 | `mock` product 可构建，但仍走真实 API | Swift-Vapor local service / base URL 覆盖未实现 | 见 `Mock.md`；Phase 4 处理，不要误判为已可用 |
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
| D-07 | `HttpService` 默认 header / Cookie 覆盖 | 旧 transport 已删除；现在由具体 API 显式设置 header | 以 service 显式 header 为准；真机验证账号 / BBS 路径 |

> 这些问题只记录，不在 Phase 1.2 目录重组时顺手修改。目录重组必须保持请求行为不变。

### 2.1 构建环境已知问题

| ID | 项目 | 当前状态 | 当前决定 |
| --- | --- | --- | --- |
| E-01 | `internal` 开发签名证书过期 | `Certificates/dev/miyoyo-dev.cer` 与 `miyoyo-profileDebug.p7b` 于 `2026-10-21 13:15:20 CST` 过期；`default` 使用的 release 证书有效期到 2029-04-24；`debug` 当前跳过签名 | 不通过改 `signingConfig` 绕过；由用户续签 Huawei AGC Development 证书和 Debug Profile。当前用 `default` / `debug` 验证代码；`internal` 只验证到 `CompileArkTS`，`SignHap` 失败不阻塞 Phase 2 / Phase 3 代码迁移 |

### 2.2 结构性暂缓（Phase 1.2 搬位置后暴露）

| ID | 项目 | 当前状态 | 当前决定 |
| --- | --- | --- | --- |
| S-01 | 基础层仍有反向依赖 | `base/cookie` 依赖 `MihoyoKit/repository/BBSRepository`、`MihoyoKit/model/AccountRow`；`base/network` 依赖 `GenshinKit/api/GenshinApiPath`、`StarRailKit/api/StarRailApiPath`、`ZZZKit/api/ZZZApiPath` / `ZZZRecordRequest`、`MihoyoKit/api/MihoyoAccountApiPath` 和根 `CoreInitializer`；`database/RdbManager` 依赖 `GenshinKit/db/migrations/RdbMigrationV4/V5` 与 `ZZZKit/db/migrations/RdbMigrationV2/V6`；`repository/SyncQueueRunner` 依赖 `MihoyoKit/model/GameRoleRow` | 本轮只搬位置，不改依赖方向；后续 Phase 3 DB 收口 / Phase 5 时通过接口、注入、SchemaRegistry 或下沉解耦，避免继续扩大 |

---

## 3. Phase 1.2 进度（第一批完成，不改业务行为）

### 3.1 已完成

1. 用 `git mv` 迁移 32 个共享文件：
   - `base/network` 14 个：`APIs`、`BaseApiService`、`HttpTypes`、`MihoyoApiService`、`ApiConfig`、`MihoyoDomain`、`MihoyoHeaderKey`、`MihoyoHeaderBuilder`、`DSUtil`、`CookieManager`、`DeviceFpService`、`GeetestService`、`GeetestReporter`、`FingerprintReporter`；
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
- 不动 `Mock.md` 涉及的 base URL 方案；`baseUrlType` 继续保持 no-op。
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
4. `base/network/GeetestService` 现在 import `GenshinKit/api/GenshinApiPath`，`database/RdbManager` import GenshinKit migrations，已并入 S-01；后续 Kit 迁移会继续扩大，必须在 Phase 3 / Phase 5 收口。
5. 未迁移：Genshin 的 `TableSchema` 片段、`GenshinMaterialBagDao` / `GenshinMaterialTargetConfigDao` 子类、material model/repository；V4 还包含星铁 material target config 的跨 Kit 迁移，按 Phase 3 处理。

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
4. `base/network/GeetestService` 现在同时 import `GenshinKit/api/GenshinApiPath` 和 `StarRailKit/api/StarRailApiPath`，已并入 S-01；ZZZKit 迁移后也加入了 `ZZZApiPath`，必须在 Phase 3 / Phase 5 收口。
5. 未迁移：StarRail 的 `TableSchema` 片段、`StarRailMaterialBagDao` / `StarRailMaterialTargetConfigDao` 子类、material model/repository；按 Phase 3 处理。

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
4. `base/network/ApiConfig` / `GeetestService` 现在 import `ZZZKit/api/ZZZRecordRequest` / `ZZZApiPath`，`database/RdbManager` import ZZZKit 的 V2/V6 migrations，已并入 S-01；MihoyoKit 迁移后又加入 `MihoyoAccountApiPath`、`BBSRepository` / `AccountRow` 等反向依赖，必须在 Phase 3 / Phase 5 收口。
5. 未迁移：ZZZ 的 `TableSchema` 片段、`ZZZMaterialBagDao` / `ZZZMaterialTargetConfigDao` 子类、material model/repository；按 Phase 3 处理。

### 3.7 Phase 2 MihoyoKit（已完成）

1. Mihoyo 账号域 18 个主文件已迁移，其中 17 个迁入 `MihoyoKit/`：
   - `api`（MihoyoAccountApiPath / MihoyoAccountApiService / PassportApiPath / QRCodeApiPath / SignApiPath / SignApiService，6）；
   - `model`（AccountRow / GameRoleRow / BbsAccountModels / GameRoleModels / TokenModels / PhoneLoginModels / QRCodeLoginModels，7）；
   - `db`（BBSDao，1）；
   - `repository`（AuthRepository / BBSRepository / SignRepository，3）。
2. `network/MihoyoApiServiceFactory.ets` 迁为根 `ApiServiceFactory.ets`，是第 18 个主文件；类名 `MihoyoApiServiceFactory` 暂不改，避免扩大符号变更，Phase 5 再统一。
3. 3 个 internal overlay（MihoyoAccountApiService / AuthRepository / PhoneLoginModels）已镜像到 `internal/ets/MihoyoKit/{api,repository,model}/`；overlay import 按 main 路径计算，保持同路径 fallback。
4. 123 处相对 import、`core/Index.ets`、`CoreInitializer`、Genshin / StarRail / ZZZ 三个 Repository、base cookie / network 和测试 import 已更新；只改路径，不改 URL、header、DS、Cookie、retcode 或上报逻辑。
5. 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因 E-01 失败；相对 import 解析检查 0 缺失。
6. 反向依赖：`base/cookie` → `MihoyoKit/repository/BBSRepository` / `MihoyoKit/model/AccountRow`；`base/network/GeetestService` → `MihoyoKit/api/MihoyoAccountApiPath`；`repository/SyncQueueRunner` → `MihoyoKit/model/GameRoleRow`；Genshin / StarRail / ZZZ 三个 Repository → `MihoyoKit/repository/BBSRepository`（Kit → MihoyoKit 是既定单向例外）。`MihoyoKit/db/BBSDao` 仍依赖 `database/TableSchema` / `RdbManager` / `RsReader`，`BBSRepository` 仍依赖 `repository/SyncQueueRunner`，留到 Phase 3 收口。
7. 未迁移：`TableSchema` 中的账号 / role 片段、material DAO 子类、material model/repository；按 Phase 3 处理。Phase 2 代码层完成。

---

## 4. Phase 1.2 / Phase 2 检查

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
- [x] `core/Index.ets` 导出的账号域符号不变；工厂文件改名但类名保持 `MihoyoApiServiceFactory`
- [x] `default` / `debug` / `mock` 构建通过；`internal` 编译通过，`SignHap` 因 E-01 失败
- [x] `test-core.sh` / `test-entry.sh` 通过
- [x] 相对 import 解析检查 0 缺失
- [x] diff 仅包含路径、import 和工厂文件改名，没有修改业务请求行为
- [x] `TableSchema` / material DAO / material model/repository 的延后项已记录

---

## 5. 真机回归清单（有设备时执行）

- [ ] 手机号登录 / 二维码登录 / Cookie 登录
- [ ] 账号详情、游戏角色列表、战绩卡片
- [ ] 原神 / 星铁 / 绝区零便笺与 Widget
- [ ] 原神 / 星铁 / 绝区零角色列表与详情
- [ ] 原神 / 星铁 / 绝区零养成计算
- [ ] 签到信息 / 签到（当前有调用方时）
- [ ] HTTP 401 / 500 / 断网 / 超时各一次
- [ ] 1034 / 10035 的 Geetest 提示，5003 / 10041 的指纹提示

> 回归结果只记录脱敏摘要；Cookie、token、`device_fp`、`device_id`、完整 HAR 不进入仓库。
