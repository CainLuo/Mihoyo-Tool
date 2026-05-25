# Widget 模块重构 - 任务清单

## 任务列表

### 阶段一：基础设施

- [x] **T1**: 创建 `entry/src/main/ets/widget/models/WidgetUIStates.ets`
  - 定义 `WidgetTheme` 单例类
  - 定义 `WidgetExtraRow` 类
  - 定义 `WidgetRoleUIState` 类
  - 定义 `Widget2x2UIState`、`Widget2x4UIState`、`Widget4x4UIState` 类
  - 定义 `Widget1x2UIState` 类

- [x] **T2**: 创建 `entry/src/main/ets/widget/viewmodel/WidgetViewModel.ets`
  - 实现 `build2x2UIState()` 方法
  - 实现 `build2x4UIState()` 方法
  - 实现 `build4x4UIState()` 方法
  - 实现 `build1x2UIState()` 方法
  - 实现 `buildRoleUIState()` 方法
  - 实现 `calcStaminaColor()` 方法
  - 实现 `buildExtraRows()` 方法
  - 实现游戏专属数据解析方法

- [x] **T3**: 添加 Widget 字符串资源
  - 在 `string.json` 中添加 `widget_expedition` ✅ 已存在
  - 在 `string.json` 中添加 `widget_home_coin` ✅ 已存在
  - 在 `string.json` 中添加 `widget_train_score` ✅ 已存在（每日实训）
  - 在 `string.json` 中添加 `widget_cocoon` ✅ 已存在（历战余响）
  - 在 `string.json` 中添加 `widget_vitality` ✅ 已存在
  - 在 `string.json` 中添加 `widget_card_sign` ✅ 已存在
  - 同步更新英文和繁体中文资源文件 — 待确认

### 阶段二：修改 Widget Pages

- [ ] **T4**: 重构 `Widget2x2.ets`
  - 移除 `buildSingleGameData()` 方法
  - 移除 `buildMultiGameData()` 方法
  - 移除 `detectGameId()` 方法
  - 移除 `parseGameSpecificData()` 方法
  - 使用 `WidgetViewModel.build2x2UIState()`
  - 传递 UIState 给 Component

- [ ] **T5**: 重构 `Widget2x4.ets`
  - 同上

- [ ] **T6**: 重构 `Widget4x4.ets`
  - 同上

- [ ] **T7**: 重构 `Widget1x2Genshin.ets`
  - 同上

- [ ] **T8**: 重构 `Widget1x2StarRail.ets`
  - 同上

- [ ] **T9**: 重构 `Widget1x2ZZZ.ets`
  - 同上

### 阶段三：修改 Widget Components

- [ ] **T10**: 重构 `Widget2x2SingleGame.ets`
  - 移除 `extraRows` getter
  - 移除 `staminaColor` getter
  - 移除 `gameColor` getter
  - 移除硬编码字符串
  - 接收 `theme` 和 `role` 参数
  - 只保留渲染逻辑

- [ ] **T11**: 重构 `WidgetSlotRenderer.ets`
  - 移除所有数据解析逻辑
  - 移除 `extraRows` getter
  - 接收 UIState 参数

- [ ] **T12**: 重构 `WidgetCardContent.ets`
  - 移除 `detectGameId()` 方法
  - 移除 `buildSlotData()` 方法
  - 接收 UIState 参数

- [ ] **T13**: 重构 `WidgetDataRow.ets`
  - 移除 `new DefaultTheme()`
  - 接收 `theme` 参数

- [ ] **T14**: 重构其他组件
  - `Widget4x4SingleGame.ets`
  - `Widget4x4MultiGame.ets`
  - `WidgetMultiGameCompact.ets`
  - `WidgetCompactGameRow.ets`
  - 等

### 阶段四：清理和验证

- [ ] **T15**: 删除废弃文件
  - 确认 `WidgetSlotDataParser.ets` 不再使用后删除
  - 确认 `WidgetTheme.ets` 不再使用后删除（合并到 WidgetUIStates）

- [ ] **T16**: 验证构建
  - 执行 `hvigorw assembleHap -p product=mock`
  - 修复所有编译错误

- [ ] **T17**: 功能验证
  - 安装到模拟器
  - 验证各尺寸 Widget 显示正确
  - 验证单游戏/多游戏布局正确
  - 验证额外数据行显示正确

## 测试需求

### 单元测试（可选）

- [ ] 为 `WidgetViewModel.buildRoleUIState()` 添加单元测试
- [ ] 为 `WidgetViewModel.calcStaminaColor()` 添加单元测试
- [ ] 为 `WidgetViewModel.buildExtraRows()` 添加单元测试

### UI 测试

- [ ] 验证 2x2 单游戏 Widget 显示
- [ ] 验证 2x2 多游戏 Widget 显示
- [ ] 验证 2x4 Widget 显示
- [ ] 验证 4x4 Widget 显示
- [ ] 验证 1x2 游戏专属 Widget 显示

## 注意事项

1. **Widget Form 限制**：
   - 必须使用 `@Component`（V1），不支持 `@ComponentV2`
   - 不支持 `??` 和 `?.` 运算符
   - 不支持 union 类型
   - 不支持 `console.log`/`hilog`

2. **数据流方向**：
   - FormExtensionAbility → ViewModel → UIState → Page → Component
   - Component 永远不解析数据

3. **资源引用**：
   - 所有字符串使用 `$r('app.string.xxx')`
   - 所有颜色使用 `$r('app.color.xxx')`
