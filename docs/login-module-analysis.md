# Code Review Report · `Login` Module

> **审查对象**：`features/account/src/main/ets/pages/LoginPage.ets` + `features/account/src/main/ets/viewmodel/LoginViewModel.ets` + `features/account/src/main/ets/views/`（18 个文件，入口为 `LoginNarrowLayout.ets` / `LoginWideLayout.ets`）
> **审查日期**：2026-10-24
> **审查者**：AI 助手
> **代码版本**：`105c8d3`
> **HarmonyOS SDK**：`6.0.2(22)`（`targetSdkVersion` / `compatibleSdkVersion`，见根 `build-profile.json5`）/ `@ComponentV2`

---

## 执行摘要

| 优先级 | 数量 |
| --- | --- |
| Critical | 0 |
| High | 0 |
| Medium | 5 |
| Low | 3 |

**整体评级：A**（0 Critical + 0 High，Medium 5 ≤ 5）

> 源行数 129（`LoginPage.ets`）；债务点数 = 0×3 + 5×2 + 3×1 = **13**；密度 = 13 ÷ 1.29 ≈ **10.1**/百行。

> Login 模块功能完整（手机号 / 二维码 / Cookie 三种登录方式），架构分层清晰（Page → ViewModel → Layout）；状态管理正确使用 V2，`@Event` 用法合法但与项目风格不统一。原「二维码轮询无取消标记」High 经基线 `105c8d3` 复核不成立（`b98abae` 已加 `qrGeneration` + `pollInFlight` 双保险），已撤回；原「Cookie 日志明文 token」Critical 经逐层核查同样不成立（`LoginViewModel.ets:350` 只记录 `error.message`，见下节），降为 Medium 加固建议。另有一条 Medium：错误提示直接展示原始异常文本、二维码请求失败被展示为「已过期」（M4）。因此本模块**无 Critical / 无 High**。

---

## 文件清单

| 文件 | 行数 | 职责 |
| --- | --- | --- |
| `pages/LoginPage.ets` | 129 | 页面：窄/宽布局切换、协议 WebView 跳转、登录成功跳转、无 stoken 弹窗 |
| `viewmodel/LoginViewModel.ets` | 415 | 手机号 / 二维码 / Cookie 三种登录、QR 轮询、短信冷却、`finalizeLogin` |
| `constants/LoginConstants.ets` | 28 | `LoginTab` / `PhoneStep` / `QRCodeStat`（前两者被测试导入，冻结） |
| `components/login/LoginNarrowLayout.ets` / `LoginWideLayout.ets` | 36 / 61 | 窄屏单栏 / 宽屏两栏 |
| `components/login/LoginCard.ets` / `LoginTabBar.ets` / `LoginTabItem.ets` / `LoginTabContent.ets` | 31 / 44 / 37 / 28 | 卡片 + Tab 栏 + Tab 内容分发 |
| `components/login/LoginPhone.ets` / `LoginPhoneInput.ets` / `LoginCodeInput.ets` | 40 / 54 / 83 | 手机号登录（含 `errorMsg` 展示） |
| `components/login/LoginQRCode.ets` / `LoginQRCodeLoading/Ready/Confirmed/Expired.ets` | 96 / 25 / 36 / 25 / 45 | 二维码登录；`QRCode()` 本地生成（`LoginQRCodeReady.ets:16`） |
| `components/login/LoginCookie.ets` | 85 | Cookie 登录（含 `errorMsg` 展示） |
| `components/login/LoginLogoSection.ets` / `LoginFeatureItem.ets` / `LoginAgreement.ets` | 45 / 42 / 39 | 品牌区 / 特性项 / 协议链接 |
| `entry/src/test/LoginViewModel.test.ets` | 162 | 22 个用例（测试资产，不计入评级） |

> `components/login/` 合计 18 个文件 852 行。`components/Geetest*.ets` / `utils/GeetestCenter.ets` / `utils/GeetestSignal.ets` **不属于本模块**：Login 链路不导入它们，人机验证由 `MainPage.ets` 统一弹出（见 [main-module-analysis.md](./main-module-analysis.md)）；本次仅在安全复核中顺带确认其日志不含 Cookie。

## 结构树 / 调用链

```
Login (@ComponentV2, LoginPage.ets:16)
├─ aboutToAppear → vm.init()（:23-25）      aboutToDisappear → vm.dispose()（:27-29）
├─ onAreaChange → windowWidth（:102-104）；≤ value480 → LoginNarrowLayout，否则 LoginWideLayout（:84-96）
│   └─ LoginCard → LoginTabBar(LoginTabItem → vm.switchTab) + LoginTabContent
│        ├─ PHONE  → LoginPhone → LoginPhoneInput(sendSmsCode) / LoginCodeInput(loginByPhone)
│        ├─ QRCODE → LoginQRCode → Loading / Ready / Confirmed / Expired(refreshQRCode)
│        └─ COOKIE → LoginCookie(loginByCookie)
│   └─ LoginAgreement → @Event onTapTerms / onTapPrivacy → pushWebView → AppRoutes.WEB_VIEW（:31-50）
├─ @Monitor('vm.loginSuccess') → AccountSignal.notify() → replacePath(ACCOUNT_DETAIL)（:52-65）
└─ @Monitor('vm.showNoStokenDialog') → showAlertDialog（:67-79）

LoginViewModel
├─ loginByPhone（:122-156）/ handleQRCodeConfirmed（:275-310）/ loginByCookie（:314-355）
│   └─ AuthRepository.getLTokenBySToken / getCookieBySToken / buildCookieString → finalizeLogin
└─ finalizeLogin（:359-393）→ CoreInitializer.bbsRepository.login → MyAccountVM → loginSuccess = true
```

---

## 安全项复核（原 Critical，已降级）

### 1. [SEC-002 · Medium] Cookie 登录失败日志的防御性加固

- **位置**：`features/account/src/main/ets/viewmodel/LoginViewModel.ets:347-355`（`Logger.error` 在 `:350`）
- **现状核查（2026-10-24，`105c8d3`）**：逐层查过 `loginByCookie()` 的异常路径，**当前不存在把凭据写进日志的语句**：
  1. `LoginViewModel.ets:348-351` 的 catch 只把 `error.message`（非 Error 时 `${error}`）拼进日志，未直接引用 `cookieInput` / `cookie` / `fields`；
  2. try 内被 await 的调用是 `bbsRepository.getBbsAccountDetail(cookie)` 与 `finalizeLogin()`。前者抛错来自 `core/src/main/ets/MihoyoKit/repository/BBSRepository.ets:482` / `:501`，消息里只有 `retcode` 与服务端 `message`，不含 Cookie；后者的 `bbsRepository.login()` 异常在 `LoginViewModel.ets:364-368` 自行捕获并只记 `error.message`，`login()` 内拉角色的子调用异常被 `catch (_) {}` 吞掉（`BBSRepository.ets:93-128`），本身不拼 Cookie；
  3. 登录链路里其余的 Cookie 相关日志只有 `core/src/main/ets/MihoyoKit/repository/AuthRepository.ets:225` 的 `buildCookieString result length: ${cookie.length}`（长度，非内容）；`AuthRepository.ets` 其余抛错（`:79/92/103/112/127/149`）同样只含 `retcode` + 服务端 `message`。
  4. **落盘日志**：唯一写文件的是 core 的 `ApiLogSystem`（`core/src/main/ets/base/log/LogFileManager.ets`，沙箱 `files/logs/`）。HTTP 层只写脱敏后的 URL + 状态码 / 耗时（`core/src/main/ets/base/network/BaseApiService.ets:126-157`，`redactUrl` 屏蔽 `stoken` / `ltoken` / `cookie_token` 等 query），不写请求头与响应体；`BBSRepository.ets:494-498` 写入的是上面第 2 点的 `msg`。均不含 Cookie / token。
  5. **Release 行为**：`Logger.canOutput()` 在 release 下只放行 INFO / WARNING（`core/src/main/ets/base/utils/Logger.ets:237-242`），`:350` 的 `Logger.error` 在 release 包中根本不输出；debug 包中 hilog 参数一律 `%{public}s`（`Logger.ets:161-162`）。
  6. entry 全目录检索 `Logger.*(...cookie|token...)`，命中的 `HomeViewModel.ets:354`、`AccountDetailViewModel.ets:82/89` 只拼 `username` 与错误消息；Geetest 链路 `GeetestCenter.ets:66/82` 只记录接口 URL 与错误消息，`GeetestTrigger.cookie` 不入日志。
- **残余风险**：`error.message` 的内容不受本模块控制。若将来上游把请求头 / 请求上下文拼进异常消息，或换用会回显请求的调试版 HTTP 客户端，凭据会随这条日志落盘。属于**纵深防御**，不是现行违规。
- **影响**：当前不构成 AGC-RJ-007 违规（无凭据进入日志或日志文件的路径），因此不再作为「阻断上架」项；保留一条脱敏约定可避免后续回归。
- **相关问题（不在本文档计数）**：Cookie / stoken 作为账号凭据由 core 持久化到 RDB（`BBSRepository.login` → `upsertOrUpdateAccount`），`core/src/main/ets/db/RdbManager.ets:22-25` 的 `StoreConfig` 仅设 `SecurityLevel.S1`、未开 `encrypt: true`，且 entry `backup_config.json` 的 `allowToBackupRestore: true` 会把该库带入系统备份。该问题按跨文档口径**只在 [ability-and-startup-modules-analysis.md](./ability-and-startup-modules-analysis.md) 以 DB-003 · High 计数**，本文档仅引用，不计入 Login 评级。
- **附注**：原报告的 `LoginViewModel.ets:302` 是 `b98abae` 时的行号，`105c8d3` 之后该 catch 已后移到 `:348-355`。
- **建议修复**：

```typescript
// ❌ 当前（LoginViewModel.ets:347-355）
const bbsDetail = await CoreInitializer.bbsRepository.getBbsAccountDetail(cookie);
// ...
} catch (error) {
  const msg = error instanceof Error ? error.message : `${error}`;
  Logger.error(TAG, `loginByCookie failed: ${msg}`);
}

// ✅ 改写：日志不拼接可变的 error.message，message 只用于 UI
// （注：Logger.error 签名为 (tag, message, context?)，不支持 %{public}s 占位参数；fields 定义在 try 块内，catch 中不可引用）
const msg = error instanceof Error ? error.message : `${error}`;
Logger.error(TAG, `loginByCookie failed: ${error instanceof Error ? error.name : typeof error}`);
this.errorMsg = msg;
```

- **参考**：`references/checklist.md` § 1 · SEC-002；`report-template.md` 引用规则

### 2. [LIFE-001 · 已修复，不计入 High] QR Code 轮询取消标记（基线复核撤回）

- **原报告位置**：`LoginViewModel.ets:198-201`
- **复核结论（2026-10-24，`105c8d3`）**：该问题**不成立**。`b98abae` 已在 `startQRCodePoll()` 中加入 `generation` 校验与 `pollInFlight` 互斥（`:216-231`），`stopQRCodePoll()` 会 `qrGeneration += 1` 并清 timer（`:232-244`），`pollQRCodeStatus()` 每次 await 后都校验 generation（`:245-274`）。页面销毁后即使请求才返回，也会因 generation 不匹配而丢弃结果。
- **残留（非 High）**：`AuthRepository.queryQRCode()` 本身没有 `AbortSignal`，请求不会真正中止，只是结果被丢弃；如需节省流量可在 Repository 层补取消能力，属优化项，不影响状态正确性。
- **参考**：`references/checklist.md` § 4 · LIFE-001

---

## 合规检查（skills checklist）

> 逐条对照 `.opencode/skills/harmonyos-review/references/checklist.md`，只列与本模块相关的条目。PERM / KIT 类不适用；DB-003 归属 Ability 文档计数，此处仅引用。

| ID | 检查项 | 结论 | 证据 / 说明 |
| --- | --- | --- | --- |
| STATE-001 | 不混用 V1 / V2 | ✅ | `LoginPage.ets` 为 `@ComponentV2`，`LoginViewModel` 为 `@ObservedV2`；`components/login/` 18 个文件无 `@State` / `@Prop` / `@Link` |
| STATE-002 / STATE-003 | 状态变更走引用替换 | ✅ | VM 字段均为标量或整体赋值，无就地 mutation |
| STATE-007 | `@Event` 必须带默认值 | ✅（但有风格不统一） | `LoginNarrowLayout.ets:13-14` / `LoginWideLayout.ets:15-16` / `LoginAgreement.ets:10-11` 的 `@Event` 都有 `() => {}` 默认值；与全项目 `@Param` 回调风格不一致（已记 M1） |
| STATE-012 | `@Monitor` 内不修改触发字段 | ⚠️ Medium | `LoginPage.ets:67-79` 在 `@Monitor('vm.showNoStokenDialog')` 内把它置 `false`；不造成死循环，但职责错位（已记 M3） |
| STATE-013 | 跨页面共享状态用 AppStorage | ✅ | 登录态通过 `CoreInitializer` 仓库层与 Signal 传递，未用全局变量 |
| LIFE-001 | `aboutToDisappear` 取消订阅 / 定时器 | ✅ | `LoginPage.ets:27-29` → `vm.dispose()`；QR 轮询用 `qrGeneration` + `pollInFlight`（`LoginViewModel.ets:67/69`）丢弃旧代结果 |
| LIFE-004 | 弹窗生命周期 | ⚠️ Low | `LoginPage.ets:67-79` `showAlertDialog` 无 dismiss 回调（已记 L2） |
| PERF-001 | 无 `forEach + await` | ✅ | 登录流程用 `for` 循环；步骤串行是业务语义，非反模式 |
| PERF-004 | 重计算不阻塞 UI | ⚠️ Medium | `finalizeLogin()`（`LoginViewModel.ets:359-393`）双层循环每次 `new` VM 对象；角色数少时无感，代码复杂度高（已记 M2） |
| ARKTS-012 | 日志走 hilog | ✅ | 全模块无 `console.*`，统一 `Logger` |
| ARKTS-013 | 无魔法数字 | ⚠️ Low | `LoginViewModel.ets:57/65/229/406`（已记 L1） |
| SEC-002 | 敏感数据（Cookie）不入日志 | ⚠️ Medium | `LoginViewModel.ets:350` 拼接 `error.message`，当前不涉 cookie 变量（已复核降级，见 §1） |
| KIT-003 / KIT-004 | ScanKit 导包与 `ScanType` 新名 | n/a | 二维码由 ArkUI `QRCode()` 组件本地生成（`LoginQRCodeReady.ets:16`），由米游社 App 扫码，本端不扫码、未用 ScanKit |
| DB-003 | 敏感数据用加密 RdbStore | ❌ 见 Ability 文档（本文档不计数） | Cookie / stoken 由 core `RdbManager.ets:22-25` 以 `SecurityLevel.S1` 存储、未开 `encrypt`，叠加 entry 备份开关；在 [ability-and-startup-modules-analysis.md](./ability-and-startup-modules-analysis.md) 记 High（见 §1「相关问题」） |
| TEST-001 | 核心逻辑有单测 | ✅（有缺口） | `LoginViewModel.test.ets` 162 行 22 用例（含 `maskedPhone` 3 条，`:88-106`）；`finalizeLogin`、Cookie 字段解析、QR 轮询未覆盖（不计入 L） |

> 合规结论：无 Critical。唯一的旧 Critical（Cookie 日志）经复核仅剩防御性加固，与 §6 评级依据一致。

---

## Medium Issues（技术债）

### 1. [STATE-007 · Medium] `@Event` 与 `@Param` 回调风格不统一

- **位置**：`LoginNarrowLayout.ets:13-14`、`LoginWideLayout.ets:15-16`、`LoginAgreement.ets:10-11`（同组件内 `LoginPhoneInput.ets:11` / `LoginCodeInput.ets:11` / `LoginQRCodeExpired.ets:10` 则用 `@Param` 传回调）
- **问题**：子组件声明 `@Event onTapTerms: () => void = () => {}`，父组件传入回调、子组件点击时调用——这本身是 `@Event` 的合法用法（子→父通知）。但与项目内其它页面用 `@Param` 传只读回调的风格不一致，阅读时容易误判方向。
- **影响**：不是功能缺陷；若统一风格，可在 `LoginNarrowLayout` / `LoginWideLayout` 改为 `@Param readonly onTapTerms?: () => void`，并保留空值判断。
- **建议修复**：

```typescript
// ❌ LoginNarrowLayout.ets:13-14
@Event onTapTerms: () => void = () => {};
@Event onTapPrivacy: () => void = () => {};

// ✅ 改写：父→子回调，用 @Param + readonly
@Param readonly onTapTerms?: () => void;
@Param readonly onTapPrivacy?: () => void;

// 使用时判断
if (this.onTapTerms) { this.onTapTerms() }
```

- **参考**：`references/checklist.md` § 3 · STATE-007；`state-management` skill

### 2. [PERF-004 · Medium] `finalizeLogin` 中角色列表循环创建对象

- **位置**：`features/account/src/main/ets/viewmodel/LoginViewModel.ets:359-393`
- **问题**：`for (let i = 0; i < loginResult.roles.length; i++)` 内嵌套 `for (let j = 0; j < rawStats.length; j++)`，每轮都 `new MyGameRoleVM(...)` 和 `new GameStatItem(...)`。在登录流程中这是同步一次性操作，不算性能瓶颈；但如果角色数多（>50），可在 TaskPool 执行。
- **影响**：这段循环位于 `bbsRepository.login()` 返回之后、仍在 UI 线程同步执行；角色数通常个位数，当前不构成可感知卡顿，主要问题是可读性差、嵌套过深。
- **建议**：提取为独立工具函数 `buildAccountVMFromLoginResult()`，降低圈复杂度。
- **参考**：`references/checklist.md` § 7 · PERF-004

### 3. [STATE-012 · Medium] `@Monitor` 回调中设 `this.vm.showNoStokenDialog = false`

- **位置**：`features/account/src/main/ets/pages/LoginPage.ets:67-79`
- **问题**：`onShowNoStokenDialog(@Monitor path)` 检测到 `showNoStokenDialog` 变化后，立即将其设为 `false`。monitor 在属性变更 **之后** 触发，**不会造成无限循环**；这是可读性/职责归属问题，不是 STATE-012 的循环缺陷。更直观的做法是在业务逻辑内部自行关闭。
- **建议**：将 `showNoStokenDialog = false` 移到调用方（即 Alert 消失后的回调中），或考虑直接用 `customDialog` 而非 `showAlertDialog` 以获得更好的生命周期管理。

### 4. [UX / i18n · Medium] 错误提示直接展示原始异常文本；二维码请求失败显示为「已过期」

- **位置**：`LoginViewModel.ets:116/152/202/305/351/367`（`this.errorMsg = msg`）→ `LoginPhone.ets:30-31`、`LoginCookie.ets:59-60`（`Text(this.vm.errorMsg)`）；`LoginQRCode.ets:29-33`
- **问题**：
  1. `errorMsg` 直接取 `error.message`，内容是 core 拼出的技术串（如 `getLTokenBySToken failed: [retcode] message`、`BBSRepository.getBbsAccountDetail failed: getBbsAccountDetail failed: [retcode] message`），未映射成本地化资源，用户在手机号 / Cookie 页看到的是开发者文本。空输入校验写入的错误码（`phone_empty` / `code_empty` / `cookie_empty`，`LoginViewModel.ets:104/124/316`）同样未经映射，被 `Text(this.vm.errorMsg)` 原样显示为英文标识符。
  2. 二维码页不渲染 `errorMsg`，`QRCodeStat.ERROR` 与 `EXPIRED` 共用 `LoginQRCodeExpired`（`:29-33`），显示 `login_qrcode_expired` 文案——网络失败 / `qr_confirm_missing_token`（`:257`）/ `finalizeLogin` 失败都被告知为「二维码已过期」。
- **影响**：失败本身用户能感知且可重试（刷新按钮可用），不阻断功能，故记 Medium；但错误原因不可读或被误导。
- **建议**：VM 只产出错误码（`phone_empty` 等已是此形式，且被测试断言），由 View 层映射为 `$r('app.string.*')`（目前 View 层缺这一步）；QR 页为 `ERROR` 单独展示失败文案。保持错误码字符串不变即可不动测试断言（`LoginViewModel.test.ets:77/83/137/144`）；改动属行为变更，不在纯目录重构中夹带。

---

## Low Issues（建议优化）

| 规则 ID | 文件 | 问题 | 建议 |
| --- | --- | --- | --- |
| ARKTS-013 | `LoginViewModel.ets:57,65`（`-1` sentinel）、`:229`（`2000` 轮询间隔）、`:406`（`1000` 冷却计步） | 魔法数字 / 空值 sentinel 硬编码在方法体内 | 提取 `const QR_POLL_INTERVAL_MS = 2000`、`const COOLDOWN_TICK_MS = 1000`；timer 用 `type TimerId = number; const INVALID_TIMER: TimerId = -1;` |
| LIFE-004 | `LoginPage.ets:67-79` | `showAlertDialog` 无 dismiss 回调设置关闭标志，关闭时机依赖 `@Monitor` | 换 `customDialog` 获得明确的关闭回调（与 M3 的 STATE-012 一并处理） |
| 重复逻辑 | `LoginPage.ets:34-43` vs `utils/LegalI18nRouter.ets:13-25` | 协议文件语言后缀在两处各写一份且规则不一致：Login 按「语言含 `Hant` 或地区 HK/TW/MO」判繁体、非中文一律 `-en`；`LegalI18nRouter` 只认 `zh-Hant*` / `zh-HK|TW|MO` 语言码、非中英文回落无后缀文件。同一设备上隐私同意页与登录页可能打开不同语言版本的协议 | Login 改用 `LegalI18nRouter.termsPath()` / `privacyPath()`（行为变更，单独提交） |

> **不计入 L 的技术缺口**（TEST-001，按 README §1.4 口径）：`LoginViewModel.test.ets`（162 行 22 用例，覆盖初始状态 / switchTab / 空输入校验 / `maskedPhone` / `backToPhoneInput` / 路径常量）未覆盖 `finalizeLogin()`、Cookie 字段解析、QR 轮询。属测试资产，记录于此不参与评级。

---

## 整体观察

- **代码质量**：ViewModel 封装清晰，三种登录方式通过 `activeTab` + `phoneStep` / `qrCodeStat` 等状态变量切换；错误处理统一用 `instanceof Error` 断言。
- **架构**：Page → ViewModel → Repository 分层明确；窄宽屏适配通过 `onAreaChange` 写 `windowWidth` 再与 `value480` 比较实现（`LoginPage.ets:84/102-104`），登录成功跳转由 `@Monitor('vm.loginSuccess')` 驱动（`:52-65`），响应式链路正确（`@ObservedV2` + `@Trace`）。
- **状态管理**：全部使用 V2 装饰器（`@Local` / `@Param` / `@Event`），无 V1 混用。LoginViewModel 正确标注 `@ObservedV2`，字段标 `@Trace`。
- **测试覆盖**：`entry/src/test/LoginViewModel.test.ets` 已覆盖初始状态、`switchTab`、空输入校验、`maskedPhone` 等 22 个用例；Cookie 字段解析、`finalizeLogin()`、QR 轮询仍无测试。

---

## 修复建议优先级

| Phase | 任务 | 预估工作量 |
| --- | --- | --- |
| **P1 · 顺手（原 P0，复核降级）** | SEC-002: Cookie 日志脱敏（加固，非阻断） | 15 分钟 |
| **P1 · 本周** | STATE-007: `@Event` → `@Param` 回调统一、PERF-004: `finalizeLogin` 角色映射抽函数 | 半天 |
| **P2 · 下迭代** | M4: 错误码 → 本地化文案映射、QR 错误态独立展示（行为变更，单独提交） | 半天 |
| **P2 · 下迭代** | LIFE-004: AlertDialog → CustomDialog、TEST-001: 补充核心逻辑单测 | 2 天 |
| **P3 · 长期** | 提取 `finalizeLogin` 角色映射为独立函数、类型安全 TimerId、协议路径改用 `LegalI18nRouter` | 顺手 |

---

## 复审建议

如做日志脱敏，改后运行 `hvigorw codeLinter` 确认日志格式无告警；如调整 `@Event` 风格，在真机（≤6.1）和平板模拟器上测试 `onTapTerms` / `onTapPrivacy` 回调触发是否仍正常。

---

## 重构执行备注（M12 · Login）

> 供 [`entry/Refactor_Spec.md`](../entry/Refactor_Spec.md) §7 执行循环使用。

### 契约与冻结项

| 项 | 内容 |
| --- | --- |
| 路由 | `custom_router_map.json:19-21`：`Login` → `pages/LoginPage.ets` + `LoginBuilder`，**页面路径与 Builder 名冻结** |
| 测试引用（冻结） | `viewmodel/LoginViewModel.ets`、`constants/LoginConstants.ets` 被 `entry/src/test/LoginViewModel.test.ets` 导入；`LoginViewModel` / `LOGIN_VM_SUCCESS` / `LOGIN_VM_ACCOUNT_ID` / `LOGIN_VM_ACCOUNT_VM`（`test:2-7`）与 `LoginTab` / `PhoneStep` 导出名不得变；`errorMsg` 错误码 `phone_empty` / `code_empty` / `cookie_empty` 被断言（`test:77/83/137/144`） |
| 组件 | `components/login/` 18 个文件（**仅 Login 页使用**：LoginPage.ets 直接导入 Narrow/WideLayout，其余为嵌套子组件），不能移动/改名（LoginBuilder 路由冻结） |
| Login spec | 根 `Refactor_Login_Spec.md` 里的 build-profile / mock 分离超出作用域，只取组件拆分；不要在本轮改 `internal/` 或 product |
| 文档基线 | `LoginViewModel.ets` 实际 415 行（旧文档写 ~365）；页面 129 行；二维码轮询 High 已撤回（`:216-274` 已有 generation + `pollInFlight`） |

### 重构范围（建议）

- **无 Critical**：本模块没有上架级阻断项。`LoginViewModel.ets:350` 的日志脱敏只是 15 分钟加固，可选；若做，单独提交，不夹带在目录调整里。
- `components/login/` 已按组件拆分（18 个），不做大规模合并；`LoginNarrowLayout` / `LoginWideLayout` 的响应式拆分保持。
- `@Event` → `@Param` 只是风格统一，不是必须；若改，需回归三种登录方式与协议回调。
- QR 轮询结果丢弃已由 generation + `pollInFlight` 实现；Repository 层真正中止请求（AbortSignal）属优化，不强制。

### 验收

1. 编译通过；`codeLinter` 不新增违规。
2. DevEco Local Test：`LoginViewModel.test.ets`（162 行）通过。
3. 冒烟：手机号 / 二维码 / Cookie 三种登录；协议/隐私 WebView；窄屏/宽屏；Cookie 失败日志不含 token（`hdc hilog` 抽查）。

### 已知问题归属

- 无 Critical（SEC-002 经逐层核查降为 Medium，见上文复核）。
- 无 High（QR 轮询原 HIGH 已撤回，见上文复核）。
- Medium（日志加固、`@Event` 风格、`finalizeLogin` 复杂度、`@Monitor` 复位、错误提示呈现）：记录，不强制；M4 属行为变更，不随目录重构提交。
- Low（魔法数字、AlertDialog 生命周期、协议语言后缀重复逻辑）：顺手。

---

## 附录 · 引用规则编号说明

- **SEC-002**: `references/checklist.md` § 1 — 敏感数据不在 hilog 中明文
- **STATE-007**: `references/checklist.md` § 3 — V2 `@Event` / `@Param` 使用规范
- **LIFE-001**: `references/checklist.md` § 4 — 页面销毁时取消订阅/定时器/长任务
- **LIFE-001, LIFE-004**: `references/checklist.md` § 4 — 生命周期资源管理
- **TEST-001**: `references/checklist.md` § 10 — 核心业务逻辑需单测覆盖
- **ARKTS-013**: `references/checklist.md` § 2 — 魔法数字处理

【已核对代码一致性】

| 校验轮次 | 范围 | 结论 |
|---------|------|------|
| 第 1 轮（行数 + 结构） | Login 129 / VM 415 / test 162、18 组件、路由 L19-21 | ✅ 全部精确 |
| 第 2 轮（关键代码段） | finalizeLogin L359-393、QR 轮询 L216-274、魔法数字 L229/406、@Event L13-16、日志 L350 | ✅ |
| 第 3 轮（全面复核） | core 仓库行号 482/501/225、§9 LoginType* 虚构组件修正、测试 10+ 用例 | ✅ 修正 2 处 |
| 第 4 轮（2026-10-26 复核） | 修正 Low 表错位（Medium 节内混入 2 行）、合并重复的 ARKTS-013 行、TEST-001 改为不计入 L；补合规检查（14 条） | ✅ 计数维持 0/0/4/2（L=2） |
| 第 5 轮（2026-10-27 复核） | 补「文件清单」「结构树 / 调用链」；安全复核补落盘日志（`ApiLogSystem`）、release 日志级别、Geetest 链路核查；修正 SEC-002 建议代码（签名 / 作用域错误）、KIT 行（二维码为本地 `QRCode()`）、`@Event` 行号、测试覆盖（22 用例，`maskedPhone` 已覆盖）；新增 M4（错误提示呈现）、L3（协议语言后缀与 `LegalI18nRouter` 重复且不一致） | ✅ 计数 0/0/4/2 → 0/0/5/3，债务点数 10 → 13 |
| 第 6 轮（2026-10-27 对抗复核） | 逐条回代码验证第 5 轮改动（文件清单行数、core 锚点、M4、L3 均成立）；DB-003 改为引用 Ability 文档（按口径在该文档记 High，本文档不计数）；M4 补「空输入错误码也原样显示」证据（`LoginViewModel.ets:104/124/316` → `LoginPhone.ets:31`）；测试断言行补 `:83`（`code_empty`） | ✅ 计数维持 0/0/5/3，债务点数 13 |
