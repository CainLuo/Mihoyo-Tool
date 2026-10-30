# ZZZCharacterDetail 模块分析

> **文件：** `features/chardetail/src/main/ets/pages/ZZZCharacterDetailPage.ets`（140 行）  
> **游戏：** 绝区零 (ZZZ) — 角色详情页面 View 层  
> **对比参考：** GenshinCharacterDetail / StarRailCharacterDetail（结构基本一致）  
> **分析日期：** 2026-10-24（重构备注同日复核）
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 1 |
| Medium | 1 |
| Low | 5 |

**整体评级：B**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + High ≤ 3 → B；有 1 条 High，达不到 A 的"0 High"）。旧百分制已废弃，原分 94/100 仅作历史参考。
>
> 债务点数 = 1×3 + 1×2 + 5×1 = **10**；页面 140 行，密度 **7.1**/百行。（2026-10-27 复核前为 H1/M1/L2、7 点、5.0：`heroHeight()` 未缓存由 Medium 改判 Low（与星铁同项同级）；`catch (_e) {}` 改为信息项不计数（与星铁 / 原神一致）；尺寸双初始化改写为"初始尺寸取整屏"；新增 ARKTS-014 Medium 与 3 条 Low。）

---

## 1. 文件基本信息

| 属性 | 值 |
|------|-----|
| 行数 | 140 |
| ViewModel | `viewmodel/ZZZCharacterDetailViewModel.ets`（265 行） |
| 模型 / 状态 | `models/CharDetailModels.ets`（272 行，三游戏共享）、`constants/ViewState.ets`（18 行） |
| 专属子组件 | `components/chardetail/zzz/` 13 个文件 / 710 行（见 2.2） |
| @Component 版本 | `@ComponentV2` |
| Preview | ✅ 包含 `@Preview ZZZCharacterDetailPreview` |
| Router Builder | ✅ 导出 `ZZZCharacterDetailBuilder` |
| 窗口适配 | ✅ 监听 `windowSizeChange` + `onAreaChange` |

---

## 2. 代码结构分析

### 2.1 整体布局

```
@ComponentV2 export struct ZZZCharacterDetail
├── @Param routerParam: CharDetailRouterParam
├── @Local tm: ThemeManager
├── @Local vm: ZZZCharacterDetailViewModel
├── @Local windowWidthVp / windowHeightVp / currentBreakpoint
├── private uiCtx: UIContext
├── private sizeCallback: (size: window.Size) => void
├── aboutToAppear() → 获取整屏尺寸（display）+ 监听 sizeChange + vm.init + vm.loadData
├── @Monitor('vm.networkErrorMsg') onNetworkError() → showFeedback(ERROR, msg)
├── aboutToDisappear() → 移除 windowSizeChange 监听
├── private heroHeight(): number → 横竖屏判断返回不同高度
├── build() → NavDestination
│   ├── Column → onAreaChange 断点判断 (xs/sm/md/lg)
│   │   ├── ViewState.LOADING → CharDetailLoadingView
│   │   ├── ViewState.EMPTY/ERROR → CharDetailEmptyView
│   │   └── else:
│   │       ├── 宽屏 (md/lg) → ZZZCharDetailWideLayout({ vm })
│   │       └── 窄屏 (xs/sm) → Scroll → Column → ZZZCharDetailHero + ZZZCharDetailContent
├── @Preview ZZZCharacterDetailPreview
└── @Builder ZZZCharacterDetailBuilder(name, param)
```

### 2.2 游戏特有组件（vs 原神/星铁）

| 组件 | 说明 |
|------|------|
| `ZZZCharDetailContent` | ZZZ 专属内容渲染组件（角色属性/装备/词条等） |
| `ZZZCharDetailHero` | ZZZ 英雄头像/立绘区域 |
| `ZZZCharDetailWideLayout` | ZZZ 宽屏分栏布局（左栏 Hero + 技能，右栏 Scroll：音擎 + 属性 + 驱动盘） |

> 其余 10 个文件由以上三者组合：`ZZZCharDetailHeroInfo`、`ZZZSkillsSection` / `ZZZSkillItem`、`ZZZWeaponSection` / `ZZZWeaponCard`、`ZZZPropsSection`、`ZZZEquipSection` / `ZZZEquipCard` / `ZZZEquipCardHeader` / `ZZZSuitSummaryRow`。
>
> 星铁对应 `StarRailCharDetailContent/Hero/WideLayout`，页面文件与本页逐行一致（仅类名 / 标题资源不同）。原神**不是**同构：组件无游戏前缀（`CharDetailPortraitLayout` / `CharDetailLandscapeLayout` / `CharDetailWideLayout` + `CharDetailHeroPanel`），并多了材料计算入口。

---

## 3. 合规审查

### 3.1 ArkTS 语法规范

| 规则 | 状态 | 说明 |
|------|------|------|
| @ComponentV2 使用 | ✅ | 正确使用 V2 装饰器 |
| @Param 路由参数 | ✅ | `routerParam: CharDetailRouterParam` 使用 @Param，正确接收路由参数 |
| @Local 状态管理 | ✅ | vm、tm、window 尺寸、breakpoint 均用 @Local |
| @Monitor 网络错误监听 | ✅ | 对 `vm.networkErrorMsg` 做 Monitor 绑定（L55），触发 toast 提示 |
| Monitor 路径为顶层 const | ⚠️ | VM L32/L34 导出 `ZZZ_CHAR_DETAIL_VM_VIEW_STATE` / `ZZZ_CHAR_DETAIL_VM_ERROR`，全工程无引用；Page L55 直接写字符串（星铁 / 原神同样如此） |
| ARKTS-014 import 走 `@kit.*` | ⚠️ | L4 `import display from '@ohos.display'` 为旧式导包 |
| 无内联 @Builder（错误用法） | ✅ | 无错误内联 @Builder |
| Preview / Router Builder | ✅ | 包含预览和路由构造器，符合路由规范 |
| 类型声明完整 | ✅ | 所有变量均有显式类型 |

### 3.2 命名约定

| 规则 | 状态 | 说明 |
|------|------|------|
| 文件名 PascalCase | ✅ | ZZZCharacterDetailPage.ets 符合规范 |
| struct 名 PascalCase | ✅ | 与文件名一致 |
| import 分组排序 | ✅ | @ohos/kit → 项目内部 → 常量/模型，顺序清晰 |

### 3.3 组件复用

| 复用的组件 | 说明 |
|-----------|------|
| `themeManager + ThemeManager` | 主题单例管理 |
| `CharDetailLoadingView / CharDetailEmptyView` | 通用 loading/空状态（common 目录，三游戏共享） |
| `ZZZCharDetailHero / Content / WideLayout` | ZZZ 专属内容组件（zzz 子目录） |
| `showFeedback + FeedbackType` | 统一的 toast/反馈工具 |
| `CharDetailRouterParam` | 路由参数模型（三游戏共享） |

**复用率：高。** common 层 Loading/Empty 视图被三游戏共享，游戏差异部分在 zzz 子目录中隔离。

### 3.4 职责划分

| 层级 | 职责 | 评价 |
|------|------|------|
| Page (ZZZCharacterDetail) | UI 布局 + 窗口适配 + 错误提示 | ✅ 清晰，仅负责 View 层 |
| ViewModel (ZZZCharacterDetailViewModel) | 数据加载 / JSON 解析 / 状态管理（无缓存） | ✅ 合理（解析异常处理见 ZZZ-CD-0） |
| Component (ZZZCharDetail*) | 游戏专属渲染逻辑 | ✅ 隔离良好 |
| Model (CharDetailModels) | 路由参数 + 三游戏展示模型（272 行） | ✅ 共享 |

### 3.5 主题适配

- ✅ 页面层使用 `themeManager.current` 获取颜色（bgPageDeep、full 等）
- ℹ️ zzz 子组件仍有较多硬编码 ARGB（如 `ZZZCharDetailHero.ets:66-67` 的 `'#99000000'` / `'#66000000'`，星铁同位置用的是 `overlayPortraitStrong` / `overlayPortraitMid` token；另见 `ZZZPropsSection` / `ZZZSkillsSection` / `ZZZSuitSummaryRow` / `ZZZWeaponCard` / `ZZZEquipCard`）。详情页固定深色底，暂无可见故障，记为信息不计数
- ✅ SafeArea 扩展 + 响应式布局
- ✅ breakpoint 系统（xs/sm/md/lg）配合宽屏自适应

---

## 4. 三游戏对比

| 维度 | 原神 | 星铁 | ZZZ |
|------|------|------|-----|
| 行数 | 154 | 140 | 140 |
| Hero 高度逻辑 | 无 `heroHeight()`；xs 下按宽高选 Portrait / Landscape 布局，竖屏英雄区固定 260 | `heroHeight()` 横竖判断 260/200 | ✅ 同星铁（`heroHeight()` L76-80） |
| 宽屏适配 | sm/md/lg → `CharDetailWideLayout` | md/lg → WideLayout | ✅ 同星铁 |
| @Monitor 网络错误 | ✅ | ✅ | ✅ |
| 组件命名一致性 | `CharDetail*`（无游戏前缀） | `StarRail*` | `ZZZ*` |

**页面相似度**：ZZZ 与星铁页面逐行一致（`diff` 仅类名 / import / 标题资源不同）；原神页面多出材料计算跳转（`localStack` + `onReady`）与 xs 横竖布局切换，结构差异明显。

---

## 5. 问题与改进建议

### 5.1 发现的问题

| 优先级 | 编号 | 问题 | 说明 |
|--------|------|------|------|
| **High** | ZZZ-CD-0 | `parseRawJson` 吞掉异常后仍进入 DATA | VM `parseRawJson` 的 catch（L223-226）只 `Logger.error`，不抛不设 ERROR；`loadData` 随后仍执行 `viewState = DATA`（L91-92），JSON 解析失败时用户看到空白 / 部分数据且无错误提示（与原神/星铁同源问题，三游戏同级 High） |
| **Medium** | ZZZ-CD-6 | 旧式 `@ohos.*` 导包（ARKTS-014） | Page L4 `import display from '@ohos.display'`，应改 `import { display } from '@kit.ArkUI'`；星铁 / 原神角色详情及三个 DailyDetail 页同样如此 |
| **低** | ZZZ-CD-1 | `heroHeight()` 是普通方法而非 @Computed | Page L76-80。这是可选的渲染优化：build() 会因读取 `@Local windowWidthVp/HeightVp` 而重算，并非响应式缺陷；与星铁同项同级（Low） |
| **低** | ZZZ-CD-3 | 初始尺寸取整屏而非窗口 | `aboutToAppear` 先用 `display.getDefaultDisplaySync()`（L41-43）初始化尺寸，`windowSizeChange`（L48）只在尺寸**变化**时回调；分屏 / 悬浮窗进入时 `heroHeight()` 基于整屏宽高判断，直到窗口再次变化。三游戏同源 |
| **低** | ZZZ-CD-7 | Monitor 路径常量已定义但未使用 | VM L32/L34 导出的两个常量全工程无引用，Page L55 直接写字符串；三游戏同级 |
| **低** | ZZZ-CD-8 | 宽屏左栏无 Scroll | `ZZZCharDetailWideLayout.ets:23-31` 左栏（Hero 固定 260 + 技能区）`.height(full)` 无滚动，右栏已有 Scroll（L34-51）；窗口高度不足时技能区底部被裁切。与星铁同构 |
| **低** | ZZZ-CD-9 | 驱动盘按数组下标排布、不按 `pos` | `ZZZEquipSection.ets:39-55` 用 `equips[startIdx]` 顺序填 6 格，占位名用 `${startIdx + 1}`；VM 已解析 `equip.pos = e.equipment_type`（VM L176）但未用于定位。未装满 6 件时，卡片位置与占位编号会和实际缺失槽位不符。星铁遗器同源，原神按 `pos` 查找不受影响 |
| ℹ️ 信息 | ZZZ-CD-2 | `catch (_e) {}` 静默吞异常 | aboutToAppear/Disappear 中共 5 处（L44 / L48 / L50 / L71 / L73），均为窗口尺寸监听的非关键路径；与星铁 / 原神一致按信息处理，**不计数**。如需排查可补一行 Logger |

### 5.2 改进建议

> 本表为建议，不计入执行摘要计数。

| 优先级 | 编号 | 建议 |
|--------|------|------|
| **低** | ZZZ-CD-4 | （对应 ZZZ-CD-1）将 `heroHeight()` 改为 `@Computed get heroHeight(): number`，或在尺寸回调里缓存到 @Local 属性。 |
| **低** | ZZZ-CD-5 | ZZZ 与星铁页面逐行一致，可提取共享页面骨架（Hero / Content / WideLayout 以参数注入）；原神结构不同，不宜一并合并。 |

---

## 6. 依赖文件索引

| 类型 | 文件 |
|------|------|
| ViewModel | `../viewmodel/ZZZCharacterDetailViewModel` |
| Model | `../models/CharDetailModels`（CharDetailRouterParam，共享） |
| Component (common) | `../components/chardetail/common/CharDetailLoadingView` / `CharDetailEmptyView` |
| Component (zzz) | `../components/chardetail/zzz/ZZZCharDetailContent` / `ZZZCharDetailHero` / `ZZZCharDetailWideLayout` |
| Theme | `../theme/ThemeManager` |
| Constant | `../constants/ViewState`、`../constants/FeedbackType` |
| Utils | `../utils/FeedbackUtil` (showFeedback) |
| Kit | `@ohos.display`、`@kit.ArkUI` (window, UIContext) |

---

## 7. 重构执行备注（M10 · ZZZ CharacterDetail）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `custom_router_map.json:34-36`：`ZZZCharacterDetail` → `pages/ZZZCharacterDetailPage.ets` + `ZZZCharacterDetailBuilder`，**页面路径与 Builder 名冻结** |
| 路由参数 | `CharDetailRouterParam`（`models/CharDetailModels.ets`，272 行）三游戏共享，字段名不改 |
| 测试 | `ZZZCharacterDetailViewModel`（265 行）**没有** Local Test；M10 只有 Genshin 版有测试 |
| 共享组件 | `components/chardetail/common/` 9 个文件不移动；本页经子组件引用其中 6 个（Loading / Empty / ConsColumn / HeroNameOverlay / SectionLabel / RelicPlaceholder），另 3 个（SkillItem / StatRow / MaterialCalcEntry）只被原神使用 |
| 游戏组件 | `components/chardetail/zzz/` 13 个文件，仅本页使用 |

### 重构范围（建议）

- 页面/目录已符合 N-4；**没有必须的目录移动**。
- `parseRawJson` 的 ERROR 兜底（ZZZ-CD-0）建议在 M10 内修，且三游戏一起修；必须与移动分开提交。
- `heroHeight()` 改 `@Computed` 是可选优化，不是正确性修复。
- `@ohos.display` → `@kit.ArkUI` 是等价导包替换，可与目录调整同提交；驱动盘按 `pos` 排布会改变展示结果，属行为修复，单独提交。
- 不合并 `zzz/` 的 13 个组件到 common（装备/驱动盘/词条模型是游戏特定的）。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. 无 Local Test：冒烟——ZZZ 角色详情窄屏/宽屏、装备/驱动盘/技能/属性、返回、错误态（构造解析失败数据）。

### 已知问题归属

- High（`parseRawJson` 吞异常）：建议随 M10 修，单独提交；修完更新评级。
- Medium（ARKTS-014 导包）：可顺手改。
- Low（`heroHeight` 未缓存、初始尺寸取整屏、Monitor 常量未使用、宽屏左栏无 Scroll、驱动盘不按 pos 排布）：Monitor 常量建议顺手清理，其余记录。
- 信息（5 处 `catch (_e) {}`）：不计数。

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | §1 Page/VM 行数、zzz 子组件 13 文件/710 行 | ✅ |
| 第 2 轮（关键代码段） | L55 Monitor、L76 heroHeight()、L112-118 onAreaChange、catch(_e){} 数量 | ✅ |
| 第 3 轮（全面复核） | parseRawJson catch、§7 测试声明、子组件逐文件行数 | ✅ |
| 第 4 轮（2026-10-27 逐条复核） | 摘要口径行写错评级条件（已改为 B 的条件）；三游戏对比表中原神组件名 / 断点 / Hero 逻辑描述不实；`heroHeight` 与星铁统一为 Low；catch 静默统一为信息项；补 ARKTS-014、Monitor 常量、宽屏左栏、驱动盘排布 | 已修正 |

> 注：ZZZ-CD-2 原文称 catch(_e){} "三个"，实际 5 处（L44/L48/L50/L71/L73），已在 5.1 更正。
