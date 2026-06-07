# 工作状态记录

> 最后更新：2026-06-07

---

## 已完成任务

### 7. WidgetConfigPreview 组件重构 ✅

**问题**：`WidgetConfigPreview.ets` 文件过大（约 1000 行），违反编码规范。

**修复内容**：
1. 将 `@Builder` 方法拆分为独立组件文件
2. 创建 `WidgetPreviewUtils.ets` 统一工具函数
3. 创建 `WidgetFormUtils.ets` 抽取 Form Manager 相关工具函数

**涉及文件**：
- `entry/src/main/ets/components/widgetconfig/WidgetConfigPreview.ets` — 主组件
- `entry/src/main/ets/components/widgetconfig/preview/` — 预览组件目录
  - `PreviewEmptyContent.ets`
  - `Preview1x2Content.ets`
  - `Preview1x2Card.ets`
  - `PreviewExtraDataRow.ets`
  - `Preview2x2SingleGame.ets`
  - `Preview2x2MultiSlot.ets`
  - `Preview2x4MultiSlot.ets`
  - `Preview4x4MultiSlot.ets`
  - `WidgetPreviewUtils.ets`
- `entry/src/main/ets/widget/utils/WidgetFormUtils.ets`

---

### 8. Preview1x2Card 装饰条高度修复 ✅

**问题**：装饰条高度超出容器。

**修复内容**：
- 与真实 Widget `Widget1x2ContentView` 保持一致
- `Stack` 使用 `height: full` 充满父容器
- 用 `padding({ top: 8, bottom: 8 })` 控制装饰条的实际高度
- 移除不再需要的 `cardHeight` 参数

**涉及文件**：
- `entry/src/main/ets/components/widgetconfig/preview/Preview1x2Card.ets`
- `entry/src/main/ets/components/widgetconfig/preview/Preview2x2MultiSlot.ets`
- `entry/src/main/ets/components/widgetconfig/WidgetConfigPreview.ets`

---

### 9. WidgetPreviewUtils 硬编码颜色修复 ✅

**问题**：`gameIdToBgColors` 函数返回硬编码的十六进制颜色字符串。

**修复内容**：
- 将返回类型改为 `Resource[]`
- 使用 `$r('app.color.widget_bg_xxx')` 引用 `color.json` 中定义的颜色资源
- 更新 `multiGameGradientColors` 函数返回类型为 `Array<[ResourceColor, number]>`

**涉及文件**：
- `entry/src/main/ets/components/widgetconfig/preview/WidgetPreviewUtils.ets`
- `entry/src/main/ets/components/widgetconfig/WidgetConfigPreview.ets`

---

### 10. ColorUtil deprecated API 警告修复 ✅

**问题**：`resMgr.getColorSync($r('app.color.xxx'))` 已废弃。

**修复内容**：
- 替换为 `resMgr.getColorByNameSync('xxx')`
- 添加 try-catch 处理异常

**涉及文件**：
- `entry/src/main/ets/utils/ColorUtil.ets`

---

### 1. Widget 2x2 白屏问题修复 ✅

**根本原因**：`WidgetCardContent` 使用普通属性接收数组参数，在 Widget 中必须使用 `@Prop` 装饰器。

**修复内容**：
- 将 `WidgetCardContent` 的 `allRoles`、`gameIds`、`isSingleGame` 改为 `@Prop` 装饰
- 记录到 `design/research/FormKit-Notes.md`

**涉及文件**：
- `entry/src/main/ets/widget/components/WidgetCardContent.ets`

---

### 2. Widget 配置数据结构重构 ✅

**目标**：将三层嵌套结构改为扁平结构，支持 `accountId/roleId` 直接查询。

**涉及文件**：
- `entry/src/main/ets/widget/models/WidgetDataStore.ets`
- `entry/src/main/ets/widget/utils/WidgetPayloadBuilder.ets`
- `entry/src/main/ets/widget/utils/WidgetDataStoreBuilder.ets`
- `entry/src/main/ets/widget/utils/WidgetDataStoreManager.ets`
- `entry/src/main/ets/entryformability/EntryFormAbility.ets`
- `entry/src/main/ets/viewmodel/WidgetConfigViewModel.ets`

---

### 3. WidgetSettings.ets 代码整理 ✅

**内容**：将所有 `@Builder` 方法拆分为独立组件。

**涉及文件**：
- `entry/src/main/ets/pages/WidgetSettings.ets`
- `entry/src/main/ets/components/widgetconfig/` 目录下所有组件

---

### 4. 组件参数数量优化（UI State 方案）✅

**内容**：
1. 创建 `WidgetSettingsModels.ets`，定义 `WidgetSettingsUIState`、`WidgetSettingsCallbacks`、`WidgetSettingsSlotHelper`
2. 在 `WidgetConfigViewModel` 中添加 `uiState`、`callbacks`、`slotHelper` 字段
3. ViewModel 负责组装 UI State（`syncUIState()` 方法）
4. 页面只从 ViewModel 获取数据并传给组件
5. 移除硬编码的 `getGameColor` 和 `getGameNameResourceId` 方法，改用 `GameIdUtil` 工具函数

**涉及文件**：
- `entry/src/main/ets/models/WidgetSettingsModels.ets`
- `entry/src/main/ets/components/widgetconfig/WidgetSettingsMainContent.ets`
- `entry/src/main/ets/components/widgetconfig/WidgetSettingsSlotStep.ets`
- `entry/src/main/ets/components/widgetconfig/WidgetSlotOption.ets`
- `entry/src/main/ets/pages/WidgetSettings.ets`
- `entry/src/main/ets/viewmodel/WidgetConfigViewModel.ets`
- `entry/src/main/ets/utils/GameIdUtil.ets`

---

### 5. 硬编码问题修复 ✅

**修复内容**：

1. **颜色硬编码**
   - `WidgetGameTypeOption.ets`：移除 `GameTypeConfig` 接口中的 `color` 字段，改用 `gameIdStrToColor()` 工具函数
   - `WidgetSettingsGameStep.ets`：从 `GAME_TYPE_CONFIGS` 常量中移除硬编码颜色值

2. **字符串硬编码**
   - `WidgetGameTypeOption.ets`：将 `"个账号"` 改为 `$r('app.string.widget_game_account_count', ...)`

**涉及文件**：
- `entry/src/main/ets/components/widgetconfig/WidgetGameTypeOption.ets`
- `entry/src/main/ets/components/widgetconfig/WidgetSettingsGameStep.ets`

---

### 6. 多语言资源同步 ✅

**问题**：英文和繁体中文文件缺少 71 个 Widget 相关字符串资源。

**修复**：将 74 个 Widget 资源翻译并添加到三个语言文件中。

**涉及文件**：
- `entry/src/main/resources/base/element/string.json`（简体中文）
- `entry/src/main/resources/en/element/string.json`（英文）
- `entry/src/main/resources/zh_HK/element/string.json`（繁体中文）

**新增资源 key**：
- `widget_game_account_count`
- `widget_select_account_hint`
- `widget_select_games_hint`
- `widget_select_game_hint`
- `widget_selected_count`
- 以及其他 69 个 Widget 相关资源

---

## 待处理任务

### UI 相关 Bug（待修复）

**状态**：待在 Windows 电脑上继续处理

**待修复内容**：
- [ ] Widget UI 显示问题（具体 bug 需确认）
- [ ] 其他 UI 相关问题

---

## 关键文件索引

### Widget 配置相关
- `entry/src/main/ets/pages/WidgetSettings.ets` — Widget 配置主页面
- `entry/src/main/ets/viewmodel/WidgetConfigViewModel.ets` — Widget 配置 ViewModel
- `entry/src/main/ets/models/WidgetSettingsModels.ets` — Widget 配置 UI State 模型
- `entry/src/main/ets/components/widgetconfig/` — Widget 配置组件目录

### Widget 显示相关
- `entry/src/main/ets/widget/pages/` — Widget 页面目录
  - `Widget2x2.ets`
  - `Widget4x4.ets`
  - `Widget1x2Genshin.ets`
  - `Widget1x2StarRail.ets`
  - `Widget1x2ZZZ.ets`
  - `Widget2x4.ets`
- `entry/src/main/ets/widget/components/` — Widget 组件目录
  - `WidgetCardContent.ets`
  - `Widget1x2Content.ets`
  - `Widget2x2SingleGame.ets`
  - `Widget4x4SingleGame.ets`
  - `Widget4x4MultiGame.ets`

### 工具函数
- `entry/src/main/ets/utils/GameIdUtil.ets` — 游戏 ID 工具函数（颜色、名称、logo 映射）
- `entry/src/main/ets/widget/utils/WidgetDataStoreManager.ets` — Widget 数据存储管理

### 研究笔记
- `design/research/FormKit-Notes.md` — FormKit/Widget 开发笔记
- `design/research/Widget-Config-Analysis.md` — Widget 配置分析

---

## 构建验证

最后构建状态：**成功** ✅

```bash
export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap -p product=mock
```

---

## 注意事项

1. **禁止硬编码**：所有颜色、字符串必须使用资源文件引用
2. **多语言同步**：新增字符串资源时，三个语言文件（base/en/zh_HK）必须同步添加
3. **Widget 使用 `@Prop`**：Widget 中数组参数必须使用 `@Prop` 装饰器
4. **UI State 组装在 ViewModel 层**：ViewModel 负责组装 UI State，页面只负责展示
