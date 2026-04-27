# 首屏隐私合规 — 任务列表

## Task 1：新建 LegalI18nRouter

- [ ] 新建 `entry/src/main/ets/utils/LegalI18nRouter.ets`
- [ ] 实现 `langSuffix()` 私有方法（基于 `i18n.System.getSystemLanguage()`）
- [ ] 实现 `privacyPath()` 和 `termsPath()` 静态方法

## Task 2：新建 LegalPreferences

- [ ] 新建 `entry/src/main/ets/utils/LegalPreferences.ets`
- [ ] 实现 `hasAgreed(context)` 同步方法
- [ ] 实现 `setAgreed(context)` 异步方法（putSync + flush）

## Task 3：新增多语言文案

- [ ] 在 `entry/src/main/resources/base/element/string.json` 新增 6 个 `privacy_consent_*` key
- [ ] 在 `entry/src/main/resources/zh_HK/element/string.json` 新增对应繁体翻译
- [ ] 在 `entry/src/main/resources/en/element/string.json` 新增对应英文翻译

## Task 4：新建 PrivacyConsentViewModel

- [ ] 新建 `entry/src/main/ets/viewmodel/PrivacyConsentViewModel.ets`
- [ ] 实现 `step`、`termsScrolledToBottom`、`privacyScrolledToBottom` 字段
- [ ] 实现 `canProceedFromTerms`、`canAgree` getter
- [ ] 实现 `goToPrivacy()` 方法

## Task 5：新建 PrivacyConsentPage

- [ ] 新建 `entry/src/main/ets/pages/PrivacyConsentPage.ets`
- [ ] 实现顶部标题栏（步骤一显示「用户协议」，步骤二显示「隐私政策 2/2」）
- [ ] 实现 Web 组件加载 rawfile HTML，监听 `onScroll` 检测是否到底部
- [ ] 步骤一底部：「下一步」按钮，`enabled: vm.canProceedFromTerms`
- [ ] 步骤二底部：「同意并继续」和「不同意，退出」，`enabled: vm.canAgree`
- [ ] 「同意并继续」：`setAgreed()` + `navigateToMain()`
- [ ] 「不同意，退出」：`terminateSelf()`
- [ ] 文件末尾添加 `@Preview`（步骤一和步骤二两种状态）

## Task 6：注册路由

- [ ] 在 `AppRoutes.ets` 新增 `PRIVACY_CONSENT = 'PrivacyConsent'`
- [ ] 在 `Index.ets` 的 `pageBuilder` 中新增 `PrivacyConsent` 分支
- [ ] 新建 `PrivacyConsentBuilder.ets`（仅做透传）

## Task 7：修改 Launch.ets

- [ ] 新增 import：`common`、`LegalPreferences`、`AppRoutes`
- [ ] 新增 `checkPrivacyAndProceed()` 私有方法
- [ ] 将 `aboutToAppear()` 中的 `this.navigateToMain()` 替换为 `this.checkPrivacyAndProceed()`

## Task 8：补充 ViewModel 单元测试

- [ ] 新建 `entry/src/test/PrivacyConsentViewModel.test.ets`
- [ ] 覆盖初始状态、canProceedFromTerms、canAgree、goToPrivacy 等用例

## Task 9：构建验证

- [ ] 运行 `bash run.sh mock` 验证构建通过
- [ ] 在模拟器上验证首次启动进入合规流程
- [ ] 验证步骤一未滑到底部时「下一步」禁用
- [ ] 验证步骤二滑到底部后两个按钮可点击
- [ ] 验证同意后重启不再进入合规流程
- [ ] 验证不同意后 App 退出
