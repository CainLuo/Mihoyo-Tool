# My 模块架构分析 — 需求文档

## 一、背景

遵循项目编码规范（`.kiro/steering/03-coding-standards.md`），禁止在 component 或 page 文件中使用 `@Builder` 内联方法。

## 二、问题

`components/my/WidgetSection.ets` 包含一个 `@Builder` 方法 `AccountWidgetBlock`，违反编码规范。

## 三、需求

将 `AccountWidgetBlock` 拆分为独立组件文件。

### 验收标准

1. `WidgetSection.ets` 中无 `@Builder` 方法
2. 新组件文件已创建
3. 编译通过
