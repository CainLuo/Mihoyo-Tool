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
- **`components/dailynote/`**：已是 `common` + `genshin` / `starrail` / `zzz` 结构，共 **17 个视图文件**（M6 后另增 `utils/` 3 个）；M6 的"三件套去重"实际上只需清理残余重复，不要按"4 个文件"的旧统计规划。
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
| M3 | AppearanceSettings | AppearanceSettingsPage | AppearanceSettingsViewModel | views/（ThemeModeRow）+ model/AppearanceSettingsModels | 路由文件路径冻结；与 theme 中心节点关联 |
| M4 | My | My | MyViewModel | views/（6 个：AccountListSection / AccountListItem / AppearanceSection / AboutSection / SectionHeader / SettingRow） | 有 Local Test |
| M5 | Notification | NotificationSettings | NotificationSettingsViewModel（318L） | `views/`（14）+ `views/NotificationSection.ets` + `model/service/`（6 个，含 `StaminaNoteReader`） | `NotificationModels` 被测试引用；服务层已做纯重构（670 → 490L），行为修复（M1/M2/M4/M7/M8）仍单独提交 |
| M6 | Dailynote | Genshin/StarRail/ZZZ DailyDetail ×3 | ×3 | dailynote/（views 17 个 + utils 3 个，已分 common/genshin/starrail/zzz） | 三页共用 `DailyDetailScaffold`；VM 共用 `DailyNoteLoader` / `ExpeditionMapper`；仅 Genshin 有测试 |
| M7 | MaterialCalc | MaterialCalc | MaterialCalcViewModel + MaterialCharacterSelectViewModel + MaterialTargetConfigViewModel ×3 | views/（MaterialCalc 8 个：MaterialCalcLevelPicker / Character / ContentView / EmptyView / Item / LoadingView / Section / Skills）+ materiallist/（6 个）+ `builders/MaterialCharacterSelectPageBuilder.ets` | `MaterialComputeService` facade；`MaterialCalcModels` 被测试引用 |
| M8 | Home | Home | HomeViewModel（754L，需拆分，保留 facade） | home/（10 个文件） | `models/HomeModels` 被测试引用（测试当前误写成 `components/home/HomeModels`，见 §0.4），不能移动 |
| M9 | Characters | Characters | CharactersViewModel | characters/（11 个：根级 5 + 3 个游戏子目录共 6） | 三件套去重；有 Local Test |
| M10 | CharDetail | Genshin/StarRail/ZZZ CharacterDetail ×3 | ×3 | chardetail/（common 9 + genshin 26 + starrail 11 + zzz 13 = 59） | 最大去重目标；`CharDetailModels` fan-in 41；仅 Genshin 有测试 |
| M11 | AccountDetail | AccountDetail | AccountDetailViewModel | accountdetail/（7） | 有 Local Test |
| M12 | Login | Login (+WebViewPage) | LoginViewModel | views/（19） | **已有根 spec `Refactor_Login_Spec.md`**：其中 build-profile/mock 分离不可执行，只取组件拆分；WebView 路由文件冻结 |
| M13 | WidgetConfig | WidgetSettings | WidgetSettingsViewModel | views/（23 = 13 根级 + preview/10） | 无 Local Test |
| M14 | Widget 子系统 | widget/pages ×6 | widget/viewmodel ×4 | `features/widget` 预览 views/preview（10）+ model/service + utils | V1 孤岛；与 widgetsyncability + notification 交互；form_config 路径冻结；本轮只重构 preview |
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
| M0 | 共享层 | [shared-layer](../docs/shared-layer-modules-analysis.md) | 0 Critical / 0 High；8 Medium（RouterUtil 静默失败、DialogDedup 释放协议脆弱、模型层混入 ArkUI 类型、MaterialComputeService 550 行 + N+1（550 行已由 M7 拆为 facade 163L + 5 文件，N+1 仍存）、themeManager 210 文件中心节点、隐式契约分散且 `SignalMonitorKey` 未被采用 / `AppRoutes` 与 routerMap 对应无编译检查、`MaterialComputeService.compute()` 部分异常未转 `FAILED` 且部分失败仍报 `SUCCESS`、`GeetestCenter` 申请 / 提交验证失败时无任何提示）+ 9 Low（启动主题 fire-and-forget、四处注释与代码不一致、`DarkTheme` 注释示例引用不存在的类、`SyncRetrySignal.accountId` 无读取方、透明色缓存不随深浅色重算、`SegmentedTabItem` 致 VM 反向依赖组件、`PlaceholderState` 装饰器不生效、`TimeFormatUtil.recoveryDesc` 不足 1 分钟显示「0 分钟」、Snackbar 关闭不 `dispose()`）；`HomeViewModel.test.ets` 引用失效属测试资产（不计入，见 §0.4） | M1、L2/L3/L4/L6 与死代码清理（不含冻结的 `AppRoutes.TOOLS` 与 `SignalMonitorKey` 值）随 M0，L9（Snackbar 关闭后 `dispose()`）同；L8 改文案单独提交；L1（改启动时序）留给 M15；L5 与 M3 一起验证；L7 记录；M2（超时释放会改变不重复弹出的语义）记录不执行；`compute()` 兜底、`GeetestCenter` 申请 / 提交失败提示各自单独提交（可感知行为变化）；M3/M4/M5、`SignalMonitorKey` 去留需决策；`@Monitor` 契约已在 §2.4 改正；外观页 High 的修复点在 M0 的 `AppearanceManager.applyColorMode`（内部吞异常），与 M3 协同 |
| M1 | Tools | [tools](../docs/tools-module-analysis.md) | 1 High（`loadData()` 无取消标记） | 记录；要修则单独提交 |
| M2 | PrivacyConsent | [privacy-consent](../docs/privacy-consent-page-module-analysis.md) | 1 Medium（`setAgreed` 失败后仍 `replace(MAIN)`） | 记录；要修则单独提交 |
| M3 | AppearanceSettings | [appearance-settings-page](../docs/appearance-settings-page-module-analysis.md) | 1 High（主题切换失败被 `AppearanceManager.applyColorMode` 内部吞掉，页面照常 `pop()` 且无提示） | 修复点在 M0 的 `AppearanceManager`（改为返回成功与否或重新抛出），会改变失败时的 UI 行为，与 M3 协同、单独提交 |
| M4 | My | [my](../docs/my-module-analysis.md) | 0 High；2 Medium（`AboutSection` 的 `@Param` 默认实例 + 依赖 page 类型）+ 1 Low（`onVisibleAreaChange` 无节流；原 ARKTS-012 经查 core `Logger` 已封装 hilog，撤回） | 随模块修；类型抽取与 M3 协调 |
| M5 | Notification | [notification-settings](../docs/notification-settings-module-analysis.md) / [notification-service](../docs/notification-service-modules-analysis.md) | 页面：0 High；1 Medium（`abilityContext=null` 时开关静默无响应）+ 2 Low（`@Monitor` 路径、改阈值不重排）。服务层：0 High；8 Medium（每次同步取消并重建全部提醒、30 条上限静默跳过、`onDailyNotesSynced` 被 Home 触发 3 次、wantAgent 硬编码 bundle、状态表无对账、即时通知重复发布、延迟未扣除已流逝时间、空 catch）+ 4 Low | 纯重构已完成；M1/M7、M4、M8 各自单独提交；M2/M6 需决策；M5 属构建配置；M9 已随重构关闭 |
| M6 | Dailynote | [daily-detail](../docs/daily-detail-modules-analysis.md) | 0 High；2 Medium（DAILY-M3 ERROR 显示为不可点击的"点击同步"空态、DAILY-M4 魔神任务卡片无数据源）+ 0 Low | 纯重构已完成（DAILY-M1 / L1 / L2 / I1 关闭，DAILY-M2 确认已修复）；M3 / M4 为行为变更，单独提交 |
| M7 | MaterialCalc | [material-calc](../docs/material-calc-module-analysis.md) / [material-list](../docs/material-list-modules-analysis.md) / [target-config](../docs/material-target-config-modules-analysis.md) / [character-select](../docs/material-character-select-module-analysis.md) | 0 Critical / **1 High**（`MaterialCalc` 路由未注册、页面不可达）；Medium 11 + Low 13（按 4 份文档 2026-10-27 的执行摘要合计，这 4 份文档第二轮复核未完成，数字待复核） | High 单独提交（需在 `custom_router_map.json` 注册或改由 navDestination 处理，涉及 resources 作用域，需用户批准）；其余记录，去重随模块（不改变 UI 行为） |
| M8 | Home | [home](../docs/home-module-analysis.md) | 2 High（ViewModel 754 行；Skeleton 动画未停） | 拆分随模块；动画修复随模块 |
| M9 | Characters | [characters](../docs/characters-module-analysis.md) | 0 High（原 H-1 已降为 M-1）；3 Medium + 4 Low | 纯重构已完成；`@Monitor` 收敛 / 冷却 Dialog / 代次保护保留 |
| M10 | CharDetail | [genshin](../docs/genshin-character-detail-module-analysis.md) / [starrail](../docs/starrail-character-detail-module-analysis.md) / [zzz](../docs/zzz-character-detail-module-analysis.md) | SR / Genshin / ZZZ 各 1 High（`parseRawJson` 未设 ERROR）；SR `entityId === '1510'` 空循环已删除 | SR/Genshin/ZZZ 各 1 High 保留，行为修复待单独提交（三游统一状态兜底） |
| M11 | AccountDetail | [account-detail](../docs/account-detail-module-analysis.md) | 0 Critical / 0 High；2 Medium（删除无二次确认、删除失败无反馈）+ 1 Low（`as common.UIAbilityContext` 强转） | 记录；删除相关行为修复单独提交 |
| M12 | Login | [login](../docs/login-module-analysis.md) / [webview](../docs/webview-page-module-analysis.md) | 0 Critical / 0 High（二维码轮询取消标记已由 `b98abae` 修复，复核撤回；原 SEC-002「Cookie 日志明文」经逐层核查无凭据落盘路径，降为 Medium 加固）；4 Medium / 2 Low；WebView 0 High（2 Low） | 无阻断项；三种登录共用 `buildCookie()`、魔法数字收敛、错误提示组件化已执行；日志脱敏 / `@Event` 风格 / 协议后缀行为修复保留，WebView 仅记录 |
| M13 | WidgetConfig | [widget-settings](../docs/widget-settings-module-analysis.md) | 0 High；1 Medium（`vm.init()` 失败后静默回退空配置，无错误态/重试；`isLoading` 必被置 false）+ 1 Low | 随模块修；VM 676→447L 已拆出尺寸映射 / 账号分组 / 持久化；未用 `@Local tm` 已删 |
| M14 | Widget 子系统 | [widget-subsystem](../docs/widget-subsystem-modules-analysis.md) / [widget-settings](../docs/widget-settings-module-analysis.md) / [component-dedup](../docs/component-deduplication-review.md) | 0 Critical / 3 High（瞬时更新失败即删用户卡片配置；无数据时展示 Mock 账号与体力；卡片从不显示数据新鲜度）；6 Medium / 3 Low；V1 孤岛（16 个 V1 文件：6 pages + 10 components） | H1/H2 保留（各自单提交），H3 需产品决策；装饰器不迁移；form_config 6 条 src 冻结；本轮只重构 preview 组件（2x4 361→218L、4x4 246→238L） |
| M15 | 框架 | [main](../docs/main-module-analysis.md) / [index](../docs/index-module-analysis.md) / [launch](../docs/launch-module-analysis.md) / [test-page](../docs/test-page-module-analysis.md) / [ability-startup](../docs/ability-and-startup-modules-analysis.md) | MainPage 2 High（人机验证弹窗关闭时无 callback 地 `off('windowSizeChange')`，注销窗口尺寸监听；返回手势关闭验证框后验证队列永久卡死——10-29 复核恢复）；10 Medium / 6 Low（含 Cookie 过期弹框叠加、窗口 API 未包 try、Tab 根页按返回可能显示空白——待真机确认）；Index / Launch 0 High；TestPage 0 High（入口仅 DEBUG 可见，Q-2）；Ability 0 High / 4 Medium（初始化失败不可见、4 个 AppStorage key 无常量、`loadContent` 无兜底、导出 ability 不校验调用方） | MainPage 513→473L 已收敛工具栏 / 窗口模式 / 弹窗标签；H1/H2 与 `MainTabContainer` / `DialogArbiter` 大拆分保留；Index / Launch / TestPage 未改 |

> 原则：重构提交**不夹带行为变更**；Critical/High 若要修，先在本表登记并在 `## M<n> spec` 说明，修复与移动分开提交。

## 十二、执行台账与回滚（新增）

| M | 模块 | 状态 | 分支 | commit | 编译 | codeLinter | Local Test / 冒烟 | review | 遗留 |
|---|---|---|---|---|---|---|---|---|---|
| M0 | 共享层 | ✅ 已提交（导出清理 + 工具去重 + 日志） | — | 1ff4cfe | ✅ 随 M8 构建通过 | ⚠️ 跳过 | 🔶 待冒烟 | 文档 13 轮复核 | M8/外观页 High 已补字符串；M7 部分失败待产品决策 |
| M1 | Tools | ✅ 真重构完成 | — | 82cf004 | ✅ BUILD SUCCESSFUL in 17s 272ms | ⚠️ codeLinter 未配置，跳过 | 🔶 待 DevEco GUI 运行 | 6 Medium/Low 记录不执行 | ToolsModels 拆分 + 死代码清理；LIFE-002/N+1 保留 |
| M2 | PrivacyConsent | ✅ 重构 + High 修复完成 | — | 8a85078 / ed45262 | ✅ BUILD SUCCESSFUL in 16s 145ms | ⚠️ 跳过 | 🔶 待运行 | — | 步骤常量/model、Footer 去重；不足一屏卡死已修 |
| M3 | AppearanceSettings | ✅ 真重构完成 | — | 1ff4cfe / b6d8309 | ✅ BUILD SUCCESSFUL in 15s 856ms | ⚠️ 跳过 | 🔶 待运行 | — | 新增 Models 35L；VM 81→55L；Param/ThemeModeItem 移入 model；标签映射共用 |
| M4 | My | ✅ 真重构完成 | — | 1ff4cfe / b6d8309 | ✅ BUILD SUCCESSFUL in 15s 856ms | ⚠️ 跳过 | 🔶 待运行 | — | MyPage 150→135L；VM 116→102L；导航收敛 openDetail；AppearanceSection 72→59L |
| M5 | Notification | ✅ 纯重构完成（行为修复待单独提交） | — | 5ca87a1 | ✅ BUILD SUCCESSFUL in 15s 80ms | ⚠️ 跳过 | 🔶 待运行 | — | 服务 670→490L + Reader 83L；VM 399→318L；M1/M2/M4/M7/M8 保留 |
| M6 | Dailynote | ✅ 真重构完成 | — | 7002525 | ✅ BUILD SUCCESSFUL in 15s 175ms | ⚠️ 跳过 | 🔶 待运行 | — | 页面 131/123/123→60/57/57；新增 Scaffold + 3 个 utils；M3/M4 保留 |
| M7 | MaterialCalc | ✅ 完成 | — | 36099a9 / 045437f / 41a09bb / a78d749 | ✅ BUILD SUCCESSFUL in 14s 73ms | ⚠️ 跳过 | 🔶 待运行 | — | 材料汇总 186→55L；目标配置 342/346/410→261/265/266L；角色选择 493→360L + Card 156L；MaterialCalc 页 111→109L、VM 493→465L；Service 560→163L + 5 文件 |
| M8 | Home | ✅ 真重构完成 | — | e831292 | ✅ BUILD SUCCESSFUL in 18s 80ms | ⚠️ 跳过 | 🔶 待运行 | — | 已拆 4 文件，最大 315L |
| M9 | Characters | ✅ 真重构完成 | — | fafcabc | ✅ BUILD SUCCESSFUL in 15s 736ms | ⚠️ 跳过 | 🔶 待运行 | — | VM 614→434L；新增 CharactersDataLoader 171L；测试契约不变 |
| M10 | CharDetail | ✅ 真重构完成（行为修复待单独提交） | — | 81d7e9d | ✅ BUILD SUCCESSFUL in 14s 775ms | ⚠️ 跳过 | 🔶 待运行 | — | 三页 150/137/137→129/116/116L；新增 CharDetailWindowSize 56L + CharDetailHeroScaffold 99L；三游戏 parseRawJson ERROR 兜底保留 |
| M11 | AccountDetail | ✅ 真重构完成（行为修复待单独提交） | — | c15d53b | ✅ BUILD SUCCESSFUL in 34s 393ms | ⚠️ 跳过 | 🔶 待运行 | — | ActionsSection 4 按钮收敛为 Builder；页面结果 Toast 收敛；VM 删除 refreshCookieError 死字段；删除二次确认 / 失败反馈保留 |
| M12 | Login | ✅ 真重构完成（行为修复待单独提交） | — | f9858e0 | ✅ BUILD SUCCESSFUL in 16s 267ms | ⚠️ 跳过 | 🔶 待运行 | — | 三种登录共用 `buildCookie()`；魔法数字收敛到 `LoginConstants`；新增 `LoginErrorText`；日志脱敏 / `@Event` 风格 / 协议后缀保留 |
| M13 | WidgetConfig | ✅ 真重构完成（行为修复待单独提交） | — | 965bb49 | ✅ BUILD SUCCESSFUL in 15s 331ms | ⚠️ 跳过 | 无 Local Test（冒烟待手动） | — | VM 676→447L；新增 SizeConfig 56L + AccountGroups 61L + ConfigSaver 96L；步骤流程去重；删除未用 `@Local tm`；M1/M2 行为修复保留 |
| M14 | Widget 子系统 | ✅ 预览组件重构完成（V1 孤岛按契约不动） | — | 1ab3d43 | ✅ BUILD SUCCESSFUL in 15s 218ms | ⚠️ 跳过 | 无 Local Test（冒烟待手动） | — | 2x4 361→218L（extraRow / expeditionAvatar Builder）；4x4 246→238L（dataRow Builder）；清理未用导入；H1/H2/H3 保留 |
| M15 | 框架 | ✅ 真重构完成（行为修复 / 大拆分保留） | — | 待补 | ✅ BUILD SUCCESSFUL in 14s 996ms | ⚠️ 跳过 | 无自动化测试（冒烟待手动） | — | MainPage 513→473L；新增 MainNavigationMode 26L + MainDialogLabels 21L；工具栏 / 窗口模式 / 弹窗标签收敛；Index / Launch / TestPage 未改；H1/H2 保留 |

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
- **M2 / M3 / M4 / M5**：按上表记录；M3 / M4 已于 2026-11-05 完成真重构。

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

## M3 spec — AppearanceSettings 模块（2026-11-05 真重构）

分析依据：[`docs/appearance-settings-page-module-analysis.md`](../docs/appearance-settings-page-module-analysis.md)「重构执行备注」。

### 背景说明

模块 5 个文件：`AppearanceSettingsPage` 163L / `AppearanceSettingsViewModel` 55L / `ThemeModeRow` 86L / `AppearanceSettingsModels` 35L / `AppearanceManager` 114L。无 Local Test；页面路径与 `AppearanceSettingsPageBuilder` 名被 `custom_router_map.json` 冻结。

### 文件改动清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 新增 | `model/AppearanceSettingsModels.ets`（35L） | `AppearanceSettingsParam` / `ThemeModeItem` / `getThemeModeLabel()` |
| 修改 | `pages/AppearanceSettingsPage.ets`（168 → 163L） | 路由参数类移出；改从 model 导入；删除 `ConfigurationConstant` 死导入 |
| 修改 | `viewmodel/AppearanceSettingsViewModel.ets`（81 → 55L） | 删除无调用方的 `getThemeModeLabel()`；`ThemeModeItem` 移入 model；标签统一走共享函数 |
| 修改 | `views/ThemeModeRow.ets` | `ThemeModeItem` 改从 model 导入 |
| 修改 | `Index.ets` | `AppearanceSettingsParam` 改从 model 导出，新增 `getThemeModeLabel` 导出 |
| 修改 | M4 `views/AppearanceSection.ets` | 删除重复的私有标签映射，改用 settings 导出函数 |

### 验收记录

| 项 | 结果 |
|---|---|
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 15s 856ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| Local Test | 🔶 无测试 |
| 测试契约 | ✅ 无测试引用；路由 / Builder 名未变 |
| 冒烟 | 🔶 待手动：我的 → 外观设置 → 三种模式切换 → 返回；重启后保持 |

### 结论

**M3 真重构完成**：路由参数与 `ThemeModeItem` 移入模型层，解除 My 页对 page 文件的类型依赖；删除 VM 死方法，标签映射由 settings 统一导出、M4 复用。High（`applyColorMode` 失败仍 pop）与重复点击已在 `1ff4cfe` 修复。

---

## M4 spec — My 模块（2026-11-05 真重构）

分析依据：[`docs/my-module-analysis.md`](../docs/my-module-analysis.md)「重构执行备注」。

### 背景说明

模块文件：`MyPage` 135L / `MyViewModel` 102L / 6 个视图组件 / `MyModels` 89L。`MyViewModel.test.ets` 断言初始 `viewState` / `accounts`，VM 路径与导出符号冻结；`MyAccountVM` 同时是 `ACCOUNT_DETAIL` 路由参数，`MyModels` 不得移动。

### 文件改动清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 修改 | `pages/MyPage.ets`（150 → 135L） | 5 处 `isSplit ? replacePath : pushPathByName` 收敛为 `openDetail(name, param)` |
| 修改 | `viewmodel/MyViewModel.ets`（116 → 102L） | 三条 `from 'core'` 导入合并；头部注释改为「只读 DB，不做网络补充」 |
| 修改 | `views/AppearanceSection.ets`（72 → 59L） | 删除重复的 `getThemeModeLabel()`，改用 settings 导出函数 |
| 修改 | `views/SettingRow.ets` | 删除 Preview 中重复的 `.backgroundColor(...)` |
| 修改 | `pages/MyPage.ets` import | `AppearanceSettingsParam` 仍从 `'settings'` 导入（M3 已移入 model），跨页类型依赖解除 |

### 验收记录

| 项 | 结果 |
|---|---|
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 15s 856ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| Local Test | 🔶 `MyViewModel.test.ets` 2 条用例——需 DevEco GUI 手动运行 |
| 测试契约 | ✅ VM 路径与导出符号不变 |
| 冒烟 | 🔶 待手动：我的页各 Section、账号列表、外观 / 通知入口；窄屏 push 与宽屏 replacePath；AboutSection 滚动刷新 |

### 结论

**M4 真重构完成**：My 页导航分支收敛，VM 导入与注释修正，外观标签映射与 M3 共用，删除 Preview 死样式行。Medium（`AboutSection` 的 `@Param` 默认实例）与 4 条 Low 保留，属行为变更。

---

*本文档为规划与执行记录；M0 代码改动见上方 `## M0 spec`。*
*进度（2026-11-05）：M0 已提交（`1ff4cfe`）；M1 真重构完成（`82cf004`）；M2 重构 + High 修复完成（`8a85078` / `ed45262`）；M3 / M4 真重构完成（`b6d8309`）；M5 纯重构完成（`5ca87a1`）；M6 真重构完成（`7002525`）；M7 四个子区域完成（`a78d749`）；M8 真重构完成（`e831292`）；M9 真重构完成（`fafcabc`）；M10 真重构完成（`81d7e9d`）；M11 真重构完成（`c15d53b`）；M12 真重构完成（`f9858e0`）；M13 真重构完成（`965bb49`）；M14 预览组件重构完成（`1ab3d43`）；M15 真重构完成（提交待补）。*

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

---

## M5 spec — Notification 模块（2026-11-02 真重构）

分析依据：[`docs/notification-settings-module-analysis.md`](../docs/notification-settings-module-analysis.md) 与 [`docs/notification-service-modules-analysis.md`](../docs/notification-service-modules-analysis.md)。

### 背景说明

页面层：`NotificationSettingsPage` 40L + `NotificationSection` 113L + `NotificationSettingsViewModel` 399L + `views/` 14 个组件。
服务层：`StaminaNotificationService` 670L、`NotificationSettingsStore` 115L、`NotificationModels` 104L、`NotificationStateStore` 102L、`StaminaThresholdCalculator` 70L。
测试只直接导入 `model/NotificationModels.ets` 与 `model/service/StaminaThresholdCalculator.ets`；服务本体未被测试 import。

### 决策

| # | 问题 | 决定 | 依据 |
| --- | --- | --- | --- |
| D1 | `StaminaNotificationService` 670L 是否拆文件 | 不拆调度类；把 daily_note 读取抽到 `StaminaNoteReader` | 调度与 reminderAgent 调用序列紧耦合；读取逻辑可独立复用且设置页也需要 |
| D2 | STYLE_A / STYLE_B 两套调度链路 | 统一为 `resolveSchedule` + `StaminaSchedule` | 两套链路除最终呈现外步骤完全相同，重复近 50 行 |
| D3 | 两套代理提醒发布方法 | 合并为 `publishTimerReminder(schedule, body)` | 标题、WantAgent、关闭按钮、状态写回完全一致，仅正文不同 |
| D4 | 游戏名称 / 体力名称 / 恢复秒数映射 | 收敛到 `GameStaminaConstants` + `GameStaminaResources` | VM 与 service 原本各写一份 if 链 |
| D5 | `getFallbackMax(gameId: string)` | 收紧为 `GameId` | 调用方与测试均传 `GameId`，编译期可校验 |
| D6 | M1/M2/M4/M7/M8 行为缺陷 | 本轮不修，单独提交 | §9「重构提交不夹带行为变更」 |

### 文件改动清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 新增 | `model/service/StaminaNoteReader.ets`（83L） | 三游戏 daily_note 读取与解析，输出 `StaminaSnapshot` |
| 修改 | `model/NotificationModels.ets`（104 → 181L） | `getSecondsPerUnit`、`getFallbackMax(GameId)`、`GameStaminaResources` |
| 修改 | `model/service/StaminaNotificationService.ets`（670 → 490L） | `StaminaSchedule` + `resolveSchedule` + `dispatchImmediateOrTimer` + `publishTimerReminder` + `saveState` + `createNotificationWantAgentInfo`；删除注释死代码与空 catch |
| 修改 | `viewmodel/NotificationSettingsViewModel.ets`（399 → 318L） | 使用 `StaminaNoteReader` / `GameStaminaResources` / `basic.getGameName` / `getSecondsPerUnit`；`Set` 去重、`find`、`slice`、`cloneGameConfig`、`saveGameSetting` |

### 已知问题记录（不执行）

| ID | 级别 | 描述 | 状态 |
| --- | --- | --- | --- |
| M1 | Medium | 每次同步取消并重建已有提醒，`shouldReschedule` 未启用 | 保留，单独提交 |
| M2 | Medium | 30 条上限命中后静默跳过 | 保留，需产品决策 |
| M4 | Medium | Home 3 处触发 `onDailyNotesSynced` 且无并发保护 | 保留，单独提交 |
| M5 | Medium | WantAgent bundle / ability 硬编码 | 保留，构建配置修复 |
| M6 | Medium | 状态表与系统提醒无对账 | 保留，需存储设计 |
| M7 | Medium | 已达阈值角色每次同步重发即时通知 | 保留，与 M1 同提交 |
| M8 | Medium | 延迟未扣除已流逝时间 | 保留，单独提交 |
| L1–L4 | Low | 权限时序 / 上限双源 / 错误信息 / 通知撤回 | 保留 |
| 页面 Medium | Medium | 改阈值 / 一键满值只取消不重排 | 保留 |
| 页面 Low ×2 | Low | `abilityContext` 为 null 静默；`@Monitor` 路径未用常量 | 保留 |

### 验收记录

| 项 | 结果 |
|---|---|
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 15s 80ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目中无 `codeLinter` task，跳过 |
| Local Test | 🔶 `StaminaNotificationService.test.ets` 26 条 + `StaminaThresholdCalculator.test.ets` 23 条——需 DevEco GUI 手动运行 |
| 测试契约 | ✅ `NotificationModels.ets` / `StaminaThresholdCalculator.ets` 路径与导出符号不变 |
| 冒烟 | 🔶 待手动：通知设置页、开关权限、阈值调整、前台/后台同步提醒 |

### 结论

**M5 纯重构完成**：服务层抽出 `StaminaNoteReader`，STYLE_A / STYLE_B 共用 `resolveSchedule` 与 `publishTimerReminder`，三处状态写回与 WantAgent 构建去重；页面 VM 复用共享读取器与资源映射，去掉手写循环 / 复制 / 查询。服务 670 → 490L，VM 399 → 318L，行为等价，编译通过。M1/M2/M4/M7/M8 等行为修复仍按计划单独提交。

---

## M6 spec — Dailynote 模块（2026-11-02 真重构）

分析依据：[`docs/daily-detail-modules-analysis.md`](../docs/daily-detail-modules-analysis.md)。

### 背景说明

模块共 24 个源文件：3 个页面（131 / 123 / 123 行）、3 个 ViewModel（97 / 82 / 63 行）、1 个模型文件、17 个视图组件。三页约 90% 同构（window 监听 + 三态分支 + 滚动容器），两个 VM 各写一份派遣转换，三个游戏各写一份体力比例配色。

### 决策

| # | 问题 | 决定 | 依据 |
| --- | --- | --- | --- |
| D1 | 三页骨架是否抽共享组件 | 抽 `DailyDetailScaffold`（`@BuilderParam` 内容槽） | 90% 重复且逻辑稳定；页面壳保留 Param / VM / 内容插槽 |
| D2 | `windowWidthVp` + `display` + `windowSizeChange` | 删除 | 三页均只写不读，宽屏实际只靠 `maxWidth 600` |
| D3 | 三个 VM 的 `loadData` 流程 | 抽 `loadDailyNote()`，返回 `DailyNoteLoadResult<T>` | 三份 LOADING / EMPTY / DATA / ERROR + 日志完全一致 |
| D4 | 原神 / 星铁派遣转换 | 抽 `toExpeditionVMs()`，参数用两类型联合 | 字段一致（avatarSideIcon / status / remainedTime）；ArkTS 无结构化类型，不用 interface |
| D5 | 三游戏体力阈值配色 | 抽 `getStaminaRatioColor(current, max, tm)` | 30% / 70% 阈值与颜色映射逐行相同 |
| D6 | `DailyNoteCard` 未使用插槽 | 删除 `icon` / `hasIcon` / `customRight` / `hasCustomRight` | 全仓无调用方，属投机扩展 |
| D7 | DAILY-M3 / M4 | 本轮不修，单独提交 | 均为用户可见行为变更 |

### 文件改动清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 新增 | `views/common/DailyDetailScaffold.ets`（67L） | NavDestination 标题栏 + 三态分支 + Scroll / 宽屏约束 |
| 新增 | `utils/DailyNoteLoader.ets`（42L） | `loadDailyNote()` 与 `DailyNoteLoadResult<T>` |
| 新增 | `utils/ExpeditionMapper.ets`（22L） | `ExpeditionSource` 联合类型 + `toExpeditionVMs()` |
| 新增 | `utils/StaminaColorUtil.ets`（21L） | `getStaminaRatioColor()` |
| 修改 | 3 个页面（131/123/123 → 60/57/57L） | 删除 window / display 样板；改用 Scaffold + `@Builder gameContent()` |
| 修改 | 3 个 VM（97/82/63 → 82/70/62L） | `loadData` 改用 loader；派遣改用 mapper |
| 修改 | `views/common/DailyNoteCard.ets` | 删除 4 个未使用参数；`title` 改 `@Require`；Preview 去掉死 `tm` |
| 修改 | `DailyNoteDataRow` / `DailyNoteSectionLabel` / `GenshinDailyTaskContent` / `ExpeditionItem` | 必填参数改 `@Require`，删除无意义默认值 |
| 修改 | `DailyNoteGenshin` / `StarRailStaminaCard` / `ZZZDailyCard` | 改用 `getStaminaRatioColor`；删除 `StarRailStaminaCard.uiCtx` 死字段 |
| 修改 | 3 个游戏入口组件 | Preview mock 函数统一命名 `createPreviewXxxNote` |

### 已知问题记录（不执行）

| ID | 级别 | 描述 | 状态 |
| --- | --- | --- | --- |
| DAILY-M3 | Medium | ERROR 与 EMPTY 共用"暂无数据，点击同步"空态，无点击 / 无错误提示 | 保留，单独提交 |
| DAILY-M4 | Medium | 原神魔神任务卡片字段从未赋值；`storedAdventure` 固定 -1 | 保留，需产品决策 |
| DAILY-M2 | 测试资产 | 测试曾引用失效方法 | ✅ 当前 32 行 / 2 用例，已无失效引用 |

### 验收记录

| 项 | 结果 |
| --- | --- |
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 15s 175ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| Local Test | 🔶 `GenshinDailyDetailViewModel.test.ets` 2 条用例——需 DevEco GUI 手动运行 |
| 测试契约 | ✅ VM 路径、类名、`viewState` / `note` 字段不变 |
| 路由契约 | ✅ 三个 `pageSourceFile` 与 `*PageBuilder` 名不变；Param 类仍在原页面文件 |
| 冒烟 | 🔶 待手动：三个游戏便笺详情、三态、宽屏 600 |

### 结论

**M6 真重构完成**：三页骨架收敛到 `DailyDetailScaffold`，页面 131/123/123 → 60/57/57 行；VM 加载流程、派遣转换、体力配色各自去重；删除三页无效 window 监听与 `DailyNoteCard` 未使用插槽。行为等价，编译通过。DAILY-M3 / M4 保留待单独提交。

---

## M7 spec — MaterialCalc 模块（2026-11-04 真重构，已完成）

分析依据：[`docs/material-calc-module-analysis.md`](../docs/material-calc-module-analysis.md) / [`docs/material-list-modules-analysis.md`](../docs/material-list-modules-analysis.md) / [`docs/material-target-config-modules-analysis.md`](../docs/material-target-config-modules-analysis.md) / [`docs/material-character-select-module-analysis.md`](../docs/material-character-select-module-analysis.md)。

### 背景说明

M7 覆盖「材料计算 → 选角色 → 目标配置（×3）→ 材料汇总（×3）」链路。四个子区域共 3 个路由入口 + 6 个页面，其中三份材料汇总页 186 行几乎逐行相同；三份目标配置页各有一份 `LevelRow` / `SkillLevelRow`；多个 VM / 组件存在死导入、死字段与重复格式化实现。

### 子区域拆分与顺序

| # | 子区域 | 状态 | 提交 |
| --- | --- | --- | --- |
| 1 | MaterialList（三页 + 三 VM） | ✅ 完成 | 36099a9 |
| 2 | TargetConfig（三页 + 三 VM） | ✅ 完成 | 045437f |
| 3 | CharacterSelect | ✅ 完成 | 41a09bb |
| 4 | MaterialCalc 页 + `MaterialComputeService` | ✅ 完成 | a78d749 |

### MaterialList 执行记录

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 新增 | `views/MaterialListScaffold.ets`（164L） | 标题栏 + 同步/配置菜单 + 视图模式 Tab + 三态 + 空态按钮；内部 `localStack` 处理「更改配置」跳转 |
| 新增 | `utils/MaterialAmountUtil.ets`（39L） | `formatCurrencyAmount()`，合并三份「万 / 亿」实现 |
| 修改 | 三个 `*MaterialListPage.ets`（186 → 55L） | 只保留 VM、路由参数与回调；删除 `Logger` / `GameId` 死导入与重复日志 |
| 修改 | 三个 `*MaterialListViewModel.ets`（686/405/437 → 628/368/421L） | 删除无调用方的 `refresh()` / `isRefreshing`；原神删除静态 `formatCurrencyAmount`；星铁删除 `'1510'` 调试循环与空 `if` |
| 修改 | `MaterialGridCard.ets` / `MaterialGridItem.ets` | 改用共享 `formatCurrencyAmount`，删除各自私有实现 |

### TargetConfig 执行记录

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 新增 | `views/LevelConfigRow.ets`（76L） | 「当前 / 目标」两列等级行，点击回调由页面提供 |
| 新增 | `views/TargetConfigTipCard.ets`（32L） | 顶部提示卡片 |
| 修改 | 三个 `*MaterialTargetConfigPage.ets`（342/346/410 → 261/265/266L） | 删除 `TipCard` / `LevelRow` / ZZZ `SkillLevelRow` 四份同构 Builder；ZZZ 技能行改用 `LevelRow('skill' + skillType, skill)` |
| 修改 | 同上 | 删除 `pickerConfigKey` / `pickerStep` / `pickerValue` 实例字段；`confirmPicker(key, step, value)` 显式传参 |

### CharacterSelect 执行记录

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 新增 | `views/CharacterSelectCard.ets`（156L） | 网格角色卡片，从页面内嵌 struct 提取 |
| 修改 | `pages/MaterialCharacterSelectPage.ets`（493 → 360L） | 删除内嵌卡片、空 `@Monitor('vm.canStart')`、`@Param detailStack` 与三处回退、`uiContext` 死字段、死导入；新增 `gameId` getter |
| 修改 | `viewmodel/MaterialCharacterSelectViewModel.ets`（448 → 432L） | 删除未使用的 `getGameColor` / `getGameLogo` / `getGameName` 导入 |

### MaterialCalc 执行记录

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 重命名 | `views/LevelPicker.ets` → `views/MaterialCalcLevelPicker.ets`（137L） | struct 统一为 `MaterialCalcLevelPicker` / `MaterialCalcLevelPickerItem` / `MaterialCalcLevelPickerPreview` |
| 修改 | `pages/MaterialCalcPage.ets`（111 → 109L） | 删除 `GameId` 死导入，改用 `MaterialCalcLevelPicker` |
| 修改 | `views/MaterialCalcContentView.ets` | 删除 `LevelOptionVM` 死导入 |
| 修改 | `viewmodel/MaterialCalcViewModel.ets`（493 → 465L） | `buildGenshinSkills` / `buildStarRailSkills` / `buildZZZSkills` 的重复循环合并为 `buildSkillTargets(skillTypes, currentLevel, maxLevel)`；技能 ID / 名称 / 初始等级保持（10/10/10、10/10/10、1/12/12）；`refresh()` / `isRefreshing` 保留（测试断言） |
| 拆分 | `model/service/MaterialComputeService.ets`（560 → 163L） | facade 保留 `hasSavedConfig` / `loadSavedTargets` / `compute` / `computeInternal` / `findAccount` / `findRole`，按 `gameId` 分派 |
| 新增 | `model/service/MaterialComputeResult.ets`（19L） | `MaterialComputeResult` 枚举；facade `export { MaterialComputeResult } from './MaterialComputeResult'`，原导入路径不变 |
| 新增 | `model/service/MaterialComputeUtils.ets`（44L） | 日志 tag、`clampLevel` / `toResult` / `parseObject` / `getErrorMessage` |
| 新增 | `model/service/GenshinMaterialCompute.ets`（51L） | 原神批量计算 |
| 新增 | `model/service/StarRailMaterialCompute.ets`（210L） | 星铁逐角色计算 + 星魂加成 / 行迹目标换算 |
| 新增 | `model/service/ZZZMaterialCompute.ets`（142L） | 绝区零逐代理人计算 + 技能等级解析 |

### 契约与冻结项

- 三个 `*MaterialList` 路由与 `GenshinMaterialListPageBuilder` / `StarRailMaterialListPageBuilder` / `ZZZMaterialListPageBuilder` 名冻结。
- 三个 `*MaterialTargetConfig` 路由与 Builder 名冻结；`MaterialCharacterSelect` 的 Builder 文件路径 / 函数名冻结。
- `MaterialTargetConfigParam` 仍在 `model/ToolsModels.ets`；三个 VM 的路径与导出符号不变；`MaterialCharacterSelectRouteParam` 保持 interface。
- `MaterialCalcParam` 仍在 `pages/MaterialCalcPage.ets`（被 `GenshinCharacterDetailPage` import）；`MaterialCalcPageBuilder` 名冻结；`MaterialComputeResult` 仍从 `model/service/MaterialComputeService` 导出。
- M7 无 MaterialList / TargetConfig / CharacterSelect Local Test；`MaterialCalcViewModel.test.ets` 不受本次改动影响。

### 验收记录

| 项 | 结果 |
| --- | --- |
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 14s 73ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| Local Test | 🔶 MaterialList / TargetConfig / CharacterSelect 无测试；`MaterialCalcViewModel.test.ets` 需 DevEco GUI 手动运行 |
| 测试契约 | ✅ 三个 VM 路径与导出符号不变；`MaterialComputeResult` 仍从 `MaterialComputeService` 导出 |
| 冒烟 | 🔶 待手动：三游戏材料汇总页、两个 Tab、更改配置入口、空态同步；三游戏目标配置页、等级 Picker、提交后跳转；角色选择页网格 / 多选上限 / 菜单；MaterialCalc 入口（H-1 未修前仍不可达） |

### 已知问题记录（不执行）

| ID | 级别 | 描述 | 状态 |
| --- | --- | --- | --- |
| M-LIST-2 | Medium | 重新计算失败对用户静默 | 保留，单独提交 |
| M-LIST-6 | Low | 「万 / 亿」中文单位未资源化 | 保留，属文案变更 |
| M-TARGET-4 | Low | 目标配置页标题仍用材料汇总页资源 | 保留，属文案变更 |
| M-TARGET-5 | Low | Picker 选项硬编码中文「级」 | 保留，属文案变更 |
| M-CALC-H1 | High | `MaterialCalc` 路由未注册，页面不可达 | 保留，需用户批准改 `custom_router_map.json` |
| M-CALC-M1 | Medium | `vm.init()` 的 `getGameRoles` 不在 try-catch 内，失败时页面卡 LOADING | 保留，单独提交 |
| M-CALC-M2 | Medium | 目标等级设置链路为占位实现（`recalculateMaterials()` 空） | 保留，单独提交 |
| M-CALC-M3 | Medium | 角色不存在时 EMPTY 被 `loadData()` 覆盖为 DATA | 保留，单独提交 |
| M-CALC-M4 | Medium | 原神材料行 `?? computeRows[0]` 回退到其他角色 | 保留，单独提交 |
| M-CALC-I1 | 信息 | 模型层 4 个死字段（`MaterialSectionVM.iconUrl` / `SkillTargetVM.iconUrl` / 两个 `maxLevel`） | 记录，待模型层统一清理 |
| M-CALC-I2 | 信息 | facade 通用日志沿用 `GENSHIN_TAG`（`'GenshinCalc'`），拆分后原样保留 | 记录，改 tag 属行为变更 |
| `GenshinMaterialListViewModel` | 信息 | 628L，仍超 500L 阈值 | 无测试，拆分待补测试后再做 |

### 结论

**M7 完成**：MaterialList / TargetConfig / CharacterSelect / MaterialCalc 四个子区域全部完成——材料汇总三页 186 → 55L，新增共享 `MaterialListScaffold`，三个 VM 删除死代码，三份「万 / 亿」实现合并；目标配置三页 342/346/410 → 261/265/266L，新增 `LevelConfigRow` / `TargetConfigTipCard`，ZZZ `SkillLevelRow` 与 Picker 实例字段删除；角色选择页 493 → 360L，卡片提取为 `CharacterSelectCard`，删除空 `@Monitor`、`detailStack` 回退与死导入；MaterialCalc 页 111 → 109L、VM 493 → 465L，`LevelPicker` 统一为 `MaterialCalcLevelPicker`，三份技能构建合并为 `buildSkillTargets`；`MaterialComputeService` 560L 按 facade 拆为 163L + 5 个文件（Result / Utils / 三游戏计算）。行为等价，编译通过。

---

## M9 spec — Characters 模块（2026-11-05 真重构）

分析依据：[`docs/characters-module-analysis.md`](../docs/characters-module-analysis.md)「重构执行记录」。

### 背景说明

模块 10 个文件：`CharactersPage` 161L / `CharactersViewModel` 434L / `CharactersDataLoader` 171L / `CharactersContent` 125L / `CharacterCard` 312L / `CharactersSkeleton` 82L / `CharacterDataSource` 44L / 三游戏 6 个角标与底栏。`CharactersViewModel` 原 614L，混合状态机与无状态数据映射；测试 `features/characters/src/test/CharactersViewModel.test.ets`（176L / 22 用例）冻结 VM 路径、导出名与 `toSelectOptions` 签名。

### 决策

| # | 问题 | 决定 | 依据 |
| --- | --- | --- | --- |
| D1 | VM 614L 如何拆 | 只把无状态静态映射移出为 `CharactersDataLoader`，状态与公开方法留在 VM | 保持测试与页面契约；状态机拆分属行为风险 |
| D2 | `toSelectOptions` 放哪 | 保留在 VM 并委托 loader | 测试直接调用 `CharactersViewModel.toSelectOptions` |
| D3 | 11 个 `@Monitor` 是否收敛 | 不收敛 | 行为相关改动，风险高（M-1） |
| D4 | `RefreshCooldownDialog` 是否提取 | 不提取 | 与 Home 共用属可选清理，单独提交 |
| D5 | 三游戏角标 / 底栏是否合并 | 不合并 | 仅 `CharacterCard` 使用，去重收益有限且改结构 |

### 文件改动清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 新增 | `viewmodel/CharactersDataLoader.ets`（171L） | `loadCharacters` / 三游戏 `build*Summaries` / `shouldSyncCharacters` / `buildAccountOptions` / `toSelectOptions` / `getGameNameResource` |
| 修改 | `viewmodel/CharactersViewModel.ets`（614 → 434L） | 静态映射移出；删除 `GenshinCharacterListRow` / `StarRailAvatarBasicRow` / `ZZZAvatarBasicRow` 与 `AppConstants` / `compareCharacter` 死导入；调用改 `CharactersDataLoader.*` |
| 修改 | 同上 | `toSelectOptions` 保留原签名，委托 `CharactersDataLoader.toSelectOptions` |

### 契约与冻结项

- `Characters` 为底部 Tab 内嵌页，不在 `custom_router_map.json`；`MainPage.ets` 的 `import { Characters }` 路径在 M15 前冻结。
- `CharactersViewModel` 文件路径、导出名、`toSelectOptions` 静态签名冻结（Local Test）。
- `AccountSwitchDialog` 在 `common/basic/shares/`，由 Main / MaterialCharacterSelect 共用，不移动。

### 验收记录

| 项 | 结果 |
| --- | --- |
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 15s 736ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| Local Test | 🔶 22 条用例——需 DevEco GUI 手动运行 |
| 测试契约 | ✅ VM 路径 / 导出名 / `toSelectOptions` 签名不变 |
| 冒烟 | 🔶 待手动：三游戏角色列表、账号切换、刷新/冷却、分屏、进入角色详情 |

### 已知问题记录（不执行）

| ID | 级别 | 描述 | 状态 |
| --- | --- | --- | --- |
| M-1 | Medium | 11 个 `@Monitor` 结构债 | 保留，行为相关 |
| M-2 | Medium | `RefreshCooldownDialog` 与 Home 复制 | 保留，单独提交 |
| M-3 | Medium | `loadData` 无代次保护 | 保留，行为相关 |
| L-4 | Low | `CharacterCard.roleUid` 死参数 | 保留 |

### 结论

**M9 真重构完成**：`CharactersViewModel` 614 → 434L，无状态数据映射整体移入 `CharactersDataLoader`（171L），VM 只保留状态、切换、刷新编排与路由构建；删除行类型与 `AppConstants` / `compareCharacter` 死导入；`toSelectOptions` 由 facade 委托 loader，测试与页面契约不变。行为等价，编译通过。

---

## M10 spec — CharDetail 模块（2026-11-05 真重构）

分析依据：[`docs/genshin-character-detail-module-analysis.md`](../docs/genshin-character-detail-module-analysis.md) / [`docs/starrail-character-detail-module-analysis.md`](../docs/starrail-character-detail-module-analysis.md) / [`docs/zzz-character-detail-module-analysis.md`](../docs/zzz-character-detail-module-analysis.md)。

### 背景说明

M10 覆盖三个游戏的角色详情页：`GenshinCharacterDetailPage` 150L / `StarRailCharacterDetailPage` 137L / `ZZZCharacterDetailPage` 137L，三页各自重复一份「初始 Display 尺寸读取 + `windowSizeChange` 订阅/取消订阅 + 断点计算」逻辑；星铁 / 绝区零英雄区 101L 各自复制一份背景渐变 + 立绘 + 遮罩 + 命座纵列 + 名字叠加层，仅立绘字段、遮罩颜色与名字下方信息不同。三个 VM 存在合并导入、未使用类型导入与死循环等清理项。

### 决策

| # | 问题 | 决定 | 依据 |
| --- | --- | --- | --- |
| D1 | 三页窗口尺寸逻辑 | 提取为 `utils/CharDetailWindowSize.ets` | 三份逐行相同，提取无行为变化 |
| D2 | 星铁 / 绝区零英雄区 | 提取 `views/common/CharDetailHeroScaffold.ets`，差异用参数注入 | 结构相同，仅数据与颜色不同 |
| D3 | ZZZ 遮罩颜色 | 保留原固定 `#99000000` / `#66000000`，不改主题色 | 避免视觉行为变化 |
| D4 | 原神 26 个专属组件 | 不合并 | HeroPanel 三分支已参数化，合并会改变组件树 |
| D5 | `parseRawJson` ERROR 兜底 | 不随本提交执行 | 行为修复，需与纯重构分开提交（三游统一） |
| D6 | `@ohos.display` | 改 `@kit.ArkUI` | 等价导包替换（ARKTS-014） |

### 文件改动清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 新增 | `utils/CharDetailWindowSize.ets`（56L） | 初始尺寸 + `windowSizeChange` 订阅/取消 + `resolveCharDetailBreakpoint()` |
| 新增 | `views/common/CharDetailHeroScaffold.ets`（99L） | 星铁 / 绝区零英雄区骨架：背景渐变、立绘、遮罩、命座纵列、名字叠加层 |
| 修改 | `pages/GenshinCharacterDetailPage.ets`（150 → 129L） | 改用窗口工具；`@ohos.display` → `@kit.ArkUI`；断点改调函数 |
| 修改 | `pages/StarRailCharacterDetailPage.ets`（137 → 116L） | 同上 |
| 修改 | `pages/ZZZCharacterDetailPage.ets`（137 → 116L） | 同上 |
| 修改 | `viewmodel/GenshinCharacterDetailViewModel.ets`（235 → 239L） | 合并 3 条 `from 'core'` 导入；删除未使用 `GenshinPropertyType`；修正 `relic.subStats` 错位换行 |
| 修改 | `viewmodel/StarRailCharacterDetailViewModel.ets`（249 → 239L） | 合并导入；删除未使用 `StarRailPropertyType` / `StarRailRawSkillNode`；删除 `entityId === '1510'` 空循环 |
| 修改 | `viewmodel/ZZZCharacterDetailViewModel.ets`（258 → 259L） | 合并 3 条 `from 'core'` 导入 |
| 修改 | `views/starrail/StarRailCharDetailHero.ets`（101 → 48L） | 改用 `CharDetailHeroScaffold`，传入主题遮罩色 |
| 修改 | `views/zzz/ZZZCharDetailHero.ets`（101 → 49L） | 改用 `CharDetailHeroScaffold`，传固定黑色遮罩 |
| 修改 | `views/genshin/CharDetailWeaponCard.ets` | 删除未使用私有 `formatStars()` |
| 修改 | `views/genshin/CharDetailHeroPanelLandscape.ets` / `CharDetailHeroPanelPortrait.ets` | 删除未使用 `getGenshinElementColor` 导入 |

### 契约与冻结项

- `custom_router_map.json` 三条路由与 `GenshinCharacterDetailBuilder` / `StarRailCharacterDetailBuilder` / `ZZZCharacterDetailBuilder` 名冻结。
- `export type GenshinCharacterDetailParam = CharDetailRouterParam` 别名保留。
- `MaterialCalcParam` 仍从 `material` 模块导入（M7 冻结）。
- `viewmodel/GenshinCharacterDetailViewModel.ets` 路径与导出名冻结（Local Test）。
- `CharDetailRouterParam` 字段名不改。

### 验收记录

| 项 | 结果 |
| --- | --- |
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 14s 775ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| Local Test | 🔶 `GenshinCharacterDetailViewModel.test.ets`（84L / 12 用例）需 DevEco GUI 手动运行；星铁 / ZZZ 无测试 |
| 测试契约 | ✅ VM 路径 / 导出名不变；测试从 `utils/GenshinPropertyUtil` 导入映射 |
| 冒烟 | 🔶 待手动：三游戏详情页窄屏/宽屏、返回、材料计算入口、错误态、旋转 |

### 已知问题记录（不执行）

| ID | 级别 | 描述 | 状态 |
| --- | --- | --- | --- |
| G-CD-0 / SR-CD-0 / ZZZ-CD-0 | High | `parseRawJson` 未设 ERROR，解析失败仍进 DATA | 保留，三游统一行为修复单独提交 |
| SR-CD-L1 | Low | `entityId === '1510'` 空循环 | ✅ 已删除 |
| L-1 | Low | 宽屏左栏无 Scroll | 保留 |
| L-2 | Low | `heroHeight` 未缓存 | 保留 |
| L-3 | Low | 初始尺寸取整屏 | 保留 |
| L-4 | Low | 遗器 / 驱动盘不按 `pos` 排布 | 保留，属行为修复 |

### 结论

**M10 真重构完成**：三页窗口尺寸逻辑提取为 `CharDetailWindowSize`（56L），页面 150/137/137 → 129/116/116L；星铁 / 绝区零英雄区提取为 `CharDetailHeroScaffold`（99L），Hero 101L → 48/49L；三个 VM 合并导入、删除未使用类型与 `1510` 空循环；删除 `formatStars()` 与 2 处未使用导入；`@ohos.display` → `@kit.ArkUI`。行为等价，编译通过。`parseRawJson` ERROR 兜底保留为行为修复，待单独提交。

---

## M11 spec — AccountDetail 模块（2026-11-05 真重构）

分析依据：[`docs/account-detail-module-analysis.md`](../docs/account-detail-module-analysis.md)。

### 背景说明

M11 覆盖账号详情二级页：`AccountDetailPage` 143L + `AccountDetailViewModel` 108L + `views/` 下 7 个 accountdetail 组件。页面本身干净，主要结构债是 `AccountActionsSection` 里 4 个逐行相同的 `Button` 样式块、页面两个结果 Monitor 中重复的 `if SUCCESS / else` Toast 分支，以及 VM 里只写不读的 `refreshCookieError`。

### 决策

| # | 问题 | 决定 | 依据 |
| --- | --- | --- | --- |
| D1 | 4 个同构按钮 | 收敛为 `@Builder actionButton(label, color, enabled, onTap)` | 样式完全一致，仅文案 / 颜色 / 可用态不同 |
| D2 | 两个结果 Monitor | 提取 `showActionResult(result, success, failed)` | 成功 / 失败分支完全相同，仅资源不同 |
| D3 | `refreshCookieError` | 删除 | 只写不读的死字段 |
| D4 | `ForEach` key | 补 `gameId_roleUid` | 避免默认 `index + JSON.stringify` |
| D5 | 删除二次确认 / 失败反馈 | 不随本提交 | 行为修复，需单独提交（M1 / M2） |
| D6 | VM 是否拆分 | 不拆 | 103L 远低于 500L 阈值 |

### 文件改动清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 修改 | `views/AccountActionsSection.ets`（94 → 82L） | 新增 `@Builder actionButton`，4 个按钮复用 |
| 修改 | `pages/AccountDetailPage.ets`（143 → 147L） | 新增 `showActionResult()`，两个 Monitor 复用；重复分支消除 |
| 修改 | `viewmodel/AccountDetailViewModel.ets`（108 → 103L） | 合并 `CoreInitializer` / `Logger` 导入；删除 `refreshCookieError` |
| 修改 | `views/AccountRolesSection.ets` | `ForEach` 补 key 生成函数 |
| 修改 | `views/AccountRoleCard.ets` | 删除 `bgImageUrl !== '' ? bgImageUrl : ''` 冗余三元 |

### 契约与冻结项

- `custom_router_map.json:14-16` 的 `AccountDetail` 路由与 `AccountDetailPageBuilder` 名冻结。
- `viewmodel/AccountDetailViewModel.ets` 路径、导出名、`isDeleted` / `errorMsg` 字段冻结（Local Test）。
- `MyAccountVM`（`model/MyModels.ets`）是路由参数，归 M4，不移动、不改字段。
- `CookieExpiredSignal` / `AccountSignal` 属共享层，不移动。

### 验收记录

| 项 | 结果 |
| --- | --- |
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 34s 393ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| Local Test | 🔶 `AccountDetailViewModel.test.ets`（25L / 2 用例）需 DevEco GUI 手动运行 |
| 测试契约 | ✅ VM 路径 / 导出名 / `isDeleted` / `errorMsg` 不变 |
| 冒烟 | 🔶 待手动：刷新 Cookie、重新生成设备指纹、删除账号、重新登录、过期提示 |

### 已知问题记录（不执行）

| ID | 级别 | 描述 | 状态 |
| --- | --- | --- | --- |
| M1 | Medium | 删除账号无二次确认 | 保留，行为修复单独提交 |
| M2 | Medium | 删除失败无反馈、部分成功不收尾、无防重入、未 `clearExpired` | 保留，行为修复单独提交 |
| L1 | Low | `getHostContext() as common.UIAbilityContext` 无空值检查 | 保留 |
| — | — | `refreshCookieError` 死字段 | ✅ 已删除 |

### 结论

**M11 真重构完成**：`AccountActionsSection` 4 个同构按钮收敛为 `@Builder actionButton`（94 → 82L）；页面两个结果 Monitor 收敛到 `showActionResult()`；VM 合并 core 导入并删除 `refreshCookieError` 死字段（108 → 103L）；RolesSection 补 ForEach key，RoleCard 删除冗余三元。行为等价，编译通过。删除二次确认与失败反馈保留为行为修复，待单独提交。

---

## M12 spec — Login 模块（2026-11-06 真重构）

分析依据：[`docs/login-module-analysis.md`](../docs/login-module-analysis.md)。

### 背景说明

M12 覆盖登录页：`LoginPage` 127L + `LoginViewModel` 402L + `views/` 下 18 个组件（本轮新增 1 个共 19 个 / 851L）+ `LoginConstants` 28L。结构债集中在 `LoginViewModel`：手机号 / 二维码 / Cookie 三种登录各自重复填充 `LoginCookieFields`（6 个字段 + 2 个设备指纹字段），以及 60 / 2000 / 1000 三个魔法数字散落在冷却与轮询逻辑中；两个登录组件重复同一段错误提示 `Text`。

### 决策

| # | 问题 | 决定 | 依据 |
| --- | --- | --- | --- |
| D1 | 三种登录重复构造 Cookie | 提取私有 `buildCookie(accountId, ltuid, stoken, mid, ltoken, cookieToken)` | 字段填充 + 设备指纹完全一致，仅入参来源不同 |
| D2 | 魔法数字 | 移入 `LoginConstants`：`SMS_COOLDOWN_SECONDS` / `QR_POLL_INTERVAL_MS` / `COOLDOWN_TICK_MS` | 避免 `startCooldown(60)` / `setInterval(2000)` / `setInterval(1000)` 散落 |
| D3 | 数组尾部赋值 | `stats[stats.length] =` / `roleVMs[roleVMs.length] =` 改为 `push` | 等价且更符合 ArkTS 惯用写法 |
| D4 | 错误提示重复 | 新增 `views/LoginErrorText.ets`，`LoginPhone` / `LoginCookie` 复用 | 样式与条件渲染完全一致 |
| D5 | `@Event` → `@Param` 风格统一 | 不随本提交 | 风格变更，需回归三种登录与协议回调 |
| D6 | 日志脱敏 | 不随本提交 | 安全加固，行为可感知，单独提交 |
| D7 | 协议语言后缀重复逻辑 | 不随本提交 | 与 `LegalI18nRouter` 行为不一致，属行为修复 |

### 文件改动清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 修改 | `viewmodel/LoginViewModel.ets`（402 → 400L） | 新增 `buildCookie()`；三处登录调用统一；魔法数字改常量；数组赋值改 `push` |
| 修改 | `constants/LoginConstants.ets`（28 → 37L） | 新增 `SMS_COOLDOWN_SECONDS = 60` / `QR_POLL_INTERVAL_MS = 2000` / `COOLDOWN_TICK_MS = 1000` |
| 新增 | `views/LoginErrorText.ets`（23L） | 登录错误提示组件（空消息不渲染） |
| 修改 | `views/LoginPhone.ets`（39 → 34L） | 改用 `LoginErrorText`，删除重复 `Text` |
| 修改 | `views/LoginCookie.ets`（83 → 78L） | 改用 `LoginErrorText`，删除重复 `Text` |

### 契约与冻结项

- `custom_router_map.json` 的 `Login` 路由与 `LoginBuilder` 名冻结；`pages/LoginPage.ets` 路径冻结。
- `viewmodel/LoginViewModel.ets`、`constants/LoginConstants.ets` 路径与导出名冻结（`features/account/src/test/LoginViewModel.test.ets` 142L / 19 用例导入）。
- `errorMsg` 错误码 `phone_empty` / `code_empty` / `cookie_empty` 被测试断言（`test:72/78/132/139`），不得变更。
- `views/` 19 个组件仅登录页使用，不移动、不改名（路由冻结）。
- WebView 协议页（`features/legal`）归 M2，本轮不改。

### 验收记录

| 项 | 结果 |
| --- | --- |
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 16s 267ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| Local Test | 🔶 `features/account/src/test/LoginViewModel.test.ets`（142L / 19 用例）需 DevEco GUI 手动运行 |
| 测试契约 | ✅ VM / `LoginConstants` 路径与导出名不变；错误码断言不变 |
| 冒烟 | 🔶 待手动：手机号 / 二维码 / Cookie 三种登录、协议 WebView、窄屏/宽屏 |

### 已知问题记录（不执行）

| ID | 级别 | 描述 | 状态 |
| --- | --- | --- | --- |
| M1 | Medium | 登录日志脱敏（`LoginViewModel` 失败日志） | 保留，单独提交 |
| M2 | Medium | `@Event` 与全项目 `@Param` 回调风格不统一 | 保留 |
| M3 | Medium | `finalizeLogin` 复杂度、`@Monitor` 内复位触发字段 | 保留 |
| M4 | Medium | 错误提示直接显示错误码（空输入时） | 保留，行为修复 |
| L1 | Low | AlertDialog 生命周期 | 保留 |
| L2 | Low | 协议语言后缀逻辑与 `LegalI18nRouter` 重复且不一致 | 保留，行为修复 |
| — | — | 魔法数字 60 / 2000 / 1000 | ✅ 已收敛到常量 |

### 结论

**M12 真重构完成**：`LoginViewModel` 三种登录共用 `buildCookie()`，魔法数字收敛到 `LoginConstants`，数组尾部赋值改 `push`；新增 `LoginErrorText` 统一手机号 / Cookie 错误提示。行为等价，`bash run.sh uat` 编译安装通过。日志脱敏、`@Event` 风格、协议语言后缀等行为 / 风格项保留，待单独提交。

---

## M13 spec — WidgetConfig 模块（2026-11-06 真重构）

分析依据：[`docs/widget-settings-module-analysis.md`](../docs/widget-settings-module-analysis.md)。

### 背景说明

M13 覆盖小组件配置页：`WidgetSettingsPage` 65L + `WidgetSettingsViewModel` 676L + `views/` 23 个组件（13 根级 + preview 10）。页面本身只有加载态切换与初始化编排，结构债集中在 676L 的 ViewModel：三份平行的「尺寸 → formName / Dimension / preset key」if-else、`goNext` / `goPrev` 重复的步骤数组、账号分组构建（约 70L）、跨进程持久化与 `openFormManager` 拉起（约 130L）。

### 决策

| # | 问题 | 决定 | 依据 |
| --- | --- | --- | --- |
| D1 | 三份尺寸映射 | 抽到 `model/WidgetSettingsSizeConfig.ets`：`getFormName` / `getDimension` / `getPresetKey` | 纯函数、无状态，集中维护跨进程契约值 |
| D2 | 账号分组构建 | 抽到 `model/WidgetSettingsAccountGroups.ets`：`buildAccountGroups(dataStore)` | 与 VM 状态无关，只依赖 dataStore；排序改用 `Array.sort` |
| D3 | 持久化 + 拉起表单 | 抽到 `model/service/WidgetSettingsConfigSaver.ets` | Preferences 文件名 / want 参数是跨进程契约，集中一处 |
| D4 | `goNext` / `goPrev` 重复 | 新增 `getStepFlow()`，两处复用 | 1x2 与其他尺寸的步骤数组只保留一份 |
| D5 | `complete()` 重复 JSDoc | 删除过期副本，保留一份 | 文档债 |
| D6 | `getSelectedGameIds` 手写去重 | 改 `indexOf` | 等价、可读 |
| D7 | 页面未使用的 `@Local tm` | 删除（含 `basic` 主题导入） | 死响应式状态 |
| D8 | `init()` 失败无错误态 / 「完成」失败无反馈 | 不随本提交 | 行为修复，需单独提交（M1 / M2） |

### 文件改动清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 修改 | `viewmodel/WidgetSettingsViewModel.ets`（676 → 447L） | 尺寸映射 / 账号分组 / 持久化改为调用新文件；`getStepFlow()` 去重；删除重复 JSDoc |
| 新增 | `model/WidgetSettingsSizeConfig.ets`（56L） | `getFormName` / `getDimension` / `getPresetKey` |
| 新增 | `model/WidgetSettingsAccountGroups.ets`（61L） | `buildAccountGroups(dataStore)` |
| 新增 | `model/service/WidgetSettingsConfigSaver.ets`（96L） | `savePresetSlots` / `savePendingConfig` / `buildFormManagerWant` / `openFormManager` |
| 修改 | `pages/WidgetSettingsPage.ets`（65 → 63L） | 删除未使用的 `@Local tm` 与 `basic` 主题导入 |

### 契约与冻结项

- `custom_router_map.json:64-66` 的 `WidgetSettings` 路由与 `WidgetSettingsBuilder` 名冻结。
- `AppRoutes.WIDGET_SETTINGS = 'WidgetSettings'` 字符串冻结。
- 跨进程契约不变：Preferences 文件 `widget_configs`、配置 key = `formName`、`widget12/22/24/44` preset key、want 三个标准参数。
- `WidgetConfigViewModel` 无 Local Test；widget 现有测试只覆盖 `Widget2x2ViewModel` / `WidgetDataHelper` / `WidgetPayloadParser` / `WidgetExtraRow*`。
- `views/` 23 个组件不移动、不改名；`home/UserGameSection` ↔ `WidgetSlotOption` 的双向引用保持不变（M8）。

### 验收记录

| 项 | 结果 |
| --- | --- |
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 15s 331ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| Local Test | — 本模块无 Local Test |
| 冒烟 | 🔶 待手动：我的 → 小组件设置 → 尺寸 → Slot → 完成；桌面添加卡片；`formProvider` 不可用时观察 Loading / 错误路径 |

### 已知问题记录（不执行）

| ID | 级别 | 描述 | 状态 |
| --- | --- | --- | --- |
| M1 | Medium | `init()` 失败后回调未初始化、按钮全部失效且无错误态 | 保留，行为修复单独提交 |
| M2 | Medium | 「完成」失败无任何反馈（`openFormManager` / 配置保存均只写日志） | 保留，行为修复单独提交 |
| L1 | Low | 未使用的 `@Local tm` | ✅ 已删除 |

### 结论

**M13 真重构完成**：`WidgetSettingsViewModel` 676 → 447L，拆出尺寸映射（56L）、账号分组（61L）、持久化服务（96L）；`goNext` / `goPrev` 步骤流程去重；删除页面未使用的 `@Local tm`。跨进程 Preferences / want 契约保持不变，行为等价，`bash run.sh uat` 编译安装通过。`init()` 错误态与「完成」失败反馈保留为行为修复，待单独提交。

---

## M14 spec — Widget 卡片预览（2026-11-06 真重构）

分析依据：[`docs/widget-subsystem-modules-analysis.md`](../docs/widget-subsystem-modules-analysis.md)。

### 背景说明

M14 原范围覆盖整个 Widget 子系统（V1 卡片孤岛 + 两个 ability + 数据仓）。本轮按计划只重构 `features/widget/src/main/ets/views/preview/`：配置页的卡片预览组件。`entry/src/main/ets/widget/` 的 6 个页面 / 4 个 ViewModel / 10 个 V1 组件受 `form_config.json` 与 `module.json5` 冻结，且 V1 装饰器不迁移，本轮不动。

预览组件里 `Preview2x4SingleGame` 361L 最突出：9 段完全同构的内联数据行、5 段派遣头像（2 个完成 + 3 个进行中）；`Preview4x4SingleGame` 两组 `ForEach` 重复同一段数据行 markup。

### 决策

| # | 问题 | 决定 | 依据 |
| --- | --- | --- | --- |
| D1 | 2x4 的 9 段数据行 | 收敛为 `@Builder extraRow(label, value, valueColor)` | 字号 / 颜色 / 布局完全一致，仅文案与颜色不同 |
| D2 | 2x4 的 5 段派遣头像 | 收敛为 `@Builder expeditionAvatar(completed)` | 完成态只多一个绿色对勾角标 |
| D3 | 4x4 两组 `ForEach` 重复行 | 收敛为 `@Builder dataRow(row)` | 两处 markup 完全相同 |
| D4 | 未使用的 `StaminaColorType` 导入 | 删除（`Preview1x2Content` / `Preview4x4SingleGame`） | 只导入未使用 |
| D5 | 多 Slot 布局重复 | 不合并 | 2x2 / 2x4 / 4x4 的分隔线方向与嵌套不同，合并会引入 BuilderParam 复杂度 |
| D6 | V1 卡片页面 / 组件 / ability | 不动 | `form_config.json` / `module.json5` 冻结；V1 不迁移 |
| D7 | H1 / H2 / H3 / M1–M8 | 不随本提交 | 行为修复或能力增强，单独提交 |

### 文件改动清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 修改 | `views/preview/Preview2x4SingleGame.ets`（361 → 218L） | 新增 `extraRow` / `expeditionAvatar` Builder，替换 9 段数据行与 5 段头像 |
| 修改 | `views/preview/Preview4x4SingleGame.ets`（246 → 238L） | 新增 `dataRow` Builder，替换两组 ForEach 内重复行；删除未用导入 |
| 修改 | `views/preview/Preview1x2Content.ets`（72L） | 删除未使用的 `StaminaColorType` 导入 |

### 契约与冻结项

- `resources/base/profile/form_config.json` 的 6 条 `src` 与 `name` 冻结；本轮不改。
- `module.json5` 的 `EntryFormAbility` / `WidgetSyncAbility` `srcEntry` 冻结。
- V1 组件不迁移到 V2，不新增 `@ComponentV2` 到卡片渲染进程。
- `'payload'` LocalStorage key、`widget_data` / `widget_configs` Preferences 文件与 JSON 结构不变。
- 测试引用的 `Widget2x2ViewModel` / `WidgetUIStates` / `WidgetPayloadParser` / `WidgetDataHelper` / `WidgetUtils` / `WidgetExtraRow*` 导出名不变。

### 验收记录

| 项 | 结果 |
| --- | --- |
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 15s 218ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| Local Test | 🔶 widget 六套测试需 DevEco GUI 手动运行 |
| 冒烟 | 🔶 待手动：配置页各尺寸预览（单游戏 / 多游戏）外观与重构前一致 |

### 已知问题记录（不执行）

| ID | 级别 | 描述 | 状态 |
| --- | --- | --- | --- |
| H1 | High | 瞬时更新失败即删用户卡片配置 | 保留，行为修复单独提交 |
| H2 | High | 无数据时展示 Mock 账号与体力 | 保留，行为修复单独提交 |
| H3 | High | 卡片从不显示数据新鲜度 | 保留，需产品决策 |
| M1–M8 | Medium | 重复解析、冷却、并发锁、`WidgetFormIdStore` 空转等 | 保留 |
| L1–L3 | Low | logger 合并、`formEvent` 校验、预览缺失 | 保留 |

### 结论

**M14 预览组件重构完成**：`Preview2x4SingleGame` 361 → 218L（`extraRow` / `expeditionAvatar` 两个 Builder 消除 14 段重复 markup）；`Preview4x4SingleGame` 246 → 238L（`dataRow` Builder）；清理未使用的 `StaminaColorType` 导入。V1 卡片孤岛、ability、H1/H2/H3 与 M1–M8 按契约保留。行为等价，`bash run.sh uat` 编译安装通过。

---

## M15 spec — 框架模块（2026-11-06 真重构）

分析依据：[`docs/main-module-analysis.md`](../docs/main-module-analysis.md) / [`docs/index-module-analysis.md`](../docs/index-module-analysis.md) / [`docs/launch-module-analysis.md`](../docs/launch-module-analysis.md) / [`docs/test-page-module-analysis.md`](../docs/test-page-module-analysis.md)。

### 背景说明

M15 覆盖应用主框架：`MainPage` 513L（4 Tab 容器 + 标题栏 + 菜单 + 弹窗仲裁）、`Index` 33L、`LaunchPage` 91L、`TestPage` 105L。`Index` / `LaunchPage` / `TestPage` 已足够小且职责单一，本轮不动；结构债集中在 `MainPage`：底部工具栏 4 段同构对象、窗口模式计算、弹窗账号标签、Cookie 队列出队等重复/内联逻辑。

### 决策

| # | 问题 | 决定 | 依据 |
| --- | --- | --- | --- |
| D1 | 工具栏 4 段同构对象 | 新增 `switchTab(tab)` + `createTabItem(label, icon, tab)` | 图标 / 选中态 / 切换行为完全一致 |
| D2 | 窗口模式计算 | 抽到 `utils/MainNavigationMode.ets`：`isLandscapeOrientation` / `resolveNavigationMode` | 纯函数，页面只保留 try/catch 与赋值 |
| D3 | 弹窗账号标签 | 抽到 `utils/MainDialogLabels.ets`：`getGameAccountLabel` | 人机验证标题与设备指纹提示共用 |
| D4 | Cookie 队列出队 | 手写循环改 `queue.slice(1)` | 等价、避免中间数组 |
| D5 | `charMenuItems` 尾部赋值 | 改 `push` | 惯用写法 |
| D6 | 无用导入 | 删除 `getGameName` / `FailedAccountInfo` / `GameId` | 仅导入未使用 |
| D7 | `MainTabContainer` / `TitleBarController` / `DialogArbiter` 大拆分 | 不随本提交 | 无自动化测试，需真机回归；拆分会改标题栏协议与弹窗时序 |
| D8 | H1 / H2 行为修复 | 不随本提交 | 行为变更，需单独提交 |

### 文件改动清单

| 操作 | 文件 | 说明 |
| --- | --- | --- |
| 修改 | `pages/MainPage.ets`（513 → 473L） | 工具栏 4 项收敛；窗口模式 / 弹窗标签改调 utils；队列出队改 `slice`；清理无用导入 |
| 新增 | `utils/MainNavigationMode.ets`（26L） | `isLandscapeOrientation` / `resolveNavigationMode` |
| 新增 | `utils/MainDialogLabels.ets`（21L） | `getGameAccountLabel` |

### 契约与冻结项

- 4 个 Tab 共享同一个 `NavPathStack`（`this.stack`），`Navigation(this.stack)` 与子页 `detailStack` 入参不变。
- 标题栏协议 10 个字段（`shouldShowHomeRefresh` / `charAccountOptions` 等）与 `TAB_HOME..TAB_MY` 索引不变。
- `windowClass` 从 AppStorage 读取的时机不变；启动页 1200ms 下限不变。
- 三个 `@Monitor`（`cookieExpiredSignal.queue` / `deviceFpInvalidSignal.version` / `geetestSignal.trigger`）与弹窗仲裁状态机不变。
- `Index` 路由 builder、`LaunchPage` 隐私 / Core 初始化流程、`TestPage` 入口（`BuildProfile.DEBUG`）不变。
- `custom_router_map.json` 的 `Main` / `Launch` / `TestPage` 路由名与 builder 名冻结。

### 验收记录

| 项 | 结果 |
| --- | --- |
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 14s 996ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| Local Test | — 本模块无自动化测试 |
| 冒烟 | 🔶 待手动：4 Tab 切换 → 二级页返回 → 折叠屏展开/折叠 → 人机验证（含返回手势关闭）→ Cookie 过期（多账号）→ 账号切换 |

### 已知问题记录（不执行）

| ID | 级别 | 描述 | 状态 |
| --- | --- | --- | --- |
| H1 | High | 人机验证弹窗关闭时无 callback 地 `off('windowSizeChange')` | 保留，行为修复单独提交 |
| H2 | High | 返回手势关闭验证框后验证队列永久卡死 | 保留，行为修复单独提交 |
| M1–M10 | Medium | 弹窗叠加、窗口 API 未包 try、Tab 根页返回等 | 保留 |
| L1–L6 | Low | 记录 | 保留 |

### 结论

**M15 真重构完成**：`MainPage` 513 → 473L，底部工具栏 4 段同构对象收敛为 `createTabItem` / `switchTab`；窗口模式与弹窗账号标签抽到 `utils/MainNavigationMode.ets`（26L）与 `utils/MainDialogLabels.ets`（21L）；Cookie 队列出队改 `slice(1)`，清理无用导入。`Index` / `LaunchPage` / `TestPage` 未改。4 Tab 共享路由栈、标题栏协议、弹窗仲裁与 H1/H2 均保留。行为等价，`bash run.sh uat` 编译安装通过。
