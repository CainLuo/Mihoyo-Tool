# Launch 模块独立分析文档

> 生成时间：2026-10-24
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）
> 作用域：`entry/src/main/ets/pages/LaunchPage.ets` + 直接依赖（CoreInitializer, ThemeManager, RouterUtil, LegalPreferences, AppRoutes）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 1 |

**整体评级：A**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + 0 High → A）。旧百分制已废弃，原分 92/100 仅作历史参考。
>
> 债务点数 = 1×1 = **1**，密度 = 1 ÷ 1.73 ≈ **0.6**（页面 `LaunchPage.ets` 173 行）。
>
> **H1 已关闭（2026-11-17，`f0f3844`）**：原判 High 的理由是「`navigateToMain()` 的 catch 降级不可达，Core 初始化一旦失败，用户永久停在启动页且无提示无重试」。现 `CoreInitializer` 在 `initCore` 失败时 reject `readyPromise`（并重建 promise 支持重试），启动页新增 20s 超时兜底 + 错误态 + 重试按钮，`EntryAbility` 的 Widget / 通知初始化改为 `registerReadyHook` 注册，重试成功后同样执行。

---

## 1. 文件清单

| 文件 | 类型 | 行数 | 职责 |
|------|------|------|------|
| `LaunchPage.ets` | Page / @ComponentV2 | 173 | 启动闪屏页，含 Logo 动画 + 隐私合规检查 + 初始化失败错误态（Model 访问经 `LaunchViewModel`） |
| `PrivacyConsentPage.ets` | Page（间接依赖） | 129 | 由 Launch 在用户未同意时替换导航 |
| `viewmodel/LaunchViewModel.ets` | ViewModel | 32 | 隐私协议判断 + 等待 Core 就绪 + 初始化失败重试 |

**直接导入依赖**：`LaunchViewModel`, `ThemeManager`, `AppRoutes`, `RouterUtil`, `common`, `Logger`, `ThemeFonts`（页面不再直接导入 `CoreInitializer` / `LegalPreferences`）

## 2. 架构分析（结构树）

```
Launch (@ComponentV2)
├── @Local tm: ThemeManager (主题状态)
├── @Local logoScale / logoOpacity: number (动画状态)
├── @Local initFailed: boolean (初始化失败 / 超时 → 错误态)
├── private uiCtx: UIContext | null (UI 上下文，缓存避免重复 getUIContext)
├── private timeoutId: number / settled: boolean (20s 超时定时器 / 本轮等待已结束)
├── aboutToAppear()
│   ├── this.uiCtx = this.getUIContext()
│   ├── animateTo(600ms, Logo 淡入放大)
│   └── checkPrivacyAndProceed()
│       ├── viewModel.hasAgreed(ctx) → true → startBootstrap(ctx)
│       └── false → RouterUtil.replace(PRIVACY_CONSENT)
├── startBootstrap(ctx)
│   ├── setTimeout(20s) → initFailed = true（超时兜底）
│   ├── Promise.all([viewModel.waitForReady(), minDelay 1200ms])
│   │   ├── then → RouterUtil.replace(MAIN)
│   │   └── catch → initFailed = true（initCore 失败已 reject）
├── onRetry() → viewModel.retryInit(ctx) + startBootstrap(ctx)
├── aboutToDisappear() → clearTimeout()
└── build()
    └── NavDestination
        └── Column (居中布局)
            ├── Image (ic_app_logo, 缩放 + 透明动画绑定)
            ├── Text (app_name, bold26, 透明动画绑定)
            ├── Text (launch_subtitle, 透明动画绑定)
            └── if (initFailed) 错误态
                ├── Text (launch_init_failed_title)
                ├── Text (launch_init_failed_desc)
                └── Button (launch_retry) → onRetry()
```

**架构模式**：页面负责动画 / 三态渲染 / 路由，Model 访问与初始化重试经 `LaunchViewModel` 收口。

## 3. ArkTS 合规性检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| `@ComponentV2` + `struct` | ✅ 通过 | 符合当前版本规范 |
| 状态装饰器正确性 | ✅ 通过 | `@Local` 用于内部私有状态，合理 |
| `themeManager` 单例引用 | ✅ 通过 | `@Local tm: ThemeManager = themeManager` |
| `aboutToAppear` 使用 | ✅ 通过 | 初始化动画 + 合规检查 |
| NavDestination 根节点 | ✅ 通过 | 最外层正确包裹 |
| UI 线程安全 | ✅ 通过 | `setTimeout` 与 Promise 回调都在 UI 线程的事件循环中执行，`.then()` 里只做路由跳转 |
| 异常降级处理 | ✅ 通过 | `waitForReady()` 在 `initCore` 失败时 reject（`CoreInitializer.doInit` 的 catch → `rejectReady`）；页面另有 20s 超时兜底（`INIT_TIMEOUT_MS`），两条路径都进入错误态 |

**ArkTS 结论：语法与状态管理通过；初始化失败 / 超时均有错误态与重试入口**

## 4. 组件复用分析

- **无独立 @Component 子组件**：所有 UI 结构内联在 `build()` 中（173 行，含错误态），暂无拆分需求
- **Logo 动画逻辑与主题字体** 通过 `ThemeManager` / `ThemeFonts` 实现外部化——值得肯定
- `PrivacyConsentPage` 作为独立路由目标已封装良好

## 5. 安全审查

| 风险 | 级别 | 说明 |
|------|------|------|
| `getUIContext().getHostContext()` 类型断言 | ⚠️ 低 | `checkPrivacyAndProceed()` 直接 `as common.UIAbilityContext`，无空值 / 类型检查；`LegalPreferences.hasAgreed()` 内部 try/catch（`LegalPreferences.ets:19-25`），异常时返回 `false`，表现为已同意用户被再次送到隐私页，不会崩溃 |
| ~~Promise.all 无超时、catch 不可达~~ | ✅ 已修（2026-11-17） | `readyPromise` 现在同时持有 resolve / reject 句柄（`CoreInitializer.createReadyPromise()`），`doInit` 失败时 `rejectReady(err)`；页面 `Promise.all` 的 catch 因此可达，另有 `INIT_TIMEOUT_MS = 20000` 定时器兜底「初始化卡住不抛错」的情况 |

**安全结论：无安全漏洞，无可靠性 High**

## 6. 风险清单

- [x] ~~**高优先级 H1**：Core 初始化失败时永久卡在启动页~~ ✅ **已修（2026-11-17，`f0f3844`）**：
  - core：`readyPromise` 增加 reject 句柄，`initCore` 拆为 `initCore()`（防并发包装）+ `doInit()`（try/catch → `rejectReady(err)` 后 rethrow），并提供 `resetReady()` 让重试重建 promise；`initInFlight` 保证超时重试不会并发初始化 DB。
  - 启动页：新增 `INIT_TIMEOUT_MS = 20000` 超时兜底与 `initFailed` 错误态（标题 + 说明 + 重试按钮），失败/超时都不再跳 Main，`settled` 标记忽略迟到结果。
  - `EntryAbility`：Widget 存储 / 通知服务的初始化从 `initCore().then` 改为 `CoreInitializer.registerReadyHook()`，重试成功后同样执行（否则重试后 Widget 与通知不工作）。
  - 字符串：`launch_init_failed_title` / `launch_init_failed_desc` / `launch_retry`（base / en / zh_HK）。
  - 验证：`assembleHap`（uat/debug）BUILD SUCCESSFUL；全量单测 891 条全绿。失败路径需真机造（如临时让 `RdbManager.init` 抛错）后手测。
- [ ] **低优先级 L1**：`getHostContext()` 直接 `as common.UIAbilityContext` 断言（`checkPrivacyAndProceed()`），无空值 / `instanceof` 校验；`hasAgreed()` 内部兜底返回 `false`，不会崩溃。与 AccountDetail（M11）的同一类问题
- （2026-10-27 编号调整）原 L1「`waitForReady` 无超时」按实际影响升为 H1；原 L2 改号为 L1，Low 由 2 条变为 1 条
- [ ] **信息提示**（不计入 Low）：启动页动画 + 隐私检查总耗时取决于 Core 初始化速度，若初始化慢则用户等待时间较长（现最多等 20s 后转入错误态）

---

## 7. 重构执行备注（M12/M15）

> 执行以 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) 为准。

**路由事实**

- `Launch` **未注册**在 `custom_router_map.json`，也没有 `@Builder`；它由 `Index.pageBuilder` 直接 `new Launch()` 渲染，路由名 `AppRoutes.LAUNCH` 只存在于 `NavPathStack`。因此**不能**仅凭“移动文件”就期望路由继续工作——移动必须同步 `Index.ets` 的 import + 分支。
- 隐私同意页也是"非 routerMap"页面：`PrivacyConsentPageBuilder` 由 `Index.ets:5` 直接 import 调用，Launch 用 `RouterUtil.replace(AppRoutes.PRIVACY_CONSENT)` 跳转。两者都不进 routerMap，迁动时要同时改 import 与分支。

**不变量与风险**

1. `startBootstrap()` 的「`Promise.all([waitForReady(), 1200ms])` → replace(MAIN)」是启动契约；H1 修复后 catch 可达，且另有 20s 超时兜底——两条失败路径都**不跳 Main**，而是展示错误态 + 重试按钮（`f0f3844`）。抽 `BootstrapGate` 时需一并搬走超时与错误态，不能只保留 catch。1200ms 下限同时为 Main 读取 AppStorage `windowClass` 留出了时间（见 main M7），缩短或去掉前要先处理该时序。
2. 各 ViewModel 也直接 `await CoreInitializer.waitForReady()`（`HomeViewModel.ets:108`、`CharactersViewModel.ets:95`、`ToolsViewModel.ets:49` 等），首装路径（隐私页 → `PrivacyConsentPage.ets:35` 直接 replace MAIN）也依赖它。注意：这些 `await` 大多在各自 `try` 之外，初始化失败时 `waitForReady()` 现在会 reject（此前是永久 pending），但启动页已拦在 Main 之前，正常流程不会触发；若将来允许「Core 未就绪也进 Main」，需把这些 await 一并包进 try。
3. `LegalPreferences.hasAgreed(ctx)` 的结果决定首屏，重构不得改变「已同意直接进 Main」的快路径。

**测试**：无自动化测试；必须手测三条路径——首次安装（Launch → 隐私页 → 同意 → Main）、已同意冷启动（Launch → Main）、Core 初始化异常（应展示错误态 + 重试；重试成功后进入 Main，且 Widget / 通知恢复正常）。

**拆分建议**：Launch 现为 173 行（含错误态），属 M15 尾部；优先把 `checkPrivacyAndProceed` / `startBootstrap` / `onRetry` 抽成 `LaunchFlow`，UI 与动画留在页面内，不做无收益的组件化。

---

*本文档仅分析，不修改代码。*

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | Launch 94 行 / PrivacyConsentPage 113 行、结构树全节点、8 项导入 | ✅ 全部精确匹配 |
| 第 2 轮（关键代码段） | aboutToAppear L30-38、checkPrivacyAndProceed L40-49、navigateToMain L51-63（1200ms + catch 降级） | ✅ |
| 第 3 轮（全面复核） | 未注册 custom_router_map、无测试、image 资源名修正（ic_app_logo） | ✅ 修正 1 处 |
| 第 4 轮（2026-10-27 逐条复核） | 连带读 `core/.../CoreInitializer.ets`（`readyPromise` 无 reject）、`LegalPreferences.hasAgreed`、`EntryAbility` initCore 失败路径 | catch 降级不可达 → 原 L1 升为 H1；原 L2 改号 L1 并修正行号 `:43-46` → `:41` 与「会崩溃」的错误描述；§3「UI 线程安全」改为通过。计数 0/0/0/2 → **0/1/0/1**，评级 A → **B**，债务 2 → 4 |
| 第 5 轮（2026-11-12 GAP-09） | 页面 94 → 91 行；新增 `viewmodel/LaunchViewModel.ets`（21 行）；`checkPrivacyAndProceed` / `navigateToMain` 改为调用 `viewModel.hasAgreed` / `waitForReady`，调用时机与 1200ms 下限不变；编译 + `entry@default` 单测通过 | ✅ 分层收口，行为不变 |
| 第 6 轮（2026-11-17 H1 修复） | 页面 91 → 173 行（错误态 + 超时 + 重试）、VM 21 → 32 行（`retryInit`）；`CoreInitializer` 增加 `readyReject` / `createReadyPromise` / `resetReady` / `initInFlight` / `registerReadyHook` / `runReadyHooks`（265 行）；`EntryAbility` 的 Widget / 通知初始化改为 ready hook；`assembleHap` BUILD SUCCESSFUL、全量单测 891 条全绿 | High 1 → 0、评级 B → A、债务 4 → 1；失败路径仍需真机手测 |
