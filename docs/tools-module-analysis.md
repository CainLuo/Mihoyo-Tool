# Code Review Report · `Tools` Module

> **审查对象**：`features/material/src/main/ets/pages/ToolsPage.ets` + `features/material/src/main/ets/viewmodel/ToolsViewModel.ets` + `features/material/src/main/ets/views/GameEntryCard.ets`
> **审查日期**：2026-10-24
> **审查者**：AI 助手
> **代码版本**：`105c8d3`
> **HarmonyOS SDK**：`6.0.2(22)`（`targetSdkVersion` / `compatibleSdkVersion`，见根 `build-profile.json5`）/ `@ComponentV2`（无 V1 混用）

---

## 模块构成

| 文件 | 角色 | 装饰器模型 |
| --- | --- | --- |
| `ToolsPage.ets` | 页面入口 | `@ComponentV2` |
| `ToolsViewModel.ets` | 数据 + 业务逻辑 | `@ObservedV2` + `@Trace` |
| `GameEntryCard.ets` | 游戏入口卡片组件 | `@ComponentV2` |
| `ToolsModels.ets`（辅助） | `GameEntryVM` 模型定义 | `@ObservedV2` + `@Trace` |

行数（`wc -l`）：`features/material/src/main/ets/pages/ToolsPage.ets` 132 · `features/material/src/main/ets/viewmodel/ToolsViewModel.ets` 171 · `features/material/src/main/ets/views/GameEntryCard.ets` 134 · `features/material/src/main/ets/model/ToolsModels.ets` 135（共享模型文件，`GameEntryVM` 在 `:115-135`）。

### 结构与调用链

```
MainPage.ets:451  Tools({ detailStack })  ← 以 .visibility() 切换，常驻挂载
  ToolsPage.ets
  ├─ aboutToAppear() → vm.loadData()                         :28-31
  ├─ @Monitor('signal.version') → vm.loadData()              :37-40   ← AccountSignal.notify()
  ├─ build(): LOADING → LoadingProgress / EMPTY → PlaceholderView（去登录）/ DATA → ForEach GameEntryCard
  └─ onEntryTap() → detailStack.pushPathByName(MATERIAL_CHARACTER_SELECT, {accountId, roleUid, gameId})  :107-123
ToolsViewModel.loadData()                                     :51-74
  ├─ CoreInitializer.waitForReady()
  ├─ bbsRepository.getAllAccounts()
  └─ buildGameEntries()                                       :82-143
       ├─ 每账号 bbsRepository.getGameRoles()
       └─ 每角色 hasComputeData() → new {Genshin|StarRail|ZZZ}MaterialTargetConfigDao().findOne()  :149-170
```

依赖：`core`（`CoreInitializer` / `AccountRow` / `GameId` / `Logger` / 三个 `*MaterialTargetConfigDao`）、`theme/ThemeManager`、`constants/ViewState` / `AppRoutes`、`utils/AccountSignal` / `GameIdUtil`、`shares/PlaceholderView`、`viewmodel/MaterialCharacterSelectViewModel`（仅 `MaterialCharacterSelectParam` 类型）。

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 6 |
| Low | 2 |

**整体评级：B**（0 High，但 Medium 6 > 5，不满足 A）

> 一句话结论：模块轻量、职责单一，V2 状态管理使用规范；无用户可感知的故障，原 High「`loadData()` 页面销毁后改写状态」经核实 Tools 作为 Tab 页常驻挂载、不会在切 Tab 时销毁，降为 Medium（LIFE-002）；另补登「加载失败显示为登录引导空态」。DAO 重复查询逻辑和硬编码箭头字符可在 P2 阶段清理。
>
> 2026-10-27 复核：原文多处 checklist ID 与 `references/checklist.md` 实际语义不符（PERF-004 = TaskPool、PERF-007 = `@AnimatableExtend`、STATE-008 = `build()` 纯函数、LIFE-004 = 跳转前清理弹窗、ARKTS-013 = ≥100 魔法数字），已改为对应的真实 ID 或标注「自定义」。

---

## 合规检查（skills checklist）

> 逐条对照 `.opencode/skills/harmonyos-review/references/checklist.md`，只列与本模块相关的条目。SEC / PERM / KIT 类不适用（本模块无网络、无权限、无 Kit 直调）。

| ID | 检查项 | 结论 | 证据 / 说明 |
| --- | --- | --- | --- |
| STATE-001 | 不混用 V1 / V2 | ✅ | `ToolsPage.ets` / `GameEntryCard.ets` 为 `@ComponentV2`，`ToolsViewModel` 为 `@ObservedV2`；无 `@State` / `@Prop` / `@Link` |
| STATE-002 | 数组变更替换引用 | ✅ | 三文件无 `.push(` / `.splice(`；`gameEntries` 每次由 `buildGameEntries()` 全量产出后整体赋值 |
| STATE-007 | 回调参数有默认值 | ✅ | `GameEntryCard.ets:15` `@Param onTap = () => {}` |
| STATE-008 | `build()` 是纯函数 | ✅ | `ToolsPage.ets:42-101` / `GameEntryCard.ets:19-68` 无 await / 赋值副作用；`statusText` getter 只读 `entry` |
| PARAM-DEFAULT（自定义） | `@Param` 默认值不构造对象 | ⚠️ Medium | `GameEntryCard.ets:14` `@Param entry: GameEntryVM = new GameEntryVM()`（已记 M4）；checklist 无对应条目 |
| LIFE-001 | `aboutToDisappear` 取消订阅 / 定时器 | ✅（不适用） | 三文件无定时器、无订阅；`ToolsPage.ets` 无 `aboutToDisappear` |
| LIFE-002 | 长任务检查 cancellation token | ⚠️ Medium | `ToolsViewModel.loadData()`（`:51-74`）无代际 / 取消标记，`aboutToAppear` 与 `@Monitor` 触发的多次加载可交错写回（已记 M5） |
| LIFE-004 | 跳转前清理弹窗 / Loading | ✅ | 本模块无弹窗；跳转只走 `detailStack.pushPathByName`（`ToolsPage.ets:66 / 122`） |
| MONITOR-PATH（自定义） | `@Monitor` 路径不硬编码 | ⚠️ Low | `ToolsPage.ets:37` 监听 `'signal.version'` 字符串，`ToolsViewModelKeys`（`ToolsViewModel.ets:33-40`）已就位但未用于此路径（已记 L2） |
| PERF-001 | 无 `forEach + await` | ✅ | `ToolsViewModel` 用 `for` 循环串行 await（串行属 N+1 问题，见 M2） |
| PERF-008 | 列表项带 `key` | ✅ | `ToolsPage.ets:82` `(entry: GameEntryVM) => entry.gameId` |
| ARKTS-012 | 日志走 hilog | ✅ | `hasComputeData` 失败走 `Logger.error`（`ToolsViewModel.ets:167`），无 `console.*` |
| ARKTS-013 | 无 ≥100 魔法数字 | ✅ | 三文件无 ≥100 的字面量 |
| KIT-005 / 错误态 | 失败有可见反馈 | ⚠️ Medium | `ToolsViewModel.ets:69-72` 失败后置 `EMPTY`，页面显示登录引导（已记 M6） |
| TEST-001 | 核心逻辑有单测 | ✅ | `features/material/src/test/ToolsViewModel.test.ets` 4 条用例覆盖初始态；`loadData` / `buildGameEntries` 的异常与取消路径未覆盖（已知缺口） |

> 合规结论：本模块无 High；Medium 6 / Low 2 均为可延后处理的技术债，与风险清单一致。

---

## High Issues（发版前必修）

无。原 High「`loadData()` 无取消标记——页面销毁后仍可能修改状态」经复核降为 Medium，见 Medium 5。

---

## Medium Issues（技术债）

### 1. [DRY（自定义）· Medium] `hasComputeData` 重复 if-else 查询逻辑

- **位置**：`features/material/src/main/ets/viewmodel/ToolsViewModel.ets:149-169`
- **问题**：三个游戏分别 new 不同 Dao 并调用 `findOne()`，代码结构完全相同（仅 Dao 类型和 configJson 字段名一致）。这种复制粘贴模式违反 DRY，增加后续新增游戏的维护成本。
- **建议修复**：提取为泛型或策略方法：

```typescript
// ✅ 改写 — 提取辅助方法
private async hasConfigData<T extends { configJson: string }>(
  dao: { findOne(accountUid: string, roleUid: string): Promise<T | null> },
  accountUid: string,
  roleUid: string
): Promise<boolean> {
  try {
    const config = await dao.findOne(accountUid, roleUid);
    return config !== null && config.configJson !== '';
  } catch { return false; }
}
```

- **参考**：checklist 无 DRY 条目（原标 PERF-004 实为"大计算放 TaskPool"，不符），编号为本目录自定义

### 2. [N+1（自定义）· Medium] `buildGameEntries` 内 N+1 数据库查询

- **位置**：`features/material/src/main/ets/viewmodel/ToolsViewModel.ets:82-140`
- **问题**：外层遍历 accounts、内层遍历 roles，每角色调用一次 `hasComputeData()`（独立 DB 查询）。假设 3 个账号共 20 个角色，需执行至少 20 次 DAO findOne。这些查询相互独立但串行执行。
- **影响**：在低端机型上可能产生明显加载延迟（1-3 秒）；数据库连接池压力随角色数线性增长。
- **建议修复**：批量查询——先将所有 (gameId, accountUid, roleUid) 三元组收集，再按游戏分组执行一次性批量查询，最后映射回结果。

```typescript
// ✅ 思路 — 先收集后批量
const queryKeys = [...roles.map(r => ({ gameId: r.gameId, accountUid: r.uid, roleUid: r.roleId }))];
const results = await this.batchHasComputeData(queryKeys); // 新 API
for (let i = 0; i < roles.length; i++) { /* 用 map 回填 */ }
```

- **参考**：checklist 无 N+1 条目（原标 PERF-007 实为 `@AnimatableExtend`，不符）；`for` 串行 await 不违反 PERF-001

### 3. [STRING-001 · Medium] `GameEntryCard.ets:47` 硬编码箭头字符 '›'

- **位置**：`features/material/src/main/ets/views/GameEntryCard.ets:47`
- **问题**：箭头字符 `'›'` 直接写在代码中，未走 `ResourceStr` 国际化。虽然 UI 效果正确（Unicode RIGHT-POINTING SINGLE ANGLE QUOTATION MARK），但多语言 app 中不同语言可能需要不同箭头（如中文习惯用 ">"）。
- **建议修复**：提取到 `string.json`：

```xml
<!-- string.json -->
<string name="tools_arrow_forward">›</string>
```

```typescript
// GameEntryCard.ets
Text($r('app.string.tools_arrow_forward'))
```

- **参考**：字符串资源规范。注：skills `checklist.md` 的 75 条里**没有**字符串资源条目，`STRING-001` 是本目录自定义编号（见文末《引用规则编号说明》），不要当成 skills 稳定 ID 引用。

### 4. [PARAM-DEFAULT（自定义）· Medium] `GameEntryCard.ets:14` `@Param entry` 默认实例

- **位置**：`features/material/src/main/ets/views/GameEntryCard.ets:14`
- **问题**：`@Param entry: GameEntryVM = new GameEntryVM()` 在组件实例化时构造默认对象。正常路径由 `ToolsPage.ets` 传入真实 entry，但 Preview 或漏传场景会拿到空 entry（`hasData=false`），掩盖漏传问题——与 `AboutSection` 的 `@Param vm = new MyViewModel()` 同类。
- **建议修复**：移除默认值（`@Param entry: GameEntryVM`），Preview 显式传入构造好的 entry；属行为修复，与其他重构分开提交。
- **参考**：checklist 无对应条目（原标 STATE-008 实为"`build()` 是纯函数"，不符），编号为本目录自定义

### 5. [LIFE-002 · Medium] `loadData()` 无代际 / 取消标记，多次加载可交错写回（原 H1，降级）

- **位置**：`features/material/src/main/ets/viewmodel/ToolsViewModel.ets:51-74`；触发点 `ToolsPage.ets:30`（`aboutToAppear`）与 `ToolsPage.ets:37-40`（`@Monitor('signal.version')`）
- **问题**：`loadData()` 是 async 方法，内部依次 await `getAllAccounts()`、`getGameRoles()`（循环）、`hasComputeData()`（每角色一次 DB 查询），没有 generation / disposed 标记。`AccountSignal.notify()` 由登录、删号、刷新 Cookie、三游戏目标配置保存触发（`LoginPage.ets:57`、`AccountDetailPage.ets:34`、`AccountDetailViewModel.ets:84`、`*MaterialTargetConfigViewModel` 各 1 处），每次都会再起一轮加载；两轮交错时后完成者覆盖先完成者，若中间 DB 已变化就可能写回旧结果。另外每轮开头都把 `viewState` 置回 `LOADING`（`:53`），列表会整块闪成转圈。
- **为何不是 High**：原文假设"切 Tab / 页面销毁后仍写状态"，但 `Tools` 在 `MainPage.ets:451-452` 以 `.visibility()` 切换、常驻挂载，切 Tab **不会**销毁；`ToolsPage.ets` 也没有 `aboutToDisappear`。页面真正销毁只随 `Main` 一起，此时写入已无 UI 可见。按 README §1 "用户能否感知故障"的口径，剩下的交错覆盖需要"加载期间 DB 变化 + 先发后至"同时成立，属技术债。
- **建议修复**：加 `loadSeq` 代际号，每轮自增并在每个 await 后比对；`LOADING` 只在首次加载时设置，后续刷新保留旧列表。
- **参考**：`references/checklist.md` § 4 · LIFE-002

### 6. [KIT-005 引申 · Medium] 加载失败被显示为"无账号"登录引导

- **位置**：`features/material/src/main/ets/viewmodel/ToolsViewModel.ets:69-72`（catch 内 `this.viewState = ViewState.EMPTY`）；`ToolsPage.ets:55-70`（`EMPTY` 渲染 `home_placeholder_*` 文案 + "去登录"按钮）
- **问题**：`getAllAccounts()` / `getGameRoles()` 抛错时只打日志，然后进入与"没有账号"相同的 `EMPTY` 分支；已登录用户会看到登录引导，点按钮进入登录页，无错误提示、无重试。与 `WidgetSettings`「`init()` 失败静默回退空配置」同类，按同口径记 Medium。
- **建议修复**：失败时置 `ViewState.ERROR` 并复用 `PlaceholderView` 的重试态；行为变更，单独提交。

---

## Low Issues（建议优化）

| 规则 ID | 文件 | 问题 | 建议 |
| --- | --- | --- | --- |
| DEAD-PARAM（自定义） | `ToolsViewModel.ets:91-98 / 129-130`、`ToolsPage.ets:117-122` | 组装并传给选角页的 `accountId` / `roleUid` 下游不使用：`MaterialCharacterSelectPage.ets:56` 只调 `vm.init(this.param.gameId)`，选角页自己从账号下标 0 取角色。且两者可能不配对（`accountId` 取全局第一个账号，`roleUid` 取该游戏第一个出现的角色，可能属于另一个账号） | 要么删去这两个字段的组装（`MaterialCharacterSelectParam` 同时被 `builders/MaterialCharacterSelectPageBuilder.ets:12-13` 与 `pages/MaterialCharacterSelectPage.ets:31-32` 声明，字段保留、传空即可），要么让选角页真正按它们定位；原 L1（`''` sentinel，ARKTS-013 实为 ≥100 魔法数字）撤回并入此条 |
| MONITOR-PATH（自定义） | `ToolsPage.ets:37` | `@Monitor('signal.version')` 路径硬编码字符串——监听的是 AccountSignal.instance().version（L23 signal），非 ToolsViewModel 自身字段；ToolsViewModelKeys 已存在（L33-40）但当前无需监听，故维持现状 |

---

## 详细分析

### 1. 状态管理架构（STATE 系列）

**✅ 亮点**：
- `Tools` 页面通过 `@Local private vm: ToolsViewModel = new ToolsViewModel()` 持有实例，符合 V2 规范
- `ToolsViewModel` 正确标注 `@ObservedV2`，`viewState`、`accountCount`、`gameEntries` 均标 `@Trace`
- `GameEntryCard` 的 `entry`（数据）和 `onTap`（回调）均使用 `@Param`，但 **`entry` 提供了默认实例 `new GameEntryVM()`**（L14），与 AboutSection 的 `new MyViewModel()` 属同类问题（Medium 4）；`onTap` 的空函数兜底可接受

**⚠️ 注意**：
- `GameEntryVM`（在 ToolsModels.ets 中）也标注了 `@ObservedV2` + `@Trace`。这意味着游戏入口列表中的单个 entry 也能触发细粒度 UI 更新；但当前架构下 entry 是在 `buildGameEntries()` 全量重建的，`@Trace` 在此场景是冗余装饰（不影响正确性）

### 2. 生命周期与资源管理（LIFE 系列）

**✅ 亮点**：
- `Tools.aboutToAppear()` 中执行 `loadData()`——异步加载不阻塞首屏渲染（先显示 LOADING 态）
- 无定时器、无网络手动取消，模块轻量故风险可控

**⚠️ 注意**：
- `Tools` 由 `Main` 以 `.visibility()` 常驻挂载（`MainPage.ets:451-452`），切 Tab 不触发销毁；真正的风险是多次 `loadData()` 交错写回与每次刷新都闪 `LOADING`（Medium 5）

### 3. 条件渲染与 V2 build() 结构

**✅ 亮点**：
- LOADING / EMPTY / DATA 三态通过纯 if-else 分支实现，无多余的 `Visibility` 切换动画干扰 UX
- `PlaceholderView` 作为通用空态组件复用，减少重复代码

**⚠️ 注意**：
- `build()` 中内联了 `Column()` + `LoadingProgress()` 5 行加载视图——可提取为独立的 `@Builder`（ArkTS 严格语法允许使用 `@Builder` 的场合），提升可读性；但考虑到只有 5 行且只在此处使用，维持现状也可接受

### 4. 数据流与 DAO 层交互

**✅ 亮点**：
- `buildGameEntries()` 按游戏汇总角色数量和计算数量，逻辑清晰
- 空账号直接返回 EMPTY 态，不进入后续循环

**⚠️ 注意**：
- `firstAccountUid` 取全局第一个账号、`roleUid` 取该游戏第一个出现的角色，二者可能不属同一账号；但选角页只用 `gameId`（`MaterialCharacterSelectPage.ets:56`），这两个字段目前是死数据（Low 1）
- 加载异常时落到 `EMPTY` 登录引导，而非错误态（Medium 6）

---

## 整体观察

- **代码质量**：模块轻量（ToolsPage.ets ~132 行、ToolsViewModel.ets ~171 行），职责清晰——纯展示层 + 数据装配；无复杂业务逻辑分支
- **架构**：Page → ViewModel → Repository → DAO 分层完整；`GameEntryCard` 组件可复用于其他列表场景
- **状态管理**：全部 V2，无 V1 混用；`@Local` / `@Param` / `@ObservedV2` + `@Trace` 使用正确
- **测试覆盖**：`features/material/src/test/ToolsViewModel.test.ets` 已覆盖初始状态（4 条用例）；`buildGameEntries()` / `loadData()` 的异步与异常路径没有覆盖。`ToolsPreview` / `GameEntryCardPreview` 提供 Preview 支持

---

## 修复建议优先级

| Phase | 任务 | 预估工作量 |
| --- | --- | --- |
| **P0 · 立即** | 无 Critical 项 | — |
| **P1 · 本周** | 无 High 项 | — |
| **P2 · 下迭代** | LIFE-002: `loadData()` 代际号；加载失败改 `ERROR` 态；N+1: 批量查询；DRY: DAO 重复代码提取；PARAM-DEFAULT: 移除 GameEntryCard entry 默认实例 | 半天 |
| **P3 · 长期** | STRING-001: 箭头字符国际化；补充 `loadData()` hypium 单测 | 顺手 |

---

## 复审建议

Medium 5 / 6 修完后执行：
1. `hvigorw assembleHap -p buildMode=debug` — 确认无编译错误
2. DevEco Studio Preview 面板验证 `ToolsPreview` / `GameEntryCardPreview` 渲染正常
3. **关键回归**：在目标配置页保存后返回 Tools，列表不应整块闪成转圈；断开 DB（或 mock 抛错）时应显示错误态而非登录引导

---

## 附录 · 扫描命令记录

```bash
# V2 装饰器一致性检查
grep -rEn "@ComponentV2" --include='*.ets' features/material/src/main/ets/pages/ToolsPage.ets
grep -rEn "@State\b|@Prop\b|@Link\b" --include='*.ets' features/material/src/main/ets/pages/ToolsPage.ets

# @Monitor 路径常量使用
grep -rEn "@Monitor\(" --include='*.ets' features/material/src/main/ets/pages/ToolsPage.ets

# DAO 重复代码定位
grep -rEn "new.*MaterialTargetConfigDao" --include='*.ets' features/material/src/main/ets/viewmodel/ToolsViewModel.ets

# 硬编码字符串检测
grep -rEn "'›'" --include='*.ets' features/material/src/main/ets/
```

---

## 附录 · 引用规则编号说明

| 规则 ID | 优先级 | 说明 |
| --- | --- | --- |
| LIFE-002 | Medium | 长任务无 cancellation / 代际标记（`loadData()` 交错写回） |
| KIT-005 引申 | Medium | 失败路径无可见错误反馈（落到登录引导空态） |
| DRY（自定义） | Medium | DAO 重复查询逻辑；checklist 无对应条目 |
| N+1（自定义） | Medium | N+1 数据库查询模式；checklist 无对应条目 |
| PARAM-DEFAULT（自定义） | Medium | `@Param` 默认值在组件实例化时构造对象（GameEntryCard entry）；checklist 无对应条目 |
| STRING-001（自定义） | Medium | 硬编码字符未走资源文件；skills checklist **无对应条目**，编号仅在本目录内使用 |
| DEAD-PARAM（自定义） | Low | 传给选角页的 `accountId` / `roleUid` 未被使用且可能不配对 |
| MONITOR-PATH（自定义） | Low | `@Monitor` 路径硬编码字符串 |

> 完整规则表见 `.opencode/skills/harmonyos-review/references/checklist.md`

---

## 重构执行备注（M1 · Tools）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。M1 是最小模块，用来演练编译 → codeLinter → Local Test → 冒烟 → 提交的完整闭环。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `Tools` 是底部 Tab 内嵌页，**不在** `custom_router_map.json`；`AppRoutes.TOOLS = 'Tools'` 字符串冻结 |
| 页面入口 | `pages/ToolsPage.ets` 没有 `export function ToolsBuilder`（由 `Main` 直接 import struct）；路径保持不动，M1 不改 `Main` |
| 测试引用（冻结） | `features/material/src/main/ets/viewmodel/ToolsViewModel.ets`、`features/material/src/main/ets/model/ToolsModels.ets`、`constants/ViewState.ets` 被 `features/material/src/test/ToolsViewModel.test.ets` 相对导入，路径与导出符号不得变 |
| 共享组件 | `components/common/PlaceholderView.ets` 属于 M0 共享层，不在 M1 移动 |
| 外部依赖 | `core` 包（`GameId` 等）属于 core 模块，不得改动 |

### 重构范围（建议）

- 现有目录与命名已符合 N-1 / N-2：`features/material/src/main/ets/pages/ToolsPage.ets`、`features/material/src/main/ets/viewmodel/ToolsViewModel.ets`、`features/material/src/main/ets/views/GameEntryCard.ets`。M1 已按「真重构」执行，实际改动见文末「M1 真重构记录（2026-11-02）」，不再以“改动接近 0”为验收目标。
- `ToolsViewModel.ets` 144 行（< 500），不拆分。
- `ToolsModels.ets` 路径与 `GameEntryVM` 导出保持不变；材料养成目标领域模型已拆到 `MaterialTargetModels.ets`，原文件 re-export 兼容既有 import。
- `GameEntryCard.ets` 仅本模块使用；调整限定在 `views/` 内。

### 验收

1. `hvigorw --mode module -p module=entry@default -p product=default -p buildMode=debug assembleHap` 通过。
2. `hvigorw codeLinter` 不新增违规。
3. DevEco Local Test：`ToolsViewModel.test.ets` 的 4 条用例通过（CLI 无 test 任务，见 Refactor_Spec §0.3）。
4. 冒烟：底部 Tab → Tools → 三游戏卡片进入/返回；快速切换 Tab 观察空态闪烁。

### 已知问题归属

- `LIFE-002`（Medium，原 High 降级）：`loadData()` 无代际标记。M1 未修（会改变并发语义），保留在 Refactor_Spec §11 遗留。
- 加载失败落到登录引导（Medium 6）：行为变更，单独提交，M1 未修。
- `N+1`（每个角色一次 `findOne`）：M1 已复用 DAO 实例、去掉每角色 new；批量查询需 core 增加 DAO 方法，留给 core / M7。
- `STRING-001` / `PARAM-DEFAULT`：M1 已修复（资源化箭头、`@Require`）。
- `MaterialCharacterSelectParam` 定义在 ViewModel、由 ToolsPage 直接 import：分层问题，随 M7 角色选择页重构迁移到 model。
- `DEAD-PARAM` / `MONITOR-PATH`：M1 未修，保留记录。

### 文档修正记录（2026-10-24）

- SDK 基线由“API 26 / minSDK API 11”更正为工程实际的 `6.0.2(22)`。
- 补充 Local Test 实际覆盖情况（原文“缺少单测”不准确）。
- Low 计数与 Low Issues 表对齐为 2 条。

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | Tools 132 / VM 171 / 测试 4 条、三态 build()、GameEntryVM @Trace | ✅ |
| 第 2 轮（行号引用） | loadData L51-74、hasComputeData L149-169、'›' L47、@Monitor L37、ToolsViewModelKeys L33-40 | ✅ 修正 2 处（PERF-007 L82-140 / ARKTS-013 L91） |
| 第 3 轮（全面复核） | GameEntryCard @Param 默认值（STATE-008）、执行摘要计数 3→4、附录/优先级/归属同步 | ✅ 修正 1 处 |
| 第 4 轮（2026-10-26 复核） | 补合规检查（11 条 checklist）；复核 `ToolsPage.ets:75-82` ForEach key、`GameEntryCard.ets:14-15` 两个 @Param、无 push / console | ✅ 无新增风险，计数维持 0/1/4/2 |
| 第 5 轮（2026-10-27 逐条事实） | `MainPage.ets:451-452` Tools 常驻挂载；`ToolsViewModel.ets:69-72` 失败落 EMPTY；`MaterialCharacterSelectPage.ets:56` 只用 gameId；checklist ID 逐条对照 | ✅ H1 降为 Medium 5；新增 Medium 6；L1 改写；5 处误用 ID 更正；计数 0/1/4/2 → 0/0/6/2，评级 B 不变 |
| 第 6 轮（2026-11-02 M1 真重构） | ToolsModels 135L 拆分（GameEntryVM 43L + MaterialTargetModels 116L，re-export 保持 import）；`hasComputeData` → `hasTargetConfig`；删除 `gameColor` / `uiContext` 死代码；`@Require`；箭头资源化；DAO 复用；编译 `bash run.sh uat` → BUILD SUCCESSFUL in 17s 272ms | ✅ M1 真重构完成；LIFE-002 / KIT-005 / N+1 保留 |

---

## M1 真重构记录（2026-11-02）

### 改动

| 类型 | 文件 | 说明 |
| --- | --- | --- |
| 拆分 | `model/MaterialTargetModels.ets`（新增 116L） | 从 `ToolsModels.ets` 迁出 `ZZZSkillType` / `ZZZSkillTarget` / `GenshinTalentSlot` / `StarRailSkillSlot` / `MaterialComputeTargets` / `MaterialTargetConfigParam` |
| facade | `model/ToolsModels.ets`（135L → 43L） | 只保留 `GameEntryVM`，并 re-export 上述模型；路径与导出符号不变 |
| 命名 | `ToolsViewModel.ets` | `hasComputeData` → `hasTargetConfig`（实际查询 `material_target_config`，原名误导） |
| 清理 | `ToolsViewModel.ets` | 删除死字段 `GameEntryVM.gameColor`（只写不读）；三个 DAO 提为字段复用；`entries[entries.length]` → `entries.push`；索引 for → for-of |
| 清理 | `ToolsPage.ets` | 删除只赋值、从不读取的 `uiContext` 字段与 `UIContext` import |
| 契约 | `GameEntryCard.ets` | `@Param entry = new GameEntryVM()` → `@Require @Param entry`（调用方与 Preview 均已显式传参） |
| 资源 | `GameEntryCard.ets` | `Text('›')` → `$r('app.string.common_arrow_right')`；边框宽度 `1` → `tm.current.value1` |
| 响应式 | `ToolsModels.ets` | `GameEntryVM` 去掉冗余 `@ObservedV2` / `@Trace`：入口列表每次整体重建，不存在字段原地修改 |

### 行为等价说明

- `hasTargetConfig` 的查询条件、表、返回语义与原来一致；DAO 无实例状态，复用不改变结果。
- `gameColor` 在全仓无读取方；删除后卡片渲染不变。
- `@Require` 只是编译期约束；`ToolsPage` 与 `GameEntryCardPreview` 均传 `entry`。
- 箭头资源 `common_arrow_right` 的值同样是 `›`；`ThemeManager.value1 = 1`，边框视觉不变。

### 验收

| 项 | 结果 |
| --- | --- |
| 编译 | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 17s 272ms`，安装/启动成功 |
| 测试契约 | ✅ `viewmodel/ToolsViewModel.ets` / `model/ToolsModels.ets` 路径不变；`GameEntryVM` 导出与 `accountId` 等字段不变 |
| 文件规模 | ✅ ToolsViewModel 144L / GameEntryCard 131L / ToolsPage 125L / ToolsModels 43L |
| 冒烟 | 🔶 待手动：Tools Tab 三卡片、进入角色选择页、空态 |

### 未执行（保留记录）

- `LIFE-002` 代际标记、KIT-005 错误态：行为变更，需单独提交。
- N+1 批量查询：每个角色仍一次 `findOne`，需 core 增加批量 DAO 方法。
- `MaterialCharacterSelectParam` 定义在 ViewModel、由 ToolsPage 直接 import：分层问题，随 M7 角色选择页重构迁移到 model。
