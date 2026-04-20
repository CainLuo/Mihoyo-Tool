# HarmonyOS 项目开发规范

## 零、核心开发原则（最高优先级，所有规范的基础）

以下原则适用于所有开发行为，优先级高于其他所有规范：

### 0. AI 行为规范

- **收到明确的执行指令后，直接动手修改代码，不要回复"Understood"或类似的确认语**
- 改完代码后必须立即用 `executeBash` 工具依次执行构建、安装、启动三步（见第二十节），如有编译错误立即修复，直到 BUILD SUCCESSFUL 为止
- 不要等用户再次催促才开始执行

### 1. 官方文档优先

**任何 ArkUI 组件、ArkTS API、系统能力的使用，必须先查阅官方文档，不得凭记忆或猜测。**

- 官方文档入口：`https://developer.huawei.com/consumer/cn/doc`
- 查阅方式：先用 `remote_web_search` 搜索，找到目标页面 URL 后用 `webFetch` 抓取详细内容
- **禁止**跳过文档查阅步骤直接写代码

### 2. 禁止使用废弃 API

- 文档中标注 `deprecated` 的 API 一律不得使用
- 必须使用文档推荐的替代方案
- hvigor 编译出现 `deprecated` 警告时，必须立即修复

### 3. 优先使用系统推荐方案

- 凡是系统/官方有推荐方案的场景，必须使用推荐方案
- **禁止**自行实现系统组件已提供的功能（如手动处理 Safe Area、手动实现 NavBar 等）
- 系统原生组件（`Navigation`、`NavDestination` 等）已处理安全区域避让，**禁止**在普通页面手动添加 `statusBarHeight` padding 或 `expandSafeArea`
- 只有有明确特殊需求的页面（如全屏启动页）才允许手动处理布局

### 4. UI 改动必须先出原型

- 任何涉及 UI 布局、视觉风格的新功能或改动，必须先输出 HTML 原型
- 必须得到用户明确确认后，才能动代码
- 详见第一节"UI 原型先行规范"

---

## 零·一、项目 API 版本信息

- **本项目目标平台**：HarmonyOS NEXT 6.0.2，对应 **API 18+**
- **ArkTS 严格模式**已启用，编译器比 IDE 语言服务更严格

### 已废弃 API 替换规则（必须遵守）

| 废弃写法               | 替代写法                               | 可用起始版本 |
| ---------------------- | -------------------------------------- | ------------ |
| 全局 `px2vp(n)`        | `this.getUIContext().px2vp(n)`         | API 12+      |
| 全局 `vp2px(n)`        | `this.getUIContext().vp2px(n)`         | API 12+      |
| 全局 `getContext()`    | `this.getUIContext().getHostContext()` | API 12+      |
| 全局 `animateTo()`     | `this.getUIContext().animateTo()`      | API 12+      |
| `@Component`           | `@ComponentV2`                         | API 12+      |
| `@State` / `@Observed` | `@Local` / `@ObservedV2` + `@Trace`    | API 12+      |

**注意**：`UIContext` 必须在 `aboutToAppear()` 里通过 `this.getUIContext()` 获取并缓存到实例变量，不能在回调或异步函数中直接调用 `this.getUIContext()`。

---

## 一、UI 原型先行规范（最高优先级）

**在编写任何新 UI 组件或页面之前，必须先输出 HTML 原型设计文档，等用户确认后才能开始动工。**

### 执行流程

1. **出原型**：用纯 HTML + CSS + 内联 `<script>` 实现交互原型，覆盖所有设备断点（Phone / Tablet / Foldable / PC）
2. **等确认**：将原型内容呈现给用户，明确等待用户回复"可以"或提出修改意见
3. **动工**：用户确认后，严格按照原型实现 ArkTS 组件，不得擅自改动已确认的视觉设计

### 原型规范

- 必须覆盖所有断点：Phone（360px）、Tablet（800px）、Foldable 展开（932px）、PC（1280px）
- 使用深色背景模拟 HarmonyOS 暗色主题（见下方"HTML 原型视觉规范"）
- 图标/图片用占位色块或真实 URL 均可，重点是布局和间距准确
- **所有原型统一在 `design/prototypes/v1.0/index.html` 中管理**，通过左侧导航切换页面，顶部统一控制设备/主题，禁止为每个页面单独创建独立 HTML 文件

### 原型文件结构

```
design/prototypes/v1.0/
├── viewer/                 ← 统一原型查看器（打开此目录下的 index.html）
│   ├── index.html          ← 入口：左侧页面导航 + 顶部设备/主题控制
│   ├── index-logic.js      ← 路由、刷新、控制栏逻辑
│   ├── shared.js           ← 共享：主题色 THEMES、工具函数
│   └── pages/
│       ├── home.js
│       ├── characters.js
│       ├── my.js
│       ├── login.js
│       ├── genshin-daily-detail.js
│       ├── char-detail.js
│       └── account-detail.js
├── CHANGELOG.md
└── COLOR-DESIGN.md
```

### 新增原型页面流程

1. 在 `pages/` 下新建 `<page-name>.js`，实现：
   - `render<PageName>(w, h)` — 返回 HTML 字符串
   - `<pageName>Controls()` — 返回页面专属控制项数组（无控制项返回 `[]`）
2. 在 `index.html` 的 `<script src="pages/...">` 处引入新文件
3. 在 `PAGES` 注册表中添加条目
4. 在左侧导航 `.sidebar` 中添加 `nav-item`

### 禁止行为

- **禁止**为每个页面单独创建独立 HTML 文件（旧的单文件原型已废弃，保留仅供参考）
- **禁止**在 `render` 函数里硬编码颜色值，必须通过 `T()` 获取主题色
- **禁止**在按钮文字里使用 `\n` 字面量，控制栏按钮由 `index.html` 统一渲染

### HTML 原型视觉规范（所有原型必须统一遵守）

**以 `char-detail.html` 为基准风格，所有新原型必须与之保持一致。**

#### 交互方式

- 采用**单屏幕切换式**展示：页面顶部固定一个控制栏（`.bar`），点击设备按钮切换屏幕内容
- **禁止**多设备并排展示（会导致横向滚动，难以评估真实布局）
- 屏幕容器 `#S` 通过 JS 动态设置 `width` / `height`，内容通过 `innerHTML` 注入

#### 控制栏（`.bar`）规范

```css
.bar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  background: #111118;
  border-bottom: 1px solid #2a2a3a;
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  flex-wrap: wrap;
}
.btn {
  padding: 3px 10px;
  border-radius: 6px;
  border: 1px solid #333;
  background: #1a1a28;
  color: #aaa;
  font-size: 11px;
  cursor: pointer;
  transition: all 0.2s;
}
.btn.on {
  background: #3a6fd8;
  border-color: #3a6fd8;
  color: #fff;
}
```

按钮文字格式：`设备名\n宽×高`，例如 `Phone 竖屏\n360×780`

#### 颜色规范

| 用途          | 值        |
| ------------- | --------- |
| 页面背景      | `#080810` |
| 卡片/面板背景 | `#111118` |
| 控制栏背景    | `#111118` |
| 边框          | `#2a2a3a` |
| 主文字        | `#e8e8f0` |
| 次要文字      | `#888`    |
| 强调色（蓝）  | `#3a6fd8` |
| 高亮色（青）  | `#4fc3f7` |
| 金色（星级）  | `#ffca28` |
| 危险色（红）  | `#ef5350` |

#### 字体规范

```css
font-family: "PingFang SC", "Microsoft YaHei", sans-serif;
```

#### 屏幕容器规范

```css
.screen {
  border: 2px solid #2a2a3a;
  border-radius: 12px;
  overflow: hidden;
}
.wrap {
  margin-top: 52px; /* 为固定控制栏留出空间 */
  display: flex;
  justify-content: center;
  padding: 20px 16px;
}
```

#### 设备尺寸规范

| 设备          | 宽 × 高    | 按钮标签               |
| ------------- | ---------- | ---------------------- |
| Phone 竖屏    | 360 × 780  | `Phone 竖屏\n360×780`  |
| Phone 横屏    | 780 × 360  | `Phone 横屏\n780×360`  |
| Foldable 展开 | 932 × 600  | `Foldable\n932×600`    |
| TripleFold    | 1200 × 600 | `TripleFold\n1200×600` |
| Tablet        | 1024 × 768 | `Tablet\n1024×768`     |
| 2in1/PC       | 1440 × 900 | `2in1/PC\n1440×900`    |

#### JS 路由模板

```javascript
var DEVS = {
  pp: [360, 780], // Phone 竖屏
  pl: [780, 360], // Phone 横屏
  fd: [932, 600], // Foldable
  tf: [1200, 600], // TripleFold
  tb: [1024, 768], // Tablet
  pc: [1440, 900], // 2in1/PC
};

function go(dev) {
  var btns = document.querySelectorAll(".btn");
  var keys = Object.keys(DEVS);
  for (var i = 0; i < btns.length; i++) {
    btns[i].classList.toggle("on", keys[i] === dev);
  }
  var d = DEVS[dev];
  var s = document.getElementById("S");
  s.style.width = d[0] + "px";
  s.style.height = d[1] + "px";
  s.innerHTML = render(dev);
}

go("pp"); // 默认展示 Phone 竖屏
```

#### 可滚动区域规范

```css
.sy {
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: rgba(255, 255, 255, 0.2) transparent;
}
.sy::-webkit-scrollbar {
  width: 3px;
}
.sy::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 2px;
}
```

### 禁止行为

- **禁止**跳过原型直接写 `.ets` 组件
- **禁止**在用户确认前修改任何业务代码
- **禁止**原型与最终实现出现未经确认的视觉差异

### UI 设计资产管理规范

所有原型文件直接在对应版本目录下创建和修改，**不经过根目录中转**。

#### 目录结构

```
design/
└── prototypes/
    ├── v1.0/          # App v1.0 原型（当前版本）
    │   ├── *.html     # 原型文件
    │   └── CHANGELOG.md
    └── v2.0/          # App v2.0 原型（改版时创建）
```

#### 版本与目录对应规则

- 原型文件的存放目录由 **App 版本号**决定：App v1.0 → `design/prototypes/v1.0/`，App v2.0 → `design/prototypes/v2.0/`，以此类推
- **新建原型时直接在对应版本目录下创建**，禁止先放根目录再移动
- 迭代修改也在版本目录内直接进行，不需要中转

#### 版本管理流程

1. **新建原型**：直接在当前 App 版本对应的目录（如 `design/prototypes/v1.0/`）下创建 `<feature>-prototype.html`
2. **迭代修改**：在同一目录内直接修改，直到用户确认
3. **确认锁定**：用户确认后，在 `CHANGELOG.md` 中追加记录（版本号、确认日期、设计规范摘要、文件清单）
4. **改版规则**：需要改版时，在 `design/prototypes/` 下新建下一版本目录（如 `v2.0/`），复制需要改版的文件后修改

#### 锁定规则

- 已确认的原型文件**禁止修改**
- 如需修改已确认的设计，必须在新版本目录中进行，并在 CHANGELOG 中说明变更原因

#### CHANGELOG.md 必填字段

- 版本号与确认日期
- 覆盖的页面/组件列表
- 各设备断点的布局规范摘要
- 文件清单

---

## 二、官方 API 检索规范（最高优先级）

**绝对禁止依赖预训练记忆中的 API 写法。** 凡涉及 HarmonyOS NEXT 官方 API 调用，必须先通过网络搜索官方文档确认后再生成代码。

### 强制执行规则

1. **使用前必查文档**：任何 ArkUI 组件、ArkTS API、系统能力调用，必须先访问 `https://developer.huawei.com/consumer/cn/doc` 确认 API 签名、参数类型、可用版本。
2. **禁止使用废弃 API**：文档中标注 `deprecated` 或 `(deprecated)` 的 API 一律不得使用，必须使用文档推荐的替代方案。
3. **优先使用系统推荐方案**：凡是系统/官方有推荐方案的场景，必须使用推荐方案，禁止自行实现等效功能。
4. **特殊页面才手动处理**：Safe Area、状态栏高度、沉浸式等布局问题，系统原生组件（`Navigation`、`NavDestination` 等）默认已处理，**禁止**在普通页面手动添加 `statusBarHeight` padding 或 `expandSafeArea`，只有有明确需求的特殊页面（如全屏启动页）才允许手动处理。
5. **UI 改动必须先出原型**：任何涉及 UI 布局、视觉风格的改动，必须先输出 HTML 原型并得到用户确认，才能动代码。

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

## 三、三方库 (OHPM) 动态检索规范

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

## 四、多模块架构物理边界规范

本项目采用鸿蒙多模块 (Multi-module) 架构，代码生成和修改必须严格遵守以下边界：

### `core` 模块（底层基础设施）

- **职责**：网络请求 (Network)、数据模型 (Models)、JSON 解析、加密解密 (Crypto)、本地持久化存储 (KVStore/RDB)
- **文件后缀**：只允许 `.ts` 或 `.ets`
- **禁区**：绝对不允许出现任何 ArkUI 组件（`@Component`、`Text`、`Column` 等装饰器或组件）
- **暴露规范**：所有对外提供的类、接口、单例，必须统一在 `core/Index.ets` 中 `export`

### `entry` 模块（UI 与业务展示）

- **职责**：视图渲染、路由跳转 (Navigation + RouterUtil)、UI 状态管理
- **依赖调用**：需要网络或数据能力时，必须从 `core` 模块导入，例如：
  ```typescript
  import { BBSRepository, GenshinRepository } from "core";
  ```
- **禁区**：
  - 严禁直接操作数据库（`RdbManager`、DAO 类、`Row` 模型写入）
  - 严禁直接调用 `ApiService` 网络方法后自己写 DB
  - 严禁判断 `isMock`、`APP_RUNTIME_ENV` 等环境变量做业务分支
  - 唯一例外：`EntryAbility.onCreate` 负责从 `BuildProfile` 读取环境并通过 `CoreInitializer.initCore({ isMock })` 传给 core，这是 entry 唯一感知环境的地方

### 测试隔离

- 所有单元测试必须与业务代码隔离
- 放置在对应模块的 `src/test/` 或 `src/ohosTest/` 目录中
- 编写测试前，必须先按规范一搜索 Hypium 最新规范后再生成测试用例

---

## 五、日志规范

**禁止**在任何业务代码中直接使用 `console.log` / `console.info` / `console.warn` / `console.error`。

必须使用项目统一的 `Logger` 工具类：

```typescript
import { Logger } from "../utils/Logger";

// 正确用法
Logger.info("TagName", "message");
Logger.warn("TagName", "message");
Logger.error("TagName", "message");
Logger.debug("TagName", "message");

// 携带上下文（推荐，便于定位代码位置）
Logger.info("Home", "card tapped", Logger.ctx("Home.ets", "onCardTap", 42));
```

`Logger` 位于 `entry/src/main/ets/utils/Logger.ets`，已实现环境感知（Mock/Release）、统一格式化、序列号等能力。

---

## 六、UI 组件选用规范

**优先级：系统原生组件 > 自定义组件。禁止使用 `@kit.UIDesignKit` 中的 Hds 系列组件。**

### 原则

- 凡是 ArkUI 有对应系统组件的场景，**必须**使用系统组件，禁止用 `Text` / `Row` / `Column` 加 `.onClick` 模拟交互控件
- 只有系统组件确实无法满足需求时，才允许自定义

### 常见映射

| 场景         | 正确做法                                               | 禁止做法                   |
| ------------ | ------------------------------------------------------ | -------------------------- |
| 导航根容器   | `Navigation`                                           | 手写自定义导航框架         |
| 子页面根容器 | `NavDestination` + `.title()` + `.hideTitleBar(false)` | 手写 `Row` 模拟 NavBar     |
| 非模态通知   | `promptAction.showToast`                               | 自定义 Toast 或遮罩层      |
| 可点击按钮   | `Button(label)`                                        | `Text(label).onClick(...)` |
| 文本输入     | `TextInput` / `TextArea`                               | 自定义输入框               |
| 加载指示器   | `LoadingProgress()`                                    | 自定义动画                 |
| 环形进度     | `Progress({ type: ProgressType.Ring })`                | 自定义 Canvas              |
| 二维码       | `QRCode(url)`                                          | 第三方库或 Canvas          |
| 下拉选择     | `Select(options)`                                      | 自定义弹层                 |
| 对话框       | `promptAction.openCustomDialog` / `AlertDialog`        | 手写遮罩层                 |

### 标题栏规范

#### 二级页（通过 push 跳转）

页面组件自身包含 `NavDestination`，通过 `.title()` 设置标题，`.hideTitleBar(false)` 显示系统标题栏：

```typescript
// AccountDetail.ets — 标准写法
build() {
  NavDestination() {
    // 页面内容
  }
  .title($r('app.string.account_detail_title'))
  .hideTitleBar(false)
  .onReady((ctx: NavDestinationContext) => {
    this.localStack = ctx.pathStack
  })
}
```

Builder 文件只做透传，不包 NavDestination：

```typescript
// XxxBuilder.ets
@Builder
export function XxxBuilder(_name: string, _param: Object) {
  Xxx()
}
```

#### Tab 子页（Home、Characters、My）

由 `Main.ets` 的 `Navigation` 统一管理标题栏，Tab 页组件本身不包含 `NavDestination`。

### Button 字体设置

`ButtonAttribute` **没有** `.font()` 方法，设置字体必须拆开写：

```typescript
// 错误 — ButtonAttribute 不支持 .font()
Button(label).font(this.tm.current.body13);

// 正确 — 拆开用 .fontSize() + .fontWeight()
Button(label)
  .fontSize(this.tm.current.body13.size)
  .fontWeight(this.tm.current.body13.weight)
  .fontColor(this.tm.current.colorTextPrimary);
```

---

## 七、路由规范

本项目使用系统原生 `Navigation` + `NavPathStack` 作为路由框架。**禁止**使用 `@hadss/hmrouter`、系统 `router` 模块或直接操作 `NavPathStack`。

### 页面分层：哪些页面需要 Builder，哪些不需要

**需要 Builder（通过路由 push/replace 跳转的页面）：**

| 页面                   | 类型                        | Builder 文件                        |
| ---------------------- | --------------------------- | ----------------------------------- |
| Launch                 | 启动页（全屏，无 TitleBar） | `LaunchBuilder.ets`                 |
| Main                   | 主框架（全屏，无 TitleBar） | `MainBuilder.ets`                   |
| Login                  | 二级页（有系统 TitleBar）   | `LoginBuilder.ets`                  |
| GenshinDailyDetail     | 二级页（有系统 TitleBar）   | `GenshinDailyDetailBuilder.ets`     |
| GenshinCharacterDetail | 二级页（有系统 TitleBar）   | `GenshinCharacterDetailBuilder.ets` |
| AccountDetail          | 二级页（有系统 TitleBar）   | `AccountDetailBuilder.ets`          |

**不需要 Builder（Tab 子页，由 Main 的 Navigation 直接渲染）：**

| 页面       | 原因                                      |
| ---------- | ----------------------------------------- |
| Home       | `Main` 内 `Navigation` 直接渲染，不走路由 |
| Characters | `Main` 内 `Navigation` 直接渲染，不走路由 |
| My         | `Main` 内 `Navigation` 直接渲染，不走路由 |

**判断规则**：凡是通过 `NavPathStack.pushPathByName` 跳转的页面，必须有 Builder；凡是作为 Tab 子页被父组件直接渲染的页面，不需要 Builder，也不需要在 `custom_router_map.json` 中注册。

### 页面 UI 标准

#### 全屏页（Launch、Main）

- `NavDestination` 设置 `.hideTitleBar(true)`
- 加 `.ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])`
- 自行管理沉浸式，不加 `statusBarHeight` padding

#### 二级页（通过 push 跳转，有系统 TitleBar）

页面组件自身包含 `NavDestination`，Builder 只做透传：

```typescript
// Xxx.ets — 页面组件包含 NavDestination
build() {
  NavDestination() {
    // 页面内容
  }
  .title($r('app.string.xxx_title'))
  .hideTitleBar(false)
  .onReady((ctx: NavDestinationContext) => {
    this.localStack = ctx.pathStack
  })
}

// XxxBuilder.ets — Builder 只做透传
@Builder
export function XxxBuilder(_name: string, _param: Object) {
  Xxx()
}
```

#### Tab 子页（Home、Characters、My）

- `Main.ets` 内部 `Navigation` 统一管理标题栏
- Tab 页组件本身不包含 `NavDestination`，不需要 Builder，不需要注册 `custom_router_map.json`

### 路由 Path 管理

所有路由 path 字符串必须统一在 `entry/src/main/ets/constants/AppRoutes.ets` 中声明为常量，**禁止**在页面文件中直接写 path 字符串字面量。

```typescript
export class AppRoutes {
  static readonly LAUNCH = "Launch";
  static readonly MAIN = "Main";
  static readonly LOGIN = "Login";
  // 新增路由页面时在此处添加
}
```

### 跳转用法

```typescript
import { AppRoutes } from "../constants/AppRoutes";

this.stack.pushPathByName(AppRoutes.LOGIN, null); // push，保留返回栈
this.stack.replacePathByName(AppRoutes.MAIN, null); // replace，不保留返回栈
this.stack.pop(); // 返回上一页
this.stack.pushPathByName(AppRoutes.ACCOUNT_DETAIL, param); // 携带参数
```

### 新增路由页面完整流程

1. 在 `AppRoutes.ets` 中添加路由常量
2. 在 `entry/src/main/ets/pages/` 下新建 `Xxx.ets`，页面组件自身包含 `NavDestination`
3. 在 `entry/src/main/ets/pages/router/` 下新建 `XxxBuilder.ets`（只做透传）
4. 在 `entry/src/main/resources/base/profile/custom_router_map.json` 中注册：
   ```json
   {
     "name": "Xxx",
     "pageSourceFile": "src/main/ets/pages/router/XxxBuilder.ets",
     "buildFunction": "XxxBuilder"
   }
   ```
5. 在 `Main.ets` 的 `allDetailBuilder` 中添加 `else if` 分支并补充 import

> **注意**：`@Builder` 函数内只能写 UI 组件语法，不能有变量声明或 Map 查找，用 `if/else if` 链分发。

---

## 八、硬编码规范

### 文字字符串

所有用户可见的文字必须通过多语言资源引用，**禁止**在 `.ets` 文件中直接写中文或英文字符串字面量：

```typescript
// 错误
Text("战绩工具");

// 正确
Text($r("app.string.home_title"));
```

字符串资源文件位于 `entry/src/main/resources/base/element/string.json`。

### 数值

所有尺寸、间距、圆角等数值必须从 `ThemeManager.current` 读取，**禁止** hard code：

```typescript
// 错误
.height(56)
.borderRadius(12)

// 正确
.height(this.tm.current.heightNavBar)
.borderRadius(this.tm.current.radius12)
```

如需新增 token，在 `AppTheme.ets` 接口中声明，在 `DefaultTheme.ets` 中赋值。**如果 Theme 中没有合适的 token，必须先新增 token，再使用，禁止直接写字面量。**

> 例外：`layoutWeight(n)` 是 ArkUI flex 权重，不是设计 token，允许直接写数字（通常为 `1`）。

### 多语言字符串

所有用户可见的文字必须通过多语言资源引用。**如果 `base/element/string.json` 和 `zh_HK/element/string.json` 中没有对应的 key，必须先添加，再使用，禁止直接写字符串字面量。**

多语言文件位置：

- `entry/src/main/resources/base/element/string.json` — 默认（简体中文）
- `entry/src/main/resources/zh_HK/element/string.json` — 繁体中文
- `entry/src/main/resources/en/element/string.json` — 英文

新增 key 时，三个文件必须同步添加。

---

## 七、Mock / Real 网络切换规范

本项目通过 **source set 替换** 实现 Mock 与真实网络的切换，两者除数据来源不同外，对上层完全透明。

### 机制说明

| source set | `APP_RUNTIME_ENV` | `CoreInitializer.isMock` | 网络实现                                          |
| ---------- | ----------------- | ------------------------ | ------------------------------------------------- |
| `mock`     | `"Mock"`          | `true`                   | 各游戏 MockService（读本地 rawfile/mock/\*.json） |
| `release`  | `"Release"`       | `false`                  | 各游戏 ApiService（真实 Axios 请求）              |
| `main`     | `"Other"`         | `false`                  | 各游戏 ApiService                                 |

- `entry/src/mock/ets/config/RuntimeConfig.ets` → `APP_RUNTIME_ENV = 'Mock'`
- `entry/src/release/ets/config/RuntimeConfig.ets` → `APP_RUNTIME_ENV = 'Release'`
- `EntryAbility.onCreate` 调用 `CoreInitializer.initCore({ isMock, context })`
- `MihoyoApiServiceFactory` 根据 `MihoyoEnvironment` 创建对应的 Service 实例并注入到 Repository

### 规则

- **禁止**在 ViewModel / Repository / 页面中直接判断 `isMock` 或 `APP_RUNTIME_ENV`
- 所有网络调用必须通过对应的 Repository（`BBSRepository`、`GenshinRepository` 等），不得直接 `new` Service 实例
- Mock 数据文件放在 `core/src/main/resources/rawfile/mock/account{N}/`，文件名规则：URL 路径中 `/` 替换为 `_`，如 `/game_record/app/genshin/api/dailyNote` → `game_record_app_genshin_api_dailyNote.json`

---

## 八、应用架构规范（MVVM）

本项目采用 **ArkUI MVVM** 分层架构，严格按以下分层组织代码：

```
entry/src/main/ets/
├── pages/          # View 层 — 只负责渲染，不含业务逻辑
├── components/     # View 层 — 可复用 UI 组件
├── viewmodel/      # ViewModel 层 — UI 状态 + 业务逻辑调用
└── ...

core/src/main/ets/
├── repository/  # Model 层 — 数据访问（网络 + 本地 DB）
├── network/     # 网络基础设施（Service + HeaderBuilder + DSUtil）
└── database/    # 数据库基础设施（RdbManager + DAO）
```

### 各层职责

**View 层（pages / components）**

- 只做 UI 渲染，不含任何业务逻辑
- 通过 `@Param` 接收 ViewModel 实例，调用其方法触发状态变更
- 禁止在 View 层直接调用 Repository 或 NetworkFactory

**ViewModel 层（entry/src/main/ets/viewmodel/）**

- 每个页面对应一个 ViewModel 文件，命名规则：`XxxViewModel.ets`
- 用 `@ObservedV2` 装饰 ViewModel 类，用 `@Trace` 装饰所有需要驱动 UI 更新的字段
- 持有 UI 状态（viewState、列表数据、加载状态、错误信息等）
- 调用 `core` 的 Repository 获取/写入数据
- 不得包含任何 ArkUI 组件代码

```typescript
// 标准 ViewModel 模板
@ObservedV2
export class HomeViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace accounts: MihoyoAccountVM[] = [];
  @Trace isRefreshing: boolean = false;

  async loadData(): Promise<void> {
    // 调用 Repository，更新 @Trace 字段驱动 UI
  }
}
```

**Model 层（core/src/main/ets/repository/）**

- `BBSRepository`：账号和游戏角色（独立，不继承 `GameRepository`）
- `GenshinRepository`、`StarRailRepository`、`ZZZRepository`：各游戏数据，继承 `GameRepository`
- `SignRepository`：签到功能
- 所有数据访问必须通过 Repository，禁止在 ViewModel 中直接调用 DAO 或 Service

### ViewModel 在 View 中的使用方式

```typescript
@ComponentV2
export struct Home {
  // ViewModel 作为 @Local 持有，生命周期与组件绑定
  @Local private vm: HomeViewModel = new HomeViewModel()

  aboutToAppear(): void {
    this.vm.loadData()
  }

  build() {
    // 直接读取 vm.viewState、vm.accounts 等 @Trace 字段
    // @Trace 变更自动触发 UI 刷新
  }
}
```

### 新增页面流程

1. 在 `entry/src/main/ets/viewmodel/` 下新建 `XxxViewModel.ets`
2. 在 `entry/src/main/ets/pages/` 下新建 `Xxx.ets`（View 层）
3. 在 `AppRoutes.ets` 中添加路由常量
4. 在 `entry/src/main/ets/pages/router/` 下新建 `XxxBuilder.ets`
5. 在 `custom_router_map.json` 中注册路由条目
6. 在 `Index.ets` 的 `builderMap` 中添加 `wrapBuilder` 注册并补充 import

---

## 九、国际服（HoYoLAB）完成度追踪

| 功能模块     | 完成度 | 说明                                                                               |
| ------------ | ------ | ---------------------------------------------------------------------------------- |
| 手机号登录   | 0%     | 接口路径待确认，占位在 `AuthRepository.ets` 末尾注释                               |
| 二维码登录   | 0%     | 接口路径待确认                                                                     |
| Cookie 登录  | 0%     | 逻辑与国服相同，但 Cookie 字段名可能不同                                           |
| 游戏角色查询 | 0%     | 预计接口：`https://bbs-api-os.hoyolab.com/game_record/card/wapi/getGameRecordCard` |
| UI 展示      | 0%     | 暂不在登录页展示国际服入口，待国服稳定后再开放                                     |

**后续开发国际服时的步骤：**

1. 确认 HoYoLAB 各接口路径和参数（参考 UIGF-org/mihoyo-api-collect 国际服文档）
2. 在 `MihoyoAccountApiService` 中新增国际服登录方法
3. 在 `MihoyoDomain` 枚举中添加国际服 BaseURL 常量
4. 在 `Login.ets` 的 Tab 栏增加"国际服"入口（或独立页面）
5. 更新本文档完成度

---

## 十、AI 回复语言规范

**所有回复必须使用简体中文。**

- 无论用户用何种语言提问，AI 的回复、解释、注释说明一律使用简体中文
- 代码注释也应使用简体中文
- 禁止在回复中出现纯英文段落或其他语言段落（代码块内的英文标识符、API 名称除外）

---

## 十一、修改文件后的影响范围检查规范（必须遵守）

**每次修改任何文件后，必须立即执行以下检查，不得跳过。**

### 检查步骤

1. **诊断修改的文件本身**
   使用 `getDiagnostics` 工具检查被修改的文件，确认无 ERROR / WARN。

2. **搜索所有引用方**
   使用 `grepSearch` 搜索被修改的符号名（类名、函数名、导出名等），找出所有 import 或调用该符号的文件。

3. **诊断所有引用方**
   对第 2 步找到的每个引用文件，同样用 `getDiagnostics` 检查，确认没有因本次修改引入新的 ERROR / WARN。

4. **修复发现的问题**
   若发现任何 ERROR 或 WARN，必须在当前轮次内修复，不得留到下一轮。

### 典型场景

| 修改类型                   | 必须额外检查的内容                        |
| -------------------------- | ----------------------------------------- |
| 删除或重命名导出符号       | 所有 `import { 旧符号名 }` 的文件         |
| 修改函数/方法签名（参数）  | 所有调用该函数的文件                      |
| 修改 class 字段名或类型    | 所有实例化或访问该字段的文件              |
| 新增必填参数               | 所有调用处，确认已传入新参数              |
| 修改 interface / type 定义 | 所有实现该 interface 或使用该 type 的文件 |

### 示例流程

```
// 修改了 NetworkFactory.ts，删除了 apiService 导出
1. getDiagnostics(['core/src/main/ets/network/NetworkFactory.ets'])
2. grepSearch('apiService', includePattern='**/*.ets')
3. getDiagnostics(['core/.../GeetestService.ets', 'core/.../AuthRepository.ets', ...])
4. 发现 AuthRepository 还有 2 处 apiService 引用 → 立即修复
5. 再次 getDiagnostics 确认全部通过
```

**禁止**在未完成上述检查的情况下，向用户报告"修改完成"或"编译应该通过"。

---

## 十二、UI 组件文件拆分规范

**禁止**在 page 文件中内联定义 `@ComponentV2` struct，每个组件必须有独立的 `.ets` 文件。

### 目录结构规则

```
entry/src/main/ets/components/
├── home/           # Home 页面专属组件
│   ├── UserGameSection.ets
│   ├── HomeSkeletonView.ets
│   └── HomePlaceholderView.ets
├── characters/     # Characters 页面专属组件
│   ├── CharacterCard.ets
│   ├── CharactersSkeleton.ets
│   └── GameTabBar.ets
├── dailynote/      # DailyNote 相关组件
│   └── DailyNoteGenshin.ets
└── GeetestDialog.ets  # 跨页面通用组件，放根目录
```

- 某个组件**只在一个页面使用** → 放在 `components/<页面名小写>/` 子目录
- 某个组件**跨多个页面复用** → 放在 `components/` 根目录
- 新增页面时，同步创建对应的 `components/<页面名>/` 目录

---

## 十三、ViewModel 状态枚举规范

**禁止**用字符串字面量 `type` 定义 ViewModel 状态，必须使用 `enum`。

### ViewState 枚举

所有页面的 `viewState` 统一使用 `entry/src/main/ets/constants/ViewStates.ets` 中的 `ViewState` enum：

```typescript
import { ViewState } from "../constants/ViewStates";

@ObservedV2
export class XxxViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
}
```

View 层比较状态时同样使用 enum：

```typescript
// 正确
if (this.vm.viewState === ViewState.DATA) { ... }

// 错误 — 字符串字面量，拼写错误不会报编译错误
if (this.vm.viewState === 'data') { ... }
```

`ViewState` 包含四个值：`LOADING` / `EMPTY` / `DATA` / `ERROR`，覆盖绝大多数页面场景。如需扩展，在 `ViewStates.ets` 中添加新值，**禁止**在 ViewModel 文件中另外定义局部 `type` 或 `enum`。

---

## 十四、API 错误码规范

**禁止**在业务代码中直接写 retcode 数字字面量，必须从 `core` 模块的 `ApiErrorCodes` 类引用。

### 文件位置

`core/src/main/ets/constants/ApiErrorCodes.ets`，已通过 `core/Index.ets` 导出。

### 使用方式

```typescript
import { ApiErrorCodes } from 'core';

// 正确
if (msg.indexOf(`retcode=${ApiErrorCodes.GEETEST_REQUIRED}`) !== -1) { ... }
if (resp.retcode !== ApiErrorCodes.SUCCESS) { ... }

// 错误 — 魔法数字，含义不明且难以维护
if (msg.indexOf('retcode=10035') !== -1) { ... }
```

### 新增错误码规则

遇到新的 retcode 时，必须先在 `ApiErrorCodes.ets` 中添加带注释的常量，再在业务代码中引用：

```typescript
/** 角色未公开展示战绩 */
static readonly ROLE_NOT_PUBLIC: number = 10102;
```

新增时注明：错误码数值、触发场景、适用游戏（如有）。

---

## 十五、应用级通用常量规范（AppConstants）

**禁止**在组件中直接硬编码 `GridRow` 断点、骨架屏索引等重复字面量，必须从 `AppConstants` 引用。

### 文件位置

`entry/src/main/ets/constants/AppConstants.ets`

### 常量分类规则

| 常量类型                               | 放哪里              | 示例                                       |
| -------------------------------------- | ------------------- | ------------------------------------------ |
| 跨组件复用的断点数组                   | `AppConstants.ets`  | `GRID_BREAKPOINTS`                         |
| 骨架屏占位索引等通用数组               | `AppConstants.ets`  | `SKELETON_CHARACTER_INDICES`               |
| 游戏业务阈值（树脂上限、好感度上限等） | `XxxConstants.ets`  | `GenshinConstants.RESIN_WARNING_THRESHOLD` |
| 路由 path 字符串                       | `AppRoutes.ets`     | `AppRoutes.SETTING`                        |
| API retcode 错误码                     | `ApiErrorCodes.ets` | `ApiErrorCodes.GEETEST_REQUIRED`           |

### ArkTS 严格模式限制

`GridRow` 的 `columns` 参数类型为 `GridRowColumnOption`（ArkUI 内置接口）。ArkTS 严格模式下，对象字面量必须对应已声明的 class 或 interface，**无法**将 `{ xs, sm, md, lg }` 存为 `static readonly` 常量（`object` 类型不被允许）。

因此 `GridRow columns` 列数配置**必须在调用处直接内联**，不要尝试抽到 `AppConstants`：

```typescript
// 正确 — 在 GridRow 调用处直接内联，编译器可推断 GridRowColumnOption
GridRow({
  columns: { xs: 2, sm: 3, md: 4, lg: 5 },
  breakpoints: {
    value: AppConstants.GRID_BREAKPOINTS,   // 断点数组可以抽常量
    reference: BreakpointsReference.WindowSize
  }
})

// 错误 — 无法将 { xs, sm, md, lg } 存为 object 类型常量
static readonly GRID_COLUMNS: object = { xs: 2, sm: 3, md: 4, lg: 5 };  // 编译报错
```

### 使用方式

```typescript
import { AppConstants } from '../constants/AppConstants';

// 断点数组 — 可以抽常量
breakpoints: {
  value: AppConstants.GRID_BREAKPOINTS,
  reference: BreakpointsReference.WindowSize
}

// 骨架屏索引 — 可以抽常量
ForEach(AppConstants.SKELETON_CHARACTER_INDICES, (idx: number) => { ... })
```

### 断点含义

| 区间          | 断点值 | 典型设备              |
| ------------- | ------ | --------------------- |
| xs < 600vp    | —      | 竖屏手机（360-480vp） |
| sm 600-840vp  | 600vp  | 横屏手机 / 小折叠展开 |
| md 840-1200vp | 840vp  | 大折叠展开 / 平板     |
| lg > 1200vp   | 1200vp | PC / 2in1             |

### 新增常量规则

遇到需要在多处使用的固定值时，先判断类型再决定放哪里（见上表），**禁止**在组件或 ViewModel 文件中直接写字面量。

---

## 十六、@Monitor 路径字符串规范

### 作用说明

`@Monitor('vm.fieldName')` 是 ArkUI 的响应式副作用装饰器，监听指定 `@Trace` 字段的变化，字段变更时自动调用被装饰的方法。等价于 Vue 的 `watch`，常用于 View 层响应 ViewModel 的副作用信号（弹窗、跳转等）。

### 必须使用 ViewModel.KEYS 常量

`@Monitor` 路径字符串写错一个字母不会报编译错误，但监听会静默失效，业务逻辑不执行。因此**禁止**在 View 层直接写路径字符串字面量，必须通过 ViewModel 的 `static readonly KEYS` 引用。

**ArkTS 严格模式限制**：`static readonly KEYS = { ... }` 是无类型对象字面量，hvigor 会报 `arkts-no-untyped-obj-literals`。必须先声明一个对应的 class，再用 `new` 实例化：

```typescript
// 第一步：声明 KEYS 类型 class（与 ViewModel 放在同一文件）
export class HomeViewModelKeys {
  networkErrorMsg: string = 'vm.networkErrorMsg';
  geetestTrigger: string = 'vm.geetestTrigger';
}

// 第二步：ViewModel 中用 new 实例化（字符串只在 class 定义处出现一次）
@ObservedV2
export class HomeViewModel {
  static readonly KEYS: HomeViewModelKeys = new HomeViewModelKeys();
  @Trace networkErrorMsg: string = '';
  @Trace geetestTrigger: GeetestTrigger | null = null;
}

// View 层引用常量（写错属性名编译器会报"属性不存在"）
@Monitor(HomeViewModel.KEYS.networkErrorMsg)   // 正确
onNetworkErrorChanged(_monitor: IMonitor): void { ... }

@Monitor('vm.networkErrorMsg')                 // 错误 — 禁止直接写字符串字面量
onNetworkErrorChanged(_monitor: IMonitor): void { ... }
```

### 新增 @Monitor 流程

1. 在 `XxxViewModelKeys` class 中添加新字段（字符串值 `'vm.字段名'`）
2. ViewModel 的 `static readonly KEYS: XxxViewModelKeys = new XxxViewModelKeys()` 自动包含新字段
3. View 层用 `XxxViewModel.KEYS.fieldName` 引用
4. 路径格式固定为 `'vm.字段名'`（`vm` 是 View 层持有 ViewModel 的字段名）

### 字段重命名注意事项

重命名 `@Trace` 字段时，必须同步更新 `KEYS` 中对应的字符串值，编译器不会自动检测字符串内容。

---

## 十七、hvigor 编译器 vs IDE 语言服务差异规范

**hvigor 编译器比 IDE 语言服务（getDiagnostics）更严格。** getDiagnostics 通过不代表 hvigor 能编译通过。

### 已知高风险 API 黑名单

以下 API 在 IDE 不报错，但 hvigor 会编译失败，**禁止使用**：

| 禁止写法                                               | 原因                                      | 替代方案                                   |
| ------------------------------------------------------ | ----------------------------------------- | ------------------------------------------ |
| `GridItemAlignment.Center`                             | 该枚举值在 API 18 不存在                  | 直接删除 `.alignItems()`，使用默认对齐     |
| `Array.from({ length: n })`                            | ArkTS 严格模式禁止                        | 用 `for` 循环手动构建数组                  |
| `Array.map()` / `Array.filter()`                       | ArkTS 严格模式禁止                        | 用 `for` 循环替代                          |
| `import('path').TypeName` 内联类型                     | ArkTS 严格模式禁止                        | 改为顶层 `import { TypeName } from 'path'` |
| `spread` 展开运算符（`...obj`）                        | ArkTS 严格模式禁止                        | 逐字段赋值                                 |
| `in` 操作符                                            | ArkTS 严格模式禁止                        | 改用可选链或显式字段检查                   |
| `unknown` 类型                                         | ArkTS 严格模式禁止                        | 改用具体类型或 `Object`                    |
| 无类型对象字面量 `{ key: val }` 作为 `static readonly` | hvigor 报 `arkts-no-untyped-obj-literals` | 先声明 class，再 `new` 实例化              |
| `throw 'string'`                                       | ArkTS 严格模式只允许抛 Error 实例         | `throw new Error('message')`               |
| 全局 `px2vp()` / `vp2px()` / `getContext()`            | API 12 起废弃                             | `this.getUIContext().px2vp()` 等           |

### 枚举值使用规范

**禁止**凭记忆或 IDE 自动补全使用枚举值，必须先通过官方文档确认枚举的实际成员列表：

```
// 查询方式：
// remote_web_search: site:developer.huawei.com ArkUI <枚举名>
// 然后 webFetch 抓取页面确认枚举成员
```

常见枚举的已知安全值：

| 枚举                   | 安全可用的值                                            |
| ---------------------- | ------------------------------------------------------- |
| `GridItemAlignment`    | `Default`、`Start`、`End`、`Stretch`（无 `Center`）     |
| `BreakpointsReference` | `WindowSize`、`ComponentSize`                           |
| `ImageFit`             | `Contain`、`Cover`、`Auto`、`Fill`、`ScaleDown`、`None` |
| `EdgeEffect`           | `Spring`、`Fade`、`None`                                |
| `BarState`             | `Off`、`Auto`、`On`                                     |

### 编译失败时的排查流程

1. 看 hvigor 报错的文件路径和行号
2. 定位到具体 API 调用
3. 查官方文档确认该 API 在 API 18 的实际签名
4. 修复后重新编译验证

**不要**仅凭 getDiagnostics 通过就认为代码正确，hvigor 是最终裁判。

---

## 十八、业务状态/类型判断必须使用 enum 规范

**禁止**在任何组件、ViewModel、Repository 中用字符串字面量做状态或类型判断。

### 规则

- 凡是需要区分多种状态/类型的场景，必须先定义 `enum`，再用 enum 值做判断
- 拼写错误的字符串字面量不会在编译期报错，enum 会
- 已有 enum 文件位于 `entry/src/main/ets/constants/` 目录

### 已有 enum 清单

| enum 名          | 文件                           | 用途                                                        |
| ---------------- | ------------------------------ | ----------------------------------------------------------- |
| `ViewState`      | `constants/ViewStates.ets`     | 页面加载状态（LOADING/EMPTY/DATA/ERROR）                    |
| `GenshinElement` | `constants/GenshinElement.ets` | 原神元素类型（HYDRO/PYRO/…/UNKNOWN）                        |
| `HeroPanelMode`  | `constants/HeroPanelMode.ets`  | 角色立绘区布局模式（WIDE/PORTRAIT/LANDSCAPE）               |
| `LoginTab`       | `constants/LoginTabEnum.ets`   | 登录方式 Tab（PHONE/QRCODE/COOKIE）                         |
| `PhoneStep`      | `constants/LoginTabEnum.ets`   | 手机号登录步骤（INPUT_PHONE/INPUT_CODE）                    |
| `QRCodeStat`     | `constants/LoginTabEnum.ets`   | 二维码状态（LOADING/READY/SCANNED/CONFIRMED/EXPIRED/ERROR） |

### 字符串 → enum 转换

API 返回的字符串必须在边界处（Repository 或 ViewModel 的 `parseRawJson`）转换为 enum，不得将原始字符串传入 UI 组件：

```typescript
// 错误 — 直接把 API 字符串传给 UI
this.charElement = parsed.element ?? "";

// 正确 — 在 ViewModel 解析时转换
import { GenshinElement, elementFromString } from "../constants/GenshinElement";
this.charElement = elementFromString(parsed.element ?? "");
```

### 新增 enum 流程

1. 在 `entry/src/main/ets/constants/` 下新建 `XxxEnum.ets`
2. 定义 enum 和对应的 `xxxFromString()` 转换函数（如需从 API 字符串转换）
3. 更新本文档的"已有 enum 清单"表格

---

## 十九、linearGradient angle 必须走 Theme Token 规范

**禁止**在任何组件中直接写 `linearGradient` 的 `angle` 数字字面量。

### 规则

所有渐变方向角度必须从 `ThemeManager.current` 读取对应 token：

```typescript
// 错误 — 直接写数字
.linearGradient({ angle: 135, colors: [...] })

// 正确 — 通过 token 引用
.linearGradient({ angle: this.tm.current.gradientAngle135, colors: [...] })
```

### 已有 angle token 清单

| token 名           | 值   | 典型用途                  |
| ------------------ | ---- | ------------------------- |
| `gradientAngle0`   | 0°   | 底部遮罩（从下到上渐变）  |
| `gradientAngle90`  | 90°  | 左右遮罩（从左到右渐变）  |
| `gradientAngle135` | 135° | 元素背景渐变（左上→右下） |
| `gradientAngle150` | 150° | Phone 背景渐变            |
| `gradientAngle180` | 180° | 上下遮罩（从上到下渐变）  |

### 新增角度 token 流程

1. 在 `AppTheme.ets` 的 `Size` 接口末尾添加声明（如 `gradientAngle45: number`）
2. 在 `DefaultTheme.ets` 中赋值
3. 更新本文档的"已有 angle token 清单"表格

---

## 二十、代码修改后的构建与运行规范

**每次修改代码后，必须按以下顺序执行，不得跳过任何步骤。**

### 标准流程

使用 `executeBash` 工具依次执行以下命令（不得使用 `controlBashProcess` 的后台进程，必须等待每步完成）：

```bash
# 1. 构建 mock 包
export DEVECO_SDK_HOME='/Applications/DevEco-Studio.app/Contents/sdk'
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleHap -p product=mock
```

```bash
# 2. 安装到模拟器
/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc -t 127.0.0.1:5555 install entry/build/mock/outputs/mock/entry-mock-unsigned.hap
```

```bash
# 3. 启动 App
/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc -t 127.0.0.1:5555 shell aa start -b com.cainluo.mihoyo.tools.mock -a EntryAbility
```

**必须等待每步命令返回结果后再执行下一步。** 如果构建失败，立即根据错误信息修复，不得跳过。

### 目标设备

- 模拟器：**Mate 80 Pro Max**
- 连接地址：`127.0.0.1:5555`
- Bundle ID（mock）：`com.cainluo.mihoyo.tools.mock`

### 禁止行为

- **禁止**使用 `controlBashProcess` 后台运行构建（无法获取真实输出，会误报成功）
- **禁止**使用 `-p buildMode=mock`（正确参数是 `-p product=mock`）
- **禁止**跳过安装步骤直接启动（旧版本仍在运行）

---

## 二十一、游戏支持范围规范

### 当前支持的游戏

本项目 UI 层只展示以下三款游戏的数据：

| 游戏           | `GameId`          | 状态        |
| -------------- | ----------------- | ----------- |
| 原神           | `GameId.GENSHIN`  | ✅ 支持     |
| 崩坏：星穹铁道 | `GameId.STARRAIL` | ✅ 支持     |
| 绝区零         | `GameId.ZZZ`      | ✅ 支持     |
| 崩坏3          | `GameId.HONKAI3`  | ⏳ 暂不支持 |

### 过滤机制

**数据库层**：所有游戏角色数据（包括崩坏3）全部写入 DB，不做过滤。

**读取层**：`BBSRepository.getGameRoles()` 只返回 `GameId.SUPPORTED` 列表中的游戏角色，其他游戏的数据不会传递给 entry 层。

### 控制入口

`core/src/main/ets/constants/GameId.ets` 中的 `SUPPORTED` 数组：

```typescript
static readonly SUPPORTED: string[] = [
  GameId.GENSHIN,
  GameId.STARRAIL,
  GameId.ZZZ,
];
```

### 启用新游戏的步骤

1. 在 `GameId.SUPPORTED` 数组中添加对应的 `GameId`
2. 实现对应的 `XxxApiService`、`XxxMockService`、`XxxRepository`、`XxxParser`
3. 在 `MihoyoApiServiceFactory` 中注册新 Service
4. 在 `SyncQueueRunner.buildTasksForRoles` 中添加同步任务
5. 在 entry 层添加对应的 UI 组件（角色卡片、便笺组件等）
6. 更新 README.md 的功能说明

### 禁止行为

- **禁止**在 entry 层（ViewModel / 页面 / 组件）直接过滤 `gameId`，过滤逻辑统一在 `BBSRepository.getGameRoles()` 中
- **禁止**在 DB 写入时过滤游戏数据，保持数据完整性
