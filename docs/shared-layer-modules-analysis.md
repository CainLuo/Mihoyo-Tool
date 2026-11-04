# 共享层分析（M0）

> **分析对象**：`common/basic/src/main/ets/{config,constants,model,shares,signals,theme,utils}` —— 37 个文件 / ~2,043 行；另含 `common/basic/Index.ets` 52 行（统一导出入口，别名 `basic`），合计 **38 文件 / ~2,095 行**。
> **分析日期**：2026-10-29
> **代码版本**：`e00e579`
> **HarmonyOS SDK**：`6.0.2(22)`（`targetSdkVersion` / `compatibleSdkVersion`，见根 `build-profile.json5`）
> **口径**：skills `harmonyos-review` 官方 A-F 评级
> **状态**：正文为 `e00e579` 基线的分析结论；2026-10-29 已在代码中修复的条目、仍待决策的条目见 **§8 修复状态**。
> **已移出共享层的大文件**（归属对应 features 模块）：`MaterialComputeService` → `features/material/model/service/`（M7 已按 facade 拆为 163L + Result / Utils / Genshin / StarRail / ZZZ 五个文件）；`GeetestSignal` / `GeetestCenter` → `features/geetest/`；`DeviceFpCenter` → `features/devicefp/`；`AppearanceManager` → `features/appearance/`。这些文件不再计入 M0 行数，仅在其遗留问题对共享层有影响时在相应条目中引用。
>
> **定位**：M0 是被全 entry 依赖的共享层（Spec §3 要求中心节点原位不动），此前没有独立分析文档。本文件补齐 38 个文件的职责、中心节点与改动风险。

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 5 |
| Low | 7 |

**整体评级：A**（0 Critical、0 High，Medium 5 ≤ 5）

**债务点数**：5×2 + 7×1 = **17**；源行数 ~2,095（38 个共享层文件）；密度 17 ÷ 20.95 ≈ **0.81 / 百行**

> **判级说明**：M1 / M2 / M5 / M6 是"协议脆弱 / 治理缺失"类技术债，当前代码没有触发路径（如 `Index.ets:23-25` 先 `RouterUtil.init` 再 push；DialogDedup 5 处调用均已释放），按 README §1「Medium = 技术债」口径计入。已移出共享层的大文件（`MaterialComputeService`、`GeetestSignal`/`GeetestCenter`、`DeviceFpCenter`、`AppearanceManager`）的风险项不再计入 M0，其遗留问题对共享层有影响时在相应条目中引用。Medium 5 ≤ 5，满足 A 级条件。

> 共享层本身很干净：**0 处 `console.*`、0 处 `any`/`as any`/`var`、0 处 `forEach + await`**（全量 grep 已核）。问题主要集中在"中心节点的耦合"上：`themeManager` 被 **210 个文件** import、3 个 `AppStorageV2` 信号类（`CookieExpiredSignal` / `SyncRetrySignal` / `AccountSignal`）同时被页面、ViewModel 与 Center 写入。M0 的真实风险不是代码质量，而是**改一个字段会牵动半个 entry**；行为缺口方面，人机验证申请 / 提交失败时对用户无任何提示（跨模块约定，`GeetestCenter`/`GeetestSignal` 已归属 features/geetest）。另外，外观设置页的 High（见 [appearance-settings-page](./appearance-settings-page-module-analysis.md)）根因在本层的 `AppearanceManager.applyColorMode` 吞掉全部异常，计数在外观页，修复点在 M0（§7）。
>
> 另有几处"注释/约定与代码不一致"需要在动手前明确，否则重构者会照着注释造出不存在的抽象或冻结错误的东西（`SignalMonitorKey` 实际没有被任何 `@Monitor` 使用，见 M6；L2 / L3 为注释错误）。
>
> `entry/src/test/HomeViewModel.test.ets` 引用失效模块、`GenshinDailyDetailViewModel.test.ets` 调用已迁到 `TimeFormatUtil` 的方法，属测试资产缺陷，按 README §1.4 **不计入本模块评级**，只作为验收前提记在 §7（详见 [test-suite-analysis.md](./test-suite-analysis.md) T1 / T6）。

---

## 1. 文件清单

### 1.4 `config/`、`constants/`（7 文件 / 171 行）

| 文件 | 行数 | 说明 | 引用方 |
| --- | --- | --- | --- |
| `config/RuntimeConfig` | 15 | `APP_ENV`（来自 hvigor `buildProfileFields`）；引用方 `EntryAbility`、`WidgetSyncAbility`。头注释（`:8`）称"唯一允许读取 `BuildProfile.APP_ENV` 的地方"，但 `widget/utils/WidgetLogger.ets:35` 也直接读取 |
| `constants/AppRoutes` | 58 | 25 个 `static readonly` 路由名常量；`AppRoutes` 被全仓 ~120+ 引用方（grep 计数） |
| `constants/AppConstants` | 39 | 响应式断点、骨架屏占位索引、自动刷新间隔（30 分钟） |
| `constants/SignalStorageKey` | 14 | 仅保留 2 个 AppStorage key：`GEETEST_SIGNAL_KEY` / `COOKIE_EXPIRED_SIGNAL_KEY`（旧 8 条 @Monitor 路径约定已作废，见 M6） |
| `constants/ViewState` | 18 | `ViewState`（fan-in 35：24 个 `viewmodel/` 中 15 个引用；被 7 个测试引用） |
| `constants/HeroPanelMode` | 14 | 立绘区布局模式（禁止写字面量） |
| `constants/FeedbackType` | 13 | Snackbar 类型枚举 |

### 1.5 `model/`（4 文件 / 278 行）

| 文件 | 行数 | 说明 | 引用方 |
| --- | --- | --- | --- |
| `model/AccountRoleModels` | 192 | `GameDataRowVM` / `GameNoteSnapshotVM` / `GameRoleCardVM` / `MihoyoAccountVM`（三游戏通用）+ `CharDetailHeroPanel` 相关类 + `CharDetailRouterParam` | fan-in **41**：3 个详情 VM + `CharactersViewModel` + 3 个详情页 + 34 个 `components/chardetail/` 组件 |
| `model/SnackbarParamsModel` | 33 | `SnackbarParams`（字段默认值用 `$r()` 读主题色，混入 ArkUI 类型见 M3） | `FeedbackUtil`、`SettingRow`（含 ArkUI `$r('sys.symbol.*')` 逻辑）、`SnackbarContent` |
| `model/AccountOptionModel` | 34 | `AccountOption`（账号选项模型）；测试资产引用见 [test-suite-analysis](./test-suite-analysis.md) T6 | `AccountSwitchDialog` + 测试 |
| `model/SegmentedTabItemModel` | 19 | `SegmentedTabItem`（L6 修复：已从 `components/common/SegmentedTabBar.ets` 移至 model 层，原文件 re-export） | `SegmentedTabBar`、`CharactersViewModel`、三游戏 MaterialList 页 |

### 1.6 `shares/`（8 文件 / 602 行）

| 文件 | 行数 | 说明 | 引用方 |
| --- | --- | --- | --- |
| `shares/AccountSwitchDialog` | 149 | 账号切换弹窗（`AccountOption` + `MihoyoAccountVM`） | 4 引用方 |
| `shares/PlaceholderView` | 113 | 骨架屏/占位视图（`PlaceholderState` 纯数据类，装饰器已删除见 L7） | 6 引用方（Tools、Home、MaterialCharacterSelect 页 + `characters/CharactersContent`） |
| `shares/SegmentedTabBar` | 100 | Tab 切换组件（`SegmentedTabItem` 从 model re-export，见 L6） | 8 引用方（三游戏 MaterialList 页、`characters/CharactersContent`） |
| `shares/SettingRow` | 68 | 设置项行组件（My 页专用） | 5 引用方（`pages/MyPage.ets`、`my/AppearanceSection`、`my/AboutSection`） |
| `shares/SnackbarContent` | 93 | Snackbar 内容视图；`aboutToDisappear` 已清理定时器（`:25-30`） | 仅 `utils/FeedbackUtil.ets:11`（§2.1 反向边之一） |
| `shares/SplitPlaceholder` | 45 | 分段占位视图 | 2 引用方 |
| `shares/UserGameSection` | 76 | 用户游戏区域组件 | 6 引用方 |
| `shares/UserGameSectionHeader` | 58 | 用户游戏区头部 | 3 引用方 |

### 1.7 `signals/`（4 文件 / 161 行）

| 文件 | 行数 | 说明 | 引用方 |
| --- | --- | --- | --- |
| `signals/CookieExpiredSignal` | 68 | Cookie 过期信号队列（AppStorageV2 单例 + `@Trace version/queue/trigger`） | **10** 引用方（Main、LoginViewModel、AccountDetailViewModel 等） |
| `signals/AccountSignal` | 25 | 登录/账号变更信号；`static readonly KEY` | **12** 引用方（三个目标配置 VM + Home/Characters/My/Tools 页面） |
| `signals/SyncRetrySignal` | 25 | 同步重试信号（L4 已删除无用的 `accountId` 字段，`notify()` 改为无参） | **7** 引用方 |
| `signals/WidgetSyncHook` | 43 | Widget 同步钩子 | **5** 引用方 |

### 1.8 `theme/`（3 文件 / 115 行）

| 文件 | 行数 | 说明 | 引用方 |
| --- | --- | --- | --- |
| `theme/ThemeFonts` | 41 | `Font` 预设对象（widget 不可用，只能 `fontSize` + `fontWeight`） | **82** 引用方（`grep -rl ThemeFonts` 得 83，含 `ThemeManager.ets:11` 注释示例） |
| `theme/ThemeManager` | 38 | `@ObservedV2` 单例 + `@Trace current`；字段无版本/废弃策略（M5） | **210** 引用方（全仓中心节点） |
| `theme/PrimaryButtonModifier` | 36 | 按钮修饰符（颜色尺寸全部取自 `themeManager`） | 继承自旧 `styles/`，已移至 `theme/` |

### 1.9 `utils/`（11 文件 / 563 行）

| 文件 | 行数 | 说明 | 引用方 |
| --- | --- | --- | --- |
| `utils/ColorUtil` | 109 | `Alpha` 常量、`colorWithAlpha`、`TransparentColorCache`（L5 修复：启动时随用户模式计算；`onConfigurationUpdate` 重算） | EntryAbility + 8 组件 |
| `utils/TimeFormatUtil` | 85 | 时间格式化（`recoveryDesc` L8 已修复不足 1 分钟显示"即将恢复"；L1 的 getCachedColorMode 建议已删除） | Home、各详情页 |
| `utils/GameIdUtil` | 77 | `GameId` → 名称/主题色/logo/主资源标签（枚举与字符串双版本） | **6 VM** + 8 组件/页面 + 2 utils（widget `WidgetUtils` 有独立映射） |
| `utils/FeedbackUtil` | 75 | Snackbar/Dialog 工具（L9 修复：关闭时 `dispose()` ComponentContent；L2 注释已改正） | **4** 引用方 |
| `utils/DialogDedupUtil` | 43 | Dialog 防重复工具（M2：现有 5 处调用均已正确释放 key，不加超时） | `FeedbackUtil` + EntryAbility |
| `utils/ServerNameUtil` | 50 | 服务器名称格式化 | 12 引用方 |
| `utils/RouterUtil` | 51 | 路由工具（M1 修复：未注入时 `Logger.error` + `isReady()`；L2 注释已改正） | ~120+ 引用方 |
| `utils/ZZZElementUtil` | 31 | ZZZ 属性 → 颜色映射 | 仅 ZZZ 详情页 |
| `utils/StarRailElementUtil` | 33 | 星铁属性 → 颜色/命途映射 | 仅星铁详情页 |
| `utils/GenshinElementUtil` | 31 | 原神属性类型 → 资源/展示顺序/高亮规则 | 仅 `GenshinCharacterDetailViewModel` |
| `utils/CharacterSortUtil` | 31 | 角色排序工具 | Characters 页 |

### 1.10 `Index.ets`（统一导出入口 / 52 行）

根目录 `common/basic/Index.ets`，逐行 re-export 上述所有符号：`config`(1) · `constants`(6) · `model`(4) · `shares`(8) · `signals`(4) · `theme`(3) · `utils`(11)，共 **37** 个导出项。

---

## 2. 架构与中心节点

### 2.1 依赖方向

```
constants  ← models  ← utils  ← viewmodel / components / pages
theme      ← components / pages / models/SnackbarParams / utils/GenshinElementUtil（AppTheme）
             （例外：widget/ 14 个文件与 components/widgetsettings/preview/ 10 个文件直接 new DefaultTheme()，绕过 themeManager）
config     ← EntryAbility / WidgetSyncAbility（取 APP_ENV 传给 CoreInitializer.initCore）
```

共享层**整体不反向依赖** `pages/components/viewmodel`，除按设计依赖页面的 `builders/MaterialCharacterSelectPageBuilder.ets:7` → `pages/MaterialCharacterSelect` 外，有 3 处例外（全量 grep import 已核）：

- `utils/FeedbackUtil.ets:11` → `components/SnackbarContent`
- `utils/GeetestSignal.ets:13` → `components/GeetestDialogHelper`（只取 `GeetestProgress` 类；`GeetestDialogHelper.ets:18` 与 `GeetestDialog.ets:23` 之间另有一条组件层循环导入，归 M15）
- `models/WidgetSettingsModels.ets:7-9` → `widget/models/{WidgetConfig,WidgetDataStore}` + `viewmodel/WidgetSettingsViewModel`（并 re-export `WidgetConfigStep` 与 `MihoyoAccountVM`）；而 `viewmodel/WidgetSettingsViewModel.ets:26` 又 import 本文件，**两者构成循环导入**（当前能编译运行，但 Spec §2.2 要求不新增循环；拆分 / 移动任一方时须先把 `WidgetConfigStep` 下沉到 models 或 constants）

因此"原位编辑"的前提对其余文件成立，对这 3 个文件只是部分成立：动 `SnackbarContent` / `GeetestDialogHelper` / `WidgetConfigStep` 会反向牵动共享层。重排目录前必须先解开这三条边。

### 2.2 五个中心节点（改动前必须知道）

| 节点 | fan-in | 影响面 |
| --- | --- | --- |
| `themeManager`（`theme/ThemeManager`） | **210**（import 它的文件数；`grep -rl themeManager` 得 211 是把定义文件自身也算进去了） | 字段改名/删除 = 全量编译失败；M3 外观设置、M15 框架都与它耦合 |
| `theme/ThemeFonts` | **82**（真实 import 方；`grep` 得 83 是把 `ThemeManager.ets:11` 的注释示例也算进去了） | 静态 `Font` 预设，字号硬编码在 `ThemeFonts.ets:23-40`，不随 `Theme` 切换；改名 / 删字段同样全量编译失败（widget 不可用，见 §1.4） |
| `models/CharDetailModels` | **41** | M10 三个游戏详情页共享：3 个详情 ViewModel + `CharactersViewModel` + 3 个详情页 + 34 个 `components/chardetail/` 组件 |
| 3 个 `AppStorageV2` 全局信号（M0 内部：`AccountSignal` / `SyncRetrySignal` / `CookieExpiredSignal`；其余见已移出文件说明） | 写入方：6 个 ViewModel（Home、Login、AccountDetail、三个目标配置；其中 `HomeViewModel.ets:276-280` 向 `CookieExpiredSignal` push）+ 页面 Login、AccountDetail、TestPage，以及 Main（`MainPage.ets:172-176` 出队改写 `cookieExpiredSignal.queue`、`:324-334` 调 `geetestSignal.resolve*`，`geetestSignal` 来自已移出的 `GeetestSignal`）；监听方（`@Local` + `@Monitor`）：Main + Home / Characters / Tools / My 4 个页面；`AccountDetailPage.ets:27` 只持有 `@Local expiredSignal` 在 `:67` 读取 `expiredUsernames`，不 `@Monitor` | 跨页面事件总线；M15 计划抽取的 `DialogArbiter`（见 main-module-analysis）会直接依赖 |

### 2.3 中心节点的实现方式

- **主题**：`@ObservedV2` + `@Trace current`，组件里写 `@Local tm = themeManager` 才会响应（`ThemeManager.ets:9-24` 是唯一的用法/切换示例）。**但全仓没有任何代码给 `themeManager.current` 赋值**（唯一出现在 `ThemeManager.ets:24` 注释），这套响应式机制目前从不触发；深浅色切换完全靠 `$r('app.color.*')` + `resources/dark`。因此 207 个文件里的 260 处 `@Local … = themeManager`（不含 `ThemeManager.ets:15` 注释示例）（另有 `SnackbarParams` / `ButtonModifier` / `CharDetailHeroPanel` 3 个 import 方不用 `@Local`）与 `WebViewPage.ets:62` / `PrivacyConsentWebView.ets:86` 的 `@Monitor('tm')` 都是休眠的（后者已记在 [webview-page](./webview-page-module-analysis.md)）。M5 的 token 治理与 L3 都以此为前提。
- **信号**：`AppStorageV2` 单例 + `@Trace version` / `queue` / `trigger`，页面用 `@Local + @Monitor` 监听。`@Monitor` 路径全部是**手写字面量**（如 `MainPage.ets:167/225/284`、`HomePage.ets:47/95`），没有一处使用 `SignalMonitorKey`；AppStorage key 也只有 `GeetestSignal` / `CookieExpiredSignal` 取自 `SignalMonitorKey`，另外 3 个信号各用自己的 `static readonly KEY`。
- **透明色**：`TransparentColorCache` 是**静态可变字段**，启动时 `init(context)` 从 `color.json` 计算并覆盖；未 init 时退回硬编码十六进制；之后不再重算（见 L5）。

### 2.4 隐式契约（跨模块一致）

| 契约 | 来源文件 | 说明 |
|------|----------|------|
| 路由名字符串 | `constants/AppRoutes`（25 个 `static readonly`）↔ `resources/base/profile/custom_router_map.json`（20 条 `name`）↔ `pages/Index.ets` `pageBuilder`（3 条） | 所有页面跳转必须通过这些常量，禁止硬编码路由名。**常量与 routerMap / pageBuilder 的对应关系编译器不检查**：常量存在但未注册时 `pushPathByName` 静默无效（`MATERIAL_CALC` 即此情况）。新增路由须三处同步 |
| @Monitor 路径字符串 | **分散在各页面的 `@Monitor('xxx.yyy')` 字面量**（37 处，全部在 pages / components）；`constants/SignalStorageKey` 只是未被采用的约定 | 真正需要冻结的是"字面量 ↔ `@Local` 字段名 / VM 字段名"的一致性：改 `signal` / `syncRetry` / `vm` 等字段名或 VM 字段名而不改字面量，监听会静默失效。`SignalMonitorKey` 的枚举值本身改动不影响任何监听（见 M6） |
| `MaterialTargetConfigParam` 结构 | `models/ToolsModels.ets:101-110` | 字段不可改名；被三个目标配置页、三游戏材料清单页、选角页及其 ViewModel 共用（注意 `MaterialComputeService` 原为引用方，已归属 `features/material/model/service/`） |
| 其余路由参数类 | `models/CharDetailModels.ets:11-15` `CharDetailRouterParam`（三个详情页 Builder 以 `param as CharDetailRouterParam` 强转，如 `StarRailCharacterDetailPage.ets:139`）；MaterialCharacterSelect 有**三份**独立定义：push 方 `ToolsPage.ets:117` 用 `viewmodel/MaterialCharacterSelectViewModel.ets:56` 的 `MaterialCharacterSelectParam`，接收方 `builders/MaterialCharacterSelectPageBuilder.ets:11-15`（`:20` 强转）与 `pages/MaterialCharacterSelectPage.ets:30-34` 各自定义未导出的同名 `MaterialCharacterSelectRouteParam` | push 方与接收方类型互不相关、接收方 `as` 强转，字段名不一致时编译不报错，运行时取到 `undefined`。字段不可改名；改 MaterialCharacterSelect 参数须三处同步 |
| 两套 `NavPathStack` | `utils/RouterUtil.ets` ↔ `pages/Index.ets:23-25`；`pages/MainPage.ets:60/415` | `RouterUtil` 只持有 `Index` 注入的**根栈**（承载 Launch / Main / PrivacyConsent，`Index.ets:8-16`）；全部 routerMap 页面走 Main 自己的 `stack`，以 `detailStack` 传给各 Tab（如 `MainPage.ets:195` 直接 `this.stack.pushPathByName`）。`RouterUtil.ets:4-5` 头注释"各页面通过静态方法跳转"不成立（见 L2）——用 `RouterUtil.push` 跳二级页会推到根栈、盖住整个 Main |
| `AccountSignal` 的双重语义 | `utils/AccountSignal.ets` ↔ 三个目标配置 VM（如 `GenshinMaterialTargetConfigViewModel.ets:180-188`；SR `:196`、ZZZ `:217` 同构） | 除登录 / 账号变更外，目标配置 VM 在**先 `saveConfig()` 成功、再 `compute()` 返回 `SUCCESS`** 时也 `notify()`，触发 Home / Characters / My / Tools 全部重载。选角页（`MaterialCharacterSelectViewModel.ets:293-297`）与三个材料清单页的计算路径**不** notify。Tools 依赖它刷新的是"已配置目标"的数量——`ToolsViewModel.ets:150-162` 的 `hasComputeData` 只查目标配置记录是否存在，不看计算结果；因此对 Tools 而言这条信号的实际含义是"目标配置已保存"。重构约束：①不能把这三处 `notify()` 当无关调用删掉；②也不能把它收进材料计算的统一发——那会让每次材料清单刷新都触发四页重载，属行为变化。现有小缺口：配置保存成功但计算返回 `NO_NEEDS` / `FAILED` 时不 notify，Tools 的已配置数不刷新（跨模块约定，随已移出的 `MaterialComputeService` 记录） |
| 人机验证 / 设备指纹监听注册时机 | `pages/MainPage.ets:94/96`（`aboutToAppear`） | **跨模块约定**：`GeetestCenter.init()` / `DeviceFpCenter.init()`（均已归属 features 模块，详见 [main](./main-module-analysis.md) 初始化链路）在 Main 出现时才注册 core 的上报监听（两文件头注释写的是"App 启动时调用一次"）。`HomeViewModel.ets:355-357`、`CharactersViewModel.ets:249-250` 遇到 1034 不自行提示，前提是 Center 已注册；M15 调整 Main 初始化顺序时必须保持"Main 首次出现前不会发出业务请求"或把注册前移 |
| `CookieExpiredSignal` 消费协议 | `utils/CookieExpiredSignal.ets:26-40` ↔ `pages/MainPage.ets:167-200` | Main 在自己的 `@Monitor('cookieExpiredSignal.queue')` 回调里出队（`:172-176`）以触发下一次回调；`:198-199` 把 `queue` 赋给自身属同引用赋值、不会再触发 `@Monitor`（已记为 [main](./main-module-analysis.md) L3）。重构时必须保持"出队 = 新数组引用" |

---

## 3. ArkTS 合规性检查

| 规则 | 状态 | 证据 |
| --- | --- | --- |
| `console.*` | ✅ 0 处 | `grep -rn "console\." utils models constants theme config styles builders` 无命中 |
| `any` / `as any` / `var` | ✅ 0 处 | 同上 |
| `forEach + await` | ✅ 0 处 | 同上 |
| 枚举替代字面量 | ⚠️ 见 M6 | `ViewStates` / `HeroPanelMode` / `LoginTabEnum` 有实际使用；`SignalMonitorKey` 的 `@Monitor` 路径值**无人引用**，37 处 `@Monitor` 全是字面量 |
| 魔法数字 | ⚠️ 少量 | `ColorUtil.Alpha` 已集中；`LegalPreferences` / `AccountSignal` / `SyncRetrySignal` 的 preferences key 为文件内常量 ✅；部分 utils（已归属 features 模块）内有等级上限 / 超时等常量化数字，但 M0 内部无其他硬编码魔法数字 |
| 模型层纯度 | ⚠️ 见 M3 | 4 个模型文件在字段/参数默认值里用 `$r()`（`HomeModels.ets:21/59/135/137/158`、`MyModels.ets:12/14/16/40`、`ToolsModels.ets:126/128`、`MaterialListModels.ets:130`）；`SnackbarParams.ets:16-32` 在方法里返回 `$r('sys.symbol.*')` 并读 `themeManager`；`MaterialTargetConfigModels` 头部却声明"Model 不应包含 ArkUI 类型" |
| 全局可变状态 | ⚠️ 见 M1/M2/L5 | `RouterUtil.stack`、`DialogDedup.activeKeys`、`TransparentColorCache.*`（其余如 `AppearanceManager.prefs`、`GeetestCenter.pendingAccounts/skippedAccounts`、`DeviceFpCenter.showing/dismissed` 归属已移出的 features 模块，记在对应模块文档中） |
| 死代码 / 未用导入 | ⚠️ 不计数 | `CookieExpiredSignal.ets:14` import 的 `Logger` 未使用、`:26` 的 `source` 参数（注释称"用于日志排查"）从未被读取；`MaterialTargetConfigModels.ets:14-18` 的 `GameId` / `CoreInitializer` / `Logger` 三个导入全部未使用；`SignalMonitorKey.HOME_GEETEST_TRIGGER = 'vm.geetestTrigger'` 指向 `HomeViewModel` 中不存在的字段；无引用的导出：`GameIdUtil.gameIdToPrimaryLabel`（`:39-42`，且映射有误——星铁 / 绝区零都返回"历练点"）、`GenshinElement.elementLabel`（`:34`）、`ZZZElement.zzzElementColor`（`:34`，只覆盖 8 种属性中的 5 种）、`MaterialTargetConfigModels` 的 3 个 `GenshinCompute*` 类（`:102-120`）、`AppRoutes.TOOLS`；`PrimaryButtonModifier` 的 `enabled=false` 分支（`PrimaryButtonModifier.ets` 中 `colorTextMuted`）无调用方使用（8 处全部传 `true`）（已移出的 `GeetestSignal` 内 `geetestSignal` 导出与 `resolveCancelAll()` 不在 M0 计数范围内） |

---

## 4. 复用分析

### 4.1 做得对的地方（保持）

- **5 个信号类同构**：都是"`AppStorageV2` 单例 + 队列/版本号 + 静态 `instance()`"，读法统一，M15 抽 `SignalBus` 有现成模式可循（注意 AppStorage key 来源不统一：2 个取 `SignalMonitorKey`，3 个用类内 `static readonly KEY`）。
- **`GameIdUtil` 双版本**：`gameIdToXxx(GameId)` 与 `gameIdStrToXxx(string)` 并存，字符串版的调用方是 widget 配置（`WidgetConfigViewModel`、`components/widgetsettings/*`，数据来自 `WidgetSlotRef.gameId`）与 `components/home/UserGameSection`；`widget/` 卡片本身不引用 `GameIdUtil`。由于 `GameId` 是字符串枚举，`gameIdToName/Color/Logo`（`:14-36`）与 `gameIdStrToName/Color/Logo`（`:50-76`）函数体逐行相同，属"为类型签名保留的重复"，改映射时两处都要改。
- **`TimeFormatUtil` 只吃 `UIContext`**：避免 `UIAbilityContext` 为 null 的分支，是正确取舍。

## 5. 安全审查

| 项 | 结论 |
| --- | --- |
| 凭据 | ✅ 共享层不持久化 cookie/token；`MaterialComputeService`（已归属 features/material）只是透传 `account.cookie` 不落盘；人机验证链路在内存中短暂持有 cookie（见下一行） |
| 明文存储 | ✅ 仅 `LegalPreferences`（是否同意隐私）、`AppearanceManager`（已归属 features/appearance，颜色模式非敏感数据），无敏感数据 |
| 日志 | ✅ `Logger.*` 只打印 uid / roleId / 错误码 / 失败接口 URL；养成目标配置 JSON（见已移出的 `MaterialComputeService`，不在 M0 计数）；未见 cookie 等凭据（与 Login 文档的 SEC-002 结论一致） |
| 人机验证 | ⚠️ **跨模块**：`GeetestSignal` / `GeetestCenter`（已归属 features/geetest）队列中的 `GeetestTrigger` 持有账号 `cookie`，仅在内存中，不落盘不打日志；`GeetestCenter.accountIdOf()` 在 Cookie 里取不到 `account_id/ltuid/stuid` 时用**整串 Cookie** 作账号标识（已归属 features/geetest），并经 `:79` 写进全局 `SyncRetrySignal.accountId`（见 L4）。`CookieExpiredSignal.expiredUsernames` 本次运行内保留，刷新 Cookie / 重新登录成功后由 `clearExpired` 移除（`CookieExpiredSignal.ets:51-56`，调用方 `AccountDetailViewModel.ets:83`、`LoginViewModel.ets:390`），属可接受 |
| 权限 | ✅ 共享层不申请权限（申请在 EntryAbility / 通知服务） |

---

## 6. 风险清单

### Medium

| # | 问题 | 位置 | 说明与建议 |
| --- | --- | --- | --- |
| M1 | `RouterUtil` 在未注入 `stack` 时**静默失败** | `utils/RouterUtil.ets:11-29`（`RouterUtil.stack?.pushPathByName`） | `?.` 让"忘记 `init`"或"`Index` 重建导致旧栈失效"变成无日志的空操作，表现为"点了没反应"。建议 `stack === null` 时 `Logger.error` 一次并暴露 `isReady`，不改调用方语义 |
| M2 | `DialogDedup` 的 key 只靠调用方 `release` | `utils/DialogDedup.ets:21-33`（`tryAcquire` / `release`） | 任一调用方在异常/页面销毁路径漏 `release`，该 key 在整个进程生命周期内**永久屏蔽**同类提示（含 Snackbar）。现有 5 处调用（`HomePage.ets:77/86/89`、`CharactersPage.ets:113/122/125`、`MainPage.ets:182/193/202`、`MaterialCharacterSelectPage.ets:332/350`、`FeedbackUtil.ets:34/44/56/59`）都已在关闭路径释放（其中 `MaterialCharacterSelectPage.ets:332-352` 只在 `showAlertDialog` 的 `onDidDisappear` 里释放，若 `showAlertDialog` 同步抛错 key 会永久占用，概率很低），**当前未发现实际泄漏**，风险在于协议脆弱、新增调用方极易漏写。可选方案是 `Map<string, token>` + 超时自动释放，但它会改变"显示期间不重复"的语义，不是行为等价（见 §7） |
| M3 | 模型层混入 ArkUI 类型，与自身约定冲突 | `models/HomeModels.ets:21 / 59`、`MyModels.ets:12-16`、`ToolsModels.ets:126/128`、`MaterialListModels.ets:130`（字段默认值 `$r(...)`）；`SnackbarParams.ets:8/16-32`（读 `themeManager`）；`models/MaterialTargetConfigModels.ets:6` 却声明"Model 文件不应包含 ArkUI 特定类型" | 两套约定并存，M0 无法给出统一规则。建议：模型只放 `ResourceStr` 之类的**类型**，默认值由 VM 填；widget 模型继续用纯字符串（卡片进程没有 `$r`） |
| M5 | `themeManager` 是 210 文件的中心节点，但字段无版本/无废弃策略 | `theme/ThemeManager.ets:32-37`（`@Trace current: Theme`） | M0 里任何 token 改名都会全量编译，且 `@Trace` 只对实例属性生效（不能把 `current` 改成静态）。建议 M0 只允许**追加**字段，禁止重命名；重命名单独立项 |
| M6 | 跨模块"隐式契约"分散，且 `@Monitor` 路径约定名存实亡 | `constants/SignalStorageKey.ets:26-50`（8 个 `@Monitor` 路径值全仓无引用；`:44` `HOME_GEETEST_TRIGGER = 'vm.geetestTrigger'` 指向 `HomeViewModel` 中不存在的字段）；实际 37 处 `@Monitor` 全是字面量（如 `MainPage.ets:167/225/284`、`HomePage.ets:47-100`、`CharactersPage.ets:52-130`）；`AppRoutes`（25 条路由）、`models/ToolsModels.ets:101-110` `MaterialTargetConfigParam` | 三者都是"字符串/结构必须一字不差"的契约，却分散在三个文件。`SignalMonitorKey` 头注释写"所有 `@Monitor` 必须使用此枚举"，代码从未执行：冻结它的值保护不了任何监听，真正脆弱的是页面里的字面量与 `@Local` 字段名 / VM 字段名的对应关系（改名后编译不报错，监听静默失效）。§2.4 已按实际情况修订；重构时以"字面量 ↔ 字段名"为冻结对象，`SignalMonitorKey` 要么真正接入 `@Monitor`，要么删掉无用的路径值——"接入"未经编译验证：`HomeViewModel.ets:68` 注释称 `@Monitor` 路径"必须是顶层 const"，enum 成员能否直接用需先编译确认。另有第二套同类约定：`HomeViewModel.ets:70-79` 导出 5 个 `HOME_VM_*` 路径常量，与 `SignalMonitorKey` 的 HOME_* 值重复、全仓无引用；`HomeViewModel` 被测试直接 import，这些导出名同样不可随意删除。`AppRoutes` 同理：常量与 `custom_router_map.json` / `Index.ets` `pageBuilder` 的对应关系没有任何编译期检查，`MATERIAL_CALC` 已因此不可达（High 计在 material-calc） |

### Low

| # | 问题 | 位置 | 说明 |
| --- | --- | --- | --- |
| L2 | 注释与代码不一致（四处） | `utils/ColorUtil.ets:79` 注释写"在 `CoreInitializer.initCore()` 中调用"，实际调用在 `EntryAbility.ets:23`；`config/RuntimeConfig.ets:8` 写"唯一允许读取 `BuildProfile.APP_ENV` 的地方"，但 `widget/utils/WidgetLogger.ets:35` 也直接读取；`RouterUtil.ets:4-5` 写"各页面通过静态方法跳转"，实际二级页走 Main 的 `stack`（§2.4）；`AccountSignal.ets:4-5` 只写"登录成功后调用"，漏了目标配置 VM 的调用（§2.4） | 重构时若照注释去 core 里找会找不到、误以为 `APP_ENV` 只有一个读取点、用 `RouterUtil` 跳二级页、或删掉目标配置 VM 里的 `notify()`；建议改注释 |
| L3 | `ThemeManager` 注释示例引用了**不存在**的 `DarkTheme` | `theme/ThemeManager.ets:24`（`themeManager.current = new DarkTheme()`）、`theme/AppTheme.ets:13`（"DarkTheme / 自定义主题按需覆盖"）；全工程无 `DarkTheme`/`LightTheme` 定义，深色模式实际走 `AppearanceManager.applyColorMode` → `context.setColorMode` + `resources/dark` | 容易诱导 M0/M3 去造一个假的 `DarkTheme` 抽象；建议把注释改为"如需主题对象切换，先实现 `Theme` 实现类" |
| L4 | `SyncRetrySignal.accountId` 无读取方，且可能被写入整串 Cookie | `utils/SyncRetrySignal.ets:15/17-19` 写入 `accountId`，全仓无读取（`HomePage.ets:95-97`、`CharactersPage.ets:95-97` 只看 `version`）；`GeetestCenter.ets:94-101` 取不到 `account_id/ltuid/stuid` 时返回整串 Cookie，经 `:79` `notify(trigger.accountId)` 写入该全局字段，`pendingAccounts/skippedAccounts` 也以它为 key | 仅在内存、不落盘不打日志，非漏洞；但凭据被放进一个任何页面都能 `AppStorageV2.connect` 到的全局对象且无用途。建议删除 `accountId` 字段（或只传 UID），`accountIdOf` 兜底改用 Cookie 的哈希 |
| L5 | `TransparentColorCache` 只在启动时按当时颜色模式计算一次 | `utils/ColorUtil.ets:81-104` 用 `getColorByNameSync('color_primary')` 计算 `blue500With15/60`，`EntryAbility.ets:23` 调用早于 `restoreOnLaunch` 完成；`color_primary` 有深色变体（`resources/base/element/color.json:120-121` `#007DFF` / `resources/dark/element/color.json:4-5` `#4DA3FF`） | 运行时切换深浅色（或用户设置与系统不同）后，`WidgetSlotOption.ets:86/90` 的选中态背景/描边仍是启动时模式的蓝色，与主题不一致（`black`/`white` 无深色变体，不受影响）。建议改为按需计算或在颜色模式变化时重算 |
| L7 | `PlaceholderState` 的 `@ObservedV2` / `@Trace` 实际不生效，且有一条无人使用的分支 | `components/common/PlaceholderView.ets:12-26`（`@ObservedV2` + 6 个 `@Trace`）；4 个调用方全部在 `build()` 里写对象字面量 `{...} as PlaceholderState`（`HomePage.ets:120-133`、`ToolsPage.ets:58-69`、`MaterialCharacterSelectPage.ets:92`、`CharactersContent.ets:68/80`），得到的是普通对象而非被观察实例，刷新全靠父组件重建时重新传入；`:37-44` 的 `sys.symbol.*` 分支（`$r(this.state.icon)`）没有调用方传入过 symbol 名（全部为 emoji） | 现状行为正确，但装饰器会误导重构者以为可以"就地改字段触发刷新"。若重构时把字面量改成 VM 持有的 `new PlaceholderState()`，刷新语义会变化，需单独验证。建议二选一：去掉装饰器明确为纯数据，或调用方统一 `new` |
| L8 | 剩余不足 1 分钟时首页显示"0 分钟后全部恢复" | `utils/TimeFormatUtil.ets:16-32`（`recoveryDesc`）：`seconds` 在 1-59 时 `h = 0`、`m = 0`，仍走 `time_minutes_recovery`（`:28`）；同文件 `formatSeconds` 对此有"即将恢复"分支（`:50-53`）。调用方 `components/home/GameStaminaBlock` | 体力将满时文案不准。修复会改变显示文案，单独提交或随 Home 模块（Spec M8）一起验证 |
| L9 | Snackbar 关闭时不释放 `ComponentContent` | `utils/FeedbackUtil.ets:42-46`：每次 `showFeedback` 新建 `ComponentContent`，`onDismiss` 只 `closeCustomDialog`，`.catch`（`:58-60`）也不处理；同仓 `components/GeetestDialogHelper.ets:83` 关闭后调用了 `contentNode.dispose()` | 每条 Snackbar 可能残留一个未释放的节点引用；实际是否泄漏需真机内存确认。补 `dispose()` 属资源释放、不改可见行为，可随 M0，但实现须覆盖两条关闭路径：定时器触发的 `onDismiss`（`:43-46`）与点外部 / 系统关闭的 `onDidDisappear`（`:55-57`，此时 `SnackbarContent` 已清定时器、`onDismiss` 不会执行），并像 `GeetestDialogHelper.ets:81-85` 那样在 `closeCustomDialog` 完成后再 `dispose()` |

---

## 7. 重构执行备注（M0 · 共享层）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 文件位置 | `utils/` `models/` `constants/` `theme/` `config/` `styles/` `builders/` 下 52 个文件、`components/common/` 2 个文件与 `components/SnackbarContent.ets` **全部原位不动**。这比 Spec §3（只要求中心节点原位不动）更严，理由：M0 没有直接单测，且下方列出的 32 个文件进入 Local Test 编译，移动任何一个都要同步改多处 import |
| `AppRoutes` | 25 个 `static readonly` 常量的**值**不可变（路由名字符串）；可以追加新常量 |
| `@Monitor` 路径 | 冻结对象是页面/组件里 37 处 `@Monitor('xxx.yyy')` 字面量与其指向的 `@Local` 字段名、VM 字段名（改任一侧都会让监听静默失效）。`SignalMonitorKey` 中只有 `GEETEST_SIGNAL_KEY` / `COOKIE_EXPIRED_SIGNAL_KEY` 两个 AppStorage key 在用，其余 8 个路径值无引用（见 M6） |
| 被测试直接引用 | `constants/ViewState`（7 个测试）、`constants/LoginConstants`（`LoginTab` / `PhoneStep`，LoginViewModel 测试）、`models/MaterialCalcModels`（`MaterialCalcCharacterVM`，MaterialCalc 测试）、`models/ToolsModels`（`GameEntryVM`，Tools 测试）。`models/HomeModels` 按保守口径**同样冻结**：`HomeViewModel.test.ets:4` 目前误指向不存在的 `components/home/HomeModels`，按 Q-9 修复后会指向它（与 Spec §2.5 一致） |
| 进入 Local Test 编译的 M0 文件 | 从 `entry/src/test/*.test.ets` 出发的相对 import 闭包（脚本计算，含多行 import）共 **32 个** M0 文件：utils `AccountSignal` `CharacterSort` `CookieExpiredSignal` `DialogDedup` `FeedbackUtil` `GameIdUtil` `GenshinPropertyUtil` `ServerNameUtil` `SyncRetrySignal` `TimeFormatUtil`；models `AccountOption` `CharDetailModels` `DailyNoteModels` `HomeModels` `MaterialCalcModels` `MyModels` `SnackbarParams` `ToolsModels`；constants `AppConstants` `AppRoutes` `FeedbackType` `GenshinElement` `LoginTabEnum` `SignalMonitorKey` `ViewStates`；theme `AppTheme` `DefaultTheme` `ThemeFonts` `ThemeManager`；`common/SegmentedTabBar`、`SnackbarContent`（全部经 10 个 VM 测试进入；9 个 widget / notification 测试不触达 M0）。它们的导出名与签名改动必须在同一提交内同步全部调用方，否则测试编译失败 |
| Q-10 修复后的测试目标 | 按保守口径一并冻结：`utils/TimeFormatUtil` 的 `formatSeconds` / `formatTransformer`（`:38/63`）、`utils/GenshinPropertyUtil` 的 `genshinPropertyTypeToResource`（`:56`）、`models/AccountOption` 的 `AccountOption`——[test-suite](./test-suite-analysis.md) T6 的修复方案会让测试直接引用它们 |
| 持久化 key | `AppearanceManager.ets:19-20` 的 `mihoyo_tool_preferences` / `app_color_mode`（注释称沿用旧 store 名以保留已有设置）；`LegalPreferences.ets:13-14` 的 `legal_prefs` / `hasAgreedPrivacy`（改名会让所有用户重新走隐私同意）；AppStorageV2 key：`SignalMonitorKey.GEETEST_SIGNAL_KEY` / `COOKIE_EXPIRED_SIGNAL_KEY` 与 `AccountSignal.KEY`（`:19`）、`SyncRetrySignal.KEY`（`:22`）。全部值不可变 |
| 主题 token | `Theme` 接口只允许**新增**字段；`themeManager` 实例名与 `current` 字段名不变 |
| `MaterialTargetConfigParam` | 位于 `models/ToolsModels.ets:101`，被三个目标配置页、三游戏材料清单页、选角页及其 ViewModel 共用，字段不可改名 |
| `MaterialCharacterSelectBuilder` | `builders/` 下的文件路径与函数名被 `custom_router_map.json:100-101` 冻结 |

### 重构范围（建议）

- **只做"加法"**：新增常量 / 新工具函数 / 新模型文件可以（L6 即新建 models 文件 + 原处 re-export）；重命名、移动已有文件一律不做（M0 没有直接单测，且 32 个文件进入 Local Test 编译，见冻结项与验收）。
- **可随模块修**：M1（RouterUtil 日志 + `isReady`）、L2 / L3（注释纠错）、L4（删无读取方的字段）、L9（Snackbar 关闭后 `dispose()`）、L6（`SegmentedTabItem` 移到 models + re-export）、§3 死代码清理 —— 都是行为等价或纯注释。死代码清理**不含** `AppRoutes.TOOLS`（25 个常量冻结）与 `SignalMonitorKey` 的值（去留待决策）。
- **M2 记录不执行**：`DialogDedup` 加超时自动释放会改变"同类弹框 / Snackbar 显示期间不重复"的语义（超时后可能重复弹出），不是行为等价；现有 5 处调用均已正确释放，暂无必要。
- **M7 / M8 单独提交**：`compute()` 外层补 `try/catch → FAILED` 会把"无反应"变成"计算失败"Toast；`GeetestCenter` 申请 / 提交失败时新增提示（需新增失败信号由 Main 消费）会改变用户可见行为。都属可感知的行为变化，按 Refactor_Spec"重构提交不夹带行为变更"单独提交或记录。（注：M7 `MaterialComputeService` 与 M8 `GeetestSignal`/`GeetestCenter` 已归属 features 模块，不再作为 M0 风险项跟踪）
- **M3 / M4 / M5 记录不执行**：模型层纯度、`MaterialComputeService` 拆分（已归属 features/material，不在 M0）、主题 token 治理都需要产品/架构决策，超出"保持行为"边界。
- **M6 已在 §2.4 修订契约**：`@Monitor` 字面量 ↔ 字段名、`MaterialTargetConfigParam` 已写入契约表；`SignalMonitorKey` 是接入还是删除无用值需决策，M0 内不动。
- **L5 / L7 / L8 记录**：L5 涉及深色模式下颜色变化，需与 M3 外观设置一起验证；L7 改动会改变刷新语义；L8 改显示文案。均不在 M0 的行为等价提交内。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. **无直接单测**：工具函数本身没有单测，但 32 个 M0 文件进入 Local Test 编译（见冻结项），Local Test 能否编译通过是 M0 的有效回归信号 —— 验收走"编译 + Local Test（修复阻塞后）+ 引用方冒烟"。**前置条件（测试资产，按 README §1.4 不计入本模块评级）**：`entry/src/test` 当前有 5 个测试文件存在编译阻塞（见 [test-suite-analysis.md](./test-suite-analysis.md) T1 / T6；Refactor_Spec §0.4 已同步），任何一处都会让整个 Local Test 无法编译；其中与 M0 直接相关的有两处——① `entry/src/test/HomeViewModel.test.ets:4` 从不存在的 `../main/ets/components/home/HomeModels` 导入 `GAME_GENSHIN` / `GAME_STARRAIL` / `GAME_ZZZ`（全仓无定义），`:89` 又给 `gameColor(gameId: GameId)` 传字符串 `'unknown_game'`；该套件已在 `List.test.ets:2` 注册，编译失败会阻塞整个 Local Test 入口。`entry/src/test` 在重构作用域外，修复需 Refactor_Spec §8 Q-9 批准（见 [test-suite-analysis.md](./test-suite-analysis.md) T1）；只改 import 路径不够，还需把三个常量换成 `GameId` 枚举值；② `GenshinDailyDetailViewModel.test.ets:34` 等用索引调用 VM 上已不存在的 `formatSeconds` / `formatTransformer`，二者已迁到 `utils/TimeFormatUtil.ets:38/63` 且多一个 `uiCtx` 参数，修复需 Q-10 批准。
3. 若改了 RouterUtil / DialogDedup：额外冒烟四条路径——任意二级页 push/pop、Cookie 过期弹窗、人机验证弹窗、Snackbar 连续触发。
4. `MaterialComputeService` 已归属 features/material，相关冒烟在 material 模块文档中跟踪；M0 内不单独执行。
5. 若改了 `SyncRetrySignal`（L4）或涉及人机验证信号（跨模块约定，`GeetestCenter`/`GeetestSignal` 已归属 features/geetest）：人机验证通过后首页 / 角色页重新同步；账号详情"重新生成设备指纹"后首页 / 角色页重新同步。M8 行为变更跟踪在 geetest 模块文档中。
6. 若改了 `SegmentedTabBar`（L6）：角色页切换游戏 Tab、三游戏材料清单切换"按角色 / 按材料"视图。

### 已知问题归属

- **Medium 5 项**：M1 可随 M0 做；M2（超时释放非行为等价）、M3/M4/M5 需决策；M6 已落到契约表（`SignalMonitorKey` 去留需决策）；M7 `MaterialComputeService` 与 M8 `GeetestCenter`/`GeetestSignal` 已归属 features 模块，不再作为 M0 风险项跟踪。
- **引用（不在本文计数）**：外观设置页 High 的修复点是 `AppearanceManager.applyColorMode`（`:61-83`）——`setColorMode` 与持久化失败都被内部 catch（`:71-73`、`:80-82`），且 `cachedColorMode` 在切换成功前就已写入（`:66`），失败时 My 页显示的模式与实际不符。需改为返回成功与否（或重新抛出），与 M3 一起改、一起验证。
- **Low 9 项**：L2/L3/L4/L9 可顺手做，其中 L2/L3 是纯注释纠错，建议先做（避免误导后续模块）；L1 改为 `await restoreOnLaunch` 会改变启动时序，记录并留给 M15（EntryAbility）；L5 与 M3 外观设置一起验证；L6 随 M0（移动类 + re-export，行为等价）；L7 记录，去装饰器或改 `new` 需单独验证刷新；L8 改文案，单独提交。
- **测试资产（不计数）**：`HomeViewModel.test.ets` 引用失效模块、`GenshinDailyDetailViewModel.test.ets` 引用已迁走的方法，归 [test-suite-analysis.md](./test-suite-analysis.md) T1 / T6 / Refactor_Spec §8 Q-9 / Q-10。
- **测试空白**：`utils/` 22 个文件、`models/` 13 个文件、`theme/` 4 个文件**没有任何直接单测**；现有测试只引用其中的枚举（`ViewState` / `LoginTab` / `PhoneStep`）与 2 个模型类（`MaterialCalcCharacterVM`、`GameEntryVM`）。

---

## 8. 依赖文件索引

| 方向 | 内容 |
| --- | --- |
| utils → core | 8 个文件 import `'core'`：`CookieExpiredSignal`、`DialogDedup`、`GameIdUtil`、`GenshinPropertyUtil`、`StarRailPropertyUtil`、`LegalPreferences`、`ServerNameUtil`、`MaterialRoutes`（`ColorUtil` / `FeedbackUtil` 等其余文件不依赖 core；已移出的 `MaterialComputeService` / `GeetestCenter` / `DeviceFpCenter` / `AppearanceManager` / `GeetestSignal` 原 import core，现归属对应 features 模块） |
| models → core / constants / theme | 8 个模型 import `'core'`（其中 `MaterialTargetConfigModels` 的导入实际未使用；主要是 `GameId`，另有 `GeetestCreateResult`、`ZZZCardSign` 等）；`SnackbarParams` → `constants/FeedbackType` + `theme/ThemeManager`；`WidgetSettingsModels` → `widget/` + `viewmodel/`（§2.1 例外）；`CharDetailModels` / `DailyNoteModels` / `AccountOption` 无任何 import |
| constants → core | `GenshinElement` / `StarRailElement` / `ZZZElement` 从 core 重导出枚举 |
| theme → 无 | `AppTheme` / `DefaultTheme` / `ThemeFonts` 不依赖任何业务模块 |
| 被谁依赖 | `viewmodel/`、`components/`、`pages/`、`entryability/` / `widgetsyncability/`（`RuntimeConfig`、`AppearanceManager`、`ColorUtil`）；`widget/` 只有 14 个文件 import `theme/DefaultTheme`（`WidgetUtils` 自持颜色映射，不引用 `GameIdUtil`）；`notification/` 不 import 任何 M0 文件（`NotificationModels` + `StaminaThresholdCalculator` 在 notification 内，不属于 M0） |

---

## 9. 修复状态（2026-10-28，代码已改、待本地编译验证）

决策依据 `.opencode/skills`：`state-management` 范例 5 直接用 `@Monitor('path')` 字面量；`harmonyos-development`「Dark mode adaptation」推荐资源限定词方案并在 `onConfigurationUpdate` 响应颜色变化；`harmonyos-review` checklist `STATE-005`（被观察对象须为 `@ObservedV2` 实例）。

| 条目 | 状态 | 改动 |
| --- | --- | --- |
| M1 | ✅ 已修 | `RouterUtil` 未注入时 `Logger.error` 并 `return`；新增 `isReady()`；头注释写明只管根栈 |
| M2 | 记录（D2） | 不加超时释放（会改变"显示期间不重复"语义，skills 无要求）；只修唯一脆弱点：`MaterialCharacterSelect.showConfigRequiredDialog` 的 `showAlertDialog` 包 try/catch，抛错时释放 key |
| M3 | 记录（D3） | skills 无"模型禁用 `$r`"要求，不改；`MaterialTargetConfigModels` 头注释改为如实描述 |
| M4 | 已移出（不在 M0） | `MaterialComputeService` 归属 features/material，拆分/批量读随材料模块重构跟踪 |
| M5 | 规则落地（D4） | `AppTheme.ets` 头注释与 Refactor_Spec §2.4 写明"`Theme` 字段只追加、不改名"；项目深浅色走资源限定词，符合 skill 推荐 |
| M6 | ✅ 部分已修（D1） | `SignalMonitorKey` 删除 8 个无人引用的 `@Monitor` 路径值，只保留 2 个 AppStorage key，头注释改为"`@Monitor` 写字面量"；`HomeViewModel` 的 `HOME_VM_*` 常量被测试 import 的文件导出，留给 M8 |
| M7 | 已移出（不在 M0） | `MaterialComputeService` 归属 features/material，其返回值契约缺口等风险由 material 模块文档跟踪 |
| M8 | 已移出（不在 M0） | `GeetestSignal` / `GeetestCenter` 归属 features/geetest，人机验证失败无反馈问题由 geetest 模块文档跟踪 |
| L1 | ✅ 已修（D5） | `restoreOnLaunch` 改为 `getPreferencesSync` 同步读取并应用（与 `LegalPreferences` 相同写法），在 `loadContent` 前完成，消除首帧闪烁；`EntryAbility` 调用方式不变 |
| L2 / L3 | ✅ 已修 | `ColorUtil` / `RuntimeConfig` / `RouterUtil` / `AccountSignal` / `ThemeManager` / `AppTheme` 注释改正 |
| L4 | ✅ 已修 | 删除 `SyncRetrySignal.accountId`，`notify()` 改无参；跨模块调用方（`GeetestCenter`/`DeviceFpCenter` 已归属 features）同步更新 |
| L5 | ✅ 已修 | 启动时随 L1 按用户模式计算；`EntryAbility.onConfigurationUpdate` 中重算 `TransparentColorCache`（缓存非响应式，已显示的页面在重建时更新） |
| L6 | ✅ 已修 | 新建 `models/SegmentedTabItem.ets`；`SegmentedTabBar.ets` re-export 保持原导入路径；`CharactersViewModel` 改从 models 导入 |
| L7 | ✅ 已修 | `PlaceholderState` 去掉无效的 `@ObservedV2` / `@Trace`，注释说明须由父组件传新对象 |
| L8 | ✅ 已修 | `recoveryDesc` 不足 1 分钟时显示已有文案 `time_soon`（"即将恢复"） |
| L9 | ✅ 已修 | `FeedbackUtil` 在 `onDidDisappear`（覆盖定时关闭 / 点外部 / 系统关闭）与打开失败时 `dispose()`，延后一轮事件循环且防重复 |
| 死代码 | ✅ 已清 | `MaterialTargetConfigModels` 三个未用 import 与 3 个 `GenshinCompute*` 类、`CookieExpiredSignal` 未用的 `Logger`、`GameIdUtil.gameIdToPrimaryLabel`、`GenshinElement.elementLabel`、`ZZZElement.zzzElementColor`。未动：`AppRoutes.TOOLS`（冻结）、`geetestSignal` 模块级常量（删除会改变 AppStorageV2 实例创建时机）、`resolveCancelAll`（不可达原因在 Main，归 M15） |
| 外观页 High 的 M0 修复点 | ⏸ 待批准 | `applyColorMode` 改为返回成功与否后，页面需要失败提示文案（同 M8，需新增字符串资源） |

**修复后剩余**：Medium——M2 / M3 / M4 / M5 记录或留给后续模块，M6 剩 `HOME_VM_*`（M8），M7 剩"部分失败"（需产品决策），M8 待批准；Low——全部已修。

**验证**：本环境无 DevEco 工具链，上述改动未编译。需在本地执行 Refactor_Spec §7 第 4-5 步（`assembleHap` + `codeLinter`），并走 §7 验收第 3-6 条冒烟。

---

*§1-§8 为基线分析；2026-10-28 的代码修复记录见 §9。*

### 复核记录（2026-10-26 第 4 轮）

| 检查项 | 结论 |
| --- | --- |
| 目录计数 | 52 文件 / 4,481 行（utils 22·1,920 / models 13·1,613 / constants 10·338 / theme 4·538 / config 1·14 / styles 1·36 / builders 1·22）与 `find+wc` 完全一致 |
| 锚点 | `RouterUtil.ets:11-29`、`DialogDedup.ets:20-32`、`HomeModels.ets:21/59`、`MaterialComputeService.ets:134-168/242/375`、`ColorUtil.ets:79`、`ThemeManager.ets:24` 全部命中预期行 |
| 中心节点 | `ThemeManager` fan-in 211 个文件复核通过（`grep -rl themeManager`） |
| 变更 | M4 补充第二处重复循环（`:365-383`，`:375` 的 `getAvatarDetail`）；计数维持 0/0/7/3，债务 17 |

### 复核记录（2026-10-27 第 5 轮：逐条回代码）

| 检查项 | 结论 |
| --- | --- |
| 目录计数 | 52 文件 / 4,481 行，逐文件 `wc -l` 与 §1 表格一致（无变化） |
| 计数口径 | 原 M7（`HomeViewModel.test.ets` 引用失效模块）属测试资产，按 README §1.4 移出风险清单，改记 §7「验收」前置条件；其中 `'unknown_game'` 行号 L86 → **L89** |
| 新增 | M7 `compute()` 三处 `await` 不在 try 内（`:151-154/232/349`）；L4 `SyncRetrySignal.accountId` 无读取方且可能存整串 Cookie；L5 `TransparentColorCache` 不随深浅色重算 |
| 改写 | M6：`SignalMonitorKey` 实际未被任何 `@Monitor` 使用（37 处全为字面量），§2.3 / §2.4 / §3 / §7 冻结项同步修订；M2 注明现有 5 处调用均已正确释放；M4 锚点改为真实重复片段 `:236-245`/`:369-378`、`:314-323`/`:417-426`，并注明 `getAvatarDetail` 是本地 DB 读；L1 纠正"`getCachedColorMode` 可替代等待"的错误建议；L3 补 `AppTheme.ets:13` |
| 中心节点 | `themeManager` import 方为 **210**（原 211 含定义文件 `ThemeManager.ets` 自身注释）；`CharDetailModels` 41 = 4 VM + 3 页 + 34 组件；信号读写方按 grep 重列 |
| 引用方 | 修正 `GeetestCenter`（仅 Main）、`DeviceFpCenter`（Main + AccountDetailVM）、`SyncRetrySignal`（HomeViewModel 只在注释）、`AppearanceManager`（+My）、`GameIdUtil`（6 VM + 8 组件/页面 + 2 utils）、`CookieExpiredSignal`、`TimeFormatUtil`、`RuntimeConfig`（+WidgetSyncAbility）；§8 `utils → core` 名单改为实际 12 个文件 |
| 结果 | 0 / 0 / 7 / 5，评级 B，债务 17 → **19**，密度 0.42 / 百行 |

### 复核记录（2026-10-27 第 6 轮：独立复核第 5 轮改动 + 补齐 Spec M0 范围）

| 检查项 | 结论 |
| --- | --- |
| 第 5 轮改动 | 逐条回代码复核：M7 三处裸 `await`（`:151-154/232/349`，原神分支 `:178-199` 已在 try 内）与 7 个 `try/finally` 无 catch 的调用方成立；`@Monitor` 39 处命中中 2 处为注释，实际 37 处、0 处引用 `SignalMonitorKey`；`themeManager` import 方 210；`CharDetailModels` 41；`GameIdUtil` 16；`ViewStates` 35（viewmodel 15、测试 7）；`utils → core` 12；widget 引 `DefaultTheme` 14；L1-L5 锚点全部命中 |
| §2.1 | 补注 `builders → pages` 为按设计存在的反向边 |
| 范围 | 新增 §1.5：Spec §4 划入 M0 的 12 个 `components/` 文件逐个核 import 方；`common/` 2 个计入本文，根级 10 个只列建议归属 |
| 新增 | L6 `SegmentedTabItem` 定义在组件文件致 VM 反向依赖；L7 `PlaceholderState` 装饰器不生效 + 无人使用的 symbol 分支 |
| 结果 | 0 / 0 / 7 / 7，评级 B，源行数 4,481 → 4,702，债务 19 → **21**，密度 **0.45 / 百行** |

### 复核记录（2026-10-27 第 7 轮：54 个文件逐个通读）

| 检查项 | 结论 |
| --- | --- |
| 方法 | 54 个文件逐个通读（utils 22 / models 13 / constants 10 / theme 4 / config / styles / builders / common 2）；§1 每个文件的"引用方"用 `grep -rl "/<文件名>'"` 重核，22 个 utils 全部一致；全部导出符号跑一遍全仓引用计数（含 `entry/src/test` 与 `core`） |
| 新增 | **M8** `GeetestCenter.verify()` 失败静默 + 账号本次运行永久跳过 |
| 扩充 | M7 补 `toResult()` 部分失败仍返回 `SUCCESS`；§7 补外观页 High 在 M0 的修复点（`applyColorMode` 吞异常 + 先写缓存） |
| 遗漏补齐 | §2.1 `WidgetSettingsModels ↔ WidgetConfigViewModel` 循环导入；§1.3 / §2.4 `AppRoutes` 25 个常量的注册情况与"常量 ↔ routerMap 编译器不检查"契约；§3 死代码补 6 项（`gameIdToPrimaryLabel` 映射错误、`elementLabel`、`zzzElementColor`、3 个 `GenshinCompute*`、`AppRoutes.TOOLS`、`PrimaryButtonModifier` 置灰分支） |
| 更正 | §1.2 `MaterialTargetConfigModels` 行：`GenshinComputeItem` 并未被使用 |
| 排除 | `starRailRankBonus` 按中文文案解析：core 请求固定 `lang=zh-cn`（`StarRailApiService.ets:112`），不成立；`DefaultTheme` 颜色全部 `$r('app.color.*')`，深色模式正常；`FeedbackUtil` key 三条释放路径齐全；`GeetestDialogHelper` / `SnackbarContent` 两条反向边无环 |
| 结果 | 0 / 0 / **8** / 7，评级 B，债务 21 → **23**，密度 **0.49 / 百行** |

### 复核记录（2026-10-27 第 8 轮：全文通读 + 剩余锚点）

| 检查项 | 结论 |
| --- | --- |
| 锚点 | 补核此前未亲自打开的锚点：`custom_router_map.json:100-101`、`AccountDetailViewModel.ets:83`、`LoginViewModel.ets:390`、`HomeViewModel.ets:276`、`MainPage.ets:94`、`MaterialCharacterSelectPage.ets:303`、`WidgetUtils.ets:34-39`、`HomePage.ets` / `CharactersPage.ets:95-97` 全部命中；测试对共享层的直接 import 为 ViewStates×7 / LoginTabEnum / MaterialCalcModels / ToolsModels，与 §7 冻结项一致 |
| 自相矛盾 | §7「可随模块修」原把 M2「超时自动释放」列为行为等价——超时释放会改变不重复弹出的语义，改为记录不执行；「已知问题归属」原写"L1/L2/L3/L4 都可顺手做"，L1 会改变启动时序，改为留给 M15 |
| 补漏 | M6 补 `AppRoutes ↔ routerMap` 无编译期检查；§3 全局可变状态补 M8；§7 验收补 L4 / M8 / L6 的冒烟路径；第 8 行定位描述改为 54 个文件 |
| 结果 | 计数不变：0 / 0 / 8 / 7，评级 B，债务 23，密度 0.49 |

### 复核记录（2026-10-27 第 9 轮：独立审稿 + 逐条回代码确认）

| 检查项 | 结论 |
| --- | --- |
| 方法 | 独立审稿人（不提供既有结论）通读 55 个文件与本文；其每条发现均由复核者回代码确认后才采纳 |
| 错误更正 | §2.2 信号读写方：`HomeViewModel.ets:276-280` 是 push（写）、`AccountDetailPage.ets:27` 不 `@Monitor`、补 Main 为写入方；§1.3 `QRCodeStat` 未被测试引用；Main 锚点 `:300-301` / `:309-317` |
| 遗漏补齐 | §7 新增"被测 VM 间接引用"冻结项（约 20 个 M0 文件经 10 个被测 VM 进入 Local Test 编译）；验收前置条件补 `GenshinDailyDetailViewModel.test` 依赖已迁到 `TimeFormatUtil` 的方法；§2.4 新增 `GeetestSignal` 消费协议（每项必 resolve）；§2.2 补 `ThemeFonts`（83）为第五个中心节点；§2.1 补 `GeetestDialog ↔ GeetestDialogHelper` 循环 |
| 改写 | M8：涵盖申请失败（`:64-67`）；注明"本次启动不再弹"是有意设计，缺陷限定为"无反馈"；补修复约束（`GeetestCenter` 无 `UIContext`）。M7：补修复后 MaterialList VM 会多一次 `loadData()`。M4：重复片段除 Logger tag 外相同 |
| 新增 | L8 `TimeFormatUtil.recoveryDesc` 1-59 秒显示"0 分钟"（调用方 `GameStaminaBlock.ets:80`） |
| 不一致 | 死代码清理排除冻结的 `AppRoutes.TOOLS` 与待决策的 `SignalMonitorKey` 值；`SnackbarContent` 按 Spec §4 计入 M0（55 文件 / 4,795 行）；`models/HomeModels` 按保守口径冻结；文件"全部不动"比 Spec §3 更严，已写明理由；摘要补判级说明（M1/M2/M5/M6 为技术债类 Medium）。Spec 同步：§2.1 / §9 fan-in 211→210，§2.2 / §6.1 / §9 "循环导入会编译报错"更正为"现存循环可编译、不得新增" |
| 结果 | 0 / 0 / 8 / **8**，评级 B，源行数 **4,795**，债务 23 → **24**，密度 **0.50 / 百行** |

### 复核记录（2026-10-27 第 10 轮：全文通读找残留）

| 检查项 | 结论 |
| --- | --- |
| 机器检查 | M 8 行 / L 8 行与摘要一致；正文 `file:line` 锚点 0 处越界；正文无残留旧数（4,702 / 54 文件 / Low 7 / 债务 23 / 四个中心节点） |
| 残留修正 | 第 9 轮改写 M8 后，摘要（第 27 行）与 §7 范围 / 验收第 5 条仍用"静默放弃 / 不再永久跳过 / 下次仍会弹验证"旧说法，统一为"无提示，是否仍弹由产品决定"；§7"只做加法"原写"M0 没有测试保护"，与新增的间接测试冻结项矛盾，改为"无直接单测"并注明 L6 属新建文件；"L4 / L5 记录"与"L4 可随 M0"冲突，改为"L5 / L7 / L8 记录"；M2 建议注明超时释放非行为等价；摘要测试资产段补 `GenshinDailyDetailViewModel.test`；验收前置条件 ② 补 Q-10；§1.2 `HomeModels` 行指向 §7 冻结 |
| 结果 | 计数不变：0 / 0 / 8 / 8，评级 B，债务 24，密度 0.50 |

### 复核记录（2026-10-27 第 11 轮：第二位独立审稿人 + 逐条回代码确认）

| 检查项 | 结论 |
| --- | --- |
| 错误更正 | `ThemeFonts` fan-in 83 → **82**（83 含 `ThemeManager.ets:11` 注释）；`FeedbackUtil` 并非"用完即销毁"（不 `dispose()`）；"约 20 个文件进入 Local Test"改为脚本计算的 **32 个**；`MaterialComputeService` 签名变化影响 7 个 VM（页面只用枚举） |
| 遗漏补齐 | §7 冻结项补 Q-10 修复后的测试目标（`TimeFormatUtil` / `GenshinPropertyUtil` / `AccountOption`）与持久化 key（Preferences 两组 + 5 个 AppStorageV2 key）；§2.4 补其余路由参数类、`DeviceFpCenter` 与 `CookieExpiredSignal` 消费协议、`resolveCancelAll` 不可达；§2.3 补"全仓无 `themeManager.current` 赋值，主题响应式休眠"；§2.1 补 `components/widgetsettings/preview/` 10 个文件 `new DefaultTheme()` 与 `GenshinElementBgUtil → AppTheme`；L2 补 `RuntimeConfig` 注释错误 |
| 新增 | L9 Snackbar 关闭不 `dispose()` `ComponentContent`（`FeedbackUtil.ets:42-46`，对照 `GeetestDialogHelper.ets:83`） |
| 不一致 | 测试阻塞数改为"5 个测试文件"（"6 处"取决于计数方式）。Spec 同步：§2.1 / §2.2 `ThemeFonts` 82；§0.4 阻塞数；§4 M8 行 `HomeModels` 路径；§4 跨模块共享组件列表；§11 M0 行（L8 单独提交、L9 随 M0）、M3 行（修复会改变 UI 行为、单独提交）、M7 行（1 High）；README MaterialCalc 行按其文档当前摘要更新 |
| 结果 | 0 / 0 / 8 / **9**，评级 B，债务 24 → **25**，密度 **0.52 / 百行** |

### 复核记录（2026-10-27 第 12 轮：第三位独立审稿人 + 逐条回代码确认）

| 检查项 | 结论 |
| --- | --- |
| 错误更正 | 32 个 M0 文件全部经 10 个 VM 测试进入（脚本分别从 VM 测试 / 其余 9 个测试出发计算：32 / 0），删去"部分经 notification / widget 测试"；`MaterialTargetConfigModels.ets:14-18` 三个 core 导入全部未使用；"210 处 `@Local tm`"改为 208 个文件 261 处 |
| 遗漏补齐 | §2.4 补 `AccountSignal` 兼作材料计算完成信号、两套 `NavPathStack`（`RouterUtil` 只管根栈）、MaterialCharacterSelect 路由参数三份定义、Geetest / 设备指纹监听在 Main `aboutToAppear` 注册；M6 补 `HOME_VM_*` 第二套路径常量与"接入"方案未经编译验证；L2 由两处注释错误扩为四处 |
| 限定说明 | M2 注明 `MaterialCharacterSelect` 仅在 `onDidDisappear` 释放；L9 修复须覆盖 `onDismiss` 与 `onDidDisappear` 两条路径并在关闭完成后 dispose |
| 不一致 | `builders/` 归属写明（M0 管位置，内容随 M7）；验收前置条件中"Spec §0.4 原只列 3 个"已过期，改为"已同步"。Spec 同步：§2.4 `@Monitor` 行补 M1 / M2 / M7，§2.4 补持久化 key、路由参数类、`AccountSignal` 双重语义，§2.5 补 Q-10 测试目标，§4 M0 / M7 行注明 builders 归属；README §4 共享层行数更新 |
| 结果 | 计数不变：0 / 0 / 8 / 9，评级 B，债务 25，密度 0.52（新增内容均为契约 / 说明，L2 为同一条目扩充） |

### 复核记录（2026-10-28 第 13 轮：第四位独立审稿人 + 逐条回代码确认）

| 检查项 | 结论 |
| --- | --- |
| 错误更正 | `@Local … = themeManager` 为 207 个文件 / 260 处（原 208 / 261 含 `ThemeManager.ets:15` 注释）；§2.4 `AccountSignal` 契约改写：只有目标配置 VM 在保存成功且计算 `SUCCESS` 时 notify，选角页 / 材料清单不 notify，Tools 的 `hasComputeData`（`ToolsViewModel.ets:150-162`）只看配置是否存在，信号对 Tools 的实际含义是"目标配置已保存"；补"不能收进 `compute()` 统一发"的约束 |
| 不一致 | Spec §11 M0 行 Low 描述补回 L3、注释错误数改为四处、补 L1 / L5 / L7 去向；Spec §3 写明 `config/ styles/ builders/`"保持不变"指文件位置 |
| 已核实无误 | 计数、fan-in、32 个测试闭包文件、§1.1 引用方、M1-M8 / L1-L9 锚点、两条循环导入均由审稿人独立复核通过 |
| 结果 | 计数不变：0 / 0 / 8 / 9，评级 B，债务 25，密度 0.52 |

【已核对代码一致性】
