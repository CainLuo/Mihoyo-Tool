# Entry 模块重构方案说明书

> 状态：**规划阶段（Phase 0），暂不修改代码**
> 基线：**HarmonyOS 6.0.2 Release / API 22**（以根目录 `build-profile.json5` 的 `compatibleSdkVersion` 为准；skills 的"生产默认 API 24"不适用于本工程）
> 记录日期：2026-10-23 ｜ 文档修订：2026-10-24（补强 Phase 0 门禁、契约与台账，无代码改动）

## 0. Phase 0 基线与验证门禁（执行前一次性）

在动第一个 `.ets` 文件之前，先把"当前是什么状态"记录下来，否则无法区分"重构引入的失败"与"本来就失败"。

### 0.1 基线记录表（待执行后填写）

| 项 | 命令 / 方式 | 当前结果 | 备注 |
|---|---|---|---|
| main 编译 | `hvigorw --mode module -p module=entry@default -p product=default -p buildMode=debug assembleHap` | 待记录 | 必须从干净构建开始 |
| codeLinter | `hvigorw codeLinter` | 待记录 | 记录错误/警告总数，作为"不新增"的基线 |
| Local Test | DevEco Studio → `entry` → Run Test（Local Test） | **已知失败** | `HomeViewModel.test.ets:4` 引用了不存在的 `components/home/HomeModels`，286 条用例全部无法编译；见 0.4 与 [`docs/test-suite-analysis.md`](../docs/test-suite-analysis.md) T1 |
| ohosTest 编译 | `bash test-entry.sh` | **已知失败** | 见 0.4，不在本次门禁内 |
| 设备 | 模拟器 `Mate 80 Pro Max`（`run.sh` 默认） | 待记录 | 冒烟验证用 |

### 0.2 构建环境

```bash
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
HVIGOR=/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw

# 编译（四个 product：default / release / uat / mock；buildMode：debug / release）
"$HVIGOR" --mode module -p module=entry@default -p product=default -p buildMode=debug assembleHap

# ArkTS 规则强校验（arkts-rules skill 要求）
"$HVIGOR" codeLinter
```

### 0.3 验证门禁的可执行性（重要）

- `entry/src/test` 是 **Local Test**（宿主机运行，不能碰 `@kit.*` 系统 API）。仓库里**没有**执行它的脚本：`test-entry.sh` / `test-core.sh` 都只是 `assembleHap` ohosTest HAP（编译验证）。
- 实测 `hvigorw tasks --mode module -p module=entry@default` 只暴露 `tasks` / `taskTree` / `init`，**没有 test 任务**。Local Test 只能在 DevEco Studio 里 Run Test。
- 因此本方案的测试门禁写作："**在 DevEco 中运行 `entry/src/test` 全部通过**"；如果只能走 CLI，则本项记为"未验证"，不能写成"通过"。

### 0.4 已知红色基线（不要误判为重构造成）

- `entry/src/ohosTest` 当前编译失败：[log.md](../log.md) 记录了 67 个错误，主要是测试仍引用已不存在的 `../main/ets/parsers/*`，以及 `arkts-no-any-unknown`。
- `entry/src/ohosTest` 是 **hypium Instrument Test**（不是 GTest）；它不在作用域内，也不作为本次门禁。
- **`entry/src/test` 目前也编译不过**，至少 5 个测试文件存在阻塞：下面列出 3 个，另有 `CharactersViewModel.test.ets` / `GenshinCharacterDetailViewModel.test.ets` 引用不存在或未导出的符号（2026-10-27 复核，详细矩阵见 [`docs/test-suite-analysis.md`](../docs/test-suite-analysis.md) T1 / T6）：
  1. `HomeViewModel.test.ets:4` 从 `../main/ets/components/home/HomeModels` 导入，实际文件在 `models/HomeModels.ets`（`components/home/` 下没有 HomeModels），且 `GAME_GENSHIN` / `GAME_STARRAIL` / `GAME_ZZZ` 全仓无定义。见 §8 Q-9。
  2. `AccountDetailViewModel.test.ets:22-28` 引用 `AccountDetailViewModel.KEYS.deleted` / `.errorMsg`，而 VM 只有顶层 const `ACCOUNT_DETAIL_VM_DELETED` / `_ERROR`，没有 `KEYS` 对象。
  3. `GenshinDailyDetailViewModel.test.ets` 通过索引调用 `GenshinDailyDetailViewModel['formatSeconds']` / `['formatTransformer']`，这两个方法已迁到 `utils/TimeFormatUtil.ets`，11 个用例中 9 个必抛 `TypeError`；另有 `vm.init(1, 'uid1')` 传 number 与 `init(accountId: string, …)` 不符。
- `log.md` 是构建失败日志的临时落点（tracked），**不要再把进度记录追加到这里**；进度写本文件 §12 与模块 `## M<n>` 章节，发布级变更写根 `CHANGELOG.md`。

## 一、决策摘要（user decisions 2026-10-23 / 文档修订 2026-10-24）

| 决策点 | 结论 |
|---|---|
| **代码作用域硬限制** | 仅允许修改 `entry/src/main/ets/**/*.ets`。以下一律不得改动：`module.json5` / `build-profile.json5` / `oh-package.json5` / `resources` / `entry/src/test` / `entry/src/ohosTest` / `core` 模块。 |
| **文档白名单（例外）** | 允许改：`entry/Refactor_Spec.md`、`docs/**`、`docs/reviews/**`（新建）、根 `CHANGELOG.md`。除此之外的 root 文档不动。 |
| **契约冻结** | 路由名、`custom_router_map.json` 的 `pageSourceFile` / `buildFunction`、4 个 ability 的 `srcEntry`、`form_config.json` 的页面路径、被 `entry/src/test` 导入的文件路径与导出符号，全部冻结；详见 §2.4 / §2.5。 |
| V1/V2 策略 | **保持现有边界，不做 V1↔V2 转换**。现状：**219 个文件**使用 `@ComponentV2` 装饰器（另 10 个文件只在注释中提及），**16 个文件**使用 `@Component`（6 个 widget pages + 10 个 widget components）；2026-10-24 复核**未发现同一文件实际混用**两种装饰器。"保持边界" = 重构时不改变装饰器风格，也不新增混合文件。 |
| 验证标准 | 每个模块迭代成功 = ① main 编译通过 ② `hvigorw codeLinter` 不新增违规 ③ `entry/src/test` 在 DevEco Local Test 全绿（仅运行，不得修改）。可视化/运行时检查按 §7.1 冒烟清单执行。 |
| 重构粒度 | 按模块（页面分组）：Home / Characters / CharDetail / …… 在 `ets/` 内按模块重组目录。可复用组件、设计模式、命名规范见 §6。 |
| Plan doc | 本文件 `entry/Refactor_Spec.md`，参照根目录 `Refactor_Login_Spec.md` 先例。 |
| 进度记录 | 本文件 §12 台账 + 各模块 `## M<n>` 章节；每次模块完成一次 git 提交（`entry: refactor M<n> …`）。 |

**作用域限制说明：** `entry/src/test` 不得改动，因此重构只能*运行*现有 hypium 测试，不能新增测试文件。现有测试对源文件的路径是硬依赖（§2.5）；如果某模块需要新增测试，必须先经用户明确确认（见 §8 Q-1）。

## 二、现状分析（inventory 2026-10-23，复核 2026-10-24）

### 2.1 `entry/src/main/ets/` 顶层布局（16 个目录，349 个 `.ets` 文件，40947 行）

> 本节为 2026-10-23 结构迁移前的快照，保留作历史；当前结构见 [docs/project-structure.md](../docs/project-structure.md)。

| dir | files | lines | role |
|---|---|---|---|
| `pages/` | 29 | 5211 | 页面容器（Navigation 路由），含框架文件 `Main`/`Index`/`Launch` + `TestPage` |
| `components/` | 195 | 14931 | 按功能划分的 UI 组件，15 个功能子目录 + 根级 10 个共享文件 |
| `viewmodel/` | 24 | 7619 | 按页面划分的 ViewModel（数据/状态层） |
| `widget/` | 40 | 6947 | 小组件子系统（pages 6 / components 10 / viewmodel 4 / models 4 / utils 16）—— V1 |
| `utils/` | 22 | 1920 | 共享工具（信号、实用函数、服务） |
| `models/` | 13 | 1613 | 共享数据模型（`.ets`，无 `.d.ts`） |
| `notification/` | 5 | 1082 | 通知服务（含 `StaminaNotificationService` 691L） |
| `theme/` | 4 | 538 | `ThemeManager`（fan-in **210**）、`ThemeFonts`（82，真实 import 方）、`DefaultTheme`（25）、`AppTheme`（4） |
| `constants/` | 10 | 338 | `AppRoutes`、`ViewStates`（fan-in 35）、按游戏分类的 Element 枚举 |
| `entryability/` `entryformability/` `entrybackupability/` `widgetsyncability/` | 4 | 676 | Stage 模型契约入口点 —— **契约区域** |
| `builders/` `config/` `styles/` | 3 | 72 | `MaterialCharacterSelectBuilder`（路由入口）/ 单例配置 / 样式常量 |

> 统计口径：`find entry/src/main/ets -name '*.ets'`，包含所有子目录。重新统计用：
> `find entry/src/main/ets -name '*.ets' | wc -l` 与 `find entry/src/main/ets -name '*.ets' -exec cat {} + | wc -l`。

### 2.2 跨模块导入图（2026-10-23 计算得出）

分层基本合理：`pages → components/viewmodel`，`viewmodel → models/utils/constants`，`components → theme/models/constants`。

Fan-in 中心节点（共享层，不可随意移动）：
- `theme/ThemeManager.ets` — **210 个导入边**（2026-10-27 复核：原 211 把定义文件自身注释也算进去了）
- `theme/ThemeFonts.ets` — 82（原 83 含 `ThemeManager.ets:11` 注释）；`models/CharDetailModels.ets` — 41；`constants/ViewState.ets` — 35
- `widget/models/WidgetUIStates.ets` — 31；`constants/AppRoutes.ets` — 21；`utils/GameIdUtil.ets` — 16

**需要关注的分层违规（潜在循环导入风险）：** 2026-10-27 复核：现存循环可以编译运行（`models/WidgetSettingsModels ↔ viewmodel/WidgetSettingsViewModel`、`components/GeetestDialog ↔ GeetestDialogHelper`（迁移后为 `features/verification` 内 `views/GeetestDialog ↔ utils/GeetestDialogUtil`，仍存在）），但循环会带来模块初始化顺序风险，重构**不得新增**循环。
- `components → viewmodel`：**48 个边**，而 `viewmodel → components`：2 个 → 按功能可能存在循环
- `viewmodel → pages`：3 个边，`utils → components`：2 个边，`models → viewmodel`：1 个边
- 每个模块需做决策：优先通过 `@Param`/`@ObjectLink` 传递状态，而非组件导入 ViewModel 类型（§6 P-3）。

### 2.3 重复代码和热点候选项

- **按游戏三件套**（Genshin/StarRail/ZZZ）：`pages/GenshinDailyDetail|StarRailDailyDetail|ZZZDailyDetail`，MaterialList / MaterialTargetConfig / CharacterDetail 同样 ×3；`viewmodel/` 共 4 组。`components/characters/` 有 `genshin` / `starrail` / `zzz` 三个子目录（含 ×3 BottomBar + ×3 TopLeftBadge）→ 去重机会：共享骨架 + 按游戏配置参数（login-spec 先例模式）。
- **`components/chardetail/`**：`common` 9 + `genshin` 26 + `starrail` 11 + `zzz` 13 = **59 个文件**，含响应式分支（Portrait/Landscape/Wide Layout ×4 HeroPanel 变体）——最大的去重目标。
- **`components/dailynote/`**：已是 `common` + `genshin` / `starrail` / `zzz` 结构，共 **16 个文件**；M6 的"三件套去重"实际上只需清理残余重复，不要按"4 个文件"的旧统计规划。
- **`components/widgetsettings/`**：**24 个文件**（13 个根级 + `preview/` 11 个），旧统计的 14 只算了根级。
- **`components/characters/`**：**11 个文件**（根级 5 + 3 个游戏子目录共 6）。
- **V1/V2 复核**：229 个文件出现过 `@ComponentV2` 字样，其中 **219 个实际使用**该装饰器（另 10 个只在注释里提及）；**16 个文件实际使用 `@Component`**（6 pages + 10 components，全部在 `widget/`；另 1 个 `widget/utils/WidgetUtils.ets` 仅在注释里提及）；未发现同一文件实际混用。**10 个 `widget/components/` 文件 + 3 个 `widget/pages/` 文件**在注释里说明"卡片引擎不支持 V2"，属于有意为之。
- **生产路径中的测试/开发文件**：当前 `entry/src/main/ets` 内**没有** `MaterialListCalcTest*.ets`（2026-10-24 复核）；实际存在的是 `pages/TestPage.ets` 与 `components/TestRow.ets`、`TestSectionHeader.ets`，保留待确认。
- **`pages/TestPage.ets`** —— 开发页面存在于生产 `pages/` 中，且已注册路由；保留待确认（§8 Q-2）。
- 命名不一致：真正带 `Page` 后缀的只有 `AppearanceSettingsPage.ets` / `PrivacyConsentPage.ets` / `WebViewPage.ets`（`WidgetSettingsPage.ets` **没有** Page 后缀）。
- **HomeViewModel 754L，GenshinMaterialListViewModel 694L，WidgetConfigViewModel 676L** —— 按功能轴拆分大型 ViewModel，作为模块重构的一部分；但受 §2.5 路径冻结约束（拆分必须保留原文件 facade）。

### 2.4 不可改动契约表（新增，P0）

| 契约 | 位置 | 冻结内容 | 涉及模块 |
|---|---|---|---|
| **路由表** | `resources/base/profile/custom_router_map.json`（20 条） | `name`、`pageSourceFile`、`buildFunction` | M3 / M5 / M6 / M7 / M10 / M11 / M12 / M13 / M15 |
| 入口页 | `resources/base/profile/main_pages.json` | 仅注册 `pages/Index` | M15 |
| 卡片配置 | `resources/base/profile/form_config.json` | 6 个 form 的 `src` 均硬编码 `./ets/widget/pages/*.ets` | M14 |
| Ability | `entry/src/main/module.json5:36/52/64/76` | `EntryAbility` / `WidgetSyncAbility` / `EntryBackupAbility` / `EntryFormAbility` 的 `srcEntry` | M0 / M14 / M15 |
| 路由常量 | `constants/AppRoutes.ets` | 所有 `static readonly` 字符串值（NavPathStack 用它 push），共 25 条 | 全模块 |
| `@Monitor` 路径 | 各页面/组件中 37 处 `@Monitor('xxx.yyy')` 字面量 | 字面量 ↔ 其指向的 `@Local` 字段名 / VM 字段名必须一致，改任一侧监听静默失效。`constants/SignalStorageKey.ets` 原有的 8 个 `@Monitor` 路径值从未被引用，已于 2026-10-28（M0）删除，现只保留 `GEETEST_SIGNAL_KEY` / `COOKIE_EXPIRED_SIGNAL_KEY` 两个 AppStorage key，这两个值冻结 | M1 / M2 / M4 / M5 / M7 / M8 / M9 / M10 / M11 / M12 / M15 |
| 持久化 key | `utils/AppearanceManager.ets:19-20`、`utils/LegalPreferences.ets:13-14`；AppStorageV2 key（`SignalMonitorKey` 两个 + `AccountSignal` / `SyncRetrySignal` / `DeviceFpInvalidSignal` 的 `KEY`） | Preferences store 名与 key、AppStorageV2 key 的字符串值（改名会丢失用户已保存的颜色模式 / 隐私同意状态） | M0 / M2 / M3 |
| 其余路由参数类 | `models/CharDetailModels.ets` `CharDetailRouterParam`；MaterialCharacterSelect 的三份定义（`viewmodel/MaterialCharacterSelectViewModel` `MaterialCharacterSelectParam`、`builders/` 与 `pages/MaterialCharacterSelect` 内的 `MaterialCharacterSelectRouteParam`） | 字段名（接收方 `as` 强转，编译期不检查） | M7 / M10 |
| `AccountSignal` 双重语义 | `utils/AccountSignal.ets` ↔ 三个目标配置 VM | 三个目标配置 VM 在保存配置且计算 `SUCCESS` 后 `notify()`，是 Tools 刷新"已配置目标"数的唯一触发（`hasComputeData` 只查配置是否存在）；不能删除，也不能收进 `MaterialComputeService.compute()` 统一发（会让材料清单每次刷新都重载四页） | M1 / M7 / M15 |
| 材料计算参数 | `models/ToolsModels.ets` 的 `MaterialTargetConfigParam` | 字段名与类型（三游戏目标配置页 + 材料清单页 + 选角页共用） | M7 |
| 页面 Builder | 21 个页面文件中的 `export function XxxBuilder` | 函数名与所在文件路径（19 个 routerMap 页面 + `MaterialCalc` + `PrivacyConsentPage`；`MaterialCharacterSelect` 的 Builder 在 `builders/`） | 全模块 |
| 测试导入 | `entry/src/test/*.test.ets` | 见 §2.5 | M1–M13 |
| 字符串资源 | `resources/**/string.json` | `$r('app.*')` 的 key 不得改名 | 全模块 |

**对 N-1 的直接影响：**
- `AppearanceSettings` 路由指向 `pages/AppearanceSettingsPage.ets`，`WebView` 路由指向 `pages/WebViewPage.ets` → **这两个文件不能改名**（改 resources 超出作用域）。
- `PrivacyConsentPage.ets` 不在 routerMap 里（由 `pages/Index.ets:5` 直接 import builder），可以改名，但要同步 `Index.ets` 的 import。
- `MaterialCharacterSelect` 的路由入口在 `builders/MaterialCharacterSelectPageBuilder.ets`，不在 `pages/`；M7 规划时不能只动 pages/components。
- 页面文件即使改名，**路由名（`AppRoutes` 字符串）也不能改**。

### 2.5 测试引用白名单（新增，P0）

`entry/src/test` 用相对路径直接导入被测文件，测试不可改 → 下列路径与导出符号**冻结**：

| 类别 | 被导入文件 |
|---|---|
| ViewModel（10 个） | `AccountDetailViewModel` / `CharactersViewModel` / `GenshinCharacterDetailViewModel` / `GenshinDailyDetailViewModel` / `HomeViewModel` / `LoginViewModel` / `MaterialCalcViewModel` / `MyViewModel` / `PrivacyConsentViewModel` / `ToolsViewModel` |
| constants | `constants/ViewState` / `constants/LoginConstants` |
| models | `models/MaterialCalcModels` / `models/ToolsModels` / `models/HomeModels`（测试当前误写成 `components/home/HomeModels`，见 §0.4）/ `notification/NotificationModels` |
| notification | `notification/StaminaThresholdCalculator` |
| Q-10 修复后的目标 | `utils/TimeFormatUtil`（`formatSeconds` / `formatTransformer`）、`utils/GenshinPropertyUtil`（`genshinPropertyTypeToResource`）、`models/AccountOption`——按保守口径同样冻结（见 test-suite T6、shared-layer §7） |
| widget | `widget/viewmodel/Widget2x2ViewModel` / `widget/models/WidgetUIStates` / `widget/utils/{WidgetPayloadParser,WidgetDataHelper,WidgetUtils,WidgetExtraRowConfig,WidgetExtraRowType}` |

**规则：**
1. 被测试导入的文件**不能移动、不能改名**；类/常量/函数的导出名不能变。
2. 大型 ViewModel 拆分时，原文件必须保留为 facade（`export { … } from './xxx/…'`），保证 `entry/src/test` 编译不变。
3. 现有测试只覆盖 24 个 ViewModel 中的 **10 个**；其余模块（AppearanceSettings / NotificationSettings / WidgetConfig / StarRail·ZZZ CharDetail / StarRail·ZZZ Dailynote / MaterialCharacterSelect / MaterialList / MaterialTargetConfig / 框架页）**没有测试**，验收只能走 §7.1 冒烟清单。

## 三、重构后目录结构 (target)

Keep `entry/src/main/ets/` 根目录结构不变，内部重新分组：

```
entry/src/main/ets/
├── entryability/ entryformability/ entrybackupability/ widgetsyncability/  # 契约区域 — 不移动文件，仅编辑内容
├── config/ styles/ builders/                    # 文件位置保持不变（文件少，与契约相邻；builders 内容随 M7 修改）
├── theme/ constants/ utils/ models/             # 共享层（M0）：可编辑，但中心节点文件原位不动
├── pages/                                       # 页面层：每个路由一个文件；见 §2.4 的路由冻结例外
├── viewmodel/                                   # ViewModel 层：每页一个 ViewModel（拆分时保留原文件 facade）
├── notification/                                # 服务层（M5）
├── widget/                                      # M14 子系统，内部布局保持不变（V1 孤岛）
└── components/
    ├── common/                                  # 共享组件（SegmentedTabBar, PlaceholderView）
    └── <feature>/                               # 每个功能模块一个目录，游戏变体在子目录中（login 先例）
        ├── common/                              #   3 个游戏共享的部分
        ├── genshin/ starrail/ zzz/              #   按游戏区分的部分（仅游戏特定的内容）
```

## 四、模块划分（重构单元）

模块 = 页面 + ViewModel + 组件目录 + models/constants 条目 + 相关工具函数。ID 顺序即执行顺序（§7），从最简单到最复杂：

| M | module | pages | viewmodel | components | notes |
|---|---|---|---|---|---|
| M0 | 共享层 | – | – | `components/common/*`（2）+ `components/SnackbarContent.ets` + shared constants/models/theme/utils/config/styles/builders | 中心节点文件，仅原位编辑，不移动；`builders/MaterialCharacterSelectPageBuilder.ets` M0 只负责位置与函数名冻结，内容随 M7。2026-10-27 复核：根级其余 9 个文件实际只服务单模块——Geetest×5 + `SplitPlaceholder` → M15，`TestRow`/`TestSectionHeader` → M15（TestPage），`SettingRow` → M4（见 shared-layer §1.5） |
| M1 | Tools | Tools | ToolsViewModel | tools/（1 个文件） | 最小模块；有 Local Test（`ToolsViewModel.test.ets`） |
| M2 | PrivacyConsent | PrivacyConsentPage | PrivacyConsentViewModel | privacyconsent/（2 个文件） | 有 Local Test；页面不在 routerMap |
| M3 | AppearanceSettings | AppearanceSettingsPage | AppearanceSettingsViewModel | appearancesettings/（1 个文件） | 路由文件路径冻结；与 theme 中心节点关联 |
| M4 | My | My | MyViewModel | my/（6 个文件） | 有 Local Test |
| M5 | Notification | NotificationSettings | NotificationSettingsViewModel（403L） | `components/notification/`（14）+ `components/my/NotificationSection.ets`（待迁入）+ `notification/` 服务（5 个） | 服务向 widget 扇出：3 条边；`NotificationModels` 被测试引用；唯一安全移动是把 `NotificationSection` 从 `my/` 迁入 `notification/` |
| M6 | Dailynote | Genshin/StarRail/ZZZ DailyDetail ×3 | ×3 | dailynote/（16 个文件，已分 common/genshin/starrail/zzz） | 页面骨架 ~90% 复制，但无必须的目录移动；仅 Genshin 有测试 |
| M7 | MaterialCalc | MaterialCalc | MaterialCalcViewModel + MaterialCharacterSelectViewModel + MaterialTargetConfigViewModel ×3 | materialcalc/（8 个常规组件：LevelPicker / Character / ContentView / EmptyView / Item / LoadingView / Section / Skills）+ materiallist/（6 个）+ `builders/MaterialCharacterSelectPageBuilder.ets` | `MaterialComputeService` 中心节点；`MaterialCalcModels` 被测试引用 |
| M8 | Home | Home | HomeViewModel（754L，需拆分，保留 facade） | home/（10 个文件） | `models/HomeModels` 被测试引用（测试当前误写成 `components/home/HomeModels`，见 §0.4），不能移动 |
| M9 | Characters | Characters | CharactersViewModel | characters/（11 个：根级 5 + 3 个游戏子目录共 6） | 三件套去重；有 Local Test |
| M10 | CharDetail | Genshin/StarRail/ZZZ CharacterDetail ×3 | ×3 | chardetail/（common 9 + genshin 26 + starrail 11 + zzz 13 = 59） | 最大去重目标；`CharDetailModels` fan-in 41；仅 Genshin 有测试 |
| M11 | AccountDetail | AccountDetail | AccountDetailViewModel | accountdetail/（7） | 有 Local Test |
| M12 | Login | Login (+WebViewPage) | LoginViewModel | login/（18） | **已有根 spec `Refactor_Login_Spec.md`**：其中 build-profile/mock 分离不可执行，只取组件拆分；WebView 路由文件冻结 |
| M13 | WidgetConfig | WidgetSettings | WidgetConfigViewModel | widgetsettings/（24 = 13 根级 + preview/11） | 无 Local Test |
| M14 | Widget 子系统 | widget/pages ×6 | widget/viewmodel ×4 | widget/components（10）+ models（4）+ utils（16） | V1 孤岛；与 widgetsyncability + notification 交互；form_config 路径冻结 |
| M15 | 框架 | MainPage, Index, LaunchPage (+TestPage) | – | – | Navigation 路由 + `@Param` 回调编排；最后执行 |

**跨模块共享组件（复用分析）** — 被多个模块导入的组件应位于 `components/common/`（或保留在原定义处）：
- `components/common/SegmentedTabBar.ets`、`PlaceholderView.ets`
- 根级 `components/SnackbarContent.ets`（被 M0 的 `FeedbackUtil` 导入，归 M0）；`SplitPlaceholder.ets`、`GeetestDialogHelper.ets` 实际只被 Main（及 `utils/GeetestSignal` 取 `GeetestProgress`）使用，归 M15、原位保留（2026-10-29 核对：`GeetestDialogHelper` 还被 `GeetestDialog`、`GeetestDialogTitleBar` 导入，均在同一功能内；结构迁移后：`SplitPlaceholder` 在 `common/basic/.../shares/`，`GeetestDialogHelper` 改名 `GeetestDialogUtil`，在 `features/verification/.../utils/`）
- `chardetail/common/CharDetailSectionLabel.ets` fan-in **12** → 3 个游戏共享
- ~~Login 组件 `LoginTypeState`/`LoginTypeSelectDialog` 被 Main 使用~~（2026-10-29 核对：代码中已不存在这两个组件，MainPage 也不导入）；`AccountSwitchDialog` 原在 `components/characters/` 下，结构迁移后在 `common/basic/.../shares/`（MainPage 与材料选角页共用）

**重构目标指标（前后对比，防"只搬文件"）：**
- 每个模块完成后统计：文件数 / 最大文件行数 / 重复 struct 数 / `components → viewmodel` 反向边数。
- 本轮**不强制**消除 48 条 `components → viewmodel` 边；只要求"不新增"。若要把分层违规作为目标，必须单独立项（会改变运行行为，超出本次"保持行为"的约束）。
- 三件套去重的验收不是"文件数变少"，而是"同一份数据在三个游戏渲染结果一致"（§7.1 逐游戏冒烟）。

## 五、各文件改动说明 — 暂不执行；按模块规范在本文件中追加记录（§7 循环第 2 步编写 `## M<n> spec` 章节）。

## 六、设计模式与命名规范（既定方案）

- **N-1 命名（2026-10-28 修订）**：全部命名以 [`docs/naming-conventions.md`](../docs/naming-conventions.md) 为准（依据 OpenHarmony《ArkTS 编程规范》与官方 codelabs）。页面统一为 `XxxPage.ets` / struct `XxxPage` / `XxxPageBuilder`（`Index.ets` 除外），原 N-1「去掉 Page 后缀」是项目自定约定、与官方示例相反，已废止。已执行的改名见 [`docs/naming-rename-map.md`](../docs/naming-rename-map.md)；路由名字符串（`AppRoutes` 的值 / routerMap `name`）始终不变。
- **N-2 ViewModel 命名**：`<Feature>ViewModel.ets`，每页一个；仅当存在清晰的数据/动作划分轴时才拆分 >500 行的 VM（HomeViewModel、MaterialList ×3、WidgetConfig）。**拆分必须保留原文件与原导出符号**（facade + re-export），否则 §2.5 的测试编译失败。
- **N-3 组件命名**：按角色后缀：`…Section`（垂直容器）、`…Card`（卡片）、`…Row`、`…Item`、`…Header`、`…Bar`、`…Panel`、`…Layout`（响应式分支）、`…Dialog`。不使用 `Comp`/`View` 缩写；保留现有主流后缀 —— 不要批量重命名正在工作的组件，仅对齐新拆分或新增的。
- **N-4 游戏变体**：共享部分放在 `<feature>/common/`，按游戏的放在 `<feature>/genshin/`、`starrail/`、`zzz/` 子目录（与 `chardetail/` 先例一致）。页面/ViewModel 层可以保留 `Genshin…` 前缀的文件（薄封装）；组件层不得复制几乎相同的.game 文件 —— 当差异仅是数据时，合并为 common + 参数。
- **P-1 三件套模式**：针对 ×3 游戏页面集（DailyDetail/MaterialList/MaterialTargetConfig/MaterialCalc target config），收敛为：一个共享页面骨架 + 按游戏的配置数据（`utils/GenshinElementUtil` 等已是 fan-in 中心节点）。保留 3 个路由入口点（Navigation 需要不同的 id 和 Builder），共享其内部实现。
- **P-2 状态传递**：主框架通过 `@Param` 回调 + 信号单例（`CookieExpiredSignal`、`GeetestSignal.instance()`、`DeviceFpInvalidSignal`）与页面通信。保留单例模式；新信号类必须位于 `utils/` 中。
- **P-3 分层规则（按模块决策）**：组件文件不应导入 ViewModel 模块（当前反向：components→viewmodel 48 条边）。当组件需要 ViewModel 类型时，通过参数传递；仅需要数据类型时，从 `models/` 导入。如果循环已存在且能编译，不要随意打破 —— 记录并保留直到测试证明有问题。

### 6.1 拆分等价性检查表（新增，每模块第 3 步自检）

拆分/移动文件不是"纯移动"，逐条确认：

1. **单文件不混用 V1/V2**（STATE-001）：复核未发现实际混用文件（219 个 V2 + 16 个 V1）；拆分时不得产生新的混合文件。
2. **`export struct`**：新文件中的 struct 必须导出；一个文件最多一个 `@Entry`。
3. **V2 子组件契约**：必填 `@Param` 加 `@Require`；`@Event` 默认值 `() => {}`；`@Local` 不能由父组件赋值。
4. **`@Builder` / `@BuilderParam` / `@Styles` / `@Extend`**：成员与全局的语义不同，跨文件移动时必须保持原有作用域，不能"顺手"改。
5. **状态归属不变**：`@Local` 不因拆分变成 `@Param`（会丢双向绑定）；`@ObjectLink`/`@ObservedV2` 的对象身份不变。
6. **生命周期与初始化顺序**：`aboutToAppear` 的调用次数/顺序不变；`build()` 内的副作用（如 `new ViewModel()`）不得复制成多份。
7. **`@Monitor` / `@Watch` 不新增回环**（STATE-012）：回调内不得修改触发字段。
8. **列表契约**：`LazyForEach` 的 key 生成不变；不新增 `ForEach` 渲染大列表（PERF-002）。
9. **导入完整**：所有基于路径的 import 已更新；没有新增循环（现存循环能编译，但有模块初始化顺序风险）。
10. **资源 key**：`$r('app.*')` 原样保留；不因组件改名而改字符串 key。

## 七、执行循环（按模块，重复）

0. **前置（一次性）**：完成 §0 基线记录；打基线 tag `refactor-baseline-2026-10-24`。
1. **读取**模块全部文件；列出每个符号的导入者（grep 基于路径的 import）；对照 §2.4 契约表与 §2.5 测试白名单 → 验证：移动/重命名映射表完整、无冻结文件被移动。
2. **规范章节**：把 `## M<n> spec` 追加到本文件：文件映射表（旧→新）、决策、风险记录。
3. **重构**仅限 `entry/src/main/ets` 内的 `.ets` 文件。建议拆成两个提交：① 纯 `git mv`（只改路径）② 内容修改（import、拆分、状态调整）；`git status --porcelain` 必须只包含白名单路径。
4. **编译**：`hvigorw --mode module -p module=entry@default -p product=default -p buildMode=debug assembleHap` 通过（错误码 201/202/801 见 build-debug skill）。
5. **静态检查**：`hvigorw codeLinter`，错误/警告数不超过 §0 基线。
6. **Local Test**：在 DevEco 中运行 `entry/src/test` 全部通过（仅运行，不得修改）；无测试的模块执行 §7.1 冒烟清单，并在 `## M<n> spec` 记录"无测试"。
7. **审计**：对改动文件执行 harmonyos-review 检查清单（10 大类 / 75 条规则，引用 `SEC-*` / `ARKTS-*` / `STATE-*` 等稳定 ID）；报告写到 `docs/reviews/YYYY-MM-DD-M<n>-<module>-review.md`，含 `file:line` 与 A-F 评级。修复 must-level 项于作用域内，nice-to-have 记录在本 spec。
8. **记录**：更新 §12 台账 + `## M<n> spec`；每个模块一次 git 提交（消息格式 `entry: refactor M<n> …`）。

### 7.1 冒烟清单（无测试模块的验收）

| M | 必走路径 |
|---|---|
| M1 | 底部 Tab → Tools；各工具卡片进入/返回 |
| M2 | 首次启动 → 隐私页 → 同意/拒绝 → 重启后状态保持 |
| M3 | 我的 → 外观设置 → 切换深浅色/主题 → 返回不白屏 |
| M4 | 我的页各分组、AboutSection、账号入口 |
| M5 | 通知设置 → 开关/权限拒绝路径；体力通知服务不被破坏 |
| M6 | 三个游戏的便笺详情各进入一次；数据/刷新/错误态 |
| M7 | 材料计算 → 选角色 → 目标配置（×3）→ 材料清单（×3） |
| M8 | 首页三游戏卡片、刷新、骨架屏 |
| M9 | 角色列表三游戏、搜索/筛选、进入详情 |
| M10 | 三个角色详情、Portrait/Landscape 切换、返回 |
| M11 | 账号详情、切换账号 |
| M12 | 二维码 / Cookie 登录；WebView 协议页 |
| M13 | 小组件设置四步流程、预览 |
| M14 | 添加 6 种卡片、刷新、深浅色 |
| M15 | 四个 Tab 切换、共享路由栈返回、折叠屏宽度 |

> 可视化检查仍为可选；但上表路径至少各走一遍，避免"编译通过但白屏"。

## 八、开放问题（需用户确认后方可修改代码）

1. Q-1: `entry/src/test` 是否允许*新增* hypium 测试文件，还是严格只运行现有测试？（作用域规则写的是"不准动"）
2. Q-2: `pages/TestPage.ets` 与 `components/TestRow.ets` / `TestSectionHeader.ets` —— 生产路径中的开发/测试文件：保留原位不动，还是由用户自行迁移/删除？
3. Q-3: Login spec（`Refactor_Login_Spec.md`）中包含 `build-profile.json5` 的改动——在现行作用域限制下禁止执行。确认：Login 重构仅限于 `.ets` 文件内的组件拆分？
4. Q-4: 框架模块（M15 `MainPage.ets` @ComponentV2 + Navigation 菜单/@Param 回调编排）——允许在 `.ets` 内部做重构，但类名 `MainPage`（2026-10-28 命名规范化由 `Main` 改名）、路由 id 和 `NavPathStack` 使用必须保留；确认这就是"契约不可移动"的含义。
5. Q-5: `AppearanceSettingsPage.ets` / `WebViewPage.ets` 的路由冻结是否维持？若要执行 N-1，需要破例修改 `custom_router_map.json`（resources），是否授权？
6. Q-6: `docs/**`、`docs/reviews/**`、根 `CHANGELOG.md` 的文档白名单是否确认？（本次文档修订已按此执行）
7. Q-7: 三件套去重的验收标准：只要求"行为等价"（同数据同 UI），还是允许顺手修已知 bug？后者会扩大 diff 与回归面。
8. Q-8: 无测试模块是否接受"编译 + codeLinter + §7.1 冒烟清单"作为验收？
9. Q-9: `entry/src/test/HomeViewModel.test.ets:4` 的过期 import（`components/home/HomeModels` → `models/HomeModels`）是否允许修？这是让 Local Test 能编译的最小改动，但测试文件在作用域外。
10. Q-10: `entry/src/test` 里另外两处阻塞（`AccountDetailViewModel.test.ets` 的 `KEYS` 引用、`GenshinDailyDetailViewModel.test.ets` 的 `formatSeconds` / `formatTransformer` 索引调用）同样在作用域外。是否允许一并做测试侧修复（不动产品代码），还是把 Local Test 门禁整体降级为"未验证"？
11. Q-11: 若批准 Q-9 / Q-10，建议把三处修复合成一个单独的 `test: fix broken relative imports & stale KEYS` 提交，先于 M1 执行，之后每个模块的验收才能真正跑起来；是否同意这个顺序？

## 九、风险与预警（参考 runtime-pitfalls + harmonyos-review skill 检查清单）

- ⚠️ **基线是 API 22，不是 API 24**：`build-profile.json5` 的 `targetSdkVersion` / `compatibleSdkVersion` 均为 `6.0.2(22)`。禁止使用 API 23/24+ 的能力（编译期直接失败）；skills 的 "API 26 Preview" 章节不适用于本工程。需要新 API 时先改 build-profile（作用域外，需单独批准）。
- ⚠️ **基于路径的导入**：每次文件移动/重命名都必须修复所有相对导入（`grep -rn "from '.*<oldPath>"`）。ArkTS 没有 index-based import；现存循环能编译，但移动文件可能改变模块初始化顺序，不得新增循环。
- ⚠️ **路由契约**：`custom_router_map.json` 的 `pageSourceFile` + `buildFunction` 是系统加载路径，改名/移动页面文件会白屏或编译失败（§2.4）。
- ⚠️ **测试路径冻结**：`entry/src/test` 的相对导入是硬依赖；移动被测试文件会导致测试编译失败，且测试不可改（§2.5）。
- ⚠️ **$r 字符串资源**：组件引用 `$r('app.xxx.key')`；移动组件不会触及 `resources/` —— 但重命名组件绝不能重命名字符串 key。
- ⚠️ **@ComponentV2 装饰器**：拆分文件时保持装饰器风格不变（@Local/@Param/@Watch 语义在文件边界处会变化；遵循 state-management skill 规则与 §6.1）。
- ⚠️ **单例静态成员**：`themeManager` 模块级单例（210 个导入者）、`CookieExpiredSignal.instance()` 模式 —— 移动文件不会移动单例；保持导入相同路径或 AppStorage，切勿重新实例化。
- ⚠️ **widgetsyncability / entryformability**：表单和同步能力与 widget/ 耦合；`form_config.json` 硬编码 6 个页面路径，M14 不得移动 `widget/pages/*`。
- ⚠️ **AppStorage / windowClass**（`entry/src/main/ets/pages/MainPage.ets` 第 44 行：`AppStorage.get<window.Window>('windowClass')`）：key-string 耦合 —— 保留 key 字符串不变。
- ⚠️ **基线与门禁**：Local Test 只能在 DevEco 运行；`test-entry.sh` 只编译 ohosTest HAP，且 ohosTest 当前 67 个编译错误（`log.md`）。不要把它当作回归保护。
- ⚠️ **作用域外已知问题（本次不处理）**：`build-profile.json5` 内含明文签名口令（SEC-001 / Critical），建议单独轮换并迁移到 CI Secret；`entry/src/ohosTest` 的过期测试需要单独清理。

## 十、完整改动文件清单

本节为**每模块执行完成后追加变更记录的占位区域**。每个模块的完整改动列表记录在其对应章节 `## M<n> spec` 末尾，包含：

- **新增文件**: 新拆分出的组件/ViewModel/页面文件
- **删除文件**: 被合并或废弃的文件（如有）
- **重命名文件**: 源路径 → 目标路径
- **内容修改**: 仅在本模块范围内修改的 `.ets` 文件列表

示例格式：

```markdown
### M<n> - <module name> 改动清单
| 操作 | 原路径 | 新路径 | 说明 |
|------|--------|--------|------|
```markdown

### M1 - Tools 改动清单
| 操作 | 原路径 | 新路径 | 说明 |
|------|--------|--------|------|
| 无变更 | `features/material/src/main/ets/pages/ToolsPage.ets` | (same) | 目录/命名已规范，不改动 |
| 无变更 | `features/material/src/main/ets/viewmodel/ToolsViewModel.ets` | (same) | 162L < 500L 阈值，不拆分 |
| 无变更 | `features/material/src/main/ets/views/GameEntryCard.ets` | (same) | 本模块 views/ 内，无需移动 |
| 无变更 | `features/material/src/main/ets/model/ToolsModels.ets` | (same) | 被测试引用 + 跨模块共享，不移动 |

> **注意**: 每完成一个模块，在本表追加对应条目，并与该模块 `## M<n> spec` 的变更记录保持一致。

## 十一、缺陷分诊表（新增）

27 份页面/子系统/系统层分析 + 3 份专项（去重 / 组件索引 / 测试套件，共 30 份）见 [`docs/README.md`](../docs/README.md)。下表把分析文档中的已知问题归属到模块，避免"重构完成后 Critical 还在"。

| M | 模块 | 分析文档 | 已知问题 | 建议归属 |
|---|---|---|---|---|
| M0 | 共享层 | [shared-layer](../docs/shared-layer-modules-analysis.md) | 0 Critical / 0 High；8 Medium（RouterUtil 静默失败、DialogDedup 释放协议脆弱、模型层混入 ArkUI 类型、MaterialComputeService 550 行 + N+1、themeManager 210 文件中心节点、隐式契约分散且 `SignalMonitorKey` 未被采用 / `AppRoutes` 与 routerMap 对应无编译检查、`MaterialComputeService.compute()` 部分异常未转 `FAILED` 且部分失败仍报 `SUCCESS`、`GeetestCenter` 申请 / 提交验证失败时无任何提示）+ 9 Low（启动主题 fire-and-forget、四处注释与代码不一致、`DarkTheme` 注释示例引用不存在的类、`SyncRetrySignal.accountId` 无读取方、透明色缓存不随深浅色重算、`SegmentedTabItem` 致 VM 反向依赖组件、`PlaceholderState` 装饰器不生效、`TimeFormatUtil.recoveryDesc` 不足 1 分钟显示「0 分钟」、Snackbar 关闭不 `dispose()`）；`HomeViewModel.test.ets` 引用失效属测试资产（不计入，见 §0.4） | M1、L2/L3/L4/L6 与死代码清理（不含冻结的 `AppRoutes.TOOLS` 与 `SignalMonitorKey` 值）随 M0，L9（Snackbar 关闭后 `dispose()`）同；L8 改文案单独提交；L1（改启动时序）留给 M15；L5 与 M3 一起验证；L7 记录；M2（超时释放会改变不重复弹出的语义）记录不执行；`compute()` 兜底、`GeetestCenter` 申请 / 提交失败提示各自单独提交（可感知行为变化）；M3/M4/M5、`SignalMonitorKey` 去留需决策；`@Monitor` 契约已在 §2.4 改正；外观页 High 的修复点在 M0 的 `AppearanceManager.applyColorMode`（内部吞异常），与 M3 协同 |
| M1 | Tools | [tools](../docs/tools-module-analysis.md) | 1 High（`loadData()` 无取消标记） | 记录；要修则单独提交 |
| M2 | PrivacyConsent | [privacy-consent](../docs/privacy-consent-page-module-analysis.md) | 1 Medium（`setAgreed` 失败后仍 `replace(MAIN)`） | 记录；要修则单独提交 |
| M3 | AppearanceSettings | [appearance-settings-page](../docs/appearance-settings-page-module-analysis.md) | 1 High（主题切换失败被 `AppearanceManager.applyColorMode` 内部吞掉，页面照常 `pop()` 且无提示） | 修复点在 M0 的 `AppearanceManager`（改为返回成功与否或重新抛出），会改变失败时的 UI 行为，与 M3 协同、单独提交 |
| M4 | My | [my](../docs/my-module-analysis.md) | 0 High；2 Medium（`AboutSection` 的 `@Param` 默认实例 + 依赖 page 类型）+ 1 Low（`onVisibleAreaChange` 无节流；原 ARKTS-012 经查 core `Logger` 已封装 hilog，撤回） | 随模块修；类型抽取与 M3 协调 |
| M5 | Notification | [notification-settings](../docs/notification-settings-module-analysis.md) / [notification-service](../docs/notification-service-modules-analysis.md) | 页面：0 High；1 Medium（`abilityContext=null` 时开关静默无响应）+ 0 Low（40 行薄壳的结构提示不算缺陷）。服务层：0 High；6 Medium（每次同步取消并重建全部提醒且与注释相反、30 条上限静默跳过、widget 推送 fire-and-forget、`onDailyNotesSynced` 被 Home 触发 3 次、wantAgent 硬编码 bundle、状态表无对账）+ 3 Low | 页面随模块修；服务层 M1/M3/M4 随 M5（各自单提交），M2/M6 需决策，M5 属构建配置 |
| M6 | Dailynote | [daily-detail](../docs/daily-detail-modules-analysis.md) | 1 Medium（三页骨架复制）+ 2 Low；另有 `GenshinDailyDetailViewModel.test.ets` 引用失效方法（测试资产，不计入评级，但阻塞 §7 验收） | 记录；共享 Scaffold 非必须；测试引用需在跑 Local Test 前修 |
| M7 | MaterialCalc | [material-calc](../docs/material-calc-module-analysis.md) / [material-list](../docs/material-list-modules-analysis.md) / [target-config](../docs/material-target-config-modules-analysis.md) / [character-select](../docs/material-character-select-module-analysis.md) | 0 Critical / **1 High**（`MaterialCalc` 路由未注册、页面不可达）；Medium 11 + Low 13（按 4 份文档 2026-10-27 的执行摘要合计，这 4 份文档第二轮复核未完成，数字待复核） | High 单独提交（需在 `custom_router_map.json` 注册或改由 navDestination 处理，涉及 resources 作用域，需用户批准）；其余记录，去重随模块（不改变 UI 行为） |
| M8 | Home | [home](../docs/home-module-analysis.md) | 2 High（ViewModel 754 行；Skeleton 动画未停） | 拆分随模块；动画修复随模块 |
| M9 | Characters | [characters](../docs/characters-module-analysis.md) | 1 High（11 个 `@Monitor` 竞态） | 记录，暂不改行为 |
| M10 | CharDetail | [genshin](../docs/genshin-character-detail-module-analysis.md) / [starrail](../docs/starrail-character-detail-module-analysis.md) / [zzz](../docs/zzz-character-detail-module-analysis.md) | SR 2 High（`parseRawJson` 未设 ERROR、`entityId === '1510'`）；Genshin 1 High（同源 ERROR）；ZZZ 1 High（`parseRawJson` 吞异常仍进 DATA） | 随模块修（三游统一状态兜底） |
| M11 | AccountDetail | [account-detail](../docs/account-detail-module-analysis.md) | 0 Critical / 0 High；1 Medium（删除无二次确认）+ 1 Low（`as common.UIAbilityContext` 强转）；另有测试 `KEYS` 引用失效（测试资产，不计入评级，阻塞 Local Test） | 记录；要修则单独提交 |
| M12 | Login | [login](../docs/login-module-analysis.md) / [webview](../docs/webview-page-module-analysis.md) | 0 Critical / 0 High（二维码轮询取消标记已由 `b98abae` 修复，复核撤回；原 SEC-002「Cookie 日志明文」经逐层核查无凭据落盘路径，降为 Medium 加固）；4 Medium / 2 Low；WebView 0 High（2 Low） | 无阻断项；日志脱敏可选（`LoginViewModel.ets:350`，单独提交）；WebView 仅记录 |
| M13 | WidgetConfig | [widget-settings](../docs/widget-settings-module-analysis.md) | 0 High；1 Medium（`vm.init()` 失败后静默回退空配置，无错误态/重试；`isLoading` 必被置 false）+ 1 Low | 随模块修 |
| M14 | Widget 子系统 | [widget-subsystem](../docs/widget-subsystem-modules-analysis.md) / [widget-settings](../docs/widget-settings-module-analysis.md) / [component-dedup](../docs/component-deduplication-review.md) | 0 Critical / 3 High（瞬时更新失败即删用户卡片配置；无数据时展示 Mock 账号与体力；卡片从不显示数据新鲜度）；6 Medium / 3 Low；V1 孤岛（16 个 V1 文件：6 pages + 10 components） | H1/H2 随模块修（各自单提交），H3 需产品决策；装饰器不迁移；form_config 6 条 src 冻结 |
| M15 | 框架 | [main](../docs/main-module-analysis.md) / [index](../docs/index-module-analysis.md) / [launch](../docs/launch-module-analysis.md) / [test-page](../docs/test-page-module-analysis.md) / [ability-startup](../docs/ability-and-startup-modules-analysis.md) | MainPage 2 High（人机验证弹窗关闭时无 callback 地 `off('windowSizeChange')`，注销窗口尺寸监听；返回手势关闭验证框后验证队列永久卡死——10-29 复核恢复）；10 Medium / 6 Low（含 Cookie 过期弹框叠加、窗口 API 未包 try、Tab 根页按返回可能显示空白——待真机确认）；Index / Launch 0 High；TestPage 0 High（入口仅 DEBUG 可见，Q-2）；Ability 0 High / 4 Medium（初始化失败不可见、4 个 AppStorage key 无常量、`loadContent` 无兜底、导出 ability 不校验调用方） | 记录；Main 行为修复后续单独立项；AppStorage 常量可随 M15 |

> 原则：重构提交**不夹带行为变更**；Critical/High 若要修，先在本表登记并在 `## M<n> spec` 说明，修复与移动分开提交。

## 十二、执行台账与回滚（新增）

| M | 模块 | 状态 | 分支 | commit | 编译 | codeLinter | Local Test / 冒烟 | review | 遗留 |
|---|---|---|---|---|---|---|---|---|---|
| M0 | 共享层 | ✅ 已提交（导出清理 + 工具去重 + 日志） | — | 1ff4cfe | ✅ 随 M8 构建通过 | ⚠️ 跳过 | 🔶 待冒烟 | 文档 13 轮复核 | M8/外观页 High 已补字符串；M7 部分失败待产品决策 |
| M1 | Tools | ✅ 真重构完成 | — | 82cf004 | ✅ BUILD SUCCESSFUL in 17s 272ms | ⚠️ codeLinter 未配置，跳过 | 🔶 待 DevEco GUI 运行 | 6 Medium/Low 记录不执行 | ToolsModels 拆分 + 死代码清理；LIFE-002/N+1 保留 |
| M2 | PrivacyConsent | ✅ 重构 + High 修复完成 | — | 待提交 | ✅ BUILD SUCCESSFUL in 16s 145ms | ⚠️ 跳过 | 🔶 待运行 | — | 步骤常量/model、Footer 去重；不足一屏卡死已修 |
| M3 | AppearanceSettings | 🔶 部分完成（失败提示 + 字符串） | — | 1ff4cfe | ✅ 随 M8 构建通过 | ⚠️ 跳过 | 🔶 待运行 | — | 真重构（组件/VM 复核）待续 |
| M4 | My | 🔶 部分完成（SettingRow 迁入） | — | 1ff4cfe | ✅ BUILD SUCCESSFUL in 16s 358ms | ⚠️ 跳过 | 🔶 待运行 | — | 真重构（组件/VM 复核）待续 |
| M5 | Notification | 🔶 命名核查完成，真重构待执行 | — | 0160c6b（夹带无关文件） | ✅ BUILD SUCCESSFUL in 15s 719ms | ⚠️ 跳过 | 🔶 待运行 | — | 提交卫生待清理；服务去重未做 |
| M6 | Dailynote | 🔶 命名核查完成，真重构待执行 | — | bf6de65（记录曾写错文档） | ✅ BUILD SUCCESSFUL in 15s 824ms | ⚠️ 跳过 | 🔶 待运行 | — | 三件套去重未做 |
| M7 | MaterialCalc | 🔶 命名核查完成，真重构待执行 | — | 5e9b2a7（记录曾写错文档） | ✅ BUILD SUCCESSFUL in 14s 40ms | ⚠️ 跳过 | 🔶 待运行 | — | 三件套去重未做 |
| M8 | Home | ✅ 真重构完成 | — | e831292 | ✅ BUILD SUCCESSFUL in 18s 80ms | ⚠️ 跳过 | 🔶 待运行 | — | 已拆 4 文件，最大 315L |
| M9 | Characters | 未开始 | — | — | — | — | — | — | — |
| M10 | CharDetail | 未开始 | — | — | — | — | — | — | — |
| M11 | AccountDetail | 未开始 | — | — | — | — | — | — | — |
| M12 | Login | 未开始 | — | — | — | — | — | — | — |
| M13 | WidgetConfig | 未开始 | — | — | — | — | — | — | — |
| M14 | Widget 子系统 | 未开始 | — | — | — | — | — | — | — |
| M15 | 框架 | 未开始 | — | — | — | — | — | — | — |

**回滚策略：**
- 执行前打基线 tag：`git tag refactor-baseline-2026-10-24`。
- 每个模块 1–2 个提交（纯 move + 内容修改分开），失败时 `git revert <hash>` 单个模块，不 `reset --hard`。
- 提交前用 `git status --porcelain` 核对：只允许 `entry/src/main/ets/**` + 文档白名单；当前 `PizzaHelperUnited` / `TeyvatGuide` 两个 submodule 处于 dirty 状态，**不要 stage**。


## M0 spec — 共享层（2026-10-28）

分析依据：[`docs/shared-layer-modules-analysis.md`](../docs/shared-layer-modules-analysis.md)（13 轮复核，含 4 位独立审稿人）；逐条状态见该文 §9。

### 决策（依据 `.opencode/skills`）

| # | 问题 | 决定 | 依据 |
| --- | --- | --- | --- |
| D1 | `SignalMonitorKey` 8 个无人引用的 `@Monitor` 路径值 | 删除，只保留 2 个 AppStorage key；`@Monitor` 写字面量 | `state-management` 范例 5 直接用字面量；"接入 enum"未经编译验证 |
| D2 | `DialogDedup` 是否加超时自动释放 | 不加；只给唯一会漏释放的调用点补 try/catch | skills 无要求；超时释放会改变"显示期间不重复"语义 |
| D3 | 模型层 `$r()` / `PlaceholderState` 装饰器 | `$r` 不动、改正误导注释；`PlaceholderState` 去掉无效装饰器 | skills 无模型纯度要求；`STATE-005` 要求被观察对象为 `@ObservedV2` 实例，调用方全是对象字面量 |
| D4 | 主题 token 治理 | `Theme` 字段只追加、不改名（写入 §2.4 与 `AppTheme` 注释）；深浅色继续走资源限定词 | `harmonyos-development`「Dark mode adaptation」推荐 `resources/dark` + `onConfigurationUpdate` |
| D5 | 启动颜色模式恢复的时序 | 改为同步读取并应用，在 `loadContent` 前完成 | 消除首帧闪烁；写法与现有 `LegalPreferences.hasAgreed` 一致，`EntryAbility` 调用不变 |

### 文件改动清单（25 个文件，含新增 1 个）

| 提交建议 | 文件 | 改动 | 行为 |
| --- | --- | --- | --- |
| ① 注释 / 死代码 | `constants/SignalStorageKey`、`utils/GenshinElementUtil`、`utils/ZZZElementUtil`、`models/MaterialTargetConfigModels`、`utils/CookieExpiredSignal`、`utils/GameIdUtil`、`utils/ColorUtil`、`config/RuntimeConfig`、`theme/ThemeManager`、`theme/AppTheme`、`utils/AccountSignal` | D1；删无引用导出与未用 import；注释改正（L2 / L3） | 等价 |
| ② 结构 / 资源释放 | `utils/SyncRetrySignal`、`utils/GeetestCenter`、`utils/DeviceFpCenter`（L4）；`models/SegmentedTabModels`（新增）、`components/common/SegmentedTabBar`、`viewmodel/CharactersViewModel`（L6）；`components/common/PlaceholderView`（L7）；`utils/RouterUtil`（M1）；`utils/FeedbackUtil`（L9）；`pages/MaterialCharacterSelect`（D2） | 见左 | 等价（仅新增日志 / 资源释放） |
| ③ 可见行为修复 | `utils/MaterialComputeService`（M7）、`utils/TimeFormatUtil`（L8）、`utils/AppearanceManager`（L1 / D5）、`entryability/EntryAbility`（L5） | 异常转 `FAILED` 并提示；不足 1 分钟显示"即将恢复"；启动不再闪烁；切换深浅色后透明色跟随 | **有可见变化**，单独提交 |

### 未做 / 待批准

- **M8、外观页 High**：需要新增失败提示字符串（`resources/**/string.json`），超出 §1 作用域，待用户批准。
- **M7 部分失败**：是否新增 `PARTIAL` 结果需产品决策。
- **M2 / M3 / M4 / M5**：按上表记录；M4 随 M7。

### 验收

1. `assembleHap`（default / debug）编译通过；`codeLinter` 不超过 §0 基线（本次删除了 3 处违反 `no-unused-vars` 的 import，应只减不增）。
2. 冒烟：任意二级页 push / pop；Snackbar 连续触发、点外部关闭；角色页切换游戏 Tab、材料清单切换视图；人机验证通过后首页 / 角色页重新同步；账号详情重新生成设备指纹；选角页 / 目标配置页 / 材料清单"开始计算"；冷启动时深色设置不闪；外观设置切换深浅色后进入小组件设置看选中态颜色；首页体力将满时文案。
3. Local Test 目前因 §0.4 阻塞无法编译；Q-9 / Q-10 批准修测试后补跑。

---

## M1 spec — Tools 模块（2026-11-02 真重构）

分析依据：[`docs/tools-module-analysis.md`](../docs/tools-module-analysis.md)「重构执行备注」与文末「M1 真重构记录」。

### 背景说明

工程已从 `modules/` 三层迁移到 `features/`（M0 阶段完成），M1 涉及的四个文件已位于正确位置：

| 文件 | 当前路径 | 角色 |
|---|---|---|
| ToolsPage | `features/material/src/main/ets/pages/ToolsPage.ets` | 页面入口（@ComponentV2，125L） |
| ToolsViewModel | `features/material/src/main/ets/viewmodel/ToolsViewModel.ets` | ViewModel（@ObservedV2 + @Trace，144L） |
| GameEntryCard | `features/material/src/main/ets/views/GameEntryCard.ets` | 组件（@ComponentV2，131L） |
| ToolsModels | `features/material/src/main/ets/model/ToolsModels.ets` | 工具页 UI State（GameEntryVM，43L） |
| MaterialTargetModels | `features/material/src/main/ets/model/MaterialTargetModels.ets` | 材料养成目标领域模型（116L，新增） |

### 决策

| # | 问题 | 决定 | 依据 |
| --- | --- | --- | --- |
| D1 | `ToolsViewModel` 是否拆分（<500L） | 不拆分；144L 远低于阈值 | §6 N-2：仅 >500L 时考虑拆分 |
| D2 | `ToolsModels.ets` 混放材料计算领域模型 | 拆出 `MaterialTargetModels.ets`，`ToolsModels.ets` 保留 `GameEntryVM` 并 re-export | 工具页 UI State 与材料计算领域模型职责不同；re-export 保持全部既有 import 与测试路径不变 |
| D3 | `GameEntryCard @Param entry` 默认实例 | 改为 `@Require @Param entry` | 所有调用方均显式传参，编译期强制比运行时构造默认对象更安全 |
| D4 | `GameEntryVM.gameColor` | 删除 | 全仓只写不读，属死字段 |
| D5 | `loadData()` 无取消标记/代际号 (LIFE-002 Medium) | 记录不执行 | 会改变并发语义；Tools 由 Main 常驻挂载，风险可控 |
| D6 | `@Monitor('signal.version')` 硬编码字符串 (MONITOR-PATH Low) | 维持现状 | 4 个页面统一写法；@Monitor 路径需字符串字面量，改常量无实际收益 |

### 文件改动清单

| 操作 | 文件 | 说明 |
|---|---|---|
| 新增 | `model/MaterialTargetModels.ets` | 迁入 `ZZZSkillType` / `ZZZSkillTarget` / `GenshinTalentSlot` / `StarRailSkillSlot` / `MaterialComputeTargets` / `MaterialTargetConfigParam` |
| 重写 | `model/ToolsModels.ets` | 只保留 `GameEntryVM`；去掉冗余 `@ObservedV2` / `@Trace` 与死字段 `gameColor`；re-export 迁出的模型 |
| 修改 | `viewmodel/ToolsViewModel.ets` | `hasComputeData` → `hasTargetConfig`；DAO 提为字段；`push` / for-of；删除 `gameColor` 赋值 |
| 修改 | `pages/ToolsPage.ets` | 删除只赋值不读取的 `uiContext` 与 `UIContext` import |
| 修改 | `views/GameEntryCard.ets` | `@Require`；箭头资源化；边框宽度走主题；Preview 去掉 `gameColor` |

### 已知问题记录（不执行）

| ID | 级别 | 描述 | 状态 |
|---|---|---|---|
| LIFE-002 | Medium | `loadData()` 无代际标记/取消，多次快速切换 Tab 可能交错写回 | 保留，单独提交 |
| KIT-005引申 | Medium | 加载异常落 EMPTY（登录引导），而非错误态 | 保留，行为变更 |
| N+1 | Medium | 每个角色一次 `findOne` 批量查询 | DAO 实例已复用；批量查询需 core 支持，保留 |
| DEAD-PARAM | Low | `accountId`/`roleUid` 传送给选角页但下游不使用且可能不配对 | 保留（测试断言 `accountId` 初始值） |
| MONITOR-PATH | Low | `@Monitor` 路径硬编码字符串 | 维持现状 |
| 分层 | Low | `MaterialCharacterSelectParam` 定义在 ViewModel、ToolsPage 直接 import | 随 M7 迁移到 model |

### 验收记录

| 项 | 结果 |
|---|---|
| 编译（uat/Debug） | ✅ `BUILD SUCCESSFUL in 17s 272ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目中无 `codeLinter` task（Hvigor 配置未启用），跳过 |
| Local Test | 🔶 `ToolsViewModel.test.ets` 4 条用例——需 DevEco GUI 手动运行，CLI 无 test 任务 |
| 测试契约 | ✅ `ToolsViewModel.ets` / `ToolsModels.ets` 路径与 `GameEntryVM` 导出不变 |
| 冒烟 | 🔶 待手动验证：底部 Tab → Tools；三游戏卡片进入/返回 |

### 结论

**M1 真重构完成**：`ToolsModels.ets` 135L → 43L（材料领域模型独立为 116L）；`hasComputeData` 更名为语义准确的 `hasTargetConfig`；删除 `gameColor` / `uiContext` 两处死代码；`GameEntryCard` 改用 `@Require`；箭头与边框宽度资源化；DAO 实例复用。行为等价，编译通过。

---

## M2 spec — PrivacyConsent 模块（2026-11-02 真重构）

分析依据：[`docs/privacy-consent-page-module-analysis.md`](../docs/privacy-consent-page-module-analysis.md)「重构执行备注」。

### 背景说明

模块共 4 个文件、364 行：`PrivacyConsentPage` 110L / `PrivacyConsentViewModel` 46L / `PrivacyConsentFooter` 98L / `PrivacyConsentWebView` 110L。测试只导入 `viewmodel/PrivacyConsentViewModel.ets`，并断言 `step` 为字符串 `'terms'` / `'privacy'`。

### 决策

| # | 问题 | 决定 | 依据 |
| --- | --- | --- | --- |
| D1 | `step` 是否改成 enum | 不改；新增 `PrivacyConsentStep` 字符串常量 | 测试 `assertEqual('terms'/'privacy')` 冻结 |
| D2 | 常量放哪里 | `model/PrivacyConsentModels.ets`；VM re-export | View 不反向依赖 ViewModel 实现 |
| D3 | 页面两个 WebView 分支是否合并 | 不合并 | 避免 `Web.src` 动态更新的不确定性，保持组件重建语义 |
| D4 | Footer 两个主按钮重复样式 | 抽 `@Builder primaryButton` | 两段样式逐项相同 |
| D5 | High：协议不足一屏时按钮永久禁用 | 单独提交修复 | 行为变更不得混入纯重构提交 |

### 文件改动清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 新增 | `model/PrivacyConsentModels.ets` | `PrivacyConsentStep.TERMS/PRIVACY` 常量 |
| 修改 | `viewmodel/PrivacyConsentViewModel.ets` | 使用常量并 re-export；导出符号与字段类型不变 |
| 修改 | `pages/PrivacyConsentPage.ets` | 提取 `isTermsStep` / `currentHtmlFile` / `canProceed` / `currentTitle` / `handleReachedBottom` |
| 修改 | `views/PrivacyConsentFooter.ets` | 主按钮抽 `@Builder`；步骤比较改用常量 |
| 修改 | `views/PrivacyConsentWebView.ets` | `SCROLL_SCRIPT` → `SCROLL_DETECTION_SCRIPT`；`injectAll` → `injectThemeAndScrollScript` |

### 验收记录

| 项 | 结果 |
|---|---|
| 编译（uat/Debug） | ✅ `BUILD SUCCESSFUL in 16s 153ms` |
| codeLinter | ⚠️ 项目中无 `codeLinter` task，跳过 |
| Local Test | 🔶 `PrivacyConsentViewModel.test.ets` 10 条用例——需 DevEco GUI 手动运行 |
| 测试契约 | ✅ VM 路径、类名、`step` 字符串值不变 |
| High 修复 | ✅ 不足一屏时脚本直接上报；`resize` 重新检测；`BUILD SUCCESSFUL in 16s 145ms` |
| 冒烟 | 🔶 待手动：两步流程、同意后进 Main、重启不重复弹出 |

### 结论

**M2 重构 + High 修复完成**：步骤常量集中到 model 层，页面分支逻辑提取为 getter/handler，Footer 主按钮去重，WebView 命名修正；另单独提交修复「协议不足一屏时按钮永久禁用」。Medium（`setAgreed` 失败后仍进 Main）保留。

---

*本文档为规划与执行记录；M0 代码改动见上方 `## M0 spec`。*
*进度（2026-11-02）：M0 已提交（`1ff4cfe`）；M1 真重构完成（`82cf004`）；M2 重构 + High 修复完成（待提交）；M3/M4 部分提交（`1ff4cfe`）；M8 真重构完成（`e831292`）；M5/M6/M7 仅完成命名核查，真重构待执行。*

---

## M8 spec — Home 模块（2026-11-01）

分析依据：[`docs/home-module-analysis.md`](../docs/home-module-analysis.md)。

### 背景

`HomeViewModel` 728 行，承担 DB 读取、三游戏快照解析、同步编排、冷启动处理、路由构造、卡片展示 6 类职责，超过 §6 N-2 的 500 行拆分阈值。测试 `features/home/src/test/HomeViewModel.test.ets` 直接导入 `viewmodel/HomeViewModel.ets` 并调用 `HomeViewModel.getGameColor`，路径与导出符号冻结。

### 文件映射

| 原文件 | 新文件 | 职责 |
|---|---|---|
| `viewmodel/HomeViewModel.ets`（728L） | `viewmodel/HomeViewModel.ets`（303L） | facade：状态字段 + 公开方法 + 静态展示方法（保留原导出符号） |
| 同上 | `viewmodel/HomeDataLoader.ets`（315L，新增） | `fetchAccounts` / `buildRoleCards` / `loadDailyNoteSnapshot` / `shouldSyncDailyNote` / `getDailyNoteLastSyncTime` |
| 同上 | `viewmodel/HomeSyncCoordinator.ets`（137L，新增） | `syncDailyNote` / `syncIfNeeded` / `syncAllDailyNotes` / `handleColdStartRefreshResult` |
| 同上 | `viewmodel/HomeCardPresenter.ets`（65L，新增） | `getGameColor` / `getGameLogo` / `syncDescKey` / `getPrimaryColor` |

### 命名修正

- `SkeletonBlock` 参数 `blockW/blockH/blockR` → `blockWidth/blockHeight/blockRadius`
- `GameToolCardHeader.syncDescResource(key)` → `syncKey`
- `loadDailyNoteSnapshot` 局部变量：`expCur/expMax` → `expeditionCurrent/expeditionMax`、`coinCur/coinMax` → `homeCoinCurrent/homeCoinMax`、`srRows` → `starRailRows`、`zzzisFull` → `isFull`、`zzzRecoverySec` → `recoverySeconds`、`vhsValue/vhsColor` → `videoStoreValue/videoStoreColor`、`cardSignDone` → `isCardSignDone`
- 删除废弃空方法 `HomeViewModel.showNextCookieExpiredDialog`（全仓无调用方）

### 决策

| # | 问题 | 决定 | 依据 |
|---|---|---|---|
| D1 | `HomeViewModel` 是否拆分 | 拆为 4 文件，保留 facade | §6 N-2：>500L 且点名 HomeViewModel；测试路径冻结 |
| D2 | 静态方法 `getGameColor` 等是否移出 | 保留在 `HomeViewModel` 上，内部委托 `HomeCardPresenter` | 测试直接调用 `HomeViewModel.getGameColor` |
| D3 | `syncDailyNote` 错误上报方式 | 由直接写 `networkErrorMsg` 改为返回错误字符串 + 回调，facade 统一写入 | 解耦 helper 与 VM 状态；逐角色提示行为等价 |
| D4 | `refresh` / `forceRefresh` 重复代码 | 提取 `performRefresh()` | 两方法除冷却检查外完全相同 |

### 验收

| 项 | 结果 |
|---|---|
| 编译（uat/Debug） | ✅ `BUILD SUCCESSFUL in 18s 80ms` |
| 最大文件行数 | ✅ 315L（`HomeDataLoader.ets`），低于 500L 阈值 |
| 测试契约 | ✅ `viewmodel/HomeViewModel.ets` 路径与 `HomeViewModel` / `getGameColor` 导出不变 |
| 行为等价 | ✅ 同步/加载/错误提示/冷却/定时器逻辑逐方法对照；错误提示仍按角色逐个触发 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| 冒烟 | 🔶 待手动：首页三游戏卡片、刷新、骨架屏 |
