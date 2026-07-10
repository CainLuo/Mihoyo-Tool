# Widget 额外信息行优化 - 任务清单

## 状态说明

- [ ] 未开始
- [x] 已完成
- [~] 进行中

---

## 一、枚举与配置

### 1.1 新增 `ExtraRowType` 枚举

- [x] 创建 `entry/src/main/ets/widget/utils/WidgetExtraRowType.ets`
- [x] 定义原神额外信息类型（5 个）
- [x] 定义星铁额外信息类型（3 个）

### 1.2 新增 `WidgetExtraRowConfig` 优先级配置

- [x] 创建 `entry/src/main/ets/widget/utils/WidgetExtraRowConfig.ets`
- [x] 定义原神优先级配置
- [x] 定义星铁优先级配置
- [x] 实现 `getPriority(gameId)` 方法

---

## 二、工具方法修改

### 2.1 修改 `WidgetDataHelper.parseExtraRows()`

- [x] 添加 `maxRows` 可选参数（默认值 0）
- [x] 原神：添加周活跃进度解析
- [x] 星铁：移除 `grid_fight` 和 `cocoon` 解析（JSON 中无对应字段）
- [x] 实现优先级排序逻辑（原神/星铁）
- [x] 实现 `maxRows` 截断逻辑

### 2.2 新增绝区零 `note_list` 解析

- [x] 实现 `parseZZZNoteList()` 私有方法
- [x] 解析 `note_list` 数组
- [x] 转换 `value_highlight` 为颜色类型
- [x] 删除旧的绝区零手动解析逻辑

---

## 三、ViewModel 修改

### 3.1 `Widget2x2ViewModel`

- [x] `buildRoleUIState()` 调用 `parseExtraRows()` 时传入 `maxRows=2`
- [x] 移除 `WIDGET_GAME_ID` 未使用的 import 警告

### 3.2 `Widget2x4ViewModel`

- [x] 检查是否需要限制行数，传入对应 `maxRows`

### 3.3 `Widget4x4ViewModel`

- [x] 检查是否需要限制行数，传入对应 `maxRows`

---

## 四、资源文件更新

### 4.1 新增字符串资源

- [x] `app.string.widget_week_active` — 周活跃进度（原神）
- [x] `app.string.widget_rogue_tourn` — 模拟宇宙积分（星铁，已存在）

---

## 五、测试

### 5.1 单元测试

- [x] 创建 `entry/src/test/WidgetExtraRowType.test.ets`
  - [x] 枚举值验证测试
- [x] 创建 `entry/src/test/WidgetExtraRowConfig.test.ets`
  - [x] 优先级配置验证测试
  - [x] `getPriority()` 方法测试
- [x] 创建 `entry/src/test/WidgetDataHelperExtraRows.test.ets`
  - [x] `parseExtraRows` 数量限制测试
  - [x] 绝区零 `note_list` 解析测试
- [x] 在 `entry/src/test/List.test.ets` 注册新测试

### 5.2 组件 @Preview

- [x] `WidgetExtraDataRows` 添加多行数据预览（4 行）

---

## 六、验证

### 6.1 编译验证

- [x] 执行 `hvigorw assembleHap -p product=mock`
- [x] 确认无编译错误和警告

### 6.2 功能验证

- [x] Mock 文件名映射修正：`/event/game_record_zzz/api/zzz/widget` → `event_record_app_zzz_widget.json`
- [x] ZZZ `parseZZZNoteList` 增加降级逻辑：从普通便笺 API 字段构建额外数据
- [x] 模拟器或真机运行 Widget
- [x] 验证原神 2x2 Widget 显示 2 行额外信息
- [x] 验证星铁 2x2 Widget 显示 2 行额外信息
- [x] 验证绝区零 2x2 Widget 显示额外信息（录像店经营、刮刮卡等）
