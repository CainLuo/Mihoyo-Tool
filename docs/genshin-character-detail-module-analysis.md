# 原神角色详情页模块分析

> 生成时间：2026-10-24 ｜ 审查标准参考：`arkts-rules/SKILL.md`
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 1 |
| Medium | 1 |
| Low | 3 |

**整体评级：B**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + High ≤ 3）。旧百分制已废弃，原分 A 仅作历史参考。
>
> 债务点数 = 1×3 + 1×2 + 3×1 = **8**；页面 154 行，密度 **5.2**/百行。（2026-10-27 复核前为 H1/M1/L2、7 点、4.5：撤回"断点应为 576"Medium（前提不成立）与"VM 依赖 init()"Low（页面总是先 init 再 load）；新增 ARKTS-014 Medium 与 2 条 Low。）

---

## 📂 文件清单

| 类别 | 文件路径 | 行数 | 说明 |
|------|----------|------|------|
| **Page** | `pages/GenshinCharacterDetailPage.ets` | 154 | 角色详情主页面（View） |
| **ViewModel** | `viewmodel/GenshinCharacterDetailViewModel.ets` | 243 | 数据加载 + JSON 解析 + 展示模型构造 |
| **路由参数** | `models/CharDetailModels.ets`（CharDetailRouterParam，L11） | 272 | 通用路由参数 + 展示模型 |
| **状态常量** | `constants/ViewState.ets`（ViewState 枚举） | 18 | 页面四态枚举 |

### 子组件（Genshin 专用，共 26 个）

| 文件 | 职责 |
|------|------|
| `components/chardetail/genshin/CharDetailPortraitLayout.ets` | 竖屏单列布局 |
| `components/chardetail/genshin/CharDetailLandscapeLayout.ets` | 横屏左右分栏 |
| `components/chardetail/genshin/CharDetailWideLayout.ets` | 宽屏三栏布局 |
| `components/chardetail/genshin/CharDetailHeroPanel.ets` | 英雄区面板（3 Preview） |
| `components/chardetail/genshin/CharDetailPortraitWeaponSection.ets` | 竖屏武器区 |
| `components/chardetail/genshin/CharDetailPortraitSkillsSection.ets` | 竖屏技能区 |
| `components/chardetail/genshin/CharDetailPortraitStatsSection.ets` | 竖屏属性区（Grid/List） |
| `components/chardetail/genshin/CharDetailPortraitRelicsSection.ets` | 竖屏圣遗物区 |
| `components/chardetail/genshin/CharDetailStatsPanel.ets` | 宽/横屏统计面板 |
| `components/chardetail/genshin/CharDetailRelicsPanel.ets` | 宽/横屏圣遗物面板 |
| `components/chardetail/genshin/CharDetailWeaponCard.ets` | 武器卡片 |
| `components/chardetail/genshin/CharDetailPortraitWeaponCard.ets` | 竖屏武器卡片 |
| `components/chardetail/genshin/CharDetailRelicCard.ets` | 圣遗物卡片 |
| `components/chardetail/genshin/CharDetailRelicRow.ets` | 圣遗物行展示 |
| `components/chardetail/genshin/CharDetailLandscapeSkillItem.ets` | 横屏技能项 |
| `components/chardetail/genshin/CharDetailPortraitSkillItem.ets` | 竖屏技能项 |
| `components/chardetail/genshin/CharDetailHeroPanelPortrait.ets` / `CharDetailHeroPanelLandscape.ets` / `CharDetailHeroPanelWide.ets` | 英雄区响应式子面板 |
| `components/chardetail/genshin/CharDetailSkillsColumn.ets` | 宽屏技能列（被 `CharDetailHeroPanelWide` 使用） |
| `components/chardetail/genshin/CharDetailLevelAndFetterRow.ets` | 等级/羁绊行 |
| `components/chardetail/genshin/CharDetailHeroInfoOverlay.ets` | 立绘区左下角信息叠加层（Portrait / Landscape 英雄面板使用） |
| `components/chardetail/genshin/CharDetailRelicPair.ets` | 圣遗物配对展示 |
| `components/chardetail/genshin/CharDetailStatsGrid.ets` | 网格化属性展示 |
| `components/chardetail/genshin/CharDetailStatsList.ets` | 列表化属性展示 |
| `components/chardetail/genshin/CharDetailWeaponRow.ets` | 武器行展示 |

### Common 共享组件（被本模块引用）

| 文件 | 职责 |
|------|------|
| `common/CharDetailLoadingView.ets` | 加载中骨架屏 |
| `common/CharDetailEmptyView.ets` | 空态占位页 |
| `common/CharDetailSkillItem.ets` | 通用技能项 |
| `common/CharDetailConsColumn.ets` | 命座列（三个游戏共用） |
| `common/CharDetailMaterialCalcEntry.ets` | 材料计算入口按钮 |
| `common/CharDetailSectionLabel.ets` | 区块标题标签 |
| `common/CharDetailStatRow.ets` | 属性行组件 |
| `common/CharDetailRelicPlaceholder.ets` | 圣遗物空卡占位 |

> `common/` 共 9 个文件，本模块引用以上 8 个；第 9 个 `CharDetailHeroNameOverlay.ets` 只被星铁 / ZZZ 的 Hero 组件引用，原神英雄区用自己的 `CharDetailHeroInfoOverlay`。

---

## 🏗️ 架构分析

### 数据流

```
DB → GenshinRepository.getAvatarDetail() → rawJson（JSON 字符串）
  ↓
GenshinCharacterDetailViewModel.parseRawJson(rawJson)
  ↓ (private 实例方法 + buildStats()，写入 @ObservedV2 VM 的 @Trace 字段)
展示模型实例：CharDetailWeapon / CharDetailRelic / CharDetailSkill / CharDetailStat 等
  ↓ (@Param vm: ViewModel)
各 Layout → Section → Card 组件树（链式传入）
```

### 布局策略

**四档断点 + xs 内横竖屏检测：**

| 条件 | Breakpoint | 布局 |
|------|-----------|------|
| `width < 600` | `xs` | `CharDetailPortraitLayout` / `CharDetailLandscapeLayout`（通过 `isPhoneLandscape()` 判断） |
| `600 ≤ width < 840` | `sm` | `CharDetailWideLayout` |
| `840 ≤ width < 1200` | `md` | `CharDetailWideLayout` |
| `width ≥ 1200` | `lg` | `CharDetailWideLayout` |

判断逻辑见 `GenshinCharacterDetailPage.ets:112-118`（竖/横屏布局决策，使用 `isPhonePortrait()` / `isPhoneLandscape()`，L82-88）与 `onAreaChange`(L125-131) 共同实现。注意 `isPhoneLandscape()` 要求 `xs`（宽 < 600vp）：常见手机横屏宽度超过 600vp，实际会走 `CharDetailWideLayout`，`CharDetailLandscapeLayout` 主要在窄窗口（分屏等）下出现。

> 与星铁 / ZZZ 的差异：原神 `sm`（600-840）已进入宽屏布局，星铁 / ZZZ 要到 `md`（≥ 840）才进入；三页断点阈值相同、布局切换点不同。

### 状态管理

- **ViewModel**：`@ObservedV2` 类 + 全部展示属性标注 `@Trace`
- **页面层**：`@Local vm`、`@Local tm`、`@Local windowWidthVp`、`@Local windowHeightVp`、`@Local currentBreakpoint`
- **错误反馈**：`@Monitor('vm.networkErrorMsg')` 监听非空后调用 `showFeedback()`

### 生命周期与资源管理

```typescript
aboutToAppear() { // Line 43
  window.getLastWindow(ctx.getHostContext(), (err, win) => {
    win.on('windowSizeChange', this.sizeCallback) // 注册窗口尺寸变化回调
  })
}

aboutToDisappear() { // Line 71
  win.off('windowSizeChange', this.sizeCallback) // 注销（try-catch 包裹）
}
```

---

## ✅ ArkTS 合规性检查

| 规则 | 状态 | 说明 |
|------|------|------|
| **使用 `@ComponentV2`** | ✅ | Page + 全部 Layout/Section/Card 组件均标注 |
| **ViewModel 用 `@ObservedV2` + `@Trace`** | ✅ | GenshinCharacterDetailViewModel 第 40-69 行 |
| **路由参数使用 `@Param`** | ✅ | Line 25: `@Param routerParam: GenshinCharacterDetailParam` |
| **Local 状态使用 `@Local`** | ✅ | vm/tm/breakpoint/尺寸等 |
| **禁止字符串字面量枚举** | ✅ | `ViewState.LOADING` / `.EMPTY` / `.DATA` / `.ERROR` |
| **Monitor 路径为顶层 const** | ⚠️ | VM L34/L36 导出 `GENSHIN_CHAR_DETAIL_VM_VIEW_STATE` / `GENSHIN_CHAR_DETAIL_VM_ERROR`，全工程无引用；Page `@Monitor('vm.networkErrorMsg')`（L61）直接写字符串（星铁 / ZZZ 同样如此） |
| **ARKTS-014 import 走 `@kit.*`** | ⚠️ | Line 4: `import display from '@ohos.display'` 为旧式导包（Line 5 已用 `@kit.ArkUI`） |
| **@Watch/@Monitor 路径字符串与声明一致** | ✅ | Line 61: `@Monitor('vm.networkErrorMsg')` 对应 `networkErrorMsg` 属性声明 |
| **Resource 类型安全引用** | ✅ | `genshinPropertyTypeToResource()` 返回 `Resource \| null`（`utils/GenshinPropertyUtil.ets:56`），模型字段 `subLabel` / `mainStatLabel` / `label` 均声明为 `Resource \| null`（`CharDetailModels.ets:53/60/71`） |
| **NavDestination 配置** | ✅ | `.title($r('app.string.char_detail_title'))` + `.hideTitleBar(false)` |
| **SafeArea 扩展** | ✅ | Line 124: `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])` |
| **Preview 注解** | ✅ | Page 有 `@Preview`（L141-147）；genshin 子组件中 7 个文件带 Preview（HeroPanel ×3、StatsPanel ×2、RelicsPanel ×2、HeroPanelPortrait / Landscape / Wide、SkillsColumn 各 1） |

---

## 🔄 组件复用分析

### 通用层（3 游戏共享）

- `CharDetailLoadingView` / `CharDetailEmptyView` — 三个详情页共用
- `CharDetailConsColumn` — 命座列，用于原神/星铁/绝区零的命座展示
- `CharDetailSectionLabel` / `CharDetailRelicPlaceholder` — 三游戏共用
- `CharDetailMaterialCalcEntry` / `CharDetailStatRow` / `CharDetailSkillItem` — 位于 common 但**只有原神使用**；`CharDetailMaterialCalcEntry` 的 `gameId` 参数声明了却未在组件内读取（`CharDetailMaterialCalcEntry.ets:12`），并不区分游戏

### 跨游戏复用机会

- **当前**：原神专用组件前缀为 `CharDetailPortrait*`、`CharDetailLandscape*` 等，无统一 Game-agnostic 前缀（例如 `CharDetailHeroPanel` 通过 `mode` 参数区分，是一个好的复用例）
- **StarRail/ZZZ** 各自有独立子组件目录，复用关系需后续评估

### 英雄面板模式化设计 ✅

`CharDetailHeroPanel` 接收 `HeroPanelMode.PORTRAIT / LANDSCAPE / WIDE` 枚举参数，内部切换不同布局——此设计可被其他游戏复用。

---

## 🛡️ 安全审查

| 风险项 | 严重程度 | 位置 | 说明 |
|--------|----------|------|------|
| **异步加载未做超时控制** | ℹ️ 信息（不计数） | VM `loadData()` L81-97 | `getAvatarDetail()` 是本地 DB 查询（core `GenshinRepository.getAvatarDetail`），无 timeout；异常已由 catch 置 ERROR。三游戏一致，不计入风险 |
| **JSON 解析异常捕获但 UI 不回退** | ⚠️ **High**（与下方 P0 同一项） | VM `parseRawJson()` L202-205 | catch 仅 Logger.error，viewState 未切换；`loadData()` 随后仍置 DATA（L89-90），用户看到部分填充 / 空白的详情页 |
| **window API try-catch 静默吞错** | ℹ️ 信息（不计数） | Page L50 / L54 / L56 / L77 / L79（5 处 `catch (_e) {}`） | 屏幕尺寸监听失败不影响核心功能，属可接受设计；三游戏页面一致按信息处理 |

---

## 🚨 风险清单

### P0 — 必须修复（High）

1. **[High] `parseRawJson` catch 分支（L202-205）未设置 viewState = ViewState.ERROR**：catch 只记日志，`loadData()` 随后无条件置 `DATA`（L89-90）。`const base = parsed.base; base.name`（L102-103）在 `base` 缺失时即抛 TypeError，此时页面显示全空的详情（不会停留在 LOADING），且不会弹出错误提示。
   - 建议：catch 内 `throw` 交由 `loadData()` 统一处理，或设 `this.viewState = ViewState.ERROR; this.networkErrorMsg = msg;` 并让 `loadData()` 不再覆盖为 DATA。星铁 / ZZZ 同源，三游戏统一修。

### P1 — 建议修复（Medium）

2. **[Medium · ARKTS-014] 旧式 `@ohos.*` 导包**：Page L4 `import display from '@ohos.display'`，应改为 `import { display } from '@kit.ArkUI'`。星铁 / ZZZ 角色详情与三个 DailyDetail 页同样如此。

### P2 — 可优化（Low）

3. **[Low] 宽屏右栏圣遗物无 Scroll**：`CharDetailWideLayout` 中栏的属性列表已在 `CharDetailStatsPanel` 内包了 `Scroll`（`CharDetailStatsPanel.ets:71-77`），但右栏 `CharDetailRelicsPanel` 宽屏分支是 5 行 `CharDetailRelicRow`（各 `layoutWeight(1)`）等分 `.height(full)`，无滚动（`CharDetailRelicsPanel.ets:105-116`）。由于手机横屏通常宽于 600vp 也会进入宽屏布局，可用高度较小时每行会被压缩。
   - 确认是否为设计意图（固定 5 行等分）。

4. **[Low] Monitor 路径常量已定义但未使用**：VM L34/L36 导出的两个常量全工程无引用，Page L61 直接写字符串。星铁 / ZZZ 同级处理。
   - 建议：Page 改用常量，或删除未用常量；二选一统一。

5. **[Low] 初始尺寸取整屏而非窗口**：`aboutToAppear` 用 `display.getDefaultDisplaySync()`（L47-49）初始化 `windowWidthVp/HeightVp`，`windowSizeChange`（L54）只在尺寸**变化**时回调。分屏 / 悬浮窗进入页面时，`isPhonePortrait()` / `isPhoneLandscape()`（L82-88）基于整屏宽高判断，窄屏下可能选错竖 / 横布局，直到窗口尺寸再次变化。三游戏同源（星铁 / ZZZ 只影响英雄区高度）。

> 2026-10-27 撤回两条：①"断点 600/840/1200 应改为鸿蒙推荐 576/840/1200"——鸿蒙栅格断点为 320/600/840（576 不是鸿蒙推荐值），前提不成立；② "VM 依赖 `init()` 手动调用可能加载脏数据"——Page 总是先 `init()`（L57）再 `loadData()`（L58），即使参数为空也只会查不到行而进入 EMPTY，不会产生脏数据。

---

## 重构执行备注（M10 · Genshin CharacterDetail）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `custom_router_map.json:9-11`：`GenshinCharacterDetail` → `pages/GenshinCharacterDetailPage.ets` + `GenshinCharacterDetailBuilder`，**页面路径与 Builder 名冻结** |
| 跨模块类型 | `pages/GenshinCharacterDetailPage.ets:18` 从 `pages/MaterialCalc` 导入 `MaterialCalcParam` 并 push 材料计算页（L95-100）；两个页面路径互相依赖，都不能随意改 |
| 路由参数别名 | `export type GenshinCharacterDetailParam = CharDetailRouterParam`（L21），仅本页使用；保持导出名不变 |
| 测试引用（冻结） | `viewmodel/GenshinCharacterDetailViewModel.ets`、`constants/ViewState.ets` 被 `entry/src/test/GenshinCharacterDetailViewModel.test.ets` 导入 |
| 共享组件 | `components/chardetail/common/` 9 个文件不移动；本页引用其中 8 个（Loading / Empty / ConsColumn / MaterialCalcEntry / SectionLabel / StatRow / SkillItem / RelicPlaceholder），其中 MaterialCalcEntry / StatRow / SkillItem 只有原神使用 |
| 游戏组件 | `components/chardetail/genshin/` 26 个文件，仅本页使用；响应式 HeroPanel 三分支不要合并 |

### 重构范围（建议）

- 页面/组件已按 common + genshin 分组；**M10 没有必须的目录移动**。
- `CharDetailHeroPanel` 的 PORTRAIT / LANDSCAPE / WIDE 三分支已经参数化；不要为了去重把 26 个文件合并成少数大文件（会改变组件树）。
- `parseRawJson` 的 ERROR 兜底是行为修复，必须与目录调整分开提交（且会影响三游戏一致性）。
- `MaterialCalcParam` / `MaterialCalc` 页保持原位（M7 已冻结）。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. DevEco Local Test：`GenshinCharacterDetailViewModel.test.ets`（90 行）通过。**前提**：该测试当前引用了 VM 上不存在的成员——静态方法 `GenshinCharacterDetailViewModel.propertyTypeToResource`（test L58/63/68/73/79，已迁到 `utils/GenshinPropertyUtil.ets`）与 `GenshinCharacterDetailViewModel.KEYS`（test L86），且 `vm.init(1, ...)`（test L51）传 number，编译不过。按 README §1.4 属测试资产问题，不计入本页评级，但需先修测试才能用作验收。
3. 冒烟：角色详情竖屏/横屏/宽屏三断点、返回、材料计算入口、错误态；窄屏旋转不残留 window 监听。

### 已知问题归属

- High（`parseRawJson` 未设 ERROR）：建议随 M10 修，单独提交。
- Medium（ARKTS-014 `@ohos.display` 导包）：等价替换，可顺手改。
- Low（宽屏圣遗物栏无 Scroll、Monitor 常量未使用、初始尺寸取整屏）：Monitor 常量建议顺手清理，其余记录。

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | §2 Page/VM/子组件 26 文件/1847 行、L61 Monitor、L40-69 @ObservedV2+@Trace | ✅ |
| 第 2 轮（关键代码段） | L43 aboutToAppear、L71 aboutToDisappear、L202-205 parseRawJson catch、L18/L95 MaterialCalcParam | ✅ |
| 第 3 轮（全面复核） | §7 测试文件 90 行、路由映射 L9-11、重构范围/验收声明 | ✅ |
| 第 4 轮（2026-10-27 逐条复核） | 安全表 parseRawJson 由"中"统一为 High；撤回断点 576 Medium 与 init() Low；Monitor 常量实际存在且未使用；common 引用关系与 `gameId` 未使用；测试文件引用失效成员；补 ARKTS-014、初始尺寸 Low | 已修正 |
