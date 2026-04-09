# 需求文档

## 简介

本 spec 覆盖 Login 页 mock source set 的 `LoginViewModel` 从旧版 `AccountRepository`（V1）迁移到 V2 Repository 的完整重构工作。

**范围**：仅修改 `entry/src/mock/ets/viewmodel/LoginViewModel.ets`。main source set 的 `LoginViewModel`（`entry/src/main/ets/viewmodel/LoginViewModel.ets`）已完全使用 V2 Repository，**不在本 spec 修改范围内**。

**目标**：

1. 移除 mock LoginViewModel 中所有旧版 `AccountRepository` 和 `GameRoleRow` 调用
2. `finalizeLogin` 切换到 `CoreInitializerV2.bbsRepository`，写入 `AccountRowV2` 和 `GameRoleRowV2`
3. `LoginViewModelKeys` 补充 `loginedAccountId` 和 `loginedAccountVM` 字段，与 main source set 接口保持一致
4. mock 登录行为对 View 层完全透明，UI 功能不变

---

## 术语表

- **mock LoginViewModel**：`entry/src/mock/ets/viewmodel/LoginViewModel.ets`，mock source set 专用，所有登录方法直接返回 Mock 数据，不发起真实网络请求
- **main LoginViewModel**：`entry/src/main/ets/viewmodel/LoginViewModel.ets`，release source set，已完成 V2 迁移，本 spec 不修改
- **AccountRepository**：旧版（V1）账号工具类，本 spec 完成后将从 mock LoginViewModel 中完全移除
- **GameRoleRow**：旧版（V1）游戏角色数据模型，本 spec 完成后将从 mock LoginViewModel 中完全移除
- **V2 finalizeLogin**：使用 `CoreInitializerV2.bbsRepository.saveAccount(AccountRowV2)` 写入账号，`saveGameRoles(GameRoleRowV2[])` 写入角色

---

## 需求列表

### 需求 1：移除旧版 import

**用户故事：** 作为开发者，我希望移除 mock LoginViewModel 中所有 V1 旧版 import，使 mock 环境和 release 环境的数据写入路径一致。

#### 验收标准

1. `entry/src/mock/ets/viewmodel/LoginViewModel.ets` 不得 import `AccountRepository`
2. `entry/src/mock/ets/viewmodel/LoginViewModel.ets` 不得 import `GameRoleRow`
3. 移除 V1 import 后，编译器不得产生任何与 import 相关的错误

---

### 需求 2：改写 finalizeLogin 使用 V2 Repository

**用户故事：** 作为开发者，我希望 mock 登录成功后通过 V2 Repository 写入账号和角色数据，使 mock 数据库结构与 release 环境一致。

#### 验收标准

1. `finalizeLogin` 使用 `CoreInitializerV2.bbsRepository.saveAccount(AccountRowV2)` 写入账号
2. `finalizeLogin` 使用 `CoreInitializerV2.bbsRepository.saveGameRoles(GameRoleRowV2[])` 写入角色
3. mock 角色数据（原神 + 星铁）构建为 `GameRoleRowV2[]`，字段与 main source set 的 `finalizeLogin` 保持一致
4. mock 登录成功后，`loginSuccess` 仍设为 `true`，行为与迁移前一致
5. `loginedAccountId` 设为写入后的账号 id，`loginedAccountVM` 设为 null（mock 环境不组装 VM）

---

### 需求 3：补充 LoginViewModelKeys 字段

**用户故事：** 作为开发者，我希望 mock LoginViewModel 的 KEYS 常量与 main source set 接口一致，使 View 层的 `@Monitor` 路径在两个 source set 下都能正确工作。

#### 验收标准

1. `LoginViewModelKeys` 新增 `loginedAccountId: string = 'vm.loginedAccountId'`
2. `LoginViewModelKeys` 新增 `loginedAccountVM: string = 'vm.loginedAccountVM'`
3. `LoginViewModel` 新增 `@Trace loginedAccountId: number = -1`
4. `LoginViewModel` 新增 `@Trace loginedAccountVM: MyAccountVM | null = null`

---

### 需求 4：UI 功能和用户体验不变

**用户故事：** 作为用户，我希望 V2 迁移后 mock 环境的登录行为与迁移前完全一致，使重构对我透明无感。

#### 验收标准

1. 手机号登录、二维码登录、Cookie 登录三种方式的 mock 流程保持不变
2. 登录成功后 `loginSuccess` 仍变为 `true`，View 层跳转逻辑不受影响
3. `switchTab`、`dispose`、`maskedPhone`、`backToPhoneInput` 等方法行为不变

---

### 需求 5：构建验证要求

#### 验收标准

1. 迁移完成后，执行 `hvigorw clean && hvigorw assembleHap -p product=mock` 输出 `BUILD SUCCESSFUL`，零编译错误
2. 构建产物不得产生超出"已知警告说明"中预存在警告的新警告
3. 若出现新警告，开发者须排查并修复，或记录在"已知警告说明"的新增警告区

---

## 数据流文档

### mock finalizeLogin 流程（V2 版本）

```mermaid
flowchart TD
    A([loginByPhone / loginByCookie / QR 确认]) --> B[finalizeLogin username, cookie]

    B --> C[构建 AccountRowV2\nusername, cookie, isActive=1]
    C --> D[bbsRepository.saveAccount]
    D --> E[bbsRepository.getAccountByUsername\n获取自增 id]

    E --> F[构建 GameRoleRowV2[]\n原神 + 星铁 mock 角色]
    F --> G[bbsRepository.saveGameRoles]

    G --> H[loginedAccountId = accountId]
    H --> I[loginSuccess = true]
    I --> J[/View 层监听 loginSuccess\n跳转到 AccountDetail/]
```

---

## 测试用例设计

### ViewModel 单元测试（entry/src/test/LoginViewModel.test.ets）

> 遵循 testing-entry-pages.md 规范，只测试纯逻辑，不依赖设备。

| 测试用例                       | 前置条件                    | 操作                                   | 预期结果                                     |
| ------------------------------ | --------------------------- | -------------------------------------- | -------------------------------------------- |
| 初始 activeTab 为 PHONE        | 新建实例                    | `new LoginViewModel()`                 | `activeTab === LoginTab.PHONE`               |
| 初始 loginSuccess 为 false     | 新建实例                    | `new LoginViewModel()`                 | `loginSuccess === false`                     |
| 初始 isLoading 为 false        | 新建实例                    | `new LoginViewModel()`                 | `isLoading === false`                        |
| 初始 errorMsg 为空             | 新建实例                    | `new LoginViewModel()`                 | `errorMsg === ''`                            |
| 初始 loginedAccountId 为 -1    | 新建实例                    | `new LoginViewModel()`                 | `loginedAccountId === -1`                    |
| 初始 loginedAccountVM 为 null  | 新建实例                    | `new LoginViewModel()`                 | `loginedAccountVM === null`                  |
| switchTab 切换 Tab             | `activeTab=PHONE`           | `switchTab(LoginTab.COOKIE)`           | `activeTab === LoginTab.COOKIE`              |
| switchTab 清空 errorMsg        | `errorMsg='error'`          | `switchTab(LoginTab.COOKIE)`           | `errorMsg === ''`                            |
| maskedPhone 脱敏正确           | `phoneNumber='13812345678'` | `vm.maskedPhone`                       | `'138****5678'`                              |
| maskedPhone 短号不脱敏         | `phoneNumber='123'`         | `vm.maskedPhone`                       | `'123'`                                      |
| backToPhoneInput 重置步骤      | `phoneStep=INPUT_CODE`      | `backToPhoneInput()`                   | `phoneStep === INPUT_PHONE`                  |
| backToPhoneInput 清空验证码    | `smsCode='123456'`          | `backToPhoneInput()`                   | `smsCode === ''`                             |
| loginByCookie 空输入不触发     | `cookieInput=''`            | `loginByCookie()`                      | `errorMsg === 'cookie_empty'`                |
| loginByCookie 只有空格不触发   | `cookieInput='   '`         | `loginByCookie()`                      | `errorMsg === 'cookie_empty'`（trim 后为空） |
| KEYS.loginSuccess 路径正确     | —                           | `LoginViewModel.KEYS.loginSuccess`     | 值为 `'vm.loginSuccess'`                     |
| KEYS.loginedAccountId 路径正确 | —                           | `LoginViewModel.KEYS.loginedAccountId` | 值为 `'vm.loginedAccountId'`                 |

---

## 构建验证要求

### 执行步骤

每次 spec 任务执行完成后，必须按以下顺序验证：

```bash
# 1. 清理
"$HVIGOR" clean

# 2. 构建（mock 模式）
"$HVIGOR" assembleHap -p product=mock

# 3. 安装
"$HDC" -t 127.0.0.1:5555 install entry/build/mock/outputs/mock/entry-mock-unsigned.hap

# 4. 启动
"$HDC" -t 127.0.0.1:5555 shell aa start -b com.cainluo.mihoyo.tools -a EntryAbility
```

### 验收标准

1. `hvigorw assembleHap -p product=mock` 输出 `BUILD SUCCESSFUL`，零编译错误
2. 安装和启动无异常
3. 新增警告必须记录在下方"已知警告说明"中

---

## 文件改动清单

| 文件                                              | 改动类型 | 改动内容                                                                                      |
| ------------------------------------------------- | -------- | --------------------------------------------------------------------------------------------- |
| `entry/src/mock/ets/viewmodel/LoginViewModel.ets` | 修改     | 移除旧版 import，改写 `finalizeLogin`，补充 `loginedAccountId`/`loginedAccountVM` 字段和 KEYS |

**本 spec 不删除的文件**：

- 旧版 V1 文件（`CharacterRepository.ets`、`DailyNoteRepository.ets` 等）— 属于 `v1-cleanup` spec 的清理范围

---

## 已知警告说明

### 预存在警告（迁移前已存在，不属于本 spec 引入）

| 警告来源           | 警告内容                                                                                      | 说明                                                                                    |
| ------------------ | --------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `RdbManagerV2.ets` | `canIUse('SystemCapability.DistributedDataManager.RelationalStore.Core')` 返回 false 相关警告 | HarmonyOS NEXT 模拟器环境下 RDB canIUse 检查的已知问题，不影响功能，运行时 RDB 正常工作 |
| 签名配置           | `Will skip sign 'hos_hap'`                                                                    | 开发环境未配置签名，正常现象                                                            |

### 迁移后新增警告记录区

> 执行 clean + rebuild 后，若出现新警告，在此处记录：

| 警告来源   | 警告内容   | 处理方式   |
| ---------- | ---------- | ---------- |
| （待填写） | （待填写） | （待填写） |
