# Core Kits 重构任务总览

> 状态：**Phase 1.2 / Phase 2 / Phase 3 / Phase 5 代码层完成；S-01 已解决；2026-10-22 环境收敛完成；release 构建与测试脚本通过；uat / mock 可编译但签名待配置；公共 Header 合并已完成；运行时验收清单已建立，待执行**
> 当前阶段：**`internal` overlay 与手机号登录 UI 已合并到 main；运行环境收敛为 `mock` / `uat` / `release`；`base → Kit` 反向依赖为 0、core import cycle 为 0；三套 product 可独立构建，release 已签名，uat / mock 需独立 AGC 调试证书和 Profile**
> 下一步：**补齐 uat / mock 签名材料；按 [`Runtime-Acceptance-Checklist.md`](Runtime-Acceptance-Checklist.md) 执行运行时验收；Phase 4 Mock local service 直连路由**
> 更新时间：2026-10-23

本目录集中存放整个 Core Kits 重构任务的规划、阶段记录和专题文档，避免 Mock、Kit、DB 等子任务的文档散落在仓库各处。

---

## 0. 当前环境模型（2026-10-22）

运行环境只有三个，`default` 是 Hvigor / DevEco 要求的技术兜底 product，不是第四个运行环境：

| 运行环境 | Product | Bundle ID | APP_ENV | Build mode | API | 调试能力 |
| --- | --- | --- | --- | --- | --- | --- |
| Release | `release` | `com.cainluo.miyoyo.tools` | `release` | `release` | 官方 API | 关闭日志 / TestPage / 抓包 |
| UAT | `uat` | `com.cainluo.miyoyo.tools.uat` | `uat` | `debug` | 官方 API | 保留日志 / TestPage / 抓包 |
| Mock | `mock` | `com.cainluo.miyoyo.tools.mock` | `mock` | `debug` | `http://127.0.0.1:8787` | 保留日志 / TestPage / 抓包 |

- `core/src/internal` 与 `entry/src/internal` 已删除；手机号登录 UI 合并进 `entry/src/main`，默认 Tab 为 `PHONE`。
- `AppEnv` 只保留 `MOCK` / `UAT` / `RELEASE`，未知值回退到 `UAT`；`AppEnvManager.isDebugCapable()` 对 Mock / UAT 返回 true。
- `MihoyoDomain` 按 `AppEnvManager.isMock()` 切换域名；Mock 下 `BBS_APIHUB` 保留 `/apihub`。
- Release 使用 `Certificates/release/` 的正式签名；UAT / Mock 必须使用各自 Bundle ID 的独立调试证书和 Profile，不能复用 release。
- 当前 UAT / Mock 只构建出 unsigned HAP，尚未安装验证；`run.sh` 在签名材料缺失时会提前报错。

---

## 1. 任务目标

把 `core` 从「按文件类型平铺」重组为「按业务域分 Kit」：

1. 建立四个 Kit：`MihoyoKit`、`GenshinKit`、`StarRailKit`、`ZZZKit`
2. 统一网络入口：`BaseApiService` 作为构建链路内唯一 axios 封装层，所有 Service 通过 `MihoyoApiService` 继承它
3. DB 归类：游戏专属 DAO / schema / 迁移下沉到对应 Kit
4. Mock 服务化：fixtures 移出 HAP，保留独立 mock product；后续用 Swift-Vapor local service
5. 保持 `entry → core` 依赖方向不变，不拆多 HAR，不改 entry 的 MVVM 结构

完整设计见 [`Plan.md`](Plan.md)。

---

## 2. 文档索引

| 文档 | 内容 |
| --- | --- |
| [`Plan.md`](Plan.md) | 完整重构方案：目标结构、BaseApiService、DB 归类、阶段计划、风险 |
| [`APIService.md`](APIService.md) | `BaseApiService` 抽离方案：axios 唯一封装层、继承关系、HTTP 状态边界、已确认事项、文件级迁移/删除清单、上报审计表、直接 return 上报漏点、Cookie 覆盖、实施陷阱；第 10 节记录已实施的公共 Header 合并 |
| [`API-Baseline.md`](API-Baseline.md) | 旧 transport 迁移前后的 API header / retcode 基线清单：按登录、BBS、三游戏、签到、设备指纹 / Geetest 分组，列出触发入口、当前 header、待填字段和完成标准；§2.2 已补三个项目 + 历史抓包的静态对照；运行时 **未采集（延后）** |
| [`Runtime-Acceptance-Checklist.md`](Runtime-Acceptance-Checklist.md) | 运行时手工验收清单：环境记录、QR / 手机号 / Cookie / BBS / 便笺 / 角色 / 签到 / 错误路径，含勾选项、待填结果和失败记录模板 |
| [`Known-Issues.md`](Known-Issues.md) | 已知问题与暂缓项：header / retcode 未采集、参考冲突、当前不改的参考差异、Phase 1.2 边界与真机回归清单 |
| [`Mock.md`](Mock.md) | Mock 部分：当前配置、已删除/保留内容、`mock-service` 契约、Swift-Vapor 迁移方案、缺口清单 |

后续如果新增 Kit / DB / 迁移记录，也放在本目录，不单独建 `Documents/Mock/` 之类的子任务目录。

---

## 3. 阶段状态

| 阶段 | 状态 | 说明 |
| --- | --- | --- |
| Phase 0 — 基线 | 🟡 构建基线完成；静态参考完成；运行时基线延后 | 当时四个 product（`default` / `mock` / `debug` / `internal`）构建通过；2026-10-22 已收敛为 `mock` / `uat` / `release`。`test-core.sh` / `test-entry.sh` 通过（仅构建 ohosTest HAP，不是网络测试）；header / retcode 清单和 §2.2 静态参考矩阵已建在 [`API-Baseline.md`](API-Baseline.md)，运行时 **未采集（用户决定延后，不阻塞迁移）** |
| Phase 1 — 底盘 | 🟡 Phase 1.1 完成；Phase 1.2 第一批完成 | 新增 `HttpTypes` / `BaseApiService`；5 个业务 Service + internal overlay 已继承并完成 `.data` 拆包；`AuthRepository` / `BBSRepository` / `DeviceFpService` / `GeetestService` / `ZZZRecordRequest` 已迁移；旧 `HttpClient` / `HttpService` / `NetworkFactory` / `LegacyBaseApiService` 已删除；Phase 1.2 第一批已迁移 32 个共享文件并只改 import；`default` / `debug` / `mock` 构建和 `test-core.sh` / `test-entry.sh` 通过，`internal` 编译通过但证书过期导致 `SignHap` 失败；基线 / 真机回归待补，见 [`Known-Issues.md`](Known-Issues.md) |
| Phase 2 — 拆 Kit | ✅ 代码层完成 | GenshinKit / StarRailKit / ZZZKit 分别迁移 13 / 11 / 14 个文件；Mihoyo 账号域迁移 18 个主文件（17 个入 MihoyoKit，工厂文件迁根），另有 3 个 internal overlay；`MihoyoApiServiceFactory` 文件迁到根 `ApiServiceFactory.ets`，Phase 5 类名统一为 `ApiServiceFactory`；Phase 3 已补齐 `TableSchema`、material DAO / model / repository；原有反向依赖已在 Phase 5 解决 |
| Phase 3 — DB 收尾 | 🟡 代码层完成；运行时迁移验证延后 | Phase 3A 将 sync / material 框架路径落位；Phase 3B 拆分 material DAO 基类与三个 Kit 子类；Phase 3C 抽离 `db/TableName.ets`，拆分各 Kit `db/schema.ets` / `sync/db/schema.ets`，V3/V7 归入 `db/migrations/cross/`，根 `SchemaRegistry.ets` 聚合 `ALL_TABLES` / `ALL_INDEXES` / 迁移，`RdbManager.init(context, SchemaRegistry)`；构建与编译检查通过，运行时 DB 测试和旧库升级路径未执行 |
| Phase 4 — Mock | 🟡 部分完成 | 清理、独立 mock product、脚本、Node mock-service 已完成；Swift-Vapor local service 与 App 接入未完成 |
| Phase 5 — 收尾 | 🟡 代码层完成；Header 合并已完成 | `ApiServiceFactory` 命名统一、删除 `baseUrlType` / `CookieManager`、Cookie 与 Sync 依赖注入、Geetest / GameFpBiz / ZZZ 指纹清理收口、删除 12 个不可达 entry 文件、`BuildProfile.ets` 转为生成物；新增架构守卫与 Mock 域名测试。公共 Header 合并已完成；运行时回归仍延后 |

> Phase 4 的“完成”只代表 **Mock 清理和构建配置完成**，不代表 mock 数据链路已经可用。详见 [`Mock.md`](Mock.md)。

---

## 4. Mock 部分已完成

- 删除 `mock/` ArkTS 源码目录
- 删除 Core/entry 中的 MockService、Mock 适配器、工厂分支、注入入口
- 删除旧 `MockServiceBase` 测试
- 保留 `AppEnv.MOCK` / `AppEnvManager.isMock()` / `appEnvFromString('mock')`
- 保留独立 `mock` product：`.mock` bundle、`APP_ENV=mock`、`app_name_mock`
- 恢复 `entry` 的 `mock` target 和 `EntryAbility_label_mock`
- `run.sh mock`、`pull-logs.sh mock`、Cookie 测试脚本的 Mock 选项均指向 `.mock` 包
- 224 个 fixture 迁移到 `mock-service/fixtures/`（约 27 MB）
- `mock-service` Node 服务保留，12 个测试通过
- 2026-10-22：`internal` 已合并，`mock` / `uat` / `release` 三个 product 可独立构建；release 已签名，uat / mock 待独立 AGC 签名
- `test-core.sh` / `test-entry.sh` 通过

---

## 5. Mock 部分缺口

以下内容尚未完成，已记录在 [`Mock.md`](Mock.md)，后续不能误认为 mock 数据链路已经可用：

- [ ] **Swift-Vapor local service 未实现**
- [x] **App 侧域名覆盖点已实现**：`MihoyoDomain` 在 `APP_ENV=mock` 时切到 `http://127.0.0.1:8787`，`BBS_APIHUB` 保留 `/apihub`
- [ ] **Mock 直接 REST 路由未实现**：`mock-service/server.mjs` 目前只有 `/__health`、`/`、`POST /__mock/rpc`，App 请求会 404
- [ ] **接入方案未最终确定**：直连路径代理 vs RPC（推荐直连路径代理）
- [ ] **uat / mock 签名未配置**：必须为对应 Bundle ID 创建独立 AGC 调试证书和 Profile，不能复用 release
- [ ] **真机 / 模拟器 mock 数据联调未做**
- [ ] **Swift-Vapor 与 Node 的 parity 测试未建立**
- [ ] **fixture 缺口未补**：签到、ZZZ `avatar_compute`、原神/星铁账号级 Widget
- [ ] **local service 启动 / 停止脚本未做**
- [x] **最终 README 已按三环境模型更新**

---

## 6. 实施记录

按 `Plan.md` 的阶段顺序，**Phase 1.1 BaseApiService** 已完成；以下保留实施记录：

**Phase 1.1 — BaseApiService（Stage 0-3 已完成；基线 / 真机回归延后）**

**Stage 0 已完成（2026-10-20）**：

- 新增 `core/src/main/ets/network/HttpTypes.ets`、`BaseApiService.ets`；
- `APIs.ets` 旧抽象临时改名 `LegacyBaseApiService`，`HttpService` / `NetworkFactory` 引用已切换；
- `core/Index.ets` 已导出 `HttpTypes` / `BaseApiService`；
- 当时四个 product 构建通过，`test-core.sh` / `test-entry.sh` 通过（仅构建 HAP）；2026-10-22 已收敛为三环境；
- Stage 0 当时未迁移业务 Service、未删除旧 transport、未改 `HttpClient` / `HttpService` 行为。

**Stage 1-3 已完成（2026-10-21）**：

- `MihoyoApiService extends BaseApiService`，删除 5 个主 Service 与 `core/src/internal` overlay 的重复 `get / post`；
- 所有具体 API 显式 `response.data` 拆包，并在需要时显式调用 `reportBusinessError`；
- `AuthRepository` / `BBSRepository` 删除旧 transport fallback；`BBSRepository` 两个账号接口切到 `MihoyoAccountApiService`；
- `DeviceFpService` / `GeetestService` / `ZZZRecordRequest` 改用 `BaseApiService.shared`；
- 删除 `HttpClient` / `HttpService` / `NetworkFactory` / `LegacyBaseApiService`；
- 当时四个 product 构建、`test-core.sh` / `test-entry.sh` 通过；2026-10-22 已收敛为三环境；
- `grep` 验收：axios 仅命中 `BaseApiService.ets`，无旧 transport 代码引用，无直接 `return this.get/post`；
- header / retcode 基线、真实设备与 Mock 回归 **延后**，不阻塞本轮代码迁移。

内容：

- 抽 `BaseApiService`，作为构建链路内最终唯一 import / 调用 axios 的封装层
- `BaseApiService` 只做 axios 实例、超时、`get / post`、HTTP 状态码拦截和 HTTP 层日志
- Base 返回项目自己的 `HttpResponse { status, data }`；具体 API 自己取 `response.data`，不依赖 axios 类型
- 不做业务 `retcode`，不做 Geetest / 指纹上报；需要上报的具体 API 自己显式调用
- 保留 `MihoyoApiService` 抽象层：`MihoyoApiService extends BaseApiService`，5 个具体 Service 继续 `extends MihoyoApiService`
- 删除 5 个主 Service 和 `core/src/internal` overlay 重复的 `get / post`
- 迁移 `AuthRepository` / `BBSRepository` 的旧 transport，以及 `DeviceFpService` / `GeetestService` / `ZZZRecordRequest`
- 迁移完成后删除 `HttpClient` / `HttpService` / `NetworkFactory` / 旧抽象类
- 文件级清单、实施顺序和验收标准见 [`APIService.md`](APIService.md) 第 8 节
- **实施陷阱已补全**：
  - `HttpResponse` 是 `object` 子类型，类型检查不会拦住漏拆包，必须逐方法审计；
  - axios 默认对非 2xx reject，Base 必须从 `error.response` 取真实状态/body，不能全当网络错误；
  - `suppressGeetestReport` 当前同时抑制 Geetest + 指纹；`HttpClient` 和 `HttpService` 两套旧 transport 都会自动上报，迁移后按接口显式补；
  - `BBSRepository.getUserGameRoles` / `getGameRecordCard` 不是 fallback，原本一直走旧 transport；
  - `AuthRepository` fallback 与 service header 不等价；`HttpService` 在非 debug 下还会用拦截器覆盖调用方显式 Cookie；
  - 直接 `return this.get/post` 的 Service 方法不能只加 `.data`，还必须在 return 前显式调用上报 helper；
  - 原计划删除 `HttpClient` 前完成 [`API-Baseline.md`](API-Baseline.md) 的 header / retcode 基线；**用户已明确将采集推迟到整个任务完成后**，本轮不以此阻塞代码迁移；Base 日志不打印 Cookie / body，URL 要脱敏；
  - `test-core.sh` / `test-entry.sh` 只构建 HAP，真机 / Mock 回归不能省。
- **本轮保持原样（后续再改，已记录在 `APIService.md` §8.7）**：
  - `suppressGeetestReport` 继续同时抑制 Geetest + 指纹，不改名 / 不拆分；
  - BBS 三个接口继续保留现状上报行为（迁移后用显式 helper 复刻，旧 transport 已删除），待真实 retcode 基线后再决定。
  - `baseUrlType` 在 Phase 5 已确认无读取方并删除，不再属于保留项。
- **公共 Header 合并已实施**：`MihoyoHeaderBuilder` 管理 profile，`MihoyoApiService` 通过 `HeaderContext` + `prepareOptions` / `getWithProfile` / `postWithProfile` 合并公共 header 与具体 Service header；raw / passport / QR / 设备指纹 / Geetest 路径保持原 header。详见 [`APIService.md`](APIService.md) 第 10 节

代码迁移和旧链路删除已完成；基线 / 真机 / Mock 回归按用户决定延后到整个任务完成后补做。已知问题和暂缓项已统一记录在 [`Known-Issues.md`](Known-Issues.md)，不阻塞后续结构整理。

**Phase 1.2 第一批已完成（2026-10-21）**：

- 32 个共享文件已用 `git mv` 迁移：`base/network`（14）、`base/log`（4）、`base/errors`（1）、`base/utils`（4）、`base/cookie`（2）、`common/constants`（7）。
- 169 处相对 import 与 `core/Index.ets` 导出已更新；`core/src/internal` overlay import 同步更新；仅路径 / import 变更，不改 URL、header、DS、Cookie、retcode 或上报逻辑。
- 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因开发证书过期失败（见 `Known-Issues.md` E-01）；全量相对 import 解析检查 524 个、0 缺失。
- 原留在 `network/` 的游戏 / 账号专属 Service、Path 和 `MihoyoApiServiceFactory` 已在 Phase 2 迁入各 Kit / 根 `ApiServiceFactory.ets`，`network/` 目录已删除；`base/cookie` 与 `base/network` 的既存反向依赖已在 Phase 5 解决，见 `Known-Issues.md` S-01。
- 后续：Phase 2 已完成；`db/`、`sync/`、`common/material` 随 Phase 3 文件迁移落位，不单独提交空目录。

**Phase 2 GenshinKit 代码层已完成（2026-10-21）**：

- 13 个 Genshin 专属文件已用 `git mv` 迁入 `GenshinKit/`：`api`（ApiPath / ApiService）、`model`（Rows / CalcModels / CharacterDetailRaw）、`parser`（DailyNote / Compute）、`constants`（Element / PropertyType）、`db`（GenshinDao + RdbMigrationV4/V5）、`repository`（GenshinRepository）。
- 更新 53 处相对 import、`core/Index.ets` 导出、`MihoyoApiServiceFactory`、`CoreInitializer` 和测试 import；仅路径变更，不改请求行为。
- 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 仍因 E-01 失败；相对 import 解析检查 0 缺失。
- `base/network/GeetestService` 当时 import `GenshinKit/api/GenshinApiPath`，属于暂时反向依赖，Phase 5 已改为游戏配置注入；`database/RdbManager` 曾 import GenshinKit 的 V4/V5 migrations，该依赖已在 Phase 3C 移除。
- Genshin 的 `TableSchema` 片段、`GenshinMaterialBagDao` / `GenshinMaterialTargetConfigDao` 子类、material repository/model 已由 Phase 3 补齐；V4 中的星铁 material target config 跨 Kit 迁移也已在 Phase 3 完成。

**Phase 2 StarRailKit 代码层已完成（2026-10-21）**：

- 11 个 StarRail 专属文件已用 `git mv` 迁入 `StarRailKit/`：`api`（ApiPath / ApiService）、`model`（Rows / AvatarDetailRaw）、`parser`（DailyNote / Compute）、`constants`（Element / PropertyType）、`db`（StarRailDao / StarRailDBManager）、`repository`（StarRailRepository）。
- 更新 63 处相对 import、`core/Index.ets` 导出、`MihoyoApiServiceFactory`、`CoreInitializer` 和测试 import；仅路径变更，不改请求行为。
- 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 仍因 E-01 失败；相对 import 解析检查 0 缺失。
- `base/network/GeetestService` 当时同时 import GenshinKit / StarRailKit 的 ApiPath，属于 S-01 暂时反向依赖，Phase 5 已改为游戏配置注入；`MihoyoApiServiceFactory` 已指向新路径。
- StarRail 的 `TableSchema` 片段、`StarRailMaterialBagDao` / `StarRailMaterialTargetConfigDao` 子类、material repository/model 已由 Phase 3 补齐。

**Phase 2 ZZZKit 代码层已完成（2026-10-21）**：

- 14 个 ZZZ 专属文件已用 `git mv` 迁入 `ZZZKit/`：`api`（ApiPath / ApiService / ZZZRecordRequest）、`model`（Rows / AvatarDetailRaw）、`parser`（DailyNote / Compute）、`constants`（Element / Enums / PropertyId）、`db`（ZZZDao + RdbMigrationV2/V6）、`repository`（ZZZRepository）。
- 更新 67 处相对 import、`core/Index.ets` 导出、`MihoyoApiServiceFactory`、`CoreInitializer` 和测试 import；仅路径变更，不改请求行为。
- 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 仍因 E-01 失败；相对 import 解析检查 0 缺失。
- `base/network/ApiConfig` 和 `GeetestService` 当时 import `ZZZKit/api/ZZZRecordRequest` / `ZZZApiPath`，属于 S-01 暂时反向依赖，Phase 5 已移除；`database/RdbManager` 曾 import ZZZKit 的 V2/V6 migrations，该依赖已在 Phase 3C 移除；`MihoyoApiServiceFactory` 已指向新路径。
- ZZZ 的 `TableSchema` 片段、`ZZZMaterialBagDao` / `ZZZMaterialTargetConfigDao` 子类、material repository/model 已由 Phase 3 补齐。

**Phase 2 MihoyoKit 代码层已完成（2026-10-21）**：

- Mihoyo 账号域 18 个主文件已迁移：17 个用 `git mv` 迁入 `MihoyoKit/`——`api`（MihoyoAccountApiPath / MihoyoAccountApiService / PassportApiPath / QRCodeApiPath / SignApiPath / SignApiService，6）、`model`（AccountRow / GameRoleRow / BbsAccountModels / GameRoleModels / TokenModels / PhoneLoginModels / QRCodeLoginModels，7）、`db`（BBSDao，1）、`repository`（AuthRepository / BBSRepository / SignRepository，3）；另 1 个工厂文件迁到根。
- `network/MihoyoApiServiceFactory.ets` 已用 `git mv` 迁为根 `ApiServiceFactory.ets`；当时类名暂不改，Phase 5 已统一为 `ApiServiceFactory`。
- 3 个 internal overlay 已同步镜像到 `internal/ets/MihoyoKit/{api,repository,model}/`，与 main 保持相同相对路径；overlay import 按 main 路径计算，继续依赖 overlay 的同路径 fallback。
- 更新 123 处相对 import、`core/Index.ets` 导出、`CoreInitializer`、Genshin / StarRail / ZZZ 三个 Repository、base cookie / network 和测试 import；仅路径变更，不改 URL、header、DS、Cookie、retcode 或上报逻辑。
- 反向依赖（S-01）：当时 `base/cookie` import `MihoyoKit/repository/BBSRepository` / `MihoyoKit/model/AccountRow`；`base/network/GeetestService` import `MihoyoKit/api/MihoyoAccountApiPath`；`sync/SyncQueueRunner` import `MihoyoKit/model/GameRoleRow`；三个游戏 Repository 也 import `MihoyoKit/repository/BBSRepository`。Phase 3A / 3C 已迁移 sync 路径并移除 `RdbManager → Kit` 反向依赖，Phase 5 已通过迁移与注入解决剩余项。
- 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 仍因 E-01 失败；相对 import 解析检查 0 缺失。
- `TableSchema` 中的账号 / role 片段、material DAO 子类、material repository/model 已由 Phase 3 补齐；Phase 2 代码层完成。

**Phase 3A — sync / material 路径迁移（2026-10-21，`5aff4e4`）**：

- `GameRepository` / `SyncQueueRunner` 迁入 `sync/`；sync 模型迁入 `sync/model/`，`SyncMetaDao` 迁入 `sync/db/`。
- material 模型迁入 `common/material/model/`，`MaterialBagRepository` / `MaterialTargetConfigRepository` 迁入 `common/material/repository/`。
- 更新 53 处相对 import、`core/Index.ets` 和测试路径；移除空的顶层 `models/`、`repository/` 目录；未改 URL、header、DS、Cookie、retcode 或表结构。
- 验证：`default` / `debug` / `mock` 构建通过，`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因 E-01 失败；相对 import 解析 524 个、0 缺失。

**Phase 3B — material DAO 拆分（2026-10-21，`1fd097e`）**：

- `BaseMaterialBagDao` / `BaseMaterialTargetConfigDao` 留 `common/material/db/`；`GenshinMaterialBagDao`、`GenshinMaterialTargetConfigDao`、`StarRailMaterialBagDao`、`StarRailMaterialTargetConfigDao`、`ZZZMaterialBagDao`、`ZZZMaterialTargetConfigDao` 分别迁入各 Kit 的 `db/`。
- material repository、`MaterialBagDao.test` 和 `core/Index.ets` 改为从基类 / 对应 Kit 子类导入；删除旧 `database/MaterialBagDao.ets` / `MaterialTargetConfigDao.ets`。
- 验证：`default` / `debug` / `mock` 构建通过，`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因 E-01 失败；相对 import 解析 550 个、0 缺失。

**Phase 3C — TableSchema 拆分与 SchemaRegistry（2026-10-21，`47135c1`）**：

- `RdbManager` / `RsReader` 迁入 `db/`；V3 / V7 跨 Kit 迁移迁入 `db/migrations/cross/`。
- `TableSchema` 拆为 `db/TableName.ets`（表名枚举）、`db/TableSchema.ets`（`ColumnDef` / `TableDef` / `IndexDef`、`CommonCol` / `ComputeStateCol`、`FK_ACCOUNT`）、各游戏 Kit 的 `db/schema.ets`、`sync/db/schema.ets` 和 `common/material/db/schema.ets`（material 列枚举）。
- 根 `SchemaRegistry.ets` 聚合 24 张表、30 个索引和 V2~V7 迁移；`RdbManager.init(context, SchemaRegistry)` 改为接收注册表，`db/` 不再 import 任何 Kit；`CoreInitializer` 和 11 个测试调用同步更新。
- 静态等价检查：`ALL_TABLES` / `ALL_INDEXES` 顺序与旧 `TableSchema` 一致；24 个表定义、23 个枚举定义和 30 个索引定义逐项比对无差异；`GENSHIN_INDEXES` 仅用于 V4 / V5 按原条件筛选，实际执行的 DDL 未变。
- 验证：`default` / `debug` / `mock` 构建通过，`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，`SignHap` 因 E-01 失败；相对 import 解析 621 个、0 缺失。
- 未验证：`RdbManager.test` / DAO 测试的实际运行、旧版本 DB 文件升级路径、真机与 Mock 回归。`test-core.sh` / `test-entry.sh` 只构建 ohosTest HAP，不是运行测试。

---

## 7. 实施前确认

以下事项已经在 [`APIService.md`](APIService.md) 第 8 节写清：

1. 使用项目自己的 `HttpResponse { status, data }`，具体 API 自己取 `response.data`，不依赖 axios 类型。
2. Geetest / 指纹上报选择 B：具体 API 自己显式调用，Base 和 `MihoyoApiService` 都不自动上报。
3. 迁移并删除 `HttpClient` / `HttpService` / `NetworkFactory` / `APIs.ets` 旧抽象类。
4. `DeviceFpService` / `GeetestService` / `ZZZRecordRequest` 统一使用 `BaseApiService.shared`。
5. 非 200 统一抛 `HttpError`；网络错误 `statusCode = 0`，保留可读的 `message`。实现必须从 `error.response` 提取真实 HTTP 状态 / body，不能把所有 axios `catch` 都当网络错误。
6. `core/src/internal` overlay 同步修改；根目录 `internal/core` 是未参与构建的历史副本，本次不混改，建议迁移完成后单独清理。
7. BaseApiService 和旧链路清理已完成；`MihoyoApiService` 公共 Header 合并也已实施，具体见 [`APIService.md`](APIService.md) 第 10 节。
8. `HttpResponse` 漏拆包不能靠类型检查发现，Stage 1 必须逐方法审计并 grep 直接 `return this.get/post`。
9. `suppressGeetestReport` 当前同时抑制 Geetest + 指纹，且不抑制 retcode / 业务日志；Base 不再读取它。**本轮保持原样，不改名 / 不拆分**，后续再改（见 `APIService.md` §8.7）。上报归属按第 4.5 节逐接口确认。
10. `BBSRepository.getUserGameRoles` / `getGameRecordCard` 原本一直走旧 transport，切换到 account service 后要单独回归请求头 / DS；`mihoyo-api-sdk` 没有说明 BBS 三个接口需要 Geetest / 指纹，暂按现状保留上报行为（迁移后显式复刻），详见第 4.7 节。
11. `AuthRepository` fallback 与 service header 不等价（如 `text/plain` vs `application/json`），删除后以 service 为 canonical。
12. 原计划删除 `HttpClient` 前完成 [`API-Baseline.md`](API-Baseline.md) 的关键接口 header / retcode 基线；**用户已明确将采集延后到整个任务完成后，不阻塞本轮迁移**。Base 不打印 Cookie / 完整 body，URL query 要脱敏。采集方法见 [`APIService.md`](APIService.md) 第 8.6 节（Proxyman + 临时脱敏记录器）。
13. `test-core.sh` / `test-entry.sh` 只构建 HAP，不代表网络行为已测试；当前 `hdc` 有 target 时安装验证。
14. `baseUrlType` 已确认没有读取方，Phase 5 已删除；Mock 域名只通过 `MihoyoDomain` 切换，不再保留客户端 Mock 业务分支。
15. 直接 `return this.get/post` 的包装方法必须同时补 `.data` 拆包和显式上报 helper；不能只替换 `HttpClient`。`HttpService` 非 debug 拦截器会覆盖显式 Cookie，删除 fallback 后以 service 的显式 Cookie 为准。

**Stage 0-3 代码迁移已完成；当前不再以基线阻塞代码。** 已完成的构建 / grep 验收见本节 Stage 1-3 记录。后续按用户安排在任务完成后补采 [`API-Baseline.md`](API-Baseline.md) 的 header / retcode 基线，并做真实设备 / Mock 回归。`suppressGeetestReport`、BBS 三个接口的上报行为本轮保持原样，已记录在 `APIService.md` §8.7，后续再改；`baseUrlType` 已在 Phase 5 删除。

---

## 8. Phase 5 — 依赖反转与未使用文件清理（2026-10-22）

**依赖反转**

- `ColdStartCookieChecker` / `CookieRefreshCoordinator` 从 `base/cookie` 迁入 `MihoyoKit/cookie`；`CookieRefreshCoordinator.init(BBSRepository)` 由 `CoreInitializer` 注入，三个游戏 Repository 不再 import `CoreInitializer`。
- 新增 `sync/SyncPorts.ets`：`SyncAccountStore` / `GenshinSyncPort` / `StarRailSyncPort` / `ZZYSyncPort` / `SyncDependencies`。`SyncQueueRunner.init(SyncDependencies)` 由 `CoreInitializer` 注入，四个 Repository 显式实现对应接口。
- `GeetestService` 不再 import 各 Kit 的 ApiPath / `ZZZRecordRequest`；游戏配置由 `CoreInitializer.registerGame()` 注册，绝区零战绩 handler 实现 `GeetestRecordHandler` 后注入。
- `GameFpBiz` 从 `DeviceFpService` 移到 `base/network/GameFpBiz.ets`；`ApiConfig.regenerateDeviceFp()` 不再清理 ZZZ 指纹，entry `DeviceFpCenter.regenerate()` 在重新生成后调用 `ZZZRecordRequest.clearAll()`。
- `MihoyoApiServiceFactory` 类名统一为 `ApiServiceFactory`；删除 `RequestOptions.baseUrlType`；移除 `core/Index.ets` 中重复的 `GenshinPropertyType` 导出。

**清理**

- 删除 `core/src/main/ets/base/network/CookieManager.ets`。
- 删除 12 个不可达 entry 文件：`HomeRefreshButton`、`BottomTabItem`、`SidebarNavItem`、`CharacterMaterialCardHeader`、`CharacterMaterialItem`、`CharacterMaterialSection`、`AccountWidgetBlock`、`ThemeChip`、`WidgetSection`、`GenshinConstants`、`WidgetBackgroundSyncService`、`WidgetFormUtils`。
- 移除空的 `core/src/main/ets/{constants,database,parsers}` 与 `entry/src/main/ets/components/main` 目录。
- `core/BuildProfile.ets` 由 Hvigor 生成：从 Git 索引移除并加入 `.gitignore`，保留本地生成文件供构建使用。
- 根目录历史副本 `internal/core` 未改动。

**验证**

- `core@default assembleHar`、`entry@ohosTest`、`mock` debug、`uat` debug、`release` release 构建通过。
- `bash test-core.sh` 编译通过（只构建 ohosTest HAP，不执行测试）；新增 `core/src/test/MihoyoDomain.test.ets`，锁定 Mock `http://127.0.0.1:8787` / `BBS_APIHUB` `/apihub` 与 UAT / Release 官方域名契约；新增 `HeaderBuilder.test.ets`，覆盖 profile、覆盖、删除和不污染调用方 options 的合并规则。
- `node scripts/check-architecture.mjs`：0 import cycle、0 `base → Kit` 边、无旧符号 / 旧路径、无空源码目录、业务 Service 无直接 header builder 调用。
- 仍未验证：UAT / Mock 签名与安装、Mock REST 路由 / Swift-Vapor、真机 header / retcode、DB 升级与三环境回归。
