# NotificationSettings 模块独立分析文档

> 生成时间：2026-10-24
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）
> 作用 scope：`features/notification/src/main/ets/pages/NotificationSettingsPage.ets` + `NotificationSection`（子组件）+ `NotificationSettingsViewModel` + `features/notification/src/main/ets/views/notification/`（14 个子组件）；服务层见 [notification-service-modules-analysis.md](./notification-service-modules-analysis.md)

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 1 |
| Low | 2 |

**整体评级：A**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + 0 High，Medium ≤ 5）。旧百分制已废弃，原分 78/100 仅作历史参考。原 High「context 为 null」经两轮复核降为 Low：不会崩溃，且 `aboutToAppear` 先于首次 `build()` 执行，实际只有 `getHostContext()` 返回 `undefined` 时才会为 null。2026-10-27 复核补登 1 条 Medium（改阈值 / 一键满值只取消提醒、不重新调度）与 1 条 Low（`@Monitor` 路径未用已导出常量）。

---

## 1. 文件清单

| 文件 | 类型 | 行数 | 职责 |
|------|------|------|------|
| `NotificationSettingsPage.ets` | Page / @ComponentV2 | 40 | 通知设置二级页，委托给 NotificationSection 组件 |
| `components/my/NotificationSection.ets` | Component（子组件，位置待迁移） | 113 | 通知设置页内容（总开关/权限/槽位/样式/账号阈值） |
| `viewmodel/NotificationSettingsViewModel.ets` | ViewModel | 403 | 通知设置数据/动作（被 Section 与多个 notification 子组件引用） |
| `components/notification/`（14 个） | Component | 720 | `NotificationGameRow` 109 · `NotificationAccountBlock` 77 · `NotificationStyleCard` 71 · `NotificationAccountHeader` 56 · `NotificationStyleBPreview` 54 · `NotificationBubbleExpanded` 52 · `NotificationSlotUsage` 47 · `NotificationStyleAPreview` 47 · `NotificationFullValueRow` 46 · `NotificationMasterToggle` 45 · `NotificationBubbleCollapsed` 32 · `NotificationPermissionWarning` 31 · `NotificationBubbleHeader` 30 · `NotificationStyleBLine` 23 |

**直接导入依赖**：`common`, `ThemeManager`, `NotificationSection`（子组件）

## 2. 架构分析（结构树）

```
NotificationSettings (@ComponentV2)
├── @Local tm: ThemeManager
├── @Local abilityContext: UIAbilityContext | null
├── private localStack: NavPathStack | null
├── private uiCtx: UIContext | null
├── aboutToAppear() — 获取 context
└── build()
    └── NavDestination
        └── NotificationSection({ context: abilityContext })
            ├── @Local vm: NotificationSettingsViewModel；aboutToAppear → vm.loadSettings()
            ├── @Monitor('vm.showLimitDialog') → promptAction.showDialog
            ├── NotificationMasterToggle → vm.onToggleEnabled(context, isOn)   → 服务 requestPermission / onDailyNotesSynced / cancelAll
            ├── NotificationPermissionWarning（enabled && permissionDenied）
            ├── NotificationSlotUsage（reminderUsed / reminderLimit）
            ├── NotificationStyleCard ×2 → vm.onStyleChange(style)          → 仅写设置
            └── ForEach accounts → NotificationAccountBlock
                ├── NotificationGameRow → onBlur/onSubmit: vm.onThresholdChange()  → 服务 cancelByAccountGame
                │                         Toggle: vm.onGameToggle()           → 服务 cancelByAccountGame / onDailyNotesSynced
                └── NotificationFullValueRow → vm.onFullValueShortcut()       → 服务 cancelByAccountGame ×N
```

**架构模式**：纯委托型页面（Delegate Pattern），自身无业务逻辑，仅传递 Context 给子组件。

## 3. ArkTS 合规性检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| `@ComponentV2` + `struct` | ✅ 通过 | |
| `aboutToAppear` context 获取 | ⚠️ 注意 | `this.uiCtx.getHostContext()` 实际返回 `UIAbilityContext | undefined`（非 CommonEvent），用 `!== undefined` 判断后强转为 UIAbilityContext；类型安全依赖 runtime |
| `@Local abilityContext: ... | null` | ⚠️ 注意 | 初始化为 null，由 aboutToAppear 填充；`aboutToAppear` 先于首次 `build()`，子组件不会先拿到 null，只有 `getHostContext()` 返回 `undefined` 时才保持 null |
| 路由 Builder 标准封装 | ✅ 通过 | `NotificationSettingsBuilder` 正确封装 |

**ArkTS 结论：存在需关注项**

## 4. 组件复用分析

- **零 UI 代码**：整个页面仅包裹一个子组件，所有业务逻辑在 NotificationSection 中——良好的关注点分离
- 此类"空壳页面"是鸿蒙项目中常见模式（作为路由节点存在），无需进一步拆分

## 5. 安全审查

| 风险 | 级别 | 说明 |
|------|------|------|
| abilityContext 为 null | ⚠️ 低 | 仅 `getHostContext()` 返回 `undefined` 时出现（`NotificationSettingsPage.ets:17-20`）。已核实唯一消费方 `NotificationMasterToggle`（`:30`）有 `if (this.context === null) { return }`，**不会崩溃**；但用户点总开关会静默无响应，无提示/重试 |

**安全结论：通过（存在需关注项）**

## 6. 风险清单

- [x] **中优先级**：修改阈值 / 一键满值后**只取消提醒、不重新调度**。`onThresholdChange()` 保存后调用 `cancelByAccountGame()`，注释写明"下次同步时重新调度"（`viewmodel/NotificationSettingsViewModel.ets:168-169`）；`onFullValueShortcut()` 对该账号每个游戏同样只取消（`:185-186`）。而 `onGameToggle()` 开启时会立即 `onDailyNotesSynced()`（`:143`）。结果是用户改完阈值离开 App，该游戏所有角色的提醒都已被删，直到下次首页同步（冷启动 / 刷新 / 自动刷新定时器）才会重建；期间体力达到新阈值也不会收到通知，页面上的槽位用量也随之下降而无说明。建议改完后与 `onGameToggle` 一样触发一次 `onDailyNotesSynced()`（行为变更，单独提交）
- [x] **低优先级**（原 Medium，降级）：`abilityContext` 可能为 null——`NotificationMasterToggle` 已做空值保护（不崩溃），但会静默吞掉点击；实际只在 `getHostContext()` 返回 `undefined` 时发生。建议拿不到 context 时禁用开关并提示
- [x] **低优先级**：`NotificationSection.ets:27` 的 `@Monitor('vm.showLimitDialog')` 写死路径字符串，而 VM 已导出同值常量 `NOTIFICATION_SETTINGS_VM_SHOW_LIMIT_DIALOG`（`viewmodel/NotificationSettingsViewModel.ets:21`，另一常量 `:22` 同样无人使用），与 Tools 的 `@Monitor` 路径问题同类
- [ ] **信息（不计入 Low）**：此页面只有 40 行空壳，业务逻辑集中在 `NotificationSection`；这是设计选择（薄壳 + 组件承接），**不是缺陷**，保持现状、不拆

*本文档仅分析，不修改代码。*

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | 页面 40 / NotificationSection 113 / VM 403；页面 3 段结构（import L4-6 / 字段 L10-13 / aboutToAppear L15-21 / build L23-32） | ✅ 全部精确匹配 |
| 第 2 轮（路由 + 子组件） | 路由 `custom_router_map.json:24-26`；`AppRoutes.ets:33`；`NotificationMasterToggle.ets:30` 的 `if (this.context === null) { return }`；`NotificationSection` 仅被页面 L6/L25 引用 | ✅ |
| 第 3 轮（全面复核） | VM 实际被 7 个组件 import（NotificationSection + 6 个 notification 子组件）；两份测试分别 import NotificationModels / StaminaThresholdCalculator（互不交叉）；`components/notification/` 下无同名 NotificationSection，迁移无冲突 | ✅ 修正 2 处（测试引用拆分 / VM 引用组件清单） |
| 第 4 轮（2026-10-27 逐条事实 + 遗漏） | 通读 VM 403 行与 14 个组件；`aboutToAppear` 先于 `build()`；VM `:168-169 / :185-186` 只取消不重排；Section `:27` 硬编码 `@Monitor` 路径 | ✅ context-null Medium → Low；新增 Medium（阈值改动不重排）与 Low（`@Monitor` 路径）；补组件清单与结构树；计数 0/0/1/0 → 0/0/1/2，评级 A 不变 |

---

## 重构执行备注（M5 · Notification）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `custom_router_map.json:24-26`：`NotificationSettings` → `pages/NotificationSettingsPage.ets` + `NotificationSettingsBuilder`，**页面路径与 Builder 名冻结** |
| 路由常量 | `AppRoutes.NOTIFICATION_SETTINGS = 'NotificationSettings'` 字符串冻结 |
| 测试引用（冻结） | `notification/NotificationModels.ets` 被 `StaminaNotificationService.test.ets` 导入；`notification/StaminaThresholdCalculator.ets` 被 `StaminaThresholdCalculator.test.ets` 导入。两份测试分别依赖对应文件，**路径/导出符号不得变** |
| 服务层 | `notification/` 的 5 个文件与 widget 存在 3 条扇出边；M5 只做目录整理时不得改服务行为 |
| 组件位置 | `NotificationSection.ets` 当前在 `components/my/`，但只有 `NotificationSettingsPage.ets` 引用它（`MyPage.ets` 不用） |

### 重构范围（建议）

- **唯一值得做的移动**：`components/my/NotificationSection.ets` → `components/notification/NotificationSection.ets`，同步更新 `pages/NotificationSettingsPage.ets:6` 的 import。已确认无其它引用、无测试引用、目标目录无同名文件。
- `NotificationSettingsViewModel` 403 行（< 500），不拆分；它被 `NotificationSection` 与 `notification/` 下 6 个子组件直接 import（`NotificationMasterToggle` / `NotificationStyleCard` / `NotificationAccountBlock` / `NotificationGameRow` / `NotificationSlotUsage` / `NotificationFullValueRow`），路径保持 `viewmodel/`。
- `notification/` 服务目录（`StaminaNotificationService` 691 行等）不在目录级改动范围；涉及行为的修复单独提交。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. DevEco Local Test：`StaminaNotificationService.test.ets`（模型/样式/hash 用例）通过；页面无单测。
3. 冒烟：我的 → 通知设置 → 总开关/权限提示/槽位/样式切换/账号阈值；拒绝通知权限后的提示路径；改阈值后直接退到后台，确认提醒仍按新阈值弹出（Medium 修复后）。

### 已知问题归属

- Medium（改阈值 / 一键满值只取消不重排）：建议随 M5 修，与服务层 M1/M7 的去重修复一起冒烟，但与移动分开提交；否则记录到 Refactor_Spec §11。
- Low（`abilityContext` 为 null 时开关静默无响应，不崩溃）：页面侧禁用态即可，可顺手修。
- Low（`@Monitor` 路径未用常量）：随 `NotificationSection` 迁移一起改为引用常量，零行为变更。
- 结构提示（页面仅 40 行空壳）：保持现状，不拆。
