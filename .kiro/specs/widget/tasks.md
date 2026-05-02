# Widget 实现任务列表

版本：V1.1.0
状态：待开始

---

## 阶段一：基础设施

### T01 — 创建 form_config.json

- 在 `entry/src/main/resources/base/profile/` 下创建 `form_config.json`
- 配置 6 个卡片模板（widget_1x2_genshin / starrail / zzz / 2x2 / 2x4 / 4x4）
- 在 `module.json5` 的 `extensionAbilities` 中注册 `EntryFormAbility`
- 添加多语言字符串（卡片显示名称）

### T02 — 实现 WidgetFormIdStore

- 创建 `entry/src/main/ets/widget/utils/WidgetFormIdStore.ets`
- 实现 save / remove / getConfig / getFormIdsByAccount / getAllFormIds
- 使用 Preferences 持久化存储

**测试任务 T02-test**：在 `entry/src/test/` 下补充 `WidgetFormIdStore.test.ets`，覆盖 save/remove/getConfig 逻辑

### T03 — 实现 WidgetDataBuilder

- 创建 `entry/src/main/ets/widget/utils/WidgetDataBuilder.ets`
- 实现 `buildPayload(formId, config)` — 从 DB 读取数据，构建 FormBindingData
- 实现 `buildAndPushForAccount(accountId)` — 遍历 formId 推送
- 注意：不能 import StaminaNotificationService

**测试任务 T03-test**：在 `entry/src/test/` 下补充 `WidgetDataBuilder.test.ets`，注入 MockService 验证数据构建逻辑

### T04 — 实现 EntryFormAbility

- 创建 `entry/src/main/ets/entryformability/EntryFormAbility.ets`
- 实现 `onAddForm`：读取 accountId/selectedGames，存 Preferences，立即推送初始数据
- 实现 `onUpdateForm`：调用 WidgetDataBuilder 推送最新数据
- 实现 `onRemoveForm`：删除 Preferences 中的 formId
- 实现 `onFormEvent`：处理卡片内刷新按钮的 message 事件

---

## 阶段二：卡片 UI

### T05 — 实现 Widget1x2Genshin

- 创建 `entry/src/main/ets/widget/pages/Widget1x2Genshin.ets`
- 显示：UID + 体力环 + 原粹树脂数值/上限 + 回满时间
- 体力满时数值变红

**测试任务 T05-test**：文件末尾添加 `@Preview`，覆盖空态、有数据、体力满三种状态

### T06 — 实现 Widget1x2StarRail

- 创建 `entry/src/main/ets/widget/pages/Widget1x2StarRail.ets`
- 显示：UID + 体力环 + 开拓力数值/上限 + 后备开拓力 + 回满时间

**测试任务 T06-test**：文件末尾添加 `@Preview`

### T07 — 实现 Widget1x2ZZZ

- 创建 `entry/src/main/ets/widget/pages/Widget1x2ZZZ.ets`
- 显示：UID + 体力环 + 电量数值/上限 + 回满时间

**测试任务 T07-test**：文件末尾添加 `@Preview`

### T08 — 实现 Widget2x2

- 创建 `entry/src/main/ets/widget/pages/Widget2x2.ets`
- 单游戏（gameCount=1）：详细模式，体力环 + 额外数据行
- 多游戏（gameCount=2-3）：精简模式，每款游戏一行
- 根据 `gameCount` 字段自动切换布局

**测试任务 T08-test**：文件末尾添加 `@Preview`，覆盖单游戏（原神/星铁/绝区零）和多游戏（2款/3款）

### T09 — 实现 Widget2x4

- 创建 `entry/src/main/ets/widget/pages/Widget2x4.ets`
- 单游戏：左右分栏，左侧体力环，右侧数据行（约 4-5 行）
- 多游戏（2款）：纵向排列，每款基础信息 + 1行额外数据
- 多游戏（3款）：纵向排列，每款横排一行（体力环+数值+游戏名·回满时间+右侧额外数据）

**测试任务 T09-test**：文件末尾添加 `@Preview`，覆盖单游戏和多游戏（2款/3款）

### T10 — 实现 Widget4x4

- 创建 `entry/src/main/ets/widget/pages/Widget4x4.ets`
- 单游戏（原神）：完整数据 + 底部探索派遣 5 个角色头像（5等分，已完成有 ✓）
- 单游戏（星铁）：完整数据（含货币战争、模拟宇宙本周积分）
- 单游戏（绝区零）：完整数据（今日活跃度、刮刮卡/占卜、录像店经营）
- 多游戏（2款）：每款基础信息 + 3行额外数据
- 多游戏（3款）：每款基础信息 + 2行额外数据

**测试任务 T10-test**：文件末尾添加 `@Preview`，覆盖三款游戏单游戏和多游戏

---

## 阶段三：App 内入口

### T11 — My 页面新增 Widget 入口区域

- 在 `entry/src/main/ets/components/my/` 下新建 `WidgetSection.ets`
- 根据已登录账号动态展示，每个账号显示可添加的游戏卡片按钮
- 点击调用 `formProvider.openFormManager(want)`，携带 accountId 和 formName
- 在 `My.ets` 中引入 `WidgetSection`

**测试任务 T11-test**：文件末尾添加 `@Preview`，覆盖无账号、单账号、多账号三种状态

---

## 阶段四：数据推送集成

### T12 — StaminaNotificationService 集成 Widget 推送

- 在 `StaminaNotificationService` 的体力检测逻辑中，检测到数据变化时调用 `WidgetDataBuilder.buildAndPushForAccount(accountId)`
- 确保不在 EntryFormAbility 进程中调用（进程隔离）

### T13 — 账号删除时清理 Widget 数据

- 在 `BBSRepository.deleteAccount` 完成后，调用 `WidgetFormIdStore.getFormIdsByAccount(accountId)` 获取相关 formId
- 对每个 formId 推送空态数据（或调用 `formProvider.deleteForm` 删除卡片）

---

## 阶段五：锁屏卡片

### T14 — 锁屏卡片配置

- 为 `widget_1x2_genshin`、`widget_1x2_starrail`、`widget_1x2_zzz` 添加锁屏支持
- 新增锁屏专用配置（`renderingMode: autoColor`）
- 在 AppGallery Connect 申请「锁屏卡片」开放能力

---

## 任务依赖关系

```
T01 → T04
T02 → T03 → T04
T02 → T12
T03 → T12
T04 → T05~T10（EntryFormAbility 需要先有卡片 UI 文件）
T05~T10 → 可并行
T11 → T03（需要 openFormManager）
T12 → T03
T13 → T02
T14 → T05~T07（锁屏使用 1×2 模板）
```

## 建议执行顺序

1. T01（配置文件）
2. T02（FormIdStore）→ T02-test
3. T03（DataBuilder）→ T03-test
4. T04（EntryFormAbility）
5. T05 ~ T10（卡片 UI，可并行）→ 各自的 test
6. T11（My 页面入口）→ T11-test
7. T12（通知服务集成）
8. T13（账号删除清理）
9. T14（锁屏配置）
