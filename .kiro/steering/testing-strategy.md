# 测试策略总览

本项目测试文档分为三份，按模块和层级严格隔离，**不得混用**：

| 文档                          | 覆盖范围                                                                                             |
| ----------------------------- | ---------------------------------------------------------------------------------------------------- |
| `testing-core.md`             | core 模块：常量/模型层、DB 层（DAO/RdbManager）、API 层（Service/DSUtil/Parser/Mock）、Repository 层 |
| `testing-entry-components.md` | entry 模块：所有 @ComponentV2 组件的 @Preview 规范和 UI 测试用例                                     |
| `testing-entry-pages.md`      | entry 模块：所有页面的 ViewModel 单元测试和设备端 UI 测试用例                                        |

## 隔离原则

- **core 和 entry 不混用**：core 的测试文件只 import core 内的类，entry 的测试文件只 import entry 内的类
- **DB 层和 API 层不混用**：DAO/RdbManager 的测试不涉及网络，Service/DSUtil 的测试不涉及数据库
- **本地测试和设备端测试不混用**：纯逻辑放 `src/test/`，需要真实 RDB/UI 的放 `src/ohosTest/`

## 测试文件位置

```
core/src/test/           ← core 本地单元测试（纯逻辑：Parser、DSUtil、MockServiceBase 静态方法、枚举、Row 模型）
core/src/ohosTest/       ← core 设备端测试（需要真实 RDB：DAO、RdbManager、Repository）
entry/src/test/          ← entry 本地单元测试（纯逻辑：ViewModel 状态初始化和纯函数）
entry/src/ohosTest/      ← entry 设备端 UI 测试（需要真机/模拟器：页面交互流程）
```

## 新增代码的测试要求

| 新增内容               | 必须补充的测试                                                          |
| ---------------------- | ----------------------------------------------------------------------- |
| 新增 Parser 类         | `core/src/test/` 下新建测试文件，覆盖全字段解析 + 无效 JSON 容错        |
| 新增枚举常量           | 在对应测试文件中添加枚举值与字符串一致性验证                            |
| 新增 Row 模型          | 在 `RowModels.test.ets` 中添加默认值验证                                |
| 新增 DAO 类            | 在 `core/src/ohosTest/` 下新建测试文件，覆盖 upsert/find/delete         |
| 新增 @ComponentV2 组件 | 在组件文件末尾添加 `@Preview`，覆盖主要状态                             |
| 新增页面               | 在 `testing-entry-pages.md` 中补充 ViewModel 单元测试和页面 UI 测试设计 |

## Spec 生成时的测试覆盖要求

**每次生成 Spec（requirements.md + design.md + tasks.md）时，必须将测试需求作为 Spec 的一部分覆盖，不得遗漏。**

### requirements.md 中必须包含

针对本次新增/修改的内容，在 requirements 中明确列出测试验收标准：

- **新增 @ComponentV2 组件**：需求中必须包含「组件文件末尾有 `@Preview` 覆盖主要状态」的验收条件
- **新增页面**：需求中必须包含 ViewModel 单元测试用例（初始状态、状态转换）和页面 UI 测试用例（关键交互流程）
- **新增 ViewModel**：需求中必须包含初始状态验证和纯函数逻辑的单元测试验收条件

### design.md 中必须包含

在设计文档的「测试策略」章节中，按以下三类分别列出：

1. **单元测试**（`entry/src/test/` 或 `core/src/test/`）
   - ViewModel 初始状态验证
   - ViewModel 纯函数逻辑（如格式化、映射函数）
   - 枚举/常量一致性

2. **组件 @Preview / Snapshot 测试**（组件文件末尾）
   - 每个新增 `@ComponentV2` 组件必须有 `@Preview` 覆盖主要状态（空态、有数据、加载中等）
   - `@Preview` 命名规范：`<组件名>Preview`，背景色 `'#1a1a2e'`

3. **设备端 UI 测试**（`entry/src/ohosTest/`）
   - 页面级关键交互流程（跳转、选中状态、回调触发）
   - 使用 Hypium + `@ohos/uitest`

### tasks.md 中必须包含

每个功能实现任务之后，必须有对应的测试任务：

- 实现组件 → 对应「为 XxxComponent 添加 @Preview」任务
- 实现页面 → 对应「补充 XxxViewModel 单元测试」和「补充 XxxPage UI 测试」任务
- 实现 ViewModel 纯函数 → 对应「补充单元测试」任务
