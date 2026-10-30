# 组件去重审查总结

> 审查范围：Mihoyo-Tool 项目全部页面与子组件，聚焦跨游戏重复代码。
> 审查日期：2026-10-24（按基线 `105c8d3` **重写**；旧版描述的是重构前结构，已失效）
> 结论口径：只描述当前代码；去重动作以 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §4 / §6 为准。

---

## 一、关键发现一览

| 类别 | 发现 | 去重优先级 |
|------|------|--------|
| 三件套页面 | 3 × `MaterialTargetConfig`（342 / 346 / 410 行）已拆出各自的 ViewModel，但页面壳（标题/底部按钮/TextPicker 接线）仍高度相似（Genshin↔StarRail `diff` 仅 66 行变更） | **高** |
| 三件套页面 | 3 × `MaterialList`（各 186 行）共用 `MaterialListContentView` + `SegmentedTabBar`，剩余重复是菜单与导航接线 | **中** |
| Preview 规模 | 全工程 **129** 个 `@Preview`（119 个文件；116 个 `@ComponentV2` + 13 个 `@Component`，V1 全在 `widget/`）；长 Preview（≥20 行）集中在 `widgetsettings/`、`materialcalc/`、`materiallist/` 等组件，三件套页面的 Preview 只是 5 行实例化 | **中** |
| 跨模块重复 | `components/widgetsettings/preview/`（11 文件 1,192 行，V2）把桌面卡片 UI 重画了一遍；其工具函数 `WidgetPreviewUtils` 与 `widget/utils/WidgetUtils` / `WidgetDataHelper` 逐项同义（见 §3.3） | **中** |
| ✅ 已做好 | 通知设置没有各游戏独立的 NotificationContent / ListItem；统一由 `NotificationSection` + `components/notification/` 实现 | — |
| ✅ 已做好 | WidgetSettings 的 MVVM 三层次分离（uiState + callbacks + slotHelper）可作为模板推广 | — |

> **旧版勘误**：旧文档中的 `class ViewModel` 内嵌页面、三值 `PickerStep` 枚举、`getCoreSkills()`、`MaterialTargetConfigParams` 接口、`NotificationContent` / `NotificationListItem` / `GameInfoItem`、`TimePickerDialog` / `WidgetSettingCard` **在当前代码中均不存在**。这些是重构前快照，已全部删除，避免误导执行。

---

## 二、当前架构与剩余重复

### 2.1 MaterialTargetConfig 家族（去重优先级：高）

**文件清单**

| 文件 | 行数 | 页面职责 |
|------|------|----------|
| `GenshinMaterialTargetConfigPage.ets` | 342 | 原神目标等级配置（角色/技能/武器） |
| `StarRailMaterialTargetConfigPage.ets` | 346 | 星铁目标等级配置 |
| `ZZZMaterialTargetConfigPage.ets` | 410 | 绝区零目标等级配置（多核心技能分支更长） |

**当前分层（已不是“页面内嵌 ViewModel”）**

```
pages/XxxMaterialTargetConfig.ets        @ComponentV2 页面壳
├── @Local vm: XxxMaterialTargetConfigViewModel   viewmodel/ 下独立文件
├── @Param param: MaterialTargetConfigParam        models/ToolsModels.ets（已共享）
├── models/MaterialTargetConfigModels.ets          LevelConfigVM / LevelLabelKeys / SkillLevelConfigVM（已共享）
└── showTextPickerDialog(...)                      页面壳内的 Picker 接线
```

**仍然重复的部分**

- 页面壳结构：`NavDestination` + 标题 + 底部确认按钮 + `showLevelPicker` / `confirmPicker` 的接线方式（三页均在 `:46` / `:85`；TargetConfig **没有**标题菜单，`.menus()` 只出现在 MaterialList）。`diff` 实测：Genshin↔StarRail 66 行变更、Genshin↔ZZZ 128 行变更（ZZZ 多一个核心技能 Builder）。
- 每页各自声明的 `type PickerStep = 'current' | 'target'`（`:20`，仅两态，三份逐字相同）。
- 等级文案格式化 `formatLevel()`（三份都是 `` `${level} 级` ``，硬编码中文）、`TipCard` / `LevelRow` Builder 样板。
- 真正不同的只有：游戏名/文案、等级上限与标签映射、ZZZ 的核心技能分支、各游戏 ViewModel 内部取数。

**结论**：ViewModel 层已经分开，**不要**再引入 `MaterialTargetConfigBase` 合并页面（会改变组件树与路由入口）。可做的是提取**无状态**的 `formatLevel` 与 `PickerStep` 类型，收益有限但风险低。

### 2.2 MaterialList 家族（去重优先级：中）

**文件清单**

| 文件 | 行数 |
|------|------|
| `GenshinMaterialListPage.ets` | 186 |
| `StarRailMaterialListPage.ets` | 186 |
| `ZZZMaterialListPage.ets` | 186 |

**当前分层**

```
pages/XxxMaterialList.ets
├── @Local vm: XxxMaterialListViewModel        viewmodel/ 下独立文件（约 690 行的是 Genshin 版）
├── components/materiallist/MaterialListContentView.ets   已共享
├── components/common/SegmentedTabBar.ets                  已共享
└── get menuItems(): NavigationMenuItem[]                  每页重复接线
```

**仍然重复的部分**：`aboutToAppear` 初始化、`menuItems`（刷新 / 改配置）、Builder、部分空态/错误态文案。
**结论**：内容视图与 TabBar 已抽出，剩余是“页面接线”级重复；合并页面收益低于风险，优先提取菜单配置工厂。

### 2.3 Preview struct 规模（去重优先级：中）

- 全工程 `@Preview` 共 **129** 处（119 个文件），其后紧跟 `@ComponentV2` 116 处、`@Component` 13 处（后者全在 `widget/`）。
- 统计口径更正：旧版用 `grep "struct .*Preview"` 得到 142 处 / 131 文件，但其中 13 个是**生产组件**（`widgetsettings/preview/` 10 个 `Preview*`、`WidgetConfigPreview`、`NotificationStyleA/BPreview`），并非 `@Preview`。按 `@Preview` 装饰器计为 129 处 / 119 文件。
- 三件套与角色详情页面的 Preview 只是 `XxxPage()` 一行实例化（如 `GenshinMaterialTargetConfigPage.ets:329-335`），**没有**复制主页面布局；≥20 行的长 Preview 主要是组件级的 mock 数据预览（`widgetsettings/`、`materialcalc/`、`materiallist/`、`widget/components/` 等）。
- 这类重复**不影响运行时**，只是维护成本；不建议为了“统一 Preview”改动主组件结构。

---

## 三、共享组件现状

### 3.1 已跨游戏共享 ✅

| 组件 / 模块 | 位置 | 使用范围 |
|------|----------|----------|
| `MaterialListContentView` | `components/materiallist/` | 3 个 MaterialList |
| `SegmentedTabBar` | `components/common/` | MaterialList 等 |
| `PrimaryButtonModifier` | `styles/PrimaryButtonModifier.ets` | 多个页面按钮态 |
| `ThemeFonts` / `ThemeManager` | `theme/` | 全工程（ThemeManager fan-in 211） |
| `MaterialTargetConfigModels` | `models/` | 3 个 TargetConfig 页面 + ViewModel |
| `MaterialTargetConfigParam` | `models/ToolsModels.ets` | 角色选择 → 目标配置 → 材料清单全链路 |

### 3.2 仍按游戏分开、但结构一致 ⚠️

| 项 | 现状 | 建议 |
|------|----------|------|
| `components/characters/{genshin,starrail,zzz}` | 各游戏 `TopLeftBadge` / `BottomBar`（`CharacterCard` 本身已共享） | **不合并**：差异是数据类型与资源，M9 只做目录整理 |
| `components/chardetail/{common,genshin,starrail,zzz}` | common 9 + 26 / 11 / 13 | **不合并**：响应式布局与游戏字段差异大，M10 只抽真正同构的 Section |
| `viewmodel/Xxx{TargetConfig,MaterialList,DailyDetail}ViewModel` | 每游戏一个 | 保留：取数/字段映射不同，合并会引入分支判断 |

### 3.3 Widget 子系统（V1 孤岛）

- 共 **16 个 V1 文件**：`widget/pages/` 6 个（Widget1x2Genshin / StarRail / ZZZ、Widget2x2、Widget2x4、Widget4x4）+ `widget/components/` 10 个（Widget2x2Header / Widget2x2StaminaBlock / WidgetEmptyContent 等）。
- 原因：桌面卡片渲染引擎不兼容 V2；V1 本身**不是重复代码问题**。
- **但卡片 UI 在设置页预览里被重画了一份**：`components/widgetsettings/preview/`（11 文件 1,192 行，V2）对应 `widget/components/`（10 文件 1,316 行，V1），如 `Preview2x2SingleGame` ↔ `Widget2x2SingleGame`、`Preview4x4SingleGame` ↔ `Widget4x4SingleGame`。组件层因 V1/V2 边界不建议合并；但纯函数层是逐项同义的重复，可安全收敛：

  | 预览侧（`widgetsettings/preview/WidgetPreviewUtils.ets`） | 卡片侧 | 关系 |
  |------|------|------|
  | `gameIdToWidgetColor`（`:29`） | `WidgetUtils.getGameColor`（`widget/utils/WidgetUtils.ets:35`） | 分支与返回值完全相同 |
  | `staminaColor`（`:67`） | `WidgetUtils.getStaminaColorByType`（`:46`） | 完全相同 |
  | `staminaColorType`（`:60`） | `WidgetDataHelper.calcStaminaColorType`（`widget/utils/WidgetDataHelper.ets:79`） | 同为 0.3 / 0.7 阈值 |
  | `recoveryTimeText`（`:76`） | `WidgetUtils.formatRecoveryTimeText`（`:61`） | 同一组字符串资源，入参模型不同 |
  | `gameIdToBgColors`（`:43`） | `WidgetUtils.widgetBgDark/Mid/LightRes`（`:205-227`） | 同一组颜色资源，默认分支不同 |

  建议（归属 M13 / M14）：预览侧改为调用 `widget/utils/WidgetUtils`（它只依赖 `widget/models/WidgetUIStates`，不依赖 `core`，V2 侧可直接导入），避免两处阈值/配色漂移；组件层保持两套。
- 旧版列的 `TimePickerDialog` / `WidgetSettingCard` 在仓库中不存在，已删除。

---

## 四、可提取项（按性价比）

### 4.1 `PickerStep` 字符串联合类型（低风险）

三份页面各自声明：

```typescript
type PickerStep = 'current' | 'target'
```

建议提取到 `models/MaterialTargetConfigModels.ets` 并导出；只改类型，不改运行时。

### 4.2 `MaterialTargetConfigParam`（已共享，无需动作）

旧版建议提取的 `MaterialTargetConfigParams` 接口**不存在**；当前统一使用 `models/ToolsModels.ets:101` 的 `class MaterialTargetConfigParam`，且被三个页面与材料清单共用。**保持原位**（§2.4 契约）。

### 4.3 MaterialList 菜单构造（中低风险）

三个页面的 `get menuItems()`（`:37`）逐字相同，图标（`arrow_clockwise` / `gearshape`）与文案也相同，**只有跳转目标路由常量不同**（`:61`）。三页整体 `diff` 只差文件头注释、VM 类名、TAG、路由常量、标题资源、Preview/Builder 名。可提取纯函数：

```typescript
buildMaterialListMenuItems({ isSyncing, onSync, onConfig }): NavigationMenuItem[]
```

不改组件树，只收敛重复。

### 4.4 等级格式化 / 标签映射（中风险）

`formatLevel` 三份逐字相同（可随 §4.1 一起提取，低风险）；`LevelLabelKeys` → 资源的映射分支（如 Genshin `:304-313` vs StarRail `:304-315`）各游戏不同，属于**数据差异**，除非先补三游戏对照测试，否则不建议合并。

---

## 五、状态管理模式评估

- **WidgetSettings**：`uiState` + `callbacks` + `slotHelper` 三层分离，页面仅 65 行，是当前最佳模板。推广时注意它的已知缺陷：回调在 `init()` 的 `try` 内初始化，`init()` 失败时回调保持空函数、按钮全部失效（见 [widget-settings-module-analysis.md](./widget-settings-module-analysis.md) M1）。
- **MaterialTargetConfig / MaterialList**：页面 `@Local vm` + 独立 ViewModel，符合 MVVM；不要再把 ViewModel 塞回页面（旧版描述的 `class ViewModel {}` 已不存在）。
- **框架页**：Main 通过 `@Param` 回调 + 单例信号编排，保持现状（见 `main-module-analysis.md`）。

---

## 六、命名约定

| 当前 | 问题 | 建议 |
|------|------|------|
| `GenshinMaterialTargetConfig` / `StarRailMaterialTargetConfig` / `ZZZMaterialTargetConfig` | 游戏前缀长 | **不改名**：路由 `pageSourceFile` 与 Builder 名冻结（§2.4） |
| `export function XxxBuilder(_name, param)` | Builder 与组件同名 | 保持；重命名属契约变更 |
| `type PickerStep = 'current' \| 'target'` | 三份重复 | 提取到 models（见 §4.1） |

---

## 七、统计

### 7.1 页面级

| 类别 | 数量 | 总行数 |
|------|------|--------|
| MaterialTargetConfig 家族 | 3 文件 | 1,098 |
| MaterialList 家族 | 3 文件 | 558 |
| 角色详情三件套 | 3 文件 | 434 |
| 其他独立页面（Launch / WebView / Privacy / NotificationSettings / WidgetSettings / MaterialCalc） | 6 文件 | 524 |

> 三件套（TargetConfig + MaterialList + DailyDetail + CharDetail）合计约 **2,473 / 5,211 行**（pages 目录），是重复治理的主要体量。

### 7.2 去重潜力（不再沿用旧估算）

| 类别 | 现状 | 可消除冗余 |
|------|------|-----------|
| MaterialTargetConfig | 页面壳 + 3 个独立 VM | UI 接线与类型重复，需逐页 diff 后估算；**不再声称 ~890 行** |
| MaterialList | 已共享 ContentView / TabBar | 菜单与导航接线，量级为几十行 |
| Preview struct | 129 个 `@Preview`（119 个文件，116 V2 + 13 V1） | 页面级 Preview 已是一行实例化，无可抽；组件级 mock 预览收益低，优先级低于业务模块重构 |
| Widget 预览 ↔ 卡片 | 两套 UI（V2 1,192 行 / V1 1,316 行）+ 一组同义纯函数 | 只收敛纯函数（§3.3 表中 5 项，几十行）；组件层不合并 |

### 7.3 综合结论

> 三件套已完成“页面 → ViewModel → 共享模型”的第一轮拆分，**剩下的不是大规模复制粘贴**，而是页面壳接线与小工具重复。重构执行应优先 M1–M15 的目录/契约整理，去重只做 §4 中可逆的小提取；不要为了行数指标合并页面。

---

## 八、复核与执行边界（2026-10-24）

> 本节优先级最高；重构执行以 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) 为准。

1. **不要新建 `shared/` 目录**：工程里没有 `shared/`，且作用域只允许改各 module 下的 `src/main/ets/**/*.ets`；类型/常量放对应 module 的 `models/` 或 `constants/`。
2. **不采用 `MaterialTargetConfigBase` / `MaterialListBase`**：Refactor_Spec M7 保留 3 个路由入口与 3 个 Builder，避免改变组件树与状态归属。
3. **M9 / M10 的游戏子组件不合并**：差异是游戏数据与响应式布局，不是重复模板。
4. **只做可逆的小提取**：`PickerStep` 类型、菜单/格式化纯函数；涉及 UI 结构、生命周期、路由参数类的改动一律单独立项。
5. 下方 §九仅作历史记录，**不是执行清单**。

## 九、历史行动计划（已废弃，仅存档）

> 以下条目来自重构前快照，其中 `shared/enums`、`MaterialTargetConfigBase`、`Thin Wrapper`、合并 NotificationContent/ListItem 等均**不再执行**。

- ~~提取 `shared/enums/PickerStep.ets`~~ → 改为提取到 `models/`（§4.1）
- ~~提取 `shared/interfaces/MaterialTargetConfigParams.ets`~~ → 已由 `models/ToolsModels.ets` 的 `MaterialTargetConfigParam` 取代
- ~~实现 `MaterialTargetConfigBase` 通用组件~~ → 与 M7 决定冲突，取消
- ~~合并 NotificationContent / NotificationListItem / GameInfoItem~~ → 这些组件不存在，取消
- ~~统一 Preview struct 模式~~ → 降为可选项，不纳入本轮

### 复核记录（2026-10-26 第 4 轮）

| 检查项 | 结论 |
| --- | --- |
| 页面体量 | TargetConfig 1,098 / MaterialList 558 / CharDetail 434 / 其他 6 页 524 → 三件套合计 2,473 行（/pages 5,211）逐项与 `wc -l` 一致 |
| Preview 规模 | `struct *Preview` 声明 **142 处 / 131 文件 / 129 处 V2 + 13 处 V1**（V1 全在 widget/），与 `grep "struct .*Preview"` 完全一致（口径有误，已在第 5 轮更正） |
| 组件族 | `components/characters/` 11 文件、`chardetail/` 59、`dailynote/` 16、`widgetsettings/` 24（13+11）均已复核 |
| 结论 | §八 执行边界仍成立：不新建 `shared/`、不合并页面、只做可逆小提取 |

### 复核记录（2026-10-27 第 5 轮）

| 检查项 | 结论 |
| --- | --- |
| 页面体量 | 1,098 / 558 / 434 / 383（DailyDetail）/ 其他 6 页 524，三件套 2,473 / pages 5,211，`wc -l` 一致 |
| Preview 规模 | 原"142 处 / 131 文件 / 129 V2 + 13 V1"把 13 个名字含 Preview 的生产组件算进去了；按 `@Preview` 实为 **129 / 119 文件 / 116 V2 + 13 V1** |
| 事实修正 | TargetConfig 无标题菜单；`formatLevel` 三份相同（非"分支不同"）；MaterialList `menuItems` 图标/文案相同、仅路由不同；三件套 Preview 不是"复制 20–40 行布局"；characters 子目录只有 Badge / BottomBar |
| 新增 | §3.3 Widget 预览 ↔ 卡片的同义纯函数（`WidgetPreviewUtils.ets:29/43/60/67/76` ↔ `WidgetUtils.ets:35/46/61/205-227`、`WidgetDataHelper.ets:79`） |
| 旧版勘误 | `TimePickerDialog` / `WidgetSettingCard` / `NotificationListItem` / `GameInfoItem` / `getCoreSkills` / `MaterialTargetConfigParams` / `class ViewModel` 全工程 0 命中（`NotificationContent` 仅为系统类型 `notificationManager.NotificationContent`），勘误成立 |

【已核对代码一致性】
