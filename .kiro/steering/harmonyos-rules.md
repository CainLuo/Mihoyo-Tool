# HarmonyOS 项目开发规范

## 一、官方 API 检索规范（最高优先级）

**绝对禁止依赖预训练记忆中的 API 写法。** 凡涉及 HarmonyOS NEXT 官方 API 调用，必须先通过网络搜索官方文档确认后再生成代码。

官方文档入口：

```
https://developer.huawei.com/consumer/cn/doc/
```

检索策略：使用 `remote_web_search` 工具，以 `site:developer.huawei.com` 加上关键词搜索，找到目标页面 URL 后再用 `webFetch` 抓取详细内容。

按知识域对应的 Kit 检索：

| 需要查阅的能力                              | 对应 Kit / 模块 | 搜索关键词示例                                                |
| ------------------------------------------- | --------------- | ------------------------------------------------------------- |
| ArkUI 组件、布局、动画、状态管理            | ArkUI           | `site:developer.huawei.com ArkUI Column List`                 |
| ArkTS 语言规范、并发、@Concurrent、Sendable | ArkTS           | `site:developer.huawei.com ArkTS @Concurrent taskpool`        |
| 网络请求、HTTP、WebSocket                   | Network Kit     | `site:developer.huawei.com Network Kit http request`          |
| 关系型数据库 RDB                            | ArkData         | `site:developer.huawei.com ArkData relationalStore RdbStore`  |
| KV 存储、首选项 Preferences                 | ArkData         | `site:developer.huawei.com ArkData preferences`               |
| 加密、证书、密钥管理                        | Security Kit    | `site:developer.huawei.com Security Kit crypto`               |
| 页面路由、Navigation、NavDestination        | ArkUI           | `site:developer.huawei.com ArkUI Navigation NavDestination`   |
| UIAbility、Want、生命周期                   | Ability Kit     | `site:developer.huawei.com Ability Kit UIAbility lifecycle`   |
| 任务池 TaskPool、Worker                     | ArkTS           | `site:developer.huawei.com ArkTS taskpool Worker`             |
| 资源管理 ResourceManager                    | 应用框架        | `site:developer.huawei.com resourceManager getRawFileContent` |
| 自动化测试 Hypium                           | 测试框架        | `site:developer.huawei.com hypium ohosTest`                   |
| 日志 hilog                                  | 系统            | `site:developer.huawei.com hilog`                             |

**执行要求：** 先搜索找到准确 URL，再用 `webFetch` 抓取页面内容确认 API 签名，不得跳过此步骤，不得凭记忆猜测 API 参数。

---

## 二、三方库 (OHPM) 动态检索规范

遇到不熟悉的第三方包（如 `@hadss/hmrouter`、`@ohos/axios`、加密库等），或被要求使用某个库时，严格按以下顺序执行：

1. **查阅清单**：先读取对应模块（`entry` 或 `core`）下的 `oh-package.json5`，确认包名和版本号。

2. **逐级深入抓取文档**，按以下优先级依次尝试，直到获得足够信息为止：
   - **第一级：OHPM 主页 README**
     访问 `https://ohpm.openharmony.cn/#/cn/detail/<包名>`，抓取页面内的 README 内容。

   - **第二级：Gitee 开源仓库 README**
     在 Gitee 搜索该包名，找到官方仓库后抓取根目录 `README.md`。

   - **第三级：示例代码 / demo 目录**
     如果 README 描述不够详细（缺少初始化方式、参数说明、生命周期等），则继续在该仓库中查找：
     - `entry/src/main/ets/` 或 `sample/`、`demo/`、`example/` 目录下的 `.ets` 示例文件
     - 直接抓取示例文件内容，从真实用法中推断正确的 API 调用方式

   - **第四级：源码**
     如果示例仍不足以说明问题，则直接阅读该库的核心源码文件（如 `Index.ets`、主类文件），从导出的接口签名和实现中确认用法。

3. **严格遵从**：基于以上获取的真实代码，学习其初始化、调用和销毁方式后再生成代码。

**禁止**直接套用标准 JS/TS 库的写法，鸿蒙三方库的 API 与 Web 生态存在本质差异。

---

## 三、多模块架构物理边界规范

本项目采用鸿蒙多模块 (Multi-module) 架构，代码生成和修改必须严格遵守以下边界：

### `core` 模块（底层基础设施）

- **职责**：网络请求 (Network)、数据模型 (Models)、JSON 解析、加密解密 (Crypto)、本地持久化存储 (KVStore/RDB)
- **文件后缀**：只允许 `.ts` 或 `.ets`
- **禁区**：绝对不允许出现任何 ArkUI 组件（`@Component`、`Text`、`Column` 等装饰器或组件）
- **暴露规范**：所有对外提供的类、接口、单例，必须统一在 `core/Index.ets` 中 `export`

### `entry` 模块（UI 与业务展示）

- **职责**：视图渲染、路由跳转 (HMRouter)、UI 状态管理
- **依赖调用**：需要网络或数据能力时，必须从 `core` 模块导入，例如：
  ```typescript
  import { NetworkManager } from "core";
  ```
- **禁区**：严禁在页面文件中直接编写底层 HTTP 请求代码或复杂加解密算法，必须委托给 `core`

### 测试隔离

- 所有单元测试必须与业务代码隔离
- 放置在对应模块的 `src/test/` 或 `src/ohosTest/` 目录中
- 编写测试前，必须先按规范一搜索 Hypium 最新规范后再生成测试用例
