# 首屏隐私合规 — 需求文档

## 背景

鸿蒙应用市场上架要求：应用首次启动时必须展示隐私合规流程，用户必须主动阅读并同意用户协议和隐私政策后才能继续使用，不同意则强制退出应用。

## 功能需求

### REQ-1：首屏阻断拦截

- 应用每次启动时，在进入主界面前检查用户是否已完成合规流程
- 若未完成，跳转到合规流程页（全屏 Splash Screen 样式），阻断后续流程
- 已完成过的用户直接跳过，正常进入主界面

### REQ-2：两步全屏阅读流程

合规流程分为两个步骤，每步占满全屏：

**步骤一：用户协议**

- 全屏展示用户协议 HTML 内容（`rawfile/legal/terms-*.html`）
- 顶部显示标题「用户协议」
- 底部固定操作区，初始状态「下一步」按钮为禁用（灰色）
- 用户滑动到协议底部后，「下一步」按钮变为可点击
- 点击「下一步」进入步骤二

**步骤二：隐私政策**

- 全屏展示隐私政策 HTML 内容（`rawfile/legal/privacy-*.html`）
- 顶部显示标题「隐私政策」及步骤指示（2/2）
- 底部固定操作区，初始状态两个按钮均为禁用
- 用户滑动到隐私政策底部后，两个按钮变为可点击：
  - 「同意并继续」（主色调）
  - 「不同意，退出」（次要文字色）

### REQ-3：滑到底部检测

- 使用 Web 组件的 `onScroll` 事件检测滚动位置
- 当 `scrollY + viewportHeight >= contentHeight - 阈值（20px）` 时判定为已到底部
- 到达底部后按钮状态变为可点击，不可逆（不会因为向上滚动而重新禁用）

### REQ-4：同意流程

- 点击「同意并继续」：
  1. 持久化 `hasAgreedPrivacy = true`（`@kit.ArkData` Preferences）
  2. 跳转到主界面（`navigateToMain()`）

### REQ-5：不同意流程

- 点击「不同意，退出」：
  1. 调用 `UIAbilityContext.terminateSelf()` 强制退出 App
  - **必须退出 App**，不能仅返回上一页（鸿蒙应用市场合规要求）

### REQ-6：多语言支持

根据系统语言自动选择对应的协议 HTML 文件：

| 系统语言 | 用户协议             | 隐私政策               |
| -------- | -------------------- | ---------------------- |
| 简体中文 | `terms-zh.html`      | `privacy-zh.html`      |
| 繁体中文 | `terms-zh-hant.html` | `privacy-zh-hant.html` |
| 英文     | `terms-en.html`      | `privacy-en.html`      |
| 其他     | `terms.html`         | `privacy.html`         |

页面标题文案同样需要多语言支持（`string.json`）。

### REQ-7：状态持久化

- 使用 `@kit.ArkData` 的 `preferences` 模块存储同意状态
- Key：`hasAgreedPrivacy`，类型：`boolean`，默认 `false`
- 写入后必须调用 `flush()` 确保持久化到磁盘

### REQ-8：架构集成

- 合规流程作为独立页面（`PrivacyConsentPage`）注册到路由
- 在 `Launch.ets` 的 `aboutToAppear()` 中检查状态：
  - 已同意 → `navigateToMain()`
  - 未同意 → `RouterUtil.replace(AppRoutes.PRIVACY_CONSENT)`

## 验收标准

- [ ] 首次安装启动时进入合规流程，无法绕过
- [ ] 步骤一未滑到底部时「下一步」按钮禁用
- [ ] 步骤一滑到底部后「下一步」按钮可点击
- [ ] 步骤二未滑到底部时两个按钮均禁用
- [ ] 步骤二滑到底部后两个按钮均可点击
- [ ] 同意后再次启动不再进入合规流程
- [ ] 不同意后 App 退出（不是返回上一页）
- [ ] 简体中文 / 繁体中文 / 英文系统下加载对应语言的协议文件
