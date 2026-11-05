# 星穹铁道角色详情页模块分析

> 生成时间：2026-10-24 ｜ 审查标准参考：`arkts-rules/SKILL.md`
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 1 |
| Medium | 1 |
| Low | 6 |

**整体评级：B**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + High ≤ 3）。旧百分制已废弃，原分 A 仅作历史参考。
>
> 债务点数 = 1×3 + 1×2 + 6×1 = **11**；页面 140 行，密度 **7.9**/百行。（2026-10-27 复核前为 H2/M1/L2、10 点、7.1：`entityId === '1510'` 空循环无运行时影响，按 COMPAT-005 由 High 改判 Low；Monitor 常量未使用由 Medium 改判 Low；新增 ARKTS-014 Medium 与 3 条 Low。）

---

## 📂 文件清单

| 类别 | 文件路径 | 行数 | 说明 |
|------|----------|------|------|
| **Page** | `features/chardetail/src/main/ets/pages/StarRailCharacterDetailPage.ets` | 116 | 角色详情主页面（View） |
| **ViewModel** | `features/chardetail/src/main/ets/viewmodel/StarRailCharacterDetailViewModel.ets` | 239 | 数据加载 + JSON 解析 + 展示模型构造 |
| **窗口工具** | `features/chardetail/src/main/ets/utils/CharDetailWindowSize.ets` | 56 | 三游戏共用：初始尺寸 + windowSizeChange 订阅 + 断点计算（M10 新增） |
| **路由参数** | `features/chardetail/src/main/ets/model/CharDetailModels.ets`（CharDetailRouterParam） | 272 | 通用路由参数 + 展示模型（注：目录已改为单数 `model/`，非复数 `models/`） |
| **状态常量** | `common/basic/src/main/ets/constants/ViewState.ets`（ViewState 枚举） | 18 | 页面四态枚举（共享层） |

### 子组件（StarRail 专用，11 个）

| 文件 | 职责 |
|------|------|
| `features/chardetail/src/main/ets/views/starrail/StarRailCharDetailHero.ets` | 英雄区主组件 |
| `features/chardetail/src/main/ets/views/starrail/StarRailCharDetailContent.ets` | 内容区（行迹+光锥+属性+遗器/饰品） |
| `features/chardetail/src/main/ets/views/starrail/StarRailCharDetailWideLayout.ets` | 宽屏布局（md/lg breakpoint） |
| `features/chardetail/src/main/ets/views/starrail/StarRailCharDetailHeroProfile.ets` | 英雄信息面板 |
| `features/chardetail/src/main/ets/views/starrail/StarRailEquipSection.ets` | 光锥区 |
| `features/chardetail/src/main/ets/views/starrail/StarRailEquipCard.ets` | 光锥卡片 |
| `features/chardetail/src/main/ets/views/starrail/StarRailSkillsSection.ets` | 行迹技能区 |
| `features/chardetail/src/main/ets/views/starrail/StarRailSkillNode.ets` | 行迹节点项 |
| `features/chardetail/src/main/ets/views/starrail/StarRailRelicsSection.ets` | 遗器区（2×2 遗器 + 1 行饰品） |
| `features/chardetail/src/main/ets/views/starrail/StarRailRelicCard.ets` | 遗器卡片 |
| `features/chardetail/src/main/ets/views/starrail/StarRailPropsSection.ets` | 属性列表区 |

### Common 共享组件（被本模块引用）

`features/chardetail/src/main/ets/views/common/` 9 个文件中本模块引用 6 个：`CharDetailLoadingView` / `CharDetailEmptyView`（页面 L8-9）、`CharDetailConsColumn` / `CharDetailHeroNameOverlay`（`StarRailCharDetailHero.ets:8-9`）、`CharDetailSectionLabel`、`CharDetailRelicPlaceholder`（`StarRailRelicsSection.ets:8-9`）。`CharDetailMaterialCalcEntry` / `CharDetailStatRow` / `CharDetailSkillItem` 只被原神组件引用，星铁**没有**材料计算入口。

---

## 🏗️ 架构分析

### 数据流

```
DB → StarRailRepository.getAvatarDetail() → rawJson（JSON 字符串）
  ↓
StarRailCharacterDetailViewModel.parseRawJson(rawJson)
  ↓ (private 实例方法，写入 @ObservedV2 VM 的 @Trace 字段)
展示模型实例：StarRailCharDetailSkillNode / StarRailCharDetailRelic / StarRailCharDetailEquip 等
  ↓ (@Param vm: ViewModel)
页面按断点二选一（L90-105）：
  md/lg → StarRailCharDetailWideLayout（内部再组合 Hero + Skills / Equip + Props + Relics）
  xs/sm → Scroll → StarRailCharDetailHero + StarRailCharDetailContent
```

### 布局策略

**四档断点（xs/sm 共用窄屏布局）+ 英雄区高度按宽高比：**

| 条件 | Breakpoint | 布局 |
|------|-----------|------|
| `width < 600` | `xs` | Scroll → Column → Hero + Content（竖屏） |
| `600 ≤ width < 840` | `sm` | Scroll → Column → Hero + Content（竖屏） |
| `840 ≤ width < 1200` | `md` | StarRailCharDetailWideLayout |
| `width ≥ 1200` | `lg` | StarRailCharDetailWideLayout |

判断逻辑见 `StarRailCharacterDetailPage.ets:112-118`，使用 `onAreaChange` 监听 `newArea.width`（number 类型断言），无横竖屏显式判断——英雄区高度通过 `heroHeight()` 方法基于宽/高比较间接处理。

### 状态管理

- **ViewModel**：`@ObservedV2` 类 + 全部展示属性标注 `@Trace`
- **页面层**：`@Local vm`、`@Local tm`、`@Local windowWidthVp`、`@Local windowHeightVp`、`@Local currentBreakpoint`
- **错误反馈**：`@Monitor('vm.networkErrorMsg')`（Line 55）监听非空后调用 `showFeedback()`

### 生命周期与资源管理

```typescript
aboutToAppear() { // Line 37
  this.uiCtx = this.getUIContext();
  display.getDefaultDisplaySync() → px2vp 初始化尺寸（取的是整屏尺寸，不是窗口尺寸）
  window.getLastWindow(ctx, (err, win) => win.on('windowSizeChange', callback))
  this.vm.init(accountId, roleUid, entityId);
  this.vm.loadData();
}

aboutToDisappear() { // Line 65
  win.off('windowSizeChange', callback) // try-catch 包裹
}
```

---

## ✅ ArkTS 合规性检查

| 规则 | 状态 | 说明 |
|------|------|------|
| **使用 `@ComponentV2`** | ✅ | Page + Hero/Content/WideLayout 等子组件均标注 |
| **ViewModel 用 `@ObservedV2` + `Trace`** | ✅ | StarRailCharacterDetailViewModel L38-76 |
| **路由参数使用 `@Param`** | ✅ | Line 20: `@Param routerParam: CharDetailRouterParam`（通用） |
| **Local 状态使用 `@Local`** | ✅ | vm/tm/breakpoint/尺寸等 |
| **禁止字符串字面量枚举** | ✅ | `ViewState.LOADING` / `.EMPTY` / `.DATA` / `.ERROR` |
| **Monitor 路径为顶层 const** | ⚠️ | VM 文件 L32/L34 定义了 `STARRAIL_CHAR_DETAIL_VM_VIEW_STATE` 和 `STARRAIL_CHAR_DETAIL_VM_ERROR`，但全工程无引用——Page 直接写字符串 `'vm.networkErrorMsg'`（Line 55）；原神 / ZZZ 同样如此 |
| **ARKTS-014 import 走 `@kit.*`** | ⚠️ | Line 4: `import display from '@ohos.display'` 为旧式导包（Line 5 已用 `@kit.ArkUI`） |
| **Resource 类型安全引用** | ✅ | `starRailPropertyTypeToResource()` 返回 `Resource \| null`（`utils/StarRailPropertyUtil.ets:17`），调用处均 `?? ''` 兜底 |
| **NavDestination 配置** | ✅ | `.title($r('app.string.starrail_char_detail_title'))` + `.hideTitleBar(false)` |
| **SafeArea 扩展** | ✅ | Line 111: `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])` |
| **Preview 注解** | ✅ | Page 级别有 `@Preview`，Line 127-133 |

---

## 🔄 组件复用分析

### 通用层（3 游戏共享）

- `CharDetailLoadingView` / `CharDetailEmptyView` — 三个详情页共用
- `CharDetailConsColumn` — 命座列，用于原神/星铁/绝区零的命座展示
- `CharDetailHeroNameOverlay` — 英雄区左下角名字覆盖层，星铁 / ZZZ 共用（原神未用）
- `CharDetailMaterialCalcEntry` 仅原神使用；其 `gameId` 参数声明了但组件内未读取（`CharDetailMaterialCalcEntry.ets:12`），并不区分游戏

### 跨游戏复用机会

- **当前**：StarRail 专用组件全部以 `StarRail` 前缀命名，与原神（`CharDetail*`）、绝区零各自独立
- Hero/Content/WideLayout 架构与 ZZZ 完全同构（两页面文件仅类名 / import / 标题资源不同）：Hero 负责英雄信息区，Content 负责行迹/光锥/属性/遗器区——可提取共享骨架。原神不同构（Portrait / Landscape / Wide 三种 Layout + `CharDetailHeroPanel`）

### 数据模型差异化 ✅

星铁使用 `StarRailCharDetailSkillNode`（含 `pointType` / `pointId`）和 `StarRailCharDetailRelic`（遗器 `relics` 与饰品 `ornaments` 两个列表共用该模型）区分于原神的圣遗物体系，模型层隔离合理。

---

## 🛡️ 安全审查

| 风险项 | 严重程度 | 位置 | 说明 |
|--------|----------|------|------|
| **JSON 解析异常捕获但 UI 不回退** | ⚠️ **High**（与下方 P0 同一项） | VM `parseRawJson()` L226-229 | catch 仅 Logger.error，viewState 未切换（loadData 随后仍会置 DATA，用户看到脏数据/空白） |
| **异步加载异常兜底** | ✅ | VM `loadData()` L87-106 | try-catch 完整，异常时正确设置 viewState = ERROR + networkErrorMsg。注意：**没有超时控制**，`getAvatarDetail()` 是本地 DB 查询，不计入风险 |
| **window API try-catch 静默吞错** | ℹ️ 信息（不计数） | Page L44 / L48 / L50 / L71 / L73（5 处 `catch (_e) {}`） | 屏幕尺寸监听失败不影响核心功能，属可接受设计；三游戏页面一致按信息处理 |
| **硬编码 entityId 调试代码** | Low | VM `parseRawJson()` L171-179 | `if (this.entityId === '1510')` 下两个只声明局部变量的空循环，无副作用、无日志，属 COMPAT-005 调试残留 |

---

## 🚨 风险清单

### P0 — 必须修复（High）

1. **[High] `parseRawJson` catch 分支（VM L226-229）未设置 viewState = ViewState.ERROR**：catch 只记日志，`loadData()` 随后无条件执行 `this.viewState = ViewState.DATA`（L98-99）。JSON 解析或字段访问抛错时，用户看到的是只填了一部分（或全空）的详情页，且没有任何错误提示（不会停留在 LOADING）。
   - 建议：catch 内 `throw` 交由 `loadData()` 的 catch 统一处理，或直接 `this.viewState = ViewState.ERROR; this.networkErrorMsg = msg;` 并让 `loadData()` 不再覆盖为 DATA。原神 / ZZZ 同源，三游戏统一修。

### P1 — 建议修复（Medium）

2. **[Medium · ARKTS-014] 旧式 `@ohos.*` 导包**：Page L4 `import display from '@ohos.display'`，应改为 `import { display } from '@kit.ArkUI'`（L5 已从 `@kit.ArkUI` 导入 `window`）。原神 / ZZZ 角色详情与三个 DailyDetail 页同样如此。

### P2 — 可优化（Low）

3. **[Low · COMPAT-005] 硬编码 entityId 调试残留（VM L171-179）**：`if (this.entityId === '1510')` 下两个循环体只有 `const s = ...`，无任何副作用。不影响功能，属发版前应清理的调试代码。
   - 建议：移除该 if 块及内部空循环。

4. **[Low] Monitor 路径常量已定义但未使用**：VM L32/L34 导出 `STARRAIL_CHAR_DETAIL_VM_VIEW_STATE` / `STARRAIL_CHAR_DETAIL_VM_ERROR`，全工程无引用，Page L55 直接写字符串 `'vm.networkErrorMsg'`。原神（`GenshinCharacterDetailViewModel.ets:34/36` vs `GenshinCharacterDetailPage.ets:61`）与 ZZZ 同样未使用，三游戏同级处理。
   - 建议：Page 改用常量，或删除未用常量；二选一统一。

5. **[Low] `StarRailCharDetailWideLayout` 左栏无 Scroll**：右栏（光锥 + 属性 + 遗器）已包在 `Scroll` 里（`StarRailCharDetailWideLayout.ets:34-51`），但左栏 `Column`（Hero 固定 260 + 行迹区，L23-31）`.height(full)` 且无滚动；窗口高度不足时行迹区底部会被裁切。建议确认设计意图。

6. **[Low] `heroHeight()`（Page L76-80）未使用 `@Computed`**：每次 build 重新计算 `this.windowWidthVp <= this.windowHeightVp`，开销极小，属可选优化。

7. **[Low] 初始尺寸取整屏而非窗口**：`aboutToAppear` 用 `display.getDefaultDisplaySync()`（L41-43）初始化 `windowWidthVp/HeightVp`，而 `windowSizeChange`（L48）只在尺寸**变化**时回调。分屏 / 悬浮窗进入页面时，`heroHeight()` 的横竖判断基于整屏宽高，直到窗口尺寸再次变化。三游戏同源。

8. **[Low] 遗器 / 饰品按数组下标排布、不按 `pos`**：`StarRailRelicsSection.ets:31-57` 用 `relics[startIdx]` 顺序填格，占位名用 `relicPosName(startIdx + 1)`；VM 虽解析了 `pos`（VM L234），渲染时未使用。部位未穿齐时（例如只穿了躯干 / 脚部），卡片会落在"头部 / 手部"格，占位标签与实际缺失部位不符。原神按 `pos` 查找（`CharDetailRelicsPanel.ets:64-76`、`CharDetailRelicPair.ets:28-41`），不受影响；ZZZ 驱动盘同样按下标排布。

---

## 重构执行备注（M10 · StarRail CharacterDetail）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `custom_router_map.json:29-31`：`StarRailCharacterDetail` → `pages/StarRailCharacterDetailPage.ets` + `StarRailCharacterDetailBuilder`（路由配置保留旧路径），**页面路径与 Builder 名冻结** |
| 路由参数 | `CharDetailRouterParam`（`model/CharDetailModels.ets`，272 行，目录为单数 `model/`）三游戏共享，字段名不改 |
| 测试 | `StarRailCharacterDetailViewModel` **没有** Local Test；M10 只有 Genshin 版有测试 |
| 共享组件 | `views/common/` 9 个文件不移动；其中本页经子组件引用 6 个（Loading / Empty / ConsColumn / HeroNameOverlay / SectionLabel / RelicPlaceholder），另 3 个（SkillItem / StatRow / MaterialCalcEntry）只被原神使用。M10 新增 `CharDetailHeroScaffold` 供星铁 / 绝区零英雄区共用 |
| 游戏组件 | `views/starrail/` 11 个文件，仅本页使用 |

### 重构范围（已执行）

- 页面/目录已符合 N-4；**没有必须的目录移动**。
- 新增 `utils/CharDetailWindowSize.ets`（56L）：三游戏共用窗口尺寸监听与断点计算；页面 140 → 116 行。
- 新增 `views/common/CharDetailHeroScaffold.ets`（99L）：星铁 / 绝区零英雄区共用骨架（背景渐变、立绘、遮罩、命座纵列、名字叠加层），游戏差异通过 `imageUrl` / `strongOverlay` / `midOverlay` / `@BuilderParam infoContent` 注入；`StarRailCharDetailHero` 101 → 48 行。
- `@ohos.display` → `@kit.ArkUI` 是等价导包替换（ARKTS-014）。
- `StarRailCharacterDetailViewModel` 合并 3 条 `from 'core'` 导入，删除未使用的 `StarRailPropertyType` / `StarRailRawSkillNode` 导入；删除 `entityId === '1510'` 空循环（无行为变化）。
- `parseRawJson` 的 ERROR 兜底是行为修复，未随本提交执行（记录为 High，单独提交）。
- 不合并 `starrail/` 的 11 个组件到 common（行迹 / 遗器模型是游戏特定的）。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. 无 Local Test：冒烟——星铁角色详情窄屏/宽屏、行迹/遗器/属性、返回、错误态（构造解析失败数据）。

### 验收记录

| 项 | 结果 |
|---|---|
| 编译（uat/Debug） | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 14s 775ms`，安装/启动成功 |
| codeLinter | ⚠️ 项目未配置 codeLinter task，跳过 |
| Local Test | 🔶 无测试 |
| 测试契约 | ✅ 路由 / Builder 名未变 |
| 冒烟 | 🔶 待手动：窄屏/宽屏、行迹/遗器/属性、返回、错误态 |

### 已知问题归属

- High（`parseRawJson` 未设 ERROR）：保留，行为修复需单独提交（三游戏统一）。
- Medium（ARKTS-014 `@ohos.display` 导包）：✅ 已在本轮改为 `@kit.ArkUI`。
- Low（`entityId === '1510'` 残留）：✅ 已删除。
- Low（宽屏左栏无 Scroll、heroHeight 未缓存、初始尺寸取整屏、遗器不按 pos 排布）：记录。

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | §2 文件清单、子组件 11 文件、L55 Monitor、L112-118 onAreaChange | ✅ |
| 第 2 轮（关键代码段） | L172-179 entityId、L224-230 parseRawJson catch、§7 测试/重构声明 | ✅ |
| 第 3 轮（全面复核） | 总计 686 / 子组件行数总和 / 路径常量 / 问题优先级归属 | ✅ |
| 第 4 轮（2026-10-27 逐条复核） | 全部锚点逐行对照；common 引用关系（原文误列 MaterialCalcEntry / StatRow、漏 HeroNameOverlay）；`1510`、Monitor 常量改判 Low；补 ARKTS-014、宽屏左栏、初始尺寸、遗器排布 | 已修正 |
| 第 5 轮（2026-11-05 M10 真重构后） | 页面 140 → 116L；VM 256 → 239L；Hero 101 → 48L；新增 `CharDetailWindowSize` 56L 与 `CharDetailHeroScaffold` 99L；删除 `1510` 空循环与未使用导入；`bash run.sh uat` → BUILD SUCCESSFUL in 14s 775ms | ✅ 编译通过；路由 / Builder 名未变 |
