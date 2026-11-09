# entry Module 组件拆分分析总索引

> **用途：** entry module（不含 core/）的全局视角追踪哪些 Page / Component 需要拆分重构，指向各自的深度子文档。  
> 子文档格式：`docs/<module>-module-analysis.md`，内含现状、问题编号、拆分方案、优劣对比、执行步骤。

---

## 一、项目文件规模总览（entry module）

### 1.1 文件结构统计

| 类别 | 文件数 | 行数范围 | 备注 |
|------|--------|----------|------|
| **正常 Page** | 4 | 33–277 | `entry/src/main/ets/pages/` |
| **Widget Page** | 6 | 82–113 | `entry/src/main/ets/widget/pages/`，运行在 `FormExtensionAbility` 中 |
| **Widget View** | 10 | 53–337 | `entry/src/main/ets/widget/views/`，Widget 专用子组件 |
| **ViewModel** | 4 | 80–162 | `entry/src/main/ets/widget/viewmodel/`，Widget 数据层 |
| **Ability** | 4 | 16–270 | `EntryAbility` / `WidgetSyncAbility` 等，不纳入拆分 |
| **Utils** | 2 | 21–26 | 纯工具类，不纳入拆分 |

### 1.2 Normal Page 复杂度分布

```
                >100行    50-100行     <50行
超大 (Top)              2             -          -
中大型                  -             -          -
小型                    -             -          1
```

| 优先级 | 文件 | 行数 | 备注 |
|--------|------|------|------|
| ✅ P0 | `MainPage.ets` | **277**（原 478） | 应用主框架 + 跨 Tab 事件分发；M15 二次拆分已完成 |
| 🟡 P1 | `TestPage.ets` | 105 | 测试页面（>100 行，也应拆分） |
| 🟢 P2 | `LaunchPage.ets` | 91 | 启动页 |
| 🔵 P3 | `Index.ets` | 33 | 入口过渡页 |

### 1.3 Widget 复杂度分布

```
               >250行    100-250行    50-100行     <50行
Widget Page               -              3            3          -
Widget View               2              2            6          -
```

| 优先级 | 文件 | 行数 | 备注 |
|--------|------|------|------|
| 🔴 W-V1 | `Widget4x4SingleGame.ets` | **337** | Widget 最大 View，单游戏展示 |
| 🔴 W-V2 | `Widget2x4SingleGame.ets` | **282** | Widget 中视图，单游戏展示 |
| 🟡 W-V3 | `Widget1x2ContentView.ets` | 121 | 小视图内容容器 |
| 🟢 W-Pages | ×6 Widget Pages | 82–113 | 各尺寸入口页（见下方详细列表） |

---

## 二、为什么要拆分 ArkTS 组件

### 正常 Page / Component

1. **可读性**：build() > 100 行时上下滚动多次才能理解布局；拆分子组件后职责单一。
2. **可维护性**：混在一起的 UI 修改容易误伤；拆分后改一处不影响其他。
3. **编译性能**：ArkUI 差分编译以组件为粒度；独立组件状态变更不触发兄弟重绘。
4. **Code Review**：Review 一个 50 行子组件比 Review 300 行大 Page 快得多。

### Widget Component ⚠️ 特殊约束

> **重要区别：** Widget Component 运行在独立的 `FormExtensionAbility` 中，与正常 Page / Component 有本质不同：
>
> - **渲染环境隔离**：Widget 在桌面宿主（home screen）中由系统渲染服务独立渲染，每个 Widget 维度对应一个独立的渲染实例。
> - **内存模型特殊**：静态卡片渲染完成后释放所有运行资源；动态卡片支持自定义交互但消耗更多内存。
> - **事件传递有限制**：Widget 不能使用常规点击事件（onClick），需通过 `FormLink` + `abilityName` + `params` 将用户操作传递给主应用的 `EntryAbility.onNewWant()` 处理。
> - **模块导入限制**：HAR 可导入，但 **HSP 不可导入**；不能加载主应用中的某些运行时模块（会导致 JS crash）。
> - **不支持调试特性**：无 Instant Preview / Breakpoint Debugging / Hot Reload。
> - **数据更新模型不同**：Widget 数据变更通过 proxy push 或主动刷新，不是直接的 UI re-render。

**结论：** Widget Component 的拆分策略与正常 Page 完全不同——需要单独分析、单独规划。**不可将 Widget 拆出来的子组件直接复用为 Normal Page 组件。**

---

## 三、拆分原则与规则

### 3.1 核心原则（Normal Page）

| 原则 | 说明 |
|------|------|
| **单职责** | 每个子组件只负责一个 UI 块渲染 |
| **按需拆分** | 简单的 `Row() { Text + Icon }` 不需要单独建文件 |
| **最小改动** | 先从 Top 超大 Page 开始，不急于改动小页面 |
| **一致命名** | 子组件统一放在对应 `views/` 目录下，命名 `UpperCamelCase` |

### 3.2 Widget Component 拆分原则 ⚠️

| 原则 | 说明 |
|------|------|
| **隔离优先** | Widget 拆出的子组件不用于 Normal Page，反之亦然（除非明确可复用） |
| **数据模型共享评估** | ViewModel 可以提取为 HAR 供多尺寸 Widget 共享，但 UI View 保持独立 |
| **尺寸适配** | Widget 按渲染尺寸（1x2/2x2/2x4/4x4）各有专属 Page + 可能各有一套 View |

### 3.3 拆分触发条件（Normal Page）

满足任一即可考虑拆分：
1. build() 内某段 UI 逻辑 **超过 30 行**
2. 同一块 UI 逻辑在多个页面或模块中 **出现 ≥ 2 次**
3. 该段 UI 逻辑有独立的 **交互状态**（如展开/折叠、选中态切换）

---

## 四、优先级 Do List — Normal Page

### Phase 0 — 已完成拆分（已验收）

| # | 文件 | 原始行 → 现在 | 拆分内容 | 验证 |
|---|------|-------------|----------|------|
| ✅ M7-1 | `CharacterSelectCard.ets` | 内联 → 独立 (156行) | MaterialCharacterSelectPage 角色卡片提取 | ✅ 编译 + 冒烟通过 |
| ✅ M7-2 | `LevelConfigRow.ets` | 4份内联 → 共享 (76行) | TargetConfig ×3 等级行统一为子组件 | ✅ 三游戏回归通过 |
| ✅ M7-3 | `TargetConfigTipCard.ets` | 内联 → 独立 (32行) | TargetConfig ×3 顶部提示卡片提取 | ✅ 已验收 |

### Phase 1 — Top Page（核心）

#### ✅ P0: `MainPage.ets` (478 → 277 行) — 已完成

| 维度 | 详情 |
|------|------|
| **角色** | 应用主框架：Navigation + TabBar + 跨 Tab 全局事件分发（极验/Cookie 过期/设备指纹） |
| **核心问题** | 约 ~180 行事件调度逻辑与 UI 混在一个 @ComponentV2 中，Page 职责不清 |
| **拆分方向** | 实际拆为三个文件：`MainPageBuilders.ets`（@Builder 外置）、`utils/MainDialogArbiter.ets`（弹窗仲裁）、`utils/MainMenuItems.ets`（标题栏菜单与 Tab 项） |
| **实际效果** | Page 478 → 277 行；新增 12 + 214 + 80 行三个职责单一文件 |
| **子文档** | [`main-module-analysis.md`](./main-module-analysis.md)（整体评级 B，2 High / 11 Medium / 5 Low；M15 二次拆分记录见 §9） |

### Phase 2 — 中等 Page (80–120 行)

| # | 文件 | 行数 | 优先级 | 拆分方向 | 子文档 |
|---|------|------|--------|----------|--------|
| 🟡 P1-1 | `TestPage.ets` | 105 | 🟡 P1 | 测试页面，视业务逻辑复杂度决定 | （暂无） |
| 🟢 P2-1 | `LaunchPage.ets` | 91 | 🟢 P2 | 启动页，简单过渡逻辑 | （暂无） |

### Phase 3 — 入口/过渡 Page (<50 行)

| # | 文件 | 行数 | 优先级 | 备注 |
|---|------|------|--------|------|
| 🔵 P3-1 | `Index.ets` | 33 | 🔵 P3 | 极短，一般不拆分 |

---

## 五、优先级 Do List — Widget Component（单独 Section）

### 5.1 Widget 结构分析

每个 Widget 尺寸配置包含：**1 个 Page + N 个 View**，共 6 个 Widget：

| Widget 尺寸 | Page 文件 | Views (直接 import) | View 嵌套子组件 |
|-------------|-----------|---------------------|-----------------|
| **1x2** (×3游戏共享) | `Widget1x2Genshin.ets` / `Widget1x2StarRail.ets` / `Widget1x2ZZZ.ets` (各 82行) | `Widget1x2ContentView.ets` (121行) + `WidgetEmptyContent.ets` (66行) | ContentView → staminaInfo, gameInfo 等嵌套子组件 |
| **2x2** | `Widget2x2.ets` (109行) | `Widget2x2SingleGame.ets` (99行) + `Widget1x2ContentView.ets` (121行) + `WidgetEmptyContent.ets` (66行) | SingleGame → Header(56), StaminaBlock(53)+ExtraRows(115); StaminaBlock → StandardStamina(70)/StarRailStamina(91) |
| **2x4** | `Widget2x4.ets` (110行) | `Widget2x4SingleGame.ets` (282行) + `Widget2x2SingleGame.ets` (99行) | SingleGame → 内部嵌套多个子组件，不 import 其他 views |
| **4x4** | `Widget4x4.ets` (113行) | `Widget4x4SingleGame.ets` (337行) + `Widget2x4SingleGame.ets` (282行) | SingleGame → 内部嵌套子组件，不 import 其他 views |

### 5.2 Widget View 复杂度 Top

| 优先级 | 文件 | 行数 | Widget 尺寸 | 问题描述 |
|--------|------|------|-------------|----------|
| 🔴 W-V1 | `Widget4x4SingleGame.ets` | **337** | 4x4 | 超大视图，可能需拆分子行 / 子卡片 |
| 🔴 W-V2 | `Widget2x4SingleGame.ets` | **282** | 2x4 | 大视图，同理需拆分 |
| 🟡 W-V3 | `Widget1x2ContentView.ets` | 121 | 1x2 | 中等，可评估是否提取 GameCard / InfoRow |

### 5.3 Widget ViewModel 共享情况

| Viewmodel | 行数 | 用途 | 可复用性 |
|-----------|------|------|----------|
| `Widget1x2ViewModel.ets` | 80 | 小视图数据模型 | — |
| `Widget2x2ViewModel.ets` | 161 | 中视图数据模型 | — |
| `Widget2x4ViewModel.ets` | 162 | 大视图数据模型 | — |
| `Widget4x4ViewModel.ets` | 159 | 最大视图数据模型 | — |

> **注意：** Widget ViewModel 按尺寸分装，但底层数据逻辑（获取角色/体力/材料等）可能大量重复。可评估提取共享 base VM 到 HAR。

### 5.4 Widget 拆分策略建议

鉴于 Widget Component 的特殊性：

1. **Page 层**：1x2 三个游戏版本可能可合并为 `Widget1x2Base.ets`（传入游戏类型参数）
2. **View 层**：
   - `SingleGame` 系列 (2x4/4x4) 结构相似但尺寸差异大，不建议共享——保持独立更简单
   - `StaminaBlock` / `StandardStamina` / `StarRailStamina` 可能可提取通用体力展示组件
3. **ViewModel**：数据获取逻辑高度重复，建议提取公共 base class

---

## 六、汇总表格

| # | 分类 | 文件 | 行数 | 优先级 | 子文档 | 状态 |
|---|------|------|------|--------|--------|------|
| 1 | Normal | MainPage.ets | 478 → 277 | ✅ P0 | `main-module-analysis.md` | ✅ 已完成（M15 二次拆分） |
| 2 | Normal | TestPage.ets | 105 | 🟡 P1 | （暂无） | ⏳ 待分析 |
| 3 | Normal | LaunchPage.ets | 91 | 🟢 P2 | （暂无） | ⏳ 待分析 |
| 4 | Normal | Index.ets | 33 | 🔵 P3 | — | 不拆分 |
| 5 | Widget | Widget4x4SingleGame.ets | 337 | 🔴 W-V1 | （暂无深度子文档） | ⏳ 待分析 |
| 6 | Widget | Widget2x4SingleGame.ets | 282 | 🔴 W-V2 | （暂无深度子文档） | ⏳ 待分析 |
| 7 | Widget | Widget1x2ContentView.ets | 121 | 🟡 W-V3 | （暂无深度子文档） | ⏳ 待分析 |
| 8 | Widget | ×6 Pages (82–113) | — | 🟢 W-Pages | （汇总分析） | ⏳ 待分析 |
| 9 | Widget | ×4 ViewModels (80–162) | — | 🟡 W-VM | （共享评估） | ⏳ 待分析 |

---

## 七、已合并的 features/ Page（不在此总索引中）

> **说明：** `features/*/` 下的 Page（共 25 个）属于 feature module 层级，拆分规划在各自的子文档中进行。本总索引只关注 **entry module**。
> 
> 如需查阅：详见各 feature 模块子文档（见 summary/历史上下文）。

---

## 📎 附录：数据源

- Page 清单来源：`find ./entry/src/main/ets/pages -name '*.ets'` + `find ./entry/src/main/ets/widget/pages -name '*.ets'`
- Widget View 来源：`find ./entry/src/main/ets/widget/views -name '*.ets'`
- Widget ViewModel 来源：`find ./entry/src/main/ets/widget/viewmodel -name '*.ets'`
- Ability 清单来源：`grep -l '@Entry(Ability)' entry/src/main/ets/`
- 更新时间：2026-11-09

【已核对代码一致性】
