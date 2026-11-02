# Home 模块分析

> **审查对象**：`features/home/src/main/ets/` —— `HomePage.ets`（185 行）+ `HomeViewModel.ets`（728 行）+ 8 个 view（485 行）；共享依赖 `common/basic` 的 `UserGameSection`（76 行）/ `UserGameSectionHeader`（58 行）/ `AccountRoleModels`（192 行）
> **审查日期**：2026-10-24（2026-10-29 结构迁移后复核，见 §10 第 7 轮）
> **审查者**：AI 助手（`skills/harmonyos-review` checklist + `skills/arkts-rules` 规则）
> **代码版本**：`e00e579`（结构迁移后）。文中 `:行号` 未注明文件时指 `HomePage.ets`；ViewModel、组件与模型按迁移后的路径给出（见 [project-structure.md](./project-structure.md) §4.4）
> **HarmonyOS targetSDK**：API 22（`6.0.2(22)`）
> **口径**：skills `harmonyos-review` 官方 A-F 评级
> **路径说明**：按项目既有约定放在 `docs/<module>-module-analysis.md`（[docs/README.md](./README.md) §6），不采用 skill 默认的 `docs/reviews/`
> **旧版结论**：92/100（百分制，已废弃）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 6 |
| Low | 5 |

**整体评级：B**

> 一句话结论：首页 View 层本身干净，问题集中在 ViewModel。**手动刷新一次后 `isAutoSync` 永不复位，后台同步开始弹错误 toast；单角色失败被吞掉，手动刷新仍报成功**（M1）。其次是与 ArkUI 复用规则相关的 ForEach key 覆盖不全（M2）、728 行 / 10 种职责（M3）、20 个无读取方的游戏专属字段（M4）、4 处空 catch + 6 处空 `.catch`（M5）与三层 ForEach（M6）。
>
> 结构迁移已解除原 M1（`UserGameSection` 双模式）与原 M3（home ↔ widget 双向依赖）：`UserGameSection` 已迁入 `common/basic`，改为 `roleBuilder` 插槽，Home 注入 `GameToolCard`、WidgetSettings 注入 `WidgetSlotOption`，两边不再互相 import。
>
> 债务点数 = 6×2 + 5×1 = **17**；源行数按 `HomePage.ets` 185 行计（与 README 口径一致，不含 ViewModel / 组件），密度 = 17 ÷ 1.85 ≈ **9.2**/百行。

---

## 1. 文件与组件清单

### 1.1 本模块文件

| 文件 | 行数 | 职责 |
| --- | --- | --- |
| `pages/HomePage.ets` | 185 | 首页 View：三态渲染（骨架 / 空态 / 数据）、7 个 `@Monitor`、`@Builder` 角色卡片、详情页路由跳转 |
| `viewmodel/HomeViewModel.ets` | 728 | 首页数据逻辑：加载 / 刷新 / 同步 / 卡片组装 / 路由参数 / 通知触发 |
| `views/HomeSkeletonView.ets` | 40 | 骨架屏容器（硬编码 2 个账号骨架卡片） |
| `views/AccountSkeletonCard.ets` | 33 | 单账号骨架卡片（4 个 `SkeletonBlock`） |
| `views/SkeletonBlock.ets` | 46 | 骨架色块，`animateTo` + `iterations: -1` 呼吸动画 |
| `views/GameToolCard.ets` | 89 | 单游戏战绩卡片：头部 + 分割线 + 通用内容区 / 无数据提示 |
| `views/GameToolCardHeader.ets` | 75 | Logo + 游戏名 + 服务器/昵称 + 同步时间 |
| `views/GameToolCardContent.ets` | 51 | 主体力区块 + `ForEach(dataRows)` 数据行列表 |
| `views/GameStaminaBlock.ets` | 102 | 体力大数字 + 环形进度 + 恢复描述 |
| `views/GameDataRow.ets` | 49 | 标签 + 值数据行 |
| **合计（10 文件）** | **1,398** | 185 + 728 + 485 |

### 1.2 共享依赖（`common/basic`）

| 文件 | 行数 | 用途 |
| --- | --- | --- |
| `shares/UserGameSection.ets` | 76 | 账号 + 角色区块容器；`account` + `roleBuilder` 插槽，Home 与 WidgetSettings 共用 |
| `shares/UserGameSectionHeader.ets` | 58 | 头像 + 昵称 + 游戏数 + 折叠箭头 |
| `model/AccountRoleModels.ets` | 192 | 4 个数据类：`GameDataRowVM` / `GameNoteSnapshotVM` / `GameRoleCardVM` / `MihoyoAccountVM`（原 `HomeModels.ets` 已并入） |

### 1.3 测试

| 文件 | 行数 | 用例 |
| --- | --- | --- |
| `features/home/src/test/HomeViewModel.test.ets` | 105 | 14 条：初始态 5 + 防重入 2 + `dispose` 2 + `getGameColor` 3 + `getGameColorByStr` 1 + 重复的冷却初始态 1 |

---

## 2. 结构与调用链

### 2.1 页面结构树

```
HomePage.build()（:105-153）
├── viewState === LOADING → HomeSkeletonView()
│   └── AccountSkeletonCard() × 2（硬编码，非 ForEach）
│       └── SkeletonBlock × 4（animateTo + iterations: -1）
├── viewState === EMPTY → PlaceholderView（无账号占位，按钮跳 Login）
└── else → Scroll(scroller) → Column
    ├── ForEach(vm.accounts) → UserGameSection（:129-141）
    │   ├── UserGameSectionHeader（头像 + 昵称 + 游戏数 + 折叠箭头）
    │   └── if (!isCollapsed) → Column → ForEach(account.roles)
    │       └── roleBuilder → GameToolCard（HomePage.ets:156-164）
    │           ├── GameToolCardHeader
    │           └── GameToolCardContent
    │               ├── GameStaminaBlock
    │               └── ForEach(dataRows) → GameDataRow
    └── Row().height(value40)（底部占位）
```

> Home 是底部 Tab 内嵌页，**无 Stack 顶部导航区**；刷新按钮由 Main 的 `Navigation.menus()` 承载（`MainPage.ets:339`）。Home 常驻在 Main 的 `Stack` 中，切 Tab 只改 `visibility`（`MainPage.ets:416`），因此 `aboutToDisappear` 实际只在 Main 销毁时触发。`HomeViewModel` 不产生 ERROR 态（`ViewState.ets:9-19` 有 `ERROR`，但 Home 全文件无赋值），加载失败落到 EMPTY（`HomeViewModel.ets:131`），网络错误通过 `showFeedback` toast 提示。

### 2.2 生命周期与回调

1. **`aboutToAppear()`**（`:28-32`）→ 获取 `uiCtx`；通过 `onReady` 把 `() => this.vm.refresh()` 交给 Main（`MainPage.ets:68` 存入 `homeDoRefresh`，`:339` 由标题栏刷新按钮调用），**不在此处触发刷新**；首屏数据由 `:31` 的 `vm.loadData()` 加载。`HomeViewModel` 在 `@Local vm` 字段声明时（`:21`）已初始化。
2. **`aboutToDisappear()`**（`:34-36`）→ 调用 `vm.dispose()`（内部 `stopAutoRefresh()`，`HomeViewModel.ets:241-243`）。`@Monitor` 注册的信号监听由框架自动清理。
3. **`@Monitor`（7 个）**：`signal.version`（`:38-41`）、`vm.viewState`（`:43-46`）、`vm.isRefreshing`（`:48-51`）、`vm.networkErrorMsg`（`:53-61`）、`vm.isRefreshCoolingDown`（`:63-83`）、`syncRetry.version`（`:86-89`）、`vm.refreshResult`（`:91-103`）。逐条行为见附录 A。
4. **Refresh 机制**：Main 标题栏刷新按钮 → `refresh()`（`HomeViewModel.ets:187-213`）→ 距上次手动刷新不足 30 分钟则翻转 `isRefreshCoolingDown`，由 Home 弹确认框（`:63-83`），确认后 `forceRefresh()`（`:218-238`）；否则先网络同步所有 daily_note → 再读 DB → 渲染。
5. **Geetest 人机验证**：Repository 层上报 → `GeetestCenter` 统一弹框 → 验证通过后通过 `SyncRetrySignal` 通知 View 调用 `forceRefresh()`（`:86-89`）。
6. **账号变更**：`AccountSignal.notify()` → `HomePage.ets:38-41` → `vm.loadData()`。发送方见 L1。

### 2.3 状态机与数据流

```
loadData()（:121-182）
  → await CoreInitializer.waitForReady()
  → viewState = LOADING
  → fetchFromLocal()：BBS 账号 → 角色 → daily_note 快照 → MihoyoAccountVM[]
  → 有数据 DATA / 无数据或异常 EMPTY
  → 分支：
      ├─ 有账号但全部无角色卡 → await syncAllDailyNotes() → 重新 fetch
      └─ 否则：
          ├─ 没有任何 snapshot（首次登录）→ await syncIfNeeded() → 重新 fetch
          └─ 有 snapshot → 先渲染，再后台 syncIfNeeded()
  → startAutoRefresh()（30 分钟 setInterval）
  → StaminaNotificationService.getInstance().onDailyNotesSynced()
  → ColdStartCookieChecker.checkAndRefreshAll(...)
```

- `refresh()` / `forceRefresh()`：`syncAllDailyNotes()` → `fetchFromLocal()` → 写 `accounts` / `viewState` / `refreshResult`；`finally` 复位 `isRefreshing`。
- `syncIfNeeded()`：逐账号逐角色调用 `needsDailyNoteSync()`，30 分钟内同步过的角色跳过；`syncAllDailyNotes()` 全量。
- `syncDailyNote()`：按 `gameId` 分派到三个 Repository；`AuthExpiredError` 推入 `CookieExpiredSignal`；`VERIFICATION_REQUIRED` 只记日志；其他错误按 `isAutoSync` 决定是否写 `networkErrorMsg`。
- `fetchFromLocal()` / `buildRoleCards()` / `loadDailyNoteSnapshot()`：把 DB 行解析成 `GameRoleCardVM`，三游戏的 `dataRows` 与颜色规则都在 `loadDailyNoteSnapshot()`（`:466-672`，全文件最大块）。
- 通知 / Widget：`onDailyNotesSynced()` 在 `:174`（冷启动）、`:367`（`syncIfNeeded` 末尾）、`:384`（`syncAllDailyNotes` 末尾）三处调用；服务侧重复触发与去重问题见 [notification-service](./notification-service-modules-analysis.md) M4，本文不重复计数。

### 2.4 共享组件复用

`UserGameSection` 已从 `components/home/` 迁入 `common/basic/shares/`，API 从「`mode` + 4 个回调」收敛为「`account` + `roleBuilder`」：

- **Home**：`roleBuilder: (role) => this.homeRoleCardBuilder(account, role)`（`HomePage.ets:132`），渲染 `GameToolCard`。
- **WidgetSettings**：`roleBuilder: (role) => this.slotRoleBuilder(account, role)`（`features/widget/.../WidgetSettingsSlotStep.ets:88-91`），渲染 `WidgetSlotOption`。
- `UserGameSection` 只依赖 `ThemeManager` / `AccountRoleModels` / `UserGameSectionHeader`（`:11-13`），**不再 import widget 的任何模型或组件**；home 与 widget 的双向依赖已解除。
- 调用方必须用箭头函数包一层，保证 `@Builder` 内的 `this` 指向调用方（`UserGameSection.ets:8-9` 的注释与 `HomePage.ets:132` 的写法）。

---

## 3. ArkTS / 状态管理合规

> 逐条对照 `.opencode/skills/harmonyos-review/references/checklist.md` 与 `.opencode/skills/arkts-rules/references/spec-quick-ref.md`，只列与本页相关的条目。

| 规则 ID | 检查项 | 结论 | 证据 / 说明 |
| --- | --- | --- | --- |
| STATE-001 | 不混用 V1 / V2 | ✅ | `HomePage.ets:14` 及各 view 均为 `@ComponentV2`；`HomeViewModel.ets:55` 为 `@ObservedV2`；全目录无 `@State` / `@Prop` / `@Link` / `@Observed` |
| STATE-002 / STATE-003 | 数组 / 对象走引用替换 | ✅ | Home 只读 `vm.accounts`（`HomePage.ets:129`），不做就地 mutation；`UserGameSection.isCollapsed` 是标量 |
| STATE-007 | `@Event` 必须有默认值 | ✅（本项目用回调 `@Param`） | `HomePage.ets:18-20`、`UserGameSectionHeader.ets:14` 等回调 `@Param` 都给了 `() => {}` 默认值 |
| STATE-012 | `@Monitor` 内不修改触发字段 | ⚠️ 有界双触发，未计入风险清单 | `HomePage.ets:53-61`（`onNetworkErrorChanged`）在 `@Monitor('vm.networkErrorMsg')` 内把 `vm.networkErrorMsg` 置空；`:91-103` 同理处理 `vm.refreshResult`。第二次触发因 `msg === ''` 直接 return，**不会无限循环**，但属同一 flutter 模式。建议 M8 拆 VM 时改为 `consumeError()` / 一次性事件通道 |
| LIFE-001 | `aboutToDisappear` 释放订阅 / 定时器 | ⚠️ 部分满足 | `HomePage.ets:34-36` 调 `vm.dispose()`（内部 `stopAutoRefresh()`）✅；`SkeletonBlock` 的无限 `animateTo` 无 `aboutToDisappear`，动画绑定在节点上、随组件销毁结束，泄漏无证据（见 L3，需真机确认） |
| LIFE-004 | 跳转前清理弹窗 / Toast | ✅ | `DialogDedup.tryAcquire('home_refresh_cooldown')` 在 `then` / `catch` 两条路径都 `release`（`HomePage.ets:77` / `:80`） |
| PERF-001 | 无 `forEach + await` | ✅ | `HomeViewModel` 全文件无 `forEach`（用 `for` 循环） |
| PERF-002 | 长列表用 `LazyForEach` | ⚠️ 已记 M6 | 三层 `ForEach`（`HomePage.ets:129` → `UserGameSection.ets:39` → `GameToolCardContent.ets:33`）；账号 / 角色 / 数据行规模为个位数～十几，暂不构成卡顿，按结构性技术债记 Medium，不强制改 `LazyForEach`（需要 `IDataSource` 包装 + 数据源可变，收益低于风险） |
| PERF-008 | 列表项带 `key` | ⚠️ 已记 M2 | 外层 key 只含 `accountId` + 各角色 `roleUid:primaryCurrent`（`HomePage.ets:134-141`）；中层 key = `roleUid + gameId`（`UserGameSection.ets:41`）；内层 key 仅为下标 `row_${idx}`（`GameToolCardContent.ets:39`） |
| ARKTS-001 | 无 `any` / `unknown` / `var` | ✅ | HomePage / ViewModel / views / UserGameSection grep 均无命中 |
| ARKTS-012 | 日志走 hilog，不用 `console.*` | ✅ | 统一 `Logger`（core），无 `console.` |
| ARKTS-016 | 空 catch 块不以静默吞错收场 | ❌ 已记 M5 | `HomeViewModel.ets:160 / :167 / :263 / :447` 四处 `catch (_) {}`；另有 6 处空 `.catch`（`:168 / :174 / :181 / :264 / :367 / :384`）。`scan-arkts.sh` 对该规则默认 Medium（文件含 `await` 时触发），本文件含大量 `await` |
| KIT-005 / ARKTS-011 | Kit Promise 都有 catch，`BusinessError` 判 code | ⚠️ 已记 M5 | `StaminaNotificationService.getInstance().onDailyNotesSynced()` 的 3 处调用都有 `.catch`，但都是空函数；`HomePage.ets:79` 的 `showDialog` catch 有 `BusinessError` 类型与日志；VM 内其余 catch 只记 `message`，不判 `code` |
| COMPAT-004 | 多端断点适配 | ✅ / 由 Main 承担 | Home 只接 `isSplit` 一个标识（`HomePage.ets:17`），断点判定在 `MainPage.ets`；折叠屏修复属 Main 文档的 H1 / M3 / M7 |
| TEST-001 | 核心逻辑有单测 | ⚠️ 覆盖不足，不计入评级 | `features/home/src/test/HomeViewModel.test.ets`（105 行、14 条）覆盖初始态 / 刷新防重 / `dispose` / 颜色；**未覆盖** `syncDescKey` / `getPrimaryColor` / `buildCardTapRoute` / `loadDailyNoteSnapshot` / 同步错误语义。旧文档「import 路径错误、Local Test 无法编译」已随结构迁移修复：当前 `:2-4` 的 `HomeViewModel` / `ViewState` / `getGameColorByStr` / `GameId` 均可解析 |
| SEC-002 | 敏感数据不入日志 | ✅ | 日志只含 `accountId` / `roleId` / `gameId` / 错误 message，不写 cookie / token |

> 合规结论：Home 自身的 ArkTS / 状态管理基本干净，问题集中在**同步错误语义**（M1）、**列表 key**（M2）、**ViewModel 体量**（M3）、**模型字段膨胀**（M4）、**空 catch**（M5）与**三层 ForEach**（M6）；`@Monitor` 内清空触发字段仅记观察项，不计入债务。

---

## 4. 风险清单

### Medium（建议后续迭代）

| # | 规则 ID | 问题 | 位置 | 说明 | 建议 |
| --- | --- | --- | --- | --- | --- |
| M1 | — | **`isAutoSync` 置 false 后永不复位；手动刷新部分失败仍报成功** | `HomeViewModel.ets:70`（初值 `true`）、`:197` / `:222`（`refresh` / `forceRefresh` 置 `false`）、`:336-338`（错误上报条件）、`:205` / `:230`（`refreshResult = 'success'`） | `isAutoSync` 全文件只有初值 `true` 与两处置 `false`，**没有任何复位**。用户手动刷新一次（或 Geetest 通过触发 `forceRefresh`）之后，30 分钟定时器（`:276-291`）、`loadData` / 账号变更时的 `syncIfNeeded`（`:346-368`）中的单角色失败都会写 `networkErrorMsg`，**后台同步开始弹错误 toast**，与 `:65-69` 注释「自动同步静默」相反。另外 `syncDailyNote` 吞掉所有单角色异常（`:303-341`），`refresh` / `forceRefresh` 照常走到 `refreshResult = 'success'`，用户会同时看到错误 toast 与「刷新成功」toast | 在 `refresh` / `forceRefresh` 的 `finally` 中复位 `isAutoSync = true`；`syncDailyNote` 返回成功/失败，`syncAllDailyNotes` 汇总失败数后决定 `refreshResult`（行为变更，单独提交） |
| M2 | PERF-008 | **首页 / 角色 / 数据行三级 ForEach key 覆盖不全，次要数据可能不刷新**（需真机确认） | `HomePage.ets:134-141`；`UserGameSection.ets:41`；`GameToolCardContent.ets:39`；`HomeViewModel.ets:448-458` | 外层 key 只由 `accountId` + 各角色 `roleUid:primaryCurrent` 组成；中层 key 只有 `roleUid + gameId`；内层 key 仅为下标。`MihoyoAccountVM` / `GameRoleCardVM` / `GameDataRowVM` 都是普通类（无 `@ObservedV2`），按 ForEach 的键值复用规则，key 不变时该项不会重新渲染：主体力未变（典型如树脂已满停在上限）时，`dataRows`（派遣/洞天/委托/实训等）、`lastSyncDesc`（「x 分钟前」）、账号昵称/头像、角色昵称/服务器的更新不会反映到 UI。外层 key 拼入 `primaryCurrent` 本身说明作者已遇到过这一刷新问题，但只覆盖了主数值 | 给 VM 增加单调递增的 `version` 字段并并入三层 key，或把 `dataRows` / `lastSyncDesc` / 昵称头像的摘要并入 key；M8 拆分时一并处理（行为变更，单独提交） |
| M3 | — | **`HomeViewModel` 职责过重**（728 行，10 种职责） | `HomeViewModel.ets` 全文 | 数据加载、状态机、刷新冷却、错误上报、冷启动 Cookie 检查、单角色/按需/全量同步、三游戏便笺解析、卡片组装、路由参数、通知触发、自动刷新定时器全部集中在一个类；难以维护、难以测试。纯结构性技术债，用户无感知（按跨文档口径记 Medium） | 按 §5 拆分为 3 个文件，保留 `HomeViewModel` facade 与导出符号；`refresh` / `forceRefresh` 的重复代码一并收敛 |
| M4 | — | **`GameNoteSnapshotVM` 字段膨胀，20 个游戏专属字段无读取方** | `AccountRoleModels.ets:61-107`；写入点 `HomeViewModel.ets:483-489`（原神）/ `:544-552`（星铁）/ `:615-625`（绝区零） | 除通用 `primary*` / `secondary*` / `dataRows` / `primaryColor` 外，类里塞入三游戏专属字段（原神 7 个 / 星铁 9 个 / 绝区零 4 个），新增游戏仍需扩类。这些字段只在 `loadDailyNoteSnapshot()` 写入，`features/home`、`entry/src/test`、`common/basic/src/test` 中**没有任何读取方**；UI 全部走 `dataRows`（`GameToolCardContent.ets:30-40`）。与「ViewModel 决定数据行、View 只渲染」的设计目标不符 | 删除无读取字段，或改为 `extraRows: GameDataRowVM[]` 数据驱动；属模型契约变更，M8 后单独提交 |
| M5 | ARKTS-016、KIT-005、ARKTS-011 | **4 处空 catch + 6 处空 `.catch` 静默吞错** | `HomeViewModel.ets:160 / :167 / :263 / :447`（`catch (_) {}`）；`:168 / :174 / :181 / :264 / :367 / :384`（`.catch((_: Error \| object) => {})`） | `:160` / `:167` 吞掉首次登录 `syncIfNeeded` / `fetchFromLocal` 失败，页面可能停在「有账号但无卡片」；`:263` 吞掉冷启动 Cookie 刷新后的重读失败；`:447` 吞掉 `getDailyNoteLastSyncTime` 失败并静默显示「从未同步」；6 处空 `.catch` 让通知 / Widget 推送、冷启动 Cookie 检查失败完全无日志。`scan-arkts.sh` 对 `ARKTS-016` 默认 Medium；`KIT-005` 在 checklist 默认 High，但这里只是少日志 / 少提示，不改变已成功路径，按工具口径与影响记 Medium | 每处补一行 `Logger.warn`（含 `BusinessError.code` 或 `error.message`）；确认是 cleanup 容错的加 `// scan-ignore: ARKTS-016` 并注明原因；通知推送的 3 处至少记录一次失败日志 |
| M6 | PERF-002 | **三层 ForEach 嵌套，未使用 `LazyForEach`** | `HomePage.ets:129` → `UserGameSection.ets:39` → `GameToolCardContent.ets:33` | 账号 × 游戏角色 × 数据行的三重 ForEach；当前账号 / 角色 / 数据行规模为个位数～十几，实际卡顿风险低，按结构性技术债记 Medium。新增游戏或数据行时会放大 | 暂不强制改 `LazyForEach`（需要 `IDataSource` 包装 + 数据源可变，收益低于风险）；M8 拆分时评估最外层是否值得懒加载，并保留 `@Reusable` 优化空间 |

### Low（持续观察）

| # | 规则 ID | 问题 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| L1 | — | **`loadData()` 无重入保护，且所有 `AccountSignal` 都触发完整冷启动流程** | `HomePage.ets:38-41`；`HomeViewModel.ets:121-182`（`:123` 置 LOADING、`:171` 重启定时器、`:177-181` 跑冷启动 Cookie 检查） | `AccountSignal.notify()` 除登录 / 账号详情外，还由三个材料目标配置 VM 在保存时发出（`GenshinMaterialTargetConfigViewModel.ets:187`、`StarRailMaterialTargetConfigViewModel.ets:196`、`ZZZMaterialTargetConfigViewModel.ets:217`）。每次都会把 `viewState` 重置为 LOADING（首页可见时骨架屏闪一下）、重启定时器、再跑一遍 `ColdStartCookieChecker`（受 7 天阈值约束，多数为空转）；`loadData` 无 in-flight 标记，与 `aboutToAppear` 的首次调用重叠时两轮各自写 `accounts` / `viewState`。`onDailyNotesSynced` 的重复触发已在 notification 文档 M4 记录，此处不重复计数 |
| L2 | — | **卡片无障碍文本读出的是 gameId** | `HomeViewModel.ets:448-458`（构造 `GameRoleCardVM` 时把 `role.gameId` 同时传给 `gameId` 与 `gameName`）；`GameToolCard.ets:59`（`a11y_game_card` 用 `card.gameName`） | 读屏会读出 `genshin` / `starrail` / `zzz`；标题文字本身走 `getGameName(card.gameId)`（`GameToolCardHeader.ets:38`），不受影响。建议 `gameName` 改填 `getGameName(role.gameId)`，或 a11y 直接用 `getGameName(card.gameId)` |
| L3 | LIFE-001 | **`SkeletonBlock` 的 `animateTo(iterations: -1)` 无限动画无显式停止** | `SkeletonBlock.ets:17-20`（`aboutToAppear` 调 `startShimmer`）、`:22-36`（`iterations: -1` 在 `:29`） | 无 `aboutToDisappear` / stop。动画绑定在该节点上，骨架屏随 `viewState` 离开 LOADING 被销毁时动画随之结束，泄漏无证据（需真机确认）；按骨架屏无限动画统一口径记 Low（与 `CharactersSkeleton` 一致）。可在 `aboutToDisappear` 以 `duration: 0` 的 `animateTo` 复位 `shimmerOpacity` 作保险 |
| L4 | — | **结构迁移残留**：未使用的类型别名、空废弃方法、过期文件头注释 | `HomeViewModel.ets:45`（`export type HomeViewState = ViewState;` 全仓无引用）、`:272`（`showNextCookieExpiredDialog()` 已 `@deprecated` 且无调用方）、`AccountRoleModels.ets:2`（文件头仍写 `HomeModels`） | 不影响运行；建议随 M8 拆分一并删除 / 改名，避免后来者误用 |
| L5 | — | **`features/home` 的 `widgetbase` 依赖未使用** | `features/home/oh-package.json5` 的 `dependencies.widgetbase`；`features/home` 全目录无 `from 'widgetbase'` | 结构迁移后 Home 只依赖 `core` / `basic` / `dailynote` / `notification`；`widgetbase` 是残留依赖。建议删除，并同步 `docs/project-structure.md:71` 的依赖清单 |

### 复核撤回 / 改判（2026-10-29）

| 原条目 | 处理 | 依据 |
| --- | --- | --- |
| 原 M1「`UserGameSection` 双模式耦合」 | **撤回**（不计入本文） | `UserGameSection.ets:16-23` 已改为 `@Param account` + `@BuilderParam roleBuilder`，`mode` / `onCardTap` / `isSlotSelected` / `onSlotToggle` 全部删除；Home 与 WidgetSettings 各自注入卡片，if-else 分支消失 |
| 原 M3「首页组件与 widget 子系统双向依赖」 | **撤回**（不计入本文） | `UserGameSection` 已迁入 `common/basic/shares/`，只 import `ThemeManager` / `AccountRoleModels` / `UserGameSectionHeader`（`:11-13`）；`WidgetSettingsSlotStep.ets:88-91` 通过 `roleBuilder` 复用，home 不再 import widget 组件或模型。Refactor_Spec §2.4 的 `WidgetSlotRef` 契约问题随之解除 |
| 原 M2「三层 ForEach 嵌套」 | **保留，重编号为 M6** | 代码仍为三层 ForEach（`HomePage.ets:129` / `UserGameSection.ets:39` / `GameToolCardContent.ets:33`）；按结构性技术债记 Medium |
| 原 M4「`GameNoteSnapshotVM` 字段膨胀」 | **保留为 M4** | 专属字段仍在 `AccountRoleModels.ets:61-107`，仍无读取方 |
| 原 M5「`isAutoSync` 不复位 / 部分失败仍报成功」 | **保留，升为 M1**（按用户影响排序） | 代码未变：`HomeViewModel.ets:70 / :197 / :222 / :336-338` |
| 原 M6「ForEach key 覆盖不全」 | **保留，升为 M2** | 三层 key 仍未覆盖 `dataRows` / `lastSyncDesc` / 昵称头像 |
| 原 M7「ViewModel 754 行职责过重」 | **保留为 M3**；行数改为 728 | 结构迁移把部分 import / 代码合并，净减 26 行；职责仍为 10 种 |
| 原 L1「`loadData` 无重入保护」 | **保留为 L1** | 代码未变 |
| 原 L2「a11y 读出 gameId」 | **保留为 L2** | 代码未变 |
| 原 L3「SkeletonBlock 无限动画」 | **保留为 L3** | 代码未变 |
| 原 TEST-001「测试 import 路径错误、无法编译」 | **改判为「可编译但覆盖不足」** | 当前测试 `:2-4` 的 import 均可解析；14 条用例覆盖初始态 / 防重入 / `dispose` / 颜色，未覆盖同步与纯函数 |
| 新增 M5 / L4 / L5 | 新增 | 4 处空 catch + 6 处空 `.catch`；迁移残留；未使用的 `widgetbase` 依赖 |

### 不计入风险的观察项

- **`@Monitor` 内清空触发字段**（`HomePage.ets:53-61` / `:91-103`）：有界双触发，第二次因空串直接 return，不会无限循环；M8 拆分时改为 `consume` 语义即可。
- **`loadData` 失败落 EMPTY 而非 ERROR**（`HomeViewModel.ets:128-132`）：DB 读失败时用户看到「无账号」占位，而不是错误页；属产品语义选择，暂不计数。
- **`loadDailyNoteSnapshot` 的 `>= 0` 恒真判断**（`HomeViewModel.ets:493 / :504 / :515` 等）：解析器对缺失字段默认 0，导致派遣 / 洞天 / 委托行总是显示；当前不影响正确性，若要做「字段存在才显示」需解析器返回 `-1` 或 `null`，属行为变更。
- **`refresh` / `forceRefresh` 约 25 行重复**（`:187-213` / `:218-238`）：M3 拆分时收敛为一个私有方法即可，不单独计数。

---

## 5. 重构执行备注（重构模块 M8 · Home）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用；本文的 M1-M6 是缺陷编号，M8 是重构模块编号，两者不是同一套编号。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `HomePage` 是底部 Tab 内嵌页，**不在** `custom_router_map.json`；`MainPage.ets:13` 直接 `import { HomePage } from 'home'`，页面路径在 M15 前冻结 |
| 测试引用（冻结） | `features/home/src/test/HomeViewModel.test.ets` 直接导入 `viewmodel/HomeViewModel.ets`、`basic` 的 `ViewState` / `getGameColorByStr`、`core` 的 `GameId`；拆分必须保留 `HomeViewModel` facade 与原导出符号 |
| 共享组件 | `common/basic/shares/UserGameSection.ets` / `UserGameSectionHeader.ets` 同时服务 Home 与 WidgetSettings；M8 不得移动 / 改名，改 `roleBuilder` 签名要两边一起改 |
| 模型 | `common/basic/model/AccountRoleModels.ets` 被 Home 与 WidgetSettings 共用；`GameDataRowVM` / `GameNoteSnapshotVM` / `GameRoleCardVM` / `MihoyoAccountVM` 的导出名冻结 |
| 通知边 | `HomeViewModel` → `notification` 的 `StaminaNotificationService.getInstance().onDailyNotesSynced()` 3 处（`:174 / :367 / :384`）；重构时保持「调用即卸载错误」的现状，不新增异常外抛 |

### 重构范围（建议）

- **M3 是拆分主体**：`HomeViewModel` 728 行 → 建议拆为
  - `HomePageVM`（约 300 行）：`loadData` / `refresh` / `forceRefresh` / `dispose` / `handleColdStartRefreshResult` / `buildCardTapRoute` / 定时器 / 状态机；
  - `DailyNoteSyncVM`（约 120 行）：`syncDailyNote` / `syncIfNeeded` / `syncAllDailyNotes` / `shouldSyncDailyNote` / `getDailyNoteLastSyncTime` + 过期/验证分支；
  - `GameToolCardDataBuilder`（约 310 行）：`fetchFromLocal` / `buildRoleCards` / `loadDailyNoteSnapshot` + `getGameColor` / `getGameLogo` / `syncDescKey` / `getPrimaryColor`。
  - `HomeViewModel.ets` 只保留 facade + re-export，避免测试与 HomePage import 断裂。
- **M1 / M2 是行为修复**：各自单独提交，不与拆分混合；M1 需要冒烟「手动刷新失败 → 错误提示；后台同步失败 → 静默」；M2 需要冒烟「树脂已满时派遣/委托变化能刷新」。
- **M4 是模型清理**：删除 20 个无读取字段或改 `extraRows`，属契约变更，M8 后单独提交。
- **M5 是清理项**：4 处空 catch + 6 处空 `.catch` 补日志或加 `scan-ignore`，可随 M8 一并提交。
- **M6 暂不强制**：三层 ForEach 在当前数据规模下可接受；若 M8 拆分后要引入 `LazyForEach`，单独评估 `IDataSource` 改造成本。
- **L4 / L5 顺手清理**：删除 `HomeViewState` / `showNextCookieExpiredDialog`、修正 `AccountRoleModels` 文件头、删除 `widgetbase` 依赖并同步 `project-structure.md`。
- **不要拆 `UserGameSection`**：它已经是 `roleBuilder` 插槽的通用容器，Home / WidgetSettings 共用；拆回两套会重新引入重复。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. DevEco Local Test：`features/home/src/test/HomeViewModel.test.ets`（105 行、14 条）通过；注意它**不覆盖**同步错误语义、`syncDescKey`、`getPrimaryColor`、`buildCardTapRoute`、`loadDailyNoteSnapshot`，不能作为 M1/M2 的回归保护。
3. 冒烟：首页三游戏卡片、刷新/冷却确认框、错误 toast、骨架屏进入/离开、窄屏/宽屏、Widget 配置页复用 `UserGameSection`、读屏卡片文案（L2）。
4. 通知 / Widget：关闭通知后首页同步仍推送 Widget（服务层行为，见 notification 文档 §2.3）；手动刷新与自动刷新各触发一次 `onDailyNotesSynced`。

### 已知问题归属

- Medium 6 项：M1 / M2 行为修复；M3 拆分主体；M4 模型清理；M5 清理项；M6 评估项。
- Low 5 项：L1 / L2 / L3 / L4 / L5 记录，L4 / L5 可随 M8 顺手处理。
- 覆盖情况：Home 有 14 条单测，但只覆盖初始态、防重入、`dispose` 与颜色；`syncDailyNote` / `syncIfNeeded` / `loadDailyNoteSnapshot` / `syncDescKey` / `getPrimaryColor` / `buildCardTapRoute` 无测试。

---

## 6. 附录

### 附录 A：HomePage 回调与 @Monitor

| 回调名 | 类型 | 触发时机 | 用途 |
| --- | --- | --- | --- |
| `onReady` | `(doRefresh: () => void) => void` | `aboutToAppear` 中调用（`:30`） | 把 `vm.refresh` 交给 Main，存入 `homeDoRefresh`（`MainPage.ets:68`），供标题栏刷新按钮调用（`:339`） |
| `onMenuStateChange` | `(shouldShowRefresh: boolean, isRefreshing: boolean) => void` | `@Monitor('vm.viewState')` / `@Monitor('vm.isRefreshing')` 变化时（`:43-51`） | 上报菜单刷新按钮可见性与加载状态 |

| 监听字段 | 回调方法 | 行为 |
| --- | --- | --- |
| `signal.version` | `onAccountDataChanged()` | 账号变更 → `vm.loadData()`（L1） |
| `vm.viewState` | `onViewStateChanged()` | 状态切换 → 更新菜单按钮 |
| `vm.isRefreshing` | `onIsRefreshingChanged()` | 刷新中 → 更新菜单按钮 |
| `vm.networkErrorMsg` | `onNetworkErrorChanged()` | 网络错误 → 清空字段后 `showFeedback` 错误 toast（有界双触发） |
| `vm.isRefreshCoolingDown` | `onRefreshCoolingDown()` | 30 分钟冷却内再次刷新 → 弹确认框（`DialogDedup` 防重），选「同步」则 `vm.forceRefresh()` |
| `syncRetry.version` | `onSyncRetry()` | 人机验证通过 → `vm.forceRefresh()` |
| `vm.refreshResult` | `onRefreshResultChanged()` | 刷新结果 → 清空字段后 `showFeedback` 成功/失败 toast |

### 附录 B：GameToolCardHeader 通用结构

`GameToolCardHeader` **不使用 gameId 分支逻辑**，而是完全通用化：

```
build()（:28-74）
├── Image(card.logoResource)        ← logo 由 ViewModel 在 buildRoleCards 中预设
├── Column
│   ├── Text(getGameName(card.gameId))   ← 游戏名映射（basic 的 GameIdUtil）
│   └── Row: Text(card.server) + Text(card.nickname)
└── Text(syncDescResource(card.lastSyncDesc))  ← 'sync_just_now' / 'sync_minutes_ago:n' 等 key
```

游戏差异由上游层处理：
- **Logo**：`HomeViewModel.buildRoleCards()` 通过 `getGameLogo(gameId)` 预设（`HomeViewModel.ets:457`）。
- **游戏名**：`getGameName(card.gameId)`（`GameToolCardHeader.ets:38`）。
- **体力标签 / 数据行**：由 `GameStaminaBlock` + `GameDataRow` 渲染（非 Header 职责）。

### 附录 C：组件依赖关系矩阵

| 源组件 | 依赖的本模块组件 | 依赖的共享组件 | 依赖的外部模块 |
| --- | --- | --- | --- |
| `HomePage` | `HomeSkeletonView`, `GameToolCard` | `UserGameSection`, `PlaceholderView` | `basic`（Theme / ViewState / AppRoutes / signals / feedback）, `core`, `@kit.BasicServicesKit` |
| `HomeSkeletonView` | `AccountSkeletonCard` | — | `basic`（Theme） |
| `AccountSkeletonCard` | `SkeletonBlock` | — | `basic`（Theme） |
| `SkeletonBlock` | — | — | `basic`（Theme） |
| `GameToolCard` | `GameToolCardHeader`, `GameToolCardContent` | — | `basic`（Theme / GameRoleCardVM）, `core`（GameId） |
| `GameToolCardContent` | `GameStaminaBlock`, `GameDataRow` | — | `basic`（Theme / AccountRoleModels） |
| `GameToolCardHeader` | — | — | `basic`（Theme / GameRoleCardVM / getGameName）, `core`（GameId） |
| `GameStaminaBlock` | — | — | `basic`（Theme / TimeFormatUtil） |
| `GameDataRow` | — | — | `basic`（Theme） |
| `UserGameSection` | — | `UserGameSectionHeader` | `basic`（Theme / AccountRoleModels） |
| `UserGameSectionHeader` | — | — | `basic`（Theme / AccountRoleModels / ThemeFonts） |

### 附录 D：复核命令

```bash
# 行数（应为 185 / 728 / 485 / 76 / 58 / 192 / 105）
wc -l features/home/src/main/ets/pages/HomePage.ets \
      features/home/src/main/ets/viewmodel/HomeViewModel.ets \
      features/home/src/main/ets/views/*.ets \
      common/basic/src/main/ets/shares/UserGameSection*.ets \
      common/basic/src/main/ets/model/AccountRoleModels.ets \
      features/home/src/test/HomeViewModel.test.ets

# 空 catch（M5，应为 4 处：160 / 167 / 263 / 447）
grep -nE "catch\s*\([^)]*\)\s*\{\s*\}" features/home/src/main/ets/viewmodel/HomeViewModel.ets

# 空 .catch（M5，应为 6 处：168 / 174 / 181 / 264 / 367 / 384）
grep -nE "\.catch\(\(_: Error \| object\) => \{\}\)" features/home/src/main/ets/viewmodel/HomeViewModel.ets

# isAutoSync 赋值（M1，应只有 :70 / :197 / :222 三处，且无复位）
grep -n "isAutoSync" features/home/src/main/ets/viewmodel/HomeViewModel.ets

# 三层 ForEach（M6）
grep -n "ForEach" features/home/src/main/ets/pages/HomePage.ets \
  common/basic/src/main/ets/shares/UserGameSection.ets \
  features/home/src/main/ets/views/GameToolCardContent.ets

# 20 个专属字段的读取方（M4，应只在 HomeViewModel 写入、无读取）
grep -rn "\.expeditionCurrent\|\.homeCoinCurrent\|\.dailyTaskFinished\|\.reserveStamina\|\.trainScoreCurrent\|\.weeklyCocoonCnt\|\.rogueScoreCurrent\|\.tournScoreCurrent\|\.vitalityCurrent\|\.scratchCardSign\|\.videoStoreState" \
  --include="*.ets" features/home entry/src/test common/basic/src/test

# UserGameSection 双模式是否已消失（应只剩 account / roleBuilder）
grep -n "mode\|onCardTap\|isSlotSelected\|onSlotToggle\|roleBuilder" \
  common/basic/src/main/ets/shares/UserGameSection.ets

# widgetbase 是否仍被使用（L5，应无输出）
grep -rn "from 'widgetbase'" features/home

# 测试用例数（应为 14）
grep -c "it(" features/home/src/test/HomeViewModel.test.ets
```

### 附录 E：校验记录

| 校验轮次 | 范围 | 结论 |
| --- | --- | --- |
| 第 1 轮（2026-10-24 行数 + 结构） | Home 185 / VM 754 / Models 192 / test 111、home 10 组件行数、L25-33 装饰器、@Monitor 7 处、import 15 项 | ✅ 当时全部精确匹配 |
| 第 2 轮（2026-10-24 关键代码段） | UserGameSection 装饰器行号、无 @Builder、buildRoleCards L461、测试 L4 错误 import、build() 结构树修正 | ✅ 修正 3 处（Stack 导航区不存在 / SkeletonView 非 ForEach / SkeletonBlock ×4） |
| 第 3 轮（2026-10-24 全面复核） | GameNoteSnapshotVM 字段膨胀（L61-112）、R2 SkeletonBlock 无 stop()、M4 膨胀声明、附录 C 依赖矩阵 | ✅ 修正 4 处 |
| 第 4 轮（2026-10-26 复核） | 补充 §8 合规检查（13 条 checklist）、M3 首页→widget 跨层依赖（`UserGameSection.ets:10/13`）、`@Monitor` 内清空触发字段的有界双触发 | ✅ 新增 1 条 Medium，评级仍为 B（0 Critical + High 2 ≤ 3） |
| 第 5 轮（2026-10-27 逐条事实复核） | 全部 `file:line` 重开源码核对；VM 职责表逐方法核对；ForEach key、`isAutoSync`、`AccountSignal` 发送方 grep；`GameNoteSnapshotVM` 专属字段读取方 grep | ✅ 修正锚点 7 处；纠正 onReady 语义、下拉刷新（实为 Main 标题栏按钮）、状态机无 ERROR、R3/R4/R5/R8 描述、ThemeManager 为 `@ObservedV2`、`@Preview` 仅 5/10、M3 中「§2.4 已冻结 WidgetSlotRef」不成立；新增 M5（`isAutoSync` 不复位）、M6（ForEach key 覆盖不全）；撤回原 L1/L2，以 `loadData` 重入与 a11y gameId 替换。计数 2H/4M/2L → 2H/6M/2L，债务 16 → 20 |
| 第 6 轮（2026-10-27） | 对第 5 轮改动逐条回代码复核（M5 `isAutoSync` 三处赋值、M6 ForEach key、L1 `AccountSignal` 发送方、M4 20 字段无读取方、Main 锚点均成立）；落实跨文档定级口径 | 原 R1（VM 754 行）High → M7；原 R2（SkeletonBlock 无限动画）High → L3（需真机确认）；M3 补 `WidgetSettingsSlotStep.ets:12` 反向 import；计数 2H/6M/2L → 0H/7M/3L，债务 20 → 17，密度 10.8 → 9.2，评级仍为 B |
| 第 7 轮（2026-10-29 结构迁移后复核） | 按 `docs/project-structure.md` 重核路径与行号：`entry/src/main/ets/pages/HomePage.ets` → `features/home/src/main/ets/pages/HomePage.ets`；`struct Home` → `HomePage`；VM 754 → 728；`HomeModels.ets` → `common/basic/.../AccountRoleModels.ets`；`UserGameSection` 119 → 76 行并迁入 `common/basic/shares/`，API 从 `mode` + 4 回调 → `account` + `roleBuilder`；home 组件 10 → 8（`UserGameSection` / `Header` 移出）；test 111 → 105、14 条且 import 已修复；`refreshCoolingDown` → `isRefreshCoolingDown`；`gameIdToName` → `getGameName`；MainPage 锚点 `:345-352` → `:339`、`:420-422` → `:405-418` | 撤回原 M1（双模式）与原 M3（home ↔ widget 双向依赖）；保留 M2/M4/M5/M6/M7 并重编号为 M6/M4/M1/M2/M3；新增 M5（4 处空 catch + 6 处空 `.catch`）、L4（迁移残留）、L5（未使用 `widgetbase` 依赖）；修正 TEST-001 为「可编译但覆盖不足」。计数 7M/3L → **6M/5L**，评级 B 不变，债务 17 → 17，密度 9.2 → 9.2 |
| 第 8 轮（2026-10-31 M8 命名核查） | 对 `features/home/src/main/ets/` 共 10 文件逐标识符核对：Page×1 / ViewModel×1 / Views×8；类名 PascalCase ✅、方法 camelCase ✅、变量 camelCase ✅、无前缀下划线违规；import 路径均正确指向 `basic` / `core`；编译验证 `bash run.sh uat` | 🔶 命名零违规；仅初步核查，未做真重构 |
| 第 9 轮（2026-11-01 M8 真重构） | `HomeViewModel` 728L 拆为 4 文件：facade 303L + `HomeDataLoader` 315L + `HomeSyncCoordinator` 137L + `HomeCardPresenter` 65L；保留 `HomeViewModel` 类名 / 导出符号 / 静态方法（测试契约）；命名修正 `blockW/H/R` → `blockWidth/Height/Radius`、`vhsValue/Color` → `videoStoreValue/Color`、`zzzisFull` → `isFull`、`srRows` → `starRailRows`、`expCur/expMax` → `expeditionCurrent/expeditionMax`、`coinCur/coinMax` → `homeCoinCurrent/homeCoinMax`、`cardSignDone` → `isCardSignDone`、`syncDescResource(key)` → `syncKey`；删除废弃空方法 `showNextCookieExpiredDialog`；编译验证 `bash run.sh uat` → BUILD SUCCESSFUL in 18s 80ms | ✅ **M8 真重构完成**：最大文件 315L（<500），同步/加载/错误提示/冷却/定时器逻辑逐方法对照保持等价；测试路径 `viewmodel/HomeViewModel.ets` 与 `HomeViewModel.getGameColor` 导出不变 |

【已核对代码一致性】
