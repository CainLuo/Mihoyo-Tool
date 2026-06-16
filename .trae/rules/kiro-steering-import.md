---
alwaysApply: true
description: 每次回答问题前，请先查看 .kiro/steering/ 目录下的所有规则文件
---

# 重要：回答前必读

在回答任何问题或执行任何任务之前，请按以下顺序操作：

## 1. 必须查看所有规则

请先遍历并读取 `.kiro/steering/` 目录下的所有规则文件：

| 文件名 | 说明 |
| --- | --- |
| `01-project-base-rules.md` | 项目基础规则与 Claude 指南 |
| `02-architecture.md` | 项目架构与模块边界规范 |
| `03-coding-standards.md` | 编码标准（硬编码、枚举、组件拆分、注释等） |
| `04-harmonyos-api.md` | HarmonyOS API 使用规范 |
| `05-ui-prototype.md` | UI 原型先行原则 |
| `06-core-data-layer.md` | core 数据层规范 |
| `07-env-and-mock.md` | 环境与 Mock 规范 |
| `08-version-management.md` | 版本管理与归档规范 |
| `error-handling-strategy.md` | 错误处理与用户反馈策略 |
| `testing-strategy.md` | 测试策略总览 |
| `testing-core.md` | core 模块测试规范 |
| `testing-entry-components.md` | entry 组件测试规范 |
| `testing-entry-pages.md` | entry 页面测试规范 |

## 2. 使用规则

在开始工作前，请确保：

- 已经读取并理解上述所有规则
- 在回答问题或修改代码时严格遵循这些规则
- 如果规则之间有冲突，请优先遵循项目的实际代码风格

## 3. 规则概述

### 项目架构
- 严格遵循 MVVM + 分层架构
- core 模块与 entry 模块有明确边界
- entry 层只能调用 Repository，不能直接操作 DB 或 API

### 编码规范
- 禁止硬编码字符串、数值
- 必须使用枚举，禁止字符串字面量
- 组件必须拆分，每个组件文件只包含一个业务组件
- 每个组件必须有 @Preview

### 工作流程
- UI 改动必须先出 HTML 原型，等用户确认后再写 .ets 代码
- 遵循测试策略，新增代码必须补充测试
- 构建必须通过 run-mock.sh 验证

### 其他重要规则
- 每次修改代码后必须用 run-mock.sh 验证构建
- 删除或修改代码后必须验证不影响原有逻辑
- 所有公开函数必须有注释

---

**重要提示：** 本规则文件只是一个入口，请务必实际读取 `.kiro/steering/` 目录下的所有规则文件，它们才是完整的项目规范。
