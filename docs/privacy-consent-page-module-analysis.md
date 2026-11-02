# PrivacyConsentPage 模块独立分析文档

> 生成时间：2026-10-24
> 代码版本：`105c8d3`（本文档分析基线，2026-10-24 复核）
> 作用 scope：`features/legal/src/main/ets/pages/PrivacyConsentPage.ets` + `PrivacyConsentViewModel` + `PrivacyConsentFooter` + `PrivacyConsentWebView` + `LegalI18nRouter` + `LegalPreferences`

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 1 |
| Medium | 1 |
| Low | 1 |

**整体评级：B**

> 口径：skills `harmonyos-review` 官方 A-F 评级（0 Critical + High ≤ 3）。旧百分制已废弃，原分 93/100 仅作历史参考。
>
> 2026-10-27 复核：补登 1 条 High——协议内容不足一屏时"滑到底"永远不会触发，按钮全部禁用，用户卡死在隐私页（系统语言非中/英时必现，见风险清单），评级 A → B。

---

## 1. 文件清单

| 文件 | 类型 | 行数 | 职责 |
|------|------|------|------|
| `PrivacyConsentPage.ets` | Page / @ComponentV2 | 113 | 隐私合规两步流程（协议→政策）+ Preview |
| `PrivacyConsentViewModel.ets` | ViewModel（`@ObservedV2` + `@Trace`） | 54 | 两步流程状态（step / canProceed / canAgree） |
| `PrivacyConsentFooter.ets` | Component（子组件） | 99 | 底部操作栏（下一步 / 同意并继续 / 不同意退出） |
| `PrivacyConsentWebView.ets` | Component（子组件） | 110 | 加载 `rawfile/legal/*.html`，注入主题色与滚动检测脚本（`SCROLL_SCRIPT` `:16-28`），经 `scrollBridge` JS 代理回调 onReachedBottom |
| `utils/LegalI18nRouter.ets` | 共享工具 | 36 | 协议/政策本地化路径（Launch 也用） |
| `utils/LegalPreferences.ets` | 共享工具 | 48 | 同意状态持久化（Launch 也用） |

**直接导入依赖**：`common`, `ThemeFonts`, `BusinessError`, `ThemeManager`, `PrivacyConsentViewModel`, `LegalI18nRouter`, `LegalPreferences`, `RouterUtil`, `AppRoutes`, `Logger`, 2 个子组件

## 2. 架构分析（结构树）

```
PrivacyConsentPage (@ComponentV2)
├── @Local vm: PrivacyConsentViewModel (核心状态源)
├── @Local tm: ThemeManager
├── handleAgree() async — setAgreed → replace(MAIN)
├── handleDisagree() — terminateSelf()（退出应用）
├── build()
│   └── NavDestination
│       └── Column
│           ├── PrivacyConsentWebView (条件渲染: vm.step === 'terms' ? 协议 : 政策)
│           │   ├── htmlFile: LegalI18nRouter.termsPath() / privacyPath()
│           │   └── onReachedBottom → vm.markTermsRead() / markPrivacyRead()
│           └── PrivacyConsentFooter (两步状态驱动的底部栏)
│               ├── step: 'terms' | 'privacy'
│               ├── canProceed（页面按 step 取 vm.canProceedFromTerms / vm.canAgree）驱动三个按钮的 enabled
│               ├── onNext → goToPrivacy()
│               ├── onAgree → handleAgree()
│               └── onDisagree → handleDisagree()
├── PrivacyConsentPageBuilder (路由 Builder)
└── PrivacyConsentPagePreview (@Preview, mock 数据)
```

**架构模式**：MVVM — ViewModel 管理多步骤流程状态，页面只做条件渲染和事件转发。

## 3. ArkTS 合规性检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| `@ComponentV2` + `struct` | ✅ 通过 | |
| `@Local vm: ViewModel` | ✅ 通过 | ViewModel 实例化为 @Local 正确 |
| 条件渲染 (`if (vm.step === ...)`) | ✅ 通过 | ArkUI V2 支持条件渲染 |
| async/await in event handler | ✅ 通过 | `handleAgree()` 使用 async，符合规范 |
| terminateSelf 异常处理 | ✅ 通过 | `.catch()` 包裹了 terminateSelf 回调错误 |
| Preview 装饰器 | ✅ 通过 | 独立的 @Preview struct 提供 mock UI |

**ArkTS 结论：通过**

## 4. 组件复用分析

- **子组件已提取**：`PrivacyConsentFooter` + `PrivacyConsentWebView` 独立封装，符合高内聚原则
- **多页面共用**：`LegalPreferences.setAgreed()` / `hasAgreed()`、`LegalI18nRouter` 工具类被 Launch + PrivacyConsentPage 共同使用——复用模式正确
- **Preview 支持**：自带 mock Preview 提升开发体验

## 5. 安全审查

| 风险 | 级别 | 说明 |
|------|------|------|
| `terminateSelf()` 不可逆操作 | ℹ️ 低（预期行为） | 用户点击"不同意，退出"直接销毁应用，无二次确认；从合规流程设计角度这是预期设计，仅记录 |
| 协议不足一屏时无法继续 | ❌ **高** | `PrivacyConsentWebView.ets:22` 只在 `sh>ih` 时回调；内容不够一屏时"同意"与"不同意，退出"都不可点（`PrivacyConsentFooter.ets:42 / 57 / 69`），用户无法进入也无法通过按钮退出 |
| async/await 异常传播路径 | ⚠️ **中** | `setAgreed` 失败时仅 `Logger.error` 但仍 `RouterUtil.replace(MAIN)`（`:29-35`），可能出现"未落盘同意记录就进主界面"；建议 catch 中显示 Toast 或停在原页重试 |

**安全结论：通过（存在轻微瑕疵）**

## 6. 风险清单

- [ ] **高优先级**：协议/政策内容不足一屏时永远无法"滑到底"，用户卡死在隐私页。滚动检测脚本的条件是 `if(sh>ih && st+ih>=sh-50)`（`components/privacyconsent/PrivacyConsentWebView.ets:22`），`sh` 取 `max(body.scrollHeight, documentElement.scrollHeight)`，内容短于视口时 `sh == ih`，`onReachedBottom` 一次也不会触发；`setTimeout(check,500)`（`:27`）同样被这个条件拦下。于是 `canProceed` 恒为 false，"下一步"、"同意并继续"、"不同意，退出"三个按钮全部禁用（`PrivacyConsentFooter.ets:42 / 57 / 69`）。`LegalI18nRouter.ets:24` 对非中文、非英文的系统语言返回无后缀的 fallback 文件，而 `rawfile/legal/privacy.html` / `terms.html` 只有 1.5 KB 左右的占位文本（正文约 10 行），任何手机都一屏装得下——**系统语言为日语、韩语等时必现**；中文版在平板 / 折叠屏展开态也可能不足一屏。建议条件改为 `st+ih>=sh-50`（去掉 `sh>ih`，不足一屏即视为已读），并让"不同意，退出"不受阅读进度限制（行为修复，单独提交）
- [ ] **中优先级**：`handleAgree()` 中 `await LegalPreferences.setAgreed(ctx)` 失败后仍执行 `RouterUtil.replace(MAIN)`，可能导致用户未保存同意记录就进入主界面；建议 catch 分支显示 Toast 或返回重试
- [ ] **低优先级**：两步流程无进度指示（如步骤条），用户可能不确定当前处于第几步

*本文档仅分析，不修改代码。*

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数） | Page 113 / VM 54 / Footer 99 / WebView 110 / LegalI18nRouter 36 / LegalPreferences 48 | ✅ 全部精确匹配 |
| 第 2 轮（关键代码段） | handleAgree L28-35（catch 后仍 replace MAIN）、handleDisagree L38-43、build 条件渲染 + Footer 传参 | ✅ |
| 第 3 轮（全面复核） | 12 项 import、VM 三字段 + 两 getter + 三方法、Index.ets:5 Builder 导入、测试文件存在 | ✅ 无不一致 |
| 第 4 轮（2026-10-27 逐条事实） | WebView 滚动脚本 `:16-28`、Footer `enabled` `:42/57/69`、`LegalI18nRouter.ets:24` fallback 与 `rawfile/legal/*.html` 体量；测试 import 实际只有 VM | ✅ 新增 High（不足一屏卡死）；修正测试引用冻结项（无 `ViewStates`）；计数 0/0/1/1 → 0/1/1/1，评级 A → B |
| 第 5 轮（2026-11-02 M2 真重构） | 步骤常量迁入 `model/PrivacyConsentModels.ets`（VM re-export）；Page 提取 5 个 getter/handler；Footer 主按钮抽 `@Builder`；WebView 两处命名修正；编译 `bash run.sh uat` → BUILD SUCCESSFUL in 16s 153ms | ✅ 纯重构完成；High / Medium 行为修复仍单独提交 |
| 第 6 轮（2026-11-02 High 修复） | `SCROLL_DETECTION_SCRIPT` 增加 `sh <= ih` 直接上报 + `resize` 监听；编译 `bash run.sh uat` → BUILD SUCCESSFUL in 16s 145ms | ✅ High（不足一屏卡死）修复；与纯重构分开提交 |

---

## 重构执行备注（M2 · PrivacyConsent）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `PrivacyConsentPage` **不在** `custom_router_map.json`；路由名为 `AppRoutes.PRIVACY_CONSENT = 'PrivacyConsent'`，字符串冻结 |
| 页面 Builder | `PrivacyConsentPageBuilder` 由 `pages/Index.ets:5` 直接 import；**不在 routerMap 中**，因此这是少数可以执行 N-1 改名的页面 |
| 测试引用（冻结） | `viewmodel/PrivacyConsentViewModel.ets` 被 `entry/src/test/PrivacyConsentViewModel.test.ets:2` 导入（该测试只 import 这一个产品文件，不涉及 `ViewStates`），路径/导出符号不得变 |
| 共享工具（冻结） | `utils/LegalPreferences.ets`、`utils/LegalI18nRouter.ets` 同时被 `Launch` 使用，**不能**移进 `components/privacyconsent/` |
| 组件 | `components/privacyconsent/` 仅 2 个文件，保持原位；不拆 `PrivacyConsentViewModel`（54 行） |

### 重构范围（建议）

- 唯一安全的目录级改动：`pages/PrivacyConsentPage.ets` → `pages/PrivacyConsent.ets`（N-1），同步修改 `pages/Index.ets` 的 import。`PrivacyConsentPageBuilder` 函数名可以保留，避免额外契约变动。
- 若不想动 Index（M15 范围），则 M2 不改文件名，只记录。
- 不移动 `PrivacyConsentFooter` / `PrivacyConsentWebView`；不把 Legal* 工具搬进模块目录。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. DevEco Local Test：`PrivacyConsentViewModel.test.ets` 通过。
3. 冒烟：首次启动 → 隐私页 → 滚动到底 → 下一步 → 同意 → 进入 Main；再次启动不重复弹出。另将系统语言切到日语（走 fallback 短文本）验证按钮可用。

### 已知问题归属

- 高优先级（不足一屏卡死）：✅ 已于 2026-11-02 修复（见文末「High 修复」）；脚本在 `scrollHeight <= innerHeight` 时直接上报到底，并监听 resize。
- 中优先级（`setAgreed` 失败后仍 `replace(MAIN)`）：属于失败路径行为修复，若在 M2 修，必须与改名/移动分开提交；否则记录到 Refactor_Spec §11。
- 低优先级（无步骤指示）：不在重构范围。

---

## M2 真重构记录（2026-11-02）

### 改动

| 类型 | 文件 | 说明 |
| --- | --- | --- |
| 新增 | `model/PrivacyConsentModels.ets` | `PrivacyConsentStep` 常量集中定义（值仍为 `'terms'` / `'privacy'`） |
| 契约 | `viewmodel/PrivacyConsentViewModel.ets` | 引用 model 常量并 re-export；`step` 类型与测试断言不变 |
| 清理 | `pages/PrivacyConsentPage.ets` | 提取 `isTermsStep` / `currentHtmlFile` / `canProceed` / `currentTitle` / `handleReachedBottom`，去掉 build 内重复三元与字符串比较 |
| 去重 | `views/PrivacyConsentFooter.ets` | 「下一步」「同意并继续」共用的主按钮样式抽为 `@Builder primaryButton` |
| 命名 | `views/PrivacyConsentWebView.ets` | `SCROLL_SCRIPT` → `SCROLL_DETECTION_SCRIPT`；`injectAll` → `injectThemeAndScrollScript` |

### 行为等价说明

- 步骤常量值与原字符串完全一致；`step` 仍是 `string`，测试 `assertEqual('terms'/'privacy')` 不受影响。
- 页面仍按 `step` 渲染两个 `PrivacyConsentWebView` 分支，未合并组件实例（避免 `Web.src` 动态更新的不确定性）。
- Footer 主按钮的尺寸、颜色、禁用逻辑与原两段代码逐项一致。

### 验收

| 项 | 结果 |
| --- | --- |
| 编译 | ✅ `bash run.sh uat` → `BUILD SUCCESSFUL in 16s 153ms` |
| 测试契约 | ✅ `viewmodel/PrivacyConsentViewModel.ets` 路径、`PrivacyConsentViewModel` / `PrivacyConsentStep` 导出不变 |
| 冒烟 | 🔶 待手动：首次启动两步流程、同意后进 Main、重启不重复弹出 |

### 未执行

- High（协议不足一屏时按钮永久禁用）：✅ 已在本轮后续提交修复（见下节「High 修复」）。
- Medium（`setAgreed` 失败后仍 `replace(MAIN)`）：行为修复，保留。

---

## High 修复（2026-11-02）

**问题**：`SCROLL_DETECTION_SCRIPT` 只在 `sh > ih` 时检查是否滚到底；当协议内容不足一屏（系统语言走 fallback 短文本时必现）时，页面没有滚动事件，`onReachedBottom` 永不触发，步骤一「下一步」和步骤二两个按钮永久禁用，用户卡死。

**修复**：

```js
if (sh <= ih) {
  if (window.scrollBridge) { window.scrollBridge.onReachedBottom(); }
  return;
}
```

并增加 `window.addEventListener("resize", check)`，覆盖旋转屏幕 / 字体变化导致的可视区变化。

**验证**：`bash run.sh uat` → `BUILD SUCCESSFUL in 16s 145ms`；VM 的 `markTermsRead` / `markPrivacyRead` 幂等，重复上报无副作用。

**遗留**：Medium（`setAgreed` 失败后仍 `replace(MAIN)`）未修；若持久化失败，用户下次启动会再次看到隐私页。
