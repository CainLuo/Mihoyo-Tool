# Home 模块架构分析需求文档

## 背景

Widget 模块架构优化完成后，按照相同流程对 Home 模块进行架构检查，发现以下问题：

1. **冗余代码**：`HomeContent.ets` 组件未被任何页面使用，`Home.ets` 直接在 `build()` 中渲染子组件
2. **ViewModel 过大**：`HomeViewModel.ets` 达到 839 行，包含大量数据解析逻辑
3. **职责边界模糊**：`loadDailyNoteSnapshot()` 方法包含三套游戏的详细解析逻辑（每套约 80-100 行），应抽取到独立的 Parser 或 Helper

## 目标

1. 移除未使用的 `HomeContent.ets` 组件
2. 分析 `HomeViewModel` 是否需要拆分，如需要则制定拆分方案
3. 评估现有代码结构是否符合 MVVM 规范

## 验收标准

- [ ] 删除 `HomeContent.ets`，确认不影响任何功能
- [ ] 评估 `HomeViewModel.ets` 是否需要拆分，如不需要则说明原因
- [ ] 更新 CHANGELOG.md 记录此次重构

## 不在范围内

- 业务逻辑修改
- 新增功能
