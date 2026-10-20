# Core Kits 重构任务总览

> 状态：**进行中**
> 当前阶段：**Mock 清理已完成；Phase 1.1 公共 APIService 方案待确认**
> 下一步：**确认 APIService 抽离范围后开始 Phase 1**
> 更新时间：2026-10-20

本目录集中存放整个 Core Kits 重构任务的规划、阶段记录和专题文档，避免 Mock、Kit、DB 等子任务的文档散落在仓库各处。

---

## 1. 任务目标

把 `core` 从「按文件类型平铺」重组为「按业务域分 Kit」：

1. 建立四个 Kit：`MihoyoKit`、`GenshinKit`、`StarRailKit`、`ZZZKit`
2. 统一网络入口：`BaseService` 作为唯一 HTTP 请求入口
3. DB 归类：游戏专属 DAO / schema / 迁移下沉到对应 Kit
4. Mock 服务化：fixtures 移出 HAP，保留独立 mock product；后续用 Swift-Vapor local service
5. 保持 `entry → core` 依赖方向不变，不拆多 HAR，不改 entry 的 MVVM 结构

完整设计见 [`Plan.md`](Plan.md)。

---

## 2. 文档索引

| 文档 | 内容 |
| --- | --- |
| [`Plan.md`](Plan.md) | 完整重构方案：目标结构、BaseService、DB 归类、阶段计划、风险 |
| [`APIService.md`](APIService.md) | 公共 APIService 抽离提案：现状、重复点、候选方案、迁移步骤、待确认问题 |
| [`Mock.md`](Mock.md) | Mock 部分：当前配置、已删除/保留内容、`mock-service` 契约、Swift-Vapor 迁移方案、缺口清单 |

后续如果新增 Kit / DB / 迁移记录，也放在本目录，不单独建 `Documents/Mock/` 之类的子任务目录。

---

## 3. 阶段状态

| 阶段 | 状态 | 说明 |
| --- | --- | --- |
| Phase 0 — 基线 | ✅ 已完成 | 四个 product（`default` / `mock` / `debug` / `internal`）构建通过；`test-core.sh` / `test-entry.sh` 通过 |
| Phase 1 — 底盘 | 🟡 方案阶段 | 先抽公共 APIService；方案见 [`APIService.md`](APIService.md)，确认后再建 `base/ common/ db/ sync/` 骨架 |
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
- [ ] **App 侧 base URL 覆盖点未实现**：预计在 `ApiConfig` / `BaseService` 集中处理
- [ ] **真机 / 模拟器 mock 数据联调未做**
- [ ] **Swift-Vapor 与 Node 的 parity 测试未建立**
- [ ] **fixture 缺口未补**：签到、ZZZ `avatar_compute`、原神/星铁账号级 Widget
- [ ] **local service 启动 / 停止脚本未做**
- [ ] **最终 README 未更新**：按约定等全部整合完成后统一更新

---

## 6. 下一步

按 `Plan.md` 的阶段顺序，Mock 清理完成后先做 **Phase 1.1 公共 APIService**：

**Phase 1.1 — 公共 APIService（方案待确认）**

内容：

- 让 `MihoyoApiService` 成为真正可复用的公共请求基类
- 删除 5 个具体 Service 重复的 `get / post`
- 评估是否同步删除 `HttpService` / `NetworkFactory` 和 Repository fallback
- 评估是否把 main/internal 重复的账号 Service / `AuthRepository` 拆成公共 base + internal 扩展
- 方案与待确认问题见 [`APIService.md`](APIService.md)

确认方案后，再进入 Phase 1.2：建 `base/ common/ db/ sync/` 骨架、迁移共享文件、`HttpClient` → `BaseService`。

---

## 7. 待确认

**请先确认 [`APIService.md`](APIService.md) 第 10 节的 8 个问题**，尤其是：

1. “公共 APIService”指公共请求基类，还是公共账号 Service，还是两者都要？
2. 本次是否只做“请求基类 + 单入口”，账号分层另开任务？
3. 是否允许删除 `HttpService` / `NetworkFactory` 和 Repository fallback？
4. 是否借这次一起做“release 剔除手机号登录”？

确认后再开始改代码。
