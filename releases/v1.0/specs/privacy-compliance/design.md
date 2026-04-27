# 首屏隐私合规 — 设计文档

## 整体架构

```
Launch.ets（启动页）
  └── aboutToAppear()
        ├── 已同意 → navigateToMain()
        └── 未同意 → RouterUtil.replace(AppRoutes.PRIVACY_CONSENT)

PrivacyConsentPage（全屏合规流程页）
  ├── 步骤一：用户协议（TermsStep）
  │     ├── Web 组件全屏展示 terms-*.html
  │     ├── 滑到底部 → 「下一步」Enable
  │     └── 点击下一步 → 切换到步骤二
  └── 步骤二：隐私政策（PrivacyStep）
        ├── Web 组件全屏展示 privacy-*.html
        ├── 滑到底部 → 两个按钮 Enable
        ├── 「同意并继续」→ setAgreed() → navigateToMain()
        └── 「不同意，退出」→ terminateSelf()
```

---

## 模块一：多语言路由层（LegalI18nRouter）

**文件：** `entry/src/main/ets/utils/LegalI18nRouter.ets`

**依赖：** `import { i18n } from '@kit.LocalizationKit'`

```typescript
import { i18n } from "@kit.LocalizationKit";

export class LegalI18nRouter {
  private static langSuffix(): string {
    const lang = i18n.System.getSystemLanguage();
    if (
      lang.startsWith("zh-Hant") ||
      lang === "zh-HK" ||
      lang === "zh-TW" ||
      lang === "zh-MO"
    ) {
      return "-zh-hant";
    }
    if (lang.startsWith("zh")) {
      return "-zh";
    }
    if (lang.startsWith("en")) {
      return "-en";
    }
    return "";
  }

  static privacyPath(): string {
    return `legal/privacy${LegalI18nRouter.langSuffix()}.html`;
  }

  static termsPath(): string {
    return `legal/terms${LegalI18nRouter.langSuffix()}.html`;
  }
}
```

---

## 模块二：状态持久化层（LegalPreferences）

**文件：** `entry/src/main/ets/utils/LegalPreferences.ets`

```typescript
import { preferences } from "@kit.ArkData";
import { common } from "@kit.AbilityKit";

const STORE_NAME = "legal_prefs";
const KEY_AGREED = "hasAgreedPrivacy";

export class LegalPreferences {
  static hasAgreed(context: common.UIAbilityContext): boolean {
    const prefs = preferences.getPreferencesSync(context, { name: STORE_NAME });
    return prefs.getSync(KEY_AGREED, false) as boolean;
  }

  static setAgreed(context: common.UIAbilityContext): Promise<void> {
    const prefs = preferences.getPreferencesSync(context, { name: STORE_NAME });
    prefs.putSync(KEY_AGREED, true);
    return new Promise<void>((resolve, reject) => {
      prefs.flush((err) => {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      });
    });
  }
}
```

---

## 模块三：合规流程页（PrivacyConsentPage）

**文件：** `entry/src/main/ets/pages/PrivacyConsentPage.ets`

这是一个全屏独立页面，不是弹窗，通过路由跳转进入。

### 页面结构

```
PrivacyConsentPage
  ├── NavDestination（hideTitleBar: true，全屏）
  └── Column（全屏）
        ├── 顶部标题栏（固定高度 52vp）
        │     ├── 标题文字（步骤一：「用户协议」/ 步骤二：「隐私政策」）
        │     └── 步骤指示（步骤二显示「2/2」）
        ├── Web 组件（flex:1，加载 rawfile HTML）
        └── 底部操作区（固定高度，padding 16vp）
              步骤一：[下一步按钮（全宽，初始禁用）]
              步骤二：[同意并继续（全宽，初始禁用）]
                      [不同意，退出（全宽，初始禁用）]
```

### UI 线框图

**步骤一（用户协议）：**

```
┌─────────────────────────────────────┐
│  用户协议                            │  ← 顶部标题栏，52vp，colorSurfaceCard
├─────────────────────────────────────┤
│                                     │
│  [Web 组件：terms-*.html 全文]       │  ← flex:1，可滚动
│                                     │
│  （未滑到底部时）                    │
│                                     │
│                                     │
│                                     │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │  ← 底部操作区，padding 16
│  │  下一步（禁用/灰色）          │   │    按钮高度 46，radius8
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘

（滑到底部后，「下一步」变为 colorPrimary 可点击）
```

**步骤二（隐私政策）：**

```
┌─────────────────────────────────────┐
│  隐私政策                    2/2    │  ← 顶部标题栏，右侧步骤指示
├─────────────────────────────────────┤
│                                     │
│  [Web 组件：privacy-*.html 全文]    │  ← flex:1，可滚动
│                                     │
│                                     │
│                                     │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │  ← 同意按钮（初始禁用）
│  │  同意并继续（禁用/灰色）      │   │    高度 46，radius8
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │  ← 不同意按钮（初始禁用）
│  │  不同意，退出（禁用/灰色）    │   │    高度 40，无背景
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘

（滑到底部后，两个按钮均变为可点击）
```

### 滑到底部检测

使用 Web 组件的 `onScroll` 事件：

```typescript
Web({
  src: `resource://rawfile/${this.htmlFile}`,
  controller: this.webController,
}).onScroll((event) => {
  // event.xOffset, event.yOffset 为当前滚动偏移（vp）
  // 通过 runJavaScript 获取页面实际高度
  this.webController.runJavaScript(
    "document.documentElement.scrollHeight - document.documentElement.clientHeight",
    (result) => {
      const maxScroll = parseFloat(result ?? "0");
      if (maxScroll > 0 && event.yOffset >= maxScroll - 20) {
        this.hasScrolledToBottom = true;
      }
    },
  );
});
```

**注意：** `hasScrolledToBottom` 一旦变为 `true` 就不再变回 `false`（不可逆）。

### ViewModel 设计

```typescript
@ObservedV2
export class PrivacyConsentViewModel {
  @Trace step: "terms" | "privacy" = "terms";
  @Trace termsScrolledToBottom: boolean = false;
  @Trace privacyScrolledToBottom: boolean = false;

  get canProceedFromTerms(): boolean {
    return this.termsScrolledToBottom;
  }

  get canAgree(): boolean {
    return this.privacyScrolledToBottom;
  }

  goToPrivacy(): void {
    this.step = "privacy";
  }
}
```

### 完整用户交互流程

```
App 启动
  │
  ▼
Launch 页（Logo 动画）
  │
  ├─ [已同意过] ──────────────────────────────→ navigateToMain()
  │
  └─ [首次启动 / 未同意]
        │
        RouterUtil.replace(PRIVACY_CONSENT)
        │
        ▼
  ┌─────────────────────────────────────────┐
  │  步骤一：用户协议（全屏）                │
  │  Web 加载 terms-*.html                  │
  │  「下一步」初始禁用                      │
  │       │                                 │
  │       ├─ 滑到底部 → 「下一步」Enable    │
  │       │                                 │
  │       └─ 点击「下一步」                 │
  └─────────────────────────────────────────┘
        │
        ▼
  ┌─────────────────────────────────────────┐
  │  步骤二：隐私政策（全屏）                │
  │  Web 加载 privacy-*.html                │
  │  两个按钮初始禁用                        │
  │       │                                 │
  │       ├─ 滑到底部 → 两个按钮 Enable     │
  │       │                                 │
  │       ├─ 点击「同意并继续」              │
  │       │   ├─ setAgreed() + flush()      │
  │       │   └─ navigateToMain()           │
  │       │                                 │
  │       └─ 点击「不同意，退出」            │
  │           └─ terminateSelf()            │
  └─────────────────────────────────────────┘
```

---

## 模块四：修改 Launch.ets

```typescript
// 新增 import
import { common } from '@kit.AbilityKit';
import { LegalPreferences } from '../utils/LegalPreferences';
import { AppRoutes } from '../constants/AppRoutes';

// 修改 aboutToAppear
aboutToAppear(): void {
  this.uiCtx = this.getUIContext();
  this.uiCtx.animateTo({ duration: 600, curve: Curve.EaseOut }, () => {
    this.logoScale = 1.0;
    this.logoOpacity = 1.0;
  });
  this.checkPrivacyAndProceed();
}

private checkPrivacyAndProceed(): void {
  const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
  const agreed = LegalPreferences.hasAgreed(ctx);
  if (agreed) {
    this.navigateToMain();
  } else {
    // replace 到合规流程页，不保留 Launch 在返回栈
    RouterUtil.replace(AppRoutes.PRIVACY_CONSENT);
  }
}
```

---

## 模块五：路由注册

**AppRoutes.ets** 新增：

```typescript
static readonly PRIVACY_CONSENT = 'PrivacyConsent'
```

**custom_router_map.json** 新增 `PrivacyConsent` 路由条目。

**Main.ets 的 allDetailBuilder** 新增 `PrivacyConsentBuilder` 分支（如果需要从 Main 内部跳转）。

实际上 `PrivacyConsentPage` 是在 `Launch` 之后、`Main` 之前的过渡页，通过 `RouterUtil.replace` 跳转，不需要在 Main 内注册。只需在 `Index.ets` 的 `pageBuilder` 中添加分支即可。

---

## 多语言文案

### 新增 string.json key

| Key                             | 简体中文     | 繁体中文     | 英文             |
| ------------------------------- | ------------ | ------------ | ---------------- |
| `privacy_consent_terms_title`   | 用户协议     | 用戶協議     | Terms of Service |
| `privacy_consent_privacy_title` | 隐私政策     | 隱私政策     | Privacy Policy   |
| `privacy_consent_next`          | 下一步       | 下一步       | Next             |
| `privacy_consent_agree`         | 同意并继续   | 同意並繼續   | Agree & Continue |
| `privacy_consent_disagree`      | 不同意，退出 | 不同意，退出 | Disagree & Exit  |
| `privacy_consent_step`          | %d/2         | %d/2         | %d/2             |

---

## 测试策略

### 单元测试（entry/src/test/）

**PrivacyConsentViewModel.test.ets**

| 测试用例                                                  | 操作                            | 预期                            |
| --------------------------------------------------------- | ------------------------------- | ------------------------------- |
| 初始 step 为 terms                                        | `new PrivacyConsentViewModel()` | `step === 'terms'`              |
| 初始 canProceedFromTerms 为 false                         | 新建实例                        | `canProceedFromTerms === false` |
| 初始 canAgree 为 false                                    | 新建实例                        | `canAgree === false`            |
| termsScrolledToBottom=true 后 canProceedFromTerms 为 true | 设置字段                        | `canProceedFromTerms === true`  |
| privacyScrolledToBottom=true 后 canAgree 为 true          | 设置字段                        | `canAgree === true`             |
| goToPrivacy 切换 step                                     | `vm.goToPrivacy()`              | `step === 'privacy'`            |

### 组件 @Preview

`PrivacyConsentPage.ets` 末尾需有 `@Preview`，覆盖步骤一和步骤二两种状态。

---

## 关键 API 来源

| API                                       | 来源                   | 确认方式                                        |
| ----------------------------------------- | ---------------------- | ----------------------------------------------- |
| `preferences.getPreferencesSync`          | `@kit.ArkData`         | 官方文档 [通过用户首选项实现数据持久化 (ArkTS)] |
| `i18n.System.getSystemLanguage()`         | `@kit.LocalizationKit` | 官方文档 [@ohos.i18n]                           |
| `common.UIAbilityContext.terminateSelf()` | `@kit.AbilityKit`      | 官方文档 [UIAbilityContext]                     |
| `Web.onScroll` + `runJavaScript`          | `@kit.ArkWeb`          | 需查官方文档确认 onScroll 事件参数              |
