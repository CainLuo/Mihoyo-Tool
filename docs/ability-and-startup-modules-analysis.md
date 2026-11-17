# Ability 与启动链路分析（M15 前置）

> **分析对象**：`entry/src/main/ets/entryability/EntryAbility.ets`（113 行）+ `entry/src/main/ets/entrybackupability/EntryBackupAbility.ets`（16 行）+ `entry/src/main/module.json5`（89 行）
> **分析日期**：2026-10-24
> **代码版本**：`105c8d3`
> **HarmonyOS SDK**：`6.0.2(22)`
> **口径**：skills `harmonyos-review` 官方 A-F 评级
> **定位**：补齐 M15 里"页面之外"的部分。`Main` / `Index` / `Launch` / `TestPage` 已有独立文档；`EntryFormAbility` / `WidgetSyncAbility` 已并入 [`widget-subsystem-modules-analysis.md`](./widget-subsystem-modules-analysis.md)。本文件只剩 **EntryAbility + EntryBackupAbility + module.json5** 与冷启动时序。

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 5 |
| Low | 4 |

**整体评级：A**

> EntryAbility 的逻辑很短（113 行），但它是**全局初始化的唯一入口**：颜色模式、透明色缓存、core 初始化、widget 数据仓、通知服务、窗口尺寸/避让区，全部在这里串起来。代码本身干净（无 `any`/`console`、错误都进日志，但 `Error` 被序列化成 `{}`，见 L4），问题是**没有一个失败路径是用户可见的**——`loadContent` 失败、widget / 通知初始化失败表现为"某功能静默不工作"；core 初始化失败更糟，`waitForReady()` 永不 resolve，应用停在启动页（该现象计入 [launch](./launch-module-analysis.md) H1）。另有一项数据面问题：系统备份不排除存有明文 Cookie 的数据库（M5）。

---

## 1. 文件清单

| 文件 | 行数 | 角色 |
| --- | --- | --- |
| `entryability/EntryAbility.ets` | 113 | 主 UIAbility：onCreate 初始化链 + onWindowStageCreate 窗口状态入 AppStorage + `loadContent('pages/Index')` |
| `entrybackupability/EntryBackupAbility.ets` | 16 | 备份扩展：`onBackup` / `onRestore` 仅打日志（实际备份由系统按 `backup_config.json` 执行） |
| `resources/base/profile/backup_config.json` | 2 | `{"allowToBackupRestore": true}`，无 include/exclude |
| `module.json5` | 89 | 2 个 UIAbility + 2 个 ExtensionAbility + 3 个权限 + `pages` / `routerMap` 指向 |
| `common/basic/src/main/ets/config/RuntimeConfig.ets` | 14 | `APP_ENV`（来自 `BuildProfile.APP_ENV`），被 EntryAbility 传给 core |

---

## 2. module.json5 结构（契约表）

| 类别 | 条目 | 关键字段 |
| --- | --- | --- |
| UIAbility | `EntryAbility` | `srcEntry: ./ets/entryability/EntryAbility.ets`、`exported: true`、home skill（`entity.system.home` + `action.home`） |
| UIAbility | `WidgetSyncAbility` | `srcEntry: ./ets/widgetsyncability/WidgetSyncAbility.ets`、**`exported: true`**（卡片宿主需要跨进程拉起） |
| ExtensionAbility | `EntryBackupAbility` | `type: backup`、`exported: false`、metadata → `$profile:backup_config` |
| ExtensionAbility | `EntryFormAbility` | `type: form`、metadata → `$profile:form_config`（6 张卡片） |
| 权限 | `ohos.permission.INTERNET` | 无 reason（普通权限） |
| 权限 | `ohos.permission.PUBLISH_AGENT_REMINDER` | `usedScene.abilities: [EntryAbility]` |
| 权限 | `ohos.permission.KEEP_BACKGROUND_RUNNING` | `usedScene.abilities: [WidgetSyncAbility]` |
| 入口 | `pages: $profile:main_pages` | 只注册 `pages/Index` |
| 路由 | `routerMap: $profile:custom_router_map` | 20 条（19 页面 + `MaterialCharacterSelectBuilder`） |

> 4 个 ability 的 `srcEntry` 全部属于 §2 的冻结契约。

---

## 3. 启动链路（冷启动）

```
EntryAbility.onCreate                                    (EntryAbility.ets:14-48)
  ├─ AppearanceManager.restoreOnLaunch()   → 恢复深/浅色（fire-and-forget）
  ├─ TransparentColorCache.init(context)   → 计算透明色（同步）
  └─ CoreInitializer.initCore({env, context})  → .then:
        ├─ WidgetDataStoreManager.init(context)
        ├─ WidgetDataStoreBuilder.initAndSave(context)      ← 首次装卡有数据可读
        ├─ SyncQueueRunner.registerOnComplete(...)          ← 同步完成后刷新 widget 数据
        └─ StaminaNotificationService.instance().init(context)
  （任何一步失败：Logger.warning，不阻塞、不提示；then 内 widget 初始化抛错也落到 :43，日志写成 "initCore failed"，
   且后续通知服务 init 被跳过）

EntryAbility.onWindowStageCreate                          (EntryAbility.ets:65-100)
  ├─ getMainWindow() → AppStorage['windowClass']          ← Main 依赖（见 M2）
  ├─ AppStorage['bottomRectHeight'] + on('avoidAreaChange')
  ├─ AppStorage['windowWidthPx'] + on('windowSizeChange')
  ├─ AppStorage['windowStatusType'] + on('windowStatusChange')
  └─ windowStage.loadContent('pages/Index')

Index.ets（34 行）
  ├─ RouterUtil.init(navPathStack)
  └─ pushPathByName(AppRoutes.LAUNCH)

LaunchPage.ets（94 行）
  ├─ LegalPreferences.hasAgreed(ctx) ? → Promise.all([waitForReady(), 1200ms]) → replace(MAIN)
  └─ 未同意 → 隐私页 → 同意 → replace(MAIN)（PrivacyConsentPage.ets:35，不经 waitForReady）
```

**关键时序**：`CoreInitializer.initCore` 是异步的，而 `loadContent` 在 `onWindowStageCreate` 里**不等它完成**；所以 Launch 的 `waitForReady()` 是已同意用户的第一道门，首装路径则靠各 ViewModel 自己 `await waitForReady()`（`HomeViewModel.ets:148` 等）。`waitForReady()` 背后的 `readyPromise` 只有 resolve、没有 reject（`core/.../CoreInitializer.ets:38-40`，仅在 initCore 成功末尾 `:160-162` resolve）——initCore 一旦抛错，两条路径都会无限等待（见 launch H1）。`windowClass` 同样是 `getMainWindow().then` 异步写入，Main 能读到它靠的是 Launch 的 1200ms 下限（见 main M7）。

---

## 4. ArkTS 合规性检查

| 规则 | 状态 | 说明 |
| --- | --- | --- |
| `console.*` / `any` / `var` | ✅ 0 处 | 两个 ability 文件均无 |
| 生命周期完整性 | ⚠️ 部分 | 注册了 3 个窗口监听（`avoidAreaChange` / `windowSizeChange` / `windowStatusChange`），但 `onWindowStageDestroy` 为空，未 `off`（见 L1）；另外 `:83` 的 `windowSizeChange` 回调会被 Main / GeetestDialog 不带 callback 的 `off` 一并清掉（见 main H1，因无消费者不影响本模块） |
| 错误处理 | ⚠️ | 所有异步链路都有 `.catch`，但日志统一 `JSON.stringify(error)`（`:19/40/44/91/95`）：`Error` 的 `message`/`stack` 不可枚举，序列化结果是 `{}`，initCore 失败时日志看不到原因（见 L4） |
| 类型 | ✅ | 无 `any`；`(err as Record<string, number>).code` 有显式断言 |
| 硬编码 | ⚠️ | `loadContent('pages/Index')` 是字符串字面量（页面名冻结，可接受）；AppStorage key 是字符串（见 M2） |
| 备份扩展 | ✅ | 只做钩子日志，实际备份交给系统；`allowToBackupRestore: true` |

---

## 5. 复用与耦合

- **`AppStorage` 是窗口信息的唯一跨模块通道**：4 个 key 中仅 2 个有消费者——`windowClass` 被 Main（`:56`）持有、`bottomRectHeight` 被弹窗组件（`AccountSwitchDialog.ets:27`）读取；但 `windowWidthPx` / `windowStatusType` **无人读取**，疑似分屏功能未实装（见 L3）。
- **EntryAbility 同时依赖 6 个模块**：core、theme（AppearanceManager）、notification（StaminaNotificationService）、widget（DataStoreManager / DataStoreBuilder）、config（RuntimeConfig）、color util（TransparentColorCache）。它是 entry 内唯一"全模块聚合点"，M15 拆 Main 时不要顺手把初始化搬进来。
- **备份扩展与业务无耦合**：`EntryBackupAbility` 不 import 任何业务代码，只依赖 core 的 Logger。

---

## 6. 安全审查

| 项 | 结论 |
| --- | --- |
| 导出面 | ⚠️ `WidgetSyncAbility.exported = true`，其 `callee.on('sync')`（`WidgetSyncAbility.ets:188`）**不校验调用方**；handler 内有并发锁 `isSyncing` 与 30 分钟冷却（`:40`、`:194-208`），但冷却时间戳只在同步成功后写入（`:224`），`isSyncing` 要等 `initCore` 完成才置位（`:220`）——失败的同步与并发首调都不受限（见 M4） |
| 权限最小化 | ✅ 仅 3 个权限，`usedScene` 明确 |
| 数据外泄 | ✅ EntryAbility 不打印 cookie / token |
| 备份 | ⚠️ `allowToBackupRestore: true` 且无 include/exclude：preferences 与数据库会进系统备份。数据库 `mihoyo_tool_v2.db` 的账号表有 `cookie TEXT NOT NULL` 列（`core/.../MihoyoKit/db/schema.ets:12/64`，手机号/扫码登录含 stoken），库只开 `SecurityLevel.S1`、未 `encrypt`（`core/.../db/RdbManager.ets:22-25`）——**明文登录凭据随备份导出**（见 M5） |
| 启动注入 | ✅ 无外部 `Want` 参数参与初始化（`onNewWant` 不解析参数，仅在 `:61` 整体打印 `want.parameters`，见 L2） |

---

## 7. 风险清单

### Medium

| # | 问题 | 位置 | 说明 |
| --- | --- | --- | --- |
| M1 | 初始化失败对用户完全不可见 | `EntryAbility.ets:14-48`（onCreate 初始化链，L18/L39/L43 共 3 处 `.catch` 只 `Logger.warning`） | widget 数据仓 / 通知服务初始化失败时：widget 无数据、通知不调度，且 `:30-32` 抛错会被 `:43` 当成 "initCore failed" 记录并跳过 `:39` 的通知初始化。core 本身初始化失败时 `waitForReady()` 永不 resolve，应用卡在启动页——该现象已作为 [launch](./launch-module-analysis.md) H1 计数，此处不重复。建议在 `AppStorage` 放一个 `bootError` 标记，由 Main/Home 显示一次可重试的提示 |
| M2 | 4 个 AppStorage key 是隐式契约，无集中定义 | `EntryAbility.ets:69 / 73 / 82 / 88`；读取方 `MainPage.ets:56`（`windowClass`）与 `AccountSwitchDialog.ets:27`（`bottomRectHeight`） | 字符串拼错不会报错，只会静默拿到 `undefined`（与 Main M7 的空值静默同源）。建议抽 `constants/AppStorageKeys`，写入方与读取方共用 |
| M3 | `loadContent` 失败无兜底 | `EntryAbility.ets:93-99`（失败只 `Logger.warning`） | 白屏且无提示；建议失败时 `loadContent` 重试一次或弹系统级错误页 |
| M4 | 导出 ability 的 callee 不校验调用方 | `WidgetSyncAbility.ets:188-238`（`callee.on('sync')`） | 见 §6。冷却（`:204`）只在同步成功后生效（`:224`），失败或并发首调不受限。建议在 handler 首行校验调用方，或把冷却时间戳提前到受理时写入 |
| M5 | 系统备份包含明文登录凭据 | `resources/base/profile/backup_config.json`（只有 `allowToBackupRestore: true`）+ `module.json5:62-73`；数据侧 `core/.../MihoyoKit/db/schema.ets:64`、`core/.../db/RdbManager.ets:22-25` | 备份范围未排除数据库，而账号表以明文保存 Cookie / stoken，设备备份或换机迁移会把长期登录凭据带出沙箱。建议 `backup_config.json` 用 `excludes` 排除数据库目录（恢复后要求重新登录），或在 core 侧启用加密库；属安全决策，记录不执行。原 L3「备份范围未显式声明」并入本条并升级 |

### Low

| # | 问题 | 位置 | 说明 |
| --- | --- | --- | --- |
| L1 | 窗口监听未注销 | `EntryAbility.ets:75 / 83 / 87`（3 处 `win.on`）与 `onWindowStageDestroy`（`:102-104`，仅日志） | 窗口与 ability 同生命周期，风险低；但折叠屏反复创建/销毁窗口时可能累积回调 |
| L2 | `onNewWant` 空实现 | `EntryAbility.ets:60-63` | 保留供扩展，当前仅日志——但 `:61` 把外部传入的 `want.parameters` 整体 `JSON.stringify` 进日志；若后续接 deep link，需要补参数校验并收窄日志 |
| L3 | 2 个 AppStorage key 无人读取 | `EntryAbility.ets:82/84/88`（`windowWidthPx` / `windowStatusType`） | 有写入、零消费者，疑似分屏功能未实装；若不需要可删除，保持 AppStorage 干净 |
| L4 | 失败日志丢失错误原因 | `EntryAbility.ets:19 / 40 / 44 / 91 / 95` | `JSON.stringify(error)` 对 `Error` 实例输出 `{}`（`message` / `stack` 不可枚举）；`RdbManager.init` 抛出的就是 `Error`（`core/.../db/RdbManager.ets:31`），所以 core 初始化失败时日志只剩 `initCore failed: {}`。改为 `error instanceof Error ? error.message : JSON.stringify(error)` |

---

## 8. 重构执行备注（M15 前置）

> 执行顺序按 Refactor_Spec §4：M15 最后做；本文件覆盖的是"框架页之外的框架层"。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| ability 路径 | 4 个 `srcEntry` 不可变（§2） |
| 入口页 | `loadContent('pages/Index')` 与 `main_pages.json` 的 `pages/Index` 必须一致 |
| AppStorage key | `windowClass` / `bottomRectHeight` / `windowWidthPx` / `windowStatusType` 四个字符串是跨模块契约；改名必须同时改写入方与所有读取方 |
| 初始化顺序 | 颜色模式 → 透明色 → core → widget 数据 → 通知；`TransparentColorCache.init` 必须早于任何使用透明色的组件渲染 |
| 备份 | `EntryBackupAbility` 保持空钩子，不要在这里加业务逻辑 |

### 重构范围（建议）

- **M2 可随 M15 做**：抽 `AppStorageKeys` 常量并替换读写两端，纯机械改动，但要一次性改完（漏一处就静默失效）。
- **M1 / M3 / M4 / M5 属行为变更**：需要产品（错误提示 UI）与安全（调用方校验、备份范围 / 凭据加密）决策，记录不执行。
- **L1 / L4 可顺手**：`onWindowStageDestroy` 注销监听、日志改成输出 `error.message`（纯日志改动，不改行为）。
- **不要动初始化顺序**：`WidgetDataStoreBuilder.initAndSave` 在 `CoreInitializer.then()` 异步队列中执行，`loadContent` 不等待 initCore（callback 异步返回），两者是并行关系（§3 已说明）；但生命周期时序保证了 initAndSave 大概率在页面可见前完成落盘。首次加卡片如果走到 `EntryFormAbility` 的 mock 分支（见 widget 文档 H2），说明 initAndSave 还没完成——保持现状即可避免这种情况。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. 无 Local Test（ability 无法在宿主机跑）。
3. 冒烟：冷启动（首装 / 已装）→ 主题恢复 → 首页数据 → 通知权限 → 添加卡片 → 杀进程后卡片提醒仍能弹出 → 备份/恢复（若测试机支持）。

### 已知问题归属

- Medium 5 项：M2 随 M15；M1/M3/M4/M5 需决策（M5 涉及备份/凭据，需安全评审；M4 归属 WidgetSyncAbility，可随 M14 处理）。
- Low 4 项：L1/L3/L4 可顺手（L3 删除死代码），L2 记录。
- 覆盖：EntryAbility 无自动化测试；其行为通过冒烟与各模块文档的启动契约间接验证。

---

## 9. 依赖文件索引

| 方向 | 内容 |
| --- | --- |
| EntryAbility → core | `CoreInitializer`、`Logger`、`SyncQueueRunner` |
| EntryAbility → features | `common/basic/src/main/ets/config/RuntimeConfig.ets`、`features/settings/src/main/ets/model/service/AppearanceManager.ets`、`common/basic/src/main/ets/utils/ColorUtil.ets`、`features/notification/src/main/ets/model/service/StaminaNotificationService.ets`、`features/widget/src/main/ets/model/service/WidgetDataStoreBuilder.ets`、`features/widget/src/main/ets/model/service/WidgetDataStoreManager.ets` |
| EntryBackupAbility → core | `Logger` |
| module.json5 → profile | `main_pages.json`、`custom_router_map.json`、`form_config.json`、`backup_config.json`、`string.json` / `color.json` / `media` |

---

*本文档仅分析，不修改代码。*

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 契约） | EntryAbility 113 / EntryBackupAbility 16 / module.json5 89 / backup_config 2 / RuntimeConfig 14；2 UIAbility + 2 ExtensionAbility + 3 权限；routerMap 20 条；form_config 6 张卡片 | ✅ 全部精确匹配 |
| 第 2 轮（启动链 + 行号） | onCreate 14-48、3 处 catch L18/L39/L43、AppStorage key L69/73/82/88、监听 L75/83/87、onWindowStageDestroy L102-104、loadContent L93-99、onNewWant L60-63 | ✅ |
| 第 3 轮（全面复核） | `windowClass` 消费者 Main:56、`bottomRectHeight` 消费者 AccountSwitchDialog:27、`windowWidthPx`/`windowStatusType` 零消费、WidgetSyncAbility:188、backup 无 include/exclude、无 ability 测试、0 console/any | ✅ 修正 2 处（onWindowStageCreate 范围 65-100 / §8 loadContent 异步表述） |
| 第 4 轮（2026-10-27 逐条复核） | 连带读 `core` 的 `CoreInitializer` / `RdbManager` / `schema`、`WidgetSyncAbility` 冷却逻辑、`PrivacyConsentPage` 首装路径 | M1 撤掉「Launch 有 catch 兜底进 Main」的错误前提（`readyPromise` 不会 reject，卡启动页计入 launch H1）；§6「数据库无凭据」不成立 → 原 L3 升为 M5（备份含明文 Cookie）；M4 补充冷却只在成功后生效的事实；原 L4 改号 L3；新增 L4（`JSON.stringify(Error)` 丢 message）。计数 0/0/4/4 → **0/0/5/4**，评级 A 不变，债务 12 → 14 |
