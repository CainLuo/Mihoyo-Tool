# Main 模块分析

> **审查对象**：`entry/src/main/ets/pages/MainPage.ets`（513 行，`struct MainPage`）
> **审查日期**：2026-10-24（2026-10-27、2026-10-29 多轮逐条复核；第 10 轮见 §11）
> **审查者**：AI 助手（`skills/harmonyos-review` checklist 全量扫描 + 独立审稿）
> **代码版本**：`e00e579`（First refactor，结构迁移后的代码）。文中 `:行号` 未注明文件时指 `MainPage.ets`；其他文件按迁移后的路径给出（见 [project-structure.md](./project-structure.md)）
> **HarmonyOS targetSDK**：API 22（`6.0.2(22)`，`build-profile.json5:27`）
> **口径**：skills `harmonyos-review` 官方评级（A-F，按 Critical/High/Medium 计数）
> **路径说明**：按项目既有约定放在 `docs/<module>-module-analysis.md`（[docs/README.md](./README.md) §6），不采用 skill 默认的 `docs/reviews/` 目录，避免打断现有 30 份文档的交叉引用
> **旧版结论**：85/100（百分制，已废弃——旧表存在 `代码质量 6/5` 的非法分值）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 2 |
| Medium | 11 |
| Low | 5 |

**整体评级：B**

> 一句话结论：MainPage 是全应用唯一的框架容器，Navigation + Tab + 标题栏协议 + 弹窗仲裁 + 折叠屏适配五件事压在一个 513 行文件里。没有阻断性问题；两个 High：**窗口尺寸监听会被人机验证弹窗整体注销**（H1），首次人机验证之后折叠屏展开/折叠不再切换单双栏；**用返回手势 / 侧滑 / ESC 关闭人机验证弹窗后，验证队列永久卡死**（H2，2026-10-29 复核恢复：10-27 以「用户始终能通过 UI 关闭」撤回原 H2 的理由漏了返回手势这条关闭路径）。原「共享路由栈」High 经 10-27 复核撤回，`windowClass` 快照降为 Medium（M7），见 §6「复核撤回 / 改判」。另有一项待真机确认的 Medium：在首页等 Tab 根页按返回，可能把 MainPage 本身从根栈弹出、显示空白页（M10）。

---

## 1. 基本信息

| 属性 | 值 |
|------|-----|
| 位置 | `entry` 模块 `pages/`（应用框架页，留在入口模块） |
| 行数 | 513（全项目页面文件中最大，其次 `features/material/.../MaterialCharacterSelectPage.ets` 499 行） |
| 装饰器 | `@ComponentV2` |
| 导出 | `MainPage`、`MainPagePreview` |
| 入口关系 | 由 `pages/Index.ets` 的 `pageBuilder` 分发，是 4 个 Tab 的唯一宿主 |
| 状态字段 | 29 个（`@Local` 16、非 `@Local` 13） |
| `@Monitor` | 3 个 |
| 模块级 `@Builder` | 1 个（`accountSwitchDialogBuilder`）✅ 非内联 |
| 内联 `@Builder` | 0 ✅ 无违规 |

---

## 2. Import 依赖清单（13 条 import，33 个符号）

| 来源 | 符号 | 说明 |
|------|------|------|
| `@kit.ArkUI` | `ComponentContent`、`SymbolGlyphModifier`、`promptAction`、`window`、`display` | 弹窗、图标、窗口、屏幕方向 |
| `@kit.AbilityKit` | `common` | `UIAbilityContext` 强转（设备指纹重生成，`:251`；`getHostContext()` 可能为 undefined，强转未判空，出错时进入 `:253` 的 catch 并提示失败） |
| `basic`（common/basic） | `themeManager`、`ThemeManager` | 主题 |
| | `AccountSwitchDialog`、`AccountSwitchDialogParams`、`splitPlaceholderBuilder` | 账号切换弹窗、分栏占位 |
| | `AccountOption` | 账号切换选项（`:12`） |
| | `CookieExpiredSignal` | Cookie 过期信号 |
| | `DialogDedup`、`showFeedback`、`getGameName` | 去重、反馈、游戏名映射 |
| | `AppRoutes`、`FeedbackType` | 路由名与反馈类型 |
| `home` / `characters` / `material` / `account` | `HomePage`、`CharactersPage`、`ToolsPage`、`MyPage` | 4 个 Tab 内容 |
| `verification` | `GeetestSignal`、`GeetestQueueItem`、`showGeetestDialog`、`GeetestCenter`、`DeviceFpCenter`、`DeviceFpInvalidSignal` | 人机验证与设备指纹 |
| `core` | `FailedAccountInfo`、`GameId`、`GeetestVerifyInput`、`Logger` | 共享类型与日志 |
| `BuildProfile`（构建期生成） | `BuildProfile` | DEBUG 判定（测试页入口） |

**观察**：MainPage 直接依赖 6 个全局信号/中心类（`CookieExpiredSignal`、`GeetestSignal`、`DeviceFpInvalidSignal` 3 个 Signal + `GeetestCenter`、`DeviceFpCenter` 2 个 Center + `DialogDedup`），是全项目耦合面最广的页面。这本身不是错误——全局弹窗必须由最上层容器统一调度——但意味着**任何信号的接口变更都会波及 MainPage**。

---

## 3. 状态与字段清单

### 3.1 Tab 与导航（3）

| 字段 | 类型 | 作用 |
|------|------|------|
| `selectedTab` | `@Local number` | 当前 Tab 索引（0-3） |
| `tabVersion` | `@Local number` | 强制 toolbar 重算的计数器（见 M1） |
| `isSplit` | `@Local boolean` | 分栏模式标志，透传给 HomePage / CharactersPage / MyPage |

### 3.2 窗口与响应式（2 + 1 private）

| 字段 | 类型 | 作用 |
|------|------|------|
| `navMode` | `@Local NavigationMode` | Stack / Split |
| `windowWidthVp` | `@Local number` | 窗口宽（vp），驱动 navBarWidth |
| `currentWindowStatusType` | `private window.WindowStatusType \| undefined` | 分屏/悬浮判定 |

### 3.3 共享路由栈（1）

| 字段 | 类型 | 作用 |
|------|------|------|
| `stack` | `readonly NavPathStack` | **4 个 Tab 共用同一个栈**（见 §5.4） |

### 3.4 标题栏回调协议（10）

| Tab | 字段 | 类型 |
|-----|------|------|
| HomePage | `shouldShowHomeRefresh` | `@Local boolean` |
| HomePage | `isHomeRefreshing` | `@Local boolean` |
| HomePage | `homeDoRefresh` | `private () => void` |
| CharactersPage | `shouldShowCharRefresh` | `@Local boolean` |
| CharactersPage | `shouldShowCharSwitcher` | `@Local boolean` |
| CharactersPage | `isCharRefreshing` | `@Local boolean` |
| CharactersPage | `charAccountOptions` | `@Local AccountOption[]` |
| CharactersPage | `charSelectedIdx` | `@Local number` |
| CharactersPage | `charDoRefresh` | `private () => void` |
| CharactersPage | `charDoSelectAccount` | `private (idx) => void` |

> 这是本文件最大的结构性技术债：**每新增一个 Tab，平均增加 4-5 个字段 + 1 个 getter 分支**（见 M2）。

### 3.5 Signal / 监听器（3 个 `@Local` + 3 `@Monitor`）

三个单例类，通过 `@Local` 持有实例引用，由 ArkUI `@Monitor` 装饰器驱动变更通知：

| 字段 | 类型 | Monitor handler | 触发条件 |
|------|------|-----------------|----------|
| `cookieExpiredSignal` | `CookieExpiredSignal` | `onCookieExpiredQueueChanged` | `queue` 数组变化 |
| `geetestSignal` | `GeetestSignal` | `onGeetestTriggered` | `trigger` 计数器自增（队列首项入队 / 处理下一项时 `+1`，`features/verification/src/main/ets/signals/GeetestSignal.ets:81/149`） |
| `deviceFpInvalidSignal` | `DeviceFpInvalidSignal` | `onDeviceFpInvalid` | `version` 数字变化 |

> 3 个 Signal 必须带 `@Local`：`@Monitor` 在 `@ComponentV2` 内只能监听组件自己的状态变量（`@Local` / `@Param` / `@Provider` / `@Consumer` / `@Computed`），`@Monitor('cookieExpiredSignal.queue')` 的第一段路径必须是本组件的状态变量，所以不写 `@Local` 就不会建立依赖。另一条合法用法是把 `@Monitor` 写在 `@ObservedV2` 类里监听自己的 `@Trace` 字段（`.opencode/skills/state-management/SKILL.md:209-224` 范例 5），本项目选择在组件侧集中仲裁，故 Signal 实例由 MainPage 用 `@Local` 持有。三者都是 AppStorageV2 单例，实例不会被替换，也没有在 `build()` 中读取。✅

### 3.6 弹窗仲裁（5 个 boolean）

| 字段 | 作用 |
|------|------|
| `isGeetestShowing` | 人机验证框正在显示 |
| `isGeetestPending` | 验证框被指纹提示挂起 |
| `isFpPromptShowing` | 指纹提示正在显示 |
| `isFpPromptPending` | 指纹提示被验证队列挂起 |
| `isGeetestCancelAllRequested` | 用户请求取消整个队列 |

### 3.7 其他（13 非 @Local）

**非 @Local（13 个）**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `stack` | `readonly NavPathStack` | **4 个 Tab 共用同一个栈**（见 §5.4） |
| `windowClass` | `window.Window \| undefined` | AppStorage 读取的窗口对象，非响应式初始化 |
| `currentWindowStatusType` | `window.WindowStatusType \| undefined` | 分屏/悬浮判定 |
| `placeholder` | `ComponentContent<object> \| null` | 分栏占位符 |
| `uiCtx` | `UIContext \| null` | UI 上下文 |
| `homeDoRefresh` | `() => void` | HomePage 刷新回调（空实现兜底） |
| `charDoRefresh` | `() => void` | CharactersPage 刷新回调（空实现兜底） |
| `charDoSelectAccount` | `(idx: number) => void` | CharactersPage 账号切换回调（空实现兜底） |
| `isGeetestCancelAllRequested` | `boolean` | 取消全部队列标记——全文件只有 `:292` 置 false，从未置 true（见 L4） |
| `isGeetestShowing` | `boolean` | 验证框显示中（见 §3.6） |
| `isGeetestPending` | `boolean` | 验证框挂起中（见 §3.6） |
| `isFpPromptShowing` | `boolean` | 指纹提示显示中（见 §3.6） |
| `isFpPromptPending` | `boolean` | 指纹提示被验证队列挂起（见 §3.6） |

**说明**：`tm`（ThemeManager，`:35`）和 3 个 Signal 带 `@Local` 装饰器，计入 @Local 总数。

**@Local 汇总（16 个）**：§3.1（`selectedTab`、`tabVersion`、`isSplit`）、§3.2（`navMode`、`windowWidthVp`）、§3.4（`shouldShowHomeRefresh`、`isHomeRefreshing`、`shouldShowCharRefresh`、`shouldShowCharSwitcher`、`isCharRefreshing`、`charAccountOptions`、`charSelectedIdx`）、§3.5（`cookieExpiredSignal`、`geetestSignal`、`deviceFpInvalidSignal`）、`:35`（`tm`）。

---

## 4. build() 结构树

```
MainPage
└── NavDestination
    └── Navigation(this.stack)                    ← 共享栈
        ├── Stack (100% × 100%)
        │   ├── HomePage({ detailStack, isSplit, onReady, onMenuStateChange })
        │   │     .visibility(this.selectedTab === TAB_HOME ? Visibility.Visible : Visibility.None)
        │   ├── CharactersPage({ detailStack, isSplit, onReady, onMenuStateChange })
        │   │     .visibility(this.selectedTab === TAB_CHARACTERS ? Visibility.Visible : Visibility.None)
        │   ├── ToolsPage({ detailStack })
        │   │     .visibility(this.selectedTab === TAB_TOOLS ? Visibility.Visible : Visibility.None)
        │   └── MyPage({ detailStack, isSplit })
        │         .visibility(this.selectedTab === TAB_MY ? Visibility.Visible : Visibility.None)
        ├── .title(this.getTabTitle())
        ├── .menus(this.currentMenuItems)
        ├── .toolbarConfiguration([4 个 ToolbarItem])
        ├── .mode(navMode)
        ├── .navBarWidth(0.4 × windowWidthVp)
        ├── .navBarWidthRange([240, 400])
        ├── .minContentWidth(320)
        ├── .splitPlaceholder(placeholder!)
        ├── .onNavigationModeChange(mode => this.isSplit = mode === NavigationMode.Split)
        └── .backgroundColor(tm.current.colorPageBg)
```

**设计要点**：4 个 Tab 全部常驻（`visibility` 切换而非 `if` 条件渲染），避免切 Tab 时重建与状态丢失。代价是 4 个页面同时持有内存与监听器——对 4 个一级页可接受，但如果未来加入重页面（如地图页）需要改为条件渲染。

---

## 5. 四大机制深度分析

### 5.1 标题栏菜单协议：子页 → 父页反向上报

ArkUI 的 `Navigation.menus` 属于父组件，子页无法直接修改。本项目采用**受控组件模式**：子页通过 `onReady`/`onMenuStateChange` props 回调把"该显示什么按钮"和"刷新函数"上报给 MainPage，MainPage 用 `@Local` 缓存后生成 `NavigationMenuItem[]`。

```
HomePage/CharactersPage ──onReady(刷新函数)/onMenuStateChange(状态)──▶ MainPage.@Local 字段
                                                              │
MainPage.currentMenuItems ──getter 合成──▶ Navigation.menus ──▶ 系统标题栏
                                                              │
用户点击 refresh ──▶ MainPage.homeDoRefresh() ──▶ HomePage 内部实际刷新
```

**评价**：思路正确，实现有三处可以收紧（第 3 处改在子页）：

1. 状态与函数分开存放，未封装成一个对象（M2）。
2. onReady 和 onMenuStateChange 各有分工：onReady 在初始化阶段注入操作函数（HomePage 注入 `doRefresh`、CharactersPage 额外注入 `doSelectAccount`），onMenuStateChange 在运行时上报布尔状态。两者不是重叠——但 CharactersPage 的 onReady 比 HomePage 多一个参数，子页调用方需要按 Tab 适配不同签名，增加了认知负担（M2 的根源）。
3. 子页把回调声明为 `@Param`（`features/home/.../pages/HomePage.ets:18-20`、`features/characters/.../pages/CharactersPage.ets:18-26`），V2 中子→父事件的专用装饰器是 `@Event`。不影响功能，不计入评级。

### 5.2 弹窗仲裁状态机

三类全局事件都需要弹 UI。实际上只有人机验证与指纹提示互相仲裁，Cookie 过期弹框不参与仲裁（见 M8）：

| 事件 | 触发源 | Monitor |
|------|--------|---------|
| Cookie 过期 | `CookieExpiredSignal.queue` | `onCookieExpiredQueueChanged` |
| 人机验证（1034/10035） | `GeetestSignal.trigger` | `onGeetestTriggered` |
| 设备指纹无效（5003/10041） | `DeviceFpInvalidSignal.version` | `onDeviceFpInvalid` |

优先级设计：**验证队列 > 指纹提示**（指纹提示会等人机验证队列清空才弹）。仲裁靠 boolean 手工编排：

```
onDeviceFpInvalid: 若 isGeetestShowing 或队列非空 → isFpPromptPending = true，返回
onGeetestTriggered: 若 isFpPromptShowing → isGeetestPending = true，返回
showCurrentGeetest: finally 中 isGeetestShowing = false；try 正常结束后，若队列空且 isFpPromptPending → showDeviceFpPrompt()（抛错时跳过）
onDeviceFpPromptClosed: isFpPromptShowing = false；若 isGeetestPending → showCurrentGeetest()
```

**评价**：在正常路径下能自洽，但存在以下风险：

- **返回手势关闭验证框后永久挂起**（H2）：JS bridge 回调（`GeetestDialog.ets:53-55`，验证成功 / 取消的正常路径）、标题栏关闭按钮 `onClose → onResult(null)`（`features/verification/src/main/ets/views/GeetestDialog.ets:89-91`）、Web 加载失败 `onErrorReceive → onResult(null)`（同文件 `:119-122`）、弹窗打开失败 `resolve(null)`（`features/verification/src/main/ets/utils/GeetestDialogUtil.ets:106-110`）这四条路径都会结束；但返回手势 / 侧滑 / ESC 关闭弹窗时没有任何代码回调 `onResult`，Promise 永不 resolve，详见 H2。Cookie 过期弹框（`:155-192`）不受 `isGeetestShowing` 门控。
- **无优先级抢占**：新事件到达时只能排队，不能取消低优先级事件。
- **状态分散**：4 个 boolean 表达一个 3 状态机（Idle / Geetest / FpPrompt），非法组合（如两个 Showing 同时为 true）无法被类型系统排除（M5）。

**改进方向**：改为 `type DialogState = 'idle' | 'geetest' | 'fpPrompt'` 单一枚举 + 一个待处理队列，可消除 4 个 boolean 与非法状态。

> **时序风险（未确认可达，不计入评级）**：人机验证的全局监听只在 `MainPage.aboutToAppear` 注册（`GeetestCenter.init()` `:82`）；在此之前 core 上报 1034 / 10035 时 `GeetestReporter.report()` 因监听为 null 直接返回（`core/src/main/ets/base/network/GeetestReporter.ets:27-30`），启动页 / 隐私页阶段的验证请求会被静默丢弃。设备指纹同理：监听只在 `DeviceFpCenter.init()`（`:84`）注册，之前 `FingerprintReporter.report()` 因监听为 null 直接返回（`core/src/main/ets/base/network/FingerprintReporter.ets:24-27`）。是否有接口在 MainPage 出现前遇到 1034 / 5003 尚未确认。

> **分层说明（不计入评级）**：MainPage 没有 ViewModel，直接调用 verification 模块的服务类（`GeetestCenter.init()` `:82`、`DeviceFpCenter.init()` `:84`、`DeviceFpCenter.regenerate()` / `dismiss()` `:226/248/251/259`），不符合官方 MVVM「View 不直接访问 Model」的分层要求。checklist 没有对应条目，不单列缺陷；重构模块 M15 抽 `DialogArbiter` 时一并移入 ViewModel（见 §9、[project-structure.md](./project-structure.md) §6）。

### 5.3 响应式导航模式

```typescript
// setCurrentMode() — :134-153
横屏 → windowStatusType === 4 ? Stack : Split
竖屏 → windowWidthVp < 520 ? Stack : Split
```

**设计依据**：官方 FAQ 推荐"横屏分栏、竖屏按断点"，与折叠屏展开态（宽屏竖持）兼容。

**三处瑕疵**：

1. **魔数 4**（M3）：注释写"分屏（WindowStatusType=4）"，但官方 API 参考（`apis-arkui/arkts-apis-window-e.md`「WindowStatusType」）定义为 `UNDEFINED=0 / FULL_SCREEN=1 / MAXIMIZE=2 / MINIMIZE=3 / FLOATING=4 / SPLIT_SCREEN=5`，`4` 命中的是**自由悬浮窗**，分屏是 `5`。项目自身文档（`Documents/Navigation-Split-Guide.md:336`）与 `entry/src/main/ets/entryability/EntryAbility.ets:87` 的注释沿用了同一个错误说法，改代码时要一起改；落地前在真机分屏与悬浮窗下各打一次 `getWindowStatus()` 日志确认行为。
2. **分栏宽度参数互相矛盾**（M4）：`0.4 × width` 在 width > 1000vp 时被压到 400、< 600vp 时被抬到 240；竖屏 520vp 即强制分栏，但 `navBarWidthRange` 下限 240 + `minContentWidth` 320 = 560vp；`:145` 注释称 520vp 是「Auto 模式阈值」，官方说明 520vp 只适用于 API 9 及之前，API 10 起为 600vp。
3. **失败静默**（M11）：`catch (_e) {}` 后保持原模式；`setCurrentMode()` 在每次尺寸 / 状态回调中会重算（`:108`、`:114`），只有 `getDefaultDisplaySync` 一直抛错时 `navMode` 才停在初始的 `Stack`，且无任何日志。

### 5.4 路由栈与 Tab 切换

```typescript
// 4 个 toolbar item 的 action 完全相同，仅 Tab 常量不同
action: () => {
  this.selectedTab = TAB_X
  this.tabVersion++
  if (this.isSplit) { this.stack.clear() }
}
```

**复核结论（原 H1 撤回）**：`toolbarConfiguration` 挂在 Navigation 的 NavBar 上（`:449-490`）。
- **单栏模式**：二级页（NavDestination）入栈后全屏覆盖 NavBar，底部 Tab 栏随之不可见，用户只能先返回到空栈才能点 Tab；此时栈本来就是空的，不 `clear()` 不会出现"Tab 高亮与内容不符"。
- **分栏模式**：Tab 栏在左侧常驻，切 Tab 时 `clear()` 让右侧回到 `splitPlaceholder`（`:495`），避免右侧残留上一个 Tab 的详情页。
- `isSplit` 由 `onNavigationModeChange`（`:496-498`）维护，首次显示与单双栏切换都会回调。

因此 `if (this.isSplit) clear()` 与两种模式的可见性是匹配的，原文描述的单栏错位场景不可达。"4 个 Tab 共享一个栈"仍是重构契约（§9 不变量 1），但不再计为缺陷。

---

## 6. 问题清单

> **编号约定**：`H* / M* / L*` 是本文的缺陷编号；各表「规则 ID」列只引用 `.opencode/skills` 中已存在的稳定编号（`harmonyos-review/references/checklist.md`、`arkts-rules/references/spec-quick-ref.md`），没有对应条目的架构类问题记 `—`，不自行编号。

### High（发版前必修）

#### H1 · 窗口尺寸监听被人机验证弹窗整体注销，首次验证后折叠屏适配失效
- **位置**：`features/verification/src/main/ets/views/GeetestDialog.ets:59-65`（`window.getLastWindow(ctx)` 拿到主窗口后 `on('windowSizeChange')`）、同文件 `:77`（`aboutToDisappear` 里 `this.win.off('windowSizeChange')`，**不带 callback**）；受害方 `MainPage.ets:98-109`（匿名回调）与 6 个详情页的 `sizeCallback`
- **问题**：`window.off(type)` 不传 callback 时注销该窗口上此类型的**全部**回调。验证框挂在主窗口内（`openCustomDialog`，非子窗口），`getLastWindow` 返回的是主窗口，于是每次验证框关闭都会把 MainPage 注册在 `:98` 的 `windowSizeChange` 回调一并清掉（缺陷所在：`GeetestDialog` 的生命周期注销，对应 checklist LIFE-001，默认 High）；若当时停在详情页，3 个角色详情页（`features/chardetail/.../pages/*CharacterDetailPage.ets`）与 3 个便笺详情页（`features/dailynote/.../pages/*DailyDetailPage.ets:44/49`）注册的 `sizeCallback` 也会被清掉。`EntryAbility.ets:84-86` 的监听同样会被清掉，但它只写 AppStorage 的 `windowWidthPx`，全工程无读取方，无用户影响；MainPage 自身 `aboutToDisappear`（`:123`）的无 callback `off` 只在 MainPage 销毁时执行（代码中没有 pop / replace 它；但按返回可能把它弹出，见 M10），此时同窗口剩下的只有 EntryAbility 的监听（无读取方），实际无害。官方依据：`apis-arkui/arkts-apis-window-Window.md`「off('windowSizeChange')」——未传 callback 则关闭窗口尺寸变化的监听。落地前用一次真机日志确认 `getLastWindow` 与 `getMainWindow` 返回的对象共用同一监听注册。
- **影响**：首次人机验证之后，`windowWidthVp` 冻结、`setCurrentMode()` 不再随尺寸变化重算（`windowStatusChange` 仍在，但折叠/展开、旋转不一定改变 status）——折叠屏折叠后仍强制分栏、展开后仍单栏，用户可见且无日志。
- **建议**：`GeetestDialog` 与 `MainPage` 都把回调存成字段，`off('windowSizeChange', this.cb)` 精确注销（与三个角色详情页 `sizeCallback` 的写法一致，如 `features/chardetail/src/main/ets/pages/GenshinCharacterDetailPage.ets:50/73`）。修复点在 `features/verification/src/main/ets/views/GeetestDialog.ets`，验收挂在重构模块 M15 的折叠屏回归。

#### H2 · 返回手势 / 侧滑 / ESC 关闭人机验证框后，验证队列永久卡死（2026-10-29 恢复）
- **位置**：`features/verification/src/main/ets/utils/GeetestDialogUtil.ets:100-110`（`openCustomDialog` 只设 `autoCancel: false`，未注册 `onWillDismiss`）、`features/verification/src/main/ets/views/GeetestDialog.ets:74-83`（`aboutToDisappear` 只注销监听，不回调 `onResult`）；受害方 `MainPage.ets:283-330`
- **规则**：`LIFE-004`（弹窗关闭路径未清理状态，默认 Medium）+ `KIT-005`（Promise 未收尾，默认 High）——按实际影响（验证队列永久卡死）记 High
- **问题**：官方 `apis-arkui/js-apis-promptAction.md` 说明 `autoCancel` 只控制「点击遮障层」是否关闭；侧滑、三键 back、键盘 ESC 等交互关闭只有注册 `onWillDismiss` 才能拦截。全工程没有 `onWillDismiss` / `onBackPress`，因此用户用返回手势关闭验证框时：`showGeetestDialog` 的 Promise 永不 resolve → `:304-306` 的 `finally` 不执行，`isGeetestShowing` 永久为 `true` → 之后所有设备指纹提示都被 `:216` 挂起；`GeetestSignal` 只在队列从 0 变 1 时 `trigger++`（`features/verification/src/main/ets/signals/GeetestSignal.ets:80-82`），当前项不出队，后续验证请求全部静默排队；该账号还留在 `GeetestCenter.pendingAccounts`（`features/verification/src/main/ets/model/service/GeetestCenter.ets:43-46`），`onSuccess` / `onCancel` 都不会被调用。
- **影响**：本次启动内人机验证与设备指纹提示全部失效，需要验证的接口持续失败，直到重启应用。另：该路径下 `GeetestDialogUtil.ets` 的 `contentNode` 也不会被 `dispose()`（只在 `onResult` 路径 `:79-85` 释放）。
- **同类路径**：若 `showGeetestDialog` 的 Promise 因执行器同步异常而 reject（见「复核撤回」原 M8），`:297-306` 只有 `finally`，`:309-324` 的 `resolveSuccess` / `resolveCancelCurrent` / `resolveCancelAll` 都不会调用，当前项不出队、账号留在 `pendingAccounts`，后果同上（`isGeetestShowing` 会被 `finally` 复位）。低概率。
- **建议**：`openCustomDialog` 注册 `onWillDismiss`，在其中走与关闭按钮相同的 `onResult(null)`；或在 `GeetestDialog.aboutToDisappear` 中兜底回调一次（需防重复 resolve）；`:297-306` 补 `catch`，异常时调用 `resolveCancelCurrent()`。真机上验证一次返回手势的实际行为。10-27 撤回原 H2 时只核对了关闭按钮、Web 错误、打开失败三条路径，漏了这一条。

### Medium（技术债，下迭代）

| 缺陷 ID | 规则 ID | 位置 | 问题 | 建议 |
|----|----|------|------|------|
| M1 | — | `:456/466/476/486` | `status: (selectedTab === X && tabVersion >= 0)` —— `>= 0` 恒真，真实作用是"读一次 tabVersion 建立渲染依赖"，属于未注释的 hack。4 个 item 本来就都读 `@Local selectedTab`，`toolbarConfiguration` 作为一个属性整体重算；`tabVersion` 额外带来的只是「点击已选中的 Tab」时也重算 | 补注释说明用途，或确认不需要后删除。属性数组不能按 item 独立追踪，不要尝试改成 `@ObservedV2` item 对象 |
| M2 | — | `:65-77` | 标题栏协议散落 10 个字段，新增 Tab 线性膨胀 | 抽成 `@ObservedV2 class TabMenuState`（状态字段加 `@Trace`：showRefresh / showSwitcher / isRefreshing / options / selectedIdx，另含 doRefresh / doSelect），MainPage 只存一个实例；用普通 `interface` 时 V2 `@Local` 只感知整体重新赋值，属性变化不会刷新（STATE-005） |
| M3 | COMPAT-004 | `:136-143` | `currentWindowStatusType === 4` 魔数，且命中语义与注释相反：官方定义 `4 = FLOATING`（自由悬浮窗），`5 = SPLIT_SCREEN`（分屏）。另外横屏分支完全不看窗口宽度，方向取自屏幕（`display.getDefaultDisplaySync()` `:136`）而非窗口，于是分屏（5）等窄的横屏窗口也被强制分栏（最小需 240 + 320 = 560vp）；只把 4 换成 `SPLIT_SCREEN` 解决不了这一点 | 横竖屏都按窗口宽度阈值决定单双栏；状态判断改用 `window.WindowStatusType` 枚举，并核对实际行为 |
| M4 | COMPAT-004、ARKTS-013 | `:146/492-494` | 分栏宽度参数互相矛盾：① `navBarWidth(0.4 × width)` 被 `navBarWidthRange([240,400])` 两端 clamp（> 1000vp 压到 400、< 600vp 抬到 240，见官方 `arkui-ts/ts-basic-components-navigation.md` 表 1「navBarWidth 最终取值」）；② 竖屏 ≥ 520vp 即强制分栏，但 240 + `minContentWidth` 320 = 560vp，520-560vp 窗口内容区被压到 `minContentWidth` 以下；③ `:145` 注释称 520vp 是「Auto 模式阈值」，官方 Auto 阈值 API 10 起为 600vp（`.opencode/skills/harmonyos-development/SKILL.md:984`），API 9 及之前才是 520vp | 只保留 range 或把系数纳入 range 计算；分栏阈值与 range + minContentWidth 对齐（或直接用官方 600vp），并改注释 |
| M5 | — | `:60-63` | 4 个 boolean 表达 3 状态机，非法组合（两个 Showing 同时为 true）无法排除；交接也容易漏：`showCurrentGeetest` 在 `:285`（无当前项）、`:289`（`uiCtx` 为 null）提前返回时跳过 `:326-329` 的挂起检查，若 `isFpPromptPending` 为 true，指纹提示不再弹出且 `DeviceFpCenter` 的 `isShowing` 保持 true（`features/verification/.../model/service/DeviceFpCenter.ets:53/56`），本次启动内不再提示（边缘路径） | 改为单一枚举 `DialogState` + 待处理队列 |
| M6 | — | `:450-489` | 4 个 toolbar item 结构完全重复（每个约 10 行），仅图标/文案/Tab 常量不同 | 用 Tab 配置数组 `map` 生成 `ToolbarItem[]` 传给 `toolbarConfiguration`（它接收普通数组；`ForEach` 是组件树语法，不能用在属性里） |
| M7 | STATE-013 | `:44-46` | `windowClass` 在字段初始化时从 AppStorage 一次性读取；写入方 `EntryAbility.ets:68-70` 在 `getMainWindow().then` 里异步写，与 `loadContent`（`EntryAbility.ets:94`）并行。正常路径靠启动页至少 1200ms（`entry/src/main/ets/pages/LaunchPage.ets:49-50`）或隐私页的用户操作把 MainPage 的构造推迟到写入之后，所以一般拿得到；但这是未声明的时序契约——`getMainWindow` 失败（`EntryAbility.ets:91-92` 只记日志）或超过 1.2s 时，`windowClass` 为 `undefined`，`:98` 与 `:112` 的可选链让两处监听静默跳过，MainPage 侧无任何日志；`windowWidthVp` 停在默认 360（`:42`），竖屏下始终单栏（平板也是）（原 H3，按"正常路径用户不可感知"降为 Medium） | `aboutToAppear` 中读取并在 `undefined` 时打日志；或由 EntryAbility 写入后再触发一次读取。不要改成 `@StorageLink`：它是 V1 装饰器，不能用在 `@ComponentV2` 中（STATE-001） |
| M8 | STATE-012 | `:155-192` | Cookie 过期弹框不排队：`:164` 在 `@Monitor('cookieExpiredSignal.queue')` 回调内重新赋值被监听的 `queue`，官方说明这会再次触发回调（`state-management/arkts-new-monitor.md`「避免在 @Monitor 中再次更改被监听的属性」），于是 N 个过期账号会让回调连续执行 N+1 次、一次性出队，N 个弹框同时叠加（`DialogDedup` 只按账号去重）；`:185-187`「若队列还有，继续弹下一个」的同引用赋值不会触发 `@Monitor`（严格相等比较），是无效代码。Cookie 弹框也不参与人机验证 / 指纹提示的仲裁，可与它们叠加。另：`:164` 先出队、`:167` 再判断 `ctx === null`，理论上会丢一项（`aboutToAppear` 后不可达） | 回调内不改 `queue`：弹框关闭后显式调用「处理下一项」的方法（出队 + 弹框）；纳入弹窗仲裁（见 M5） |
| M9 | — | `:45-46/98` | 窗口 API 异常保护不一致：`:46` 在字段初始化中调用 `getWindowStatus()`，未包 try，官方列出的 801（能力不支持）/ 1300002（窗口状态异常）一旦抛出，MainPage 无法构造；`:98` `on('windowSizeChange')` 未包 try（相邻 `:111-118` 的 `on('windowStatusChange')` 有）。目标设备 phone / tablet / 2in1 正常不会抛，触发概率低 | 移到 `aboutToAppear` 并包 try，失败时打日志 |
| M10 | NAV-001（同类白屏） | `:402`；`pages/Index.ets:28-31` | **待真机确认**：在 Tab 根页（内层栈为空）按系统返回，可能把 MainPage 从 Index 的根栈弹出，显示空白页，再按一次才退出。依据：Index 外层 `Navigation` 设 `.hideNavBar(true)`（`Index.ets:28-31`），官方说明「路由栈中不存在 NavDestination 页面时显示空白」（`arkui-ts/ts-basic-components-navigation.md`「hideNavBar」）；MAIN 是外层栈唯一页面（`LaunchPage.ets:54/58`、`PrivacyConsentPage.ets:32` 都用 `replace`）；MainPage 的 `NavDestination`（`:402`）没有 `onBackPressed`，全工程也没有拦截返回的代码。若成立，MainPage 的状态与监听全部销毁 | 真机确认后，在 MainPage 的 `NavDestination` 加 `onBackPressed`：内层栈为空时把应用移到后台并返回 true |
| M11 | ARKTS-016 | `:92/104/116/125/150/189/207/233/257/391` | 10 处静默吞异常：`:92/104/116/125/150/207/233` 为空 catch（只有注释或完全空）；`:189` Cookie 过期弹窗 catch（仅 `DialogDedup.release`）、`:257` 设备指纹弹窗 catch（仅 `onDeviceFpPromptClosed` + `DeviceFpCenter.dismiss`），均无日志或用户反馈；`:391` `.catch({})` 完全空。`scan-arkts.sh` 将 `ARKTS-016` 默认定为 Medium（文件含 `await` 时触发），本文件含 `await`，按工具口径计 Medium | 每处补一行 `Logger.warn`（含 `BusinessError.code`），或在确认无害处加 `// scan-ignore: ARKTS-016` 并注明原因 |

### Low（建议优化）

| 缺陷 ID | 规则 ID | 位置 | 问题 |
|----|----|------|------|
| L1 | ARKTS-013 | `:177-178/241-243/388`、`:42/146/493/494` | 颜色硬编码绕过 ThemeManager：`maskColor: '#80000000'`、按钮色 `'#999999'/'#E8534A'`；布局数值硬编码（ARKTS-013 ≥ 100 的常量）：`360`（`:42` 默认宽度）、`520`（`:146`）、`240` / `400`（`:493`）、`320`（`:494`） |
| ~~L2~~ | ARKTS-016 | — | 2026-10-29 升为 **M11**：`scan-arkts.sh` 对该规则默认定为 Medium，原先「只少一条日志、不改变业务结果」的 Low 判级与工具口径不一致，按用户要求统一为工具默认级别。10 处位置与详情见 M11 |
| ~~L3~~ | — | — | 2026-10-29 并入 M8（同引用赋值无效之外，`:164` 的出队赋值会让回调连续重触发、多个弹框同时叠加，影响升为 Medium） |
| L4 | — | `:55/292/318-320` | `isGeetestCancelAllRequested` 全文件只在 `:292` 被置为 `false`，没有任何位置置 `true`，`resolveCancelAll()`（`features/verification/src/main/ets/signals/GeetestSignal.ets:133`）在 MainPage 中不可达；"取消全部"是半成品死分支。要么删掉该字段与分支，要么在验证框标题栏补"全部取消"入口后再接上 |
| L5 | KIT-005、ARKTS-011 | `:384`、`:268`；全部 catch | Promise 处理不完整：`:384` `closeCustomDialog(content)` 返回的 Promise 无 catch；`:268` 在同步方法里调用 async 的 `showCurrentGeetest()`，未 await 也未 catch，异常会成为未处理的 rejection；全文件 catch 都没有收窄为 `BusinessError` 并判断 `code`（KIT-005 / ARKTS-011）。checklist 默认级别为 High / Medium，按实际影响记 Low：失败只影响关闭弹框动作或日志信息，不改变业务结果 |
| L6 | — | `:383`、`:85` | `showAccountSwitchSheet` 创建的 `ComponentContent`（`:383`）关闭后未 `dispose()`（对比 `GeetestDialogUtil.ets:83` 会 dispose）；分栏占位 `placeholder`（`:85`）也从未 dispose |
| L7 | AGC-RJ-014 | `:209`、`:254` | 账号标签硬编码：`` `${gameName} · UID ${roleId}` `` / `` `UID ${roleId}` `` 中的「UID」与分隔符没有走资源字符串（`AGC-RJ-014`「UI 硬编码中文字符串」，`arkts-rules/references/spec-quick-ref.md:80`）；`:254` 日志 tag 仍为改名前的 `'Main'` |

### 复核撤回 / 改判（2026-10-27）

| 原条目 | 处理 | 依据 |
|----|----|----|
| 原 H1 共享 NavPathStack 切 Tab 语义不一致 | 撤回 | 单栏下二级页覆盖 NavBar，Tab 栏不可点；分栏下切 Tab 清栈。原文的"Tab 高亮与内容不符"不可达，详见 §5.4 |
| 原 H2 人机验证队列无超时、永久挂起 | 10-27 撤回；**2026-10-29 恢复为 H2** | 10-27 的依据：验证框有关闭按钮（`GeetestDialog.ets:89-91`），Web 错误与打开失败都 resolve `null`（`GeetestDialog.ets:119-122`、`GeetestDialogUtil.ets:106-110`）。漏了返回手势 / 侧滑 / ESC 关闭路径（未注册 `onWillDismiss`），该路径下 Promise 永不 resolve，见 H2 |
| 原 H3 `windowClass` 一次性读取 | 降为 M7 | 正常启动路径被启动页的 1200ms 下限兜住，仅在 `getMainWindow` 失败/超慢时触发 |
| 原 M7 `@Monitor` 深监听数组有性能开销 | 撤回 | `queue` 从不就地 push/splice，每次整体替换（`CookieExpiredSignal.ets:33-38/53`）；`@Monitor('x.queue')` 只在整体赋值时触发一次，不存在逐项深比较带来的额外回调 |
| 原 M8 `onGeetestTriggered` 缺 `return await` 会产生 unhandled rejection | 撤回（维持） | `await` 与 `return await` 对异常传播等价。`showGeetestDialog` 的执行器只调用 `resolve`（`GeetestDialogUtil.ets:75-111`），但执行器内的同步异常（如 `:94` `new ComponentContent`、`:106` `openCustomDialog` 同步抛错）仍会让 Promise reject，此时 `:297-306` 的 `try/finally` 会把异常抛出 async `@Monitor`，属低概率路径 |
| 原 L3 `placeholder!` 若 build 先执行会崩溃 | 撤回 | ArkUI 保证 `aboutToAppear`（`:85` 赋值）先于首次 `build()` |
| 原 L4 `readonly stack` 无保护作用 | 撤回 | `readonly` 防止替换栈实例正是需要的保护（子页持有同一引用，`:406/418/439/441`），不是缺陷 |
| 原 L5 身份赋值 | 10-27 改写为 L3；10-29 并入 M8 | 补充"同引用赋值不触发 `@Monitor`"与"回调内出队赋值会连续重触发"的事实 |

### 做得对的地方（保留）

- ✅ 模块级 `@Builder accountSwitchDialogBuilder`（`:23-26`），**没有**写成内联 `@Builder`，符合规范。
- ✅ `TAB_HOME..TAB_MY` 用命名常量（`:28-31`），未在 build 中散落 0-3 字面量。
- ✅ 测试页入口用 `BuildProfile.DEBUG` 隔离（`:366`），release 构建不会暴露。
- ✅ `aboutToDisappear` 有 `off('windowSizeChange')` / `off('windowStatusChange')`（`:121-128`）；不带 callback 的写法在这里实际无害（只在 MainPage 销毁时执行），但与 H1 是同一写法，建议一并改为精确注销。
- ✅ 回调兜底空实现（`:68/76/77`），未就绪时点击不会崩溃。
- ✅ Cookie 过期弹窗用 `DialogDedup` 去重（`:169-172`），避免同账号重复弹框。
- ✅ `has` 保护：`windowClass?.on(...)`、`uiCtx === null` 早返回都做了。

### 合规检查（skills checklist）

> 逐条对照 `.opencode/skills/harmonyos-review/references/checklist.md` 与 `.opencode/skills/arkts-rules/references/spec-quick-ref.md`，只列与 MainPage 相关的条目。DB、PERM 类不适用（MainPage 不直接访问数据库、不申请权限）；SEC、KIT 只列相关的 SEC-002、KIT-005。`ARKTS-016` / `NAV-001` / `AGC-RJ-014` 只在 spec-quick-ref 中定义，条目后注明出处。

| ID | 检查项 | 结论 | 证据 / 说明 |
| --- | --- | --- | --- |
| ARKTS-001~010、014、015 | ArkTS 语法类：`any` / `unknown` / `var`、无类型对象字面量、索引签名、解构、`function` 表达式、`#` 私有字段、正则字面量、`delete`、`for-in`、未初始化字段、`@ohos.*` 旧式 import、一元 `+` | ✅ | 逐项 grep 无命中（命令见 §10）；`HomePage({ ... })` 等是 ArkUI 组件初始化语法，不是对象解构 |
| STATE-001 | 不混用 V1 / V2 | ✅ | `MainPage.ets:33` `@ComponentV2`；全文件无 `@State` / `@Prop` / `@Link` |
| STATE-008 | `build()` 无 await / 副作用 | ✅（对象分配偏高，不计入风险） | `build()`（`:401-502`）无 await、无赋值副作用；但每次 build 都新建 `SymbolGlyphModifier`：4 个 toolbar item 共 8 个（`:452-484`），菜单 getter 另有 `:337/348/355/369`，建议随 M6 一并抽常量 |
| STATE-012 | `@Monitor` 内不修改触发字段 | ❌ 已记 M8 | `:164` 在 `@Monitor('cookieExpiredSignal.queue')` 内重新赋值 `queue`，每出队一项就重触发一次，靠"队列空则 return"收敛；后果是多个过期弹框同时叠加。按实际影响（可关闭、不丢数据）记 Medium |
| STATE-013 | 跨页面共享状态用 AppStorage | ✅ 存在但为一次性快照（已记 M7） | `:44` `AppStorage.get<window.Window>('windowClass')` 只在字段初始化时读一次 |
| LIFE-001 | `aboutToDisappear` 取消监听 | ⚠️ 已记 H1 | 缺陷在 MainPage 承载的 `GeetestDialog`：`GeetestDialog.ets:77` 不带 callback 的 `off` 注销了 MainPage 与详情页的回调（H1，按 checklist 默认 High）。MainPage 自身 `:121-128` 同样不带 callback，但只在 MainPage 销毁时执行，实际无害；修 H1 时建议一并改为精确注销 |
| LIFE-004 | 页面跳转 / 关闭前清理弹窗状态 | ⚠️ 部分（已记 H2） | Cookie 弹框在 then / catch 两条路径都 `DialogDedup.release`（`:181` / `:190`）；指纹提示在 then / catch 两条路径都经 `onDeviceFpPromptClosed()`（`:246` / `:258`）清理 `isFpPromptShowing`；但人机验证框用返回手势关闭时没有清理路径（H2） |
| NAV-001 | 不把栈弹空导致白屏 | ⚠️ 同类（已记 M10，待真机确认） | 外层 `Index` 栈只有 MainPage 一个页面；Tab 根页按返回可能把它弹出（M10）。`spec-quick-ref.md:53` 的 NAV-001 针对 `NavPathStack.pop()` 到空栈，症状相同、触发路径不同 |
| ARKTS-012 | 日志走 hilog | ✅ | 统一 `Logger`（core），无 `console.*` |
| ARKTS-011 | 错误处理用 `BusinessError` 类型断言 | ⚠️ 已记 L5 | 所有 catch 都是 `(_e)` 或 `Error \| object`，没有收窄为 `BusinessError` |
| ARKTS-013 | 无魔法数字（≥ 100 的常量） | ⚠️ 5 处（已记 L1） | `360`（`:42`）、`520`（`:146`）、`240` / `400`（`:493`）、`320`（`:494`）；`:141` 的 `4` 不在本条范围，其语义错误记 M3；Tab 索引已用 `TAB_HOME..TAB_MY` 常量（`:28-31`） |
| ARKTS-016 | 空 catch 块不以静默吞错收场 | ❌ 已记 M11 | `:92/104/116/125/150/207/233` 完全空；`:189/257/391` 只做一行清理，均无日志（此条只在 `arkts-rules/references/spec-quick-ref.md:30` 定义；`scan-arkts.sh` 默认 Medium，本文按工具口径记 Medium） |
| AGC-RJ-014 | UI 不硬编码中文字符串 | ⚠️ 已记 L7 | `:209` 的「UID」与「 · 」分隔符没有走资源字符串（`spec-quick-ref.md:80`）；`:254` 日志 tag `'Main'` 属命名遗留，不是 UI 文案 |
| PERF-008 | 列表项带 key | n/a | MainPage 的 4 个 Tab 是静态写死的，无 `ForEach` |
| COMPAT-004 | 折叠屏 / 分屏适配 | ⚠️ 已记 M3 / M4 / M7（H1 的后果也体现在这里，缺陷本身按 LIFE-001 计） | 断点判定集中在 `setCurrentMode()`（`:134-153`）；尺寸监听会被验证弹窗注销（H1），分屏判定用了 FLOATING 的值（M3），分栏阈值与宽度范围矛盾（M4），`windowClass` 为一次性快照（M7） |
| KIT-005 | Kit Promise 都有 catch，BusinessError 判 code | ⚠️ 已记 L5 | `showDialog`（`:173` / `:237`）与 `openCustomDialog`（`:385`）有 catch（`:189` / `:257` / `:391`，最后一处为空，已记 M11）；`:384` `closeCustomDialog` 无 catch；所有 catch 都不判 `code` |
| SEC-002 | 敏感数据不入日志 | ✅ | 去重 key 只含 `username`（`:169`，即米游社 account_id），`DialogDedup.tryAcquire` 会把 key 明文写入日志（`common/basic/.../utils/DialogDedupUtil.ets:23`），但不是 cookie / token；弹框文案只用 `nickname`（`:175`） |
| COMPAT-005 | release 不保留 debug-only 代码 | ⚠️ 不在本文计数 | `:366` `BuildProfile.DEBUG` 只隐藏菜单入口，`TestPage` 与其路由仍编译进 release；已在 [test-page-module-analysis.md](./test-page-module-analysis.md) L1 计数，此处不重复计 |
| TEST-001 | 核心逻辑有单测 | ⚠️ 不计入评级（README §1.4） | MainPage 无测试；`entry/src/test` 只有 `LocalUnit` 与 `Widget2x2ViewModel` 两个测试 |

---

## 7. 评级依据

| 维度 | 结论 |
|------|------|
| Critical | 0 —— 无安全漏洞、无数据丢失、无阻断上架问题 |
| High | 2 —— H1 窗口尺寸监听被验证弹窗注销（用户可见：折叠/展开后单双栏不再切换）；H2 返回手势关闭验证框后验证队列永久卡死（用户可见：本次启动内验证与指纹提示全部失效） |
| Medium | 11 —— M1-M11（M7 为原 H3 降级：正常路径用户不可感知；M8 由原 L3 升级；M10 待真机确认；M11 由原 L2 升级：`ARKTS-016` 工具默认 Medium） |
| Low | 5 —— L1、L4、L5、L6、L7（L2 升 M11；L3 并入 M8） |

按 skills 评级表：`0 Critical + High ≤ 3` → **B**。债务点数 = 2×3 + 11×2 + 5×1 = **33**（10-27 为 21），密度 = 33 ÷ 5.13 = **6.4**（10-27 为 4.0）。

> **关于旧版 85 分的差异**：旧文档给的是"架构 17/20 + ArkTS 18/20 + 复用 16/20 + 异常 13/20 + 性能 15/15 + 代码质量 **6/5**"，总分 85。其中 `代码质量 6/5` 是非法分值，且"异常处理 13/20"没有转化为可执行的 High 项。新版只把会导致可见故障的问题计为 High（2026-10-27 复核后为 1 项，2026-10-29 复核后为 2 项）。

### 7.1 整体观察（skills report-template 要求）

- **代码质量**：命名（`TAB_HOME..TAB_MY` 常量、布尔 `is/should` 前缀）与模块级 `@Builder` 是本文件的两个亮点；扣分项是 `tabVersion >= 0`、`currentWindowStatusType === 4` 两处未注释的语义 hack（M1 / M3）。
- **架构**：单容器 + 全局信号仲裁，符合「顶层统一调度全局弹窗」的思路；但 View 直接调用 `GeetestCenter` / `DeviceFpCenter`（无 ViewModel），弹窗仲裁靠 4 个 boolean 手写状态机（M5），标题栏协议散落 10 个字段（M2）。
- **测试覆盖**：MainPage 无单测；`entry/src/test` 只有 `LocalUnit` / `Widget2x2ViewModel` 两套，M15 拆分只能靠真机回归（§9）。
- **文档**：文件头注释准确描述了 Navigation 的职责；但 `:141` 的 `4`（M3）与 `:145` 的 520vp（M4）注释与官方语义不符，改代码时须同步。

### 7.2 复审建议

修完 H1 / H2 后：`hvigorw codeLinter` → 真机回归「人机验证后折叠/展开」「验证框弹出后用返回手势关闭」「多账号 Cookie 同时过期」「Tab 根页按返回（确认 M10）」；通过后再进入 M15 拆分。完整回归清单见 §9「测试与验证」。

---

## 8. 依赖文件索引

| 类型 | 文件 |
|------|------|
| 子页面 | `features/home/.../pages/HomePage.ets`、`features/characters/.../pages/CharactersPage.ets`、`features/material/.../pages/ToolsPage.ets`、`features/account/.../pages/MyPage.ets` |
| 组件（common/basic） | `shares/AccountSwitchDialog.ets`、`shares/SplitPlaceholder.ets` |
| 全局信号（common/basic） | `signals/CookieExpiredSignal.ets` |
| 工具与常量（common/basic） | `utils/DialogDedupUtil.ets`、`utils/FeedbackUtil.ets`、`utils/GameIdUtil.ets`、`constants/AppRoutes.ets`、`constants/FeedbackType.ets`、`model/AccountOptionModel.ets`、`theme/ThemeManager.ets` |
| 人机验证与设备指纹（features/verification） | `signals/GeetestSignal.ets`、`utils/GeetestDialogUtil.ets`、`views/GeetestDialog.ets`（H1 / H2 修复点）、`model/service/GeetestCenter.ets`、`model/service/DeviceFpCenter.ets`（含 `DeviceFpInvalidSignal`） |
| Core | `'core'`（`FailedAccountInfo`、`GameId`、`GeetestVerifyInput`、`Logger`） |

> 表中 `.../` 为 `src/main/ets`。

---

## 9. 重构执行备注（M15）

> 本节优先级高于 §6 的历史建议；执行以 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) 为准。

**不变量（拆 MainPage 前必须冻结）**

1. **4 个 Tab 共享一个 `NavPathStack`** 是当前导航契约（子页通过 `detailStack` 拿到同一实例，`:406/418/439/441`；内层 `Navigation(this.stack)` 无 `.navDestination()`，二级页全靠各模块 routerMap 解析）。"分栏切 Tab 清栈、单栏不清"与 Tab 栏可见性是配套的（§5.4），拆分时不要顺手改成各 Tab 独立栈，否则 4 个子页的 `detailStack` 入参与 MainPage 内的 push 点（`:183`、`:370`）都要一起改，属行为变更。
2. **标题栏协议 10 个字段**（`:65-77`）是 HomePage / CharactersPage 与 MainPage 之间的隐式接口（ToolsPage 只收 `detailStack`，MyPage 只收 `detailStack` / `isSplit`，`:439/441`）。抽 `TabMenuState` 必须同步改这 2 个子页的调用点，不能用 wrapper 兼容两套入参。
3. **`windowClass` 时序来自 EntryAbility 写入 AppStorage**（M7），并依赖启动页的 1200ms 下限；抽 `MainTabContainer` 时不要把读取提前到更早的时机。H1（无 callback 的 `off`）修复前，折叠屏回归必须包含「触发一次人机验证后再折叠/展开」；H2 修复后回归必须包含「验证框弹出后用返回手势关闭，再触发一次验证」；M10 确认 / 修复后回归「Tab 根页按返回」。
4. **`TAB_HOME..TAB_MY` 索引**（`:28-31`）在 visibility（`:416-442`）、标题（`:395-397`）、菜单（`:364-366`）、toolbar 状态（`:456-488`）四处一致使用，改动时必须同步；它们与 `AppRoutes`、分栏布局无关。

**测试与验证**

- 该模块无自动化测试；M15 每个拆分步骤都要回归：4 Tab 互相切换 → 二级页返回 → 折叠屏展开/折叠 → 人机验证弹窗（含返回手势关闭）→ Cookie 过期弹窗（含多个账号同时过期）→ 账号切换弹窗。
- `TestPage` 入口已由 `BuildProfile.DEBUG` 隔离（`MainPage.ets:366`），release 不会暴露（mock / uat 以 debug 模式构建，可见）；但该页仍在 entry 的 `custom_router_map.json` 注册（见 [`test-page-module-analysis.md`](./test-page-module-analysis.md) §7，决策 Q-2）。
- 依赖 `'core'` 的 `GeetestVerifyInput` / `FailedAccountInfo`，拆分期间不要顺手改 Core 类型签名。

**分层（重构模块 M15 一并处理）**：MainPage 没有 ViewModel，弹窗仲裁直接调用 verification 的 `GeetestCenter` / `DeviceFpCenter`（§5.2 分层说明）。抽 `DialogArbiter` 时放进 ViewModel，MainPage 只保留弹窗 UI。

**拆分顺序**：MainPage 排最后（重构模块 M15）。HomePage / CharactersPage / ToolsPage / MyPage 各自完成 M8–M13 后，再抽 `MainTabContainer` + `TitleBarController` + `DialogArbiter` 三个职责，避免子页与容器同时改动。

### M15 执行记录（2026-11-06）

> 本轮为纯重构，未改 H1 / H2、弹窗仲裁时序、路由栈与 Tab 可见性契约。`MainTabContainer` / `DialogArbiter` 的大拆分保留（无自动化测试，需真机回归），先收敛可安全提取的重复与纯逻辑。

| 项 | 结果 |
| --- | --- |
| `MainPage.ets` | 513 → 473L |
| 工具栏 4 项 | 4 段同构对象收敛为 `createTabItem(label, icon, tab)`（`:385`）+ `switchTab(tab)`（`:376`）；`tabVersion >= 0` 恒真条件移除 |
| 窗口模式 | 纯逻辑抽到 `utils/MainNavigationMode.ets`（26L）：`isLandscapeOrientation` / `resolveNavigationMode`；`setCurrentMode()`（`:136`）只保留 try/catch 与赋值 |
| 弹窗标签 | `getGameAccountLabel` 抽到 `utils/MainDialogLabels.ets`（21L）；`getGeetestLabel`（`:182`）与设备指纹提示共用 |
| 其他 | Cookie 过期队列出队改 `slice(1)`（`:151`）；`charMenuItems` 尾部赋值改 `push`；删除未使用的 `getGameName` / `FailedAccountInfo` / `GameId` 导入 |
| 编译 | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 14s 996ms`，安装/启动成功 |
| 冒烟 | 🔶 待手动：4 Tab 切换 → 二级页返回 → 折叠屏展开/折叠 → 人机验证（含返回手势关闭）→ Cookie 过期（多账号）→ 账号切换 |

**保留不变量**：4 Tab 共享 `this.stack`（`:48`，`Navigation(this.stack)` 在 `:403`）；标题栏协议字段、`TAB_HOME..TAB_MY` 索引、`windowClass` 读取时序、`@Monitor` 三个信号均未改；`MainTabContainer` / `TitleBarController` / `DialogArbiter` 三个大拆分与 H1/H2 行为修复留待后续单独立项。

---

## 10. 复核命令（可复现）

```bash
# 字段 / 装饰器计数（29 = 16 @Local + 13 非 @Local；3 个 @Monitor；1 个模块级 @Builder）
grep -nE "@Local|@Monitor|@Builder" entry/src/main/ets/pages/MainPage.ets

# ArkTS 语法类（ARKTS-001~010 / 014 / 015）应为 0 命中
grep -nE "\bany\b|\bunknown\b|\bvar\b|= *function|@ohos\.|delete |for \(.* in |#[a-zA-Z_]+ *:|=\s*\+[a-zA-Z]" entry/src/main/ets/pages/MainPage.ets

# 静默吞异常（M11 的 10 处）
grep -nE "catch \(" entry/src/main/ets/pages/MainPage.ets

# 尺寸监听注册 / 注销（H1 的受害链路）
grep -rn "windowSizeChange" entry/src/main/ets features/verification features/chardetail features/dailynote

# 弹窗关闭路径（H2 缺少 onWillDismiss）
grep -rnE "onWillDismiss|openCustomDialog|closeCustomDialog|autoCancel" entry/src/main features/verification

# 魔法数字（ARKTS-013：≥ 100）
grep -nE "[^0-9](100|[2-9][0-9]{2}|[0-9]{4})" entry/src/main/ets/pages/MainPage.ets
```

---

*本文档仅分析，不修改代码。*

## 11. 校验记录

> 第 1-5 轮记录中的行号、文件名为当时（迁移前）的版本，保留原样作为历史。

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 字段） | 525 行、29 状态字段（16 @Local + 13 非 @Local）、3 @Monitor、1 @Builder | ✅ 全部精确匹配 |
| 第 2 轮（行号引用） | H1 L60/L470-500、H2 L284-342、M1-M8 全部行号、L1-L5 全部行号、L2 10 处 catch | ✅ 全部精确 |
| 第 3 轮（全面复核） | build() 结构树、Tab 传参、TestPage 路由、Index pageBuilder、无测试声明 | ✅ 修正 2 处（H3 可选链 / §5.1 机制图） |
| 第 4 轮（2026-10-26 复核） | 补 §6 合规检查（11 条 checklist）；核对 `:153` 魔数 4、`:193/202/269` release 路径、`:403` 空 catch、`:133-140` off 监听 | ✅ 无新增风险，计数维持 0/3/8/5 |
| 第 5 轮（2026-10-27 逐条复核） | 逐条回到代码验证 H/M/L 描述；连带读 `GeetestDialog` / `GeetestDialogHelper` / `GeetestSignal` / `CookieExpiredSignal` / `EntryAbility` / `Launch` | 撤回原 H1/H2/M7/M8/L3/L4，原 H3 降为 M7，新增 H1（无 callback 的 `off('windowSizeChange')`）与 L4（`geetestCancelAllRequested` 死分支）；修正 `trigger` 语义与 7 处行号。计数 0/3/8/5 → **0/1/7/4**，评级 B 不变，债务 30 → 21 |
| 第 6 轮（2026-10-29 结构迁移后） | 全文行号、路径、命名按迁移后代码重核：文件 525 → 513 行（import 合并为包名）；struct `Main` → `MainPage`，子页 `Home` 等 → `HomePage` 等，`gameIdToName` → `getGameName`，10 个字段改名（`homeShowRefresh` → `shouldShowHomeRefresh`、`geetestShowing` → `isGeetestShowing` 等）；`GeetestDialogHelper` → `verification/utils/GeetestDialogUtil`；跨文件引用（GeetestDialog / GeetestSignal / CookieExpiredSignal / EntryAbility / LaunchPage / Navigation-Split-Guide）逐个重核 | 结论与计数不变（0/1/7/4，B，债务 21，密度 4.0 → 4.1）。更正：§2 原标题「25 项」是迁移前的 import 语句数（25 条、33 个符号，已对迁移前备份核对），表内实际列了 33 个符号，现改为「12 条 import，33 个符号」；M3 枚举值改为引用官方 API 参考（原文注明「本机无 SDK 源码」未核实）；`CookieExpiredSignal` 行号 34-39/54 → 33-38/53；补充分层说明（MainPage 无 ViewModel、直接调用 verification 服务，不计入评级） |
| 第 7 轮（2026-10-29 独立审稿） | 独立审稿人逐条回代码与官方文档（promptAction、@Monitor、window、Navigation）核对，报 29 项；逐项复核全部成立 | 恢复 H2（返回手势关闭验证框后队列卡死，10-27 撤回理由漏了该路径）；原 L3 升为 M8（`@Monitor` 内改 `queue` 致回调连续重触发、多个过期弹框叠加；Cookie 弹框不参与仲裁）；新增 M9（窗口 API 未包 try）、L5（`closeCustomDialog` 无 catch、未判 `code`）、L6（`ComponentContent` 未 dispose）、L7（「UID」硬编码）；M4 扩充（两端 clamp、520 / 560 矛盾、520vp 为 API 9 阈值）；L1 补 ARKTS-013 的 5 个数值；更正：import 13 条（非 12）、§3.5 `@Local` 的真实原因、§5.2 仲裁范围与伪代码、§5.3 失败静默条件、H1 受害方（6 个详情页；EntryAbility 监听无读取方、MainPage 自身 off 实际无害）并补官方依据、M1 / M2 / M6 / M7 建议、§9 不变量 2 / 4、原 M8 撤回理由措辞；合规表补 ARKTS-011。计数 0/1/7/4 → **0/2/9/6**，评级 B 不变，债务 21 → 30。注：合规表现为 13 行（第 4 轮记录的「11 条」是当时的行数） |
| 第 8 轮（2026-10-29 独立审稿第 2 轮） | 新审稿人从头核对，报 17 项；逐项回代码复核，16 项成立、1 项部分成立（CharactersPage 回调行号：原文 `:18-20` 截短，审稿人给的 `:9-17` 也不对，实为 `:18-26`） | 更正 §5.1 行号；§5.2 补第四条结束路径（JS bridge 回调）与启动阶段验证上报被丢弃的时序风险（未确认可达，不计入）；M5 补提前返回跳过挂起检查的边缘路径；M7 补「windowWidthVp 停在 360、竖屏始终单栏」与可选链表述；L5 补 `:268` 未 await / catch 并说明按实际影响记 Low 的理由；LIFE-001 与「做得对」改为与 H1 一致（MainPage 自身 off 实际无害）；合规表前言更正、补 TEST-001、SEC-002 证据补日志明文 key；STATE-008 补菜单 getter；`M15` 改称「重构模块 M15」避免与缺陷编号混淆；注明第 1-5 轮记录为迁移前行号。计数不变（0/2/9/6，B，债务 30） |
| 第 9 轮（2026-10-29 独立审稿第 3 轮） | 新审稿人从头核对：全部行号、计数、官方文档表述无误；报 14 项，逐项回代码复核全部成立 | 新增 M10（Tab 根页按返回可能弹出 MainPage 显示空白，待真机确认）；H2 补 reject 同类路径与 `contentNode` 未释放；M3 补横屏分支不看窗口宽度；H1 改按 LIFE-001 计（默认 High，原挂在 COMPAT-004 未说明理由）；MainPage 自身 off 的前提改为「销毁时」；补 COMPAT-005 行（在 TestPage 文档计数）、时序风险补设备指纹、L7 补日志 tag、STATE-008 改指 M6、HomePage 行号、§8 补 GeetestDialog。未采纳：菜单 `value` 英文（官方说明 API 10 起不显示，审稿人也标低置信）；Refactor_Spec §2.1 的 `Main` 属迁移前快照（已标注）。计数 0/2/9/6 → **0/2/10/6**，评级 B，债务 30 → 32 |
| 第 10 轮（2026-10-29 按 skills 复核） | 对照 `skills/harmonyos-review/references/checklist.md`、`skills/harmonyos-review/references/report-template.md`、`skills/arkts-rules/references/spec-quick-ref.md`、`skills/state-management/SKILL.md`、`skills/harmonyos-development/SKILL.md` 重扫；代码事实（513 行、29 字段、13 import / 33 符号、全部 `file:line`、GeetestSignal / GeetestCenter / CookieExpiredSignal / EntryAbility / Index / LaunchPage 引用）逐条回核 | 结论与计数不变（0/2/10/6，B，债务 32，密度 6.2）。修正 4 处与 skills 的偏差：① §3.5「@Monitor 只能监听 @Local 等」表述过窄，补 `@ObservedV2` + `@Trace` 用法与 `state-management` 范例 5 出处；② 问题清单补「规则 ID」列（M3 / M4 → COMPAT-004、ARKTS-013；M7 / M8 → STATE-013 / STATE-012；M10 → NAV-001 同类；H2 → LIFE-004 + KIT-005；L2 → ARKTS-016；L7 → AGC-RJ-014），架构类无对应条目记 `—`；③ 合规检查补 `ARKTS-016` / `AGC-RJ-014` / `NAV-001` 三行，并把 `LIFE-004` 由 ✅ 改为 ⚠️（与 H2 一致）；④ 按 report-template 补「整体观察」「复审建议」「复核命令」附录，页头补审查者 / targetSDK / 代码版本 / 路径说明 |
| 第 11 轮（2026-10-29 严重级对齐 scan-arkts） | 按 `skills/arkts-rules/references/scan-arkts.sh` 的默认级别复核 `ARKTS-016`：该脚本把空 catch 判为 Medium（且仅在文件含 `await` 时触发），MainPage 含 `await`（`:44-46` 等） | 原 L2（10 处静默吞异常）升为 **M11**，L 表保留 `~~L2~~` 改判说明；§5.3、合规表 `ARKTS-016` / `KIT-005` 行同步改指 M11；§10 复核命令注释同步。计数 0/2/10/6 → **0/2/11/5**，评级 B 不变，债务 32 → 33，密度 6.2 → 6.4 |

【已核对代码一致性】
