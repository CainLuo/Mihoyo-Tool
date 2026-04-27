# 需求文档：Cookie 自动刷新与过期处理

## 简介

本功能为米游社工具类 HarmonyOS NEXT App 提供完整的 Cookie 生命周期管理能力。

米游社 API 使用 Cookie 作为身份凭证，其中 `ltoken` 和 `cookie_token` 会定期过期（约 30 天），而 `stoken` 有效期更长（约 1 年）。

**三种登录方式与 stoken 的关系：**

| 登录方式        | cookie 字段中是否包含 stoken | 说明                                                                                                      |
| --------------- | ---------------------------- | --------------------------------------------------------------------------------------------------------- |
| 手机号登录      | **一定有**                   | 登录流程中通过 `loginByMobileCaptcha` 获取 stoken，再换取 ltoken/cookie_token，最终拼入 cookie 字符串存储 |
| 二维码登录      | **一定有**                   | 登录流程中通过 `getTokenByGameToken` 获取 stoken，再换取 ltoken/cookie_token，最终拼入 cookie 字符串存储  |
| Cookie 粘贴登录 | **不确定**                   | 取决于用户粘贴的内容：从浏览器复制的 Cookie 通常不含 stoken；从米游社 App 抓包的 Cookie 可能含 stoken     |

**刷新能力取决于 stoken 是否存在，而非登录方式本身。** 系统在运行时只检查 cookie 字符串中是否包含非空的 `stoken` 字段，不区分账号的登录方式。

本功能覆盖两条刷新路径：

1. **冷启动定期检查**：App 启动时检查 `account_table.update_time`，超过 7 天则主动刷新（参考 TeyvatGuide 做法）。
2. **API 按需刷新**：任意 API 返回 `retcode=-100` 时，尝试用 `stoken` 刷新后自动重试。

---

## 词汇表

- **Cookie_Refresh_Service**：负责 Cookie 刷新逻辑的核心服务层组件（在 `BBSRepository` 中实现）
- **ColdStart_Checker**：冷启动时执行定期检查的组件（在 `CoreInitializer` 或 `HomeViewModel` 中触发）
- **API_Interceptor**：拦截 API 响应、检测 `retcode=-100` 并触发刷新的机制
- **Notification_Manager**：向用户展示登录过期 Dialog 的 UI 层组件（使用 `promptAction.showDialog`）
- **stoken**：米游社长效令牌，有效期约 1 年。手机号/二维码登录后**一定存在**于 cookie 字符串中（由登录流程主动换取并拼入）；Cookie 粘贴登录的用户**不一定有**（取决于粘贴内容）。可用于换取新的 `ltoken` 和 `cookie_token`
- **ltoken**：米游社短效访问令牌，约 30 天过期
- **cookie_token**：米游社短效 Cookie 令牌，约 30 天过期
- **update_time**：`account_table` 中记录 Cookie 最后更新时间的字段（Unix 秒）
- **retcode=-100**：米游社 API 返回的 Cookie 失效错误码，对应 `ApiErrorCodes.AUTH_EXPIRED`
- **AuthExpiredError**：`core/src/main/ets/errors/ApiErrors.ets` 中定义的 Cookie 失效错误类型
- **多账号**：App 支持同时登录多个米游社账号，每个账号独立管理 Cookie

---

## 需求列表

### 需求 1：冷启动定期 Cookie 检查

**用户故事：** 作为一名已登录用户（无论通过手机号、二维码还是 Cookie 粘贴方式登录），我希望 App 在冷启动时自动检查并刷新即将过期的 Cookie（前提是 cookie 中包含 stoken），以便我无需手动重新登录即可持续使用所有功能。

#### 验收标准

1. WHEN App 冷启动完成初始化，THE ColdStart_Checker SHALL 遍历 `account_table` 中的所有账号，检查每个账号的 `update_time` 字段。

2. WHEN 某账号的 `update_time` 距当前时间超过 7 天（604800 秒），且该账号 Cookie 中包含有效的 `stoken` 字段，THE Cookie_Refresh_Service SHALL 调用 `refreshCookieIfNeeded(username, cookie)` 对该账号执行静默刷新。

3. WHEN 某账号的 `update_time` 距当前时间超过 7 天，且该账号 Cookie 中不包含 `stoken` 字段或 `stoken` 为空字符串，THE ColdStart_Checker SHALL 跳过该账号，不执行刷新，不产生任何通知。

4. WHEN 某账号的 `update_time` 距当前时间不超过 7 天，THE ColdStart_Checker SHALL 跳过该账号，不执行刷新。

5. WHEN 冷启动检查中某账号刷新成功，THE Cookie_Refresh_Service SHALL 将新 Cookie 写入 `account_table`，并将 `update_time` 更新为当前时间戳。

6. WHEN 冷启动检查中所有需要刷新的账号均刷新成功，THE Notification_Manager SHALL 通过 `HdsSnackBar` 显示一条静默成功通知，通知内容包含刷新成功的账号数量。

7. WHEN 冷启动检查中某账号刷新失败（`stoken` 已过期或网络错误），THE Notification_Manager SHALL 通过 `HdsSnackBar` 显示一条警告通知，提示用户该账号需要重新登录，通知内容包含账号昵称或 username。

8. WHEN 冷启动检查中存在多个账号需要刷新，THE ColdStart_Checker SHALL 按账号顺序逐一执行刷新，单个账号刷新失败不影响其他账号的刷新流程。

9. WHEN `account_table` 中没有任何账号，THE ColdStart_Checker SHALL 跳过检查，不执行任何操作。

10. WHEN 冷启动检查正在进行中，THE ColdStart_Checker SHALL 在后台异步执行，不阻塞 UI 渲染和用户交互。

---

### 需求 2：API 返回 -100 时按需刷新

**用户故事：** 作为一名已登录用户，我希望当 API 因 Cookie 过期返回错误时，App 能自动刷新 Cookie 并重试请求，以便我不会因为 Cookie 过期而看到错误提示。

#### 验收标准

1. WHEN 任意米游社 API 调用返回 `retcode=-100`（对应 `AuthExpiredError`），且当前账号 Cookie 中包含有效的 `stoken`，THE API_Interceptor SHALL 调用 `Cookie_Refresh_Service` 刷新该账号的 Cookie。

2. WHEN Cookie 刷新成功，THE API_Interceptor SHALL 使用新 Cookie 自动重试原始 API 请求一次。

3. WHEN 重试后 API 请求成功，THE API_Interceptor SHALL 将成功结果返回给调用方，不向用户展示任何错误提示。

4. WHEN 任意米游社 API 调用返回 `retcode=-100`，且当前账号 Cookie 中不包含 `stoken` 或 `stoken` 为空字符串，THE API_Interceptor SHALL 不执行刷新，直接抛出 `AuthExpiredError`，由上层 ViewModel 处理。

5. WHEN Cookie 刷新成功但重试后 API 请求仍然失败（非 -100 错误），THE API_Interceptor SHALL 将该失败结果返回给调用方，不再重试。

6. WHEN Cookie 刷新本身失败（`stoken` 已过期），THE API_Interceptor SHALL 抛出 `AuthExpiredError`，由上层 ViewModel 处理。

7. WHEN 同一账号在短时间内（60 秒内）已触发过一次 Cookie 刷新，THE API_Interceptor SHALL 等待第一次刷新完成后复用其结果，不重复发起刷新请求（防止并发刷新）。

---

### 需求 3：刷新失败后的用户通知与重新登录引导

**用户故事：** 作为一名 Cookie 已完全过期的用户（包括 stoken 也过期的手机号/二维码登录用户，以及 cookie 中本就没有 stoken 的 Cookie 粘贴登录用户），我希望 App 能明确告知我需要重新登录，并提供便捷的跳转入口，以便我能快速恢复账号功能。

#### 验收标准

1. WHEN Cookie 刷新失败（无论是冷启动检查还是 API 按需刷新），且失败原因为 `stoken` 过期或不存在，THE Notification_Manager SHALL 向用户展示一条包含账号昵称（或 username）的错误通知，通知文案为「[账号昵称] Cookie 已过期，请重新登录」。

2. WHEN 用户点击上述错误通知，THE Notification_Manager SHALL 导航至登录页（`AppRoutes.LOGIN`）。

3. WHEN Cookie 刷新失败原因为网络错误（非 `stoken` 过期），THE Notification_Manager SHALL 向用户展示一条网络错误通知，通知文案为「Cookie 刷新失败，请检查网络连接」，不跳转登录页。

4. WHEN 多账号场景下多个账号均刷新失败，THE Notification_Manager SHALL 为每个失败账号分别展示独立的错误通知，通知中包含对应账号的昵称或 username。

5. WHEN API 按需刷新失败后，THE Notification_Manager SHALL 在当前页面通过 `HdsSnackBar` 展示错误通知，不强制跳转登录页（用户可自行决定是否前往登录页）。

6. WHEN 冷启动刷新失败后，THE Notification_Manager SHALL 在首页（Home Tab）加载完成后通过 `HdsSnackBar` 展示错误通知。

---

### 需求 4：多账号场景下的独立 Cookie 管理

**用户故事：** 作为一名同时登录了多个米游社账号的用户，我希望每个账号的 Cookie 刷新和过期处理相互独立，以便单个账号的 Cookie 问题不影响其他账号的正常使用。

#### 验收标准

1. THE Cookie_Refresh_Service SHALL 按账号 `username` 独立管理每个账号的 Cookie 刷新状态，不同账号的刷新操作互不影响。

2. WHEN 账号 A 的 Cookie 刷新失败，THE Cookie_Refresh_Service SHALL 继续处理账号 B 的 Cookie 刷新，不因账号 A 的失败而中断整体流程。

3. WHEN 多个账号同时触发 API 按需刷新，THE API_Interceptor SHALL 为每个账号独立维护刷新锁（以 `username` 为键），防止同一账号并发刷新，同时允许不同账号并行刷新。

4. WHEN 某账号被删除（`deleteAccount`），THE Cookie_Refresh_Service SHALL 清除该账号的刷新锁和刷新状态，不再对已删除账号执行任何刷新操作。

5. WHEN 冷启动检查遍历多个账号时，THE ColdStart_Checker SHALL 对每个账号独立判断是否需要刷新，不因某账号无 `stoken` 而跳过其他账号的检查。

---

### 需求 5：Cookie 刷新状态的持久化与幂等性

**用户故事：** 作为一名用户，我希望 Cookie 刷新操作是可靠的，即使 App 在刷新过程中被强制关闭，重启后也不会出现数据不一致的问题。

#### 验收标准

1. WHEN Cookie 刷新成功，THE Cookie_Refresh_Service SHALL 在同一数据库事务中同时更新 `account_table` 的 `cookie` 字段和 `update_time` 字段，确保两个字段的更新原子性。

2. WHEN Cookie 刷新过程中 App 被强制关闭，THE Cookie_Refresh_Service SHALL 在下次冷启动时重新检查 `update_time`，若仍超过 7 天则重新执行刷新，不产生数据不一致。

3. WHEN 对同一账号在 60 秒内重复调用 `refreshCookieIfNeeded`，THE Cookie_Refresh_Service SHALL 返回第一次刷新的结果，不重复发起网络请求（幂等保护）。

4. WHEN Cookie 刷新成功后，THE Cookie_Refresh_Service SHALL 确保后续所有使用该账号 Cookie 的 API 调用均使用新 Cookie，不使用旧 Cookie。

---

### 需求 6：冷启动刷新的时机与顺序控制

**用户故事：** 作为一名用户，我希望冷启动时的 Cookie 刷新不影响 App 的启动速度和首屏渲染，以便 App 能快速展示内容。

#### 验收标准

1. WHEN App 冷启动，THE ColdStart_Checker SHALL 在 `CoreInitializer.initCore()` 完成且 UI 首屏渲染完成后，才开始执行 Cookie 检查，不阻塞启动流程。

2. WHEN 冷启动 Cookie 刷新正在进行中，THE ColdStart_Checker SHALL 不阻塞 `HomeViewModel.loadData()` 的执行，两者并行运行。

3. WHEN 冷启动 Cookie 刷新完成（无论成功或失败），THE ColdStart_Checker SHALL 通过回调或信号通知 `HomeViewModel`，以便 `HomeViewModel` 在必要时重新加载数据。

4. WHEN 冷启动 Cookie 刷新成功后，THE HomeViewModel SHALL 重新触发一次数据同步（`syncIfNeeded`），以便使用新 Cookie 获取最新数据。

5. WHILE 冷启动 Cookie 刷新正在进行中，THE ColdStart_Checker SHALL 在 UI 层不展示任何加载指示器，保持首屏体验流畅。

---

### 需求 7：Cookie 刷新的可测试性设计

**用户故事：** 作为一名开发者，我希望 Cookie 刷新逻辑有完整的单元测试覆盖，以便在不依赖真实网络的情况下验证各种场景的正确性。

#### 验收标准

1. THE Cookie_Refresh_Service SHALL 通过依赖注入接受 `AuthRepository` 的 mock 实现，以便在单元测试中模拟 `stoken` 刷新成功、失败等场景。

2. THE ColdStart_Checker SHALL 通过依赖注入接受当前时间戳参数，以便在单元测试中模拟不同的时间差场景（如恰好 7 天、超过 7 天、不足 7 天）。

3. FOR ALL 账号 Cookie 字符串，THE Cookie_Refresh_Service.extractCookieField 方法 SHALL 正确提取指定字段的值，且对同一 Cookie 字符串先提取再重新组装后再提取，结果与原始提取结果相同（round-trip 属性）。

4. THE Cookie_Refresh_Service SHALL 提供 `needsColdStartRefresh(updateTime: number, now: number): boolean` 纯函数，以便在本地单元测试中验证 7 天阈值判断逻辑，无需依赖设备或数据库。

---

### 需求 8：UI 呈现规范

**用户故事：** 作为一名用户，我希望 App 在 Cookie 过期时能明确告知我并提供操作选项，以便我能快速决定是否重新登录。

#### 8.1 通知组件规范

Cookie 过期场景使用 `promptAction.showDialog`（`@kit.ArkUI`）进行强提示，要求用户主动决策。

> 刷新成功、网络错误等轻量反馈留待「全局操作反馈」Spec 统一处理，本 Spec 不涉及 `HdsSnackBar`。

Dialog 内容规范：

- 标题：「登录已过期」
- 内容：「[账号昵称] 的登录凭证已过期，请重新登录以继续使用」
- 左按钮：「取消」（关闭 Dialog，用户继续浏览已缓存数据）
- 右按钮：「去登录」（跳转登录页）

#### 8.2 冷启动刷新的 UI 呈现

| 场景                                        | UI 呈现                                     | 出现时机                | 用户操作                                          |
| ------------------------------------------- | ------------------------------------------- | ----------------------- | ------------------------------------------------- |
| 所有账号均无需刷新（update_time 未超 7 天） | 无任何通知                                  | —                       | —                                                 |
| 所有账号均无 stoken，跳过刷新               | 无任何通知                                  | —                       | —                                                 |
| 账号刷新成功                                | 无任何通知（留给全局操作反馈 Spec）         | —                       | —                                                 |
| 某账号刷新失败（stoken 过期或不存在）       | Dialog：「登录已过期」，「取消」/「去登录」 | Home Tab 首屏渲染完成后 | 点击「去登录」跳转登录页；点击「取消」关闭 Dialog |
| 某账号刷新失败（网络错误）                  | 无任何通知（留给全局操作反馈 Spec）         | —                       | —                                                 |
| 多账号混合（部分成功、部分失败）            | 仅对过期账号逐一弹出 Dialog                 | Home Tab 首屏渲染完成后 | 同上                                              |

> 冷启动刷新**不展示任何加载指示器**，完全在后台静默执行，不阻塞首屏渲染。

#### 8.3 API 按需刷新（retcode=-100）的 UI 呈现

| 场景                                            | UI 呈现                                     | 出现时机 | 用户操作                                          |
| ----------------------------------------------- | ------------------------------------------- | -------- | ------------------------------------------------- |
| 有 stoken，刷新中                               | 无任何通知（后台静默重试）                  | —        | —                                                 |
| 有 stoken，刷新成功，重试成功                   | 无任何通知（用户无感知）                    | —        | —                                                 |
| 有 stoken，刷新成功，重试仍失败（非 -100 错误） | 当前页面正常展示该 API 的业务错误           | 当前页面 | 用户可手动重试                                    |
| 有 stoken，刷新失败（stoken 过期）              | Dialog：「登录已过期」，「取消」/「去登录」 | 当前页面 | 点击「去登录」跳转登录页；点击「取消」关闭 Dialog |
| 无 stoken，直接失败                             | Dialog：「登录已过期」，「取消」/「去登录」 | 当前页面 | 点击「去登录」跳转登录页；点击「取消」关闭 Dialog |
| 网络错误导致刷新失败                            | 无任何通知（留给全局操作反馈 Spec）         | —        | —                                                 |

#### 8.4 Dialog 文案规范

所有文案需添加到多语言资源文件（`base/element/string.json`、`zh_HK/element/string.json`、`en/element/string.json`）：

| 资源 key                      | 简体中文文案                                | 说明                            |
| ----------------------------- | ------------------------------------------- | ------------------------------- |
| `cookie_expired_dialog_title` | `登录已过期`                                | Dialog 标题                     |
| `cookie_expired_dialog_msg`   | `%s 的登录凭证已过期，请重新登录以继续使用` | Dialog 内容，%s 为账号昵称      |
| `cookie_expired_go_login`     | `去登录`                                    | Dialog 确认按钮                 |
| `dialog_cancel`               | `取消`                                      | Dialog 取消按钮（复用已有 key） |

#### 8.5 Dialog「去登录」按钮行为

- 点击后导航至登录页（`AppRoutes.LOGIN`）
- 登录页不预填任何账号信息，用户可选择任意登录方式（手机号/二维码/Cookie 粘贴）
- 登录成功后，新账号覆盖原账号的 Cookie，不创建新账号（通过 `upsertOrUpdateAccount` 实现）

#### 8.6 多账号过期时的 Dialog 顺序

- 多个账号均过期时，按账号在 `account_table` 中的顺序逐一弹出 Dialog
- 用户处理完当前账号的 Dialog（点击「去登录」或「取消」）后，才弹出下一个账号的 Dialog

---

### 需求 9：错误处理与降级策略

**用户故事：** 作为一名用户，我希望即使 Cookie 刷新功能出现异常，App 的其他功能也能正常使用，以便单一功能的故障不影响整体体验。

#### 验收标准

1. IF Cookie 刷新过程中发生未预期的异常（如 JSON 解析错误、DB 写入失败），THEN THE Cookie_Refresh_Service SHALL 捕获异常并记录到 `ApiLogSystem`，不向上层抛出未处理的异常。

2. IF 冷启动检查过程中某账号的 Cookie 字段为空字符串，THEN THE ColdStart_Checker SHALL 跳过该账号，不执行刷新，不产生错误通知。

3. IF API 按需刷新重试后仍返回 `retcode=-100`，THEN THE API_Interceptor SHALL 不再重试，直接抛出 `AuthExpiredError`，避免无限重试循环。

4. IF 网络不可用时触发 Cookie 刷新，THEN THE Cookie_Refresh_Service SHALL 在超时后（30 秒）放弃刷新，记录日志，不展示任何通知（网络错误反馈留给全局操作反馈 Spec 统一处理）。

5. WHILE App 处于后台时触发的 Cookie 刷新失败（登录过期），THE Cookie_Refresh_Service SHALL 将失败状态记录到内存，待 App 回到前台时通过 `Notification_Manager` 弹出登录过期 Dialog。
