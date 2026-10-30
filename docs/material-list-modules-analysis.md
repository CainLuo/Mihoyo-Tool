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
| `features/material/src/main/ets/pages/GenshinMaterialListPage.ets` | 186 | `@ComponentV2` | GenshinMaterialListViewModel |
| `features/material/src/main/ets/pages/StarRailMaterialListPage.ets` | 186 | `@ComponentV2` | StarRailMaterialListViewModel |
| `features/material/src/main/ets/pages/ZZZMaterialListPage.ets` | 186 | `@ComponentV2` | ZZZMaterialListViewModel |

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

### 4.2 合并建议

**当前状态评价：重复程度高但可接受。**

理由：
1. 三个游戏的数据模型不完全相同，如果合并为泛型参数会增加复杂度。
2. 差异点仅在游戏 ID 和 ViewModel，属于"同类模板"而非"需要复用的逻辑"。
3. MaterialListContentView / SegmentedTabBar 等子组件已提取复用；空/错误态为内联 Column，无独立 ErrorStateView 文件。

**推荐方案（可选）：** 如果未来新增第四游戏，可考虑引入代码生成工具（如脚本自动生成三份文件），而非继续手动复制粘贴。

---

## 5. 问题与改进建议

### 5.1 发现的问题

| 优先级 | 编号 | 问题 | 说明 |
|--------|------|------|------|
| **中** | M-LIST-1 | 三页骨架复制（约 96% / 180 行） | `Genshin/StarRail/ZZZMaterialList` 各 186 行，除 TAG、VM 类名、`AppRoutes` 目标、`GameId` 外逐行相同；新增第四个游戏要再复制 186 行，改一处外壳要同步改三处。与 DAILY-M1（便签三页）同类问题。 |
| **中** | M-LIST-2 | 重新计算失败对用户静默 | 三个 VM 的 `syncComputeData()`（`features/material/src/main/ets/viewmodel/GenshinMaterialListViewModel.ets:141-166`、`features/material/src/main/ets/viewmodel/StarRailMaterialListViewModel.ets:120-145`、`features/material/src/main/ets/viewmodel/ZZZMaterialListViewModel.ets:120-145`）把 `no_selection` / `compute_failed` / `no_config` 写进 `@Trace syncErrorMsg`，但三页均不读取该字段（全工程只有 VM 自己引用）；右上角 sync（L46-49）与空态按钮（L135-138）点完只看到按钮短暂禁用，失败后照旧 `loadData()` 展示旧数据，用户无法区分"已是最新"与"计算失败"。 |
| **低** | M-LIST-3 | 三页日志文案重复且偏调试 | `Logger.info(TAG, 'Button onClick triggered')` 等文案逐页复制；可收敛为统一日志点，但不影响功能。 |
| **低** | M-LIST-4 | 死导入 / 死代码 | 星铁/ZZZ `import { Logger, GameId } from 'core'`（`StarRailMaterialListPage.ets:15` / `ZZZMaterialListPage.ets:15`）中 `GameId` 未使用，原神文件没有导入；三个 VM 的 `refresh()` / `isRefreshing`（Genshin L74/L114、SR·ZZZ L54/L93）页面无 Refresh 容器、无调用方；`GenshinMaterialListViewModel.formatCurrencyAmount`（静态，无引用）。 |
| **低** | M-LIST-5 | 星铁 VM 调试残留 | `features/material/src/main/ets/viewmodel/StarRailMaterialListViewModel.ets:255-266` 对 `avatarId === '1510'` 把 rawJson 切成 2000 字符分段但不输出任何内容；L279-280 为空 `if` 体。无副作用，与 starrail-character-detail 的 `'1510'` 残留同判 Low（COMPAT-005）。 |
| **低** | M-LIST-6 | 数量单位"万/亿"硬编码 | `MaterialGridCard.ets:87-119` 与 `MaterialGridItem.ets:93` 各自私有一份 `formatCurrencyAmount`，直接拼接中文 `'万'` / `'亿'`，英文环境下仍显示中文单位；与 VM 内的静态版本共三份重复实现。 |

### 5.2 改进建议

| 优先级 | 编号 | 建议 |
|--------|------|------|
| **信息** | M-LIST-7 | 是否提取 `BaseMaterialList<T>` 泛型外壳（NavDestination + Scroll + SegmentedTabBar + PrimaryButton）：**当前不建议**（ArkTS 泛型 struct + `@BuilderParam` 会改变组件树），先保持三页，只统一日志与删除死导入。 |

---

## 6. 依赖文件索引

| 类型 | 文件 |
|------|------|
| ViewModel | `features/material/src/main/ets/viewmodel/GenshinMaterialListViewModel.ets` / `features/material/src/main/ets/viewmodel/StarRailMaterialListViewModel.ets` / `features/material/src/main/ets/viewmodel/ZZZMaterialListViewModel.ets` |
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
| 测试 | 三个 `*MaterialListViewModel` **没有** Local Test；M7 只有 `features/material/src/test/MaterialCalcViewModel.test.ets` |
| 共享组件 | `features/material/src/main/ets/views/materiallist/`（6 个文件）与 `common/basic/src/main/ets/shares/SegmentedTabBar.ets` 被三页共用，不移动 |
| 共享模型 | `features/material/src/main/ets/model/MaterialListModels.ets`、`features/material/src/main/ets/model/ToolsModels.ets`（`MaterialTargetConfigParam`）保持原位 |

### 重构范围（建议）

- 页面级合并（`BaseMaterialList`）不建议在 M7 做：三个路由入口 + 三个 Builder 必须保留，收益主要在 UI 外壳，风险大于收益。
- `GenshinMaterialListViewModel` 694 行（>500）可拆分，但它**没有测试**，拆分必须保留原文件 facade；建议先记录，不强制。
- `MaterialListContentView` / `SegmentedTabBar` 已经是共享组件，不要下沉到某个游戏目录。
- 仅允许等价清理：统一三页的日志文案与重复菜单回调（行为不变）。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. 无 Local Test：按 Refactor_Spec §7.1 冒烟——三个游戏材料汇总页、按角色/按材料两个 Tab、目标配置入口、空/错误态。

### 已知问题归属

- Medium（三页骨架复制 ~96%）：与 M6 同类，记录；不合并页面，只在新增第四游戏前先评估共享外壳。
- Medium（重新计算失败静默，M-LIST-2）：补 toast / 错误态属行为变更，单独提交，不夹带在重构里。
- Low（日志文案重复、死导入/死代码、星铁 `'1510'` 残留、万/亿硬编码）：前三项可顺手清理（行为不变），单独提交；万/亿需补资源字符串，属 UI 文案变更。
- 信息（可提取 BaseMaterialList）：记录，不在本轮做。

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | 三页均 186 行；VM 694 / 413 / 445；material-list 6 个组件全部存在且被引用；`MaterialListViewMode` 枚举 | ✅ 全部精确匹配 |
| 第 2 轮（差异 + 行号） | L2 注释 / L15 core import / L21 TAG / L25 VM / L61 路由常量；菜单 sync 条件（DATA）+ config 始终；EMPTY 内联 Column；路由 `69-71 / 89-91 / 94-96` | ✅ 全部精确 |
| 第 3 轮（全面复核） | ContentView 实际 4 个参数；星铁/ZZZ `GameId` 仅 import 未使用；页面未导入 PlaceholderView；StarRail vs ZZZ diff；§7 归属与 §5 对齐 | ✅ 修正 5 处（传参 / 差异描述 / 虚构依赖 / import 说明 / 归属） |
| 第 4 轮（2026-10-27 逐条复核） | 三个 VM 全文（sync / loadData / 调试代码）、material-list 组件的数量格式化、`SegmentedTabBar` 同 Tab 点击保护、§2.2 diff 全量 | ✅ 新增 1 Medium（sync 失败静默）+ 2 Low（`'1510'` 残留、万/亿硬编码），原 GameId Low 扩为死导入/死代码；补 L162 标题差异；去掉未使用的 RouterUtil；编号重排为 M-LIST-1~7 |
| 第 5 轮（2026-10-30 断链修复） | 三页 / ViewModel / Model / Content View 全量更新为 `features/material/src/main/ets/` 绝对路径；`SegmentedTabBar` 从 `components/common/` → `common/basic/src/main/ets/shares/`；`PrimaryButtonModifier` 从 `styles/` → `common/basic/src/main/ets/theme/`；§7 测试路径补全 | ✅ 16 处路径全部验证存在 |
