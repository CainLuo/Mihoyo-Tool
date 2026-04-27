# Design Document: entry ViewModel 单元测试

## Overview

为 `entry/src/test/` 目录补充 7 个 ViewModel 的本地单元测试文件。
所有测试使用 `@ohos/hypium` 框架，不依赖设备，不 import core 模块的 Repository 或 DAO。
测试只覆盖构造函数初始状态和纯函数（static 方法、getter）。

---

## 测试文件结构

```
entry/src/test/
├── List.test.ets                          ← 注册入口（已存在，需更新）
├── LocalUnit.test.ets                     ← 已有测试（保留）
├── HomeViewModel.test.ets                 ← 新建
├── CharactersViewModel.test.ets           ← 新建
├── LoginViewModel.test.ets                ← 新建
├── MyViewModel.test.ets                   ← 新建
├── AccountDetailViewModel.test.ets        ← 新建
├── GenshinDailyDetailViewModel.test.ets   ← 新建
└── GenshinCharacterDetailViewModel.test.ets ← 新建
```

---

## 测试模式

### 1. 构造函数初始状态测试

直接 `new XxxViewModel()`，断言各 `@Trace` 字段的初始值。
不调用任何 async 方法（loadData / refresh 等），避免触发 Repository 依赖。

```typescript
it("初始 viewState 为 LOADING", 0, () => {
  const vm = new HomeViewModel();
  expect(vm.viewState).assertEqual(ViewState.LOADING);
});
```

### 2. 纯函数测试（static 方法）

直接调用 `ClassName.staticMethod(args)`，断言返回值。
这些方法不依赖实例状态，也不调用 Repository。

```typescript
it("resinRecoveryDesc 3660秒包含1小时", 0, () => {
  const result = HomeViewModel["resinRecoveryDesc"](3660);
  expect(result.indexOf("1 小时") >= 0).assertTrue();
});
```

> 注意：`resinRecoveryDesc`、`formatSeconds`、`formatTransformer` 是 `private static`，
> 测试时通过 `ViewModel['methodName']` 方式访问（ArkTS 允许通过索引访问私有成员）。

### 3. getter 测试

设置实例字段后访问 getter，断言返回值。

```typescript
it("maskedPhone 脱敏正确", 0, () => {
  const vm = new LoginViewModel();
  vm.phoneNumber = "13812345678";
  expect(vm.maskedPhone).assertEqual("138****5678");
});
```

### 4. 状态变更方法测试（同步）

调用同步方法（`switchTab`、`backToPhoneInput`），断言字段变化。
不调用 async 方法，避免 Repository 依赖。

```typescript
it("switchTab 切换后 activeTab 更新", 0, () => {
  const vm = new LoginViewModel();
  vm.switchTab(LoginTab.COOKIE);
  expect(vm.activeTab).assertEqual(LoginTab.COOKIE);
});
```

---

## 各 ViewModel 测试用例设计

### HomeViewModel.test.ets

被测类：`entry/src/main/ets/viewmodel/HomeViewModel.ets`

**关键字段初始值：**

- `viewState: ViewState = ViewState.LOADING`
- `accounts: MihoyoAccountVM[] = []`
- `isRefreshing: boolean = false`
- `networkErrorMsg: string = ''`
- `geetestTrigger: GeetestTrigger | null = null`

**纯函数：** `private static resinRecoveryDesc(seconds: number): string`

- 通过 `HomeViewModel['resinRecoveryDesc']` 访问
- `3660` → 包含 `'1 小时'`
- `600` → 包含 `'10 分钟'`
- `0` → 返回 `''`

**测试套件导出函数名：** `homeViewModelTest`

---

### CharactersViewModel.test.ets

被测类：`entry/src/main/ets/viewmodel/CharactersViewModel.ets`

**关键字段初始值：**

- `viewState: ViewState = ViewState.LOADING`
- `selectedAccountIdx: number = 0`
- `selectedGameIdx: number = 0`
- `characters: GameDataSummary[] = []`

**静态方法：** `static toSelectOptions(opts: AccountOption[]): SelectOption[]`

- 输入 `[new AccountOption(1, 'u1')]` → 返回长度为 1 的数组，`result[0].value === 'u1'`

**测试套件导出函数名：** `charactersViewModelTest`

---

### LoginViewModel.test.ets

被测类：`entry/src/main/ets/viewmodel/LoginViewModel.ets`

**关键字段初始值：**

- `activeTab: LoginTab = LoginTab.PHONE`
- `loginSuccess: boolean = false`
- `isLoading: boolean = false`
- `errorMsg: string = ''`

**同步方法：** `switchTab(tab: LoginTab): void`

- 切换到 `LoginTab.COOKIE` → `activeTab === LoginTab.COOKIE`
- 预设 `errorMsg = 'error'` 后切换 → `errorMsg === ''`

**getter：** `get maskedPhone(): string`

- `phoneNumber = '13812345678'` → `'138****5678'`
- `phoneNumber = '123'`（长度 < 7）→ `'123'`

**同步方法：** `backToPhoneInput(): void`

- 调用后 `phoneStep === PhoneStep.INPUT_PHONE`
- 预设 `smsCode = '123456'` 后调用 → `smsCode === ''`

**async 方法（仅测试同步前置校验）：** `loginByCookie()`

- `cookieInput = ''` → `errorMsg === 'cookie_empty'`（方法内同步赋值，无需 await）
- `cookieInput = '   '`（纯空格）→ `errorMsg === 'cookie_empty'`

> `loginByCookie` 在 `cookieInput.trim().length === 0` 时同步设置 `errorMsg` 并 return，
> 不会触发 Repository 调用，因此可以直接调用并断言。

**测试套件导出函数名：** `loginViewModelTest`

---

### MyViewModel.test.ets

被测类：`entry/src/main/ets/viewmodel/MyViewModel.ets`

**关键字段初始值：**

- `viewState: ViewState = ViewState.LOADING`
- `accounts: MyAccountVM[] = []`

**测试套件导出函数名：** `myViewModelTest`

---

### AccountDetailViewModel.test.ets

被测类：`entry/src/main/ets/viewmodel/AccountDetailViewModel.ets`

**关键字段初始值：**

- `deleted: boolean = false`
- `errorMsg: string = ''`

**测试套件导出函数名：** `accountDetailViewModelTest`

---

### GenshinDailyDetailViewModel.test.ets

被测类：`entry/src/main/ets/viewmodel/GenshinDailyDetailViewModel.ets`

**关键字段初始值：**

- `viewState: ViewState = ViewState.LOADING`

**纯函数（private static，通过索引访问）：**

`formatSeconds(seconds: number): string`

- `3660` → 包含 `'1小时'`
- `600` → 包含 `'10分钟'`
- `0` → 返回 `''`

`formatTransformer(day: number, hour: number, minute: number): string`

- `(1, 2, 30)` → 包含 `'1天'`
- `(0, 3, 0)` → 包含 `'3小时'`
- `(0, 0, 15)` → 包含 `'15分钟'`

**测试套件导出函数名：** `genshinDailyDetailViewModelTest`

---

### GenshinCharacterDetailViewModel.test.ets

被测类：`entry/src/main/ets/viewmodel/GenshinCharacterDetailViewModel.ets`

**关键字段初始值：**

- `viewState: ViewState = ViewState.LOADING`

**静态方法：** `static propertyTypeToResource(pt: number): Resource | null`

- `GenshinPropertyType.HP_FLAT`（值 = 2）→ 返回非 null
- `GenshinPropertyType.CRIT_RATE`（值 = 20）→ 返回非 null
- `9999`（未知类型）→ 返回 `null`

> `propertyTypeToResource` 返回 `$r(...)` Resource 对象，在本地测试环境中
> `$r` 返回一个对象引用（非 null），因此只断言 `!== null` 即可，不断言具体字符串。

**测试套件导出函数名：** `genshinCharDetailViewModelTest`

---

## 测试文件模板

每个测试文件遵循以下结构：

```typescript
import { describe, it, expect } from "@ohos/hypium";
import { XxxViewModel } from "../main/ets/viewmodel/XxxViewModel";
// 按需 import 枚举

export default function xxxViewModelTest() {
  describe("XxxViewModel", () => {
    it("初始 xxx 为 yyy", 0, () => {
      const vm = new XxxViewModel();
      expect(vm.xxx).assertEqual(yyy);
    });

    // ...更多用例
  });
}
```

---

## List.test.ets 更新方案

在现有 `localUnitTest()` 调用基础上，追加 7 个新测试套件的 import 和调用：

```typescript
import localUnitTest from "./LocalUnit.test";
import homeViewModelTest from "./HomeViewModel.test";
import charactersViewModelTest from "./CharactersViewModel.test";
import loginViewModelTest from "./LoginViewModel.test";
import myViewModelTest from "./MyViewModel.test";
import accountDetailViewModelTest from "./AccountDetailViewModel.test";
import genshinDailyDetailViewModelTest from "./GenshinDailyDetailViewModel.test";
import genshinCharDetailViewModelTest from "./GenshinCharacterDetailViewModel.test";

export default function testsuite() {
  localUnitTest();
  homeViewModelTest();
  charactersViewModelTest();
  loginViewModelTest();
  myViewModelTest();
  accountDetailViewModelTest();
  genshinDailyDetailViewModelTest();
  genshinCharDetailViewModelTest();
}
```

---

## Correctness Properties

### Property 1: ViewModel 初始状态幂等性

对同一 ViewModel 类多次调用构造函数，每次得到的初始字段值相同。

- 适用于：所有 7 个 ViewModel
- 可测试性：yes - property

### Property 2: resinRecoveryDesc 零值边界

`resinRecoveryDesc(0)` 和 `resinRecoveryDesc(-1)` 均返回 `''`（不崩溃，不返回非空字符串）。

- 适用于：HomeViewModel
- 可测试性：yes - example

### Property 3: maskedPhone 长度不变性

`maskedPhone` 的返回值长度 ≤ 原始 `phoneNumber` 长度（脱敏不增加字符）。

- 适用于：LoginViewModel
- 可测试性：yes - property

### Property 4: switchTab 清空 errorMsg

无论 `errorMsg` 初始值为何，调用 `switchTab` 后 `errorMsg === ''`。

- 适用于：LoginViewModel
- 可测试性：yes - property

### Property 5: formatSeconds 非负输入不崩溃

对任意非负整数输入，`formatSeconds` 返回字符串（不抛异常）。

- 适用于：GenshinDailyDetailViewModel
- 可测试性：yes - property

### Property 6: propertyTypeToResource 已知类型非 null

对 GenshinPropertyType 枚举中所有已知值，`propertyTypeToResource` 返回非 null。

- 适用于：GenshinCharacterDetailViewModel
- 可测试性：yes - property
