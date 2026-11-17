# 工程结构方案（多设备：Phone / Tablet / 2in1 / Wearable）

> **状态**：已执行（2026-10-29），实施时有调整：`core` 不动、`entry` 不挪到 `products/default`、新增 `common/widgetbase`。**当前实际结构以 [project-structure.md](./project-structure.md) 为准**；本文附录的逐文件归属是迁移前的映射，不再更新。
> **日期**：2026-10-28（替代同日上一版"单模块 MVVM"方案——加入 Wearable 后，单模块方案不再成立）
> **一句话结论**：按官方"一次开发，多端部署"的**三层工程结构**重组：`common`（公共能力）/ `features`（功能模块）/ `products`（每类设备一个入口）。手机、平板、2in1 共用现有入口模块 `entry`（**位置与模块名不变**，承担官方 products 层 default 的角色）；手表将来单独一个入口 `products/wearable`。两个入口共用的代码都放进 `common` 和 `features`。
>
> **用户决定（2026-10-28）**：`core` 不动（不在 entry 重构范围）；`entry` 不挪到 `products/default`、不改名（另见迁移计划 P2：模块名关系到沙箱数据路径）。

---

## 1. 官方依据

| # | 资料 | 本方案用到的结论 |
| --- | --- | --- |
| ① | OpenHarmony《一次开发，多端部署 · 简介》（[introduction.md](https://gitee.com/openharmony/docs/blob/OpenHarmony-5.0.0-Release/zh-cn/application-dev/key-features/multi-device-app-dev/introduction.md)）"部署模型""工程结构"两节 | 设备按屏幕尺寸、输入方式、交互距离分**泛类**：手机/平板一类，车机/智慧屏一类，智能穿戴一类。**同一泛类优先部署模型 A（同一个 HAP），不同泛类优先部署模型 B（不同 HAP）**。推荐三层结构：common（可选，HAR/HSP）、features（可选，HAR/HSP/Feature HAP）、products（必选，每个子目录一个 Entry HAP，示例子目录就是 `wearable`、`default`） |
| ② | OpenHarmony《一次开发，多端部署 · 工程管理》（[ide-using.md](https://gitee.com/openharmony/docs/blob/OpenHarmony-5.0.0-Release/zh-cn/application-dev/key-features/multi-device-app-dev/ide-using.md)） | `default` 模块 `deviceTypes` 配 `["default", "tablet"]`，`wearable` 模块配 `["wearable"]`，两者都是 `entry` 类型；**同一设备类型只能有一个 Entry 模块**；common 被 features 和 products 依赖，features 被 products 依赖 |
| ③ | OpenHarmony《HAR》《HSP》约束（[har-package.md](https://gitee.com/openharmony/docs/blob/OpenHarmony-5.0.0-Release/zh-cn/application-dev/quick-start/har-package.md)、[in-app-hsp.md](https://gitee.com/openharmony/docs/blob/OpenHarmony-5.0.0-Release/zh-cn/application-dev/quick-start/in-app-hsp.md)） | HAR / HSP **都不能声明 UIAbility / ExtensionAbility**；**不支持循环依赖，也不支持依赖传递**（A 依赖 B、B 依赖 C，A 仍不能直接用 C）；HAR 不能声明 pages，但可以包含页面并通过命名路由跳转；HAR 不能引用 AppScope 资源 |
| ④ | OpenHarmony《状态管理 · MVVM 模式》（[arkts-mvvm.md](https://gitee.com/openharmony/docs/blob/master/zh-cn/application-dev/ui/state-management/arkts-mvvm.md)） | **每个模块内部**按 `pages/`（页面）、`views/`（业务组件）、`shares/`（通用组件）、`viewmodel/`、`model/` 分层；View 不能跨层访问 Model，下层不能访问上层 |
| ⑤ | 官方 codelabs：MultiDeviceMusic（三层结构的完整范例，[README](https://gitee.com/openharmony/codelabs/tree/master/ExcellentCase/MultiDeviceMusic)）及 ArkTSComponents 等 7 个 | 常量 `constants/XxxConstants.ets`、工具 `utils/`、页面 `XxxPage.ets`、ViewModel `XxxViewModel.ets` |

`.opencode/skills` 对目录结构只给出 DevEco 新建工程的最小模板（`entryability/` + `pages/Index.ets`），也没有 Wearable 的结构建议，因此以上述官方资料为准。

---

## 2. 设备怎么分组

| 入口模块 | `deviceTypes` | 包含设备 | 部署模型 | 理由 |
| --- | --- | --- | --- | --- |
| `entry`（原位置，相当于官方的 `products/default`） | `["phone", "tablet", "2in1"]` | 手机、平板、2in1 | A（同一个 HAP） | 同一泛类，UI 用响应式布局（断点）适配大小屏即可；现有 entry 已是这三类 |
| `products/wearable` | `["wearable"]` | 手表 | B（单独的 HAP） | 不同泛类：屏幕小且多为圆形、交互方式不同，官方示例即单独的 `wearable` 子目录 |

> `entry` 内部的大小屏适配沿用官方"响应式布局"（断点 sm / md / lg、栅格），项目已有 `GRID_BREAKPOINTS` 与 Main 的分栏逻辑；2in1 额外关注键鼠交互与窗口自由缩放。

---

## 3. 目标工程结构

```
Mihoyo-Tool/
├── AppScope/
├── core/              HAR           现有 core 模块，**位置与内容不动**（不在本次 entry 重构范围，用户 2026-10-28 明确）
├── common/                          公共能力层（只被 features / products 依赖）
│   ├── widgetbase/    HAR           新建：卡片页面导入链上的纯文件（主题常量、卡片模型与工具）
│   └── basic/         HAR           新建：主题、通用组件、通用工具、常量、全局信号
├── features/                        功能层（每个功能一个 HAR，可横向依赖，但不能成环）
│   ├── home/                        首页
│   ├── dailynote/                   便笺详情（三游戏）
│   ├── characters/                  角色列表
│   ├── chardetail/                  角色详情（三游戏）
│   ├── material/                    材料计算 / 清单 / 目标配置 / 选角 / 工具页
│   ├── account/                     登录、我的、账号详情
│   ├── notification/                体力通知（服务 + 设置页）
│   ├── widget/                      小组件数据与小组件设置页（卡片 UI 本身留在 entry）
│   ├── verification/                人机验证、设备指纹
│   ├── legal/                       隐私同意、协议 WebView
│   └── settings/                    外观设置
├── entry/             entry HAP     原位置、原模块名；phone / tablet / 2in1：4 个 Ability、Index / Launch / Main 框架页、服务卡片 UI
└── products/                        （阶段 3 才建）
    └── wearable/      entry HAP     wearable：手表专属页面，复用 features 的 viewmodel / model（见 §6）
```

**依赖方向**（官方规定，编译期强制）：`entry / products → features → common`；`features` 之间可以横向依赖但**不能成环**；`common` 不依赖任何上层；每个模块必须**直接**声明自己用到的模块（不能靠传递）。

**为什么这几样必须留在 `entry`**：
- 4 个 Ability（`EntryAbility`、`EntryBackupAbility`、`EntryFormAbility`、`WidgetSyncAbility`）——依据 ③，HAR / HSP 不能声明 Ability；
- 服务卡片的 6 个卡片页面及其组件、ViewModel——由声明 `FormExtensionAbility` 的模块的 `form_config.json` 引用；卡片运行在独立进程。已核实（官方 [arkts-form-overview.md「约束与限制」](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/form/arkts-form-overview.md)）：卡片可导入 HAR、不可导入 HSP，且导入链只能含卡片支持的 API。因此卡片页面留在入口模块，卡片导入链上的 9 个纯文件单独放入 `common/widgetbase`（HAR），见 [structure-migration-plan.md 阶段 2](./structure-migration-plan.md)；
- `Index` / `Launch` / `Main` / `TestPage`——应用框架，每个设备形态各自一份。

---

## 4. 每个模块内部怎么分（依据 ④⑤）

```
<模块>/src/main/ets/
├── pages/          页面（XxxPage.ets），通过命名路由 / routerMap 被跳转
├── views/          只属于本功能的组件（按子功能可再分子目录，如 views/genshin/）
├── viewmodel/      XxxViewModel.ets
├── model/          数据模型：单个 XxxModel.ets，多个 XxxModels.ets
│   └── service/    本功能有状态的业务服务 / 存储（如 MaterialComputeService）
└── utils/ constants/   本功能专用的工具与常量（需要时才建）
```

`common/basic` 内部：`shares/`（通用组件）、`theme/`、`utils/`、`constants/`、`signals/`（全局信号）、`config/`、`model/`（跨功能共用的模型）。

**文件后缀规则**（沿用 [naming-conventions.md](./naming-conventions.md)，补充模型后缀）：

| 类别 | 规则 | 例子 |
| --- | --- | --- |
| 页面 | `XxxPage.ets` | `HomePage.ets` |
| ViewModel | `XxxViewModel.ets` | `HomeViewModel.ets` |
| 模型 | 单个 `XxxModel.ets`，多个 `XxxModels.ets` | `widget/models/WidgetConfig.ets` → `features/widget/.../model/WidgetConfigModels.ets` |
| 常量 | `XxxConstants.ets`；单个枚举与枚举同名 | `LoginConstants.ets`、`ViewState.ets` |
| 工具 | `XxxUtil.ets` | `DialogDedup.ets` → `DialogDedupUtil.ets` |
| 服务 | 保持 `XxxService / Manager / Store / Center` | `MaterialComputeService.ets` |
| 组件 | 描述性名字，不强制 `Component` 后缀（官方示例两种都有） | `GameToolCard.ets` |

---

## 5. 按现在的代码拆分会遇到的问题（已用脚本核对 import 依赖）

把 350 个文件按附录归属后计算模块间依赖：**没有**下层依赖上层的违规；**有两个环**（依据 ③ 必须先解开，否则无法编译）。

| 环 | 形成原因（文件级证据） | 解法 | 性质 |
| --- | --- | --- | --- |
| characters → chardetail → material → characters | `CharactersViewModel` 用 chardetail 的 `CharDetailRouterParam`；`GenshinCharacterDetailPage` import `MaterialCalcPage`；`MaterialCharacterSelectPage` 用 characters 的 `AccountSwitchDialog`，`MaterialCharacterSelectViewModel` 用 `CharacterSortUtil` | 把 `AccountSwitchDialog`、`CharacterSortUtil` 移到 `common/basic`（附录已按此归属，**移动后此环消失，已验证**） | 纯移动 |
| home → widget → home，notification → widget | `home/UserGameSection` 同时承担"首页展示"和"小组件选槽位"两种用途，import 了 widget 的 `WidgetDataStore` / `WidgetSlotOption`；widget 的设置页又 import 了 `UserGameSection` 与 `HomeModels`；`StaminaNotificationService` 直接调用 widget 的 `WidgetDataBuilder` / `WidgetDataStoreBuilder` / `WidgetFormIdStore` 推送卡片 | ① 把 `UserGameSection` 拆成"通用的账号角色列表（放 common/basic）+ widget 自己的选槽位包装"；② 账号角色模型 `MihoyoAccountVM` / `GameRoleCardVM` 移到 common/basic；③ 通知服务改为发信号（common/basic/signals），由 widget 订阅后推送卡片 | **需要改代码** |

其它必须同步处理的事：
- **路由表拆分**：`custom_router_map.json` 现在 20 条全在 entry；拆分后各 feature 的页面要在各自模块的 routerMap 注册，路由名（`AppRoutes` 的值）不变。
- **资源拆分**：`$r('app.string.xxx')` 只能取本模块及其依赖模块的资源；`string.json` / `color.json` / 图片要按使用方分到各模块（共用的放 common/basic）。
- **测试拆分**：`entry/src/test` 按被测文件所在模块拆到各模块的 `src/test`。
- **core 的 `deviceTypes`**（改 core，超出本次 entry 重构范围，届时需用户单独批准）：现为 `["default", "tablet", "2in1"]`，要加 `"wearable"` 才能被手表入口依赖；core 里每个 API 在手表上是否可用需核实（见 §6）。
- 以前的分析文档把 core 写成 HSP，实际 `core/src/main/module.json5` 是 **HAR**。

---

## 6. 手表（Wearable）——需要先确认的事

**能力是否可用：未核实。** 官方没有找到"各 Kit × 设备类型"的汇总表；网上只确认 HarmonyOS 5.1.0（API 18）起支持手表应用开发。本项目重度依赖的能力：

| 能力 | 本项目用在哪 | 手表上 |
| --- | --- | --- |
| ArkWeb（Web 组件） | 人机验证弹框、协议页、隐私同意页 | 未核实 |
| Form Kit（服务卡片） | 6 种桌面小组件 | 未核实（手表卡片形态与手机不同） |
| Notification / Reminder | 体力提醒 | 未核实 |
| 网络、RDB、Preferences | core 全部数据层 | 未核实 |

**核实方法**（需在装有 DevEco 的机器上做）：在 `core` 与新建的 `products/wearable` 的 `deviceTypes` 中加入 `"wearable"` 后编译，DevEco 会按 SysCap 报出手表不支持的 API；或查 SDK 自带的各设备 SysCap 定义。

**产品需要你决定的**：
1. 手表上提供哪些功能？（建议起步：查看各账号的便笺/体力 + 体力提醒；登录、材料计算、角色详情等重交互功能只在手机端）
2. 手表的数据从哪来？
   - A：手表独立登录、独立请求（依赖手表上的网络与登录方式；扫码登录需显示二维码并轮询，人机验证依赖 Web）；
   - B：由手机端同步给手表（需要手机与手表之间的数据通道，具体 Kit 待核实）。

---

## 7. 分阶段执行（推荐）

| 阶段 | 做什么 | 结果 | 风险 |
| --- | --- | --- | --- |
| 1 | **先在 entry 内部按未来模块边界归位**：建 `entry/.../features/<功能>/{pages,views,viewmodel,model}`、`entry/.../common/...` 目录，按附录移动文件；解开 §5 的两个环 | 目录 = 未来的模块，但仍是一个模块，路由 / 资源 / 构建都不变 | 低（与上一轮改名同类的文件移动 + 静态检查 + 本地编译） |
| 2 | **抽成真正的模块**：建 `common/basic` 与 `common/widgetbase`、每个 feature 一个 HAR（entry 原位不动）；拆路由表、资源、测试 | 三层结构落地，手机 / 平板 / 2in1 行为不变 | 中（改工程配置、模块依赖、资源归属） |
| 3 | **新增 `products/wearable`**：先按 §6 核实能力、定功能范围与数据来源，再开发手表页面 | 手表入口 | 取决于 §6 的结论 |

阶段 1 完成后再做 Refactor_Spec 的 M1–M15 模块重构，重构的就是各 feature 目录，边界已经清楚。

---

## 8. 需要你决定的事

1. **认可三层结构与设备分组吗？**（default = phone / tablet / 2in1；wearable 单独）
2. **features 怎么划分**——§3 的 11 个功能模块是按现有页面职责划分的，是否合并（例如 settings 并入 account，legal 并入 account）？
3. **先做阶段 1 吗？**（只在 entry 内移动文件、解开两个环，不动工程配置）
4. **手表的功能范围与数据来源**（§6），可以等阶段 2 之后再定。

---

## 附录：逐文件归属（阶段 1 / 阶段 2 共用）

按当前代码自动生成：每个文件的目标模块及其在模块内的路径。`components/characters/AccountSwitchDialog.ets`、`utils/CharacterSortUtil.ets` 为解开环而归入 `common/basic`；`home/UserGameSection` 与 `HomeModels` 在阶段 1 拆分后会有部分内容移到 `common/basic`（§5），此表按拆分前的文件列出。

### `entry`（入口模块，原位不动，30 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `components/TestRow.ets` | `views/test/TestRow.ets` |
| `components/TestSectionHeader.ets` | `views/test/TestSectionHeader.ets` |
| `entryability/EntryAbility.ets` | `entryability/EntryAbility.ets` |
| `entrybackupability/EntryBackupAbility.ets` | `entrybackupability/EntryBackupAbility.ets` |
| `entryformability/EntryFormAbility.ets` | `entryformability/EntryFormAbility.ets` |
| `pages/` 下 4 个（`Index`、`LaunchPage`、`MainPage`、`TestPage`） | `pages/`，文件名不变 |
| `widget/components/` 下 10 个（`Widget1x2ContentView`、`Widget2x2Header`、`Widget2x2SingleGame`、`Widget2x2StaminaBlock`、`Widget2x2StandardStamina`、`Widget2x2StarRailStamina`…） | `widget/views/`，文件名不变 |
| `widget/pages/` 下 6 个（`Widget1x2Genshin`、`Widget1x2StarRail`、`Widget1x2ZZZ`、`Widget2x2`、`Widget2x4`、`Widget4x4`） | `widget/pages/`，文件名不变 |
| `widget/viewmodel/` 下 4 个（`Widget1x2ViewModel`、`Widget2x2ViewModel`、`Widget2x4ViewModel`、`Widget4x4ViewModel`） | `widget/viewmodel/`，文件名不变 |
| `widgetsyncability/WidgetSyncAbility.ets` | `widgetsyncability/WidgetSyncAbility.ets` |

### `common/basic`（35 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `components/SettingRow.ets` | `shares/SettingRow.ets` |
| `components/SnackbarContent.ets` | `shares/SnackbarContent.ets` |
| `components/SplitPlaceholder.ets` | `shares/SplitPlaceholder.ets` |
| `components/characters/AccountSwitchDialog.ets` | `shares/AccountSwitchDialog.ets` |
| `components/common/PlaceholderView.ets` | `shares/PlaceholderView.ets` |
| `components/common/SegmentedTabBar.ets` | `shares/SegmentedTabBar.ets` |
| `config/RuntimeConfig.ets` | `config/RuntimeConfig.ets` |
| `constants/` 下 6 个（`AppConstants`、`AppRoutes`、`FeedbackType`、`HeroPanelMode`、`SignalStorageKey`、`ViewState`） | `constants/`，文件名不变 |
| `models/AccountOption.ets` | `model/AccountOptionModel.ets` |
| `models/SegmentedTabItem.ets` | `model/SegmentedTabItemModel.ets` |
| `models/SnackbarParams.ets` | `model/SnackbarParamsModel.ets` |
| `styles/PrimaryButtonModifier.ets` | `theme/PrimaryButtonModifier.ets` |
| `theme/` 下 4 个（`AppTheme`、`DefaultTheme`、`ThemeFonts`、`ThemeManager`） | `theme/`，文件名不变 |
| `utils/AccountSignal.ets` | `signals/AccountSignal.ets` |
| `utils/CookieExpiredSignal.ets` | `signals/CookieExpiredSignal.ets` |
| `utils/SyncRetrySignal.ets` | `signals/SyncRetrySignal.ets` |
| `utils/CharacterSortUtil.ets` | `utils/CharacterSortUtil.ets` |
| `utils/ColorUtil.ets` | `utils/ColorUtil.ets` |
| `utils/DialogDedup.ets` | `utils/DialogDedupUtil.ets` |
| `utils/FeedbackUtil.ets` | `utils/FeedbackUtil.ets` |
| `utils/GameIdUtil.ets` | `utils/GameIdUtil.ets` |
| `utils/GenshinElementUtil.ets` | `utils/GenshinElementUtil.ets` |
| `utils/RouterUtil.ets` | `utils/RouterUtil.ets` |
| `utils/ServerNameUtil.ets` | `utils/ServerNameUtil.ets` |
| `utils/StarRailElementUtil.ets` | `utils/StarRailElementUtil.ets` |
| `utils/TimeFormatUtil.ets` | `utils/TimeFormatUtil.ets` |
| `utils/ZZZElementUtil.ets` | `utils/ZZZElementUtil.ets` |

### `features/account`（38 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `components/accountdetail/` 下 7 个（`AccountActionsSection`、`AccountHeaderCard`、`AccountRoleCard`、`AccountRoleCardHeader`、`AccountRoleServerRow`、`AccountRoleStatItem`…） | `views/`，文件名不变 |
| `components/login/` 下 18 个（`LoginAgreement`、`LoginCard`、`LoginCodeInput`、`LoginCookie`、`LoginFeatureItem`、`LoginLogoSection`…） | `views/`，文件名不变 |
| `components/my/` 下 5 个（`AboutSection`、`AccountListItem`、`AccountListSection`、`AppearanceSection`、`SectionHeader`） | `views/`，文件名不变 |
| `constants/LoginConstants.ets` | `constants/LoginConstants.ets` |
| `models/MyModels.ets` | `model/MyModels.ets` |
| `pages/AccountDetailPage.ets` | `pages/AccountDetailPage.ets` |
| `pages/LoginPage.ets` | `pages/LoginPage.ets` |
| `pages/MyPage.ets` | `pages/MyPage.ets` |
| `viewmodel/AccountDetailViewModel.ets` | `viewmodel/AccountDetailViewModel.ets` |
| `viewmodel/LoginViewModel.ets` | `viewmodel/LoginViewModel.ets` |
| `viewmodel/MyViewModel.ets` | `viewmodel/MyViewModel.ets` |

### `features/characters`（12 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `components/characters/` 下 4 个（`CharacterCard`、`CharacterDataSource`、`CharactersContent`、`CharactersSkeleton`） | `views/`，文件名不变 |
| `components/characters/genshin/GenshinBottomBar.ets` | `views/genshin/GenshinBottomBar.ets` |
| `components/characters/genshin/GenshinTopLeftBadge.ets` | `views/genshin/GenshinTopLeftBadge.ets` |
| `components/characters/starrail/StarRailBottomBar.ets` | `views/starrail/StarRailBottomBar.ets` |
| `components/characters/starrail/StarRailTopLeftBadge.ets` | `views/starrail/StarRailTopLeftBadge.ets` |
| `components/characters/zzz/ZZZBottomBar.ets` | `views/zzz/ZZZBottomBar.ets` |
| `components/characters/zzz/ZZZTopLeftBadge.ets` | `views/zzz/ZZZTopLeftBadge.ets` |
| `pages/CharactersPage.ets` | `pages/CharactersPage.ets` |
| `viewmodel/CharactersViewModel.ets` | `viewmodel/CharactersViewModel.ets` |

### `features/chardetail`（69 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `components/chardetail/common/` 下 9 个（`CharDetailConsColumn`、`CharDetailEmptyView`、`CharDetailHeroNameOverlay`、`CharDetailLoadingView`、`CharDetailMaterialCalcEntry`、`CharDetailRelicPlaceholder`…） | `views/common/`，文件名不变 |
| `components/chardetail/genshin/` 下 26 个（`CharDetailHeroInfoOverlay`、`CharDetailHeroPanel`、`CharDetailHeroPanelLandscape`、`CharDetailHeroPanelPortrait`、`CharDetailHeroPanelWide`、`CharDetailLandscapeLayout`…） | `views/genshin/`，文件名不变 |
| `components/chardetail/starrail/` 下 11 个（`StarRailCharDetailContent`、`StarRailCharDetailHero`、`StarRailCharDetailHeroProfile`、`StarRailCharDetailWideLayout`、`StarRailEquipCard`、`StarRailEquipSection`…） | `views/starrail/`，文件名不变 |
| `components/chardetail/zzz/` 下 13 个（`ZZZCharDetailContent`、`ZZZCharDetailHero`、`ZZZCharDetailHeroProfile`、`ZZZCharDetailWideLayout`、`ZZZEquipCard`、`ZZZEquipCardHeader`…） | `views/zzz/`，文件名不变 |
| `models/CharDetailModels.ets` | `model/CharDetailModels.ets` |
| `pages/GenshinCharacterDetailPage.ets` | `pages/GenshinCharacterDetailPage.ets` |
| `pages/StarRailCharacterDetailPage.ets` | `pages/StarRailCharacterDetailPage.ets` |
| `pages/ZZZCharacterDetailPage.ets` | `pages/ZZZCharacterDetailPage.ets` |
| `utils/GenshinElementBgUtil.ets` | `utils/GenshinElementBgUtil.ets` |
| `utils/GenshinPropertyUtil.ets` | `utils/GenshinPropertyUtil.ets` |
| `utils/StarRailPropertyUtil.ets` | `utils/StarRailPropertyUtil.ets` |
| `viewmodel/GenshinCharacterDetailViewModel.ets` | `viewmodel/GenshinCharacterDetailViewModel.ets` |
| `viewmodel/StarRailCharacterDetailViewModel.ets` | `viewmodel/StarRailCharacterDetailViewModel.ets` |
| `viewmodel/ZZZCharacterDetailViewModel.ets` | `viewmodel/ZZZCharacterDetailViewModel.ets` |

### `features/dailynote`（23 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `components/dailynote/common/` 下 6 个（`DailyNoteCard`、`DailyNoteDataRow`、`DailyNoteEmptyView`、`DailyNoteLoadingView`、`DailyNoteSectionLabel`、`ExpeditionItem`） | `views/common/`，文件名不变 |
| `components/dailynote/genshin/DailyNoteGenshin.ets` | `views/genshin/DailyNoteGenshin.ets` |
| `components/dailynote/genshin/GenshinDailyTaskContent.ets` | `views/genshin/GenshinDailyTaskContent.ets` |
| `components/dailynote/genshin/GenshinExpeditionSection.ets` | `views/genshin/GenshinExpeditionSection.ets` |
| `components/dailynote/starrail/DailyNoteStarRail.ets` | `views/starrail/DailyNoteStarRail.ets` |
| `components/dailynote/starrail/StarRailStaminaCard.ets` | `views/starrail/StarRailStaminaCard.ets` |
| `components/dailynote/starrail/StarRailUniverseCard.ets` | `views/starrail/StarRailUniverseCard.ets` |
| `components/dailynote/zzz/` 下 4 个（`DailyNoteZZZ`、`ZZZDailyCard`、`ZZZOtherCard`、`ZZZShopCard`） | `views/zzz/`，文件名不变 |
| `models/DailyNoteModels.ets` | `model/DailyNoteModels.ets` |
| `pages/GenshinDailyDetailPage.ets` | `pages/GenshinDailyDetailPage.ets` |
| `pages/StarRailDailyDetailPage.ets` | `pages/StarRailDailyDetailPage.ets` |
| `pages/ZZZDailyDetailPage.ets` | `pages/ZZZDailyDetailPage.ets` |
| `viewmodel/GenshinDailyDetailViewModel.ets` | `viewmodel/GenshinDailyDetailViewModel.ets` |
| `viewmodel/StarRailDailyDetailViewModel.ets` | `viewmodel/StarRailDailyDetailViewModel.ets` |
| `viewmodel/ZZZDailyDetailViewModel.ets` | `viewmodel/ZZZDailyDetailViewModel.ets` |

### `features/home`（13 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `components/home/` 下 10 个（`AccountSkeletonCard`、`GameDataRow`、`GameStaminaBlock`、`GameToolCard`、`GameToolCardContent`、`GameToolCardHeader`…） | `views/`，文件名不变 |
| `models/HomeModels.ets` | `model/HomeModels.ets` |
| `pages/HomePage.ets` | `pages/HomePage.ets` |
| `viewmodel/HomeViewModel.ets` | `viewmodel/HomeViewModel.ets` |

### `features/legal`（7 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `components/privacyconsent/PrivacyConsentFooter.ets` | `views/PrivacyConsentFooter.ets` |
| `components/privacyconsent/PrivacyConsentWebView.ets` | `views/PrivacyConsentWebView.ets` |
| `pages/PrivacyConsentPage.ets` | `pages/PrivacyConsentPage.ets` |
| `pages/WebViewPage.ets` | `pages/WebViewPage.ets` |
| `utils/LegalI18nRouter.ets` | `utils/LegalI18nUtil.ets` |
| `utils/LegalPreferences.ets` | `model/service/LegalPreferences.ets` |
| `viewmodel/PrivacyConsentViewModel.ets` | `viewmodel/PrivacyConsentViewModel.ets` |

### `features/material`（40 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `builders/MaterialCharacterSelectPageBuilder.ets` | `pages/MaterialCharacterSelectPageBuilder.ets` |
| `components/materialcalc/` 下 8 个（`LevelPicker`、`MaterialCalcCharacter`、`MaterialCalcContentView`、`MaterialCalcEmptyView`、`MaterialCalcItem`、`MaterialCalcLoadingView`…） | `views/`，文件名不变 |
| `components/materiallist/` 下 6 个（`CharacterMaterialCard`、`CharacterMaterialSections`、`MaterialGridCard`、`MaterialGridItem`、`MaterialListContentView`、`MaterialSectionView`） | `views/`，文件名不变 |
| `components/tools/GameEntryCard.ets` | `views/GameEntryCard.ets` |
| `models/` 下 4 个（`MaterialCalcModels`、`MaterialListModels`、`MaterialTargetConfigModels`、`ToolsModels`） | `model/`，文件名不变 |
| `pages/` 下 9 个（`GenshinMaterialListPage`、`GenshinMaterialTargetConfigPage`、`MaterialCalcPage`、`MaterialCharacterSelectPage`、`StarRailMaterialListPage`、`StarRailMaterialTargetConfigPage`…） | `pages/`，文件名不变 |
| `utils/MaterialComputeService.ets` | `model/service/MaterialComputeService.ets` |
| `utils/MaterialRouteUtil.ets` | `utils/MaterialRouteUtil.ets` |
| `viewmodel/` 下 9 个（`GenshinMaterialListViewModel`、`GenshinMaterialTargetConfigViewModel`、`MaterialCalcViewModel`、`MaterialCharacterSelectViewModel`、`StarRailMaterialListViewModel`、`StarRailMaterialTargetConfigViewModel`…） | `viewmodel/`，文件名不变 |

### `features/notification`（22 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `components/my/NotificationSection.ets` | `views/NotificationSection.ets` |
| `components/notification/` 下 14 个（`NotificationAccountBlock`、`NotificationAccountHeader`、`NotificationBubbleCollapsed`、`NotificationBubbleExpanded`、`NotificationBubbleHeader`、`NotificationFullValueRow`…） | `views/`，文件名不变 |
| `notification/NotificationModels.ets` | `model/NotificationModels.ets` |
| `notification/` 下 4 个（`NotificationSettingsStore`、`NotificationStateStore`、`StaminaNotificationService`、`StaminaThresholdCalculator`） | `model/service/`，文件名不变 |
| `pages/NotificationSettingsPage.ets` | `pages/NotificationSettingsPage.ets` |
| `viewmodel/NotificationSettingsViewModel.ets` | `viewmodel/NotificationSettingsViewModel.ets` |

### `features/settings`（4 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `components/appearancesettings/ThemeModeRow.ets` | `views/ThemeModeRow.ets` |
| `pages/AppearanceSettingsPage.ets` | `pages/AppearanceSettingsPage.ets` |
| `utils/AppearanceManager.ets` | `model/service/AppearanceManager.ets` |
| `viewmodel/AppearanceSettingsViewModel.ets` | `viewmodel/AppearanceSettingsViewModel.ets` |

### `features/verification`（9 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `components/` 下 5 个（`GeetestBridge`、`GeetestDialog`、`GeetestDialogHelper`、`GeetestDialogTitleBar`、`GeetestHtmlBuilder`） | `views/`，文件名不变 |
| `models/GeetestTrigger.ets` | `model/GeetestTriggerModel.ets` |
| `utils/DeviceFpCenter.ets` | `model/service/DeviceFpCenter.ets` |
| `utils/GeetestCenter.ets` | `model/service/GeetestCenter.ets` |
| `utils/GeetestSignal.ets` | `signals/GeetestSignal.ets` |

### `features/widget`（48 个）

| 现在（entry/src/main/ets/ 下） | 目标（模块内 src/main/ets/ 下） |
| --- | --- |
| `components/widgetsettings/` 下 13 个（`WidgetConfigDone`、`WidgetConfigPreview`、`WidgetGameTypeOption`、`WidgetSettingsBottomButtons`、`WidgetSettingsGameStep`、`WidgetSettingsLoading`…） | `views/`，文件名不变 |
| `components/widgetsettings/preview/` 下 11 个（`Preview1x2Card`、`Preview1x2Content`、`Preview2x2MultiSlot`、`Preview2x2SingleGame`、`Preview2x4MultiSlot`、`Preview2x4SingleGame`…） | `views/preview/`，文件名不变 |
| `models/WidgetPreviewModels.ets` | `model/WidgetPreviewModels.ets` |
| `models/WidgetSettingsModels.ets` | `model/WidgetSettingsModels.ets` |
| `pages/WidgetSettingsPage.ets` | `pages/WidgetSettingsPage.ets` |
| `viewmodel/WidgetSettingsViewModel.ets` | `viewmodel/WidgetSettingsViewModel.ets` |
| `widget/models/WidgetConfig.ets` | `model/WidgetConfigModels.ets` |
| `widget/models/WidgetDataStore.ets` | `model/WidgetDataStoreModels.ets` |
| `widget/models/WidgetModels.ets` | `model/WidgetGameSnapshotModel.ets` |
| `widget/models/WidgetUIStates.ets` | `model/WidgetUIStateModels.ets` |
| `widget/utils/` 下 16 个（`WidgetConfigStore`、`WidgetDataBuilder`、`WidgetDataHelper`、`WidgetDataStoreBuilder`、`WidgetDataStoreManager`、`WidgetExtraRowConfig`…） | `utils/`，文件名不变 |

> 统计：`entry` 30、`common/basic` 35、`features/account` 38、`features/characters` 12、`features/chardetail` 69、`features/dailynote` 23、`features/home` 13、`features/legal` 7、`features/material` 40、`features/notification` 22、`features/settings` 4、`features/verification` 9、`features/widget` 48；合计 350。

