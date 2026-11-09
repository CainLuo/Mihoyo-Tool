# Widget 子系统分析（M14）

> **分析对象**：`entry/src/main/ets/widget/`（40 个文件 / 6,947 行）+ `entryformability/EntryFormAbility.ets`（286 行）+ `widgetsyncability/WidgetSyncAbility.ets`（261 行）
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
| High | 3 |
| Medium | 8 |
| Low | 3 |

**整体评级：B**

> 架构本身是清楚的：主应用写「数据仓」→ 卡片进程读 payload → 6 个页面各自经 ViewModel 构建 UIState → V1 组件渲染。**没有崩溃级缺陷，但有三处会直接伤害"桌面卡片"这个核心场景**：更新失败会把用户的卡片配置删掉（H1）、无数据时展示伪造的"测试账号"（H2）、卡片从不显示数据有多旧（H3）。三条都不影响主应用，只影响卡片，所以历史上一直没被页面级评审覆盖。2026-10-27 复核另补 2 条 Medium：点击同步的并发锁置位过晚（M7）、`WidgetFormIdStore` 无写入方导致两条调用链空转（M8）。
>
> 另有结构性事实需要先说清楚：widget **是 V1 孤岛**（16 个文件使用 `@Component`，0 个 `@ComponentV2`），这是卡片渲染引擎的限制，不是技术债——本轮重构**不迁移**装饰器。

---

## 1. 文件清单

### 1.1 页面（6，全部是 `form_config.json` 的 `src`）

| 文件 | 行数 | 尺寸 | 布局 |
| --- | --- | --- | --- |
| `widget/pages/Widget1x2Genshin.ets` | 85 | 1×2 | 单角色迷你卡（原神） |
| `widget/pages/Widget1x2StarRail.ets` | 85 | 1×2 | 单角色迷你卡（星铁） |
| `widget/pages/Widget1x2ZZZ.ets` | 85 | 1×2 | 单角色迷你卡（绝区零） |
| `widget/pages/Widget2x2.ets` | 112 | 2×2 | 单游戏详细 / 双游戏上下分栏 |
| `widget/pages/Widget2x4.ets` | 113 | 2×4 | 单游戏横排 / 双游戏左右分栏 |
| `widget/pages/Widget4x4.ets` | 116 | 4×4 | 单游戏大卡 / 双游戏上下分栏 |

### 1.2 ViewModel（4，588 行）

| 文件 | 行数 | 职责 |
| --- | --- | --- |
| `widget/viewmodel/Widget1x2ViewModel.ets` | 83 | 按 `gameId` 过滤后取首个角色 |
| `widget/viewmodel/Widget2x2ViewModel.ets` | 169 | 单游戏详细态 / 多游戏最多 2 个 |
| `widget/viewmodel/Widget2x4ViewModel.ets` | 169 | 同上，横向布局态 |
| `widget/viewmodel/Widget4x4ViewModel.ets` | 167 | 同上，大卡态 |

### 1.3 组件（17，1,554 行）

`Widget1x2ContentView`（121）· `Widget2x2Header`（56）· `Widget2x2SingleGame`（99）· `Widget2x2StaminaBlock`（53）· `Widget2x2StandardStamina`（70）· `Widget2x2StarRailStamina`（91）· `Widget2x4SingleGame`（152）· `Widget2x4InfoColumn`（106）· `Widget4x4SingleGame`（131）· `Widget4x4Header`（65）· `Widget4x4StaminaBlock`（112）· `Widget4x4ExtraRowsGroup`（63）· `Widget4x4ExpeditionBlock`（64）· `WidgetDataRow`（64）· `WidgetExpeditionAvatar`（126）· `WidgetEmptyContent`（66）· `WidgetExtraDataRows`（115）

### 1.4 模型（4，973 行）

| 文件 | 行数 | 职责 |
| --- | --- | --- |
| `widget/models/WidgetModels.ets` | 134 | 原始 JSON 结构 + payload 中间模型 |
| `widget/models/WidgetUIStates.ets` | 236 | 各尺寸 UIState（被测试直接引用） |
| `widget/models/WidgetConfig.ets` | 151 | 单个卡片的配置（尺寸 / slots / formName） |
| `widget/models/WidgetDataStore.ets` | 452 | 全局数据仓（账号 → 角色 → rawJson），写入 `preferences` |

### 1.5 工具（16，3,474 行）

| 分组 | 文件（行数） |
| --- | --- |
| **数据构建** | `WidgetDataBuilder`（228）· `WidgetDataStoreBuilder`（365）· `WidgetPayloadBuilder`（358） |
| **数据解析** | `WidgetPayloadParser`（395，被测试引用）· `WidgetDataHelper`（497，被测试引用） |
| **存储** | `WidgetDataStoreManager`（164）· `WidgetConfigStore`（127）· `WidgetFormIdStore`（132） |
| **推送** | `WidgetUpdateNotifier`（146） |
| **图片** | `WidgetImageDownloader`（479） |
| **展示工具** | `WidgetUtils`（315）· `WidgetExtraRowConfig`（55，被测试引用）· `WidgetExtraRowType`（35，被测试引用） |
| **日志 / 调试** | `WidgetLogger`（80）· `WidgetLog`（53）· `WidgetMockData`（45） |

### 1.6 子系统外的两个 ability

| 文件 | 行数 | 角色 |
| --- | --- | --- |
| `entryformability/EntryFormAbility.ets` | 286 | 卡片生命周期：`onAddForm` 同步返回初始数据、`onUpdateForm` / `onFormEvent` 推送、`onRemoveForm` 清配置 |
| `widgetsyncability/WidgetSyncAbility.ets` | 261 | 卡片点击触发的 `call` 事件：拉取全部账号便笺 → 刷新数据仓 → 推送全部卡片 |

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
widgetsyncability/WidgetSyncAbility.ets    卡片点击 → 后台同步入口
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

6 个页面都用同一套写法：`payload` 字符串 → `parsePayload()`（2×2 / 2×4 / 4×4 经页面私有 `getParsed()`，1×2 三页直接在 `getUIState()` 内调用）→ ViewModel 静态方法 → 组件。ViewModel 完全无状态，可单测（4 个里只有 `Widget2x2ViewModel` 有测试）。

### 2.5 点击刷新链路

```
卡片 onClick
  → postCardAction({ action: 'call', abilityName: 'WidgetSyncAbility', method: 'sync' })
  → WidgetSyncAbility.onCreate 注册的 callee.on('sync')
      → isSyncing 并发锁（模块级变量，WidgetSyncAbility.ets:46；检查在 :194，置位却在 initCore 完成后的 :220，见 M7）
      → 冷却检查：widget_last_sync_time 距今 < 30 分钟则拒绝（:40 / :204）
      → 立即返回 SyncParcelable(true, 'Sync started')（:237）
      → 异步：CoreInitializer.initCore() → syncAllWidgets()
          → 遍历 账号 × 角色，逐个 syncDailyNote（:105-118）
          → WidgetDataStoreBuilder.refreshAndSave()
          → WidgetUpdateNotifier.notifyAllWidgets()
```

**关键时序**：`call` 的返回值和同步是否成功**没有关系**——返回 `'Sync started'` 时同步才刚开始，卡片侧拿不到最终结果。

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

`Widget2x2` / `2x4` / `4x4` 三个 ViewModel 都是"空态 → 单游戏详细态 → 多游戏最多 2 个"，差异只在 UIState 类型和 stamin 区块选择。`Widget1x2ViewModel` 是"按游戏过滤取首个"。**同构但类型不同**（ArkTS 无泛型 UIState），合并收益低、风险高。

### 4.4 真正可去的重复

| 重复 | 证据 | 建议 |
| --- | --- | --- |
| 两套 logger | `WidgetLog`（53 行，仅 `WidgetPayloadBuilder` 用）与 `WidgetLogger`（80 行，4 处用）职责完全重叠 | 合并为 `WidgetLogger`（可逆、低风险） |
| 主题常量 | `WidgetUtils` 内自带 `WidgetColors` / 渐变函数，与 `theme/DefaultTheme` 有重叠取值 | 保留（卡片进程不适合依赖单例主题），仅记录 |
| 1×2 三页 | §4.1 | 可抽出 `Widget1x2Page(gameId)` 共享页面壳；但**页面名被 `form_config.json` 的 `src` 冻结**，只能"内部共享"，不能改文件名 |

---

## 5. 安全审查

| 项 | 结论 |
| --- | --- |
| **凭据落盘** | ✅ 干净。`WidgetDataStore` / `WidgetPayloadBuilder` / `WidgetPayloadParser` / `WidgetModels` 中 **grep `cookie` / `token` 无命中**；数据仓只存 `accountId` / `accountName` / `roleId` / `nickname` / `server` / `rawJson`（便笺原始 JSON） |
| **网络请求** | ⚠️ 仅 `WidgetImageDownloader` 走网络，下载派遣头像；`http.createHttp()` 在 `finally` 里 `destroy()`（`WidgetImageDownloader.ets:401/434`）。但 URL 直接取自便笺 `rawJson` 的 `avatar_side_icon`（`:468`），**没有 scheme / 域名校验**，并非"只下载 `https://`"；来源是米游社接口，风险低 |
| **明文存储** | ⚠️ `preferences: widget_data` 是明文 JSON，但内容不含凭据，可接受 |
| **日志** | ⚠️ `syncAllWidgets` 打印 `uid` / `roleId` / `gameId`（`WidgetSyncAbility.ets:107` 起），属中等敏感度；没有打印 cookie |
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

**H2 · 无数据时卡片展示伪造的账号与体力**

- **位置**：`EntryFormAbility.ets:183-186`（`!dataStore.hasData` → `buildMockFormData()`）、`:212-216`、`WidgetMockPayload.ets:18-26`（`buildPayload`）/ `:31-44`（原神便笺假数据）
- **问题**：首次添加卡片、或数据仓为空时，`onAddForm` 返回 `WidgetMockData.buildPayload()` —— 内容是 `"测试账号"` / `"旅行者"` / 树脂 152 / 洞天宝钱 1230 等固定假数据，`payload` 里没有任何 `isMock` 标记。
- **影响**：用户看到的是**看起来完全真实**的体力与恢复时间，无法区分"占位"与"真实数据"。这是产品级误导，不只是调试残留。
- **建议**：Mock 只允许在 `BuildProfile.DEBUG` 下使用；release 下无数据应返回空态 payload（页面已有 `WidgetEmptyContent`）。
- **状态**：✅ 已修复（`bae5b61`）。`EntryFormAbility.buildFormData` 删除 Mock 分支：`!dataStore.hasData` 时只记一条 warn 日志，仍用 `WidgetPayloadBuilder.buildPayload` 返回真实空 payload，卡片走 `WidgetEmptyContent` 空态。生产代码已无 `WidgetMockData` / `WidgetMockPayload` 引用（仅测试与 `features/widget/Index.ets` 导出保留）。

**H3 · 卡片从不显示数据新鲜度**

- **位置**：`WidgetPayloadBuilder.ets:77`（`toLocalStorageRecord()` 写入 `updatedAt = Date.now()`）→ `WidgetPayloadParser.ets:283`（解析出 `updatedAt`）→ **6 个页面与 10 个组件均未使用**；真正的数据时间 `WidgetDataStore.updatedAt`（`WidgetDataStore.ets:216`，由 `WidgetDataStoreBuilder.ets:43/297/316` 写入）**没有进入 payload**
- **问题**：payload 里的 `updatedAt` 是**推送时刻**而非数据拉取时刻，即使渲染出来也只会显示"刚刚"；体力与恢复倒计时也是同步时刻的快照（widget 内无任何按当前时间推算的逻辑）。没有一个组件渲染"更新于 X 分钟前"；叠加 §2.5 的 30 分钟全局冷却、H1 的静默失败、`syncDailyNoteQuietly` 遇到人机验证直接跳过（`WidgetSyncAbility.ets:164-166`），卡片可能长时间停在旧数值上。
- **影响**：用户把陈旧数据当实时数据决策（"还有 160 体力，先打一把"）。
- **建议**：把 `dataStore.updatedAt` 写进 payload（而不是推送时刻），至少在 2×2 / 2×4 / 4×4 的角落显示相对时间；或当 `now - updatedAt > 2×updateDuration` 时给一个降透明度/角标。

### Medium（技术债）

| # | 问题 | 位置 | 说明 |
| --- | --- | --- | --- |
| M1 | `build()` 内反复解析 payload | `Widget2x2.ets:64,70,71,75,85,86`（`build()` 内 `getUIState()` **6 次**）+ `:57/61/63`（`getGameIds` / `getIsEmpty` / `getIsSingleGame` 各再 `getParsed()` 1 次），多游戏分支单次渲染最多 8 次 `JSON.parse`（3 + `:70/71/75/85/86` 5 次）；`Widget2x4.ets:54-89` / `Widget4x4.ets:54-90` 各 6 次 `getUIState()` + `:49` 1 次 `getGameIds()`；1×2 三页各 2 次（`:44/48`） | 每次 `getUIState()` 都 `JSON.parse` 整个 payload 并重建 `ParsedPayload` + UIState。V1 没有 computed，且 `build()` 不能声明局部变量——这是限制下的写法，但可以让页面缓存一次（例如在私有字段里记住上次的 `payloadJson` 与解析结果，`payloadJson` 变化时失效；V1 页面不能用 V2 的 `@Local`） |
| M2 | 30 分钟冷却被所有卡片共享，且失败也计入冷却 | `WidgetSyncAbility.ets:40 / 43 / 204 / 224` | `widget_last_sync_time` 是**单个全局 key**：用户点了 1×2 的卡片后，30 分钟内点任何其他卡片都只得到 "In cooldown"；没有 per-form 刷新。另外 `syncAllWidgets` 自己吞掉全部异常（`:131-134`），`refreshAndSave` 失败也只是 `return`（`:122-124`），所以 `:224` 的时间戳在同步失败时照写，`:227` 的 catch 实际不可达——**一次失败的刷新同样锁 30 分钟** |
| M3 | 同步结果不可见 | `WidgetSyncAbility.ets:237` | `call` 立刻返回 `'Sync started'`，之后失败只写 hilog；卡片侧无法显示"刷新失败" |
| M4 | `onAddForm` 全同步链路压在 10 秒窗口 | `EntryFormAbility.ets:42 / 45-67`（Preferences 同步读 + `loadFormImagesSync` + payload 构建） | 账号 × 角色多时，图片 fd 读取与 payload 构建都在主线程；没有超时保护 |
| M5 | 全量同步是串行双层循环 | `WidgetSyncAbility.ets:105-118` | 账号 × 角色逐个 `await syncDailyNote`，无并发上限、无进度、无总超时；一次点击可能是几十个串行网络请求 |
| M6 | 派遣头像缓存永不更新 | `WidgetImageDownloader.ets:87`（文件名固定为 `${prefsKey}_${i}.png`）、`:91-105`（文件已存在就跳过下载）、`WidgetDataStoreBuilder.ets:234-238`（所有原神角色共用前缀 `exp_avatar`）；`cleanExpiredCache`（`:291`）/ `clearAllCache`（`:257`）/ `clearCache`（`:220`）**全工程无调用点** | 文件名只按序号 0-4 命名且"存在即跳过"，首次下载的 5 张头像会被永久复用：派遣角色变化、换账号、多个原神角色时，2×4 / 4×4 卡片显示的派遣头像都与实际不符。文件数固定 ≤5，并不会"只增不减"，问题是**内容陈旧**而非空间 |
| M7 | 点击同步的并发锁置位过晚 | `WidgetSyncAbility.ets:194`（检查 `isSyncing`）vs `:211-220`（`initCore()` + 两次 `init` 完成后才 `isSyncing = true`）；冷却时间戳在同步结束后才写（`:224`） | `initCore` 期间连点卡片，每次都能通过并发检查与冷却检查，各自启动一条 `syncAllWidgets` 链，造成账号 × 角色的重复请求（更易触发人机验证）与重复推送。应在返回 `'Sync started'` 前同步置位 |
| M8 | `WidgetFormIdStore` 无写入方，两条调用链空转 | `WidgetFormIdStore.ets:51`（`save()`）全工程**零调用**，`widget_form_ids` 永远为空 → `WidgetDataBuilder.ets:46-49` 的 `buildAndPushForAccount` 恒提前返回（由 `StaminaNotificationService.ets:111-112` 调用）；`AccountDetailViewModel.ets:102-105` 删除账号时的卡片清理恒为 no-op | 这是早于 `WidgetConfigStore`（`widget_configs`）的遗留第二套 formId 存储（还自带同名 `interface WidgetConfig`，`WidgetFormIdStore.ets:19`）。后果：AccountDetail 的清理即使命中也只删 `widget_form_ids`，真正生效的 `widget_configs` 里指向已删账号的 slots 从无清理路径；通知服务那条"逐账号推送"实际不推送（真正的推送靠 `refreshAndSave` 内部的 `notifyAllWidgets`，`WidgetDataStoreBuilder.ets:184-187`）。`WidgetDataBuilder.buildPayload` 等其余方法无外部调用方 |

### Low（建议优化）

| # | 问题 | 位置 | 说明 |
| --- | --- | --- | --- |
| L1 | 两套 logger 并存 | `WidgetLog.ets`（53）vs `WidgetLogger.ets`（80） | 职责重叠，`WidgetLog` 只有 1 个调用方 |
| L2 | `onFormEvent` 忽略 `message` | `EntryFormAbility.ets:87-89` | 任何 `formEvent` 都对该 formId 触发 `pushUpdate`，不校验内容；而 6 个页面的点击只发 `action: 'call'`（如 `Widget2x2.ets:104`），从不发 `message`，该回调目前没有触发源 |
| L3 | 页面级只有 1×2 三页有 `@Preview` | `widget/pages/Widget1x2*.ets:73` | 9 个组件文件各有 `@Preview`（`WidgetEmptyContent` 无），但 2×2 / 2×4 / 4×4 页面的空态 / 单游戏 / 多游戏分支组合只能上真机验证；建议补页面级 `@Preview`（不改页面结构） |

---

## 7. 重构执行备注（M14 · Widget 子系统）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。M14 排在最后（§4），因为它是 V1 孤岛且与 ability / notification 双向耦合。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 卡片定义 | `resources/base/profile/form_config.json` 的 6 条 `src` 路径（`./ets/widget/pages/Widget*.ets`）与 `name` 全部冻结；改名 = 卡片在桌面消失 |
| Ability | `module.json5` 的 `EntryFormAbility` / `WidgetSyncAbility` `srcEntry` 冻结 |
| 测试引用（冻结） | `widget/viewmodel/Widget2x2ViewModel`、`widget/models/WidgetUIStates`、`widget/utils/{WidgetPayloadParser,WidgetDataHelper,WidgetUtils,WidgetExtraRowConfig,WidgetExtraRowType}` —— 导出名不得变（§2.5） |
| 装饰器 | **不迁移 V1 → V2**；不新增 `@ComponentV2` 文件 |
| payload 键名 | `'payload'` 是卡片进程与主应用的唯一约定（6 个 `@LocalStorageProp`），不能改名 |
| 数据仓格式 | `widget_data` / `widget_configs` 两个 preferences 文件与 JSON 结构（`version: 2`）不可变，否则已装卡片读不到数据 |

### 重构范围（建议）

- **只做内部整理**：`widget/` 目录已经按 pages/components/viewmodel/models/utils 分好，**不需要搬文件**；本轮最多统一命名（`WidgetLog` → `WidgetLogger` 合并、`WidgetMockData` 明确标注 debug-only）。
- **优先修 H1 / H2**：两处都不改变 UI 结构，H1 是 10 行左右的错误码分支，H2 是一个 `BuildProfile.DEBUG` 判断；建议各自单独提交。
- **H3 需要产品决策**：加"更新于 X 分钟前"会改变卡片视觉，属于行为变更，应单独立项。
- **M1 可以随 M14 做**：页面内缓存 `ParsedPayload`，不改任何组件接口；但要回归 6 张卡片 × 单/多游戏。
- **不要合并 1×2 三页文件**：`src` 冻结，只能抽内部共享 struct。
- **M4 / M5 属于能力增强**（超时、并发、进度），超出"保持行为"的重构边界，记录不执行。
- **M7 / M8 是行为修复**：M7 把 `isSyncing = true` 提前到返回前（几行）；M8 需决定删除 `WidgetFormIdStore` / `WidgetDataBuilder` 遗留链路（同时改 notification 与 AccountDetail 两个调用方，跨 M5 / M11）还是改用 `WidgetConfigStore`，均单独提交。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. DevEco Local Test：`Widget2x2ViewModel` / `WidgetPayloadParser` / `WidgetDataHelper` / `WidgetDataHelperExtraRows` / `WidgetExtraRowConfig` / `WidgetExtraRowType` 六套通过。
3. 冒烟（无自动化，必须真机/模拟器）：6 张卡片各添加一次 → 单游戏 / 双游戏 / 三游戏（应截断到 2）→ 空数据 → 点击刷新 → 冷却期再点 → 主应用同步后卡片自动更新 → 删除卡片后配置清理。
4. H1 修复后额外验证：模拟 `updateForm` 抛非 401 错误，确认卡片配置**仍在**；`401` 时确认被清理。

### 已知问题归属

- **High 3 项**（配置误删、Mock 数据、无新鲜度标识）：H1 / H2 建议随 M14 修，H3 需产品决策。
- **Medium 8 项**（重复解析、全局冷却且失败也计冷却、结果不可见、10 秒窗口、串行同步、派遣头像永不更新、并发锁置位过晚、`WidgetFormIdStore` 空转）：M1 可随模块做；M7 / M8 为行为修复单独提交；其余属增强。
- **Low 3 项**（logger 合并、`formEvent` 校验、预览缺失）：可顺手做。
- **测试空白**：`Widget1x2/2x4/4x4ViewModel`（419 行）、`WidgetDataStore`（452）、`WidgetPayloadBuilder`（358）、`WidgetDataStoreBuilder`（365）、`WidgetImageDownloader`（479）、`WidgetUpdateNotifier`（146）均无单测——即**本子系统 3 个 High 所在的文件全部无测试保护**。

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

---

## 8. 依赖文件索引

| 方向 | 内容 |
| --- | --- |
| 页面 → ViewModel | 6 个页面各依赖 1 个 ViewModel（1×2 三页共用 `Widget1x2ViewModel`） |
| 页面 / 组件 → 工具 | `WidgetPayloadParser`（parsePayload）、`WidgetUtils`（渐变 / 游戏色 / 体力色 / 时间格式化）、`WidgetDataHelper`（额外数据行） |
| 工具 → core | `WidgetDataStoreBuilder`、`WidgetDataBuilder`、`WidgetImageDownloader`、`WidgetUpdateNotifier` 依赖 `'core'`（RDB / Logger / Repository）。注意 `WidgetImageDownloader.ets:37` 导入 `core` 的 `Logger`，因此 `EntryFormAbility` 经它**间接导入了 core（HSP）**，与 `EntryFormAbility.ets:5` 头注释"FormExtensionAbility 不能导入 HSP 模块"的自述约束相悖；重构时不要再扩大这条边 |
| ability → widget | `EntryFormAbility` → `WidgetConfigStore` / `WidgetDataStoreManager` / `WidgetPayloadBuilder` / `WidgetImageDownloader` / `WidgetMockData`；`WidgetSyncAbility` → 同上 + `WidgetDataStoreBuilder` / `WidgetUpdateNotifier` |
| notification → widget | `notification/StaminaNotificationService.ets:17-19` 反向导入 `WidgetDataBuilder` / `WidgetFormIdStore` / `WidgetDataStoreBuilder`（**3 条边**，与 Refactor_Spec §4 M5 的"服务向 widget 扇出 3 条"一致）；widget **不**反向依赖 notification |

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

【已核对代码一致性】
