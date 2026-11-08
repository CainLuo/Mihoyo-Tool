# 通知服务层分析（M5 · 服务层）

> **审查对象**：`features/notification/src/main/ets/model/` —— 6 个文件 / 1,041 行
> （`StaminaNotificationService` 490 · `NotificationSettingsStore` 115 · `NotificationModels` 181 · `NotificationStateStore` 102 · `StaminaThresholdCalculator` 70 · `StaminaNoteReader` 83）
> **审查日期**：2026-10-24（2026-10-29 结构迁移后复核，见 §10 第 5 轮）
> **审查者**：AI 助手（`skills/harmonyos-review` checklist + `skills/arkts-rules` 规则）
> **代码版本**：`e00e579`（结构迁移后）。文中 `:行号` 未注明文件时指 `StaminaNotificationService.ets`；其他文件按 `features/notification/src/main/ets/` 下的路径给出
> **HarmonyOS targetSDK**：API 22（`6.0.2(22)`）
> **口径**：skills `harmonyos-review` 官方 A-F 评级
> **定位**：页面层已有 [`notification-settings-module-analysis.md`](./notification-settings-module-analysis.md)（`NotificationSettingsPage.ets` + ViewModel + 14 个组件）。本文档补的是它背后**从未被单独分析的服务层**：代理提醒调度、两套 preferences、阈值计算。

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 8 |
| Low | 4 |

**整体评级：B**

> 服务层的设计是合理的：用 `reminderAgentManager` 注册**系统级代理提醒**（App 被杀也能弹），纯函数 `StaminaThresholdCalculator` 单独可测，设置与状态分两个 preferences 文件互不污染，并且有 49 条单测（`StaminaNotificationService.test.ets` 26 + `StaminaThresholdCalculator.test.ets` 23）。**注意**：前者并未 import 服务本体，而是复制了一份 `hashNotificationId` 逻辑来测（见 §7），真实覆盖集中在阈值计算与模型常量。
>
> 主要问题在"调度节流"和"静默跳过"：每次便签同步都会**先取消再重建**提醒（本该生效的 `shouldReschedule` 判断在生产代码里被注释掉了），已达阈值的角色每次同步都会被**重发一次即时通知**（状态表读不回 `reminderId = -1` 的条目），延迟又按缓存快照计算、未扣除已流逝时间，提醒会被推迟；30 条上限命中时只在日志里留一行，设置页只能看到槽位用量，看不到是哪些角色被跳过。
>
> 2026-10-29 复核撤回原 M3：服务层已改为 `await WidgetSyncHook.onDailyNotesSynced(this.context)`（`:97-103`），原先"循环内 fire-and-forget + `this.context!`"的代码已迁到 widget 侧；同时新增 M9（3 处空 catch）与 L3 / L4（错误处理、通知撤回）。

---

## 1. 文件清单

| 文件 | 行数 | 职责 |
| --- | --- | --- |
| `model/service/StaminaNotificationService.ets` | 490 | 单例服务：权限 → 读设置 → 读便签 → 算延迟 → 发布/取消代理提醒；STYLE_A 独立通知 / STYLE_B 合并通知；顺带触发 widget 推送 |
| `model/service/StaminaNoteReader.ets` | 83 | 读取并解析三游戏 daily_note，输出 `StaminaSnapshot`（recoveryTime / maxStamina / currentStamina） |
| `model/service/NotificationSettingsStore.ets` | 115 | `notification_settings` preferences：全局 `enabled` / `style` + 按 `game_{accountId}_{gameId}` 的阈值 |
| `model/service/NotificationStateStore.ets` | 102 | `notification_state` preferences：每个 `accountId_roleUid_gameId` 的 `reminderId` / `Recovery_Time` 快照 / 阈值 / 调度时间 |
| `model/NotificationModels.ets` | 181 | `NotificationStyle`、`GameNotificationConfig`、`NotificationSettings`、`GameStaminaConstants`（含 `REMINDER_LIMIT = 30` / `getSecondsPerUnit` / `getFallbackMax`）、`GameStaminaResources` |
| `model/service/StaminaThresholdCalculator.ets` | 70 | 纯函数：`calcDelaySeconds` / `clampThreshold` / `shouldReschedule` / `parseGenshinRecoveryTime` |

---

## 2. 架构与数据流

### 2.1 调度链路

```
HomeViewModel（3 处：:174 / :367 / :384）
NotificationSettingsViewModel（2 处：:83 / :139）
  → StaminaNotificationService.getInstance().onDailyNotesSynced()
      ├─ [无条件] await WidgetSyncHook.onDailyNotesSynced(this.context)
      ├─ 读全局设置 enabled && style；无权限则 return
      ├─ 遍历 账号 × 角色
      │    └─ resolveSchedule()：读 daily_note → 读游戏设置 → clamp → 取消旧提醒 → 算延迟
      │         ├─ STYLE_A：dispatchImmediateOrTimer() → 立即通知或 publishTimerReminder()
      │         └─ STYLE_B：delay ≤ 0 收进列表；否则 publishTimerReminder()
      └─ STYLE_B：publishMergedNotification() 一次性弹合并通知
```

### 2.2 存储布局

| 文件 | key 形态 | 内容 |
| --- | --- | --- |
| `notification_settings` | `enabled` / `style` / `game_{accountId}_{gameId}_enabled` / `game_{accountId}_{gameId}_threshold` | 全局开关、通知样式、每账号每游戏开关与阈值 |
| `notification_state` | `{accountId}_{roleUid}_{gameId}` + 后缀 `_rid` / `_rt` / `_th` / `_at` | 系统 reminderId、体力恢复时间快照、阈值、调度时间 |

### 2.3 与 widget 的解耦

服务层**不再直接 import** widget 的 `WidgetDataBuilder` / `WidgetFormIdStore` / `WidgetDataStoreBuilder`，改为依赖 `basic` 的 `WidgetSyncHook`（`StaminaNotificationService.ets:26`）：

- `init()` 里 `await WidgetSyncHook.init(context)`（`:68`）；
- `onDailyNotesSynced()` 里 `await WidgetSyncHook.onDailyNotesSynced(this.context)`（`:103-112`），异常由服务层 catch 记录；
- 真正的 widget 实现在 `features/widget/.../WidgetSyncHandlerImpl.ets`，由 `EntryAbility.onCreate` 注册（`EntryAbility.ets:16`），且该推送**不受通知设置控制**——即使通知全关，每次 `onDailyNotesSynced()` 仍会刷新并推送 widget。

这是结构迁移中完成的依赖倒置，原先 Refactor_Spec §4 M5 记的"服务向 widget 扇出 3 条边"已收敛为 1 条 `basic` 边。

---

## 3. ArkTS 合规性检查

| 规则 ID | 检查项 | 状态 | 说明 |
| --- | --- | --- | --- |
| `ARKTS-001` / `ARKTS-012` | 无 `any` / `console.*`；另 grep `var` | ✅ 0 处 | 全目录 grep 无命中 |
| `ARKTS-010` | 类字段在声明或 constructor 中初始化 | ✅ | 单例 `_instance` + 静态 `getInstance()`（`:47-52`），`context` 声明即初始化 |
| `KIT-005` / `ARKTS-011` | Kit Promise 都有 catch，`BusinessError` 判 code | ⚠️ | 3 处空 catch（M9）；`checkPermission` 失败静默返回 `false`（`:77-79`，L3）；只有 `scheduleReminder` / `scheduleMergedReminder` 记录 `BusinessError.code`（`:385-389` / `:552-556`），其余只记 `message` |
| `ARKTS-016` | 空 catch 块不以静默吞错收场 | ❌ | `:189` / `:235` / `:430` 三处 `catch (_) {}`（M9） |
| — | 非空断言 | ⚠️ 1 处 | `this.context!`（`requestPermission` `:65`）；`init()` 之前调用会静默失败（L1） |
| — | 硬编码 bundle / ability | ✅ 已修 | bundle 改为 `this.bundleName`（读 `context.abilityInfo.bundleName`，`a785ca6`）；`ABILITY_NAME = 'EntryAbility'` 仍为常量（各 product 一致） |
| `KIT-006` | Background Tasks Kit 不滥用 | ✅ | 仅用 `reminderAgentManager` 注册代理提醒，`PUBLISH_AGENT_REMINDER` 已在 `entry/src/main/module.json5:17-23` 声明 |
| `KIT-009` | Notification Kit：通知 ID 唯一、渠道注册一次 | ⚠️ | 单角色 ID 由 `hashNotificationId` 生成（`:663-669`），合并通知用固定 ID（`:284`）；关闭开关不撤回已发布通知（L4） |
| `SEC-002` | 敏感数据不入日志 | ✅ | 日志只含 `accountId` / `roleId` / `gameId` / 错误码，不写 cookie / token |
| `PERF-001` | 无 `forEach + await` 反模式 | ✅ | 全部用 `for` 循环顺序 await（`:120-151`、`:178-192`、`:278-281`、`:319-327`） |
| — | 纯函数隔离 | ✅ | `StaminaThresholdCalculator` 不依赖设备 API，可在宿主机跑测试 |

---

## 4. 复用分析

- **STYLE_A / STYLE_B 共用同一套阈值与延迟计算**（`StaminaThresholdCalculator`），只有"聚合方式"不同——拆分正确。
- **`GameStaminaConstants` 又定义了一份上限**（`GENSHIN_MAX_FALLBACK 200` / `STARRAIL 300` / `ZZZ 240`，`NotificationModels.ets:87-89`），core 的 Parser 也有 max 值，属"双源"，见 L2。
- **被测试直接引用的 notification 文件有 2 个**：`NotificationModels`（`NotificationStyle` / `GameStaminaConstants` 等）与 `StaminaThresholdCalculator`；`StaminaNotificationService` 本体**未被任何测试 import**（其同名测试用本地复制的 `hashNotificationId` 逻辑，见 §7），`NotificationStateStore` / `NotificationSettingsStore` 也无测试。

---

## 5. 安全审查

| 项 | 结论 |
| --- | --- |
| 权限 | ✅ 使用 `PUBLISH_AGENT_REMINDER`（`entry/src/main/module.json5:17-23` 已声明，`usedScene.abilities = EntryAbility`）与 `requestEnableNotification` 运行时申请 |
| 凭据 | ✅ 服务层不写 cookie / token；日志只打印 `accountId` / `roleId` / `gameId` / 错误码 |
| 存储 | ✅ 两个 preferences 只存开关、阈值、reminderId、体力快照 |
| 越权风险 | ⚠️ `cancelAll()` 调 `reminderAgentManager.cancelAllReminders()`（`:166`）——会清掉**本应用**所有代理提醒（目前只有体力提醒，可接受）；若将来新增其他提醒类型，这个 API 会误伤 |

---

## 6. 风险清单

> **行号基线**：M1–M9 / L1–L4 的 `:行号` 仍指 2026-10-24 的 670 行版本（历史审查记录）。M5 真重构后的对应位置见下表；风险结论本身未变，行为修复仍按 §7.2 单独提交。
>
> | 原位置（670L） | 现位置（490L） |
> | --- | --- |
> | `onDailyNotesSynced` `:94-161` | `:103-185` |
> | STYLE_A `checkAndSchedule` `:396-452` | `resolveSchedule` `:204-251` + `dispatchImmediateOrTimer` `:264-291` |
> | STYLE_B `buildMergedEntry` `:204-259` | `resolveSchedule` `:204-251` |
> | `scheduleReminder` `:506-558` / `scheduleMergedReminder` `:341-391` | `publishTimerReminder` `:377-425` |
> | `publishImmediateNotification` `:454-504` | `:339-375` |
> | `publishMergedNotification` `:267-333` | `:293-337` |
> | `loadStaminaRecovery` `:560-611` | `StaminaNoteReader.read` |
> | `getSecondsPerUnit` `:613-621` | `GameStaminaConstants.getSecondsPerUnit` |
> | `getStaminaName` / `getGameName` `:623-661` | `:457-478` |
> | 3 处空 catch `:189` / `:235` / `:430` | `cancelExistingReminder` `:253-262`（已补日志） |
> | `BUNDLE_NAME` / `ABILITY_NAME` `:20-21` | `:29-30` |
> | 状态写回 `:321-326` / `:379-384` / `:493-498` | `saveState` `:441-455` |

### Medium

| # | 规则 ID | 问题 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| M1 | — | 每次同步都**取消并重建**已有提醒，`shouldReschedule` 跳过的逻辑被注释掉 | STYLE_A：`:423-426`（`shouldReschedule` 判断整段被 `//` 注释）、`:427-432`（直接 `cancelReminder` + `removeEntry`）；STYLE_B：`:229-237`（同样是先取消再重建） | 便签每次刷新（Home 进前台 / 手动刷新 / 设置页改动）都会让所有提醒重建一次：系统通知列表抖动，"再过 2 分钟回满"的提醒可能因重建而推迟。`StaminaThresholdCalculator.shouldReschedule` 专为此写了纯函数且有 3 条单测（`StaminaThresholdCalculator.test.ets:124-139`），却没被任何生产代码调用。建议恢复注入这条判断（单独提交，行为变更） |
| M2 | — | 30 条上限命中后**静默跳过** | `:343-347`（STYLE_B）与 `:515-519`（STYLE_A），均只打一行 `reminder limit reached (...), skip` 后 `return` | 用户有 3 账号 × 多角色时很容易超过 30 条；超出的角色收不到提醒，游戏开关仍显示"已开启"。设置页已有槽位用量（`NotificationSettingsViewModel.ets:27-28` 的 `reminderUsed / reminderLimit`，`:31-37` 按比例变色）与开启前的上限弹窗（`:112-118`），但后台同步中被跳过的**是哪些角色**无从得知。建议服务层返回被跳过的 key 列表供设置页标注，或在超限时降级为 STYLE_B 合并 |
| M4 | — | `onDailyNotesSynced()` 被 Home 触发 3 次，且服务无并发保护 | `features/home/src/main/ets/viewmodel/HomeViewModel.ets:174 / :367 / :384`（均为 `catch((_: Error \| object) => {})` 静默）；服务 `onDailyNotesSynced`（`:94-161`）无 in-flight 标记 | 首页冷启动、下拉刷新、强制刷新、自动刷新定时器都会触发一轮 O(账号×角色) 的遍历 + 全量提醒重建（即 M1）。冷启动时 `HomeViewModel.ets:162` 的 `syncIfNeeded()` 未 await，`:174` 的冷启动推送与 `syncIfNeeded` 末尾的 `:367` 两次调用可能重叠：两轮各自"读旧条目 → 取消 → 发布"，状态表只留后写的 `reminderId`，先发布的那条成为孤儿提醒（重复弹出且占用 30 条槽位）。建议服务层加 in-flight 合并 + "最小间隔"（如 60s） |
| M5 | — | `wantAgent` 目标写死 bundle 与 ability 名 | `:20-21`（`BUNDLE_NAME` / `ABILITY_NAME`），用于 `:289 / :351 / :468 / :523` | uat / mock product 的 bundle 分别是 `com.cainluo.miyoyo.tools.uat` / `.mock`（`build-profile.json5:64 / 83`），这两个包点击通知会去拉起正式包或失败；建议从 `context.abilityInfo` 读取。✅ 已修（`a785ca6`）：新增 `private get bundleName()` 读 `this.context.abilityInfo.bundleName`，`publishTimerReminder` 与 `createNotificationWantAgentInfo` 改用该 getter；`context` 为 null 时返回空串（该路径本就需要 context，会在发布时抛错并被 catch 记录） |
| M6 | — | 状态表与系统提醒**没有对账** | `NotificationStateStore.ets:35-56`（只按 key 读，`reminderId < 0` 视为不存在）；全文件无"校验系统中是否仍存在该 reminderId"的逻辑 | 系统清理、用户手动关闭通知、卸载重装后，`notification_state` 里会留下失效 reminderId；`getReminderCount()`（`:83-92`）只用 `getValidReminders().length` 取总数，不逐条核对。建议启动时用 `getValidReminders()` 与状态表做一次差集清理 |
| M7 | — | 已达阈值的角色**每次同步都重发即时通知** | 即时通知写入的状态是 `reminderId = -1`（`:493-498`、`:321-326`），而 `NotificationStateStore.getEntry()` 对 `reminderId < 0` 直接返回 `null`（`NotificationStateStore.ets:42-44`）；STYLE_A `:447-448`、STYLE_B `:136-138 → :154-156` 因此每轮都会重新 `publish` | "已经通知过"的事实写进了状态表却永远读不回来，只要体力仍高于阈值，每次首页同步（M4 的各触发点）都会以同一 ID 重新发布并再次提醒。注意：仅恢复 M1 的 `shouldReschedule` 也拦不住这条（`getEntry` 先返回了 `null`）。建议 `getEntry` 区分"无条目"与"已即时通知"，与 M1 一并修（行为变更，单独提交） |
| M8 | — | 延迟按**缓存快照的相对秒数**计算，未扣除已流逝时间 | `:574 / :587 / :600` 直接取 DB `rawJson` 里的"距满值剩余秒数"，`:239-241`、`:434-436` 用它算延迟；全文件未读取 row 上的 `updateTime`（`core/src/main/ets/GenshinKit/db/GenshinDao.ets:227` 已映射，`GenshinRows.ets:92` 单位秒；星铁 / 绝区零同构） | `onDailyNotesSynced` 经常在**没有重新拉取**的数据上运行：冷启动 `HomeViewModel.ets:174` 直接用库存数据，`syncIfNeeded` 对 30 分钟内同步过的角色跳过拉取（`HomeViewModel.ets:355-362`）。此时算出的延迟比真实值多出"距上次拉取的时长"，提醒按这个偏差**推迟弹出**；叠加 M1 的取消重建，每轮都会把原本正确的提醒替换成更晚的那条；即时通知正文的体力值也是旧值。建议 `delay -= now - row.updateTime`（单独提交，行为变更） |
| M9 | `ARKTS-016` | 3 处 `catch (_) {}` 静默吞掉 `cancelReminder` 失败 | `:189`（`cancelByAccountGame`）、`:235`（`buildMergedEntry`）、`:430`（`checkAndSchedule`） | 取消失败时状态条目仍被 `removeEntry` 删掉，系统中可能残留一条无人管理的提醒；由于没有日志，排查时只能看到"提醒没消失"的结果。`scan-arkts.sh` 对该规则默认 Medium（文件含 `await` 时触发），本文件含大量 `await`，按工具口径计 Medium。建议补一行 `Logger.warn`（含 `BusinessError.code`），或在确认是 cleanup 容错处加 `// scan-ignore: ARKTS-016` 并注明原因 |

### Low

| # | 规则 ID | 问题 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| L1 | — | `requestPermission()` 依赖 `init()` 先调用 | `:63-72`（`:65` `this.context!`） | `init` 在 `EntryAbility` 的 core 初始化回调里才 fire-and-forget 执行（`entry/src/main/ets/entryability/EntryAbility.ets:40`）；若设置页在极端时序下先调 `requestPermission`，`requestEnableNotification(null)` 的异常被 `:67-71` 捕获后返回 `false`，用户看到的是"权限被拒"提示而非真实原因 |
| L2 | — | 体力上限双源 | `NotificationModels.ets:87-89`（fallback 200/300/240）与 core Parser 的 max 值 | 仅当接口缺字段时用 fallback，风险低；但改上限要改两处 |
| L3 | `KIT-005` / `ARKTS-011` | 错误处理信息不足：`checkPermission` 静默返回 `false`，资源读取失败静默走 fallback，其余 catch 只记 `message` 不判 `code` | `:77-79`；`:638-640` / `:658-660`；`:67-71`、`:100-103`、`:157-160`、`:193-196`、`:329-332`、`:500-503`、`:606-610`；`NotificationSettingsStore.ets:35-49` 在 pref 未初始化时返回默认 `isEnabled = false` | checklist 对 `KIT-005` 默认 High，但实际影响是"少日志 / 权限状态误判 / 设置读取失败时静默不通知"，不改变已成功路径的业务结果，按实际影响记 Low。建议统一收窄为 `BusinessError` 并记录 `code`；`loadGlobal` 失败时至少打一条 `error` |
| L4 | `KIT-009` | 关闭通知 / 关闭单游戏后，**已发布的即时通知不会撤回** | `cancelAll()` `:163-174` 只调 `cancelAllReminders()` + 清状态；`cancelByAccountGame()` `:176-197` 只处理 `reminderId >= 0` 的条目 | `notificationManager.publish` 发出的即时通知（STYLE_A 单角色、STYLE_B 合并）不在 `reminderAgentManager` 的管理范围内，全工程也没有 `notificationManager.cancel` / `cancelAll` 调用。用户关掉总开关后，通知栏里已弹出的提醒仍会留着，直到手动滑掉；与 §7 验收里"关闭通知 → 提醒全部消失"的预期不一致。建议总开关关闭时补 `notificationManager.cancelAll()`；单游戏关闭时按 `hashNotificationId(key)` 撤回对应单角色通知，合并通知按剩余角色重新发布（或一并撤回后由下一轮同步重建） |

---

### 复核撤回 / 改判（2026-10-29）

| 原条目 | 处理 | 依据 |
| --- | --- | --- |
| M3（widget 推送循环内 fire-and-forget + `this.context!`） | **撤回**（不计入本文） | 服务层已改为 `await WidgetSyncHook.onDailyNotesSynced(this.context)`（`:97-103`），不再在循环内直接调 `WidgetFormIdStore.init`，也不再使用 `this.context!`。残余的"循环内 fire-and-forget + `context!`"在 `features/widget/src/main/ets/model/service/WidgetSyncHandlerImpl.ets:31-43`，属 M14（widget 子系统），建议在对应文档复核，避免重复计数 |
| 文件行数 691 / 总计 1,082 | 改为 670 / 1,061 | 结构迁移把 widget 推送逻辑外移到 `WidgetSyncHandlerImpl`，服务本体净减 21 行 |

---

## 7. 重构执行备注（M5 · 服务层）

> 与页面层文档 [`notification-settings-module-analysis.md`](./notification-settings-module-analysis.md) 配套使用；执行顺序按 Refactor_Spec §4（M5）。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 测试引用 | `features/notification/src/test/StaminaNotificationService.test.ets` 与 `StaminaThresholdCalculator.test.ets` 直接导入 `../main/ets/model/NotificationModels`、`../main/ets/model/service/StaminaThresholdCalculator`，**路径、类名、静态成员名冻结** |
| preferences | `notification_settings` / `notification_state` 两个文件名与 key 结构不可变（否则已装机用户丢失阈值与提醒状态） |
| 权限 | `PUBLISH_AGENT_REMINDER` 声明在 `entry/src/main/module.json5:17-23`，`usedScene` 指向 `EntryAbility` |
| 与 widget 的边 | 1 条 import 边：`basic` 的 `WidgetSyncHook`。实现 `WidgetSyncHandlerImpl` 在 `EntryAbility.onCreate:16` 注册；改接口签名要 notification / widget 两边一起改 |
| 触发入口 | `HomeViewModel` 的 3 处（`:174 / :367 / :384`）与 `NotificationSettingsViewModel` 的 2 处（`:83 / :139`），重构时保持"调用即卸载错误"的现状（不新增异常外抛） |

### 重构范围（建议）

- **M1 可随重构模块 M5 修**：把 `shouldReschedule` 真正用上，跳过未变化的提醒。这是行为变更（减少重复发布），需要单独提交 + 冒烟"提醒仍能按时弹出"。
- **M4 是稳定性修复**：服务层 in-flight 合并 + 最小间隔，不改 UI。
- **M8 是时间基准修复**：扣除 `now - updateTime` 会让提醒提前到正确时刻，属行为变更，单独提交并冒烟"30 分钟内二次进首页，提醒时间不后移"。
- **M7 与 M1 同一提交**：`getEntry` 需要能读回"已即时通知"状态，否则恢复 `shouldReschedule` 也无法去重；同样是行为变更，需冒烟"体力高于阈值时多次刷新首页只提醒一次"。
- **M2 / M6 需要产品与存储设计**：被跳过角色的展示、状态对账都涉及新增 UI 或迁移逻辑，记录不执行。
- **缺陷 M5 属构建配置**：从 `context.abilityInfo` 读取 bundle / ability，随 uat / mock 打包验证。
- **M9 是清理项**：3 处空 catch 补日志或加 `scan-ignore`，可随本模块重构一并提交。
- **不要拆 `StaminaNotificationService`**：490 行仍然偏大，但它与 reminderAgent 的调用序列紧耦合，拆分收益低于回归风险；M5 已把 daily_note 读取抽到 `StaminaNoteReader`，本轮不再拆调度类。
- **M3 已撤回**：残余 widget 推送问题在 `WidgetSyncHandlerImpl`，归 M14，不在本轮通知服务改造范围内。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. DevEco Local Test：`features/notification/src/test/StaminaNotificationService.test.ets`（26 条）+ `StaminaThresholdCalculator.test.ets`（23 条）通过；注意前者未 import 服务本体，不能作为服务行为的回归保护。
3. 冒烟：开启通知 → 调低阈值触发提醒 → 关闭通知 → 代理提醒全部消失（已发布的即时通知需手动清除，见 L4）→ 重启应用后设置保持 → 多账号多角色下观察 30 条上限行为。
4. uat / mock 包各点一次通知，确认拉起的是当前包（M5）。

### 已知问题归属

- Medium 8 项：M1 / M7（同一提交）/ M4 / M8 可随重构模块 M5 修；M2 / M6 需决策；缺陷 M5 属包名 / 构建配置；M9 为清理项。
- Low 4 项：L1 / L2 / L3 / L4 记录。
- 覆盖情况：服务层有 **49 条单测**，但 `StaminaNotificationService.test.ets` 只 import `NotificationModels`（+ `GameId`），**没有 import 服务本体**；`hashNotificationId` 的 6 条用例测的是测试文件内 `:18-24` 的本地副本，服务实现改动不会被发现。真实被测的只有 `StaminaThresholdCalculator` 纯函数（23 条，真实 import）与 `NotificationModels` 的常量 / 枚举 / 数据类（20 条，其中 3 条为合并通知数据构建）。`checkAndSchedule` / `publishMergedNotification` / 状态对账**无测试**。

### 7.1 整体观察（skills report-template 要求）

- **代码质量**：两个 preferences store 与 calculator 职责单一，命名一致；`StaminaSchedule` 统一了 STYLE_A / STYLE_B 的调度数据，daily_note 读取抽到 `StaminaNoteReader`，服务本体从 670 行降到 490 行。扣分项是写死的 bundle / ability（M5）与仍存在的 30 条上限静默跳过（M2）。
- **架构**：服务 → 两个 preferences store → 纯函数 calculator 的单向依赖清晰；widget 通过 `WidgetSyncHook` 依赖倒置，不再形成 notification ↔ widget 循环。缺口是 `onDailyNotesSynced` 没有 in-flight / 节流（M4），以及状态表与系统提醒没有对账（M6）。
- **安全**：权限声明完整，日志不含凭据；`cancelAll` 的"清空本应用全部代理提醒"是未来扩展时的误伤点（§5）。
- **性能**：每轮同步 O(账号×角色)，且 `getReminderCount()` 在每个角色调度前都调一次 `getValidReminders()`（`:343`、`:515`），角色多时是 O(N) 次系统 IPC；可改为本轮只取一次、发布后本地自增。该点暂未单列缺陷，随 M4 的节流一起优化即可。

### 7.2 复审建议

1. **先修行为正确性**：M1 + M7 一个提交，M8 一个提交；每个都带"提醒时间不后移 / 不重复提醒"的冒烟。
2. **再修稳定性**：M4 的 in-flight 合并与最小间隔，避免冷启动两条链路互相覆盖状态。
3. **产品决策项**：M2（被跳过角色可见性）与 M6（状态对账）需要设置页 / 存储迁移配合，单独排期。
4. **收尾**：M9 + L3 + L4 可合并为一个"错误处理与通知撤回"清理提交。
5. **真机回归**：30 条上限、uat / mock 通知点击、关闭总开关后通知栏清空（L4）、重启后设置保持。

---

## 8. 依赖文件索引

| 方向 | 内容 |
| --- | --- |
| → core | `StaminaNotificationService`：`CoreInitializer`、`Logger`、`GameId`；`StaminaNoteReader`：三个 `*DailyNoteParser` |
| → basic | `WidgetSyncHook`（1 条边；widget 实现在 `features/widget` 注册） |
| → 系统 Kit | `@kit.BackgroundTasksKit`（reminderAgentManager）、`@kit.NotificationKit`、`@kit.ArkData`（preferences）、`@kit.AbilityKit`（wantAgent / common）、`@kit.BasicServicesKit`（`BusinessError`） |
| ← 调用方 | `HomeViewModel.ets:155` + `HomeSyncCoordinator.ets:96 / :114`（`onDailyNotesSynced` 3 处）、`NotificationSettingsViewModel.ets:86 / :137`（`onDailyNotesSynced` 2 处；另调 `checkPermission` / `requestPermission` / `getReminderCount` / `cancelAll` / `cancelByAccountGame`，并直接使用 `NotificationSettingsStore` / `StaminaThresholdCalculator` / `StaminaNoteReader`）、`entry/src/main/ets/entryability/EntryAbility.ets:40`（`init`） |
| ← 测试 | `features/notification/src/test/StaminaNotificationService.test.ets`、`StaminaThresholdCalculator.test.ets` |

---

## 9. 复核命令

```bash
# 行数（应为 490 / 83 / 115 / 102 / 181 / 70）
wc -l features/notification/src/main/ets/model/NotificationModels.ets \
      features/notification/src/main/ets/model/service/*.ets

# 空 catch（M9，应为 0 处；取消路径已补 Logger.warn）
grep -nE "catch\s*\([^)]*\)\s*\{\s*\}" \
  features/notification/src/main/ets/model/service/StaminaNotificationService.ets

# shouldReschedule 的生产调用（应为 0 处；测试仍保留）
grep -rn "shouldReschedule" --include="*.ets" features/notification/src/main/ets

# 即时通知写回 reminderId = -1（M7，现通过 saveState(..., -1, ...)）
grep -n "saveState(.*-1" \
  features/notification/src/main/ets/model/service/StaminaNotificationService.ets

# 硬编码 bundle / ability（M5）
grep -n "BUNDLE_NAME\|ABILITY_NAME" \
  features/notification/src/main/ets/model/service/StaminaNotificationService.ets

# 触发入口（M4，应为 Home 3 + Settings 2）
grep -rn "onDailyNotesSynced" --include="*.ets" features/home features/notification

# 通知撤回（L4，应无命中）
grep -rn "notificationManager.cancel" --include="*.ets" features/notification
```

---

## 10. 校验记录

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（2026-10-24 行数 + 文件） | 5 文件 691/115/104/102/70 = 1,082；测试用例 26 + 23 | ✅ 当时全部精确匹配 |
| 第 2 轮（2026-10-24 关键行号） | M1 `444-453 / 250-258`、M2 `366`、M3 `105-121`、M4 `200/393/410`、M5 `22-23`、M6 `35-72`、L3 `87-89`；Home 3 处 + Settings 2 处；3 条 widget import | ✅ 当时通过 |
| 第 3 轮（2026-10-24 全面复核） | 设置 key 实际带 `_enabled` / `_threshold` 后缀；`StaminaNotificationService.test.ets` 未 import 服务本体、`hashNotificationId` 为测试内副本；测试直接 import 的是 `NotificationModels` + `StaminaThresholdCalculator`；widget 推送先于通知开关检查；`cancelAll` 当时在 L187 | ✅ 修正 5 处（key 形态 / 唯一被引用文件 / STYLE_B 行号 / L1 行号 / 测试覆盖描述） |
| 第 4 轮（2026-10-24 逐条事实） | `this.context!` 当时两处均在 try/catch 内（不崩）；设置页已有槽位用量与上限弹窗；`getEntry` 对 `rid < 0` 返回 null；Home 冷启动两次调用可重叠；uat / mock bundle 不同 | ✅ 新增 M7（即时通知每次同步重发）、M8（延迟未扣除已流逝时间）；撤回原 L2（`getReminderCount` + `reminderUsed` 已回读并展示）；改写 M2/M3/M4/M5/L1 与合规表；计数 6M/3L → 8M/2L |
| 第 5 轮（2026-10-29 结构迁移后复核） | 按 `docs/project-structure.md` 重核路径与行号：`entry/src/main/ets/notification/` → `features/notification/src/main/ets/model/`；服务 691 → 670 行、总计 1,082 → 1,061；`instance()` → `getInstance()`；widget 3 条 import → `basic` 的 `WidgetSyncHook` 1 条边（`EntryAbility.ets:16` 注册实现）；全部 `file:line` 逐条回代码；测试 import 与本地 `hashNotificationId` 副本核对；对照 `skills/harmonyos-review/references/checklist.md`、`skills/arkts-rules/references/spec-quick-ref.md`、`scan-arkts.sh` 重扫 | 撤回 M3（服务层已 await `WidgetSyncHook`，残余在 `WidgetSyncHandlerImpl`，归 M14）；新增 M9（3 处空 catch，`ARKTS-016` 默认 Medium）、L3（`KIT-005` / `ARKTS-011` 错误处理信息不足）、L4（关闭通知不撤回已发布通知）；补「规则 ID」列、整体观察 / 复审建议 / 复核命令 / 页头元数据。计数 8M/2L → **8M/4L**，评级 B 不变，债务 18 → 20，密度 1.7 → 1.9 |
| 第 6 轮（2026-11-02 M5 真重构） | 服务 670 → 490 行；新增 `StaminaNoteReader`（83 行）统一三游戏 daily_note 读取；`NotificationModels` 104 → 181 行（`getSecondsPerUnit` / `getFallbackMax(GameId)` / `GameStaminaResources`）；`StaminaSchedule` 统一 STYLE_A/B 调度数据；`resolveSchedule` / `publishTimerReminder` / `saveState` / `createNotificationWantAgentInfo` 去重；删除注释掉的 `shouldReschedule` 与 `_style` / `_server` 参数；3 处空 catch 收敛为 1 处并补日志；编译 `bash run.sh uat` → BUILD SUCCESSFUL in 15s 80ms | ✅ 纯重构完成；M1/M2/M4/M5/M6/M7/M8 行为修复仍未执行（单独提交） |

【已核对代码一致性】

---

## 11. M5 服务层真重构记录（2026-11-02）

### 改动

| 类型 | 文件 | 说明 |
| --- | --- | --- |
| 新增 | `model/service/StaminaNoteReader.ets`（83L） | 三游戏 `getDailyNote → Parser → 行数据兜底` 的唯一实现，输出 `StaminaSnapshot` |
| 去重 | `StaminaNotificationService.ets` | `buildMergedEntry` 与 `checkAndSchedule` 合并为 `resolveSchedule`：读快照 → 读设置 → clamp → 取消旧提醒 → 算延迟 → 拼文案数据 |
| 去重 | `StaminaNotificationService.ets` | `scheduleReminder` 与 `scheduleMergedReminder` 合并为 `publishTimerReminder`；`publishImmediateNotification` / `publishMergedNotification` 共用 `createNotificationWantAgentInfo` 与 `saveState` |
| 去重 | `StaminaNotificationService.ets` | 两处「取消旧提醒 + removeEntry」合并为 `cancelExistingReminder`；三处 `NotificationStateEntry` 写回合并为 `saveState` |
| 清理 | `StaminaNotificationService.ets` | 删除注释掉的 `shouldReschedule` 死代码、未使用的 `_style` / `_server` 参数、`StaminaRecovery` / `MergedNotificationEntry` 内部类 |
| 命名 | `StaminaNotificationService.ets` | `checkAndSchedule` → `dispatchImmediateOrTimer`；`StaminaSchedule` 统一两种样式的调度数据 |
| 去重 | `NotificationModels.ets` | 新增 `GameStaminaConstants.getSecondsPerUnit`、`GameStaminaResources`（资源 key / Resource / 英文 fallback）；`getFallbackMax` 入参由 `string` 收紧为 `GameId` |
| 清理 | `StaminaNotificationService.ets` | 3 处空 catch 收敛为 1 处并补 `Logger.warn`（M9 关闭）；索引循环改 for-of |

### 行为等价说明

- `resolveSchedule` 的步骤顺序与原 `checkAndSchedule` / `buildMergedEntry` 一致；STYLE_B 仍然先取消旧提醒再决定「立即合并」或「注册代理提醒」。
- 服务层 `maxStamina` 仍在读设置前套用 `getFallbackMax`，与原 `loadStaminaRecovery` 一致；设置页仍使用原始值（0 表示无数据）。
- 两种样式的通知标题 / 正文逐字保留：STYLE_A 即时通知用 `当前/上限，请及时消耗`，STYLE_B 代理提醒用 `已达阈值 阈值/上限`。
- `publishMergedNotification` 的固定通知 ID、多行格式、状态写回字段均未变。
- 新增的 `Logger.warn` 只影响取消失败时的日志，不改变「取消失败仍 removeEntry」的原有语义。

### 验收

| 项 | 结果 |
| --- | --- |
| 编译 | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 15s 80ms`，安装/启动成功 |
| 测试契约 | ✅ `NotificationModels.ets` / `StaminaThresholdCalculator.ets` 路径不变；`NotificationStyle` / `GameStaminaConstants` / `GameNotificationSetting` 导出不变；`getFallbackMax(GameId)` 与测试调用一致 |
| 文件规模 | ✅ Service 670 → 490L；新增 Reader 83L；Models 104 → 181L |
| 冒烟 | 🔶 待手动：开启通知 → 调低阈值 → 前台/后台各触发一次同步 → 确认提醒时间与文案 |

### 未执行（保留记录）

- M1（每次同步取消重建）、M7（即时通知重复发布）、M4（Home 3 次触发无并发保护）、M8（延迟未扣除已流逝时间）：行为变更，单独提交。
- M2（30 条上限静默跳过）、M6（状态表对账）：需产品 / 存储设计，保留。
- M5（bundle / ability 硬编码）：构建配置修复，单独提交。
- L1–L4：保留记录。
