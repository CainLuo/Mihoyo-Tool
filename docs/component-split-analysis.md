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
| **Widget View** | 17 | 53–152 | `entry/src/main/ets/widget/views/`，Widget 专用子组件 |
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
Widget View               -              7           10          -
```

| 优先级 | 文件 | 行数 | 备注 |
|--------|------|------|------|
| ✅ W-V1 | `Widget4x4SingleGame.ets` | **131**（原 337） | 已拆为 Header / StaminaBlock / ExtraRowsGroup / ExpeditionBlock 四个 V1 子组件 |
| ✅ W-V2 | `Widget2x4SingleGame.ets` | **152**（原 282） | 已拆出 InfoColumn，数据行与派遣头像复用共享组件 |
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
| **2x2** | `Widget2x2.ets` (109行) | `Widget2x2SingleGame.ets` (99行) + `Widget1x2ContentView.ets` (121行) + `WidgetEmptyContent.ets` (66行) | SingleGame → Header(56), StaminaBlock(53)+ExtraRows(108); StaminaBlock → StandardStamina(70)/StarRailStamina(91) |
| **2x4** | `Widget2x4.ets` (110行) | `Widget2x4SingleGame.ets` (152行) + `Widget2x2SingleGame.ets` (99行) | SingleGame → InfoColumn(106) + 共享 DataRow(64) / ExpeditionAvatar(126) |
| **4x4** | `Widget4x4.ets` (113行) | `Widget4x4SingleGame.ets` (131行) + `Widget2x4SingleGame.ets` (152行) | SingleGame → Header(65), StaminaBlock(112), ExtraRowsGroup(63)×2, ExpeditionBlock(64) |

### 5.2 Widget View 复杂度 Top

| 优先级 | 文件 | 行数 | Widget 尺寸 | 问题描述 |
|--------|------|------|-------------|----------|
| ✅ W-V1 | `Widget4x4SingleGame.ets` | **131**（原 337） | 4x4 | 已拆分为 4 个 V1 子组件（Header / StaminaBlock / ExtraRowsGroup / ExpeditionBlock） |
| ✅ W-V2 | `Widget2x4SingleGame.ets` | **152**（原 282） | 2x4 | 已拆出 InfoColumn；数据行 / 派遣头像复用共享组件 |
| ✅ W-V3 | `Widget1x2ContentView.ets` | 121 | 1x2 | 已评估：组件体约 62 行（其余为文件头注释与 import），单一职责、三游戏共用、无重复结构 → **不拆分**（详见 6.1） |

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
   - `SingleGame` 系列 (2x4/4x4) 主体布局差异大，保持独立；但**数据行**与**派遣头像**结构完全一致，已抽为 `WidgetDataRow` / `WidgetExpeditionAvatar` 共享（2026-11-09）
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
| 5 | Widget | Widget4x4SingleGame.ets | 337 → 131 | ✅ W-V1 | （暂无深度子文档） | ✅ 已完成（拆 4 个 V1 子组件） |
| 6 | Widget | Widget2x4SingleGame.ets | 282 → 152 | ✅ W-V2 | （暂无深度子文档） | ✅ 已完成（InfoColumn + 共享组件） |
| 7 | Widget | Widget1x2ContentView.ets | 121 | ✅ W-V3 | （暂无深度子文档） | ✅ 已评估（不拆分，组件体 ~62 行） |
| 8 | Widget | ×6 Pages (82–113) | — | 🟢 W-Pages | （汇总分析） | ⏳ 待分析 |
| 9 | Widget | ×4 ViewModels (80–162) | — | 🟡 W-VM | （共享评估） | ⏳ 待分析 |

### 6.1 执行记录

#### W-V1 `Widget4x4SingleGame.ets`（2026-11-09）

> 纯结构拆分，布局属性与数据来源逐行对应；未改 `WidgetRoleUIState`、ViewModel 与卡片入口 `Widget4x4.ets`。

| 项 | 结果 |
| --- | --- |
| 主文件 | 337 → **131 行** |
| 新增子组件 | `Widget4x4Header.ets`（65）· `Widget4x4StaminaBlock.ets`（112）· `Widget4x4ExtraRowsGroup.ets`（75）· `Widget4x4ExpeditionBlock.ets`（124） |
| 复用 | 区块 2 / 区块 3 原为两段同构代码，合并为一个 `Widget4x4ExtraRowsGroup`，以 `showBottomBorder` 区分分隔线 |
| 保留不变量 | `layoutWeight(1)` 分配（数据行分组与派遣区均分剩余高度）、分隔线条件（分组1 看分组2 是否非空，分组2 看派遣区是否存在）、派遣头像 `memory://` → 网络 URL → 渐变占位三级兜底 |
| 体系 | 全部 `@Component`（V1）+ `@Prop`，与既有 `Widget2x2*` 子组件风格一致；无 HSP 导入、无网络权限依赖 |
| 编译 | ✅ `hvigorw assembleHap -p product=uat -p buildMode=debug` → `BUILD SUCCESSFUL` |
| 安装 | ✅ `bash run.sh uat` 安装/启动成功 |
| 冒烟 | 🔶 模拟器桌面无法通过注入事件进入编辑态，卡片渲染需在真机/桌面手动添加 4×4 卡片确认 |

#### 共享组件 `WidgetDataRow` / `WidgetExpeditionAvatar`（2026-11-09）

> 2×4 与 4×4 存在两处结构完全一致、仅样式参数不同的重复，抽为共享组件；2×2 / 1×2 未改动（`WidgetExtraDataRows` 保持原样）。

| 项 | 结果 |
| --- | --- |
| `WidgetDataRow.ets`（64） | 单行「标签 + 值」，参数 `fontSize` / `labelOpacity` / `valueFontWeight`；替换 2×4 右侧列与 4×4 数据行分组中的两份内联 Row |
| `WidgetExpeditionAvatar.ets`（126） | 单枚派遣头像（三级图片兜底 + 完成遮罩 + 勾勾），参数 `avatarSize`（24 / 32），勾勾尺寸 / 字号 / 描边按尺寸派生；替换 2×4 与 4×4 两份 60+ 行实现 |
| 命名注意 | 属性不能命名为 `size`（与 `CustomComponent.size` 通用属性冲突），改用 `avatarSize` |
| 未合并项 | 体力区块（5 种布局：后备位置 / 有无标签 / 字号 18–40）、标题行（3 种排布）、容器间距——合并会退化为参数爆炸，保留各自实现 |

#### W-V2 `Widget2x4SingleGame.ets`（2026-11-09）

| 项 | 结果 |
| --- | --- |
| 主文件 | 282 → **152 行** |
| 新增子组件 | `Widget2x4InfoColumn.ets`（106）：游戏名 / 角色名 / UID / 体力数值 / 恢复时间 |
| 复用 | 右侧数据行改用 `WidgetDataRow`（`labelOpacity` = `OPACITY_TEXT_FAINT` 0.4）；底部派遣头像改用 `WidgetExpeditionAvatar`（24） |
| 保留不变量 | 左右分栏与 1vp 分隔线（`height('50%')`、`opacity(0.08)`、左右 12）、右侧 `Column({ space: 6 })`、底部 `border-top` 与 `margin({ top: 8 })`、`isInNestedContainer` 时的 padding 切换、`flexShrink(0)` |
| 编译 | ✅ `hvigorw clean assembleHap -p product=uat -p buildMode=debug` → `BUILD SUCCESSFUL`，无本模块新增警告 |
| 安装 | ✅ `bash run.sh uat` 安装/启动成功，hilog 无异常 |
| 冒烟 | 🔶 同 W-V1：桌面卡片渲染待真机确认（2×4 单游戏 / 4×4 多游戏两种用法） |

#### W-V3 `Widget1x2ContentView.ets`（2026-11-11，评估结论：不拆分）

| 项 | 结果 |
| --- | --- |
| 体量构成 | 121 行中，文件头注释 + import 约 25 行，`build()` 组件体约 62 行（其余为属性声明与空行） |
| 结构 | 单个 `Row`：左侧 3vp 游戏色竖条 + 右侧 3 行（游戏名/UID、体力、恢复时间）；无嵌套子区块、无重复片段 |
| 复用面 | 已被 1×2 三张卡（原神 / 星铁 / 绝区零）共用，再拆只会把 62 行切成两半并新增跨文件跳转 |
| 结论 | **不拆分**；后续若要统一 1×2 与 2×2 的体力排版，需先确认字号 18 vs 24 的差异是否要保留 |

#### 预览组件去重（`features/widget/views/preview/`，2026-11-11）

> 预览侧是 V2 体系，无法复用 entry 的 V1 卡片组件，只能在预览内部去重。

| 项 | 结果 |
| --- | --- |
| `PreviewExtraDataRow.ets` | 32 → **63 行**：新增 `fontSize` / `labelOpacity` / `valueFontWeight` / `valueOpacity` 参数（默认值保持 2×2 的 11 / 0.55 / 400 / 0.95）；导出 `PreviewExtraRow` 数据模型，供 2×4 / 4×4 共用 |
| 新增 `PreviewExpeditionAvatar.ets` | **56 行**：渐变占位圆头像 + 可选完成勾勾，`avatarSize`（24 / 32）派生勾勾 10/12、字号 7/8 |
| `Preview2x4SingleGame.ets` | 221 → **194 行**：删除 `@Builder extraRow` / `@Builder expeditionAvatar`；数据行改为 `getExtraRows(gameId)` + `ForEach`，与 4×4 预览同构 |
| `Preview4x4SingleGame.ets` | 241 → **221 行**：删除 `@Builder dataRow` 与本地 `ExtraRow` 类，改用共享 `PreviewExtraRow` |
| 行为不变量 | 三个尺寸的行内容 / 行序 / 字号 / 透明度 / 字重、勾勾位置与尺寸均与改造前逐项一致 |
| 编译 | ✅ `hvigorw assembleHap -p product=uat -p buildMode=debug` → `BUILD SUCCESSFUL` |
| 冒烟 | ✅ 应用内「我的 → Widget 卡片」实测：2×2（3 行数据）、2×4（3 行数据 + 5 头像含 2 勾勾）、4×4（两分组 + 4 头像）渲染与改造前一致 |

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
