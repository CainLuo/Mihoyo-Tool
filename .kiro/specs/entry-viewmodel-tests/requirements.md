# Requirements Document

## Introduction

为 `entry/src/test/` 目录下的 ViewModel 本地单元测试补充完整覆盖。
测试范围：7 个 ViewModel 的构造函数初始状态验证，以及纯函数（static 方法、getter）的行为验证。
所有测试不依赖设备，不 import core 模块的 Repository 或 DAO，使用 `@ohos/hypium` 框架。

## Glossary

- **ViewModel**: 遵循 MVVM 架构的 UI 状态持有类，使用 `@ObservedV2` + `@Trace` 装饰
- **ViewState**: 页面加载状态枚举（LOADING / EMPTY / DATA / ERROR），定义于 `ViewStates.ets`
- **LoginTab**: 登录方式 Tab 枚举（PHONE / QRCODE / COOKIE），定义于 `LoginTabEnum.ets`
- **PhoneStep**: 手机号登录步骤枚举（INPUT_PHONE / INPUT_CODE），定义于 `LoginTabEnum.ets`
- **GenshinPropertyType**: 原神属性类型枚举，定义于 `core/src/main/ets/constants/GenshinPropertyType.ets`
- **Test_Runner**: `@ohos/hypium` 测试框架，提供 `describe/it/expect` 断言 API
- **List_Test**: `entry/src/test/List.test.ets`，所有本地测试套件的注册入口

## Requirements

### Requirement 1: HomeViewModel 初始状态与纯函数测试

**User Story:** As a developer, I want to verify HomeViewModel's initial state and pure functions, so that I can catch regressions in state initialization and time formatting logic.

#### Acceptance Criteria

1. WHEN `new HomeViewModel()` is called, THE Test_Runner SHALL assert `viewState === ViewState.LOADING`
2. WHEN `new HomeViewModel()` is called, THE Test_Runner SHALL assert `accounts.length === 0`
3. WHEN `new HomeViewModel()` is called, THE Test_Runner SHALL assert `isRefreshing === false`
4. WHEN `new HomeViewModel()` is called, THE Test_Runner SHALL assert `networkErrorMsg === ''`
5. WHEN `new HomeViewModel()` is called, THE Test_Runner SHALL assert `geetestTrigger === null`
6. WHEN `resinRecoveryDesc(3660)` is called, THE Test_Runner SHALL assert the result contains '1 小时'
7. WHEN `resinRecoveryDesc(600)` is called, THE Test_Runner SHALL assert the result contains '10 分钟'
8. WHEN `resinRecoveryDesc(0)` is called, THE Test_Runner SHALL assert the result equals `''`

---

### Requirement 2: CharactersViewModel 初始状态与静态方法测试

**User Story:** As a developer, I want to verify CharactersViewModel's initial state and toSelectOptions conversion, so that I can ensure the account selector renders correctly from the start.

#### Acceptance Criteria

1. WHEN `new CharactersViewModel()` is called, THE Test_Runner SHALL assert `viewState === ViewState.LOADING`
2. WHEN `new CharactersViewModel()` is called, THE Test_Runner SHALL assert `selectedAccountIdx === 0`
3. WHEN `new CharactersViewModel()` is called, THE Test_Runner SHALL assert `selectedGameIdx === 0`
4. WHEN `new CharactersViewModel()` is called, THE Test_Runner SHALL assert `characters.length === 0`
5. WHEN `CharactersViewModel.toSelectOptions([{accountId:1, username:'u1'}])` is called, THE Test_Runner SHALL assert the result array has length 1 and `result[0].value === 'u1'`

---

### Requirement 3: LoginViewModel 初始状态、Tab 切换与纯函数测试

**User Story:** As a developer, I want to verify LoginViewModel's initial state, tab switching behavior, phone masking, and cookie validation, so that I can prevent regressions in login flow logic.

#### Acceptance Criteria

1. WHEN `new LoginViewModel()` is called, THE Test_Runner SHALL assert `activeTab === LoginTab.PHONE`
2. WHEN `new LoginViewModel()` is called, THE Test_Runner SHALL assert `loginSuccess === false`
3. WHEN `new LoginViewModel()` is called, THE Test_Runner SHALL assert `isLoading === false`
4. WHEN `new LoginViewModel()` is called, THE Test_Runner SHALL assert `errorMsg === ''`
5. WHEN `switchTab(LoginTab.COOKIE)` is called on a LoginViewModel instance, THE Test_Runner SHALL assert `activeTab === LoginTab.COOKIE`
6. WHEN `switchTab(LoginTab.COOKIE)` is called with `errorMsg` pre-set to a non-empty string, THE Test_Runner SHALL assert `errorMsg === ''`
7. WHEN `maskedPhone` getter is accessed with `phoneNumber = '13812345678'`, THE Test_Runner SHALL assert the result equals `'138****5678'`
8. WHEN `maskedPhone` getter is accessed with `phoneNumber = '123'` (length < 7), THE Test_Runner SHALL assert the result equals `'123'`
9. WHEN `backToPhoneInput()` is called, THE Test_Runner SHALL assert `phoneStep === PhoneStep.INPUT_PHONE`
10. WHEN `backToPhoneInput()` is called with `smsCode` pre-set to `'123456'`, THE Test_Runner SHALL assert `smsCode === ''`
11. WHEN `loginByCookie()` is called with `cookieInput === ''`, THE Test_Runner SHALL assert `errorMsg === 'cookie_empty'`
12. WHEN `loginByCookie()` is called with `cookieInput` containing only whitespace characters, THE Test_Runner SHALL assert `errorMsg === 'cookie_empty'`

---

### Requirement 4: MyViewModel 初始状态测试

**User Story:** As a developer, I want to verify MyViewModel's initial state, so that the My page renders the correct loading skeleton on first mount.

#### Acceptance Criteria

1. WHEN `new MyViewModel()` is called, THE Test_Runner SHALL assert `viewState === ViewState.LOADING`
2. WHEN `new MyViewModel()` is called, THE Test_Runner SHALL assert `accounts.length === 0`

---

### Requirement 5: AccountDetailViewModel 初始状态测试

**User Story:** As a developer, I want to verify AccountDetailViewModel's initial state, so that the delete flow starts from a clean state.

#### Acceptance Criteria

1. WHEN `new AccountDetailViewModel()` is called, THE Test_Runner SHALL assert `deleted === false`
2. WHEN `new AccountDetailViewModel()` is called, THE Test_Runner SHALL assert `errorMsg === ''`

---

### Requirement 6: GenshinDailyDetailViewModel 初始状态与时间格式化测试

**User Story:** As a developer, I want to verify GenshinDailyDetailViewModel's initial state and time formatting pure functions, so that recovery time descriptions are always correct.

#### Acceptance Criteria

1. WHEN `new GenshinDailyDetailViewModel()` is called, THE Test_Runner SHALL assert `viewState === ViewState.LOADING`
2. WHEN `formatSeconds(3660)` is called, THE Test_Runner SHALL assert the result contains '1小时'
3. WHEN `formatSeconds(600)` is called, THE Test_Runner SHALL assert the result contains '10分钟'
4. WHEN `formatSeconds(0)` is called, THE Test_Runner SHALL assert the result equals `''`
5. WHEN `formatTransformer(1, 2, 30)` is called, THE Test_Runner SHALL assert the result contains '1天'
6. WHEN `formatTransformer(0, 3, 0)` is called, THE Test_Runner SHALL assert the result contains '3小时'
7. WHEN `formatTransformer(0, 0, 15)` is called, THE Test_Runner SHALL assert the result contains '15分钟'

---

### Requirement 7: GenshinCharacterDetailViewModel 初始状态与属性类型映射测试

**User Story:** As a developer, I want to verify GenshinCharacterDetailViewModel's initial state and propertyTypeToResource mapping, so that relic and weapon stat labels are always correctly resolved.

#### Acceptance Criteria

1. WHEN `new GenshinCharacterDetailViewModel()` is called, THE Test_Runner SHALL assert `viewState === ViewState.LOADING`
2. WHEN `propertyTypeToResource(GenshinPropertyType.HP_FLAT)` is called, THE Test_Runner SHALL assert the result is not null
3. WHEN `propertyTypeToResource(GenshinPropertyType.CRIT_RATE)` is called, THE Test_Runner SHALL assert the result is not null
4. WHEN `propertyTypeToResource(9999)` is called, THE Test_Runner SHALL assert the result equals `null`

---

### Requirement 8: 测试套件注册

**User Story:** As a developer, I want all ViewModel test suites registered in List.test.ets, so that the test runner discovers and executes all tests automatically.

#### Acceptance Criteria

1. THE List_Test SHALL import and invoke `homeViewModelTest()`
2. THE List_Test SHALL import and invoke `charactersViewModelTest()`
3. THE List_Test SHALL import and invoke `loginViewModelTest()`
4. THE List_Test SHALL import and invoke `myViewModelTest()`
5. THE List_Test SHALL import and invoke `accountDetailViewModelTest()`
6. THE List_Test SHALL import and invoke `genshinDailyDetailViewModelTest()`
7. THE List_Test SHALL import and invoke `genshinCharDetailViewModelTest()`
