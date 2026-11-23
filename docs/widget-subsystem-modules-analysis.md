# Widget 子系统分析（M14）

> **分析对象**：`entry/src/main/ets/widget/`（28 个文件 / 2,836 行：pages 6·775 + views 17·1,599 + viewmodel 5·462）+ `entryformability/EntryFormAbility.ets`（322 行）；另含 `features/widget/src/main/ets/`（43 文件 / 6,063 行）与 `common/widgetbase/`（卡片进程共享的解析 / 工具 / 主题代码）。`widgetsyncability/WidgetSyncAbility.ets`（263 行）已于 2026-11-20 删除。
> **分析日期**：2026-10-24
> **代码版本**：`105c8d3`
> **HarmonyOS SDK**：`6.0.2(22)`（`targetSdkVersion` / `compatibleSdkVersion`，见根 `build-profile.json5`）
> **口径**：skills `harmonyos-review` 官方 A-F 评级（按 Critical/High/Medium 计数）
> **定位**：这是 M14 的唯一分析文档。此前 `docs/` 里没有任何文档覆盖 widget 子系统（`Refactor_Spec` §4 只有一行描述），本文件就是为补这个缺口而写的。

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 1 |

**整体评级：A**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + 0 High → A）。
>
> 计数为 2026-11-23 现状：H1 / H2 已修复（`bae5b61`，对应审计 GAP-01 / GAP-06），**H3 已修复（`f629da5`）**，M1 / M6 / M7 / M8 已修复，L1（`WidgetLog` 重复）/ L2（`onFormEvent` 忽略 `message`）已修复（L1 2026-11-13、L2 2026-11-15，代码见 `EntryFormAbility.ets` 对非空 `message` 直接忽略并记日志）；M2 / M3 / M5 随 `WidgetSyncAbility` 删除而关闭（2026-11-20），M4 已修复（2026-11-23：按尺寸跳过图片、图片读取加时间预算、补耗时日志）。**Medium 已清零，仅剩 L3（2×2 / 2×4 / 4×4 缺页面级 `@Preview`）。**
>
> 债务 1×1 = **1**；体量 9,221 行（`features/widget/src/main/ets/` 6,063 + `entry/src/main/ets/widget/` 2,836 + `EntryFormAbility` 322），密度 1 ÷ 92.21 ≈ **0.01 / 百行**（`WidgetSyncAbility` 263 行已随 2026-11-20 清理移除）。

> 架构本身是清楚的：主应用写「数据仓」→ 卡片进程读 payload → 6 个页面各自经 ViewModel 构建 UIState → V1 组件渲染。**曾经有三处会直接伤害"桌面卡片"这个核心场景**：更新失败会把用户的卡片配置删掉（H1，已修）、无数据时展示伪造的"测试账号"（H2，已修）、卡片从不显示数据有多旧（H3，已修）。这三条都不影响主应用，只影响卡片，所以历史上一直没被页面级评审覆盖。2026-10-27 复核另补 2 条 Medium：点击同步的并发锁置位过晚（M7，已修）、`WidgetFormIdStore` 无写入方导致两条调用链空转（M8，已删）。
>
> 另有结构性事实需要先说清楚：widget **是 V1 孤岛**（16 个文件使用 `@Component`，0 个 `@ComponentV2`），这是卡片渲染引擎的限制，不是技术债——本轮重构**不迁移**装饰器。

---

## 1. 文件清单

### 1.1 页面（6，全部是 `form_config.json` 的 `src`）

| 文件 | 行数 | 尺寸 | 布局 |
| --- | --- | --- | --- |
| `widget/pages/Widget1x2Genshin.ets` | 99 | 1×2 | 单角色迷你卡（原神） |
| `widget/pages/Widget1x2StarRail.ets` | 99 | 1×2 | 单角色迷你卡（星铁） |
| `widget/pages/Widget1x2ZZZ.ets` | 99 | 1×2 | 单角色迷你卡（绝区零） |
| `widget/pages/Widget2x2.ets` | 159 | 2×2 | 单游戏详细 / 双游戏上下分栏；多游戏时右下角显示数据新鲜度 |
| `widget/pages/Widget2x4.ets` | 156 | 2×4 | 单游戏横排 / 双游戏左右分栏；右上角显示数据新鲜度 |
| `widget/pages/Widget4x4.ets` | 163 | 4×4 | 单游戏大卡 / 双游戏上下分栏；多游戏时右上角显示数据新鲜度 |

### 1.2 ViewModel（5，462 行）

| 文件 | 行数 | 职责 |
| --- | --- | --- |
| `widget/viewmodel/WidgetRoleStateBuilder.ets` | 151 | 角色 UIState 共享构建器（2×2 / 2×4 / 4×4 共用，布局差异由 `WidgetRoleLayout` 表达） |
| `widget/viewmodel/Widget1x2ViewModel.ets` | 80 | 按 `gameId` 过滤后取首个角色（产出紧凑的 `Widget1x2RoleUIState`） |
| `widget/viewmodel/Widget2x2ViewModel.ets` | 111 | 单游戏详细态 / 多游戏最多 2 个 |
| `widget/viewmodel/Widget2x4ViewModel.ets` | 60 | 同上，横向布局态 |
| `widget/viewmodel/Widget4x4ViewModel.ets` | 60 | 同上，大卡态 |

### 1.3 组件（17，1,552 行）

`Widget1x2ContentView`（121）· `Widget2x2Header`（76，含新鲜度）· `Widget2x2SingleGame`（106）· `Widget2x2StaminaBlock`（53）· `Widget2x2StandardStamina`（70）· `Widget2x2StarRailStamina`（91）· `Widget2x4SingleGame`（152）· `Widget2x4InfoColumn`（106）· `Widget4x4SingleGame`（136）· `Widget4x4Header`（80，含新鲜度）· `Widget4x4StaminaBlock`（112）· `Widget4x4ExtraRowsGroup`（63）· `Widget4x4ExpeditionBlock`（64）· `WidgetDataRow`（69）· `WidgetExpeditionAvatar`（126）· `WidgetEmptyContent`（66）· `WidgetExtraDataRows`（108）

### 1.4 模型（4，979 行）

| 文件 | 行数 | 职责 |
| --- | --- | --- |
| `features/widget/.../model/WidgetGameSnapshotModel.ets` | 134 | 原始 JSON 结构 + payload 中间模型 |
| `common/widgetbase/.../model/WidgetUIStateModels.ets` | 236 | 各尺寸 UIState（被测试直接引用） |
| `features/widget/.../model/WidgetConfigModels.ets` | 151 | 单个卡片的配置（尺寸 / slots / formName） |
| `features/widget/.../model/WidgetDataStoreModels.ets` | 458 | 全局数据仓（账号 → 角色 → rawJson + 拉取时间），写入 `preferences` |

### 1.5 工具（12，3,219 行）

| 分组 | 文件（行数） |
| --- | --- |
| **数据构建** | `WidgetDataStoreBuilder`（394）· `WidgetPayloadBuilder`（379） |
| **数据解析** | `WidgetPayloadUtil`（395，被测试引用）· `WidgetDataUtil`（497，被测试引用） |
| **存储** | `WidgetDataStoreManager`（164）· `WidgetConfigStore`（145） |
| **推送** | `WidgetUpdateNotifier`（168） |
| **图片** | `WidgetImageDownloader`（489） |
| **展示工具** | `WidgetUtil`（418，含新鲜度格式化）· `WidgetExtraRowConstants`（55，被测试引用）· `WidgetExtraRowType`（35，被测试引用） |
| **日志 / 调试** | `WidgetLogger`（80）；`WidgetMockPayload`（45）已于 2026-11-20 删除 |

### 1.6 子系统外的两个 ability

| 文件 | 行数 | 角色 |
| --- | --- | --- |
| `entryformability/EntryFormAbility.ets` | 322 | 卡片生命周期：`onAddForm` 同步返回初始数据（按尺寸决定是否读图片 fd，带时间预算与分段耗时日志）、`onUpdateForm` / `onFormEvent` 推送、`onRemoveForm` 清配置 |

---

## 2. 架构分析

### 2.1 结构树

```
widget/
├── pages/          6 个 @Entry(storage) 页面，form_config.json 直接按路径引用
├── components/     10 个 V1 组件（4 个尺寸 × 单/多游戏 + 空态 + 额外数据行）
├── viewmodel/      4 个纯静态 ViewModel（无状态，只做 ParsedPayload → UIState）
├── models/         payload 结构 / UIState / 卡片配置 / 全局数据仓
└── utils/          16 个：构建 / 解析 / 存储 / 推送 / 图片 / 日志
entryformability/EntryFormAbility.ets      卡片生命周期入口
```

### 2.2 卡片定义（`form_config.json`，6 个 form）

6 个 form 的字段几乎一致：`uiSyntax: arkts`、`isDynamic: true`、`updateEnabled: true`、`updateDuration: 1`、`renderingMode: fullColor`、`metadata: []`；只有 `widget_2x2` 的 `isDefault` 是 `true`，其余为 `false`。`src` 全部硬编码为 `./ets/widget/pages/*.ets`（`form_config.json:7 / 24 / 41 / 58 / 75 / 92`），属于**不可改动契约**。

### 2.3 写入链路（主应用 → `preferences`）

```
主应用同步完成
  → WidgetDataStoreBuilder.buildFromDB()（读 core 的 RDB）
  → WidgetDataStoreManager.save()（JSON 写入 preferences: widget_data）
  → WidgetUpdateNotifier.notifyAllWidgets()
      → 遍历 WidgetConfigStore 里的每个 formId
      → WidgetPayloadBuilder.buildPayload(config, dataStore)
      → formProvider.updateForm(formId, formBindingData(record))
```

`payload` 只通过 `LocalStorage` 传给卡片进程，键名固定为 `'payload'`（`Widget2x2.ets:26`、`Widget1x2*.ets:34`、`Widget2x4/4x4.ets:29` 共 6 处 `@LocalStorageProp('payload')`）。

### 2.4 渲染链路（卡片进程内）

```
@LocalStorageProp('payload')  →  parsePayload()  →  ParsedPayload
   →  WidgetNxMViewModel.buildUIState()  →  UIState
   →  V1 组件（@Prop role / state / gameColor）
```

6 个页面都用同一套写法：`payload` 字符串 → `parsePayload()`（2×2 / 2×4 / 4×4 经页面私有 `getParsed()`，1×2 三页直接在 `getUIState()` 内调用）→ ViewModel 静态方法 → 组件。ViewModel 完全无状态，四个 ViewModel 均有 `entry/src/test` 单测。

### 2.5 点击卡片链路

```
卡片 onClick
  → postCardAction({ action: 'router', abilityName: 'EntryAbility',
                     params: { from: 'widget'[, gameId, accountId, roleUid] } })
  → EntryAbility
      → onCreate：解析路由 → AppStorage('widgetEntryRoute')（冷启动，等 MainPage 挂载时消费）
      → onNewWant：解析路由 → eventHub.emit('widgetEntryRoute')（热启动，MainPage 直接消费）
      → 两条路径都会调用 WidgetSyncHook.onDailyNotesSynced(context)
          → WidgetDataStoreBuilder.refreshAndSave()（本地 DB → Preferences → 推送卡片）
  → MainPage
      → 1×2 卡片：gameId + accountId + roleUid → buildDailyDetailRoute()
          → 竖屏 pushPathByName / 分栏 replacePath → 对应游戏便笺详情页
      → 2×2 / 2×4 / 4×4：只带 from，落在首页
```

**2026-11-19 修正**：原先 6 张卡片都发 `action: 'call'` 拉起 `WidgetSyncAbility`，但该 Ability 的 `onWindowStageCreate` 不 `loadContent`，是纯后台同步入口——点击卡片只会在后台同步，**永远不会打开 App**。现在改为 `router` 直接打开 `EntryAbility`，由它刷新一次卡片数据并处理跳转；网络同步交给 App 首页原有的同步流程（同步完成回调仍会刷新卡片）。

**1×2 直达详情**：`ParsedRole` 增加 `accountId`，`Widget1x2RoleUIState` 透传，卡片点击时把 `gameId` / `accountId` / `roleUid` 放进 `params`。路由映射收敛到 `features/home` 的 `buildDailyDetailRoute()`，首页卡片点击与桌面卡片点击共用同一份实现。

`WidgetSyncAbility` 已于 2026-11-20 删除：点击改 `router` 后它没有任何调用方，且该 Ability 从未注册定时器（30 分钟冷却只约束「重复点击同步」，不是自动刷新）。`KEEP_BACKGROUND_RUNNING` 权限与两条字符串资源一并移除。后续若要恢复「点击卡片触发网络同步」，建议把同步编排抽到 widget 功能层，由 `EntryAbility` 在收到 `from=widget` 时调用。

---

## 3. ArkTS 合规性检查

| 规则 | 状态 | 说明 |
| --- | --- | --- |
| V1/V2 边界 | ✅ 有意为之 | widget 内 `@ComponentV2` **0 个**、`@Component` **16 个源文件**（6 pages + 10 components，注意：嵌套装饰器共 30 处实例）；9 个组件文件在注释里写明"卡片渲染引擎不支持 @ComponentV2"，3 个 1×2 页面注释写明"V1 体系，不能使用 @ObservedV2/@Trace"（`Widget1x2Genshin.ets:11`）。全工程 16 个 V1 文件全在这里 |
| union 类型 | ⚠️ 受限 | 页面注释明确写"Widget Form 不支持 union 类型，使用默认对象而非 null"（`Widget1x2Genshin.ets:10`）；payload 模型因此用空字符串 / `0` 代替 `null` |
| `build()` 内局部变量 | ⚠️ 受限 | 页面注释写"`build()` 方法中不能声明局部变量，必须使用组件方法"（`Widget1x2Genshin.ets:12`）；6 个页面全部改成私有 getter——**这正是 §6 M1 性能问题的成因** |
| `@Entry(storage)` | ✅ | 6 个页面各自 `let storage = new LocalStorage()` + `@Entry(storage)` + `@LocalStorageProp('payload')`，形态一致 |
| 装饰器合规 | ✅ | 组件用 `@Prop`（V1）接收 `role` / `state` / `gameColor`，无 `@ObjectLink` 误用 |
| 主题访问 | ✅ | 组件内 `private theme = new DefaultTheme()`，不依赖单例 `ThemeManager`（卡片进程无法保证主题初始化） |
| 日志 | ⚠️ | 两套 logger 并存（见 §4.4） |

> V1/V2 结论：**保持现状**。本轮重构只动目录/命名/内部拆分，不改变装饰器，也不新增混合文件。

---

## 4. 组件复用分析

### 4.1 1×2 三个页面是复制粘贴

`Widget1x2Genshin` / `StarRail` / `ZZZ` 各 85 行，逐行 diff 后除文件头注释、`struct` 名与 Preview `struct` 名外，**逻辑只有 3 处不同**：`buildUIState` 的 `gameId` 参数（`:39`）、`getGameColor(...)`（`:49`）、`widgetSingleGameGradient(...)`（`:59`）。三份的 `@Preview` 块结构也一致（页面级只有这 3 页有 `@Preview`，2×2 / 2×4 / 4×4 页面没有）。

### 4.2 2×2 体力区块有两个变体

`Widget2x2StandardStamina`（原神/绝区零：`Column` + 当前体力/恢复时间）与 `Widget2x2StarRailStamina`（星铁：`Row` + 当前体力 + 后备开拓力）**是两套布局**，不是重复代码；`Widget2x2StaminaBlock` 是外层容器。三者职责清晰，不建议合并。

### 4.3 4 个 ViewModel 高度同构

`Widget2x2` / `2x4` / `4x4` 三个 ViewModel 都是"空态 → 单游戏详细态 → 多游戏最多 2 个"，差异只在 UIState 类型和 stamina 区块选择。`Widget1x2ViewModel` 是"按游戏过滤取首个"。

**已处理（2026-11-11）**：三者共有的「`ParsedRole` → `WidgetRoleUIState`」逻辑（角色字段 / 体力 / 额外数据行 / 派遣头像 / 多游戏去重）已抽到 `WidgetRoleStateBuilder`，布局差异用 `WidgetRoleLayout`（`COMPACT_2X2` / `GRID_2X4` / `GRID_4X4`）表达。三个 ViewModel 只保留 `buildUIState` 分支，161+162+159 → 111+60+60 行。`Widget1x2ViewModel` 产出 `Widget1x2RoleUIState`，结构不同，保留独立实现。

### 4.4 真正可去的重复

| 重复 | 证据 | 建议 |
| --- | --- | --- |
| ~~两套 logger~~ | ✅ 已修复（2026-11-13）：`WidgetLog`（53 行）唯一的引用是 `WidgetPayloadBuilder` 的未使用 import，属死代码，已删除；日志统一用 `WidgetLogger` | 已完成 |
| 主题常量 | `WidgetUtils` 内自带 `WidgetColors` / 渐变函数，与 `theme/DefaultTheme` 有重叠取值 | 保留（卡片进程不适合依赖单例主题），仅记录 |
| 1×2 三页 | §4.1 | **已评估不抽（2026-11-11）**：三页只差一个 `WidgetGameId` 常量，抽 `Widget1x2Page(gameId)` 需在卡片数据链路（`@LocalStorageProp` → `@Prop`）多加一跳，且桌面渲染无法在模拟器验证；页面名被 `form_config.json` 的 `src` 冻结，收益为负 |

---

## 5. 安全审查

| 项 | 结论 |
| --- | --- |
| **凭据落盘** | ✅ 干净。`WidgetDataStore` / `WidgetPayloadBuilder` / `WidgetPayloadParser` / `WidgetModels` 中 **grep `cookie` / `token` 无命中**；数据仓只存 `accountId` / `accountName` / `roleId` / `nickname` / `server` / `rawJson`（便笺原始 JSON） |
| **网络请求** | ⚠️ 仅 `WidgetImageDownloader` 走网络，下载派遣头像；`http.createHttp()` 在 `finally` 里 `destroy()`（`WidgetImageDownloader.ets:410/444`）。但 URL 直接取自便笺 `rawJson` 的 `avatar_side_icon`（`:478`），**没有 scheme / 域名校验**，并非"只下载 `https://`"；来源是米游社接口，风险低 |
| **明文存储** | ⚠️ `preferences: widget_data` 是明文 JSON，但内容不含凭据，可接受 |
| **日志** | ✅ `WidgetSyncAbility` 已删除，其 `syncAllWidgets` 打印 `uid` / `roleId` / `gameId` 的日志随之消失；现存卡片链路不打印账号标识，也没有打印 cookie |
| **Mock 数据** | ❌ 见 H2：无数据时把"测试账号 / 旅行者 / 树脂 152"当真数据返回给卡片 |

---

## 6. 风险清单

### High（建议随 M14 修，行为修复单独提交）

**H1 · 一次瞬时更新失败会永久删除用户的卡片配置**

- **位置**：`WidgetUpdateNotifier.ets:66-75`（失败即 `deleteConfig`）、`:120-144`（`pushUpdate` 对所有异常都 `return false`）
- **问题**：`pushUpdate` 只有 `err.code === 401 || 16500050` 才代表"卡片已删除"（`:137`），但其余错误（宿主繁忙、更新频率超限、`updateForm` 抛错）也走 `return false`。`notifyAllWidgets` 拿 `false` 就当"卡片已删除"处理，直接 `WidgetConfigStore.deleteConfig(config.formId)`。
- **影响**：一次偶发失败 → 用户在该卡片上选的游戏/角色槽位被清空，且**没有任何提示**；配置删除后该 formId 不再出现在 `getAllConfigs()`，主应用同步后的 `notifyAllWidgets` 再也不会推送它，只能等 `onUpdateForm` 用 `loadConfig()` 返回的空 `WidgetConfig`（`WidgetConfigStore.ets:64-80`，`formName` 为空 → 走默认 fallback）兜底；重建卡片后需重新配置。
- **建议**：区分"不存在"与"暂时失败"——只有 401 / 16500050 才删配置，其余记日志并保留；或加失败计数阈值。
- **状态**：✅ 已修复（`bae5b61`）。`WidgetUpdateNotifier` 新增 `WidgetPushResult`（`SUCCESS` / `WIDGET_REMOVED` / `FAILED`）与 `classifyPushError()`：仅 `401` / `16500050` 清理配置，其余失败只记日志并保留配置，下次同步继续推送。
  - **补充（2026-11-18，`5b6d0a9`）**：模拟器实测发现漏了一个错误码。桌面删卡后 `updateForm` 返回 **`16501001`「The ID of the form to be operated does not exist」**，`classifyPushError()` 未识别，于是走 `FAILED` 分支「保留配置」，导致失效配置永久残留——每轮同步都白跑一次 IPC 并刷 `pushUpdate error` / `keeping config` 两条日志（实测 4 条/轮）。现已把 `16501001` 并入 `WIDGET_REMOVED`：首轮 `success=1 removed=4 failed=0`，后续轮次 `removed=0 failed=0`，配置被真正清理。单测 79 → 80 条。

**H2 · 无数据时卡片展示伪造的账号与体力**

- **位置**：`EntryFormAbility.ets:183-186`（`!dataStore.hasData` → `buildMockFormData()`）、`:212-216`、`WidgetMockPayload.ets:18-26`（`buildPayload`）/ `:31-44`（原神便笺假数据）
- **问题**：首次添加卡片、或数据仓为空时，`onAddForm` 返回 `WidgetMockData.buildPayload()` —— 内容是 `"测试账号"` / `"旅行者"` / 树脂 152 / 洞天宝钱 1230 等固定假数据，`payload` 里没有任何 `isMock` 标记。
- **影响**：用户看到的是**看起来完全真实**的体力与恢复时间，无法区分"占位"与"真实数据"。这是产品级误导，不只是调试残留。
- **建议**：Mock 只允许在 `BuildProfile.DEBUG` 下使用；release 下无数据应返回空态 payload（页面已有 `WidgetEmptyContent`）。
- **状态**：✅ 已修复（`bae5b61`）。`EntryFormAbility.buildFormData` 删除 Mock 分支：`!dataStore.hasData` 时只记一条 warn 日志，仍用 `WidgetPayloadBuilder.buildPayload` 返回真实空 payload，卡片走 `WidgetEmptyContent` 空态。2026-11-20 进一步删除 `WidgetMockPayload` 及其单测、`features/widget/Index.ets` 导出，生产与测试代码均无 Mock 残留。

**H3 · 卡片从不显示数据新鲜度**

- **位置**：`WidgetPayloadBuilder.ets:77`（`toLocalStorageRecord()` 写入 `updatedAt = Date.now()`）→ `WidgetPayloadParser.ets:283`（解析出 `updatedAt`）→ **6 个页面与 10 个组件均未使用**；真正的数据时间 `WidgetDataStore.updatedAt`（`WidgetDataStore.ets:216`，由 `WidgetDataStoreBuilder.ets:43/297/316` 写入）**没有进入 payload**
- **问题**：payload 里的 `updatedAt` 是**推送时刻**而非数据拉取时刻，即使渲染出来也只会显示"刚刚"；体力与恢复倒计时也是同步时刻的快照（widget 内无任何按当前时间推算的逻辑）。没有一个组件渲染"更新于 X 分钟前"；叠加 §2.5 的 30 分钟全局冷却、H1 的静默失败、已删除的 `WidgetSyncAbility` 内 `syncDailyNoteQuietly` 遇到人机验证直接跳过（原 `:164-166`），卡片可能长时间停在旧数值上。
- **影响**：用户把陈旧数据当实时数据决策（"还有 160 体力，先打一把"）。
- **建议**：把 `dataStore.updatedAt` 写进 payload（而不是推送时刻），至少在 2×2 / 2×4 / 4×4 的角落显示相对时间；或当 `now - updatedAt > 2×updateDuration` 时给一个降透明度/角标。
- **状态**：✅ 已修复（`f629da5`，2026-11-17）。数据时间改为**便笺行的真实拉取时间**，而不是「数据仓最后一次保存时间」——后者在每次冷启动 `buildFromDB()` 读本地 DB 时都会被刷新成「刚刚」，等于没修。具体：
  - `WidgetSlotSnapshot.updatedAt`（新字段，`WidgetDataStoreModels.ets`）：由 `WidgetDataStoreBuilder.buildSlotData()` 取 `dailyNote.updateTime` 写入，随 store JSON 持久化（旧数据缺失时为 0，向后兼容）。
  - `WidgetPayloadBuilder.buildPayload()`：`payload.updatedAt` 取**本次展示 slot 中最早的 `updatedAt`**（`resolveUpdatedAt()`），跳过无数据 / 无时间的 slot；`toLocalStorageRecord()` 不再写 `Date.now()`。
  - `saveWidgetsConfig()` 不再改 `store.updatedAt`（改卡片配置不代表数据变新）；`buildFromDB()` 的 `store.updatedAt` 改为所有有数据 slot 的最早时间。
  - 卡片渲染（`widgetbase`，不依赖 core）：`formatUpdatedAtText()` / `formatUpdatedAtCompactText()` + `isWidgetDataStale()`；超过 1 小时（`WIDGET_FRESHNESS_STALE_SECONDS`）改用 `color_warning` + 高透明度高亮。
  - 位置：2×2 单游戏在 `Widget2x2Header` 的 UID 行右侧（紧凑文案），2×2 多游戏在右下角；2×4 在右上角（完整文案）；4×4 单游戏在 `Widget4x4Header` 的 UID 右侧，多游戏在右上角。1×2 三页空间不足，不显示。
  - 测试：`WidgetPayloadBuilder.test.ets` 覆盖「取最早时间 / 跳过未同步 slot」；`WidgetFreshness.test.ets` 覆盖陈旧阈值；`widget` 76 → 79 条、`widgetbase` 96 → 100 条。

### Medium（技术债）

| # | 问题 | 位置 | 说明 |
| --- | --- | --- | --- |
| M1 | `build()` 内反复解析 payload | `Widget2x2.ets:57/61/63`（`getGameIds` / `getIsEmpty` / `getIsSingleGame` 各 `getParsed()` 1 次）+ `build()` 内 6 处 `getUIState()`，多游戏分支单次渲染最多 **9 次** `JSON.parse`；`Widget2x4.ets` / `Widget4x4.ets` 各 6 次 `getUIState()` + 1 次 `getGameIds()`（**7 次**）；1×2 三页各 2 次 | 每次 `getUIState()` 都 `JSON.parse` 整个 payload 并重建 `ParsedPayload` + UIState。V1 没有 computed，且 `build()` 不能声明局部变量——这是限制下的写法，但可以让页面缓存一次（私有字段记住上次的 `payloadJson` 与解析结果，`payloadJson` 变化时失效；V1 页面不能用 V2 的 `@Local`）。**✅ 已修复（2026-11-11，见 §7 M1 执行记录）** |
| M2 | ~~30 分钟冷却被所有卡片共享，且失败也计入冷却~~ | ~~`WidgetSyncAbility.ets:40 / 43 / 204 / 224`~~ | **已关闭（2026-11-20）**：`WidgetSyncAbility` 删除，全局冷却逻辑不存在；卡片点击改为打开 App，由首页同步流程接管 |
| M3 | ~~同步结果不可见~~ | ~~`WidgetSyncAbility.ets:237`~~ | **已关闭（2026-11-20）**：`call` 链路随 Ability 删除；`router` 打开 App 后由页面自身展示刷新状态 |
| M4 | ✅ 已修复（2026-11-23） | 原 `EntryFormAbility.ets:42 / 45-67`（Preferences 同步读 + `loadFormImagesSync` + payload 构建） | 修复：① 只有 2×4 / 4×4（`dimension` 3 / 4）才读派遣头像 fd，1×2 / 2×2 直接返回空 map；② 图片读取前检查已耗时，≥3 秒则跳过图片保证按时返回；③ `onAddForm` 记录 `total / config / store / payload / images` 耗时，≥3 秒打 warn。Preferences 与 payload 构建仍同步，但卡片最多 2 个 slot，成本有界 |
| M5 | ~~全量同步是串行双层循环~~ | ~~`WidgetSyncAbility.ets:105-118`~~ | **已关闭（2026-11-20）**：`syncAllWidgets` 随 Ability 删除；App 首页的同步编排不受影响 |
| M6 | ✅ 已修复（2026-11-12） | 原 `WidgetImageDownloader.ets:87`（文件名固定 `${prefsKey}_${i}.png`）、`:91-105`（文件已存在就跳过下载） | 修复：下载时把源 URL 记到 `${key}_url`，只有「文件存在 **且 URL 未变**」才跳过；URL 变化（派遣角色变化 / 换账号）重新下载并用 `TRUNC` 覆盖同名文件。旧安装（无 URL 记录）会重下一次，自动纠正历史陈旧头像 |
| M7 | ✅ 已修复（2026-11-12），随 Ability 删除关闭（2026-11-20） | 原 `WidgetSyncAbility.ets:194` 检查 vs `:217` 置位（`initCore()` + 两次 `init` 完成后才置位） | 修复：冷却检查通过后**同步**置位 `isSyncing`，再启动异步链；`initCore` 失败也释放锁。`initCore` 期间连点卡片会被 "Already syncing" 拦下，不再并发起多条 `syncAllWidgets` |
| M8 | ✅ 已修复（2026-11-13） | 原：`WidgetFormIdStore.save()` 全工程零调用 → `widget_form_ids` 永远为空，`WidgetDataBuilder.buildAndPushForAccount` 恒提前返回，`AccountDetailViewModel.deleteAccount` 的卡片清理恒为 no-op | 修复：整条遗留链路删除（`WidgetFormIdStore.ets` 141 行 + `WidgetDataBuilder.ets` 228 行 + `WidgetFormIdStore.test.ets` 3 条用例），`WidgetSyncHandlerImpl` 只留 `refreshAndSave`，`WidgetSyncHook.init` 与通知服务 init 里的调用一并删除，`AccountDetailViewModel` 去掉 no-op 清理。真正的卡片推送一直由 `WidgetDataStoreBuilder.refreshAndSave` → `WidgetUpdateNotifier.notifyAllWidgets` 负责，行为零变更 |

### Low（建议优化）

| # | 问题 | 位置 | 说明 |
| --- | --- | --- | --- |
| L1 | ✅ 已修复（2026-11-13） | 原：`WidgetLog.ets`（53）vs `WidgetLogger.ets`（80）并存 | `WidgetLog` 的唯一引用是未使用的 import，已删除 |
| ~~L2~~ ✅ | `onFormEvent` 忽略 `message` | `EntryFormAbility.ets:87-89` | 任何 `formEvent` 都对该 formId 触发 `pushUpdate`，不校验内容；而 6 个页面的点击只发 `action: 'call'`（如 `Widget2x2.ets:104`），从不发 `message`，该回调目前没有触发源 |
| L3 | 页面级只有 1×2 三页有 `@Preview` | `widget/pages/Widget1x2*.ets:73` | 9 个组件文件各有 `@Preview`（`WidgetEmptyContent` 无），但 2×2 / 2×4 / 4×4 页面的空态 / 单游戏 / 多游戏分支组合只能上真机验证；建议补页面级 `@Preview`（不改页面结构） |

---

## 7. 重构执行备注（M14 · Widget 子系统）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。M14 排在最后（§4），因为它是 V1 孤岛且与 ability / notification 双向耦合。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 卡片定义 | `resources/base/profile/form_config.json` 的 6 条 `src` 路径（`./ets/widget/pages/Widget*.ets`）与 `name` 全部冻结；改名 = 卡片在桌面消失 |
| Ability | `module.json5` 的 `EntryFormAbility` `srcEntry` 冻结（`WidgetSyncAbility` 已于 2026-11-20 删除） |
| 测试引用（冻结） | `widget/viewmodel/Widget2x2ViewModel`、`widget/models/WidgetUIStates`、`widget/utils/{WidgetPayloadParser,WidgetDataHelper,WidgetUtils,WidgetExtraRowConfig,WidgetExtraRowType}` —— 导出名不得变（§2.5） |
| 装饰器 | **不迁移 V1 → V2**；不新增 `@ComponentV2` 文件 |
| payload 键名 | `'payload'` 是卡片进程与主应用的唯一约定（6 个 `@LocalStorageProp`），不能改名 |
| 数据仓格式 | `widget_data` / `widget_configs` 两个 preferences 文件与 JSON 结构（`version: 2`）不可变，否则已装卡片读不到数据；新增字段必须是**可选**的（如 slot 的 `updatedAt`），旧数据缺失时按 0 处理 |

### 重构范围（建议）

- **只做内部整理**：`widget/` 目录已经按 pages/components/viewmodel/models/utils 分好，**不需要搬文件**；本轮只做了 `WidgetLog` 删除（2026-11-13，死代码）与 `WidgetMockData` 的 debug-only 标注。
- **优先修 H1 / H2**：两处都不改变 UI 结构，H1 是 10 行左右的错误码分支，H2 是一个 `BuildProfile.DEBUG` 判断；建议各自单独提交。
- **H3 已完成**（2026-11-17）：payload 改用便笺真实拉取时间，2×2 / 2×4 / 4×4 显示相对时间，超 1 小时高亮；只改渲染层与数据时间，未动 `form_config.json` / payload 键名。
- **M1 已完成**：页面内缓存 `ParsedPayload` + UIState，不改任何组件接口（2026-11-11，见下方执行记录）；回归 6 张卡片 × 单/多游戏仍待真机。
- **不要合并 1×2 三页文件**：`src` 冻结，只能抽内部共享 struct。
- **M4 已修复**（2026-11-23）：`onAddForm` 只对 2×4 / 4×4 读派遣头像 fd，图片读取带 3 秒时间预算，并补充分段耗时日志；Preferences 与 payload 构建保持同步（卡片最多 2 个 slot，成本有界）。M5 随 `WidgetSyncAbility` 删除关闭。
- **M6 / M7 是行为修复**：M6 用「源 URL + 文件」双记录判断缓存是否过期，URL 变化即重下；M7 把 `isSyncing = true` 提前到返回前并在 `initCore` 失败时释放。两项已于 2026-11-12 单独提交。
- **M8 已按「删除遗留链路」执行**（2026-11-13）：删 `WidgetFormIdStore` / `WidgetDataBuilder` 与对应测试，`WidgetSyncHandlerImpl` 只保留 `refreshAndSave`，`WidgetSyncHook` 去掉只为它存在的 `init` 接口，`AccountDetailViewModel` 去掉恒 no-op 的清理；行为零变更，单独提交。**遗留缺陷另立**：「删除账号后 `widget_configs` 里指向该账号的 slots 无人清理」需要 `deleteAccount` 拿到 context 后按 `slot.accountId` 过滤，属行为变更，未随本次提交。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. DevEco Local Test：`Widget2x2ViewModel` / `WidgetPayloadParser` / `WidgetDataHelper` / `WidgetDataHelperExtraRows` / `WidgetExtraRowConfig` / `WidgetExtraRowType` 六套通过。
3. 冒烟（无自动化，必须真机/模拟器）：6 张卡片各添加一次 → 单游戏 / 双游戏 / 三游戏（应截断到 2）→ 空数据 → 点击刷新 → 冷却期再点 → 主应用同步后卡片自动更新 → 删除卡片后配置清理。
4. H1 修复后额外验证：模拟 `updateForm` 抛非 401 错误，确认卡片配置**仍在**；`401` 时确认被清理。

### 已知问题归属

- **High 3 项**（配置误删、Mock 数据、无新鲜度标识）：**全部关闭**——H1 / H2 于 `bae5b61`，H3 于 `f629da5`。
- **Medium 8 项**（重复解析、全局冷却且失败也计冷却、结果不可见、10 秒窗口、串行同步、派遣头像永不更新、并发锁置位过晚、`WidgetFormIdStore` 空转）：**全部关闭**——M1 / M4 / M6 / M7 / M8 已修复（M8 走删除路线），M2 / M3 / M5 随 `WidgetSyncAbility` 删除关闭。
- **Low 2 项**（logger 合并、预览缺失）：`formEvent` 校验已于 2026-11-15 修复——非空 `message` 只记日志、不触发刷新。
- **测试覆盖**：`WidgetDataStoreModels`（序列化往返 / `getRole` / 配置）与 `WidgetPayloadBuilder`（slot 选择 / 截断 / `updatedAt`）已有单测；`WidgetDataStoreBuilder`（365）、`WidgetImageDownloader`（489）、`WidgetUpdateNotifier`（146）仍无单测。四个 ViewModel 自 2026-11-07 起已有 `entry/src/test` 单测（本轮实测四个均 100% 行覆盖）。

### 预览组件执行记录（2026-11-06）

> **范围说明**：本轮 M14 只重构 `features/widget/src/main/ets/views/preview/`（配置页卡片预览），**未改** `entry/src/main/ets/widget/` 的 V1 卡片渲染孤岛与两个 ability —— 它们受 `form_config.json` / `module.json5` 冻结，且按契约不迁移 V1 → V2。H1 / H2 / H3 与 M1–M8 保留，未随本轮提交。

| 项 | 结果 |
| --- | --- |
| `Preview2x4SingleGame.ets` | 361 → 218L：9 段内联数据行收敛为 `@Builder extraRow(label, value, valueColor)`；5 段派遣头像收敛为 `@Builder expeditionAvatar(completed)` |
| `Preview4x4SingleGame.ets` | 246 → 238L：两组 `ForEach` 中重复的数据行收敛为 `@Builder dataRow(row)`；删除未使用的 `StaminaColorType` 导入 |
| `Preview1x2Content.ets` | 72L：删除未使用的 `StaminaColorType` 导入 |
| 编译 | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 15s 218ms`，安装/启动成功 |
| 冒烟 | ✅ 2026-11-07 模拟器实测：1x2 / 2x2 / 2x4 / 4x4 预览均正常渲染，布局与重构前一致 |
| 已知显示缺陷（非本轮引入） | ✅ 已修复（`db33854`）：四个预览组件的 UID 行改为 `Text() { Span($r('app.string.widget_uid_prefix')); Span(this.roleId) }`，模拟器实测 1×2 / 2×2 / 2×4 / 4×4 均显示 `UID 109050292`。根因是 `widget_uid_prefix` 资源值为 `"UID "`（无 `%s`），`$r(..., this.roleId)` 的格式化参数被丢弃 |

### V1 卡片 View 拆分执行记录（2026-11-09）

> 本轮只拆 `entry/src/main/ets/widget/views/Widget4x4SingleGame.ets`，未改 `widget/pages/`、`widget/viewmodel/`、`form_config.json` 与 ability。

| 项 | 结果 |
| --- | --- |
| `Widget4x4SingleGame.ets` | 337 → **131L**：只保留 `role`、分组切分（`getGroup1` / `getGroup2`）与区块组装 |
| 新增 `Widget4x4Header.ets` | 65L：游戏色圆点 + 游戏名 + UID 行 |
| 新增 `Widget4x4StaminaBlock.ets` | 112L：体力标签 / 数值 / 恢复时间 / 星铁后备开拓力 + 底部分隔线 |
| 新增 `Widget4x4ExtraRowsGroup.ets` | 75L：区块 2 / 区块 3 原为同构代码，合并为一个组件，`showBottomBorder` 控制分隔线 |
| 新增 `Widget4x4ExpeditionBlock.ets` | 124L：原神派遣头像（`memory://` → 网络 URL → 渐变占位三级兜底 + 完成态遮罩与勾勾） |
| 体系一致性 | 全部 `@Component`（V1）+ `@Prop`，与 `Widget2x2*` 既有子组件一致；未引入 HSP 导入或网络依赖 |
| 编译 | ✅ `hvigorw assembleHap -p product=uat -p buildMode=debug` → `BUILD SUCCESSFUL` |
| 安装 | ✅ `bash run.sh uat` 安装/启动成功 |
| 冒烟 | 🔶 模拟器桌面不接受注入的长按事件，无法进入编辑态添加卡片；4×4 桌面渲染待真机/手动确认 |

### 2×4 / 4×4 共享组件合并执行记录（2026-11-09）

> 只合并 2×4 与 4×4 之间结构一致的重复；`WidgetExtraDataRows`（2×2 在用）与 1×2 内容组件未改动。

| 项 | 结果 |
| --- | --- |
| `WidgetDataRow.ets`（64） | 单行「标签 + 值」；`fontSize` / `labelOpacity` / `valueFontWeight` 三个样式参数，替换 2×4 右侧列与 4×4 分组内的两份内联 Row |
| `WidgetExpeditionAvatar.ets`（126） | 单枚派遣头像；`avatarSize`（24 / 32）派生勾勾 10/12、字号 7/8、描边 1.5/2；替换两份 60+ 行实现 |
| `Widget2x4InfoColumn.ets`（106） | 2×4 左侧角色信息列（游戏名 / 角色名 / UID / 体力 / 恢复时间） |
| `Widget2x4SingleGame.ets` | 282 → **152L** |
| `Widget4x4ExpeditionBlock.ets` | 124 → 64L（ForEach 内改用共享头像） |
| `Widget4x4ExtraRowsGroup.ets` | 75 → 63L（ForEach 内改用共享数据行） |
| 命名注意 | 头像组件属性不能叫 `size`，与 `CustomComponent.size` 通用属性冲突，改用 `avatarSize` |
| 编译 | ✅ `hvigorw clean assembleHap -p product=uat -p buildMode=debug` → `BUILD SUCCESSFUL` |
| 安装 | ✅ `bash run.sh uat` 安装/启动成功，hilog 无异常 |
| 冒烟 | 🔶 桌面卡片渲染待真机确认（2×4 单游戏 / 4×4 单游戏 / 4×4 多游戏三种用法） |

### `WidgetExtraDataRows` 接入共享数据行（2026-11-11）

> 上一轮为控制回归面未动 2×2 卡片；本轮把 2×2 使用的 `WidgetExtraDataRows` 也切到 `WidgetDataRow`，消除第三份数据行实现。

| 项 | 结果 |
| --- | --- |
| `WidgetDataRow.ets` | 64 → **69L**：新增 `labelMaxLines`（0 = 不限制，内部按 99 处理），承接 2×2 的标签单行省略 |
| `WidgetExtraDataRows.ets` | 115 → **108L**：`ForEach` 内改用 `WidgetDataRow`（`fontSize: theme.font11` / `labelOpacity: OPACITY_TEXT_SECONDARY` / `valueFontWeight: Bold` / `labelMaxLines: 1`） |
| 行为不变量 | 2×2 的字号 11、标签透明度 0.55、值加粗、标签单行省略均保持原样 |
| 编译 | ✅ `hvigorw assembleHap -p product=uat -p buildMode=debug` → `BUILD SUCCESSFUL` |
| 冒烟 | 🔶 2×2 桌面卡片渲染待真机确认（模拟器无法进入桌面编辑态） |

### 预览组件去重执行记录（2026-11-11）

> 预览侧是 V2 体系，无法复用 entry 的 V1 卡片组件，只能在预览内部去重。本轮只动 `features/widget/src/main/ets/views/preview/`，未改 entry 的卡片渲染。

| 项 | 结果 |
| --- | --- |
| `PreviewExtraDataRow.ets` | 32 → **63L**：新增 `fontSize` / `labelOpacity` / `valueFontWeight` / `valueOpacity`（默认值保持 2×2 的 11 / 0.55 / 400 / 0.95）；导出 `PreviewExtraRow` 数据模型 |
| 新增 `PreviewExpeditionAvatar.ets` | **56L**：渐变占位头像 + 可选完成勾勾；`avatarSize`（24 / 32）派生勾勾 10/12、字号 7/8 |
| `Preview2x4SingleGame.ets` | 221 → **194L**：删除 `@Builder extraRow` / `@Builder expeditionAvatar`；数据行改为 `getExtraRows(gameId)` + `ForEach` |
| `Preview4x4SingleGame.ets` | 241 → **221L**：删除 `@Builder dataRow` 与本地 `ExtraRow` 类，改用共享 `PreviewExtraRow` |
| 行为不变量 | 行内容 / 行序 / 字号 / 透明度 / 字重、勾勾位置与尺寸均与改造前逐项一致 |
| 编译 | ✅ `hvigorw assembleHap -p product=uat -p buildMode=debug` → `BUILD SUCCESSFUL` |
| 冒烟 | ✅ 应用内「我的 → Widget 卡片」实测 2×2 / 2×4 / 4×4 预览渲染与改造前一致 |

### M1 性能项执行记录（2026-11-11）

> 只改 6 个 Widget 页面的数据读取方式，不动组件接口、`form_config.json`、ability 与 payload 约定。

| 项 | 结果 |
| --- | --- |
| 方案 | 页面内按 payload 字符串缓存：私有字段 `cachedPayloadJson` / `cachedParsed` / `cachedUIState` + `ensureCache()`；`getParsed()` / `getUIState()` 先调 `ensureCache()`。payload 未变化时复用缓存，变化时重建 |
| `Widget2x2.ets` | 单次 build 的 `parsePayload` 调用 **9 → 1**（3 次状态判定 + 6 处 `getUIState()`） |
| `Widget2x4.ets` / `Widget4x4.ets` | 单次 build **7 → 1**（1 次 `getGameIds()` + 6 处 `getUIState()`） |
| `Widget1x2{Genshin,StarRail,ZZZ}.ets` | 单次 build **2 → 1** |
| 行为等价性 | `Widget*ViewModel.buildUIState()` 无 `Date.now()` / `new Date()` 依赖，输入只有 `ParsedPayload`，同一 payload 的解析与 UIState 结果完全确定，缓存不改变渲染结果 |
| 更新路径 | `@LocalStorageProp('payload')` 变化仍触发 build，`ensureCache()` 读到新字符串后重建缓存；payload 未变时返回同一 UIState 引用，子组件跳过无意义重建（收益来源） |
| 计数修正 | M1 原记录"2×2 多游戏分支最多 8 次"应为 **9 次**（3 次状态判定 + `build()` 内 6 处 `getUIState()`），本轮一并修正 |
| 编译 | ✅ `hvigorw assembleHap -p product=uat -p buildMode=debug` → `BUILD SUCCESSFUL in 3 s 58 ms` |
| 冒烟 | 🔶 桌面卡片渲染待真机确认（6 张卡片 × 单/多游戏 × 空数据） |

### M6 / M7 行为修复执行记录（2026-11-12）

> 两项都是行为修复，不改接口、不改 `form_config.json`；提交 `fix(widget): 派遣头像按 URL 判缓存，并发锁提前置位`。

| 项 | 结果 |
| --- | --- |
| M6 问题 | 文件名固定 `${prefsKey}_${i}.png` 且「文件存在即跳过」，首次下载的 5 张派遣头像被永久复用：派遣角色变化 / 换账号 / 多个原神角色时，2×4 与 4×4 卡片显示旧头像 |
| M6 修复 | `downloadAndSave` 额外把源 URL 写入 `${key}_url`；只有「文件存在 **且** URL 相同」才跳过，否则重下。`downloadImage` 打开文件时补 `TRUNC`，避免新图更小时残留旧字节。旧安装没有 `_url` 记录，首次同步会自动重下，纠正历史陈旧头像 |
| M6 不变量 | 文件名 / prefs key / `loadFormImagesSync` 读取方式 / `hasImage` / `hasAllImages` 均不变；文件数仍 ≤ 5，不产生增量垃圾 |
| M7 问题 | `isSyncing` 检查在 `:194`，置位却在 `initCore()` + 两次 `init` 之后：`initCore` 期间连点卡片每次都能通过检查，各自启动一条 `syncAllWidgets` 链 |
| M7 修复 | 冷却检查通过后**同步**置位 `isSyncing = true` 再启动异步链；`initCore` 失败（`.catch`）与同步失败（`finally`）都释放锁，避免锁永久占用 |
| 编译 | ✅ `hvigorw assembleHap -p product=uat -p buildMode=debug` → `BUILD SUCCESSFUL` |
| 冒烟 | 🔶 待真机：派遣角色变化后 2×4 / 4×4 头像应更新；冷却期外连点卡片只触发一次同步（hilog 只出现一条 `handleSyncCall: sync completed`） |

---

## 8. 依赖文件索引

| 方向 | 内容 |
| --- | --- |
| 页面 → ViewModel | 6 个页面各依赖 1 个 ViewModel（1×2 三页共用 `Widget1x2ViewModel`）；2×2 / 2×4 / 4×4 的 ViewModel 再依赖共享构建器 `WidgetRoleStateBuilder` |
| 页面 / 组件 → 工具 | `WidgetPayloadParser`（parsePayload）、`WidgetUtils`（渐变 / 游戏色 / 体力色 / 时间格式化）、`WidgetDataHelper`（额外数据行） |
| 工具 → core | `WidgetDataStoreBuilder`、`WidgetImageDownloader`、`WidgetUpdateNotifier` 依赖 `'core'`（RDB / Logger / Repository）。注意 `WidgetImageDownloader.ets:37` 导入 `core` 的 `Logger`，因此 `EntryFormAbility` 经它**间接导入了 core（HSP）**，与 `EntryFormAbility.ets:5` 头注释"FormExtensionAbility 不能导入 HSP 模块"的自述约束相悖；重构时不要再扩大这条边 |
| ability → widget | `EntryFormAbility` → `WidgetConfigStore` / `WidgetDataStoreManager` / `WidgetPayloadBuilder` / `WidgetImageDownloader` / `WidgetMockData`；`WidgetSyncAbility` → 同上 + `WidgetDataStoreBuilder` / `WidgetUpdateNotifier` |
| notification → widget | **已无直接依赖**（2026-11-13 复核）：`features/notification/oh-package.json5` 只声明 `widgetbase`；便笺同步后的卡片刷新走 `basic` 的 `WidgetSyncHook` 回调，实现 `WidgetSyncHandlerImpl` 在 `EntryAbility.onCreate` 注册。原「`StaminaNotificationService` 反向导入 `WidgetDataBuilder` / `WidgetFormIdStore` / `WidgetDataStoreBuilder` 3 条边」已随 M8 与 Hook 改造消失 |

---

*本文档仅分析，不修改代码。*

### 复核记录（2026-10-26 第 4 轮）

| 检查项 | 结论 |
| --- | --- |
| 体量 | `widget/` 40 文件 6,947 行（pages 6·596 / components 10 / viewmodel 4 / models 4 / utils 16）+ 2 个 ability（EntryFormAbility 286、WidgetSyncAbility 261）= 42 文件 7,494 行 |
| 装饰器 | 16 个 V1 文件（6 pages + 10 components），无同文件混用；`WidgetUtils.ets` 仅在注释提及 `@Component` |
| 锚点 | `WidgetUpdateNotifier.ets:73/120/137`（失败即删配置、401\|16500050）、`EntryFormAbility.ets:184`（mock 兜底）、`WidgetPayloadBuilder.ets:77`（`updatedAt`）全部命中 |
| 结论 | 0 Critical / 3 High / 6 Medium / 3 Low，债务 24，评级 B（第 5 轮已更新，见下） |

### 复核记录（2026-10-27 第 5 轮）

| 检查项 | 结论 |
| --- | --- |
| 体量 | `wc -l` 重核：42 文件 7,494 行，各表行数全部一致 |
| 锚点修正 | `@LocalStorageProp` `Widget2x2.ets:24→26`；同步循环 `:88-120→:105-118`；`WidgetMockPayload.ets:17-30→18-26/31-44`；M1 行号重算 |
| 事实修正 | V2 注释文件数 10→9 组件 + 3 页面；"只下载 https" 无代码依据；H3 的 `updatedAt` 是推送时刻；M6 由"`filesDir` 只增不减"改为"头像内容永不更新"；L2 / L3 描述按代码修正；M1 建议去掉 V1 不可用的 `@Local` |
| 新增 | M7 并发锁置位过晚（`WidgetSyncAbility.ets:194/220`）、M8 `WidgetFormIdStore` 无写入方（`WidgetFormIdStore.ets:51` 零调用） |
| 结论 | 0 Critical / 3 High / 8 Medium / 3 Low，债务 9+16+3=**28**，评级 **B**；源行数 7,494，密度 0.37 |

### 复核记录（2026-10-27 第 6 轮）

| 检查项 | 结论 |
| --- | --- |
| 第 5 轮改动对抗复核 | 逐条回到代码核实：M7（`WidgetSyncAbility.ets:194` 检查 / `:220` 置位）、M8（`WidgetFormIdStore.save()` 全工程零调用，`widget_form_ids` 仅 `init`/`remove`/读取；`WidgetConfigStore` 用的是另一文件 `widget_configs`）、M2 失败计冷却（`:121-125/131-134/224`）、M6 存在即跳过（`WidgetImageDownloader.ets:87-105`）、H3 推送时刻（`WidgetPayloadBuilder.ets:77`）均成立，行号命中 |
| 修正 | M1"多游戏分支最多 9 次"→ **8 次**（`:57/61/63` 3 次 + `:70/71/75/85/86` 5 次） |
| 结论 | 计数不变：0 Critical / 3 High / 8 Medium / 3 Low，债务 28，评级 B；源行数 7,494（`widget/` 6,947 + 两个 ability 547），密度 0.37 |

### 复核记录（2026-11-12 第 7 轮，M6 / M7 修复后）

| 检查项 | 结论 |
| --- | --- |
| 行数复核 | `wc -l`：`WidgetImageDownloader.ets` 479 → **489**（+10：URL 记录与 `TRUNC` 注释）、`WidgetSyncAbility.ets` 261 → **263**（+2：锁前置与失败释放）；`widget/` 合计 6,947 → **6,957**，子系统合计 7,506 |
| M6 命中 | `downloadAndSave` 内新增 `${key}_url` 写入与比对；`downloadImage` 的 `openSync` 已含 `OpenMode.TRUNC`（`:430-431`）；文件名 / prefs key / `loadFormImagesSync` 读取方式未变 |
| M7 命中 | `isSyncing` 检查 `:191`、置位 `:209`（在 `initCore()` 之前）、`.catch` 释放 `:236`、`finally` 释放 `:230`；冷却检查仍在置位之前 |
| 结论 | 计数更新：0 Critical / 3 High / 6 Medium（M1 / M6 / M7 关闭后）/ 3 Low，评级 B；债务 24，密度 24 ÷ (7,506/100) ≈ 0.32 |

### 复核记录（2026-11-13 第 8 轮，M8 删除后）

| 检查项 | 结论 |
| --- | --- |
| 删除范围 | `WidgetFormIdStore.ets`（141 行）、`WidgetDataBuilder.ets`（228 行）、`WidgetFormIdStore.test.ets`（3 条用例）删除；`features/widget/Index.ets` 去掉 `WidgetFormIdStore` 导出；全仓 `WidgetFormIdStore` / `WidgetDataBuilder` / `formIdFromStorageKey` 零引用（仅 `WidgetGameSnapshotModel` 头注释改为 `WidgetPayloadBuilder`） |
| 调用方 | `WidgetSyncHandlerImpl` 只剩 `refreshAndSave`（`CoreInitializer` import 一并删除）；`WidgetSyncHook` 去掉 `init` 接口与静态方法（只为 formId store 存在）；`StaminaNotificationService.init` 去掉 `WidgetSyncHook.init` 调用；`AccountDetailViewModel.deleteAccount` 去掉恒 no-op 的清理与 `widget` 依赖 import |
| 行为等价 | 被删链路原本恒提前返回：`getFormIdsByAccount()` 依赖的 `widget_form_ids` 无写入方。卡片推送一直由 `WidgetDataStoreBuilder.refreshAndSave` → `WidgetUpdateNotifier.notifyAllWidgets` 完成，未受影响 |
| 验证 | `assembleHap`（uat/debug）成功；`widget@default`（76 条）/ `account@default` / `notification@default` / `basic@default` / `entry@default` 单测全绿 |
| 计数 | 0 Critical / 1 High（H3）/ 4 Medium（M2 / M3 / M4 / M5）/ 2 Low，评级 B；债务 13（L2 于 2026-11-15 修复） |
| 体量实测 | `features/widget/src/main/ets/` 43 文件 **6,006 行**（两轮删除前 6,428）、`entry/src/main/ets/widget/` 28 文件 2,703 行、`EntryFormAbility` 270 行、`WidgetSyncAbility` 263 行；旧记录的 7,506 行基线自 M14 预览去重后未再校准，本轮以实测为准 |
| 遗留 | 「删除账号后 `widget_configs` 里指向该账号的 slots 无人清理」是真实缺陷（原 M8 的后果之一），修法需给 `deleteAccount` 传 context 并按 `slot.accountId` 过滤，属行为变更，未随本次提交 |

### 复核记录（2026-11-13 第 9 轮，L1 / S7 日志类清理）

| 检查项 | 结论 |
| --- | --- |
| 死代码确认 | 全仓 `WidgetLog` 只有 1 处引用：`WidgetPayloadBuilder.ets:12` 的 `import { WidgetLog } from '../../utils/WidgetLog'`，文件内无任何 `WidgetLog.` 调用 |
| 处理 | 删除 `features/widget/src/main/ets/utils/WidgetLog.ets`（53 行）与该未使用 import；日志统一走 `widgetbase` 的 `WidgetLogger`（含 release 环境降级），卡片进程仍不依赖 core（HSP） |
| 体量 | `features/widget/src/main/ets/` 44 → **43 文件**，6,060 → **6,006 行** |
| 验证 | `assembleHap`（uat/debug）成功；`widget@default` 76 条单测全绿 |

### 复核记录（2026-11-17 第 10 轮，H3 数据新鲜度）

| 检查项 | 结论 |
| --- | --- |
| 根因确认 | 原 `WidgetPayloadBuilder.ets:77` 写 `updatedAt = Date.now()`（推送时刻），`WidgetDataStore.updatedAt` 未进入 payload；6 个页面 / 10 个组件均未渲染它 |
| 关键修正 | 仅把 `dataStore.updatedAt` 写进 payload 不够：`buildFromDB()` 每次冷启动都会把 `store.updatedAt` 刷成「构建时刻」。因此新增 `WidgetSlotSnapshot.updatedAt`，取便笺行 `updateTime`（真实拉取时间），payload 取本次展示 slot 的最早值 |
| 数据时间口径 | `buildSlotData()` 写 `slot.updatedAt = dailyNote.updateTime`；`buildFromDB()` 的 `store.updatedAt` = 所有有数据 slot 的最早时间；`saveWidgetsConfig()` 不再改 `updatedAt` |
| 渲染 | `widgetbase` 新增 `formatUpdatedAtText` / `formatUpdatedAtCompactText` / `isWidgetDataStale`（卡片进程不依赖 core）；2×2 紧凑文案、2×4 / 4×4 完整文案；超 1 小时用 `color_warning` 高亮；1×2 空间不足不显示 |
| 兼容性 | slot JSON 新增 `updatedAt?` 为可选字段，旧 `widget_data` 反序列化为 0（不显示新鲜度）；payload 键名、`form_config.json`、V1 装饰器均未改 |
| 验证 | `assembleHap`（uat/debug）BUILD SUCCESSFUL；`widget@default` 79 条、`widgetbase@default` 100 条、全量 898 条单测全绿；6 张卡片的实际视觉与超时高亮待真机回归 |
| 计数 | 0 Critical / **0 High** / 4 Medium / 1 Low，评级 **A**；债务 9，密度 9 ÷ 94.39 ≈ 0.10 |

### 复核记录（2026-11-18 第 11 轮，模拟器运行时验证）

| 检查项 | 结论 |
| --- | --- |
| 触发方式 | 首次在模拟器（Mate 80 Pro Max / HarmonyOS 6.0.2(22)）安装 uat 包并启动，从 `hilog` 观察 `WIDGET_UPDATE` 实际行为 |
| 发现问题 | 每轮同步固定刷出 4 条 `pushUpdate error ... code=16501001 The ID of the form to be operated does not exist` + 4 条 `keeping config`。桌面删卡后系统返回的是 **16501001**，而 `classifyPushError()` 只认 `401` / `16500050`，被误判为可重试失败 |
| 影响 | 失效 `formId` 永久留在 `widget_configs`，每轮同步白跑 4 次 IPC、刷 8 行日志，且配置永不清理 |
| 修复 | `classifyPushError()` 把 `16501001` 并入 `WIDGET_REMOVED`（`5b6d0a9`） |
| 验证 | 首轮 `notifyAllWidgets: done, success=1 removed=4 failed=0`；后续两轮 `found 1 widgets` / `removed=0 failed=0`，不再出现 `16501001` |
| 计数 | 0 Critical / 0 High / 4 Medium / 1 Low，评级 **A**；`widget` 单测 79 → 80 条 |
| 遗留 | 6 张卡片在真机的实际视觉、超时高亮、派遣头像仍需真机验证，见 [`device-regression-checklist.md`](./device-regression-checklist.md) §2 |

### 复核记录（2026-11-19 第 10 轮：绝区零体力 0/160 + 卡片点击）

| 检查项 | 结论 |
| --- | --- |
| 现象 | 4×4 卡片绝区零显示 `0/160 已回满`，App 内是 `65/240`；点击卡片不打开 App |
| 根因 1（数据） | `ZZZRepository.doSyncDailyNoteWidget` 构造的新行只填 `widgetRawJson`，而 `ZZZDailyNoteDao.upsert` 是 `INSERT OR REPLACE` 整行覆盖 → 普通便笺写入的 `raw_json` 被清空。实测 UAT 库：`energy_current=65`、`energy_max=240`、`raw_json` 长度 **0**、`widget_raw_json` 长度 1655 |
| 根因 2（解析） | `WidgetPayloadUtil.parseStaminaData` 只读 `rawJson`，为空时保留默认 `currentStamina=0 / maxStamina=160 / recoverySeconds=0`；`formatRecoveryTime(0, false)` 又把 0 秒判为已满 → 显示 `0/160 已回满` |
| 根因 3（点击） | 6 张卡片都发 `postCardAction({ action: 'call', abilityName: 'WidgetSyncAbility' })`，该 Ability 不 `loadContent`，点击只触发后台同步，永远不打开 App |
| 修复 1 | `doSyncDailyNoteWidget` 先 `findOne` 已有行，`parseZZZDailyNoteData` 新增 `existing` 参数，保留 `rawJson` 与 Widget 接口缺失的 `energy` / `vitality` / `vhs_sale` / `card_sign` 字段 |
| 修复 2 | `parseStaminaData` 拆成 `parseStaminaFromJson`，`rawJson` 解析不到体力时回退 `widgetRawJson`；`WidgetPayloadBuilder.resolveUpdatedAt` 判空同时看两个 JSON |
| 修复 3 | 6 张卡片改 `router` → `EntryAbility`，`params: { from: 'widget' }`；`EntryAbility.onCreate`（`registerReadyHook` 内）与 `onNewWant` 检测后调用 `WidgetSyncHook.onDailyNotesSynced` 刷新卡片 |
| 验证 | 模拟器 UAT 包：卡片由 `0/160 已回满` 变为 `66/240 / 17小时18分钟后回满`；点击卡片成功打开 App 首页；`widgetbase` 102 条（+2）、`widget` 80 条、`core` 250 条本地单测全绿 |
| 遗留 | `WidgetSyncAbility` 当前无调用方，是否删除或改为「长按菜单同步」待决策；1×2 卡片点击已在同批次补上直达详情页 |

### 复核记录（2026-11-20 第 11 轮：孤儿代码清理）

| 检查项 | 结论 |
| --- | --- |
| 删除 1 | `WidgetSyncAbility.ets`（263 行）删除；`module.json5` 移除 ability 注册与 `KEEP_BACKGROUND_RUNNING` 权限；`string.json` 移除 `permission_reason_keep_background` / `WidgetSyncAbility_desc` / `WidgetSyncAbility_label` |
| 删除 2 | `WidgetMockPayload.ets`（45 行）及其单测（58 行）删除，`features/widget/Index.ets` 导出与 `List.test.ets` 引用同步移除 |
| 删除 3 | `WidgetDataStoreBuilder.updateRoleRawJson()`（约 60 行）与其专用私有方法 `parseGameId()` 删除；`WidgetDataStore.updateRoleRawJson()` 是模型层方法且有单测覆盖，保留 |
| 保留 | `TestPage` 不是孤儿：DEBUG 构建「我的」菜单可进，`custom_router_map.json` 注册了路由，是 Cookie 过期手工测试入口 |
| 不影响自动刷新 | App 内 30 分钟联网刷新在 `HomeViewModel.startAutoRefresh()`（`AppConstants.AUTO_REFRESH_INTERVAL_MS`），与本次删除无引用关系；卡片侧 `updateDuration: 1` 仍只重绘本地缓存 |
| 验证 | `widget` 80 条、`widgetbase` 102 条单测全绿；default / uat 构建通过 |

### 复核记录（2026-11-23 第 12 轮：M4 `onAddForm` 时间窗口）

| 检查项 | 结论 |
| --- | --- |
| 原问题 | `onAddForm` 同步链路包含 Preferences 读取、payload 构建、派遣头像 fd 读取，全部压在主线程；宿主只给 10 秒，超时会直接添加失败，且没有耗时数据 |
| 修复 1（按尺寸） | 只有 2×4 / 4×4（`dimension` 3 / 4）才调用 `loadFormImagesSync`；1×2 / 2×2 直接返回空 map。全仓只有 `Widget2x4SingleGame` / `Widget4x4ExpeditionBlock` 使用 `WidgetExpeditionAvatar`，小尺寸本就不渲染派遣头像 |
| 修复 2（时间预算） | 读图片前检查已耗时，≥3 秒则跳过图片，优先保证 `onAddForm` 按时返回（空 map 只影响头像，显示占位图） |
| 修复 3（可观测） | 新增分段日志 `total / config / store / payload / images`；总耗时 ≥3 秒打 warn，便于后续定位 |
| 模拟器实测（UAT） | 2×2：`total=5ms payload=0ms images=0ms imagesLoaded=0`；2×4：`total=1ms images=1ms imagesLoaded=5`；1×2：`total=10ms images=0ms`（首次 config 初始化 8ms）；新加 2×2 绝区零卡正常显示 49/240，4×4 卡 5 个派遣头像正常 |
| 单测 | `entry` 47 条、`widget` 77 条全绿 |
| 未改动 | Preferences 同步读取与 payload 构建保持原样：卡片最多 2 个 slot，payload 构建成本有界；本次只去掉小尺寸无意义的图片 fd 读取并补上保护与度量 |

【已核对代码一致性】
