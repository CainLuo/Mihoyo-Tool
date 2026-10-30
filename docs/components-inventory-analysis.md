# 组件全量索引（专项）

> **索引对象**：各 feature module 下的 `src/main/ets/views/`（原 `entry/src/main/ets/components/`，已迁移至 `features/*/src/main/ets/views/`）
> **索引日期**：2026-10-24
> **代码版本**：`105c8d3`
> **性质**：索引 / 去重专项，**不单独评级**（评级见各页面模块文档）
> **为什么需要这份文档**：此前的 24 份页面级文档（20 份独立 + 3 个家族 + 1 份 widget 子系统）是按"页面 → 它直接依赖的组件"组织的，组件实际被**跨模块复用**，此前没有一处能回答"这个文件属于哪份文档 / 有没有第二份实现"。逐文件覆盖的缺口就在这里。

---

## 1. 总览

| 目录 | 文件数 | 行数 | 归属文档 |
| --- | --- | --- | --- |
| `components/`（根级） | 10 | 726 | Refactor_Spec §4 归 **M0**（根级 10 个共享文件，原位不动）；调用方：`GeetestDialogHelper` ← `pages/MainPage.ets:24` + `utils/GeetestSignal.ets:13`、`SnackbarContent` ← `utils/FeedbackUtil.ets:11`、`SettingRow` ← My 页（`pages/MyPage.ets:15`、`my/AppearanceSection.ets:9`、`my/AboutSection.ets:9`）、`SplitPlaceholder` ← `pages/MainPage.ets:20`、`TestRow` / `TestSectionHeader` ← `pages/TestPage.ets:9-10`（Q-2） |
| `accountdetail/` | 7 | 499 | [account-detail](./account-detail-module-analysis.md) |
| `appearancesettings/` | 1 | 87 | [appearance-settings](./appearance-settings-page-module-analysis.md) |
| `characters/` | 5 | 718 | [characters](./characters-module-analysis.md) |
| `characters/{genshin,starrail,zzz}/` | 6 | 297 | 同上（三游戏差异条） |
| `chardetail/common/` | 9 | 404 | 三个 CharDetail 文档共用 |
| `chardetail/genshin/` | 26 | 1,847 | [genshin-detail](./genshin-character-detail-module-analysis.md) |
| `chardetail/starrail/` | 11 | 652 | [starrail-detail](./starrail-character-detail-module-analysis.md) |
| `chardetail/zzz/` | 13 | 710 | [zzz-detail](./zzz-character-detail-module-analysis.md) |
| `common/` | 2 | 221 | Refactor_Spec §4 归 **M0**；`SegmentedTabBar` ← 三个 MaterialList 页（M7）+ `characters/CharactersContent`、`CharactersViewModel`（M9）；`PlaceholderView` ← Tools / Home / MaterialCharacterSelect / `characters/CharactersContent` |
| `dailynote/common/` | 6 | 336 | [daily-detail](./daily-detail-modules-analysis.md) |
| `dailynote/{genshin,starrail,zzz}/` | 10 | 892 | 同上 |
| `home/` | 10 | 671 | [home](./home-module-analysis.md) |
| `login/` | 18 | 852 | [login](./login-module-analysis.md) |
| `materialcalc/` | 8 | 781 | [material-calc](./material-calc-module-analysis.md) |
| `materiallist/` | 6 | 1,049 | [material-list](./material-list-modules-analysis.md) |
| `my/` | 6 | 442 | [my](./my-module-analysis.md) |
| `notification/` | 14 | 720 | [notification-settings](./notification-settings-module-analysis.md) |
| `privacyconsent/` | 2 | 209 | [privacy-consent](./privacy-consent-page-module-analysis.md) |
| `tools/` | 1 | 134 | [tools](./tools-module-analysis.md) |
| `widgetsettings/` | 13 | 1,492 | [widget-settings](./widget-settings-module-analysis.md) |
| `widgetsettings/preview/` | 11 | 1,192 | 同上（预览数据是 `models/WidgetPreviewModels` 的占位数据；仅 `WidgetColors` / `StaminaColorType` 取自 [widget-subsystem](./widget-subsystem-modules-analysis.md) 的 `WidgetUIStates`） |

> 目录合计 195 文件 / 14,931 行；`chardetail` 全家族 59 文件 / 3,613 行，是最大的组件簇。

---

## 2. 全量索引（文件 → 行数）

### 2.1 根级（10 / 726）

`GeetestBridge`(44) · `GeetestDialog`(152) · `GeetestDialogHelper`(112) · `GeetestDialogTitleBar`(74) · `GeetestHtmlBuilder`(69) · `SettingRow`(68) · `SnackbarContent`(93) · `SplitPlaceholder`(45) · `TestRow`(46) · `TestSectionHeader`(23)

### 2.2 accountdetail（7 / 499）

`AccountActionsSection`(94) · `AccountHeaderCard`(70) · `AccountRoleCard`(98) · `AccountRoleCardHeader`(92) · `AccountRoleServerRow`(42) · `AccountRoleStatItem`(41) · `AccountRolesSection`(62)

### 2.3 appearancesettings（1 / 87）

`ThemeModeRow`(87)

### 2.4 characters（5 + 6 / 1,015）

- 根级：`AccountSwitchDialog`(149) · `CharacterCard`(313) · `CharacterDataSource`(44) · `CharactersContent`(129) · `CharactersSkeleton`(83)
- genshin：`GenshinBottomBar`(50) · `GenshinTopLeftBadge`(37)
- starrail：`StarRailBottomBar`(40) · `StarRailTopLeftBadge`(49)
- zzz：`ZZZBottomBar`(61) · `ZZZTopLeftBadge`(60)

### 2.5 chardetail（59 / 3,613）

- **common（9 / 404）**：`CharDetailConsColumn`(102) · `CharDetailEmptyView`(34) · `CharDetailHeroNameOverlay`(40) · `CharDetailLoadingView`(34) · `CharDetailMaterialCalcEntry`(71) · `CharDetailRelicPlaceholder`(34) · `CharDetailSectionLabel`(20，fan-in 12) · `CharDetailSkillItem`(37) · `CharDetailStatRow`(32)
- **genshin（26 / 1,847）**：`CharDetailHeroInfoOverlay`(73) · `CharDetailHeroPanel`(104) · `CharDetailHeroPanelLandscape`(132) · `CharDetailHeroPanelPortrait`(132) · `CharDetailHeroPanelWide`(133) · `CharDetailLandscapeLayout`(51) · `CharDetailLandscapeSkillItem`(25) · `CharDetailLevelAndFetterRow`(51) · `CharDetailPortraitLayout`(62) · `CharDetailPortraitRelicsSection`(25) · `CharDetailPortraitSkillItem`(51) · `CharDetailPortraitSkillsSection`(40) · `CharDetailPortraitStatsSection`(44) · `CharDetailPortraitWeaponCard`(88) · `CharDetailPortraitWeaponSection`(44) · `CharDetailRelicCard`(87) · `CharDetailRelicPair`(71) · `CharDetailRelicRow`(89) · `CharDetailRelicsPanel`(118) · `CharDetailSkillsColumn`(53) · `CharDetailStatsGrid`(42) · `CharDetailStatsList`(31) · `CharDetailStatsPanel`(86) · `CharDetailWeaponCard`(96) · `CharDetailWeaponRow`(71) · `CharDetailWideLayout`(48)
- **starrail（11 / 652）**：`StarRailCharDetailContent`(41) · `StarRailCharDetailHero`(101) · `StarRailCharDetailHeroInfo`(31) · `StarRailCharDetailWideLayout`(58) · `StarRailEquipCard`(54) · `StarRailEquipSection`(48) · `StarRailPropsSection`(45) · `StarRailRelicCard`(84) · `StarRailRelicsSection`(67) · `StarRailSkillNode`(54) · `StarRailSkillsSection`(69)
- **zzz（13 / 710）**：`ZZZCharDetailContent`(41) · `ZZZCharDetailHero`(101) · `ZZZCharDetailHeroInfo`(44) · `ZZZCharDetailWideLayout`(58) · `ZZZEquipCard`(71) · `ZZZEquipCardHeader`(42) · `ZZZEquipSection`(62) · `ZZZPropsSection`(47) · `ZZZSkillItem`(46) · `ZZZSkillsSection`(37) · `ZZZSuitSummaryRow`(48) · `ZZZWeaponCard`(63) · `ZZZWeaponSection`(50)

### 2.6 common（2 / 221）

`PlaceholderView`(109) · `SegmentedTabBar`(112)

### 2.7 dailynote（16 / 1,228）

- common（6 / 336）：`DailyNoteCard`(142) · `DailyNoteDataRow`(39) · `DailyNoteEmptyView`(21) · `DailyNoteLoadingView`(21) · `DailyNoteSectionLabel`(26) · `ExpeditionItem`(87)
- genshin（3 / 275）：`DailyNoteGenshin`(150) · `GenshinDailyTaskContent`(78) · `GenshinExpeditionSection`(47)
- starrail（3 / 277）：`DailyNoteStarRail`(72) · `StarRailStaminaCard`(104) · `StarRailUniverseCard`(101)
- zzz（4 / 340）：`DailyNoteZZZ`(72) · `ZZZDailyCard`(109) · `ZZZOtherCard`(101) · `ZZZShopCard`(58)

### 2.8 home（10 / 671）

`AccountSkeletonCard`(33) · `GameDataRow`(50) · `GameStaminaBlock`(104) · `GameToolCard`(91) · `GameToolCardContent`(52) · `GameToolCardHeader`(78) · `HomeSkeletonView`(40) · `SkeletonBlock`(46) · `UserGameSection`(119) · `UserGameSectionHeader`(58)

### 2.9 login（18 / 852）

`LoginAgreement`(39) · `LoginCard`(31) · `LoginCodeInput`(83) · `LoginCookie`(85) · `LoginFeatureItem`(42) · `LoginLogoSection`(45) · `LoginNarrowLayout`(36) · `LoginPhone`(40) · `LoginPhoneInput`(54) · `LoginQRCode`(96) · `LoginQRCodeConfirmed`(25) · `LoginQRCodeExpired`(45) · `LoginQRCodeLoading`(25) · `LoginQRCodeReady`(36) · `LoginTabBar`(44) · `LoginTabContent`(28) · `LoginTabItem`(37) · `LoginWideLayout`(61)

### 2.10 material-calc（8 / 781）

`LevelPicker`(137) · `MaterialCalcCharacter`(134) · `MaterialCalcContentView`(81) · `MaterialCalcEmptyView`(43) · `MaterialCalcItem`(130) · `MaterialCalcLoadingView`(34) · `MaterialCalcSection`(115) · `MaterialCalcSkills`(107)

### 2.11 material-list（6 / 1,049）

`CharacterMaterialCard`(329) · `CharacterMaterialSections`(174) · `MaterialGridCard`(191) · `MaterialGridItem`(177) · `MaterialListContentView`(96) · `MaterialSectionView`(82)

### 2.12 my（6 / 442）

`AboutSection`(72) · `AccountListItem`(60) · `AccountListSection`(88) · `AppearanceSection`(72) · `NotificationSection`(113) · `SectionHeader`(37)

### 2.13 notification（14 / 720）

`NotificationAccountBlock`(77) · `NotificationAccountHeader`(56) · `NotificationBubbleCollapsed`(32) · `NotificationBubbleExpanded`(52) · `NotificationBubbleHeader`(30) · `NotificationFullValueRow`(46) · `NotificationGameRow`(109) · `NotificationMasterToggle`(45) · `NotificationPermissionWarning`(31) · `NotificationSlotUsage`(47) · `NotificationStyleAPreview`(47) · `NotificationStyleBLine`(23) · `NotificationStyleBPreview`(54) · `NotificationStyleCard`(71)

### 2.14 privacyconsent（2 / 209）

`PrivacyConsentFooter`(99) · `PrivacyConsentWebView`(110)

### 2.15 tools（1 / 134）

`GameEntryCard`(134)

### 2.16 widgetconfig（13 + 11 / 2,684）

- 根级（13 / 1,492）：`WidgetConfigDone`(115) · `WidgetConfigPreview`(200) · `WidgetGameTypeOption`(110) · `WidgetSettingsBottomButtons`(96) · `WidgetSettingsGameStep`(65) · `WidgetSettingsLoading`(21) · `WidgetSettingsMainContent`(134) · `WidgetSettingsSizeStep`(54) · `WidgetSettingsSlotStep`(99) · `WidgetSizeOption`(107) · `WidgetSizeThumbs`(255) · `WidgetSlotOption`(143) · `WidgetStepIndicator`(93)
- preview（11 / 1,192）：`Preview1x2Card`(45) · `Preview1x2Content`(73) · `Preview2x2MultiSlot`(52) · `Preview2x2SingleGame`(124) · `Preview2x4MultiSlot`(57) · `Preview2x4SingleGame`(362) · `Preview4x4MultiSlot`(57) · `Preview4x4SingleGame`(247) · `PreviewEmptyContent`(25) · `PreviewExtraDataRow`(33) · `WidgetPreviewUtils`(117)

---

## 3. 体量热点（>150 行）

| 文件 | 行数 | 说明 |
| --- | --- | --- |
| `widgetsettings/preview/Preview2x4SingleGame` | 362 | **与 `widget/components/Widget2x4SingleGame`(290) 是两份实现**——预览在设置页里重画了一遍卡片 |
| `materiallist/CharacterMaterialCard` | 329 | 单角色材料卡（含技能/武器/材料三组） |
| `characters/CharacterCard` | 313 | 角色卡（含元素、命座、属性摘要） |
| `widgetsettings/WidgetSizeThumbs` | 255 | 尺寸缩略图 |
| `widgetsettings/preview/Preview4x4SingleGame` | 247 | 对应 `Widget4x4SingleGame`(344) 的预览版 |
| `widgetsettings/WidgetConfigPreview` | 200 | 预览容器（按尺寸分发） |
| `materiallist/MaterialGridCard` | 191 | 按材料汇总的网格卡 |
| `materiallist/MaterialGridItem` | 177 | 网格单元 |
| `materiallist/CharacterMaterialSections` | 174 | 角色材料分组 |
| `GeetestDialog` | 152 | 人机验证弹窗（Web 组件） |

---

## 4. 复用与重复

### 4.1 已做好的复用（保持）

| 组件 | 复用面 | 说明 |
| --- | --- | --- |
| `chardetail/common/CharDetailSectionLabel` | fan-in **12** | 三游戏详情页统一小节标题 |
| `common/SegmentedTabBar` | 三个材料清单页 / 角色列表（`CharactersContent`） | 统一分段控件 |
| `common/PlaceholderView` | Tools / Home / MaterialCharacterSelect / 角色列表的空/错态 | 统一占位 |
| `dailynote/common/*` | 三游戏便签 | 卡片/数据行/空态/加载态已抽出 |
| `chardetail/common/*` | 三游戏详情 | 空态/加载态/属性行/材料入口已抽出 |

### 4.2 真实重复（需要在重构中处理）

| 重复 | 证据 | 风险 |
| --- | --- | --- |
| **预览组件 vs widget 组件** | `components/widgetsettings/preview/Preview2x4SingleGame`(362) 与 `widget/components/Widget2x4SingleGame`(290)；`Preview4x4SingleGame`(247) 与 `Widget4x4SingleGame`(344)；`Preview2x2SingleGame`(124) 与 `Widget2x2SingleGame`(101) | **最高**：改卡片布局必须同步改预览，否则设置页预览与桌面实际卡片不一致。两份只共享 `WidgetUIStates` 的 `WidgetColors` / `StaminaColorType`；预览数据来自 `models/WidgetPreviewModels`（占位值），颜色/名称/恢复时间计算在 `widgetsettings/preview/WidgetPreviewUtils.ets:15-90`（`gameIdToWidgetName` / `staminaColor` / `recoveryTimeText`）又写了一份，与 `widget/utils/WidgetUtils.ets:46/61/128`（`getStaminaColorByType` / `formatRecoveryTimeText` / `gameNameRes`）平行，渲染层与辅助函数层都分叉 |
| 原神详情 4 套 Hero 变体 | `CharDetailHeroPanel`(104) + `Portrait`(132) + `Landscape`(132) + `Wide`(133) | 中：响应式布局差异真实存在，但 4 份的标题/等级/属性排布高度相似 |
| 原神详情 Portrait/Landscape 成对组件 | `PortraitSkillItem`(51)/`LandscapeSkillItem`(25)、`PortraitWeaponCard`(88)/`WeaponCard`(96)、`PortraitRelicsSection`(25)/`RelicsPanel`(118) | 中：同一信息的两种排布 |
| 三游戏"顶部徽标 / 底部条" | `GenshinTopLeftBadge`(37) · `StarRailTopLeftBadge`(49) · `ZZZTopLeftBadge`(60)；三个 `*BottomBar` | 低：内容差异大（元素/命途/职业），合并收益小 |

### 4.3 归属未定的组件

| 组件 | 现状 | 归属 |
| --- | --- | --- |
| `TestRow` / `TestSectionHeader` | 生产 `components/` 根级，只被 `pages/TestPage.ets` 使用 | Q-2 决策前保持原位（见 [test-page](./test-page-module-analysis.md) §7） |
| `SnackbarContent` | 由 `FeedbackUtil` 的 `ComponentContent` 动态加载 | M0（`utils/FeedbackUtil`） |
| `SettingRow` | 设置类通用行；实际只被 My 页使用（`pages/MyPage.ets:15`、`my/AppearanceSection.ets:9`、`my/AboutSection.ets:9`），外观设置 / 通知设置均未引用 | Spec §4 归 M0；调用方全在 M4 |
| `SplitPlaceholder` | 分屏占位，只被 Main 使用（`pages/MainPage.ets:20`） | Spec §4 归 M0；唯一调用方 M15 |
| `characters/AccountSwitchDialog` | 放在 M9 目录，但只被 `pages/MainPage.ets:14`（M15）与 `pages/MaterialCharacterSelectPage.ets:10`（M7）引用，角色列表本身不用 | M9 目录内原位；M7 / M15 重构时注意反向依赖 |
| `my/NotificationSection` | 放在 M4 目录，只被 `pages/NotificationSettingsPage.ets:6`（M5）引用，内部引 6 个 `notification/*` 组件 | Spec §4 M5：唯一安全移动是迁入 `notification/` |
| `my/SectionHeader` | `pages/MyPage.ets:11` + `pages/AccountDetailPage.ets:7` | M4 目录；M11 跨目录引用 |
| `home/UserGameSection` ↔ `widgetsettings/WidgetSlotOption` | `home/UserGameSection.ets:13` 引 `widgetsettings/WidgetSlotOption`，`widgetsettings/WidgetSettingsSlotStep.ets:12` 又引 `home/UserGameSection` —— M8 与 M13 目录互引 | 两模块重构时须同时考虑，不要单边移动 |

---

## 5. 结论与执行边界

1. **组件不需要大规模搬家**：195 个文件已经按功能目录分好（15 个一级功能目录；`characters` / `chardetail` / `dailynote` 下按 genshin / starrail / zzz 分子目录，另有 `chardetail/common`、`dailynote/common`、`widgetsettings/preview`，共 12 个二级子目录），与 Refactor_Spec §3 的目标结构一致。
2. **唯一值得做的去重是"预览 vs 卡片"**：两份渲染实现是设置页与桌面不一致的根源；但合并需要 widget 侧抽出可复用渲染单元（V1 限制：预览在 `@ComponentV2` 环境、卡片在 `@Component` 环境，**不能直接复用同一个 struct**）。因此本轮**只记录，不合并**。
3. **大文件优先拆**：`CharacterMaterialCard`(329) / `CharacterCard`(313) / `WidgetSizeThumbs`(255) 都属"一个文件多个 struct"（前两者第二个 struct 是 `@Preview` 预览：`CharacterMaterialCard.ets:240`、`CharacterCard.ets:240`；`WidgetSizeThumbs` 是 4 个缩略图 struct），可随 M7 / M9 / M13 内部拆分，不改文件路径。
4. **不要在 M14 之前动 `widgetsettings/preview/`**：它依赖 `widget/models/WidgetUIStates`（§2.5 冻结项）。

---

*本文档仅索引，不修改代码。*

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（总量） | 总计 195 文件 / 14,931 行、chardetail 家族 59 / 3,613 | ✅ |
| 第 2 轮（分目录） | 16 个子目录文件数 & 行数、100+ 逐文件行数抽样 | ✅ |
| 第 3 轮（复核） | §3 体量热点 10 项、§4.3 组件引用路径 | ✅ |
| 第 4 轮（2026-10-27 全量脚本） | 195 个文件逐个 `wc -l` 与 §2 全部一致；目录数 20→27；按实际 import 重核归属：根级与 `common/` 按 Spec §4 归 M0，`SettingRow` 实际只被 My 页用、`SegmentedTabBar` 实际被材料清单 + 角色列表用；补 `AccountSwitchDialog` / `NotificationSection` / `SectionHeader` / `UserGameSection↔WidgetSlotOption` 跨模块边；预览与卡片的辅助函数层也分叉 | ✅ 已修正 |
