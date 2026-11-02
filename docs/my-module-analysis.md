# Code Review Report · My 页面模块

> **审查对象**：`features/account/src/main/ets/pages/MyPage.ets` + `features/account/src/main/ets/viewmodel/MyViewModel.ets` + 子组件
> **审查日期**：2026-10-24
> **审查者**：AI 助手
> **代码版本**：`105c8d3`
> **HarmonyOS SDK**：`6.0.2(22)`（`targetSdkVersion` / `compatibleSdkVersion`，见根 `build-profile.json5`）

---

## 模块构成

| 文件 | 行数 | 角色 | 装饰器模型 |
| --- | --- | --- | --- |
| `pages/MyPage.ets` | 150 | 页面入口 | `@ComponentV2` |
| `viewmodel/MyViewModel.ets` | 116 | 数据 + 业务逻辑（账号加载、日志大小/导出、清理缓存） | `@ObservedV2` + `@Trace` |
| `components/my/AccountListSection.ets` | 88 | 账号列表容器 | `@ComponentV2` |
| `components/my/AccountListItem.ets` | 60 | 单个账号行 | `@ComponentV2` |
| `components/my/AppearanceSection.ets` | 72 | 外观设置入口 | `@ComponentV2` |
| `components/my/AboutSection.ets` | 72 | 关于 Section | `@ComponentV2` |
| `components/my/SectionHeader.ets` | 37 | 分区标题 | `@ComponentV2` |
| `models/MyModels.ets` | 89 | `MyAccountVM` / `MyGameRoleVM` / `GameStatItem` 数据类（普通类，无 `@ObservedV2`） | — |

> 同目录的 `NotificationSection.ets`（113 行）虽然放在 `components/my/`，但只被 `pages/NotificationSettingsPage.ets` 使用，归属 **M5**，不在 M4 范围。
>
> `models/MyModels.ets` 不是 My 专属：`MyAccountVM` 还是 `AccountDetail` 的路由参数（`MyPage.ets:65/67`），并被 `LoginViewModel`、`components/accountdetail/` 三个组件导入，归 M4 维护但不得移动。另有 `components/SettingRow.ets`（共享层）被 My / AppearanceSection / AboutSection 使用。

### 结构树 / 调用链

```
My.build()（MyPage.ets:57-149）
└── Scroll → Column
    ├── SectionHeader + AccountListSection(accounts = vm.accounts)
    │   ├── accounts 为空 → "暂无账号"行（AccountListSection.ets:22-30）
    │   ├── ForEach(accounts, key = accountId) → AccountListItem → onAccountTap → ACCOUNT_DETAIL（param = MyAccountVM）
    │   └── "添加账号"按钮 → onAddTap → LOGIN
    ├── SectionHeader + AppearanceSection(themeMode) → onTap → APPEARANCE_SETTINGS（param = AppearanceSettingsParam，回调写回 themeMode）
    ├── SectionHeader + SettingRow → WIDGET_SETTINGS（param = vm.accounts）
    ├── SectionHeader + SettingRow → NOTIFICATION_SETTINGS
    └── SectionHeader + AboutSection(vm)
        ├── aboutToAppear / onVisibleAreaChange → vm.refreshLogSize()
        ├── 导出日志 → vm.exportLogs(uiCtx) → core LogExporter.export()
        ├── 清理缓存 → vm.clearCache(uiCtx) → showDialog → deleteAllLogs()
        └── 版本号（BuildProfile.VERSION_NAME）

生命周期：aboutToAppear（:28-32）→ vm.loadAccounts() + loadSavedColorMode()
          @Monitor('signal.version')（:34-37）→ vm.loadAccounts()
          无 aboutToDisappear（无定时器 / 订阅需释放）
```

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 2 |
| Low | 4 |

**整体评级：A**

> 一句话结论：模块结构清晰、状态管理一致；已有跨模块类型耦合（My → AppearanceSettingsParam）和 `@Param` 默认值两处技术债，下迭代处理；另有日志导出/清理缓存的反馈缺口与账号列表 key 覆盖不全 4 条 Low。
>
> 债务点数 = 0×3 + 2×2 + 4×1 = **8**；源行数按 `MyPage.ets` 150 行计，密度 = 8 ÷ 1.5 ≈ **5.3**/百行。

---

## 合规检查（skills checklist）

> 逐条对照 `.opencode/skills/harmonyos-review/references/checklist.md`，只列与本模块相关的条目。SEC / DB / PERM / KIT 类不适用。

| ID | 检查项 | 结论 | 证据 / 说明 |
| --- | --- | --- | --- |
| STATE-001 | 不混用 V1 / V2 | ✅ | `MyPage.ets` 与 `components/my/` 六个组件均为 `@ComponentV2`；`MyViewModel` 为 `@ObservedV2`（`:28`） |
| STATE-002 / STATE-003 | 数组 / 对象走引用替换 | ✅ | `accounts` 全量赋值（`MyViewModel.ets:108`）；`stats[stats.length] = …`（`:98`）发生在局部数组构造期间，赋值完成后才整体透传 |
| STATE-007 | 回调 / `@Event` 有默认值 | ✅ | `@Param detailStack` / `isSplit`（`MyPage.ets:20-21`）均有默认值 |
| STATE-008 | `build()` 纯函数 | ✅ | My 与 5 个组件的 `build()` 内无 await / 状态写入；副作用都在 `aboutToAppear` 或回调中 |
| —（项目约定，非 checklist 条目） | `@Param` 不构造默认对象 | ⚠️ Medium | `AboutSection.ets:13` `@Param vm: MyViewModel = new MyViewModel()`（已记 Medium 第 2 条）。注：checklist 的 STATE-008 是"build() 纯函数"，旧稿把本项标成 STATE-008 属编号误用 |
| STATE-013 | 跨页面共享状态不当用全局变量 | ✅ | 账号变更通过 `AccountSignal` 单例广播（`MyPage.ets:34`），无裸全局变量 |
| LIFE-001 | `aboutToDisappear` 取消订阅 | ✅（无需注销） | 页面只持 `@Monitor('signal.version')`，由框架自动解绑；无定时器 |
| LIFE-004 | 跳转前清理弹窗 | ✅ | My 页无自有弹窗；切页均通过 `detailStack`（`MyPage.ets:63-123`，共 5 处 push / replace）。`clearCache` 的确认框由 VM 弹出（`MyViewModel.ets:59-81`），在 then/catch 中结束，不跨页残留 |
| PERF-003 | 高频组件 `@Reusable` | ✅（暂不需要） | 列表项 `AccountListItem` 数量等于账号数（通常 ≤ 5），`@Reusable` 收益低于复杂度 |
| PERF-008 | 列表项带 `key` | ⚠️ Low | 账号列表 `ForEach` 的 key 只有 `accountId`（`AccountListSection.ets:43`），昵称 / 头像 / 角色数变化不改 key（见 Low 第 4 条） |
| ARKTS-012 | 日志走 hilog | ✅（已核实） | `MyViewModel.ets:112` 用 core 的 `Logger`，而 `core/src/main/ets/base/utils/Logger.ets:2` 直接 `import { hilog } from '@kit.PerformanceAnalysisKit'`，domain `0xFF00`；原 Low 项撤回 |
| ARKTS-014 | import 走 `@kit.*` | ✅ | `MyPage.ets:4` 只用 `@kit.AbilityKit`（另有 `MyViewModel.ets:11`、`AppearanceSection.ets:7` 同样走 `@kit.AbilityKit`），无 `@ohos.*` 旧式导包 |
| TEST-001 | 核心逻辑有单测 | ⚠️ 有测试（不计入 L） | `entry/src/test/MyViewModel.test.ets`（32 行，4 条用例）只覆盖初始 `viewState` / `accounts` 与 `KEYS.viewState` / `KEYS.accounts` 两条路径常量；`loadAccounts` / `refreshLogSize` / `exportLogs` / `clearCache` 均无单测，`loadSavedColorMode` 在页面层也无测试 |

> 合规结论：本模块的实际问题是 2 个 Medium（跨层类型引用 + `@Param` 默认实例）与 4 个 Low（日志导出无反馈、清理缓存错误路径、`onVisibleAreaChange` 重复刷新、列表 key），原 ARKTS-012 经查 core `Logger` 已封装 hilog，**撤回**。

---

## Medium Issues（技术债）

| 规则 ID | 文件 | 问题 | 建议 |
| --- | --- | --- | --- |
| ARCH（项目 P-3） | `MyPage.ets:16` | `import { AppearanceSettingsParam } from '../pages/AppearanceSettingsPage'` — 页面直接依赖另一个页面文件导出的参数类型（数据类型应放 `models/`），违反单向依赖 | 将 `AppearanceSettingsParam` 提取到 `models/`；属跨模块改动，需与 M3 协调 |
| STATE（项目约定） | `AboutSection.ets:13` | `@Param vm: MyViewModel = new MyViewModel()` 提供默认实例。`MyPage.ets:132` 始终传入 `this.vm`，运行时不触发默认值；但 Preview 与“忘传参”场景会各自 new 一个 ViewModel，数据不同步且容易掩盖漏传 | 移除默认值（`@Param vm: MyViewModel`），Preview 显式传入；属行为修复，与目录调整分开提交 |

### 观察项（不计入债务）

- `MyViewModel.ets:7` 的 `import BuildProfile from 'BuildProfile'` **不是缺陷**：`BuildProfile.ets` 由 hvigor 为每个 product/target 生成（已验证 `entry/build/*/generated/profile/*/BuildProfile.ets`），运行时可用。原文把它记为 `KIT-004` 属于规则误用。
- `MyViewModel.ets:98` 的 `stats[stats.length] = …` 只是数组写法风格，不是 `PERF-003`（`@Reusable`）问题；改成 `push` 可选，不计入债务。

---

## Low Issues（建议优化）

| 规则 ID | 文件 | 问题 | 建议 |
| --- | --- | --- | --- |
| PERF（建议） | `AboutSection.ets:16-18`、`:50-54` | `aboutToAppear` 已调一次 `refreshLogSize()`，首次可见时 `onVisibleAreaChange` 又调一次；之后每次跨越可见阈值（`[0.0, 1.0]`）都重新遍历日志目录计算大小，无节流 / in-flight 守卫 | 去掉 `aboutToAppear` 中的重复调用，或在 VM 加 in-flight 标记 |
| 反馈（建议） | `MyViewModel.ets:49-55` | `exportLogs` 忽略 `LogExporter.export()` 的布尔返回值：无日志文件或用户取消时返回 `false`（core `LogExporter.ets:28-31 / 52-56`），成功也无提示，用户点"导出日志"后可能毫无反馈；`uiCtx.getHostContext() as common.UIAbilityContext` 无 `undefined` 检查（`MyPage.ets:39-45` 的同类写法有检查） | 按返回值给出"无日志可导出 / 已导出"提示；复用页面的空值检查 |
| 反馈 / 硬编码（建议） | `MyViewModel.ets:59-81` | `clearCache`：`deleteAllLogs()` 整体失败被 `.catch(() => {})` 吞掉（`:80`），用户确认后无任何反馈；部分失败（`failedCount > 0`）时仍先把 `logSize` 置为 `'0 B'`（`:70`）；按钮色硬编码 `'#999999'` / `'#E8534A'`（`:63-64`），不跟随主题 | 失败路径给出错误 toast，部分失败后调 `refreshLogSize()`；颜色改用 `$r('app.color.*')` |
| PERF-008 | `AccountListSection.ets:43` | 账号 `ForEach` 的 key 只有 `accountId`；`MyAccountVM` 为普通类（`MyModels.ets:67`），`loadAccounts()` 每次生成新实例（`MyViewModel.ets:106-108`）。按 ForEach 键值复用规则，同一账号重新登录后昵称 / 头像 / 角色数的变化不会刷新到该行 | key 拼入 `nickname` / `avatarUrl` / `roles.length`，或给 VM 加版本号 |

> ~~ARKTS-012（`Logger` 未封装 hilog）~~ **已撤回**：`core/src/main/ets/base/utils/Logger.ets:2` 直接 `import { hilog }`，全项目统一走该封装，不是缺陷。

---

## 详细分析

### 1. 状态管理架构（STATE 系列）

**✅ 亮点**：
- `MyViewModel` 正确使用 `@ObservedV2` + `@Trace` 实现响应式数据流
- `My` 页面通过 `@Local private vm: MyViewModel = new MyViewModel()` 持有实例，符合 V2 规范
- `AccountListSection`、`AppearanceSection` 等子组件仅使用 `@Param` 接收只读数据，职责清晰

**⚠️ 注意**：
- `MyViewModelKeys` 类（第 22-26 行）声明为 `@Monitor` 路径常量，但全 `ets` 没有任何 `@Monitor` 使用它（`MyPage.ets` 唯一的 `@Monitor` 监听的是 `signal.version`，`:34`）；实际读取方只有 `MyViewModel.test.ets:23-29`。它是测试冻结的导出符号（Refactor_Spec §2.5），重构时保持原样即可，不要误当成运行时契约去扩展

### 2. 生命周期与资源管理（LIFE 系列）

**✅ 亮点**：
- `My.aboutToAppear()` 中执行 `loadAccounts()` + `loadSavedColorMode()`，异步加载不阻塞渲染
- `AboutSection` 在 `aboutToAppear`（`:16-18`）与 `onVisibleAreaChange`（`:50-54`）两处都刷新日志大小——并非懒加载，首屏会重复计算一次（见 Low 第 1 条）

**⚠️ 注意**：
- `loadSavedColorMode()` 使用 `.catch()` 但未记录日志（第 52 行 `_e` 被忽略）。若读取持久化失败，外观行回落显示"跟随系统"（`:53`），与实际生效的主题可能不一致
- `getAbilityContext()` 链式调用含两次空值检查，可提取为安全助手函数提升可读性

### 3. 路由与导航模式

**✅ 亮点**：
- `isSplit` 双态支持（窄屏 push / 宽屏 replacePath），适配多窗口模式
- 通过 `AppRoutes` 常量集中管理路由名称，避免魔法字符串

**⚠️ 注意**：
- 5 个跳转回调重复 `if (this.isSplit)` 判断逻辑（第 64-76、86-90、100-104、118-122 行），可提取为私有方法 `navigateTo(name: string, param: Object | null)`（不要用 `unknown`，会违反 ARKTS-001）

### 4. 跨模块耦合分析

**⚠️ 架构隐患（按优先级计为 Medium，非 Critical）**：
- `MyPage.ets` 第 16 行直接 `import { AppearanceSettingsParam } from '../pages/AppearanceSettingsPage'`
- `AppearanceSection` 在 My 页面内使用，但参数类型来自另一个 Page 文件
- **风险**：若 `AppearanceSettingsPage` 重构或改名，My 模块编译失败；违反"页面之间不互相依赖类型、数据类型放 `models/`"的单向依赖原则

**建议**：
```typescript
// ✅ 新建 features/account/src/main/ets/model/AppearanceSettingsParam.ets（字段与 AppearanceSettingsPage.ets:21-24 现有定义一致）
export class AppearanceSettingsParam {
  themeMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  onThemeChange: (mode: number) => void = (_m: number) => {}
}

// MyPage.ets 中改为
import { AppearanceSettingsParam } from '../models/AppearanceSettingsParam'
```

### 5. 数据流与幂等性

**✅ 亮点**：
- `@Monitor('signal.version')` 监听 `AccountSignal`，账号增删后自动刷新列表
- `loadAccounts()` 使用 `async/await` + `try/catch`，异常时降级为 `ViewState.EMPTY`

**⚠️ 注意**：
- `loadAccounts()` 第 108 行 `this.accounts = vms` 全量替换，未做增量 diff；账号数通常 ≤ 5，不构成性能问题（不计入债务）。但全量替换配合只含 `accountId` 的 ForEach key，会导致同账号字段更新不刷新（见 Low 第 4 条）
- `loadAccounts()` 失败时只把 `viewState` 置为 EMPTY（`:113`），而 `MyPage.ets` 并不读取 `vm.viewState`，失败表现为"暂无账号"（`AccountListSection.ets:22-30`）；属观察项，不计入债务
- `MyViewModel.KEYS` 静态属性（第 30 行，`static readonly KEYS: MyViewModelKeys`）就是 `MyViewModelKeys`（L22-26）的单例实例，二者是同一套常量，仅被测试使用

---

## 整体观察

- **代码质量**：V2 装饰器使用一致，无 V1/V2 混用；子组件职责单一、可复用性强
- **架构**：Repository 调用集中在 `loadAccounts()`；但 VM 同时承担日志导出 / 清理缓存，并直接持有 `UIContext` 弹框与 toast（`MyViewModel.ets:49-82`），UI 逻辑渗入 VM；`AboutSection` 直接导入 `MyViewModel`（Refactor_Spec §6 P-3 反向依赖）。跨模块类型引用需解耦
- **测试覆盖**：`entry/src/test/MyViewModel.test.ets` 已有 4 条用例（初始 `viewState` / `accounts` / `KEYS` 路径）；`loadAccounts()` 及日志相关方法均未覆盖。5 个组件中除 `AccountListItem` 外都含 `@Preview`（`MyPage.ets` 本身无 Preview），可手工校验 UI
- **文档**：文件顶部 JSDoc 基本清晰，但 `MyViewModel.ets:4` 称"通过 AuthRepository 补充网络数据"，与 `loadAccounts` 只读 DB 的实现（`:90` 注释、`:86-107`）不符，重构时顺手更正

---

## 修复建议优先级

| Phase | 任务 | 预估工作量 |
| --- | --- | --- |
| **P0 · 立即** | 无 Critical 项 | — |
| **P1 · 本周** | 提取 `AppearanceSettingsParam` 到独立模块 | 1 小时 |
| **P2 · 下迭代** | 移除 `AboutSection` 的 `@Param` 默认实例；重构路由导航为私有方法；`onVisibleAreaChange` 去重；`exportLogs` / `clearCache` 补反馈与主题色；账号列表 key 补字段 | 4 小时 |
| **P3 · 长期** | 补充 `loadAccounts()` hypium 单测；统一常量命名规范 | 半天 |

---

## 复审建议

P1 修完后执行：
1. `hvigorw assembleHap -p buildMode=debug` — 确认无编译错误
2. DevEco Studio Preview 面板验证 `AccountListSectionPreview` / `AppearanceSectionPreview` / `AboutSectionPreview` 渲染正常
3. 真机多窗口模式（窄屏 / 分屏）回归导航行为

---

## 附录 · 扫描命令记录

```bash
# 状态管理混用检查
grep -rEn "@Component[^V2]" --include='*.ets' features/account/src/main/ets/views/
grep -rEn "@State\b|@Prop\b|@Link\b" --include='*.ets' features/account/src/main/ets/pages/MyPage.ets

# 跨模块依赖检查
grep -rEn "import.*from.*pages/" --include='*.ets' features/account/src/main/ets/views/

# @Monitor 路径常量同步性
grep -rEn "@Monitor\(" --include='*.ets' features/account/src/main/ets/
grep -rEn "MyViewModelKeys" --include='*.ets' features/account/src/main/ets/
```

---

## 附录 · 引用规则编号说明

| 规则 ID |  severity | 说明 |
| --- | --- | --- |
| STATE（项目约定） | Medium | `@Param` 默认值在组件实例化时构造对象（父组件已传参时不生效）；checklist 的 STATE-008 是"build() 纯函数"，此处不沿用该编号 |
| ARCH（项目 P-3） | Medium | 组件/page 类型跨层引用 |
| ~~ARKTS-012~~ | ~~Low~~ | **已撤回**：core 的 `Logger` 已封装 hilog（`Logger.ets:2`），不走 `console` |
| PERF（建议） | Low | 可见区域回调与 `aboutToAppear` 重复刷新、无节流 |
| 反馈（建议） | Low | `exportLogs` 忽略返回值 / 强转无空检查 |
| 反馈 / 硬编码（建议） | Low | `clearCache` 失败静默、部分失败仍显示 0 B、按钮色硬编码 |
| PERF-008 | Low | 账号列表 key 只含 `accountId` |

> 完整规则表见 `.opencode/skills/harmonyos-review/references/checklist.md`

---

## 重构执行备注（M4 · My）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `My` 是底部 Tab 内嵌页，**不在** `custom_router_map.json`；`MainPage.ets:17` 直接 `import { My } from './My'`，页面路径在 M15 前冻结 |
| 测试引用（冻结） | `viewmodel/MyViewModel.ets`、`constants/ViewState.ets` 被 `entry/src/test/MyViewModel.test.ets` 导入，路径/导出符号不得变 |
| 跨页类型 | `MyPage.ets:16` 从 `pages/AppearanceSettingsPage` 导入 `AppearanceSettingsParam`；这是已知的跨层耦合，改造需与 M3 协调 |
| 组件 | `components/my/` 的 5 个 M4 组件（AccountListSection / AccountListItem / AppearanceSection / AboutSection / SectionHeader）；同目录 `NotificationSection` 归 M5 |
| 模型 | `models/MyModels.ets` 的 `MyAccountVM` 是 `ACCOUNT_DETAIL` 路由参数（`MyPage.ets:65/67`），并被 Login / AccountDetail 共用，字段与路径不变；`MyPage.ets:101/103` 把 `vm.accounts` 整体作为 `WIDGET_SETTINGS` 路由参数传出 |

### 重构范围（建议）

- 目录/命名已符合规范：**没有安全的文件移动**。`MyPage.ets` 不能改名（Main 直接 import）；`MyViewModel.ets` 不能移动（测试冻结）。
- 可选的等价重构：把 `onAccountTap` / `onAddTap` 中重复的 `isSplit` 判断收敛为私有导航方法（行为不变）。
- `AppearanceSettingsParam` 拆到 `models/` 属于跨模块改动：会同时改 M3 的页面和 M4 的 `MyPage.ets`，默认不在 M4 做；若要做，先在本节登记并单独提交，保留原 page 的导出以免其它引用断裂。
- 移除 `AboutSection` 的 `@Param vm = new MyViewModel()` 是行为修复（涉及 Preview/默认实例），必须与目录调整分开提交。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. DevEco Local Test：`MyViewModel.test.ets` 4 条用例通过。
3. 冒烟：我的页各 Section、账号列表、外观/通知入口；窄屏 push 与宽屏 `replacePath` 两种导航；AboutSection 滚动刷新日志大小。

### 已知问题归属

- Medium（`AboutSection` 的 `@Param` 默认实例）：建议随 M4 修，单独提交；仅做目录调整则记录到 Refactor_Spec §11。
- Medium（`MyPage.ets` 依赖 page 类型）：记录；是否抽取由 M3/M4 协调决定。
- Low（`onVisibleAreaChange` 重复刷新、`exportLogs` 无反馈、`clearCache` 错误路径与硬编码色、账号列表 key）：均为行为变更，记录；要修则各自单独提交，不与目录调整混合。

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（文件 + 行号） | 7 个模块文件、NotificationSection 113 行、MyPage.ets:16/132、AboutSection:13 | ✅ |
| 第 2 轮（VM 细节） | MyViewModel L7/L22-26/L30/L98/L108/L112、MyPage.ets L52/L64-76、测试 4 条用例 | ✅ 修正 1 处（ETCHED_KEYS → KEYS） |
| 第 3 轮（全面复核） | @Monitor L34、getAbilityContext 双空检、NotificationSection 唯一消费者、MainPage.ets:17 | ✅ |
| 第 4 轮（2026-10-26 复核） | 补 §合规检查（12 条 checklist）；核实 core `Logger` 已封装 hilog（`Logger.ets:2`）→ 撤回 ARKTS-012 Low | ✅ Low 2→1，债务 6→5 |
| 第 5 轮（2026-10-27 逐条事实复核） | 重读 My / VM / 5 组件 / MyModels / 测试全文；核对每个锚点与规则编号 | ✅ 模块构成补 `models/MyModels.ets` 与行数列，补齐 README §6 要求的「结构树 / 调用链」章节；纠正规则编号误用（`@Param` 默认实例 ≠ STATE-008；`PERF-007` 不适用）；LIFE-004 锚点 `83-108 → 63-123`；ARKTS-014 不含 `@kit.ArkUI`；TEST-001 实际不覆盖账号加载；`MyViewModelKeys` 无 `@Monitor` 使用方；"懒刷新"不成立；`AppearanceSettingsParam` 示例与现有定义对齐；`navigateTo` 建议去掉 `unknown`。新增 3 条 Low（`exportLogs` 无反馈、`clearCache` 错误路径 / 硬编码色、账号列表 key）。计数 0H/2M/1L → 0H/2M/4L，债务 5 → 8，评级仍为 A |
| 第 6 轮（M4 命名核查，2026-10-30） | 逐文件命名核查：类名/PascalCase ✅ / 方法名/camelCase ✅ / 变量名/camelCase ✅ / 常量/UPPER_SNAKE_CASE ✅；编译验证 `bash run.sh uat` → BUILD SUCCESSFUL in 16s 358ms | 🔶 命名零违规；M4 真重构（SettingRow 迁入、组件去重、行为等价验证）待执行 |
