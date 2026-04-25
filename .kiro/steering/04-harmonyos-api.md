# HarmonyOS API 使用规范

## 一、项目平台信息

- **目标平台**：HarmonyOS NEXT 6.0.2，对应 **API 18+**
- **ArkTS 严格模式**已启用，hvigor 编译器比 IDE 语言服务更严格

---

## 二、强制查文档规则（减少 AI 幻觉的核心）

**任何 HarmonyOS API、组件、装饰器的使用，必须先查官方文档，禁止依赖训练数据中的记忆。**

原因：HarmonyOS API 迭代快，API 12 → API 18 之间有大量废弃和新增，记忆中的写法极易出错。

### 文档类型说明

官方文档分为以下类型，用途不同：

| 类型                       | URL 路径特征             | 用途                                 | 何时查                                 |
| -------------------------- | ------------------------ | ------------------------------------ | -------------------------------------- |
| **指南（Guides）**         | `/harmonyos-guides/`     | 概念介绍、开发流程                   | 不熟悉某个功能时，先看指南了解整体用法 |
| **API 参考（References）** | `/harmonyos-references/` | 接口签名、参数类型、返回值、可用版本 | 写具体代码前，必须查 API 参考确认签名  |
| **最佳实践**               | `/best-practices/`       | 性能优化、推荐写法                   | 有性能疑虑时查                         |
| **FAQ**                    | `/harmonyos-faqs/`       | 常见问题解答                         | 遇到报错或异常行为时查                 |

**最重要的是 API 参考**，它是唯一可信的参数签名来源。

### 按场景选择文档类型

| 场景                                  | 应查的文档类型 | 入口                              |
| ------------------------------------- | -------------- | --------------------------------- |
| 不知道某个功能怎么用、有哪些 API      | 指南           | Kit 指南入口（见下方表格）        |
| 要确认某个 API 的参数名、类型、返回值 | API 参考       | 直接构造 URL 或从指南页面跳转     |
| 代码写出来但运行不符合预期            | FAQ            | `/harmonyos-faqs/` 路径下搜索     |
| 担心性能问题、想知道推荐写法          | 最佳实践       | `/best-practices/` 路径下搜索     |
| 某个 API 报错说已废弃                 | API 参考       | 查替代方案，确认新 API 的最低版本 |

### 查文档的标准流程

**第一步：构造文档 URL 直接访问**

华为官方文档的 URL 有固定规律，可以直接构造后用 `webFetch` 访问：

**ArkUI 组件 API 参考**（`/harmonyos-references/ts-<类型>-<组件名小写>`）：

| 组件           | URL                                                                                                    |
| -------------- | ------------------------------------------------------------------------------------------------------ |
| Column         | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-column`                |
| Row            | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-row`                   |
| List           | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-list`                  |
| Scroll         | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-container-scroll`                |
| Text           | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-text`           |
| Button         | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-button`         |
| Image          | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-image`          |
| TextInput      | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-textinput`      |
| Toggle         | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-toggle`         |
| Navigation     | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-navigation`     |
| NavDestination | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-navdestination` |
| Progress       | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-basic-components-progress`       |
| 通用属性       | `https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-component-general-attributes`    |

**Kit 指南入口**（`/harmonyos-guides/<kit名>`）：

| Kit                  | URL                                                                                 |
| -------------------- | ----------------------------------------------------------------------------------- |
| ArkUI                | `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkui`               |
| Ability Kit          | `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ability-kit`         |
| ArkTS                | `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts`               |
| ArkData              | `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkdata`             |
| Notification Kit     | `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/notification-kit`    |
| Background Tasks Kit | `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/background-task-kit` |

**第二步：如果不知道 URL 后缀，先从 Kit 指南入口找**

直接用 `webFetch` 访问对应 Kit 的指南入口（见上方表格），页面内有完整的子页面目录，从中找到目标组件或功能的链接，再用 `webFetch` 访问该链接。

例如：要找 `Grid` 组件的 API 参考 → 先访问 ArkUI 指南入口 → 在页面目录中找到 Grid → 跳转到对应 API 参考页。

如果 Kit 入口页面内容不够，改用 `remote_web_search` 搜索：查询词格式为 `HarmonyOS <组件名或功能名> developer.huawei.com`（**不要加 `site:` 限定符，它在此工具中不生效**），从搜索结果中找 `developer.huawei.com` 域名的链接，再用 `webFetch` 访问。

**第三步：用 `webFetch` 抓取页面**

华为官方文档页面是 JavaScript 渲染的，**必须使用 `mode="rendered"`**，其他模式（`truncated`、`full`）只能拿到 53 字节的空内容：

```
# ❌ 无效 — 只返回 53 字节空内容
webFetch(url, mode="truncated")
webFetch(url, mode="full")

# ✅ 有效 — 能拿到完整页面正文
webFetch(url, mode="rendered")
```

**已验证可用的文档 URL 列表（直接用 rendered 模式访问）**：

| 文档                          | URL                                                                                                       |
| ----------------------------- | --------------------------------------------------------------------------------------------------------- |
| Navigation 基础架构介绍       | `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-architecture`             |
| Navigation 分栏开发           | `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-split-mode`               |
| Navigation 子页面             | `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-navdestination`           |
| Navigation 页面路由           | `https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-navigation-jump`                     |
| 多设备设置界面最佳实践        | `https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-multi-settings-application-page`        |
| 折叠屏分栏模式适配            | `https://developer.huawei.com/consumer/cn/doc/architecture-guides/app_multiplier-0000002312850858`        |
| 分屏模式不支持分栏显示        | `https://developer.huawei.com/consumer/cn/doc/architecture-guides/news-v1_2-ts_c160-0000002396788336`     |
| Navigation 分栏模式留白       | `https://developer.huawei.com/consumer/cn/doc/architecture-guides/educate-v1_1-ts_c56-0000002385171678`   |
| Navigation 单栏与分栏动态切换 | `https://developer.huawei.com/consumer/cn/doc/architecture-guides/insurance-v1_2-ts_116-0000002406922585` |
| Navigation 如何隐藏导航栏     | `https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-arkui-149`                              |

**第四步：确认以下四项，缺一不可**

1. 参数名称和类型是否与预期一致
2. 返回值类型
3. 该 API 的最低可用版本（页面中标注 `since API version X` 或上角标数字）
4. 是否标注 `deprecated`（如果是，必须找替代方案）

**第五步：如果是指南，继续找 API 参考**

指南描述「怎么用」，API 参考才是「参数是什么」。指南页面通常有链接指向对应的 API 参考，必须点进去确认实际签名。

**禁止**跳过上述步骤直接写代码。

---

## 三、废弃 API 替换规则

遇到 `deprecated` 标注的 API，**禁止**继续使用，必须按以下顺序找替代方案：

1. **先看声明文件**：在 DevEco Studio 中 Command+点击该方法，跳转到 `.d.ts` 声明文件，`@deprecated` 注释里通常会写明替代方法（`use XXX instead`）
2. **再查官方文档**：用 `webFetch` 访问对应的 API 参考页，确认替代方法的参数签名和最低可用版本
3. **确认版本兼容**：替代方法必须在 API 18 及以下可用，不得使用高于项目目标版本的 API

```typescript
// 错误 — 使用已废弃的 API
promptAction.showDialog(...)  // 如果此方法已标注 @deprecated

// 正确 — 查声明文件找到替代，确认签名后使用
promptAction.openCustomDialog(...)
```

已知废弃替换表：

| 废弃写法                             | 替代写法                                                      | 可用起始版本 |
| ------------------------------------ | ------------------------------------------------------------- | ------------ |
| 全局 `px2vp(n)`                      | `this.getUIContext().px2vp(n)`                                | API 12+      |
| 全局 `vp2px(n)`                      | `this.getUIContext().vp2px(n)`                                | API 12+      |
| 全局 `getContext()`                  | `this.getUIContext().getHostContext()`                        | API 12+      |
| 全局 `animateTo()`                   | `this.getUIContext().animateTo()`                             | API 12+      |
| `@Component`                         | `@ComponentV2`                                                | API 12+      |
| `@State` / `@Observed`               | `@Local` / `@ObservedV2` + `@Trace`                           | API 12+      |
| `promptAction.showDialog(...)`       | `this.getUIContext().getPromptAction().showDialog(...)`       | API 18+      |
| `promptAction.showToast(...)`        | `this.getUIContext().getPromptAction().showToast(...)`        | API 18+      |
| `promptAction.openCustomDialog(...)` | `this.getUIContext().getPromptAction().openCustomDialog(...)` | API 18+      |
| `AlertDialog.show(...)`              | `this.getUIContext().showAlertDialog(...)`                    | API 12+      |

`UIContext` 必须在 `aboutToAppear()` 里通过 `this.getUIContext()` 获取并缓存，不能在回调或异步函数中直接调用。

---

## 四、ArkTS 严格模式禁止写法

以下写法在 IDE 不报错，但 hvigor 会编译失败：

| 禁止写法                               | 原因                                           | 替代方案                                        |
| -------------------------------------- | ---------------------------------------------- | ----------------------------------------------- |
| `GridItemAlignment.Center`             | API 18 不存在此枚举值                          | 删除 `.alignItems()`，使用默认对齐              |
| `Array.from({ length: n })`            | ArkTS 严格模式禁止                             | 用 `for` 循环手动构建数组                       |
| `Array.map()` / `Array.filter()`       | ArkTS 严格模式禁止                             | 用 `for` 循环替代                               |
| `import('path').TypeName` 内联类型     | ArkTS 严格模式禁止                             | 改为顶层 `import { TypeName } from 'path'`      |
| `...obj` 展开运算符                    | ArkTS 严格模式禁止                             | 逐字段赋值                                      |
| `in` 操作符                            | ArkTS 严格模式禁止                             | 改用可选链或显式字段检查                        |
| `unknown` 类型                         | ArkTS 严格模式禁止                             | 改用具体类型或 `Object`                         |
| 无类型对象字面量作为 `static readonly` | hvigor 报 `arkts-no-untyped-obj-literals`      | 先声明 class，再 `new` 实例化                   |
| `throw 'string'`                       | 只允许抛 Error 实例                            | `throw new Error('message')`                    |
| `export` 语句在 `import` 之前          | ArkTS 严格模式要求所有 import 必须在文件最顶部 | 把所有 `import` 移到文件开头，`export` 放在后面 |

**hvigor 是最终裁判**，getDiagnostics 通过不代表 hvigor 能编译通过。

遇到枚举值不确定时，必须查 API 参考确认枚举成员列表，不得凭记忆或 IDE 自动补全。

---

## 四·一、@BuilderParam 使用规范

`@BuilderParam` 的 lambda 里**只能调用 `@Builder` 方法，不能直接调用 `@ComponentV2` 组件**。直接调用组件会导致运行时 crash（编译不报错）。

```typescript
// ❌ 错误 — 直接在 lambda 里调用组件，运行时 crash
DailyNoteCard({
  hasCustomBottom: true,
  customBottom: () => { GenshinDailyTaskContent({ task: this.data.dailyTask }) }
})

// ✅ 正确 — 先定义 @Builder 方法，lambda 里调用 @Builder
@Builder
taskContent() {
  GenshinDailyTaskContent({ task: this.data.dailyTask })
}

DailyNoteCard({
  hasCustomBottom: true,
  customBottom: () => { this.taskContent() }
})
```

`@BuilderParam` 的默认值必须是一个空的 `@Builder` 函数（ArkTS 不支持可选 `@BuilderParam`）：

```typescript
@Builder
function emptyBuilder() {}

@ComponentV2
export struct MyCard {
  @BuilderParam customSlot: () => void = emptyBuilder
}
```

---

## 五、UI 组件选用规范

优先使用系统原生组件，**禁止**使用 `@kit.UIDesignKit` 中的 Hds 系列组件。

| 场景         | 正确做法                                        | 禁止做法                   |
| ------------ | ----------------------------------------------- | -------------------------- |
| 导航根容器   | `Navigation`                                    | 手写自定义导航框架         |
| 子页面根容器 | `NavDestination` + `.title()`                   | 手写 `Row` 模拟 NavBar     |
| 非模态通知   | `promptAction.showToast`                        | 自定义 Toast               |
| 可点击按钮   | `Button(label)`                                 | `Text(label).onClick(...)` |
| 文本输入     | `TextInput` / `TextArea`                        | 自定义输入框               |
| 加载指示器   | `LoadingProgress()`                             | 自定义动画                 |
| 环形进度     | `Progress({ type: ProgressType.Ring })`         | 自定义 Canvas              |
| 二维码       | `QRCode(url)`                                   | 第三方库或 Canvas          |
| 对话框       | `promptAction.openCustomDialog` / `AlertDialog` | 手写遮罩层                 |

系统原生组件（`Navigation`、`NavDestination` 等）已处理安全区域避让，**禁止**在普通页面手动添加 `statusBarHeight` padding 或 `expandSafeArea`。

---

## 六、三方库使用规范

遇到不熟悉的 OHPM 包时，按以下顺序查阅：

1. 读取 `oh-package.json5` 确认包名和版本
2. 访问 `https://ohpm.openharmony.cn/#/cn/detail/<包名>` 抓取 README
3. 在 Gitee 找官方仓库，查看示例代码
4. 必要时直接阅读库的核心源码

**禁止**直接套用标准 JS/TS 库的写法，鸿蒙三方库的 API 与 Web 生态存在本质差异。

---

## 七、构建与运行规范

**每次修改代码后，必须在前台执行 `run-mock.sh` 验证构建结果，不得跳过：**

```bash
bash run-mock.sh
```

脚本会依次执行：Clean → Build(mock) → 安装到模拟器 → 启动 App。

**必须等待脚本执行完毕，检查输出结果：**

- 出现 `ERROR` → 必须修复，不得忽略
- 出现 `WARN` → 必须评估，deprecated API 等警告必须修复
- 输出 `✅ 完成` → 验证通过

**禁止**在后台执行构建命令（不得使用 `&` 或 `controlBashProcess` 启动构建），否则无法捕获 error 和 warning。

如果只需要验证编译（不需要安装运行），可以单独执行构建步骤：

```bash
export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap -p product=mock
```

- 模拟器连接地址：`127.0.0.1:5555`
- Bundle ID（mock）：`com.cainluo.miyoyo.tools.mock`
- **禁止**使用 `-p buildMode=mock`（正确参数是 `-p product=mock`）
- **禁止**跳过安装步骤直接启动
