# MaterialList 家族模块分析

> **作用范围：** `GenshinMaterialList` / `StarRailMaterialList` / `ZZZMaterialList` 三文件  
> **分析方式：** 合并分析（三份代码结构几乎完全一致，差异仅在于 ViewModel 和游戏名）  
> **分析日期：** 2026-10-24（重构备注同日复核）
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 2 |
| Low | 4 |

**整体评级：A**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + 0 High，Medium ≤ 5）。旧百分制已废弃，原分 92/100 仅作历史参考。
>
> **债务点数**：2×2 + 4×1 = 8；密度 8 ÷ (558/100) ≈ 1.4（源行数为三页合计 3×186）。

---

## 1. 文件基本信息

| 文件 | 行数 | @Component 版本 | 主要依赖 |
|------|------|-----------------|----------|
| `features/material/src/main/ets/pages/GenshinMaterialListPage.ets` | 55 | `@ComponentV2` | GenshinMaterialListViewModel + MaterialListScaffold |
| `features/material/src/main/ets/pages/StarRailMaterialListPage.ets` | 55 | `@ComponentV2` | StarRailMaterialListViewModel + MaterialListScaffold |
| `features/material/src/main/ets/pages/ZZZMaterialListPage.ets` | 55 | `@ComponentV2` | ZZZMaterialListViewModel + MaterialListScaffold |
| `features/material/src/main/ets/views/MaterialListScaffold.ets` | 164 | `@ComponentV2` | 三页共用外壳（标题栏 / 菜单 / Tab / 三态） |
| `features/material/src/main/ets/utils/MaterialAmountUtil.ets` | 39 | – | 货币材料「万 / 亿」格式化（三处共用） |
| `features/material/src/main/ets/viewmodel/GenshinMaterialListViewModel.ets` | 449 | – | 原神材料汇总页 ViewModel（整批 `overall_consume` 精确值 + 按角色估算回退） |
| `features/material/src/main/ets/viewmodel/StarRailMaterialListViewModel.ets` | 261 | – | 星铁材料汇总页 ViewModel（`need_get` 逐角色） |
| `features/material/src/main/ets/viewmodel/ZZZMaterialListViewModel.ets` | 258 | – | 绝区零材料汇总页 ViewModel（`need_get` 优先，回退 consume） |
| `features/material/src/main/ets/viewmodel/MaterialListAggregator.ets` | 273 | – | 三游戏共用纯函数聚合器（排序 / 汇总 / 分组 / 材料项转换） |

> 上表为 M7 重构后现状；§2 / §3 / §4 保留重构前基线，便于对照。

---

## 2. 代码结构分析

### 2.1 整体布局

```
@ComponentV2 export struct GenshinMaterialList
├── @Local private vm: GenshinMaterialListViewModel = new GenshinMaterialListViewModel()
├── @Local private tm: ThemeManager = themeManager
├── @Local private buttonModifier: PrimaryButtonModifier = new PrimaryButtonModifier(true)
├── @Param param: MaterialTargetConfigParam | null = null
├── private localStack: NavPathStack | null = null（onReady 赋值）
├── aboutToAppear() → vm.init(this.param)（未 await）
├── build() → NavDestination ({ .title(...) .hideTitleBar(false) .menus(this.menuItems) })
│   └── Column ()
│       ├── SegmentedTabBar({ tabs, selectedIdx, onSelect: () => vm.toggleViewMode })
│       └── if/else viewState 条件渲染：
│           ├─ LOADING → LoadingProgress (居中)
│           ├─ EMPTY → Column(📦 + Text + Button onClick → vm.syncComputeData)
│           └─ DATA → MaterialListContentView({ viewMode, characterMaterials, materialSections, onToggleCharacterExpand })
├── getViewModeTabs(): SegmentedTabItem[] → ['character', 'material']
├── getViewModeIndex(): number
├── menuItems (getter): NavigationMenuItem[] → sync(有数据时) + config(始终)
│   └─ config action: localStack?.pushPathByName(AppRoutes.GENSHIN_MATERIAL_TARGET_CONFIG, vm.getSelection())
```

### 2.2 三文件差异对比

| 差异点 | 原神 | 星铁 | ZZZ |
|--------|------|------|-----|
| L2 注释 | `GenshinMaterialList`（原神） | `StarRailMaterialList`（星穹铁道） | `ZZZMaterialList`（绝区零） |
| TAG (L21) | `'GenshinMaterialList'` | `'StarRailMaterialList'` | `'ZZZMaterialList'` |
| ViewModel (L25) | `GenshinMaterialListViewModel` | `StarRailMaterialListViewModel` | `ZZZMaterialListViewModel` |
| L15 import core | `import { Logger } from 'core'` | `import { Logger, GameId } from 'core'`（GameId 未使用） | `import { Logger, GameId } from 'core'`（GameId 未使用） |
| L61 路由常量 | `AppRoutes.GENSHIN_MATERIAL_TARGET_CONFIG` | `AppRoutes.STARRAIL_MATERIAL_TARGET_CONFIG` | `AppRoutes.ZZZ_MATERIAL_TARGET_CONFIG`（路径指向 `features/material/`） |
| L162 标题资源 | `app.string.genshin_material_list_title` | `app.string.starrail_material_list_title` | `app.string.zzz_material_list_title` |

**其余 180+ 行逻辑完全一致。**

---

## 3. 合规审查

### 3.1 ArkTS 语法规范

| 规则 | 状态 | 说明 |
|------|------|------|
| @ComponentV2 使用 | ✅ | 正确使用 V2 装饰器 |
| @Local 状态管理 | ✅ | vm、tm、buttonModifier 均用 @Local，页面级状态合理 |
| 无内联 @Builder（错误用法） | ✅ | @Builder 仅用于 Router Builder（文件底部 `*MaterialListBuilder`），用法正确 |
| const TAG | ✅ | 已定义字符串常量 |
| 类型声明完整 | ✅ | 所有变量均有显式类型 |
| Logger 使用 | ✅ | 三页均在 `aboutToAppear` / 菜单 / 按钮回调中调用 `Logger.info(TAG, ...)`，导入有效 |

### 3.2 命名约定

| 规则 | 状态 | 说明 |
|------|------|------|
| 文件名 PascalCase | ✅ | GenshinMaterialListPage.ets 等符合规范 |
| struct 名 PascalCase | ✅ | 与文件名一致 |
| import 分组排序 | ⚠️ | `import { Logger, GameId } from 'core'` 夹在相对路径 import 之间（L15），未按“kit → 第三方/core → 本地”分组；星铁/ZZZ 的 `GameId` 还是未使用导入 |
| 常量/变量命名 camelCase | ✅ | buttonModifier、materialViewer 等符合规范 |

### 3.3 组件复用

| 复用的组件 | 说明 |
|-----------|------|
| `MaterialListContentView` | 核心内容视图，已提取为公共组件 |
| `SegmentedTabBar / SegmentedTabItem` | 分段控制器，已提取为公共组件 |
| `ThemeManager` | 主题管理单例 |
| `PrimaryButtonModifier` | 按钮样式修饰器 |
| `PlaceholderView`（`components/common`） | 其他页面使用；MaterialList 三页的 EMPTY 态为内联 Column（📦 + Text + Button），未使用 PlaceholderView 组件 |
| `AppRoutes` | 路由常量（导航直接用 `onReady` 拿到的 `localStack`，未使用 `RouterUtil`） |

**复用率：高。业务逻辑下沉到 ViewModel，UI 层只负责布局。**

### 3.4 职责划分

| 层级 | 职责 | 评价 |
|------|------|------|
| Page (MaterialList) | UI 布局 + Tab 切换 + 导航 | ✅ 清晰 |
| ViewModel | 数据转换 (`materialsGroupByCharacter/Material`) | ✅ 合理 |
| Model (MaterialListModels) | `MaterialListViewMode` 枚举 | ✅ 轻量 |
| Component (MaterialListContentView) | 列表渲染 | ✅ 提取良好 |

### 3.5 主题适配

- ✅ 使用 `themeManager` + `ThemeFonts`
- ✅ `PrimaryButtonModifier` 封装按钮样式
- ⚠️ 无显式深色模式颜色切换逻辑（可能在 ThemeManager / ThemeFonts 内部处理）

---

## 4. 重复度评估

### 4.1 代码重复统计

三文件之间：

- **结构相同的代码：** 约 180 行/文件（~96%）；差异集中在 L2/L4 注释、L12 VM import、L15 import（星铁/ZZZ 多 `GameId` 未使用）、TAG、struct/VM 类名、路由常量、L162 标题资源、Preview / Builder 名。
- 星铁 / ZZZ 除 §2.2 列出的命名、ViewModel、路由常量与标题资源差异外逐行一致。
- **ViewModel 层（2026-11-12 已处理）**：三个 ViewModel 的「角色排序 / 按材料汇总 / 分组 / 材料项转换」逐行重复，已抽到 `viewmodel/MaterialListAggregator.ets`；重复部分从 628 + 368 + 421 行降到 449 + 261 + 258 行（详见 §4.3）。

### 4.2 合并建议

**页面层：重复程度高但可接受。**

理由：
1. 三个游戏的数据模型不完全相同，如果合并为泛型参数会增加复杂度。
2. 差异点仅在游戏 ID 和 ViewModel，属于"同类模板"而非"需要复用的逻辑"。
3. MaterialListContentView / SegmentedTabBar 等子组件已提取复用；空/错误态为内联 Column，无独立 ErrorStateView 文件。

**推荐方案（可选）：** 如果未来新增第四游戏，可考虑引入代码生成工具（如脚本自动生成三份文件），而非继续手动复制粘贴。

### 4.3 ViewModel 聚合逻辑去重（2026-11-12）

| 项 | 结果 |
| --- | --- |
| 新增 `viewmodel/MaterialListAggregator.ets` | 273 行纯函数聚合器：`sortCharactersForDisplay` / `stampSectionKeys` / `aggregateMaterials` / `groupIntoSections` / `buildMaterialItems` / `rarityFromString` / `rarityFromZZZString` |
| 差异参数化 | 已拥有数量：原神传 `bagCounts`（`max(背包, 单角色最大已拥有)` 且不超过总需求），星铁 / 绝区零传 `null` 保持 0；分组：原神传货币 id 集合（`202` / `104003` / `104013`）分两组，星铁 / 绝区零传 `null` 只有 `ALL` 分组 |
| `GenshinMaterialListViewModel` | 628 → **449 行**：保留 `buildSummariesFromOverall`（整批 `overall_consume` 精确值）、`parseSkillItems`、`loadCharacterMaterials` 等原神专属逻辑 |
| `StarRailMaterialListViewModel` | 368 → **261 行** |
| `ZZZMaterialListViewModel` | 421 → **258 行**：`parseNeedGetItems` / `parseMaterialItems` / `parseZZZRarity` 改为委托聚合器（顺带删除逐条材料的调试日志） |
| 行为不变量 | 材料 id 数值降序、同材料同角色需求量累加、关联角色合并、`have >= need` 过滤（绝区零 `need_get` 的 `have = 0` 等价于过滤 `need <= 0`）、货币分组按总需求降序、`renderKey` 规则均与改造前一致 |
| 单元测试 | 新增 `src/test/MaterialListAggregator.test.ets`（16 条）：覆盖排序 / 汇总 / 背包语义 / 分组 / 材料项过滤 / 稀有度转换；`MaterialListAggregator` 覆盖率 **98.58% 行 / 100% 分支** |
| 编译 | ✅ `hvigorw assembleHap -p product=uat -p buildMode=debug` → `BUILD SUCCESSFUL` |
| 测试 | ✅ `hvigorw --mode module -p module=material@default -p product=default test` → 全绿 |

---

## 5. 问题与改进建议

### 5.1 发现的问题

| 优先级 | 编号 | 问题 | 说明 |
|--------|------|------|------|
| **中** | M-LIST-1 | 三页骨架复制（约 96% / 180 行） | ✅ 已关闭（M7）：抽 `MaterialListScaffold`，三页各 55 行，仅保留 VM / 路由 / 标题差异。 |
| **中** | M-LIST-2 | 重新计算失败对用户静默 | 三个 VM 的 `syncComputeData()` 把 `no_selection` / `compute_failed` / `no_config` 写进 `@Trace syncErrorMsg`，但页面仍不读取该字段；失败后照旧 `loadData()` 展示旧数据。属行为变更，单独提交。 |
| **低** | M-LIST-3 | 三页日志文案重复且偏调试 | ✅ 已关闭（M7）：页面不再打日志，`sync` / `config` / 空态回调集中到 `MaterialListScaffold`。 |
| **低** | M-LIST-4 | 死导入 / 死代码 | ✅ 已关闭（M7）：删除星铁 / ZZZ 的 `GameId` 死导入、三页 `Logger` 死导入、三个 VM 的 `refresh()` / `isRefreshing`、`GenshinMaterialListViewModel.formatCurrencyAmount`。 |
| **低** | M-LIST-5 | 星铁 VM 调试残留 | ✅ 已关闭（M7）：删除 `avatarId === '1510'` 分段循环与空 `if` 体。 |
| **低** | M-LIST-6 | 数量单位"万/亿"硬编码 | 🔶 部分关闭（M7）：三份重复实现合并为 `utils/MaterialAmountUtil.formatCurrencyAmount`；中文单位文案未改，英文环境仍显示「万 / 亿」，留待文案资源化。 |

### 5.2 改进建议

| 优先级 | 编号 | 建议 |
|--------|------|------|
| **信息** | M-LIST-7 | 是否提取 `BaseMaterialList<T>` 泛型外壳（NavDestination + Scroll + SegmentedTabBar + PrimaryButton）：**当前不建议**（ArkTS 泛型 struct + `@BuilderParam` 会改变组件树），先保持三页，只统一日志与删除死导入。 |

---

## 6. 依赖文件索引

| 类型 | 文件 |
|------|------|
| ViewModel | `features/material/src/main/ets/viewmodel/GenshinMaterialListViewModel.ets` / `features/material/src/main/ets/viewmodel/StarRailMaterialListViewModel.ets` / `features/material/src/main/ets/viewmodel/ZZZMaterialListViewModel.ets` |
| 共享聚合器 | `features/material/src/main/ets/viewmodel/MaterialListAggregator.ets`（三个材料汇总 ViewModel 共用，纯函数、无状态） |
| Model | `features/material/src/main/ets/model/MaterialListModels.ets`（共享） |
| Component | `features/material/src/main/ets/views/MaterialListContentView.ets`（共享） |
| Component | `common/basic/src/main/ets/shares/SegmentedTabBar.ets`（共享，见 common 层） |
| Component | ~~`../components/common/PlaceholderView`~~ **未使用**：三页 EMPTY 态均为页内内联 `Column`（📦 + Text + Button），未导入 PlaceholderView |
| Theme | `common/basic/src/main/ets/theme/ThemeManager.ets`、`common/basic/src/main/ets/theme/ThemeFonts.ets` |
| Style | `common/basic/src/main/ets/theme/PrimaryButtonModifier.ets` |
| Constant | `common/basic/src/main/ets/constants/AppRoutes.ets`、`common/basic/src/main/ets/constants/ViewState.ets` |
| Core | `'core'` (Logger)；StarRail/ZZZ 文件有未使用的 `GameId` 导入（见 M-LIST-4） |

---

## 7. 重构执行备注（M7 · MaterialList）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `custom_router_map.json:69-71 / 89-91 / 94-96`（ZZZ / Genshin / StarRail）：三条 `*MaterialList` 路由分别指向三个页面与 `GenshinMaterialListBuilder` / `StarRailMaterialListBuilder` / `ZZZMaterialListBuilder`，**页面路径与 Builder 名冻结** |
| 路由常量 | `AppRoutes.GENSHIN_MATERIAL_LIST` / `STARRAIL_MATERIAL_LIST` / `ZZZ_MATERIAL_LIST` 字符串冻结；目标配置页路由常量同样冻结 |
| 测试 | 三个 `*MaterialListViewModel` 自 2026-11-07 起有 Local Test（`src/test/*MaterialListViewModel.test.ets`，覆盖状态机 / 切换 / 折叠 / 同步守卫）；2026-11-12 新增 `MaterialListAggregator.test.ets` 覆盖聚合逻辑 |
| 共享组件 | `features/material/src/main/ets/views/materiallist/`（6 个文件）与 `common/basic/src/main/ets/shares/SegmentedTabBar.ets` 被三页共用，不移动 |
| 共享模型 | `features/material/src/main/ets/model/MaterialListModels.ets`、`features/material/src/main/ets/model/ToolsModels.ets`（`MaterialTargetConfigParam`）保持原位 |

### 重构范围（已执行）

- 三页外壳收敛到 `views/MaterialListScaffold.ets`：标题栏、同步 / 更改配置菜单、视图模式 Tab、LOADING / EMPTY / DATA 三态与空态按钮统一；页面只保留 VM 初始化、参数与回调。
- 三个路由入口与三个 Builder 保留，`pageSourceFile` / `buildFunction` 不变。
- 删除死代码：星铁 / ZZZ 的 `GameId` 与三页 `Logger` 死导入、三个 VM 的 `refresh()` / `isRefreshing`、`GenshinMaterialListViewModel.formatCurrencyAmount`、星铁 `'1510'` 调试循环与空 `if`。
- 三份「万 / 亿」格式化合并为 `utils/MaterialAmountUtil.ets`，输出文案与舍入规则保持不变。
- `GenshinMaterialListViewModel` 628 → **449 行**（2026-11-12）：角色排序、按材料汇总、分组、材料项转换抽到 `viewmodel/MaterialListAggregator.ets`；星铁 / 绝区零同步降到 261 / 258 行。
- `MaterialListContentView` / `SegmentedTabBar` 保持原位。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. Local Test：三个 ViewModel 的状态机用例 + `MaterialListAggregator` 的聚合用例全绿（`material@default` 模块）。
3. 冒烟：三个游戏材料汇总页、按角色/按材料两个 Tab、目标配置入口、空/错误态。

### 已知问题归属

- Medium（重新计算失败静默，M-LIST-2）：补 toast / 错误态属行为变更，单独提交，不夹带在重构里。
- Low（万/亿中文单位，M-LIST-6 剩余部分）：需补资源字符串，属 UI 文案变更，单独提交。
- ~~信息（拆分 `GenshinMaterialListViewModel`）~~：✅ 已执行（GAP-08，2026-11-12）。

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | 三页均 186 行；VM 694 / 413 / 445；material-list 6 个组件全部存在且被引用；`MaterialListViewMode` 枚举 | ✅ 全部精确匹配 |
| 第 2 轮（差异 + 行号） | L2 注释 / L15 core import / L21 TAG / L25 VM / L61 路由常量；菜单 sync 条件（DATA）+ config 始终；EMPTY 内联 Column；路由 `69-71 / 89-91 / 94-96` | ✅ 全部精确 |
| 第 3 轮（全面复核） | ContentView 实际 4 个参数；星铁/ZZZ `GameId` 仅 import 未使用；页面未导入 PlaceholderView；StarRail vs ZZZ diff；§7 归属与 §5 对齐 | ✅ 修正 5 处（传参 / 差异描述 / 虚构依赖 / import 说明 / 归属） |
| 第 4 轮（2026-10-27 逐条复核） | 三个 VM 全文（sync / loadData / 调试代码）、material-list 组件的数量格式化、`SegmentedTabBar` 同 Tab 点击保护、§2.2 diff 全量 | ✅ 新增 1 Medium（sync 失败静默）+ 2 Low（`'1510'` 残留、万/亿硬编码），原 GameId Low 扩为死导入/死代码；补 L162 标题差异；去掉未使用的 RouterUtil；编号重排为 M-LIST-1~7 |
| 第 5 轮（2026-10-30 断链修复） | 三页 / ViewModel / Model / Content View 全量更新为 `features/material/src/main/ets/` 绝对路径；`SegmentedTabBar` 从 `components/common/` → `common/basic/src/main/ets/shares/`；`PrimaryButtonModifier` 从 `styles/` → `common/basic/src/main/ets/theme/`；§7 测试路径补全 | ✅ 16 处路径全部验证存在 |
| 第 6 轮（2026-11-04 M7 执行后） | 三页各 55L + `MaterialListScaffold` 164L + `MaterialAmountUtil` 39L；VM 628 / 368 / 421L；死代码与 `'1510'` 残留已删；`bash run.sh uat` 通过 | ✅ 行数与结构复核一致 |
| 第 7 轮（2026-11-12 GAP-08 执行后） | 三个 VM 449 / 261 / 258L + `MaterialListAggregator` 273L；`wc -l` 复核；聚合逻辑全部委托共享件、原神专属逻辑保留；`assembleHap` 通过 + `material@default` 单测全绿（聚合器 98.58% 行 / 100% 分支） | ✅ 行数、调用点与测试现状一致 |
