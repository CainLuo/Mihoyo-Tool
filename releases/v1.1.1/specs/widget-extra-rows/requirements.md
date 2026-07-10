# Widget 额外信息行优化

## 背景

当前 `WidgetDataHelper.parseExtraRows()` 返回所有可能的额外信息行，没有数量限制。在 2x2 Widget 中，星铁最多可能返回 6 行数据，超出屏幕显示范围。

## 问题

1. **数量无限制**：`parseExtraRows` 没有 `maxRows` 参数，无法控制返回行数
2. **缺少优先级机制**：当行数超过限制时，无法决定显示哪些行
3. **绝区零未使用 `note_list`**：绝区零 API 返回的 `note_list` 字段已包含预格式化的额外信息，当前代码在手动解析原始字段

## 目标

1. 为 `parseExtraRows` 添加 `maxRows` 参数，支持限制返回行数
2. 为原神和星铁定义额外信息类型枚举和优先级配置
3. 绝区零直接使用 `note_list` 字段，不再手动解析原始字段
4. 所有数据解析逻辑放在 ViewModel 层，严格遵守 MVVM 规则

## 范围

### 包含

- `WidgetDataHelper.parseExtraRows()` 方法签名变更
- 新增 `ExtraRowType` 枚举（原神、星铁）
- 新增 `WidgetExtraRowConfig` 优先级配置类
- 绝区零 `note_list` 解析逻辑
- `Widget2x2ViewModel` 调用变更
- 其他 Widget ViewModel 调用变更（如 `Widget2x4ViewModel`、`Widget4x4ViewModel`）
- 测试覆盖

### 不包含

- Widget UI 组件修改（组件只负责渲染）
- entry 模块普通页面的修改（本次只涉及 Widget 相关代码）
