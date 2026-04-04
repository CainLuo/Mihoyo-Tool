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
