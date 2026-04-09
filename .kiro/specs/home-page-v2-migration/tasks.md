# 任务列表

## 任务 1：清理旧版 import，更新 GeetestTrigger

- [x] 1.1 删除 `HomeViewModel.ets` 中对 `GameRoleRow` 的 import
- [x] 1.2 删除 `HomeViewModel.ets` 中对 `DailyNoteRepository` 的 import
- [x] 1.3 在 `GeetestTrigger` 类中新增 `accountId: number` 字段，并更新构造函数
- [x] 1.4 更新 `handleGeetestV2` 方法签名，接收 `account: AccountRowV2` 替代仅 `cookie: string`，以便在触发 Geetest 时保存 `accountId`

## 任务 2：实现 syncDailyNoteV2 私有辅助方法

- [x] 2.1 新增私有方法 `syncDailyNoteV2(account: AccountRowV2, role: GameRoleRowV2): Promise<void>`
- [x] 2.2 在方法内根据 `role.gameId` 分发到对应 V2 Repository（genshin / starrail / zzz），其他 gameId 静默跳过
- [x] 2.3 实现原神分支：调用 `genshinRepository.markDailyNoteSyncing` → `getService().getDailyNote` → 构建 `GenshinDailyNoteRow`（设置 rawJson、accountId、roleUid、updateTime）→ `genshinRepository.upsertDailyNote`
- [x] 2.4 实现星铁分支：调用 `starRailRepository.markDailyNoteSyncing` → `getService().getDailyNote` → 构建 `StarRailDailyNoteRow`（设置 rawJson 及兜底字段 currentStamina、maxStamina）→ `starRailRepository.upsertDailyNote`
- [x] 2.5 实现绝区零分支：调用 `zzzRepository.markDailyNoteSyncing` → `getService().getDailyNote` → 构建 `ZZZDailyNoteRow`（设置 rawJson 及兜底字段 energyCurrent、energyMax）→ `zzzRepository.upsertDailyNote`
- [x] 2.6 在各分支的 catch 块中：若错误包含 `retcode=10035` 则调用 `handleGeetestV2(account, role)`；否则调用对应 Repository 的 `markDailyNoteFailed` 并设置 `networkErrorMsg`

## 任务 3：改写 syncIfNeeded

- [x] 3.1 将 `syncIfNeeded` 中调用 `DailyNoteRepository.syncDailyNote` 的代码替换为 `await this.syncDailyNoteV2(account, role)`
- [x] 3.2 删除原有的 try/catch 块（错误处理已移入 `syncDailyNoteV2`）
- [x] 3.3 删除注释"暂时保留旧版网络同步调用"

## 任务 4：改写 syncAllDailyNotes

- [x] 4.1 将 `syncAllDailyNotes` 中调用 `DailyNoteRepository.syncDailyNote` 的代码替换为 `await this.syncDailyNoteV2(account, role)`
- [x] 4.2 删除原有的 try/catch 块（错误处理已移入 `syncDailyNoteV2`）
- [x] 4.3 删除注释"暂时保留旧版网络同步调用"

## 任务 5：改写 onGeetestResult

- [x] 5.1 删除 `DailyNoteRepository.syncDailyNoteWithChallenge` 调用
- [x] 5.2 新增私有方法 `syncDailyNoteV2WithChallenge(accountId, cookie, gameId, roleId, server, challenge, validate, seccode): Promise<void>`，通过 V2 Service 重新拉取便笺并写库
- [x] 5.3 在 `onGeetestResult` 中调用 `syncDailyNoteV2WithChallenge`，传入 `trigger.accountId`
- [x] 5.4 确保 Geetest 重试成功后调用 `fetchFromLocal()` 刷新 UI

## 任务 6：编写 ViewModel 单元测试

- [x] 6.1 在 `entry/src/test/` 下新建 `HomeViewModel.test.ets`
- [ ] 6.2 实现初始状态测试：`viewState === LOADING`、`accounts.length === 0`、`isRefreshing === false`、`networkErrorMsg === ''`、`geetestTrigger === null`、`refreshCoolingDown === false`
- [ ] 6.3 实现防重入测试：`isRefreshing=true` 时调用 `refresh()` 和 `forceRefresh()` 均不重复触发
- [ ] 6.4 实现 `onGeetestResult` 边界测试：传入 null 时直接返回；`geetestTrigger=null` 时调用不崩溃
- [ ] 6.5 实现 `dispose` 测试：调用后定时器停止；多次调用不崩溃
- [ ] 6.6 实现 `resinRecoveryDesc` 测试：超过 1 小时、不足 1 小时、0 秒、负数四种情况
- [ ] 6.7 实现 `gameColor` 测试：原神/星铁/绝区零返回正确颜色资源；未知 gameId 返回 accent 颜色
- [ ] 6.8 实现 `refreshCoolingDown` 信号翻转测试
- [ ] 6.9 实现 `HomeViewModel.KEYS` 常量路径正确性测试（三个字段）
- [x] 6.10 在 `entry/src/test/List.test.ets` 中注册 `homeViewModelTest`

## 任务 7：构建验证

- [ ] 7.1 执行 `hvigorw clean`
- [x] 7.2 执行 `hvigorw assembleHap -p product=mock`，确认 `BUILD SUCCESSFUL`，零编译错误
- [ ] 7.3 安装到模拟器：`hdc -t 127.0.0.1:5555 install entry/build/mock/outputs/mock/entry-mock-unsigned.hap`
- [ ] 7.4 启动应用，验证 Home 页正常展示便笺数据
- [ ] 7.5 若出现新警告，记录到 `requirements.md` 的"迁移后新增警告记录区"

---

> **说明：UI 测试和 Snapshot 测试不在本 spec 范围内。**
> Home 页的 UI 测试（Hypium + uitest）和截图回归测试（componentSnapshot）已在独立 spec
> `.kiro/specs/entry-ui-and-snapshot-tests/` 中定义，需单独执行。
> 本 spec 完成后，如需验证 UI 视觉回归，请执行 `entry-ui-and-snapshot-tests` spec。
