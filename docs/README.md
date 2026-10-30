# entry 模块分析索引

> **覆盖范围**：`entry/src/main/ets` 全部 **349 个 `.ets`** = 29 页面 + 195 组件 + 24 ViewModel（`viewmodel/`）+ 40 widget 文件（含 4 个 widget ViewModel）+ 52 共享层（utils/models/constants/theme/config/styles/builders）+ 5 通知服务 + 4 ability；另含 `module.json5` 契约与 `entry/src/test` 的 20 个测试文件
> **文档数量**：20 份单页面分析 + 3 份家族/模板合并分析 + 4 份跨层/子系统分析 + 3 份专项（去重/组件索引/测试套件）= **30 份**
> **最后更新**：2026-10-26（全目录逐份复核）
> **评分口径**：`skills/harmonyos-review` 官方 A-F 评级（统一，见第 1 节）
> **配套方案**：重构执行以 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) 为准（模块划分、契约冻结、缺陷分诊见其 §4 / §11）

---

## 1. 评分口径

### 1.1 评级规则（来自 skills 包）

| 评级 | 条件 |
| --- | --- |
| **A** | 0 Critical + 0 High，且 Medium ≤ 5 |
| **B** | 0 Critical + High ≤ 3 |
| **C** | 0 Critical + High ≤ 8 |
| **D** | Critical ≤ 1 + High ≤ 12 |
| **F** | Critical > 1，或综合阻断上架 |

**优先级定义**（同 skills `references/report-template.md`）：

| 级别 | 含义 |
| --- | --- |
| **Critical** | 阻断上架 / 安全漏洞 / 数据丢失 |
| **High** | 影响功能可靠性，发版前必修 |
| **Medium** | 技术债，下个迭代修 |
| **Low** | 锦上添花 |

### 1.2 为什么废弃百分制

本目录早期文档存在 **3 套互不兼容的打分体系**，分数无法横向比较：

| 体系 | 示例 | 问题 |
| --- | --- | --- |
| 6 维 20 分制 | `架构 17/20 + ArkTS 18/20 + ...` | 不同文档维度数不同；出现 `代码质量 6/5`、`性能 15/18` 等非法分值 |
| 10 分制子项 | `ArkTS 评分 7/10`、`安全评分 7.5/10` | 与 20 分制混用；折算成 100 分时权重未定义 |
| 45/15/20/15/5 | `ArkTS 45 + 命名 15 + ...` | 无"异常处理"维度，导致带缺陷的页面反而得高分 |

**现已全部迁移到 skills 官方 A-F 口径**，原百分数仅在各文档的执行摘要中作为历史参考保留一行。

### 1.3 技术债点数（辅助排序指标）

```
债务点数 = High × 3 + Medium × 2 + Low × 1
密度     = 债务点数 ÷ (源文件行数 / 100)
```

> 债务点数衡量**绝对工作量**，密度衡量**单位代码的风险浓度**。两者都不参与评级，仅用于排优先级。

### 1.4 统计范围（口径边界）

| 范围 | 是否计入页面评级 | 说明 |
| --- | --- | --- |
| `entry/src/main/ets` 产品代码 | ✅ 计入 | C / H / M / L 与债务点数只统计这里 |
| `entry/src/test` 测试资产 | ❌ 不计入 | 测试自身的缺陷（引用不存在的符号 / 方法 / 模块）统一由 [test-suite-analysis.md](./test-suite-analysis.md) 汇总；页面文档提到它时只作为「验收前提」，不改变该页评级 |
| `module.json5` / `form_config.json` / `custom_router_map.json` 等配置 | ✅ 计入所属模块 | 与代码同属一份契约的配置缺陷，算在对应模块（Ability / Widget / 路由宿主）内 |

> 这条边界是为了防止同一处测试缺陷在页面文档与测试专项里各记一次，导致全目录重复计数。
>
> **TEST-001（核心逻辑缺单测）也不计入 L**：它描述的是覆盖缺口而非代码缺陷，只写在「合规检查」与第 4 节第 4 点，避免把没有测试的模块集体抬高债务点数。

---

## 2. 文档总览（按债务点数降序）

| 模块 | 页面 / 文件 | 分析文档 | 评级 | C | H | M | L | 源行数 | 债务点数 | 密度/百行 |
|---|---|---|---|---|---|---|---|---|---|---|
| 应用框架 | `MainPage.ets` | [main-module-analysis.md](./main-module-analysis.md) | **B** | 0 | 2 | 11 | 5 | 513 | 33 | 6.4 |
| **共享层 (M0)** | `utils/ models/ constants/ theme/ config/ styles/ builders/`（52 文件）+ `components/common/`（2）+ `SnackbarContent` | [shared-layer-modules-analysis.md](./shared-layer-modules-analysis.md) | **B** | 0 | 0 | 8 | 9 | 4795 | 25 | 0.52 |
| **Widget 子系统 (M14)** | `WidgetProvider/Service + Widget1x2/2x2/4x4`（6 页） | [widget-subsystem-modules-analysis.md](./widget-subsystem-modules-analysis.md) | **B** | 0 | 3 | 6 | 3 | — | 24 | — |
| **通知服务层 (M5)** | `features/notification/.../model/`（5 文件） | [notification-service-modules-analysis.md](./notification-service-modules-analysis.md) | **B** | 0 | 0 | 8 | 4 | 1061 | 20 | 1.9 |
| 首页 | `HomePage.ets` | [home-module-analysis.md](./home-module-analysis.md) | **B** | 0 | 0 | 6 | 5 | 185 | 17 | 9.2 |
| 工具页 | `ToolsPage.ets` | [tools-module-analysis.md](./tools-module-analysis.md) | **B** | 0 | 1 | 4 | 2 | 132 | 13 | 9.8 |
| **Ability (M15)** | `EntryAbility.ets / EntryBackupAbility.ets` | [ability-and-startup-modules-analysis.md](./ability-and-startup-modules-analysis.md) | **A** | 0 | 0 | 4 | 4 | — | 12 | — |
| 登录 | `LoginPage.ets` | [login-module-analysis.md](./login-module-analysis.md) | **A** | 0 | 0 | 4 | 2 | 129 | 10 | 7.8 |
| 角色详情·星铁 | `StarRailCharacterDetailPage.ets` | [starrail-character-detail-module-analysis.md](./starrail-character-detail-module-analysis.md) | **B** | 0 | 2 | 1 | 2 | 140 | 10 | 7.1 |
| 角色列表 | `CharactersPage.ets` | [characters-module-analysis.md](./characters-module-analysis.md) | **B** | 0 | 1 | 2 | 2 | 167 | 9 | 5.4 |
| 外观设置 | `AppearanceSettingsPage.ets` | [appearance-settings-page-module-analysis.md](./appearance-settings-page-module-analysis.md) | **B** | 0 | 1 | 2 | 1 | 145 | 8 | 5.5 |
| 角色详情·原神 | `GenshinCharacterDetailPage.ets` | [genshin-character-detail-module-analysis.md](./genshin-character-detail-module-analysis.md) | **B** | 0 | 1 | 1 | 2 | 154 | 7 | 4.5 |
| 角色详情·ZZZ | `ZZZCharacterDetailPage.ets` | [zzz-character-detail-module-analysis.md](./zzz-character-detail-module-analysis.md) | **B** | 0 | 1 | 1 | 2 | 140 | 7 | 5.0 |
| 材料选角色 | `MaterialCharacterSelectPage.ets` | [material-character-select-module-analysis.md](./material-character-select-module-analysis.md) | **A** | 0 | 0 | 2 | 3 | 493 | 7 | 1.4 |
| 目标配置×3 | `Genshin/StarRail/ZZZMaterialTargetConfigPage.ets` | [material-target-config-modules-analysis.md](./material-target-config-modules-analysis.md) | **A** | 0 | 0 | 2 | 1 | 1098 | 5 | 0.5 |
| 我的 | `MyPage.ets` | [my-module-analysis.md](./my-module-analysis.md) | **A** | 0 | 0 | 2 | 1 | 150 | 5 | 3.3 |
| 日常详情×3 | `Genshin/StarRail/ZZZDailyDetailPage.ets` | [daily-detail-modules-analysis.md](./daily-detail-modules-analysis.md) | **A** | 0 | 0 | 1 | 2 | 383 | 4 | 1.0 |
| 材料计算 | `MaterialCalcPage.ets` | [material-calc-module-analysis.md](./material-calc-module-analysis.md) | **B** | 0 | 1 | 4 | 3 | 111 | 14 | 12.6 |
| 材料清单×3 | `Genshin/StarRail/ZZZMaterialListPage.ets` | [material-list-modules-analysis.md](./material-list-modules-analysis.md) | **A** | 0 | 0 | 1 | 2 | 558 | 4 | 0.7 |
| 账号详情 | `AccountDetailPage.ets` | [account-detail-module-analysis.md](./account-detail-module-analysis.md) | **A** | 0 | 0 | 1 | 1 | 148 | 3 | 2.0 |
| 小组件设置 | `WidgetSettingsPage.ets` | [widget-settings-module-analysis.md](./widget-settings-module-analysis.md) | **A** | 0 | 0 | 1 | 1 | 65 | 3 | 4.6 |
| 隐私同意 | `PrivacyConsentPage.ets` | [privacy-consent-page-module-analysis.md](./privacy-consent-page-module-analysis.md) | **A** | 0 | 0 | 1 | 1 | 113 | 3 | 2.7 |
| 通知设置 | `NotificationSettingsPage.ets` | [notification-settings-module-analysis.md](./notification-settings-module-analysis.md) | **A** | 0 | 0 | 1 | 0 | 40 | 2 | 5.0 |
| 启动页 | `LaunchPage.ets` | [launch-module-analysis.md](./launch-module-analysis.md) | **A** | 0 | 0 | 0 | 2 | 94 | 2 | 2.1 |
| 入口 | `Index.ets` | [index-module-analysis.md](./index-module-analysis.md) | **A** | 0 | 0 | 0 | 2 | 34 | 2 | 5.9 |
| WebView | `WebViewPage.ets` | [webview-page-module-analysis.md](./webview-page-module-analysis.md) | **A** | 0 | 0 | 0 | 2 | 101 | 2 | 2.0 |
| 测试页 | `TestPage.ets` | [test-page-module-analysis.md](./test-page-module-analysis.md) | **A** | 0 | 0 | 0 | 2 | 106 | 2 | 1.9 |

**专项文档**（不计入评级）：

- [project-structure.md](./project-structure.md) —— **当前**工程目录结构（2026-10-29 结构迁移完成后，逐文件注释、模块依赖、路由、资源分布）
- [structure-migration-plan.md](./structure-migration-plan.md) —— 结构迁移计划与执行记录、待办（Local Test、全量冒烟、29 份文档复核）
- [naming-conventions.md](./naming-conventions.md) —— entry 命名规范（依据 OpenHarmony《ArkTS 编程规范》与官方 codelabs）
- [naming-rename-map.md](./naming-rename-map.md) —— 2026-10-28 全量改名映射（文件 / 类型 / 常量 / 布尔 / 方法 / 资源 / 测试）；本目录文档中的文件名已按此表更新，`file:line` 行号仍为基线 `105c8d3`

- [component-deduplication-review.md](./component-deduplication-review.md) —— 跨页面组件重复度审查与整合方案
- [components-inventory-analysis.md](./components-inventory-analysis.md) —— 195 个组件 / 14,931 行的全量索引与归属
- [test-suite-analysis.md](./test-suite-analysis.md) —— `entry/src/test` 20 文件 / 286 用例的覆盖矩阵与红色基线

---

## 3. 整改优先级

### P0 · 立即：无

> 2026-10-24 复核：本目录曾经唯一的 D 级 `Login` 已撤销，现无 Critical、无 D 级模块。
>
> - `LoginViewModel.ets:350` 的 catch 只记录 `error.message`，不引用 cookie 变量；`BBSRepository.ets:482/501` 的抛错只含 `retcode` + 服务端 `message`；`AuthRepository.ets:225` 只记 cookie 长度。**没有凭据落盘的现行路径**，原 SEC-002「Critical」降为 Medium 加固。
> - 原 High「二维码轮询无取消标记」已在 `b98abae` 修复（`qrGeneration` + `pollInFlight`），同样撤回。
> - 两项撤回后 `Login` 由 D 升为 A，债务点数 8 → 10（4 Medium + 2 Low）。
>
> 详见 [login-module-analysis.md](./login-module-analysis.md) 的「安全项复核」一节。

### P1 · 本迭代（High 集中区）

| 模块 | High 数 | 核心问题 |
| --- | --- | --- |
| `MainPage.ets` | 2 | 人机验证弹窗关闭时无 callback 地 `off('windowSizeChange')`，首次验证后折叠屏单双栏不再切换；用返回手势 / 侧滑关闭验证框后验证队列永久卡死（10-29 复核恢复，10-27 的撤回理由漏了这条关闭路径） |
| `StarRailCharacterDetailPage.ets` | 2 | `parseRawJson` 异常分支未设 `ViewState.ERROR`（用户看到空白）；`entityId === '1510'` 调试残留 |
| `Widget 子系统`（6 页） | 3 | 更新瞬时失败会永久删除用户的卡片配置；无数据时展示 Mock 账号与体力；卡片从不显示数据新鲜度 |
| `CharactersPage.ets` | 1 | 11 个 `@Monitor` 密集使用，易产生竞态 |
| `ToolsPage.ets` | 1 | `loadData()` 无取消标记，页面销毁后仍改写状态 |
| `GenshinCharacterDetailPage.ets` | 1 | `parseRawJson` 异常分支未设 `ERROR`（与星铁同源问题） |
| `ZZZCharacterDetailPage.ets` | 1 | `parseRawJson` 吞异常后仍进入 `DATA`，解析失败时空白页（三游同源） |
| `AppearanceSettingsPage.ets` | 1 | `applyColorMode()` 异步失败后仍 `pop()`，用户无感知 |

**不计入 High、但值得顺手做的加固**：`LoginPage.ets` 的失败日志（`LoginViewModel.ets:350`）改成不拼接可变 `error.message` 的格式，15 分钟，可与 M12 目录调整一并提交。

### P2 · 下迭代（Medium 集中区）

`MainPage.ets` 的 11 项技术债（工具栏 hack、10 字段回调协议、魔数 `4`、分栏宽度参数矛盾、`windowClass` 一次性读取、Cookie 过期弹框叠加、窗口 API 未包 try、Tab 根页按返回可能显示空白（待真机确认）、10 处空 catch 静默吞异常等，M1-M11）建议与 M15（框架模块）重构计划合并处理。

`HomePage.ets` / `HomeViewModel.ets` 的 6 项技术债（`isAutoSync` 不复位且部分失败仍报成功、三级 ForEach key 覆盖不全、VM 728 行 10 种职责、20 个无读取方的游戏专属字段、4 处空 catch + 6 处空 `.catch`、三层 ForEach）建议随 M8（Home 重构）处理；L4 / L5（迁移残留、未使用的 `widgetbase` 依赖）可顺手清理。

> 复核调整：`MyPage.ets`（`@Param` 默认实例父组件始终传参）、`NotificationSettingsPage.ets`（`context=null` 已有空值保护，不崩溃）、`WidgetSettingsPage.ets`（`init()` 内部已 catch，不会永久 Loading）三项原 High 按实际影响降为 Medium，已从 P1 移出。

### 观察项（高密度但体量小）

- `NotificationSettingsPage.ets` 密度 5.0、`Index.ets` 密度 5.9 —— 单文件只有 34-40 行，一个 Medium 就能把密度拉高。这类"小文件高密度"通常修复成本极低，可作为碎片时间任务。

---

## 4. 文档深度说明（已知局限）

| 类别 | 文档 | 说明 |
| --- | --- | --- |
| **深度分析** | Main、Home、Characters、Tools、Login、My | 含结构树、依赖清单、机制剖析、逐条 `file:line` |
| **标准分析** | 其余 14 份页面级独立文档 | 含结构树、合规检查、风险清单，证据锚点较少 |
| **系统层分析** | 共享层（M0）、通知服务层（M5）、Ability & 启动链路（M15）、Widget 子系统（M14） | 按文件清单 + 中心节点 + 调用链组织；共享层为 55 文件 4,795 行（含 `components/common/` 2 个与 `SnackbarContent`），服务层 5 文件 1,061 行 |
| **家族合并分析** | MaterialList×3、MaterialTargetConfig×3、DailyDetail×3、Widget 子系统×6 | 一份文档覆盖多份高度雷同的模板代码，行数按文件合计（widget 为 6 页 596 行，另含 4 VM / 10 组件 / 4 模型 / 16 工具与 2 个 ability，共 42 文件 7,494 行） |
| **专题** | component-deduplication-review、components-inventory-analysis、test-suite-analysis | 跨页面 / 全局索引维度，不重复单页结论；组件索引覆盖 195 文件 14,931 行，测试索引覆盖 20 文件 286 用例 |

**需要说明的四点**：

1. **深度不完全一致**。早期文档（Home / Characters）用 12 章节模板，中期为控制生成长度压缩到 7 章节，导致部分文档偏薄。**2026-10-26 复核已统一章节骨架与计数口径**：27 份模块文档（20 单页 + 3 家族 + 4 系统层）均含「执行摘要（C/H/M/L）→ 文件/组件清单 → 结构或调用链 → 合规检查 → 风险清单 → 重构执行备注」，并逐份重算了行数、计数与 `file:line` 锚点；Login / Tools / My / Main 四份补齐了缺失的「合规检查」章节，Home 补齐后新增 1 条 Medium（首页组件反向依赖 widget；2026-10-29 结构迁移把 `UserGameSection` 迁入 `common/basic` 并改为 `roleBuilder` 插槽，该 Medium 已解除）。
2. **证据锚点已机器化核对**：全部文档引用的 `*.ets:行号` 均落在真实文件与行数范围内，引用的文件路径全部存在；表格里的「文件名 → 行数」逐行与 `wc -l` 对过（30/30 一致）。复核方法见文末《7. 全目录复核记录》。
3. **债务点数为人工分类**，不是 `codeLinter` 或静态工具输出。同一问题在不同文档中可能被判为 High 或 Medium（例如"异步失败后仍照常推进"在 `AppearanceSettingsPage` 记为 High——用户会被 `pop()` 带走且无任何提示；在 `PrivacyConsentPage` 记为 Medium——用户看到的是正常进入主界面），判断依据是**用户是否能感知到故障**。跨文档横向比较时请以评级为准，不要逐一对比点数值。
4. **评级不代表有测试保护**。`entry/src/test` 的 Local Test 只覆盖 24 个 ViewModel 中的 10 个（AccountDetail / Characters / GenshinCharacterDetail / GenshinDailyDetail / Home / Login / MaterialCalc / My / PrivacyConsent / Tools）；AppearanceSettings、NotificationSettings、WidgetConfig、StarRail·ZZZ CharDetail、StarRail·ZZZ Dailynote、MaterialCharacterSelect、MaterialList / MaterialTargetConfig 以及框架页**没有单测**。A 级只说明代码问题少，不代表重构后能被测试接住。完整矩阵（含 286 条用例与当前红色基线）见 [test-suite-analysis.md](./test-suite-analysis.md)。

---

## 5. 重构模块映射

[`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) 的模块 ID 与本文档的对应关系（执行顺序 M0 → M15）：

| M | 模块 | 分析文档 |
|---|---|---|
| M0 | 共享层 | [shared-layer-modules-analysis.md](./shared-layer-modules-analysis.md) |
| M1 | Tools | [tools-module-analysis.md](./tools-module-analysis.md) |
| M2 | PrivacyConsent | [privacy-consent-page-module-analysis.md](./privacy-consent-page-module-analysis.md) |
| M3 | AppearanceSettings | [appearance-settings-page-module-analysis.md](./appearance-settings-page-module-analysis.md) |
| M4 | My | [my-module-analysis.md](./my-module-analysis.md) |
| M5 | Notification | [notification-settings-module-analysis.md](./notification-settings-module-analysis.md) / [notification-service-modules-analysis.md](./notification-service-modules-analysis.md) |
| M6 | Dailynote | [daily-detail-modules-analysis.md](./daily-detail-modules-analysis.md) |
| M7 | MaterialCalc | [material-calc-module-analysis.md](./material-calc-module-analysis.md) / [material-list-modules-analysis.md](./material-list-modules-analysis.md) / [material-target-config-modules-analysis.md](./material-target-config-modules-analysis.md) / [material-character-select-module-analysis.md](./material-character-select-module-analysis.md) |
| M8 | Home | [home-module-analysis.md](./home-module-analysis.md) |
| M9 | Characters | [characters-module-analysis.md](./characters-module-analysis.md) |
| M10 | CharDetail | [genshin-character-detail-module-analysis.md](./genshin-character-detail-module-analysis.md) / [starrail-character-detail-module-analysis.md](./starrail-character-detail-module-analysis.md) / [zzz-character-detail-module-analysis.md](./zzz-character-detail-module-analysis.md) |
| M11 | AccountDetail | [account-detail-module-analysis.md](./account-detail-module-analysis.md) |
| M12 | Login | [login-module-analysis.md](./login-module-analysis.md) / [webview-page-module-analysis.md](./webview-page-module-analysis.md) |
| M13 | WidgetConfig | [widget-settings-module-analysis.md](./widget-settings-module-analysis.md) |
| M14 | Widget 子系统 | [widget-subsystem-modules-analysis.md](./widget-subsystem-modules-analysis.md) / [widget-settings-module-analysis.md](./widget-settings-module-analysis.md) / [component-deduplication-review.md](./component-deduplication-review.md) |
| M15 | 框架 | [main-module-analysis.md](./main-module-analysis.md) / [index-module-analysis.md](./index-module-analysis.md) / [launch-module-analysis.md](./launch-module-analysis.md) / [test-page-module-analysis.md](./test-page-module-analysis.md) / [ability-and-startup-modules-analysis.md](./ability-and-startup-modules-analysis.md) |

> 已知 Critical / High 的归属与"本次修 / 后续修"决策见 Refactor_Spec §11；重构提交不夹带行为变更。

## 6. 新增文档规范

新增页面分析时请遵守：

1. **位置**：`docs/<module>-module-analysis.md`，家族模板用 `<family>-modules-analysis.md`；跨模块的系统层用 `<layer>-modules-analysis.md`。
2. **必含章节**：`执行摘要`（C/H/M/L 计数表 + A-F 评级）→ 文件清单 → 结构树/调用链 → 合规检查 → 风险清单 → `重构执行备注`（契约与冻结项 / 重构范围 / 验收 / 已知问题归属）。纯索引类专项（如组件索引、测试套件）可免"执行摘要 + 评级"，但必须有文件清单、风险与归属。
3. **评级必须可推导**：写明 High / Medium 的判定理由，不要直接给总分。
4. **证据锚点**：关键结论标注 `文件:行号`。
5. **禁止**：自定义维度权重、`x/10` 或 `x/100` 子分、`B+` 之类的非标准等级。
6. **更新本索引**：新增文档后同步第 2 节表格、第 3 节优先级与第 5 节模块映射；若涉及契约或测试路径，同步 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §11 缺陷分诊。

---

## 7. 全目录复核记录（2026-10-26）

对 `docs/` 下全部 31 份 Markdown 做了一轮机器 + 人工复核，检查项与结论：

| 检查项 | 方法 | 结论 |
| --- | --- | --- |
| 证据锚点 | 提取全部 `*.ets:行号`，比对文件存在性与行数上限 | ✅ 0 处越界 / 0 处文件不存在 |
| 引用文件 | 提取全部 `` `path/File.ets` `` 引用 | ✅ 仅 4 处为「建议新建/已废弃」路径，正文已标注，非事实错误 |
| 文件行数 | 表格中「文件名 → 行数」逐行与 `wc -l` 比对 | ✅ 全部一致（含 195 组件、42 widget、52 共享层、20 测试文件） |
| 目录计数 | `components/` 16 个子目录、`ets/` 16 个顶层目录、349 文件 40,947 行 | ✅ 与 Refactor_Spec §2.1、组件索引一致 |
| 评级算数 | 每份文档的 C/H/M/L → 债务点数 → 评级规则 | ✅ 修正 8 份 README 表格行的陈旧计数 |
| 校准口径 | 测试资产是否计入评级 | 新增 §1.4，并据此回调 DailyDetail（2M→1M）、AccountDetail（2M→1M）、My（2L→1L） |
| 章节骨架 | 摘要 → 清单 → 结构 → 合规 → 风险 → 重构备注 | ✅ 四份原本缺「合规检查」的模块（Login / Tools / My / Main）已补齐 |
| 交叉引用 | README ↔ Refactor_Spec §11/§12 ↔ 各文档 | ✅ 同步 M0/M4/M6/M11 的计数与测试资产说明 |

### 7.1 第二轮：逐条证据复核（同日）

第一轮解决的是"数字对不对"，第二轮把每份文档的 High / Medium / Low 条目逐条拿回代码里验证"这句描述是否成立"，又修了一批**等级标注与计数不符**的问题：

| 文档 | 发现 | 处理 |
| --- | --- | --- |
| [appearance-settings-page](./appearance-settings-page-module-analysis.md) | 摘要写 Medium 2，风险清单只有 1 条 | 补登记真实存在的第二条：`selectTheme()` 无重复点击保护，连点会连续 `pop()`（`:47-67`） |
| [characters](./characters-module-analysis.md) | 11 个 `@Monitor` 放在"高风险"表里却编号 `M-1` | 改号为 `H-1`，与 High 1 / Medium 2 对上 |
| [starrail-character-detail](./starrail-character-detail-module-analysis.md) | 同一项 `parseRawJson` 在安全审查表标"中"、在 P0 标必修 | 统一为 High，并注明与 P0 同项 |
| [privacy-consent-page](./privacy-consent-page-module-analysis.md) | 安全审查把 `terminateSelf` 标中、`setAgreed` 标低 | 互换：`setAgreed` 失败仍进 MAIN 才是 Medium（与 Refactor_Spec §11 一致） |
| [launch](./launch-module-analysis.md) | 摘要 Low 2，实际 1 条 Low + 1 条"信息"；另有一个乱码字符 `⡹` | 拆成 L1（`waitForReady` 无超时）+ L2（`getHostContext()` 强转），修掉乱码 |
| [index](./index-module-analysis.md) | 同上：第 2 条 Low 被写成"信息提示" | 明确为低优先级（无 `@Preview` 的开发体验项） |
| [material-list](./material-list-modules-analysis.md) | 摘要 Medium 1 但清单里没有 Medium | 补登真实问题：三页骨架复制约 96%（各 186 行）；日志/死导入降为 2 条 Low |
| [material-target-config](./material-target-config-modules-analysis.md) | M-TARGET-4/5 与 1/3 是同一件事，编号还缺 2 | 重建编号：M1 `LevelRow` 过大、M2 三页 UI 外壳复制、M3 `pickerStep` 未入 VM，建议表只留"信息" |
| [material-calc](./material-calc-module-analysis.md) | Low 2 只有 1 条 | 第 2 条（`levelOptions` 非响应式）从"信息"改判 Low |

**第一轮变更摘要**：Main +1 合规章节（11 条）；Home +1 合规章节（13 条）+1 Medium（跨层依赖，后随结构迁移解除）；Login 修正 Low 表错位、合并重复编号、+1 合规章节（14 条）；Tools +1 合规章节（11 条）；My +1 合规章节（12 条）、撤回一条失效 Low；DailyDetail / AccountDetail 按 §1.4 回调计数；README 表格重算并按债务点数重排。

【已核对代码一致性】
