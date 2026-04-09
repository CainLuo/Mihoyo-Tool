# 任务列表

## 任务 1：清理旧版 import，添加 V2 依赖

- [x] 1.1 从 `entry/src/mock/ets/viewmodel/LoginViewModel.ets` 的 import 列表中移除 `AccountRepository`
- [x] 1.2 从 import 列表中移除 `GameRoleRow`
- [x] 1.3 在 import 列表中添加 `CoreInitializerV2`、`AccountRowV2`、`GameRoleRowV2`
- [x] 1.4 在 import 列表中添加 `MyAccountVM`（用于 `loginedAccountVM` 字段类型）

## 任务 2：补充 LoginViewModelKeys 和 @Trace 字段

- [x] 2.1 在 `LoginViewModelKeys` 类中新增 `loginedAccountId: string = 'vm.loginedAccountId'`
- [x] 2.2 在 `LoginViewModelKeys` 类中新增 `loginedAccountVM: string = 'vm.loginedAccountVM'`
- [x] 2.3 在 `LoginViewModel` 类中新增 `@Trace loginedAccountId: number = -1`
- [x] 2.4 在 `LoginViewModel` 类中新增 `@Trace loginedAccountVM: MyAccountVM | null = null`

## 任务 3：改写 finalizeLogin 使用 V2 Repository

- [x] 3.1 删除 `AccountRepository.insertAccount(username, cookie)` 调用
- [x] 3.2 删除 `AccountRepository.setActiveAccount(accountId)` 调用
- [x] 3.3 删除 `AccountRepository.replaceRoles(accountId, roles)` 调用
- [x] 3.4 删除 `buildMockRoles` 函数中使用 `GameRoleRow` 的代码，改为构建 `GameRoleRowV2[]`
- [x] 3.5 新增：构建 `AccountRowV2`，设置 `username`、`cookie`、`isActive=1`、`createTime`、`updateTime`
- [x] 3.6 新增：调用 `CoreInitializerV2.bbsRepository.saveAccount(accountRow)` 写入账号
- [x] 3.7 新增：调用 `CoreInitializerV2.bbsRepository.getAccountByUsername(username)` 获取自增 id
- [x] 3.8 新增：构建 `GameRoleRowV2[]`（原神 + 星铁 mock 角色），设置 `accountId`、`gameId`、`roleId`、`nickname`、`level`、`server`
- [x] 3.9 新增：调用 `CoreInitializerV2.bbsRepository.saveGameRoles(roleRows)` 写入角色
- [x] 3.10 新增：设置 `this.loginedAccountId = accountId`
- [x] 3.11 确认 `this.loginSuccess = true` 仍在最后设置，行为与迁移前一致

## 任务 4：编写 ViewModel 单元测试

- [x] 4.1 在 `entry/src/test/` 下新建 `LoginViewModel.test.ets`
- [x] 4.2 实现初始状态测试：`activeTab === LoginTab.PHONE`、`loginSuccess === false`、`isLoading === false`、`errorMsg === ''`、`loginedAccountId === -1`、`loginedAccountVM === null`
- [x] 4.3 实现 `switchTab` 测试：切换 Tab 后 `activeTab` 更新；切换时 `errorMsg` 清空
- [x] 4.4 实现 `maskedPhone` 测试：11 位手机号脱敏正确（`138****5678`）；短号（< 7 位）不脱敏
- [x] 4.5 实现 `backToPhoneInput` 测试：`phoneStep` 重置为 `INPUT_PHONE`；`smsCode` 清空
- [x] 4.6 实现 `loginByCookie` 空输入防重测试：`cookieInput=''` 时 `errorMsg === 'cookie_empty'`；`cookieInput='   '`（只有空格）时同样触发
- [x] 4.7 实现 `LoginViewModel.KEYS` 常量路径正确性测试：`loginSuccess`、`loginedAccountId`、`loginedAccountVM` 三个字段路径正确
- [x] 4.8 在 `entry/src/test/List.test.ets` 中注册 `loginViewModelTest`

## 任务 5：构建验证

- [x] 5.1 执行 `hvigorw clean`
- [x] 5.2 执行 `hvigorw assembleHap -p product=mock`，确认 `BUILD SUCCESSFUL`，零编译错误
- [ ] 5.3 安装到模拟器：`hdc -t 127.0.0.1:5555 install entry/build/mock/outputs/mock/entry-mock-unsigned.hap`
- [ ] 5.4 启动应用，进入 Login 页，用 Cookie 方式登录，验证账号写入 V2 DB 后正常跳转
- [x] 5.5 若出现新警告，记录到 `requirements.md` 的"迁移后新增警告记录区"

---

> **说明：UI 测试和 Snapshot 测试不在本 spec 范围内。**
> Login 页的 UI 测试（Hypium + uitest）已在独立 spec
> `.kiro/specs/entry-ui-and-snapshot-tests/` 中定义，需单独执行。
