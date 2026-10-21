# Core Kits 重构任务总览

> 状态：**Stage 0-3 代码迁移完成；header / retcode 静态参考对照完成，运行时基线延后**
> 当前阶段：**旧 transport 已删除；四个 product 构建、`test-core.sh` / `test-entry.sh` 通过；已用 mihoyo-api-sdk / TeyvatGuide / PizzaHelperUnited 和本项目历史抓包完成静态对照；运行时 baseline 未采集（用户明确推迟到整个任务完成后）**
> 下一步：**进入 Phase 1.2 目录骨架整理；已知问题和运行时候补项见 [`Known-Issues.md`](Known-Issues.md)**
> 更新时间：2026-10-21

本目录集中存放整个 Core Kits 重构任务的规划、阶段记录和专题文档，避免 Mock、Kit、DB 等子任务的文档散落在仓库各处。

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
| [`APIService.md`](APIService.md) | `BaseApiService` 抽离方案：axios 唯一封装层、继承关系、HTTP 状态边界、已确认事项、文件级迁移/删除清单、上报审计表、直接 return 上报漏点、Cookie 覆盖、实施陷阱；第 10 节记录后续公共 Header 合并 |
| [`API-Baseline.md`](API-Baseline.md) | 旧 transport 迁移前后的 API header / retcode 基线清单：按登录、BBS、三游戏、签到、设备指纹 / Geetest 分组，列出触发入口、当前 header、待填字段和完成标准；§2.2 已补三个项目 + 历史抓包的静态对照；运行时 **未采集（延后）** |
| [`Known-Issues.md`](Known-Issues.md) | 已知问题与暂缓项：header / retcode 未采集、参考冲突、当前不改的参考差异、Phase 1.2 边界与真机回归清单 |
| [`Mock.md`](Mock.md) | Mock 部分：当前配置、已删除/保留内容、`mock-service` 契约、Swift-Vapor 迁移方案、缺口清单 |

后续如果新增 Kit / DB / 迁移记录，也放在本目录，不单独建 `Documents/Mock/` 之类的子任务目录。

---

## 3. 阶段状态

| 阶段 | 状态 | 说明 |
| --- | --- | --- |
| Phase 0 — 基线 | 🟡 构建基线完成；静态参考完成；运行时基线延后 | 四个 product（`default` / `mock` / `debug` / `internal`）构建通过；`test-core.sh` / `test-entry.sh` 通过（仅构建 ohosTest HAP，不是网络测试）；header / retcode 清单和 §2.2 静态参考矩阵已建在 [`API-Baseline.md`](API-Baseline.md)，运行时 **未采集（用户决定延后，不阻塞迁移）** |
| Phase 1 — 底盘 | ✅ Stage 0-3 代码迁移完成；Phase 1.2 待开始 | 新增 `HttpTypes` / `BaseApiService`；5 个业务 Service + internal overlay 已继承并完成 `.data` 拆包；`AuthRepository` / `BBSRepository` / `DeviceFpService` / `GeetestService` / `ZZZRecordRequest` 已迁移；旧 `HttpClient` / `HttpService` / `NetworkFactory` / `LegacyBaseApiService` 已删除；四产品和两个测试脚本构建通过；基线 / 真机回归待补，见 [`Known-Issues.md`](Known-Issues.md) |
| Phase 2 — 拆 Kit | ⏳ 未开始 | 按 Genshin → StarRail → ZZZ → Mihoyo 顺序拆 Kit |
| Phase 3 — DB 收尾 | ⏳ 未开始 | `TableName` 抽离、跨 Kit 迁移、`SchemaRegistry` 聚合 |
| Phase 4 — Mock | 🟡 部分完成 | 清理、独立 mock product、脚本、Node mock-service 已完成；Swift-Vapor local service 与 App 接入未完成 |
| Phase 5 — 收尾 | ⏳ 未开始 | 命名统一、删除兼容别名、最终更新 README / 文档 / CI |

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
- 四个 product 构建通过，`test-core.sh` / `test-entry.sh` 通过

---

## 5. Mock 部分缺口

以下内容尚未完成，已记录在 [`Mock.md`](Mock.md)，后续不能误认为 mock 数据链路已经可用：

- [ ] **Swift-Vapor local service 未实现**
- [ ] **App 未连接 local service**：当前 mock 包仍走真实 API，不返回 fixture 数据
- [ ] **接入方案未最终确定**：直连路径代理 vs RPC（推荐直连路径代理）
- [ ] **App 侧 base URL 覆盖点未实现**：预计在 `ApiConfig` / `BaseApiService` 集中处理
- [ ] **真机 / 模拟器 mock 数据联调未做**
- [ ] **Swift-Vapor 与 Node 的 parity 测试未建立**
- [ ] **fixture 缺口未补**：签到、ZZZ `avatar_compute`、原神/星铁账号级 Widget
- [ ] **local service 启动 / 停止脚本未做**
- [ ] **最终 README 未更新**：按约定等全部整合完成后统一更新

---

## 6. 下一步

按 `Plan.md` 的阶段顺序，Mock 清理完成后先做 **Phase 1.1 BaseApiService**：

**Phase 1.1 — BaseApiService（Stage 0-3 已完成；基线 / 真机回归延后）**

**Stage 0 已完成（2026-10-20）**：

- 新增 `core/src/main/ets/network/HttpTypes.ets`、`BaseApiService.ets`；
- `APIs.ets` 旧抽象临时改名 `LegacyBaseApiService`，`HttpService` / `NetworkFactory` 引用已切换；
- `core/Index.ets` 已导出 `HttpTypes` / `BaseApiService`；
- 四个 product 构建通过，`test-core.sh` / `test-entry.sh` 通过（仅构建 HAP）；
- Stage 0 当时未迁移业务 Service、未删除旧 transport、未改 `HttpClient` / `HttpService` 行为。

**Stage 1-3 已完成（2026-10-21）**：

- `MihoyoApiService extends BaseApiService`，删除 5 个主 Service 与 `core/src/internal` overlay 的重复 `get / post`；
- 所有具体 API 显式 `response.data` 拆包，并在需要时显式调用 `reportBusinessError`；
- `AuthRepository` / `BBSRepository` 删除旧 transport fallback；`BBSRepository` 两个账号接口切到 `MihoyoAccountApiService`；
- `DeviceFpService` / `GeetestService` / `ZZZRecordRequest` 改用 `BaseApiService.shared`；
- 删除 `HttpClient` / `HttpService` / `NetworkFactory` / `LegacyBaseApiService`；
- 四个 product 构建、`test-core.sh` / `test-entry.sh` 通过；
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
  - `baseUrlType` 继续保留，不删除 / 不改造；
  - BBS 三个接口继续保留现状上报行为（迁移后用显式 helper 复刻，旧 transport 已删除），待真实 retcode 基线后再决定。
- **不在本次实施**：`MihoyoApiService` 公共 Header 合并。Header 由独立 Header 抽象类（名称待定）管理，`MihoyoApiService` 负责合并公共 header + 具体 Service header；等所有 ApiService 整理完后作为 Phase 5 收尾项做，详见 [`APIService.md`](APIService.md) 第 10 节

代码迁移和旧链路删除已完成；基线 / 真机 / Mock 回归按用户决定延后到整个任务完成后补做。已知问题和暂缓项已统一记录在 [`Known-Issues.md`](Known-Issues.md)，不阻塞后续结构整理。下一步进入 **Phase 1.2**：先建 `base/ common/ db/ sync/` 骨架，再按 `Plan.md` §3.3 的共享文件清单用 `git mv` 迁移；先不改业务请求行为。

---

## 7. 实施前确认

以下事项已经在 [`APIService.md`](APIService.md) 第 8 节写清：

1. 使用项目自己的 `HttpResponse { status, data }`，具体 API 自己取 `response.data`，不依赖 axios 类型。
2. Geetest / 指纹上报选择 B：具体 API 自己显式调用，Base 和 `MihoyoApiService` 都不自动上报。
3. 迁移并删除 `HttpClient` / `HttpService` / `NetworkFactory` / `APIs.ets` 旧抽象类。
4. `DeviceFpService` / `GeetestService` / `ZZZRecordRequest` 统一使用 `BaseApiService.shared`。
5. 非 200 统一抛 `HttpError`；网络错误 `statusCode = 0`，保留可读的 `message`。实现必须从 `error.response` 提取真实 HTTP 状态 / body，不能把所有 axios `catch` 都当网络错误。
6. `core/src/internal` overlay 同步修改；根目录 `internal/core` 是未参与构建的历史副本，本次不混改，建议迁移完成后单独清理。
7. 本次只做 BaseApiService 和旧链路清理；`MihoyoApiService` 公共 Header 合并延后，等所有 ApiService 整理完再做。
8. `HttpResponse` 漏拆包不能靠类型检查发现，Stage 1 必须逐方法审计并 grep 直接 `return this.get/post`。
9. `suppressGeetestReport` 当前同时抑制 Geetest + 指纹，且不抑制 retcode / 业务日志；Base 不再读取它。**本轮保持原样，不改名 / 不拆分**，后续再改（见 `APIService.md` §8.7）。上报归属按第 4.5 节逐接口确认。
10. `BBSRepository.getUserGameRoles` / `getGameRecordCard` 原本一直走旧 transport，切换到 account service 后要单独回归请求头 / DS；`mihoyo-api-sdk` 没有说明 BBS 三个接口需要 Geetest / 指纹，暂按现状保留上报行为（迁移后显式复刻），详见第 4.7 节。
11. `AuthRepository` fallback 与 service header 不等价（如 `text/plain` vs `application/json`），删除后以 service 为 canonical。
12. 原计划删除 `HttpClient` 前完成 [`API-Baseline.md`](API-Baseline.md) 的关键接口 header / retcode 基线；**用户已明确将采集延后到整个任务完成后，不阻塞本轮迁移**。Base 不打印 Cookie / 完整 body，URL query 要脱敏。采集方法见 [`APIService.md`](APIService.md) 第 8.6 节（Proxyman + 临时脱敏记录器）。
13. `test-core.sh` / `test-entry.sh` 只构建 HAP，不代表网络行为已测试；当前 `hdc` 有 target 时安装验证。
14. `baseUrlType` 目前仍是 no-op；`HttpService` 删除后已没有读取方。**本轮保持字段原样，不删除 / 不改造**；等 Phase 4 Mock base URL 方案确定后再处理（见 `APIService.md` §8.7）。
15. 直接 `return this.get/post` 的包装方法必须同时补 `.data` 拆包和显式上报 helper；不能只替换 `HttpClient`。`HttpService` 非 debug 拦截器会覆盖显式 Cookie，删除 fallback 后以 service 的显式 Cookie 为准。

**Stage 0-3 代码迁移已完成；当前不再以基线阻塞代码。** 已完成的构建 / grep 验收见本节 Stage 1-3 记录。后续按用户安排在任务完成后补采 [`API-Baseline.md`](API-Baseline.md) 的 header / retcode 基线，并做真实设备 / Mock 回归。`suppressGeetestReport`、`baseUrlType`、BBS 三个接口的上报行为本轮保持原样，已记录在 `APIService.md` §8.7，后续再改。
