# Implementation Plan: entry ViewModel 单元测试

## Overview

为 7 个 entry ViewModel 新建本地单元测试文件，并更新 `List.test.ets` 注册所有套件。
所有测试文件放在 `entry/src/test/`，使用 `@ohos/hypium`，不依赖设备。

## Tasks

- [ ] 1. 新建 HomeViewModel.test.ets
  - 创建 `entry/src/test/HomeViewModel.test.ets`
  - 导出函数 `homeViewModelTest()`，使用 `describe('HomeViewModel', ...)`
  - 测试构造函数初始状态：`viewState`、`accounts`、`isRefreshing`、`networkErrorMsg`、`geetestTrigger`
  - 通过 `HomeViewModel['resinRecoveryDesc']` 测试私有静态方法：3660秒、600秒、0秒三个用例
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8_

  - [ ]\* 1.1 为 resinRecoveryDesc 编写属性测试
    - **Property 2: resinRecoveryDesc 零值边界**
    - **Validates: Requirements 1.8**

- [ ] 2. 新建 CharactersViewModel.test.ets
  - 创建 `entry/src/test/CharactersViewModel.test.ets`
  - 导出函数 `charactersViewModelTest()`，使用 `describe('CharactersViewModel', ...)`
  - 测试构造函数初始状态：`viewState`、`selectedAccountIdx`、`selectedGameIdx`、`characters`
  - 测试静态方法 `toSelectOptions`：传入 `[new AccountOption(1, 'u1')]`，断言结果长度和 `value`
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 3. 新建 LoginViewModel.test.ets
  - 创建 `entry/src/test/LoginViewModel.test.ets`
  - 导出函数 `loginViewModelTest()`，使用 `describe('LoginViewModel', ...)`
  - 测试构造函数初始状态：`activeTab`、`loginSuccess`、`isLoading`、`errorMsg`
  - 测试 `switchTab(LoginTab.COOKIE)`：断言 `activeTab` 更新、`errorMsg` 清空
  - 测试 getter `maskedPhone`：11位手机号脱敏、短号不脱敏两个用例
  - 测试 `backToPhoneInput()`：断言 `phoneStep` 重置、`smsCode` 清空
  - 测试 `loginByCookie()` 前置校验：空字符串和纯空格均设置 `errorMsg = 'cookie_empty'`
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11, 3.12_

  - [ ]\* 3.1 为 maskedPhone 编写属性测试
    - **Property 3: maskedPhone 长度不变性**
    - **Validates: Requirements 3.7, 3.8**

  - [ ]\* 3.2 为 switchTab 编写属性测试
    - **Property 4: switchTab 清空 errorMsg**
    - **Validates: Requirements 3.6**

- [ ] 4. 新建 MyViewModel.test.ets
  - 创建 `entry/src/test/MyViewModel.test.ets`
  - 导出函数 `myViewModelTest()`，使用 `describe('MyViewModel', ...)`
  - 测试构造函数初始状态：`viewState`、`accounts`
  - _Requirements: 4.1, 4.2_

- [ ] 5. 新建 AccountDetailViewModel.test.ets
  - 创建 `entry/src/test/AccountDetailViewModel.test.ets`
  - 导出函数 `accountDetailViewModelTest()`，使用 `describe('AccountDetailViewModel', ...)`
  - 测试构造函数初始状态：`deleted`、`errorMsg`
  - _Requirements: 5.1, 5.2_

- [ ] 6. 新建 GenshinDailyDetailViewModel.test.ets
  - 创建 `entry/src/test/GenshinDailyDetailViewModel.test.ets`
  - 导出函数 `genshinDailyDetailViewModelTest()`，使用 `describe('GenshinDailyDetailViewModel', ...)`
  - 测试构造函数初始状态：`viewState`
  - 通过 `GenshinDailyDetailViewModel['formatSeconds']` 测试私有静态方法：3660秒、600秒、0秒
  - 通过 `GenshinDailyDetailViewModel['formatTransformer']` 测试私有静态方法：有天数、只有小时、只有分钟
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

  - [ ]\* 6.1 为 formatSeconds 编写属性测试
    - **Property 5: formatSeconds 非负输入不崩溃**
    - **Validates: Requirements 6.2, 6.3, 6.4**

- [ ] 7. 新建 GenshinCharacterDetailViewModel.test.ets
  - 创建 `entry/src/test/GenshinCharacterDetailViewModel.test.ets`
  - 导出函数 `genshinCharDetailViewModelTest()`，使用 `describe('GenshinCharacterDetailViewModel', ...)`
  - 测试构造函数初始状态：`viewState`
  - 测试静态方法 `propertyTypeToResource`：`HP_FLAT`（值2）非 null、`CRIT_RATE`（值20）非 null、`9999` 返回 null
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

  - [ ]\* 7.1 为 propertyTypeToResource 编写属性测试
    - **Property 6: propertyTypeToResource 已知类型非 null**
    - **Validates: Requirements 7.2, 7.3**

- [ ] 8. 更新 List.test.ets，注册以上 7 个测试套件
  - 修改 `entry/src/test/List.test.ets`
  - 保留现有 `localUnitTest()` 调用
  - 追加 import 和调用：`homeViewModelTest`、`charactersViewModelTest`、`loginViewModelTest`、`myViewModelTest`、`accountDetailViewModelTest`、`genshinDailyDetailViewModelTest`、`genshinCharDetailViewModelTest`
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

- [ ] 9. Checkpoint — 确认所有测试文件可编译
  - 确认所有测试文件无编译错误，ask the user if questions arise.

## Notes

- 任务 1-7 中标 `*` 的属性测试子任务为可选，可跳过以加快 MVP 进度
- 私有静态方法通过 `ViewModel['methodName']` 索引访问，ArkTS 允许此写法
- `loginByCookie()` 的空输入校验是同步的（trim 后为空直接 return），无需 await
- `propertyTypeToResource` 在本地测试环境中 `$r(...)` 返回非 null 对象，只断言 `!== null`
