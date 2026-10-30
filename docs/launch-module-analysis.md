# Launch 模块独立分析文档

> 生成时间：2026-10-24
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）
> 作用域：`entry/src/main/ets/pages/LaunchPage.ets` + 直接依赖（CoreInitializer, ThemeManager, RouterUtil, LegalPreferences, AppRoutes）

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 1 |
| Medium | 0 |
| Low | 1 |

**整体评级：B**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + High ≤ 3 → B）。旧百分制已废弃，原分 92/100 仅作历史参考。
>
> 债务点数 = 1×3 + 0×2 + 1×1 = **4**，密度 = 4 ÷ 0.94 = **4.3**（2026-10-27 复核前为 0/0/0/2、A、2 点、2.1）。判为 High 的理由：`navigateToMain()` 的 catch 降级在现有代码下不可达，Core 初始化一旦失败，用户永久停在启动页且无任何提示或重试入口。

---

## 1. 文件清单

| 文件 | 类型 | 行数 | 职责 |
|------|------|------|------|
| `LaunchPage.ets` | Page / @ComponentV2 | 94 | 启动闪屏页，含 Logo 动画 + 隐私合规检查 |
| `PrivacyConsentPage.ets` | Page（间接依赖） | 113 | 由 Launch 在用户未同意时替换导航 |

**直接导入依赖**：`CoreInitializer`, `ThemeManager`, `AppRoutes`, `RouterUtil`, `LegalPreferences`, `common`, `Logger`, `ThemeFonts`

## 2. 架构分析（结构树）

```
Launch (@ComponentV2)
├── @Local tm: ThemeManager (主题状态)
├── @Local logoScale: number (动画状态)
├── @Local logoOpacity: number (动画状态)
├── private uiCtx: UIContext | null (UI 上下文，缓存 avoid 重复 getUIContext)
├── aboutToAppear()
│   ├── this.uiCtx = this.getUIContext()
│   ├── animateTo(600ms, Logo 淡入放大)
│   └── checkPrivacyAndProceed()
│       ├── LegalPreferences.hasAgreed(ctx) → true → navigateToMain()
│       └── false → RouterUtil.replace(PRIVACY_CONSENT)
├── navigateToMain()
│   ├── Promise.all([CoreInitializer.waitForReady(), minDelay 1200ms])
│   │   → RouterUtil.replace(MAIN)
│   └── catch → RouterUtil.replace(MAIN)（降级；实际不可达，见 H1）
└── build()
    └── NavDestination
        └── Column (居中布局)
            ├── Image (ic_app_logo, 缩放 + 透明动画绑定)
            ├── Text (app_name, bold26, 透明动画绑定)
            └── Text (launch_subtitle, 透明动画绑定)
```

**架构模式**：单页直写型（无 ViewModel），UI 逻辑集中在页面内，同步初始化 → 异步导航链式调用。

## 3. ArkTS 合规性检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| `@ComponentV2` + `struct` | ✅ 通过 | 符合当前版本规范 |
| 状态装饰器正确性 | ✅ 通过 | `@Local` 用于内部私有状态，合理 |
| `themeManager` 单例引用 | ✅ 通过 | `@Local tm: ThemeManager = themeManager` |
| `aboutToAppear` 使用 | ✅ 通过 | 初始化动画 + 合规检查 |
| NavDestination 根节点 | ✅ 通过 | 最外层正确包裹 |
| UI 线程安全 | ✅ 通过 | `setTimeout` 与 Promise 回调都在 UI 线程的事件循环中执行，`.then()` 里只做路由跳转 |
| 异常降级处理 | ❌ 不成立 | `catch` 分支（`:59-62`）只在 `Promise.all` reject 时执行，但 `waitForReady()` 与 `minDelay` 都不会 reject（见 H1） |

**ArkTS 结论：语法与状态管理通过；启动降级逻辑失效（H1）**

## 4. 组件复用分析

- **无独立 @Component 子组件**：所有 UI 结构内联在 `build()` 中，代码量小（~94 行），暂无拆分需求
- **Logo 动画逻辑与主题字体** 通过 `ThemeManager` / `ThemeFonts` 实现外部化——值得肯定
- `PrivacyConsentPage` 作为独立路由目标已封装良好

## 5. 安全审查

| 风险 | 级别 | 说明 |
|------|------|------|
| `getUIContext().getHostContext()` 类型断言 | ⚠️ 低 | `:41` 直接 `as common.UIAbilityContext`，无空值 / 类型检查；`LegalPreferences.hasAgreed()` 内部 try/catch（`LegalPreferences.ets:19-25`），异常时返回 `false`，表现为已同意用户被再次送到隐私页，不会崩溃 |
| Promise.all 无超时、catch 不可达 | ❌ 高 | `waitForReady()` 返回的 `readyPromise` 只有 resolve 句柄（`core/.../CoreInitializer.ets:38-40`），只在 `initCore` 成功末尾 resolve（`:160-162`）；`initCore` 抛错（如 `RdbManager.init` 失败）时它永远 pending。`minDelay` 也不会 reject，所以 `:59-62` 的 catch 永远不执行 |

**安全结论：无安全漏洞；存在 1 项可靠性 High**

## 6. 风险清单

- [ ] **高优先级 H1**：Core 初始化失败时永久卡在启动页（`LaunchPage.ets:53-62`）。`Promise.all([waitForReady(), minDelay])` 的两个成员都不会 reject，catch 降级到 MAIN 是死代码；而 `EntryAbility.ets:43-45` 对 initCore 失败只记日志。结果是用户只看到 Logo，无提示、无重试，只能杀进程（下次启动大概率同样失败）。建议对 `waitForReady()` 加超时（如 `Promise.race` 10s）后仍进入 Main 并展示错误态，或让 core 在 initCore 失败时 reject `readyPromise`（后者改 core，需单独评审）
- [ ] **低优先级 L1**：`getHostContext()` 直接 `as common.UIAbilityContext` 断言（`:41`），无空值 / `instanceof` 校验；`hasAgreed()` 内部兜底返回 `false`，不会崩溃。与 AccountDetail（M11）的同一类问题
- （2026-10-27 编号调整）原 L1「`waitForReady` 无超时」按实际影响升为 H1；原 L2 改号为 L1，Low 由 2 条变为 1 条
- [ ] **信息提示**（不计入 Low）：启动页动画 + 隐私检查总耗时取决于 Core 初始化速度，若初始化慢则用户等待时间较长

---

## 7. 重构执行备注（M12/M15）

> 执行以 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) 为准。

**路由事实**

- `Launch` **未注册**在 `custom_router_map.json`，也没有 `@Builder`；它由 `Index.pageBuilder` 直接 `new Launch()` 渲染，路由名 `AppRoutes.LAUNCH` 只存在于 `NavPathStack`。因此**不能**仅凭“移动文件”就期望路由继续工作——移动必须同步 `Index.ets` 的 import + 分支。
- 隐私同意页也是"非 routerMap"页面：`PrivacyConsentPageBuilder` 由 `Index.ets:5` 直接 import 调用，Launch 用 `RouterUtil.replace(AppRoutes.PRIVACY_CONSENT)` 跳转。两者都不进 routerMap，迁动时要同时改 import 与分支。

**不变量与风险**

1. `navigateToMain()` 的「`Promise.all([waitForReady(), 1200ms])` → replace(MAIN)」是启动契约；旧文档声称的「catch 降级也进主界面」**当前并不生效**（H1）。抽 `BootstrapGate` 时若要真正兜底，必须给 `waitForReady()` 加超时，单纯保留 catch 没有意义。1200ms 下限同时为 Main 读取 AppStorage `windowClass` 留出了时间（见 main M7），缩短或去掉前要先处理该时序。
2. 各 ViewModel 也直接 `await CoreInitializer.waitForReady()`（`HomeViewModel.ets:148`、`CharactersViewModel.ets:123`、`ToolsViewModel.ets:52` 等），首装路径（隐私页 → `PrivacyConsentPage.ets:35` 直接 replace MAIN）也依赖它；若引入 `withTimeout()`，放在 M15 公共层统一使用，别在各模块各写一份。
3. `LegalPreferences.hasAgreed(ctx)` 的结果决定首屏，重构不得改变「已同意直接进 Main」的快路径。

**测试**：无自动化测试；必须手测三条路径——首次安装（Launch → 隐私页 → 同意 → Main）、已同意冷启动（Launch → Main）、Core 初始化异常（当前会停在启动页；H1 修复后应进入 Main 并提示）。

**拆分建议**：Launch 只有 94 行，属 M15 尾部；优先把 `checkPrivacyAndProceed` / `navigateToMain` 抽成 `LaunchFlow`，UI 与动画留在页面内，不做无收益的组件化。

---

*本文档仅分析，不修改代码。*

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | Launch 94 行 / PrivacyConsentPage 113 行、结构树全节点、8 项导入 | ✅ 全部精确匹配 |
| 第 2 轮（关键代码段） | aboutToAppear L30-38、checkPrivacyAndProceed L40-49、navigateToMain L51-63（1200ms + catch 降级） | ✅ |
| 第 3 轮（全面复核） | 未注册 custom_router_map、无测试、image 资源名修正（ic_app_logo） | ✅ 修正 1 处 |
| 第 4 轮（2026-10-27 逐条复核） | 连带读 `core/.../CoreInitializer.ets`（`readyPromise` 无 reject）、`LegalPreferences.hasAgreed`、`EntryAbility` initCore 失败路径 | catch 降级不可达 → 原 L1 升为 H1；原 L2 改号 L1 并修正行号 `:43-46` → `:41` 与「会崩溃」的错误描述；§3「UI 线程安全」改为通过。计数 0/0/0/2 → **0/1/0/1**，评级 A → **B**，债务 2 → 4 |
