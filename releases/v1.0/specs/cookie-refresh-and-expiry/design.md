# 设计文档：Cookie 自动刷新与过期处理

## 概述

本功能为米游社工具类 HarmonyOS NEXT App 提供完整的 Cookie 生命周期管理能力。

米游社 API 使用 Cookie 作为身份凭证，其中 `ltoken` 和 `cookie_token` 约 30 天过期，而 `stoken` 有效期约 1 年。本功能覆盖两条刷新路径：

1. **冷启动定期检查**：App 启动后，在首屏渲染完成后异步检查 `account_table.update_time`，超过 7 天且有 `stoken` 则静默刷新。
2. **API 按需刷新**：任意 API 返回 `retcode=-100` 时，有 `stoken` 则刷新后自动重试一次，无 `stoken` 或刷新失败则弹 Dialog 引导重新登录。

**关键约束**：

- 刷新能力取决于 cookie 字符串中是否包含非空 `stoken`，与登录方式无关
- 冷启动刷新完全在后台静默执行，不阻塞首屏渲染
- 多账号场景下每个账号独立管理刷新状态，互不影响

---

## 架构

### 整体数据流

```
冷启动路径：
  CoreInitializer.initCore() 完成
    → HomeViewModel.loadData() 渲染首屏
    → ColdStartCookieChecker.checkAndRefreshAll()（后台异步）
        → BBSRepository.getAllAccounts()
        → needsColdStartRefresh(updateTime, now)
        → BBSRepository.refreshCookieIfNeeded(username, cookie)
        → promptAction.showDialog（仅刷新失败且 stoken 过期时）

API 按需刷新路径：
  任意 Repository.syncXxx() 调用
    → API 返回 retcode=-100
    → CookieRefreshCoordinator.refreshWithLock(username, cookie)
        → BBSRepository.refreshCookieIfNeeded(username, cookie)
        → 重试原始 API 请求（使用新 cookie）
        → 失败时 → promptAction.showDialog
```

### 模块职责

| 模块                                  | 位置                                                    | 职责                                                        |
| ------------------------------------- | ------------------------------------------------------- | ----------------------------------------------------------- |
| `ColdStartCookieChecker`              | `core/src/main/ets/cookie/ColdStartCookieChecker.ets`   | 冷启动检查逻辑：遍历账号、判断是否需要刷新、调用刷新        |
| `CookieRefreshCoordinator`            | `core/src/main/ets/cookie/CookieRefreshCoordinator.ets` | 并发控制：维护每个账号的刷新锁（Map），防止同一账号并发刷新 |
| `BBSRepository.refreshCookieIfNeeded` | `core/src/main/ets/repository/BBSRepository.ets`        | 已有：用 stoken 换新 ltoken/cookie_token，写入 DB           |
| `HomeViewModel`（触发点）             | `entry/src/main/ets/viewmodel/HomeViewModel.ets`        | 在 `loadData()` 首屏渲染完成后触发冷启动检查                |
| Dialog 展示                           | `entry` 层 ViewModel                                    | 使用 `promptAction.showDialog` 展示登录过期 Dialog          |

### 分层边界

```
entry 层（ViewModel）
  ├── 触发冷启动检查（调用 ColdStartCookieChecker）
  ├── 处理刷新结果回调（弹 Dialog、重新加载数据）
  └── 展示 Dialog（promptAction.showDialog）

core 层
  ├── ColdStartCookieChecker（纯逻辑，可注入时间戳）
  ├── CookieRefreshCoordinator（并发锁管理）
  └── BBSRepository.refreshCookieIfNeeded（已有）
```

---

## 组件与接口

### ColdStartCookieChecker

```typescript
// core/src/main/ets/cookie/ColdStartCookieChecker.ets

export class ColdStartRefreshResult {
  successCount: number = 0;
  failedAccounts: FailedAccountInfo[] = [];
}

export class FailedAccountInfo {
  username: string = "";
  nickname: string = "";
  isNetworkError: boolean = false; // true=网络错误，false=stoken 过期/不存在
}

export class ColdStartCookieChecker {
  /**
   * 纯函数：判断是否需要冷启动刷新。
   * 可注入 now 参数，便于单元测试。
   * @param updateTime  account_table.update_time（Unix 秒）
   * @param now         当前时间戳（Unix 秒），默认 Math.floor(Date.now() / 1000)
   */
  static needsColdStartRefresh(updateTime: number, now: number): boolean {
    return now - updateTime > COLD_START_REFRESH_THRESHOLD_SECONDS;
  }

  /**
   * 遍历所有账号，对需要刷新的账号执行静默刷新。
   * 在后台异步执行，不阻塞调用方。
   * @param bbsRepository  BBSRepository 实例
   * @param now            当前时间戳（Unix 秒），默认 Math.floor(Date.now() / 1000)
   */
  static async checkAndRefreshAll(
    bbsRepository: BBSRepository,
    now?: number,
  ): Promise<ColdStartRefreshResult>;
}

/** 7 天阈值（秒） */
const COLD_START_REFRESH_THRESHOLD_SECONDS = 604800;
```

### CookieRefreshCoordinator

```typescript
// core/src/main/ets/cookie/CookieRefreshCoordinator.ets

export class CookieRefreshCoordinator {
  /** 单例 */
  static readonly instance: CookieRefreshCoordinator;

  /**
   * 带锁的刷新：同一账号 60 秒内只发起一次网络请求，并发调用复用结果。
   * @param username       账号 username
   * @param cookie         当前 cookie 字符串
   * @param bbsRepository  BBSRepository 实例
   * @returns 刷新后的新 cookie 字符串
   * @throws AuthExpiredError  stoken 不存在或已过期
   */
  async refreshWithLock(
    username: string,
    cookie: string,
    bbsRepository: BBSRepository,
  ): Promise<string>;

  /**
   * 清除指定账号的刷新锁（账号删除时调用）。
   */
  clearLock(username: string): void;
}
```

### HomeViewModel 扩展

在 `HomeViewModel.loadData()` 中，首屏渲染完成后触发冷启动检查：

```typescript
// 在 loadData() 末尾，首屏渲染完成后异步触发
ColdStartCookieChecker.checkAndRefreshAll(CoreInitializer.bbsRepository)
  .then((result) => {
    // 对每个 stoken 过期的失败账号弹 Dialog
    this.handleColdStartRefreshResult(result);
    // 如有成功刷新，重新触发数据同步
    if (result.successCount > 0) {
      this.syncIfNeeded().catch((_: Error | object) => {});
    }
  })
  .catch((_: Error | object) => {});
```

### API 按需刷新集成点

在各游戏 Repository 的 `syncDailyNote` 等方法中，捕获 `AuthExpiredError` 后调用 `CookieRefreshCoordinator`：

```typescript
// 伪代码，集成到 GenshinRepository / StarRailRepository / ZZZRepository
try {
  await this.service.getDailyNote(roleId, server, cookie);
} catch (e) {
  if (e instanceof AuthExpiredError) {
    // 尝试刷新并重试
    const newCookie = await CookieRefreshCoordinator.instance.refreshWithLock(
      username,
      cookie,
      CoreInitializer.bbsRepository,
    );
    await this.service.getDailyNote(roleId, server, newCookie);
  } else {
    throw e;
  }
}
```

**注意**：`retcode=-100` 的检测点在各 Repository 的业务方法层，而非 `HttpClient` 层。`HttpClient` 只负责记录日志，不做业务拦截。

---

## 数据模型

### 现有数据模型（无需新增表）

`account_table` 已有所需字段：

| 字段          | 类型    | 说明                                                   |
| ------------- | ------- | ------------------------------------------------------ |
| `username`    | TEXT    | 账号唯一标识（米游社 account_id）                      |
| `cookie`      | TEXT    | 完整 cookie 字符串（含 stoken/ltoken/cookie_token 等） |
| `update_time` | INTEGER | Cookie 最后更新时间（Unix 秒），刷新成功后更新         |
| `nickname`    | TEXT    | 账号昵称，用于 Dialog 文案                             |

### 内存状态（CookieRefreshCoordinator）

```typescript
// 刷新锁：key=username，value=进行中的 Promise<string>
private refreshLocks: Map<string, Promise<string>> = new Map();

// 刷新时间戳：key=username，value=上次刷新完成的 Unix 秒
private lastRefreshTime: Map<string, number> = new Map();
```

**锁的生命周期**：

- 刷新开始时写入 `refreshLocks`
- 刷新完成（成功或失败）后从 `refreshLocks` 移除
- 账号删除时调用 `clearLock(username)` 清除两个 Map 中的条目

### Cookie 字段操作

复用 `BBSRepository` 中已有的静态方法：

```typescript
// 提取字段值
BBSRepository.extractCookieField(cookie: string, field: string): string

// 替换字段值（字段不存在时追加）
BBSRepository.replaceCookieField(cookie: string, field: string, newValue: string): string
```

---

## 正确性属性

_属性是在系统所有有效执行中都应成立的特征或行为——本质上是关于系统应该做什么的形式化陈述。属性作为人类可读规范与机器可验证正确性保证之间的桥梁。_

### 属性 1：冷启动刷新阈值判断

_对任意_ `updateTime`（Unix 秒）和 `now`（Unix 秒），当 `now - updateTime > 604800` 时，`needsColdStartRefresh(updateTime, now)` 应返回 `true`；否则返回 `false`。

**验证：需求 1.2、1.4、7.4**

### 属性 2：Cookie 字段提取 round-trip

_对任意_ cookie 字符串和字段名，先调用 `extractCookieField` 提取字段值，再调用 `replaceCookieField` 用相同值替换，再次调用 `extractCookieField` 提取，结果应与第一次提取的值相同。

**验证：需求 7.3**

### 属性 3：多账号刷新失败隔离

_对任意_ 账号列表（含随机数量的需要刷新账号），当某些账号刷新失败时，其他账号的刷新流程应继续执行，最终处理的账号总数等于需要刷新的账号总数。

**验证：需求 1.8、4.2、4.5**

### 属性 4：并发刷新去重（同一账号）

_对任意_ 账号，在 60 秒内并发发起多次 `refreshWithLock` 调用，实际向 `AuthRepository` 发起的网络请求次数应为 1，所有调用方均获得相同的新 cookie 结果。

**验证：需求 2.7、5.3**

### 属性 5：刷新后 cookie 持久化 round-trip

_对任意_ 新 cookie 字符串，调用 `refreshCookieIfNeeded` 成功后，从 `account_table` 读取该账号的 cookie 字段，结果应等于新 cookie 字符串。

**验证：需求 5.4**

### 属性 6：多账号失败通知数量一致性

_对任意_ N 个 stoken 过期的失败账号，`handleColdStartRefreshResult` 应触发恰好 N 次 Dialog 展示（每个账号一次，按顺序）。

**验证：需求 3.4、8.6**

---

## 错误处理

### 错误分类与处理策略

| 错误类型                          | 触发条件                                                    | 处理方式                                  | UI 呈现                        |
| --------------------------------- | ----------------------------------------------------------- | ----------------------------------------- | ------------------------------ |
| `AuthExpiredError`（无 stoken）   | cookie 中无 stoken 字段或为空                               | 直接抛出，不尝试刷新                      | Dialog：「登录已过期」         |
| `AuthExpiredError`（stoken 过期） | `getLTokenBySToken` 或 `getCookieBySToken` 返回非 0 retcode | 包装为 `AuthExpiredError` 抛出            | Dialog：「登录已过期」         |
| 网络错误                          | HTTP 超时、连接失败等                                       | 记录日志，静默忽略                        | 无（留给全局操作反馈 Spec）    |
| DB 写入失败                       | `accountDao.updateCookie` 抛出异常                          | 捕获并记录到 `ApiLogSystem`，不向上层抛出 | 无                             |
| 重试后仍失败（非 -100）           | 刷新成功但重试 API 返回其他错误                             | 将失败结果返回给调用方                    | 由调用方的业务错误处理逻辑处理 |
| 重试后仍返回 -100                 | 刷新成功但重试 API 仍返回 -100                              | 不再重试，抛出 `AuthExpiredError`         | Dialog：「登录已过期」         |

### 防无限重试

API 按需刷新只重试一次。重试后若仍返回 `retcode=-100`，直接抛出 `AuthExpiredError`，不再触发第二次刷新。

### 冷启动刷新的异常隔离

```typescript
// ColdStartCookieChecker.checkAndRefreshAll 内部
for (const account of accounts) {
  try {
    await bbsRepository.refreshCookieIfNeeded(account.username, account.cookie);
    result.successCount++;
  } catch (e) {
    // 单个账号失败不影响其他账号
    const isNetworkError = !(e instanceof AuthExpiredError);
    result.failedAccounts.push({
      username: account.username,
      nickname: account.nickname,
      isNetworkError
    });
    // 记录日志
    ApiLogSystem.getInstance().warning('ColdStartCookieChecker', ...);
  }
}
```

### App 后台时的失败处理

当 App 处于后台时触发的刷新失败（stoken 过期），`ColdStartCookieChecker` 将失败信息记录到内存（`pendingDialogs` 数组）。`HomeViewModel` 在 App 回到前台时（`onPageShow`）检查并展示 Dialog。

---

## 测试策略

### 单元测试（`core/src/test/`）

测试纯函数逻辑，不依赖设备：

**ColdStartCookieChecker.test.ets**

| 测试用例                    | 输入                        | 预期    |
| --------------------------- | --------------------------- | ------- |
| 超过 7 天返回 true          | `now - updateTime = 604801` | `true`  |
| 恰好 7 天返回 false         | `now - updateTime = 604800` | `false` |
| 不足 7 天返回 false         | `now - updateTime = 86400`  | `false` |
| updateTime=0 返回 true      | `updateTime=0, now=1000000` | `true`  |
| now < updateTime 返回 false | `now=100, updateTime=200`   | `false` |

**CookieFieldUtils.test.ets**（测试 `BBSRepository` 的静态方法）

| 测试用例                   | 输入                                   | 预期                |
| -------------------------- | -------------------------------------- | ------------------- |
| 提取存在的字段             | `'stoken=abc; ltoken=xyz'`, `'stoken'` | `'abc'`             |
| 提取不存在的字段           | `'ltoken=xyz'`, `'stoken'`             | `''`                |
| 提取空值字段               | `'stoken=; ltoken=xyz'`, `'stoken'`    | `''`                |
| 替换存在的字段             | `'ltoken=old'`, `'ltoken'`, `'new'`    | `'ltoken=new'`      |
| 替换不存在的字段（追加）   | `'ltoken=abc'`, `'stoken'`, `'xyz'`    | 包含 `'stoken=xyz'` |
| round-trip：提取→替换→提取 | 任意 cookie 和字段名                   | 两次提取结果相同    |

### 属性测试（`core/src/test/`）

使用 `@ohos/hypium` 配合手动生成随机输入，每个属性测试运行 100 次迭代：

**属性 1：冷启动阈值判断**

```typescript
// 生成随机时间差，验证阈值判断的正确性
// Feature: cookie-refresh-and-expiry, Property 1: 冷启动刷新阈值判断
for (let i = 0; i < 100; i++) {
  const diff = Math.floor(Math.random() * 2000000); // 0 ~ 23 天
  const now = 1700000000;
  const updateTime = now - diff;
  const result = ColdStartCookieChecker.needsColdStartRefresh(updateTime, now);
  expect(result).assertEqual(diff > 604800);
}
```

**属性 2：Cookie 字段 round-trip**

```typescript
// Feature: cookie-refresh-and-expiry, Property 2: Cookie 字段提取 round-trip
const fields = ["stoken", "ltoken", "cookie_token", "account_id", "mid"];
for (let i = 0; i < 100; i++) {
  const cookie = generateRandomCookie(); // 随机生成含各字段的 cookie 字符串
  const field = fields[Math.floor(Math.random() * fields.length)];
  const original = BBSRepository.extractCookieField(cookie, field);
  const replaced = BBSRepository.replaceCookieField(cookie, field, original);
  const extracted = BBSRepository.extractCookieField(replaced, field);
  expect(extracted).assertEqual(original);
}
```

### 设备端集成测试（`core/src/ohosTest/`）

**CookieRefreshCoordinator.test.ets**

| 测试用例         | 前置条件            | 操作                              | 预期                                        |
| ---------------- | ------------------- | --------------------------------- | ------------------------------------------- |
| 并发刷新去重     | mock AuthRepository | 同一账号并发 5 次 refreshWithLock | 网络请求只发出 1 次，5 个调用均获得相同结果 |
| 不同账号并行刷新 | mock AuthRepository | 账号 A 和账号 B 同时刷新          | 两个账号各自独立刷新，互不阻塞              |
| 账号删除后清除锁 | 已有刷新锁          | clearLock(username)               | 后续刷新重新发起网络请求                    |
| 60 秒内复用结果  | 已完成一次刷新      | 60 秒内再次调用                   | 不发起新网络请求，返回缓存结果              |
| 60 秒后重新刷新  | 已完成一次刷新      | 60 秒后再次调用                   | 发起新网络请求                              |

**ColdStartCookieChecker.test.ets（设备端）**

| 测试用例                  | 前置条件                                 | 操作                 | 预期                                           |
| ------------------------- | ---------------------------------------- | -------------------- | ---------------------------------------------- |
| 空账号列表                | DB 无账号                                | checkAndRefreshAll() | 返回 successCount=0，failedAccounts=[]         |
| 单账号刷新成功            | 1 个账号，update_time 超 7 天，有 stoken | checkAndRefreshAll() | successCount=1，DB 中 cookie 已更新            |
| 单账号无 stoken 跳过      | 1 个账号，无 stoken                      | checkAndRefreshAll() | successCount=0，failedAccounts=[]              |
| 多账号部分失败            | 3 个账号，1 个 stoken 过期               | checkAndRefreshAll() | 其他 2 个账号正常处理，failedAccounts.length=1 |
| update_time 未超 7 天跳过 | 1 个账号，update_time=now-86400          | checkAndRefreshAll() | successCount=0，不发起网络请求                 |

### ViewModel 单元测试（`entry/src/test/`）

在 `testing-entry-pages.md` 的 `HomeViewModel` 测试中补充：

| 测试用例                                | 前置条件                      | 操作                  | 预期                                        |
| --------------------------------------- | ----------------------------- | --------------------- | ------------------------------------------- |
| 初始 cookieExpiredDialogQueue 为空      | 新建实例                      | `new HomeViewModel()` | `cookieExpiredDialogQueue.length === 0`     |
| handleColdStartRefreshResult 无失败账号 | result.failedAccounts=[]      | 调用方法              | 不触发 Dialog                               |
| handleColdStartRefreshResult 有失败账号 | result.failedAccounts=[{...}] | 调用方法              | cookieExpiredDialogQueue 长度等于失败账号数 |

### UI 测试（`entry/src/ohosTest/`）

在 `HomePageTest.test.ets` 中补充：

| 测试用例                   | 前置条件             | 操作                   | 预期                           |
| -------------------------- | -------------------- | ---------------------- | ------------------------------ |
| 冷启动刷新失败弹 Dialog    | mock stoken 过期     | 启动应用，等待首屏渲染 | Dialog「登录已过期」可见       |
| Dialog「去登录」跳转登录页 | Dialog 已弹出        | 点击「去登录」         | 跳转到 Login 页                |
| Dialog「取消」关闭 Dialog  | Dialog 已弹出        | 点击「取消」           | Dialog 关闭，停留当前页        |
| 多账号过期逐一弹 Dialog    | 2 个账号 stoken 过期 | 处理第一个 Dialog      | 第一个 Dialog 关闭后弹出第二个 |

---

## 手动测试指南

> 本功能涉及「Cookie 过期」场景，真实过期需要等 30 天，因此所有手动测试均通过以下方式模拟：
>
> - **修改 DB** 中的 `update_time` 或 `cookie` 字段来模拟过期状态
> - **修改 mock 文件** 让接口返回 `retcode=-100` 来模拟 API 按需刷新

### 前置准备

确保 mock App 已安装并运行过一次（有账号数据）。

在终端执行以下命令前，先定义变量：

```bash
HDC='/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc'
DB_PATH='/data/app/el2/100/base/com.cainluo.miyoyo.tools.mock/haps/entry/databases/mihoyo_tool_v2.db'
```

或者直接进入模拟器 shell 操作（更简单）：

```bash
/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc -t 127.0.0.1:5555 shell
# 进入后直接用 sqlite3 命令，无需 hdc 前缀
```

---

### 场景 T1：冷启动 7 天检查 — 正常刷新（有 stoken）

**目的**：验证 update_time 超过 7 天且有 stoken 时，冷启动静默刷新，无任何 UI 提示。

**步骤**：

1. 把 `update_time` 改成 8 天前：

   ```bash
   "$HDC" -t 127.0.0.1:5555 shell \
     "sqlite3 $DB_PATH \"UPDATE account_table SET update_time = strftime('%s','now') - 691200;\""
   ```

2. 确认账号 cookie 里包含 `stoken`（mock 登录后默认有）：

   ```bash
   "$HDC" -t 127.0.0.1:5555 shell \
     "sqlite3 $DB_PATH \"SELECT username, substr(cookie, 1, 80) FROM account_table;\""
   ```

3. 重启 App：`bash run-mock.sh`

**预期结果**：

- 首屏正常渲染，无任何 Dialog 或通知
- 查看 DB，`update_time` 已更新为当前时间戳：
  ```bash
  "$HDC" -t 127.0.0.1:5555 shell \
    "sqlite3 $DB_PATH \"SELECT username, update_time, strftime('%s','now') FROM account_table;\""
  ```

---

### 场景 T2：冷启动 7 天检查 — stoken 过期，弹 Dialog

**目的**：验证 update_time 超过 7 天但 stoken 已过期时，弹出「登录已过期」Dialog。

**步骤**：

1. 把 `update_time` 改成 8 天前，同时把 `stoken` 改成无效值：

   ```bash
   "$HDC" -t 127.0.0.1:5555 shell \
     "sqlite3 $DB_PATH \"UPDATE account_table SET update_time = strftime('%s','now') - 691200, cookie = replace(cookie, substr(cookie, instr(cookie, 'stoken='), instr(substr(cookie, instr(cookie, 'stoken=')), ';')), 'stoken=invalid_token');\""
   ```

2. 重启 App：`bash run-mock.sh`

**预期结果**：

- 首屏渲染完成后弹出 Dialog
- Dialog 标题：「登录已过期」
- Dialog 内容包含账号昵称
- 有「取消」和「去登录」两个按钮

---

### 场景 T3：冷启动 7 天检查 — 无 stoken，跳过刷新

**目的**：验证 update_time 超过 7 天但 cookie 里没有 stoken 时，静默跳过，无任何提示。

**步骤**：

1. 把 `update_time` 改成 8 天前，同时清空 stoken：

   ```bash
   # 先查看当前 cookie 内容
   "$HDC" -t 127.0.0.1:5555 shell \
     "sqlite3 $DB_PATH \"SELECT cookie FROM account_table LIMIT 1;\""

   # 把 update_time 改成 8 天前（不修改 cookie，确保 cookie 里没有 stoken 字段）
   # 如果 cookie 里有 stoken，手动编辑去掉 stoken 部分
   "$HDC" -t 127.0.0.1:5555 shell \
     "sqlite3 $DB_PATH \"UPDATE account_table SET update_time = strftime('%s','now') - 691200, cookie = 'account_id=123; cookie_token=abc; ltoken=xyz; ltuid=123';\""
   ```

2. 重启 App：`bash run-mock.sh`

**预期结果**：

- 首屏正常渲染，无任何 Dialog 或通知
- DB 中 `update_time` 未变化（没有触发刷新）

---

### 场景 T4：冷启动 7 天检查 — update_time 未超 7 天，跳过

**目的**：验证 update_time 在 7 天内时不触发刷新。

**步骤**：

1. 把 `update_time` 改成 1 天前：

   ```bash
   "$HDC" -t 127.0.0.1:5555 shell \
     "sqlite3 $DB_PATH \"UPDATE account_table SET update_time = strftime('%s','now') - 86400;\""
   ```

2. 重启 App：`bash run-mock.sh`

**预期结果**：

- 首屏正常渲染，无任何 Dialog 或通知
- DB 中 `update_time` 未变化

---

### 场景 T5：API 按需刷新 — retcode=-100，有 stoken，刷新成功后重试

**目的**：验证 API 返回 -100 时，有 stoken 则自动刷新并重试，用户无感知。

**步骤**：

1. 修改某个 mock 文件，让它第一次返回 -100，第二次返回正常数据。

   由于 mock 文件是静态的，最简单的方式是：**临时把 mock 文件改成返回 -100**，然后观察 App 行为，再改回正常。

   ```bash
   # 找到原神便笺的 mock 文件
   # 路径：core/src/main/resources/rawfile/mock/1/<roleId>/game_record_app_genshin_api_dailyNote.json

   # 备份原文件
   cp game_record_app_genshin_api_dailyNote.json game_record_app_genshin_api_dailyNote.json.bak

   # 改成返回 -100
   echo '{"retcode":-100,"message":"登录失效，请重新登录","data":null}' > game_record_app_genshin_api_dailyNote.json
   ```

2. 重新打包安装：`bash run-mock.sh`

3. 进入原神便笺详情页，触发数据加载

**预期结果**（刷新成功场景）：

- 如果 mock 的 `getLTokenBySToken` 接口返回正常，刷新成功后重试，页面正常显示数据
- 无任何 Dialog

**注意**：在 mock 环境下，`getLTokenBySToken` 也是 mock 的，需要确保对应的 mock 文件返回正常数据。

---

### 场景 T6：API 按需刷新 — retcode=-100，无 stoken，直接弹 Dialog

**目的**：验证 API 返回 -100 且 cookie 里没有 stoken 时，直接弹 Dialog。

**步骤**：

1. 把账号 cookie 改成不含 stoken 的版本：

   ```bash
   "$HDC" -t 127.0.0.1:5555 shell \
     "sqlite3 $DB_PATH \"UPDATE account_table SET cookie = 'account_id=123; cookie_token=abc; ltoken=xyz; ltuid=123';\""
   ```

2. 修改 mock 文件返回 -100（同场景 T5 步骤 1）

3. 重新打包安装：`bash run-mock.sh`

4. 进入原神便笺详情页

**预期结果**：

- 弹出 Dialog「登录已过期」
- 有「取消」和「去登录」两个按钮
- 点击「去登录」跳转到登录页
- 点击「取消」关闭 Dialog，停留当前页

---

### 场景 T7：Dialog 交互验证

**目的**：验证 Dialog 的两个按钮行为正确。

在 T2 或 T6 触发 Dialog 后：

| 操作           | 预期结果                                                  |
| -------------- | --------------------------------------------------------- |
| 点击「取消」   | Dialog 关闭，停留当前页，App 继续正常使用                 |
| 点击「去登录」 | 跳转到登录页，可选择手机号/二维码/Cookie 粘贴任意方式登录 |
| 登录成功后     | 返回首页，账号 Cookie 已更新，数据正常加载                |

---

### 场景 T8：多账号过期，逐一弹 Dialog

**目的**：验证多个账号过期时，按顺序逐一弹 Dialog。

**步骤**：

1. 确保 DB 里有 2 个以上账号（需要登录多个账号）

2. 把所有账号的 `update_time` 改成 8 天前，stoken 改成无效值：

   ```bash
   "$HDC" -t 127.0.0.1:5555 shell \
     "sqlite3 $DB_PATH \"UPDATE account_table SET update_time = strftime('%s','now') - 691200, cookie = replace(cookie, substr(cookie, instr(cookie, 'stoken='), instr(substr(cookie, instr(cookie, 'stoken=')), ';')), 'stoken=invalid');\""
   ```

3. 重启 App：`bash run-mock.sh`

**预期结果**：

- 首屏渲染完成后弹出第一个账号的 Dialog
- 点击「取消」或「去登录」处理后，弹出第二个账号的 Dialog
- 每个 Dialog 内容包含对应账号的昵称

---

### 快速验证技巧

如果只想快速验证 Dialog UI 是否正确，不想操作 DB，可以在实现时临时把 `COLD_START_REFRESH_THRESHOLD_SECONDS` 改成 `0`：

```typescript
// ColdStartCookieChecker.ets — 临时改成 0，任何账号都触发检查
const COLD_START_REFRESH_THRESHOLD_SECONDS = 0; // 正式值为 604800
```

重新打包后，任何账号都会触发冷启动检查，可以快速验证 Dialog 流程。**测试完记得改回 604800。**
