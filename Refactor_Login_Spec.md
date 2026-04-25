# 登录模块物理隔离重构方案说明书

> 版本：v2.0（已确认）
> 状态：待执行
> 目标：利用 HarmonyOS Multi-Target SourceSet 机制，将手机号登录（含短信 API）从 `default`（上架包）构建中物理剔除，在 `mock`/`debug`/`internal` 构建中保留全部功能。

---

## 一、决策摘要

| 决策项                             | 结论                                                                             |
| ---------------------------------- | -------------------------------------------------------------------------------- |
| 哪些 target 保留手机号             | `mock`、`debug`、`internal` 保留；`default`（上架包）剔除                        |
| `core` 层是否隔离                  | 是，`AuthRepository` 和 `MihoyoAccountApiService` 都要隔离                       |
| `AuthRepository` 隔离粒度          | 选项 A：只隔离 `createLoginCaptcha`、`loginByMobileCaptcha` 两个方法，其余保留   |
| `MihoyoAccountApiService` 隔离粒度 | 选项 B：release 版完全删除 `createLoginCaptcha`、`loginByMobileCaptcha` 两个方法 |
| `internal` Bundle ID               | 与 `default` 相同：`com.cainluo.miyoyo.tools`                                    |
| dev 证书路径                       | `Certificates/dev/miyoyo-dev.cer` + `Certificates/dev/miyoyo-profileDebug.p7b`   |
| 代码存放位置                       | 所有 internal 专属代码统一放在 `internal/` 目录下                                |

---

## 二、现状分析

### 2.1 需要隔离的文件完整清单

**entry 模块（UI 层）：**

| 文件                                                      | 隔离类型         | 说明                         |
| --------------------------------------------------------- | ---------------- | ---------------------------- |
| `entry/src/main/ets/components/login/LoginPhone.ets`      | 仅 internal 存在 | 手机号登录容器               |
| `entry/src/main/ets/components/login/LoginPhoneInput.ets` | 仅 internal 存在 | 手机号输入 UI                |
| `entry/src/main/ets/components/login/LoginCodeInput.ets`  | 仅 internal 存在 | 验证码输入 UI                |
| `entry/src/main/ets/components/login/LoginTabBar.ets`     | 两个版本         | release 版无 PHONE Tab       |
| `entry/src/main/ets/components/login/LoginTabContent.ets` | 两个版本         | release 版无 LoginPhone 分支 |
| `entry/src/main/ets/viewmodel/LoginViewModel.ets`         | 两个版本         | release 版无手机号字段和方法 |

**core 模块（网络/业务层）：**

| 文件                                                    | 隔离类型         | 说明                                                             |
| ------------------------------------------------------- | ---------------- | ---------------------------------------------------------------- |
| `core/src/main/ets/network/MihoyoAccountApiService.ets` | 两个版本         | release 版删除 `createLoginCaptcha`、`loginByMobileCaptcha`      |
| `core/src/main/ets/repository/AuthRepository.ets`       | 两个版本         | release 版删除 `createLoginCaptcha`、`loginByMobileCaptcha` 方法 |
| `core/src/main/ets/models/PhoneLoginModels.ets`         | 仅 internal 存在 | 手机号登录数据模型（`LoginMobileResult` 等）                     |
| `core/Index.ets`                                        | 两个版本         | release 版不 export `PhoneLoginModels` 和手机号相关类型          |

**无需改动的文件：**

- `Login.ets`、`LoginNarrowLayout.ets`、`LoginWideLayout.ets`、`LoginCard.ets`
- `LoginCookie.ets`、`LoginQRCode*.ets`、`LoginAgreement.ets`、`LoginLogoSection.ets`
- `LoginFeatureItem.ets`、`LoginTabItem.ets`
- `core/src/main/ets/models/QRCodeLoginModels.ets`、`TokenModels.ets`（二维码和 Token 换取保留）
- `PassportApiPath.ets`（路径枚举保留，release 版只是不调用手机号路径）

---

## 三、重构后目录结构

### 3.1 核心原则

所有 internal 专属代码统一放在项目根目录下的 `internal/` 文件夹，按模块分子目录：

```
internal/
├── entry/
│   └── ets/
│       ├── components/
│       │   └── login/
│       │       ├── LoginTabBar.ets          ← internal 版（含 PHONE Tab）
│       │       ├── LoginTabContent.ets      ← internal 版（含 LoginPhone 分支）
│       │       ├── LoginPhone.ets           ← 仅 internal（手机号容器）
│       │       ├── LoginPhoneInput.ets      ← 仅 internal（手机号输入）
│       │       └── LoginCodeInput.ets       ← 仅 internal（验证码输入）
│       └── viewmodel/
│           └── LoginViewModel.ets           ← internal 版（含手机号方法）
└── core/
    └── ets/
        ├── network/
        │   └── MihoyoAccountApiService.ets  ← internal 版（含手机号 API 方法）
        ├── repository/
        │   └── AuthRepository.ets           ← internal 版（含手机号方法）
        ├── models/
        │   └── PhoneLoginModels.ets         ← 仅 internal（手机号数据模型）
        └── Index.ets                        ← internal 版（export PhoneLoginModels）
```

### 3.2 `src/main/` 中的 release 版文件

`src/main/` 中的文件是 `default`（上架包）版本，不含任何手机号代码：

```
entry/src/main/ets/
├── components/login/
│   ├── LoginTabBar.ets          ← release 版（只有 QRCODE + COOKIE Tab）
│   ├── LoginTabContent.ets      ← release 版（无 LoginPhone 分支）
│   └── ...（其余文件不变）
└── viewmodel/
    └── LoginViewModel.ets       ← release 版（无手机号字段和方法）

core/src/main/ets/
├── network/
│   └── MihoyoAccountApiService.ets  ← release 版（无 createLoginCaptcha/loginByMobileCaptcha）
├── repository/
│   └── AuthRepository.ets           ← release 版（无 createLoginCaptcha/loginByMobileCaptcha）
└── Index.ets                         ← release 版（不 export PhoneLoginModels）
```

### 3.3 SourceSet 覆盖机制

```
编译 default（上架包）target 时：
  使用 src/main/ 中的文件
  internal/ 目录完全不参与编译
  LoginPhone.ets / LoginPhoneInput.ets / LoginCodeInput.ets 物理不存在

编译 mock / debug / internal target 时：
  internal/ 中的同名文件覆盖 src/main/ 中的文件
  LoginPhone.ets 等仅存在于 internal/ 的文件正常参与编译
```

---

## 四、`build-profile.json5` 修改蓝图

```json5
{
  app: {
    signingConfigs: [
      // 现有 release 签名不变
      {
        name: "release",
        // ... 现有配置 ...
      },
      // 新增 internal 签名（复用 dev 证书）
      {
        name: "internal",
        type: "HarmonyOS",
        material: {
          certpath: "Certificates/dev/miyoyo-dev.cer",
          keyAlias: "Miyoyo",
          keyPassword: "...", // 与 release 相同的 keyPassword
          profile: "Certificates/dev/miyoyo-profileDebug.p7b",
          signAlg: "SHA256withECDSA",
          storeFile: "Certificates/Miyoyo.p12",
          storePassword: "...", // 与 release 相同的 storePassword
        },
      },
    ],
    products: [
      // default（上架包）：不变，使用 src/main/ 的精简版代码
      {
        name: "default",
        signingConfig: "release",
        bundleName: "com.cainluo.miyoyo.tools",
        // ... 现有配置不变 ...
      },
      // mock：新增 sourceRoots，覆盖为 internal 版代码
      {
        name: "mock",
        signingConfig: "default",
        bundleName: "com.cainluo.miyoyo.tools.mock",
        // ... 现有配置不变 ...
      },
      // debug：新增 sourceRoots，覆盖为 internal 版代码
      {
        name: "debug",
        signingConfig: "default",
        bundleName: "com.cainluo.miyoyo.tools.debug",
        // ... 现有配置不变 ...
      },
      // 新增 internal product
      {
        name: "internal",
        signingConfig: "internal",
        bundleName: "com.cainluo.miyoyo.tools", // 与 default 相同，方便覆盖安装
        label: "$string:app_name_internal",
        targetSdkVersion: "6.0.2(22)",
        compatibleSdkVersion: "6.0.2(22)",
        runtimeOS: "HarmonyOS",
        buildOption: {
          strictMode: {
            caseSensitiveCheck: true,
            useNormalizedOHMUrl: true,
          },
          arkOptions: {
            buildProfileFields: {
              APP_ENV: "debug",
            },
          },
        },
      },
    ],
    buildModeSet: [
      { name: "debug" },
      { name: "mock" },
      { name: "release" },
      { name: "internal" }, // 新增
    ],
  },
  modules: [
    {
      name: "entry",
      srcPath: "./entry",
      targets: [
        // default：不变，使用 src/main/
        {
          name: "default",
          applyToProducts: ["default"],
        },
        // mock：叠加 internal/ 目录
        {
          name: "mock",
          applyToProducts: ["mock"],
          source: {
            sourceRoots: ["../internal/entry/ets"],
          },
        },
        // debug：叠加 internal/ 目录
        {
          name: "debug",
          applyToProducts: ["debug"],
          source: {
            sourceRoots: ["../internal/entry/ets"],
          },
        },
        // 新增 internal target
        {
          name: "internal",
          applyToProducts: ["internal"],
          source: {
            sourceRoots: ["../internal/entry/ets"],
          },
        },
      ],
    },
    {
      name: "core",
      srcPath: "./core",
      targets: [
        // default：不变，使用 src/main/
        {
          name: "default",
          applyToProducts: ["default"],
        },
        // mock：叠加 internal/ 目录
        {
          name: "mock",
          applyToProducts: ["mock"],
          source: {
            sourceRoots: ["../internal/core/ets"],
          },
        },
        // debug：叠加 internal/ 目录
        {
          name: "debug",
          applyToProducts: ["debug"],
          source: {
            sourceRoots: ["../internal/core/ets"],
          },
        },
        // 新增 internal target
        {
          name: "internal",
          applyToProducts: ["internal"],
          source: {
            sourceRoots: ["../internal/core/ets"],
          },
        },
      ],
    },
  ],
}
```

**注意：** `sourceRoots` 路径是相对于模块根目录（`entry/` 或 `core/`）的，所以 `internal/` 在项目根目录时，路径写 `"../internal/entry/ets"` 和 `"../internal/core/ets"`。

---

## 五、各文件的具体改动说明

### 5.1 entry 层

#### `src/main/ets/components/login/LoginTabBar.ets`（release 版）

- 删除 `LoginTab.PHONE` 的 Tab 项
- 默认 Tab 改为 `LoginTab.QRCODE`
- 不 import `LoginTab.PHONE`（枚举值仍存在，只是不渲染）

#### `internal/entry/ets/components/login/LoginTabBar.ets`（internal 版）

- 直接复制现有 `LoginTabBar.ets`，保持三个 Tab 不变

#### `src/main/ets/components/login/LoginTabContent.ets`（release 版）

- 删除 `import { LoginPhone }` 语句
- 删除 `if (activeTab === LoginTab.PHONE)` 分支

#### `internal/entry/ets/components/login/LoginTabContent.ets`（internal 版）

- 直接复制现有 `LoginTabContent.ets`，保持三个分支不变

#### `internal/entry/ets/components/login/LoginPhone.ets`（仅 internal）

- 直接复制现有 `LoginPhone.ets`

#### `internal/entry/ets/components/login/LoginPhoneInput.ets`（仅 internal）

- 直接复制现有 `LoginPhoneInput.ets`

#### `internal/entry/ets/components/login/LoginCodeInput.ets`（仅 internal）

- 直接复制现有 `LoginCodeInput.ets`

#### `src/main/ets/viewmodel/LoginViewModel.ets`（release 版）

- 删除字段：`phoneStep`、`phoneNumber`、`smsCode`、`smsCooldown`、`cooldownTimer`
- 删除方法：`sendSmsCode()`、`loginByPhone()`、`backToPhoneInput()`、`maskedPhone` getter、`startCooldown()`、`stopCooldown()`
- `activeTab` 默认值改为 `LoginTab.QRCODE`
- `switchTab()` 中删除 `LoginTab.PHONE` 相关处理

#### `internal/entry/ets/viewmodel/LoginViewModel.ets`（internal 版）

- 直接复制现有 `LoginViewModel.ets`，保持完整功能

---

### 5.2 core 层

#### `src/main/ets/network/MihoyoAccountApiService.ets`（release 版）

- 完全删除 `createLoginCaptcha()` 方法
- 完全删除 `loginByMobileCaptcha()` 方法
- 其余方法（`getLTokenBySToken`、`getCookieTokenBySToken`、`fetchQRCode`、`queryQRCode`、`getTokenByGameToken`、账号相关方法）全部保留

#### `internal/core/ets/network/MihoyoAccountApiService.ets`（internal 版）

- 直接复制现有 `MihoyoAccountApiService.ets`，保持完整功能

#### `src/main/ets/repository/AuthRepository.ets`（release 版）

- 删除 `createLoginCaptcha()` 方法
- 删除 `loginByMobileCaptcha()` 方法
- 删除对 `PhoneLoginModels` 的 import（`LoginMobileResult` 等）
- 删除 `export { LoginMobileResult, MmtData, ... }` 语句
- 保留所有二维码、Token 换取、Cookie 相关方法

#### `internal/core/ets/repository/AuthRepository.ets`（internal 版）

- 直接复制现有 `AuthRepository.ets`，保持完整功能

#### `internal/core/ets/models/PhoneLoginModels.ets`（仅 internal）

- 直接复制现有 `PhoneLoginModels.ets`

#### `src/main/ets/Index.ets`（release 版，即 `core/Index.ets`）

- 删除 `export * from './src/main/ets/repository/AuthRepository'` 中手机号相关的 re-export
  - 具体：删除 `export { LoginMobileResult, MmtData, MmtResponse, GeetestV4Data, PhoneLoginAccountInfo, PhoneLoginResponse }` 这行

#### `internal/core/ets/Index.ets`（internal 版）

- 直接复制现有 `core/Index.ets`，保持完整 export

---

## 六、潜在风险与预警

### ⚠️ 预警 1：`core/Index.ets` 的路径特殊性

`core/Index.ets` 位于 `core/` 根目录，不在 `core/src/main/ets/` 下。`sourceRoots` 指向的是 `../internal/core/ets`，这个路径下的文件会覆盖 `core/src/main/ets/` 中的同名文件。

但 `Index.ets` 在 `core/` 根目录，不在 `src/main/ets/` 下，SourceSet 覆盖机制**不适用**于它。

**解决方案：** `core/Index.ets` 不通过 SourceSet 覆盖，而是直接修改 `core/Index.ets`，把手机号相关的 export 改为条件性的——但 ArkTS 不支持条件 export。

**实际方案：** `core/Index.ets` 中的 `export { LoginMobileResult, ... }` 来自 `AuthRepository.ets` 的 re-export。release 版的 `AuthRepository.ets` 删除了这些 re-export，所以 `core/Index.ets` 不需要改动——它 export 的是 `AuthRepository`，而 release 版的 `AuthRepository` 本身就不再 re-export 手机号相关类型。

**结论：** `core/Index.ets` 无需改动，不需要 internal 版本。

---

### ⚠️ 预警 2：`LoginViewModel` 中 `LoginTab.PHONE` 枚举值

release 版 `LoginViewModel` 删除了手机号方法，但 `LoginTabEnum.ets` 中的 `LoginTab.PHONE` 枚举值仍然存在。release 版的 `activeTab` 默认值需要改为 `LoginTab.QRCODE`，否则启动时 `LoginTabContent` 找不到对应的渲染分支会显示空白。

---

### ⚠️ 预警 3：`mock` target 的 `MihoyoAccountMockService`

`core/src/main/ets/network/mock/MihoyoAccountMockService.ets` 继承自 `MihoyoAccountApiService`，并覆盖了 `createLoginCaptcha`、`loginByMobileCaptcha` 等方法。

release 版的 `MihoyoAccountApiService` 删除了这两个方法后，`MihoyoAccountMockService` 中覆盖这两个方法的代码会导致编译错误（子类不能覆盖父类不存在的方法）。

**解决方案：** `MihoyoAccountMockService.ets` 也需要两个版本：

- `src/main/ets/network/mock/MihoyoAccountMockService.ets`（release 版）：删除 `createLoginCaptcha`、`loginByMobileCaptcha` 的覆盖方法
- `internal/core/ets/network/mock/MihoyoAccountMockService.ets`（internal 版）：直接复制现有文件

这是原始 Spec 中遗漏的一个文件，需要补充到改动清单中。

---

### ⚠️ 预警 4：`sourceRoots` 路径相对于模块根目录

`build-profile.json5` 中 `source.sourceRoots` 的路径是相对于**模块根目录**（`entry/` 或 `core/`）的，不是相对于项目根目录。

- `entry` 模块根目录是 `entry/`，所以 `internal/entry/ets` 的相对路径是 `"../internal/entry/ets"`
- `core` 模块根目录是 `core/`，所以 `internal/core/ets` 的相对路径是 `"../internal/core/ets"`

---

### ⚠️ 预警 5：`app_name_internal` 字符串资源

新增 `internal` product 使用了 `label: "$string:app_name_internal"`，需要在 `AppScope/resources/base/element/string.json` 中添加这个 key。

---

## 七、完整改动文件清单

| 操作         | 文件                                                                      |
| ------------ | ------------------------------------------------------------------------- |
| 修改（精简） | `entry/src/main/ets/components/login/LoginTabBar.ets`                     |
| 修改（精简） | `entry/src/main/ets/components/login/LoginTabContent.ets`                 |
| 修改（精简） | `entry/src/main/ets/viewmodel/LoginViewModel.ets`                         |
| 修改（精简） | `core/src/main/ets/network/MihoyoAccountApiService.ets`                   |
| 修改（精简） | `core/src/main/ets/network/mock/MihoyoAccountMockService.ets`             |
| 修改（精简） | `core/src/main/ets/repository/AuthRepository.ets`                         |
| 新建（复制） | `internal/entry/ets/components/login/LoginTabBar.ets`                     |
| 新建（复制） | `internal/entry/ets/components/login/LoginTabContent.ets`                 |
| 新建（复制） | `internal/entry/ets/components/login/LoginPhone.ets`                      |
| 新建（复制） | `internal/entry/ets/components/login/LoginPhoneInput.ets`                 |
| 新建（复制） | `internal/entry/ets/components/login/LoginCodeInput.ets`                  |
| 新建（复制） | `internal/entry/ets/viewmodel/LoginViewModel.ets`                         |
| 新建（复制） | `internal/core/ets/network/MihoyoAccountApiService.ets`                   |
| 新建（复制） | `internal/core/ets/network/mock/MihoyoAccountMockService.ets`             |
| 新建（复制） | `internal/core/ets/repository/AuthRepository.ets`                         |
| 新建（复制） | `internal/core/ets/models/PhoneLoginModels.ets`                           |
| 修改         | `build-profile.json5`                                                     |
| 修改         | `AppScope/resources/base/element/string.json`（新增 `app_name_internal`） |

**总计：** 6 个文件修改，12 个文件新建，2 个配置文件修改。

---

_Spec v2.0 确认完毕。回复"Spec 确认无误，请执行"后进入第二阶段。_
