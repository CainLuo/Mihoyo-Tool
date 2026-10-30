# ArkTS 命名规范

> **适用范围**：`entry/src/main/ets/**`、`entry/src/test/**`、`features/*/src/main/ets/**`、`common/*/src/main/ets/**`
> **制定日期**：2026-10-28
> **依据**（按优先级）：
> 1. OpenHarmony《ArkTS 编程规范》命名章节（[arkts-coding-style-guide](https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/quick-start/arkts-coding-style-guide.md)）——标识符命名的唯一官方成文规则
> 2. OpenHarmony《资源分类与访问》（[resource-categories-and-access](https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/quick-start/resource-categories-and-access.md)）——资源目录与限定词
> 3. OpenHarmony 官方 codelabs 的工程结构（ArkTSComponents、TargetManagement、SecondLevelLinkage、MultipleDialog、Preferences、RankingDemo、SwiperArkTS 七个示例）与 DevEco 新建工程模板——文件名、目录名的事实惯例（官方规范对文件名 / 目录名没有成文规定）
> 4. `.opencode/skills/harmonyos-development` 的 *Naming conventions* 表（摘自规范 1）
>
> 规范 1 中除"为标识符取一个好名字"外均为**建议**级别；本项目一律按**规则**执行。

---

## 1. 标识符

| 对象 | 规则 | 正例 | 反例 | 来源 |
| --- | --- | --- | --- | --- |
| 通用 | 意图清晰；不用单字母（循环下标、`_` 忽略参数除外）、非标准缩写、拼音 | `userName` | `un`、`yongHu` | 规范 1 |
| 类、struct、interface、enum、命名空间、类型别名 | UpperCamelCase；类名用名词 / 名词短语；避免 `Data`、`Info` 等模糊词 | `PreviewStamina`、`HeroSummary` | `PreviewStaminaData`、`FormInfo` | 规范 1 |
| 变量、参数、属性、方法、函数 | lowerCamelCase | `userName` | `user_name` | 规范 1 |
| 方法 / 函数名 | 动词或动词短语：`get/set/load/save/is/has/build/parse/format/…` + 宾语；取值类方法用 `getXxx` | `getGameName(gameId)`、`getResinColor()` | `gameIdToName(gameId)`、`resinColor()` | 规范 1 |
| 常量（`const` 原始值 / 冻结配置、`static readonly` 常量） | UPPER_SNAKE_CASE，表达完整语义 | `MAX_USER_SIZE`、`FONT_MEDIUM_17` | `font17`、`maxSize` | 规范 1 |
| 枚举值 | UPPER_SNAKE_CASE（数字段之间的字母也大写） | `SIZE_2X2` | `SIZE_2x2` | 规范 1 |
| 布尔变量 / 属性 / 返回布尔的方法 | `is` / `has` / `can` / `should` 前缀；不用否定式 | `isCollapsed`、`hasPageLoaded`、`isEmpty()` | `collapsed`、`showNoStokenDialog` | 规范 1 |
| 单例对象实例（`export const x = new X()`） | 视为变量，lowerCamelCase | `themeManager` | — | 本项目约定（规范 1 第 4 条针对"常量值"，对象实例按变量处理） |

## 2. 文件与目录

| 对象 | 规则 | 正例 | 来源 |
| --- | --- | --- | --- |
| 目录 | 全小写单词直接拼接，不用连字符 / 下划线 | `materialcalc`、`chardetail`、`entryability` | 规范 3（官方示例 `viewmodel`、`entryability`、DevEco 模板） |
| `.ets` 文件 | UpperCamelCase；只有一个主类型时与主类型同名 | `ViewState.ets` 导出 `ViewState` | 规范 3 |
| 页面（`pages/`，含 `@Entry` 或被 routerMap 指向） | `XxxPage.ets`，主 struct 同名 `XxxPage`；`Index.ets` 为模板入口，保留 | `HomePage.ets`、`MaterialCharacterSelectPage.ets` | 规范 3（`LoginPage` / `MainPage` / `HomePage` / `IndexPage` / `RankPage`） |
| 页面 Builder 函数 | `XxxPageBuilder`（与页面 struct 对应） | `HomePageBuilder` | 本项目约定（routerMap `buildFunction`） |
| ViewModel | `XxxViewModel.ets` | `HomeViewModel.ets` | 规范 3 |
| 常量集合 | `XxxConstants.ets` | `LoginConstants.ets` | 规范 3（`CommonConstants` / `StyleConstants`） |
| 模型集合 | `XxxModels.ets`；单一模型与类名同名 | `HomeModels.ets` | 规范 3（`DataModel`、`ClassifyModel`） |
| 函数集合（工具） | `XxxUtil.ets` | `GameIdUtil.ets` | 规范 3（`DateUtil` / `CommonUtils`）；本项目已有 `XxxUtil` 占多数，统一单数 |
| 日志类 | `utils/XxxLogger.ets`，与类同名 | `WidgetLogger.ets` | 官方 codelabs 仓库 `utils/Logger.ets` 28 处（2026-10-29 统计 openharmony/codelabs） |
| 数据 / 业务服务类（Store、Manager、Builder、Service、Calculator 等有状态或访问存储 / 网络的类） | `model/service/`，与类同名 | `WidgetConfigStore.ets`、`NotificationSettingsStore.ets` | 官方 MVVM：Model 层负责数据与业务；本项目各 feature 统一放 `model/service/` |
| 懒加载数据源（`IDataSource` 实现） | `viewmodel/XxxDataSource.ets` | `CharacterDataSource.ets` | 官方 codelab MultiDeviceMusic：`viewmodel/SongDataSource.ets` |
| 一个页面的路由 Builder | 写在页面文件末尾（`// ─── Router Builder ───`），不单独成文件 | `HomePageBuilder` 在 `HomePage.ets` | 本项目统一写法 |
| 测试 | `<被测文件名>.test.ets` | `HomeViewModel.test.ets` | `testing-quality` skill 铁律 1 |

## 3. 资源

| 对象 | 规则 | 来源 |
| --- | --- | --- |
| 限定词目录 | 按官方：语言小写、文字首字母大写、地区大写，`-` 连接（现状已符合） | 规范 2 |
| `element` 文件名 | `string.json` / `color.json` / … 官方固定名称 | 规范 2 |
| 资源 `name`、`media` 文件名 | 小写 snake_case | 规范 2 的全部示例 |
| 例外 | DevEco 模板生成的 `EntryAbility_desc` / `EntryAbility_label` 及其它 Ability 同名资源、`startIcon.png` 保留模板写法 | DevEco 模板 |

## 4. 不改名的名字（改了会破坏兼容或运行时匹配）

| 类别 | 说明 |
| --- | --- |
| 路由名字符串 | `AppRoutes` 常量的**值**（`'Home'`、`'Login'`…）与 routerMap `name` 对应；只改常量名的写法不改值 |
| 持久化 key 的值 | Preferences store 名与 key（如 `'mihoyo_tool_preferences'`、`'hasAgreedPrivacy'`、`'enabled'`）、AppStorageV2 key 字符串；改名只改承载它们的常量 / 字段名 |
| 外部数据字段 | 对应接口 JSON 的字段（如 `avatar_id`、`is_unlocked`、`point_id`）；`widget/` 中 `JSON.stringify` 存盘或跨进程传给卡片的模型字段（`WidgetDataStore` / `WidgetConfig` / `WidgetModels` / payload） |
| 框架 / 接口规定的名字 | 生命周期与回调（`aboutToAppear`、`onCreate`…）、`IDataSource` 方法（`totalCount`、`getData`、`registerDataChangeListener`…）、`marshalling` / `unmarshalling`、日志 API（`info` / `warn` / `error` / `debug`） |
| `@Builder` 函数 | ArkUI 惯例为名词（`xxxBuilder`），保留 |
| `_` 前缀的忽略参数 | 按 codeLinter `argsIgnorePattern: "^_"` 约定保留 |
| `widget/pages/` 卡片 UI | 服务卡片不是导航页面（官方卡片模板为 `WidgetCard.ets`），不加 `Page` 后缀；`form_config.json` 引用其路径 |
| 转换惯用法 | `toXxx()`（实例 → 表示，如 `toJson`、`toVM`）与静态工厂 `fromXxx()` 视同动词，与标准库 `toString()` / `Array.from()` 一致 |
| core 模块导出的名字 | 不在 entry 作用域 |

## 5. 改名时的联动

- `@Monitor('vm.xxx')` / `@Monitor('signal.xxx')` 字面量必须随字段名同步修改（编译期不检查）。
- `entry/src/test/**` 的 import 路径与引用的符号同步修改（2026-10-28 用户批准）。
- `resources/base/profile/custom_router_map.json` 的 `pageSourceFile` / `buildFunction` 同步修改（2026-10-28 用户批准）；`name` 不变。
- `docs/**` 与 `entry/Refactor_Spec.md` 中的文件名引用同步更新。

完整改名映射与执行记录见 [`naming-rename-map.md`](./naming-rename-map.md)。
