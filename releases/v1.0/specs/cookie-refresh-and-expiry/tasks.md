# 实现计划：Cookie 自动刷新与过期处理

## 概述

按设计文档分层实现：先建纯逻辑的 `ColdStartCookieChecker` 和并发控制的 `CookieRefreshCoordinator`，再集成到各游戏 Repository 的 API 按需刷新路径，最后扩展 `HomeViewModel` 触发冷启动检查并弹 Dialog，补充多语言资源和测试。

## 任务

- [x] 1. 新建 ColdStartCookieChecker（纯逻辑层）
  - 在 `core/src/main/ets/cookie/ColdStartCookieChecker.ets` 新建文件
  - 定义 `FailedAccountInfo` 类（username、nickname、isNetworkError 字段）
  - 定义 `ColdStartRefreshResult` 类（successCount、failedAccounts 字段）
  - 实现 `needsColdStartRefresh(updateTime: number, now: number): boolean` 纯函数，阈值为 604800 秒
  - 实现 `checkAndRefreshAll(bbsRepository, now?)` 静态异步方法：遍历所有账号，跳过 cookie 为空或 update_time 未超阈值的账号，跳过无 stoken 的账号，调用 `refreshCookieIfNeeded` 刷新，单账号失败不中断其他账号，记录日志到 `ApiLogSystem`
  - 在 `core/Index.ets` 中导出新增类型
  - _需求：1.1–1.10、4.5、6.1–6.3、7.4、9.1–9.2_

- [x] 2. 新建 CookieRefreshCoordinator（并发锁管理）
  - 在 `core/src/main/ets/cookie/CookieRefreshCoordinator.ets` 新建文件
  - 实现单例模式（`static readonly instance`）
  - 维护 `refreshLocks: Map<string, Promise<string>>` 和 `lastRefreshTime: Map<string, number>`
  - 实现 `refreshWithLock(username, cookie, bbsRepository)` 方法：60 秒内同一账号复用进行中的 Promise，刷新完成后移除锁，刷新成功后记录时间戳
  - 实现 `clearLock(username)` 方法：清除指定账号的锁和时间戳
  - 在 `core/Index.ets` 中导出
  - _需求：2.7、4.3、4.4、5.3_

- [x] 3. 各游戏 Repository 集成 API 按需刷新
  - [x] 3.1 GenshinRepository.syncDailyNote 集成刷新
    - 在 `syncDailyNote` 的 catch 块中检测 `AuthExpiredError`
    - 调用 `CookieRefreshCoordinator.instance.refreshWithLock` 获取新 cookie
    - 用新 cookie 重试一次 `getDailyNote`；重试后若仍返回 -100 则抛出 `AuthExpiredError`，不再重试
    - 刷新失败（无 stoken 或 stoken 过期）直接向上抛出 `AuthExpiredError`
    - _需求：2.1–2.6、9.3_
  - [x] 3.2 StarRailRepository.syncDailyNote 集成刷新
    - 与 3.1 相同模式，集成到 `StarRailRepository.syncDailyNote`
    - _需求：2.1–2.6、9.3_
  - [x] 3.3 ZZZRepository.syncDailyNote 集成刷新
    - 与 3.1 相同模式，集成到 `ZZZRepository.syncDailyNote`
    - _需求：2.1–2.6、9.3_

- [x] 4. 多语言资源：新增 Cookie 过期 Dialog 文案
  - 在 `entry/src/main/resources/base/element/string.json` 新增三个 key：`cookie_expired_dialog_title`（登录已过期）、`cookie_expired_dialog_msg`（%s 的登录凭证已过期，请重新登录以继续使用）、`cookie_expired_go_login`（去登录）
  - 在 `entry/src/main/resources/zh_HK/element/string.json` 同步新增繁体中文文案
  - 在 `entry/src/main/resources/en/element/string.json` 同步新增英文文案
  - 确认 `dialog_cancel`（取消）key 已存在，若不存在则同步新增
  - _需求：8.4_

- [x] 5. HomeViewModel 扩展：冷启动检查触发与 Dialog 处理
  - [x] 5.1 新增 cookieExpiredDialogQueue 状态字段
    - 在 `HomeViewModel` 中新增 `@Trace cookieExpiredDialogQueue: FailedAccountInfo[] = []`
    - 新增 `HomeViewModelKeys` 中对应的 KEYS 常量
    - _需求：3.1、8.1、8.6_
  - [x] 5.2 实现 handleColdStartRefreshResult 方法
    - 新增私有方法 `handleColdStartRefreshResult(result: ColdStartRefreshResult)`
    - 将 `result.failedAccounts` 中 `isNetworkError=false` 的账号追加到 `cookieExpiredDialogQueue`
    - 若有成功刷新（`result.successCount > 0`），异步触发 `syncIfNeeded()`
    - _需求：3.1、3.6、6.3–6.4_
  - [x] 5.3 在 loadData() 末尾触发冷启动检查
    - 在 `loadData()` 首屏渲染完成后（现有逻辑末尾），异步调用 `ColdStartCookieChecker.checkAndRefreshAll`
    - 通过 `.then()` 调用 `handleColdStartRefreshResult`，`.catch()` 静默忽略
    - _需求：1.10、6.1–6.2_
  - [x] 5.4 实现 showNextCookieExpiredDialog 方法
    - 新增公开方法 `showNextCookieExpiredDialog(context: UIContext)`
    - 从 `cookieExpiredDialogQueue` 取出第一个账号，使用 `promptAction.showDialog` 弹出 Dialog
    - Dialog 标题使用 `cookie_expired_dialog_title`，内容使用 `cookie_expired_dialog_msg`（含账号昵称）
    - 「去登录」按钮调用 `RouterUtil.push(AppRoutes.LOGIN)`；「取消」按钮关闭 Dialog
    - _需求：3.2、8.1–8.3、8.5–8.6_

- [x] 6. Home 页面集成 Dialog 展示逻辑
  - 在 `entry/src/main/ets/pages/Home.ets` 中通过 `@Monitor` 监听 `cookieExpiredDialogQueue` 变化
  - 当队列非空时调用 `vm.showNextCookieExpiredDialog(this.getUIContext())`
  - _需求：3.6、8.1_

- [x] 7. 单元测试：ColdStartCookieChecker 纯函数（core/src/test/）
  - [x] 7.1 新建 ColdStartCookieChecker.test.ets，测试 needsColdStartRefresh 边界值
    - 超过 7 天（604801 秒差）返回 true
    - 恰好 7 天（604800 秒差）返回 false
    - 不足 7 天（86400 秒差）返回 false
    - updateTime=0 时返回 true
    - now < updateTime 时返回 false
    - _需求：7.4_
  - [ ]\* 7.2 属性测试：needsColdStartRefresh 阈值判断（Property 1）
    - **Property 1：冷启动刷新阈值判断**
    - 随机生成 0~2000000 秒的时间差，验证 `diff > 604800` 与函数返回值一致
    - 运行 100 次迭代
    - **验证：需求 1.2、1.4、7.4**
  - [ ]\* 7.3 属性测试：Cookie 字段 round-trip（Property 2）
    - **Property 2：Cookie 字段提取 round-trip**
    - 随机生成含各字段的 cookie 字符串，对随机字段执行 extractCookieField → replaceCookieField → extractCookieField，验证两次提取结果相同
    - 运行 100 次迭代
    - **验证：需求 7.3**
  - 在 `core/src/test/List.test.ets` 中注册新测试套件
  - _需求：7.1–7.4_

- [ ] 8. 设备端集成测试：CookieRefreshCoordinator（core/src/ohosTest/）
  - [ ]\* 8.1 新建 CookieRefreshCoordinator.test.ets
    - 并发刷新去重：同一账号并发 5 次 refreshWithLock，验证网络请求只发出 1 次，5 个调用均获得相同结果
    - 不同账号并行刷新：账号 A 和账号 B 同时刷新，互不阻塞
    - clearLock 后重新刷新：调用 clearLock 后再次刷新，重新发起网络请求
    - 60 秒内复用结果：已完成一次刷新，60 秒内再次调用不发起新请求
    - _需求：2.7、4.3–4.4、5.3_

- [ ] 9. ViewModel 单元测试补充（entry/src/test/）
  - [ ]\* 9.1 在 HomeViewModel.test.ets 中补充 Cookie 刷新相关用例
    - 初始 cookieExpiredDialogQueue 为空数组
    - handleColdStartRefreshResult 无失败账号时不修改队列
    - handleColdStartRefreshResult 有 N 个 stoken 过期账号时队列长度为 N
    - _需求：8.1、8.6_

- [x] 10. 最终检查点
  - 确保所有测试通过，向用户确认如有疑问
