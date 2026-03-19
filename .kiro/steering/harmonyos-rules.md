# HarmonyOS 项目开发规范

## 零、项目 API 版本信息

- **本项目目标平台**：HarmonyOS NEXT 6.0.2，对应 **API 18+**
- **ArkTS 严格模式**已启用，编译器比 IDE 语言服务更严格

### 已废弃 API 替换规则（必须遵守）

| 废弃写法               | 替代写法                               | 可用起始版本 |
| ---------------------- | -------------------------------------- | ------------ |
| 全局 `px2vp(n)`        | `this.getUIContext().px2vp(n)`         | API 12+      |
| 全局 `vp2px(n)`        | `this.getUIContext().vp2px(n)`         | API 12+      |
| 全局 `getContext()`    | `this.getUIContext().getHostContext()` | API 12+      |
| `@Component`           | `@ComponentV2`                         | API 12+      |
| `@State` / `@Observed` | `@Local` / `@ObservedV2` + `@Trace`    | API 12+      |

**注意**：`UIContext` 必须在 `aboutToAppear()` 里通过 `this.getUIContext()` 获取并缓存到实例变量，不能在回调或异步函数中直接调用 `this.getUIContext()`。

---

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

---

## 四、日志规范

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

## 五、路由规范

本项目使用 `@hadss/hmrouter`（HMRouter）作为路由框架，**禁止**使用系统原生 `router` 或 `Navigation` 直接跳转。

### 路由 Path 管理

所有路由 path 字符串必须统一在 `entry/src/main/ets/constants/AppRoutes.ets` 中声明为常量，**禁止**在页面文件中直接写 path 字符串字面量。

```typescript
// AppRoutes.ets
export class AppRoutes {
  static readonly MAIN = "Main";
  static readonly LOGIN = "Login";
  static readonly SETTING = "Setting";
  // 新增页面时在此处添加
}
```

### 跳转用法

```typescript
import { HMRouterMgr } from "@hadss/hmrouter";
import { AppRoutes } from "../constants/AppRoutes";

// 跳转
HMRouterMgr.push({ pageUrl: AppRoutes.SETTING });

// 返回
HMRouterMgr.pop();
```

### 新增页面流程

1. 在 `AppRoutes.ets` 中添加路由常量
2. 在 `entry/src/main/ets/pages/router/` 下新建对应的 `XxxBuilder.ets`
3. 在 `Index.ets` 中 `import` 新页面（触发 HMRouter 注册）

---

## 六、硬编码规范

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

| source set | `APP_RUNTIME_ENV` | `CoreInitializer.isMock` | 网络实现                                     |
| ---------- | ----------------- | ------------------------ | -------------------------------------------- |
| `mock`     | `"Mock"`          | `true`                   | `MockService`（读本地 rawfile/mock/\*.json） |
| `release`  | `"Release"`       | `false`                  | `HttpService`（真实 Axios 请求）             |
| `main`     | `"Other"`         | `false`                  | `HttpService`                                |

- `entry/src/mock/ets/config/RuntimeConfig.ets` → `APP_RUNTIME_ENV = 'Mock'`
- `entry/src/release/ets/config/RuntimeConfig.ets` → `APP_RUNTIME_ENV = 'Release'`
- `EntryAbility.onCreate` 读取 `Logger.getRuntimeEnv()` 后调用 `CoreInitializer.initCore({ isMock, context })`
- `NetworkFactory.getInstance()` 根据 `CoreInitializer.getIsMock()` 返回 `MockService` 或 `HttpService`

### 规则

- **禁止**在 ViewModel / Repository / 页面中直接判断 `isMock` 或 `APP_RUNTIME_ENV`
- 所有网络调用必须通过 `NetworkFactory.getInstance()` 获取 `BaseApiService`，不得直接 `new HttpService()` 或 `new MockService()`
- Mock 数据文件放在 `core/src/mockFiles/`（rawfile 目录），文件名规则：URL 路径中 `/` 替换为 `_`，如 `/genshin/character/list` → `genshin_character_list.json`

---

## 八、应用架构规范（MVVM）

本项目采用 **ArkUI V2 MVVM** 分层架构，严格按以下分层组织代码：

```
entry/src/main/ets/
├── pages/          # View 层 — 只负责渲染，不含业务逻辑
├── components/     # View 层 — 可复用 UI 组件
├── viewmodel/      # ViewModel 层 — UI 状态 + 业务逻辑调用
└── ...

core/src/main/ets/
├── repository/     # Model 层 — 数据访问（网络 + 本地 DB）
├── network/        # 网络基础设施
└── database/       # 数据库基础设施
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
  @Trace viewState: HomeViewState = "loading";
  @Trace accounts: MihoyoAccountVM[] = [];
  @Trace isRefreshing: boolean = false;

  async loadData(): Promise<void> {
    // 调用 Repository，更新 @Trace 字段驱动 UI
  }
}
```

**Model 层（core/src/main/ets/repository/）**

- 已有 `CharacterRepository`、`ActivityRepository`、`GachaRepository`
- 所有数据访问必须通过 Repository，禁止在 ViewModel 中直接调用 DAO 或 NetworkFactory

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
5. 在 `Index.ets` 中 `import` 新页面触发 HMRouter 注册

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
2. 在 `AuthRepository.ets` 中实现 `// TODO: 国际服占位` 下方的方法
3. 在 `ApiConfig.ets` 中添加国际服 BaseURL 常量
4. 在 `Login.ets` 的 Tab 栏增加"国际服"入口（或独立页面）
5. 更新本文档完成度
