# Cookie 与认证机制

## 一、Cookie 字段说明

| 字段           | 来源                      | 用途                         | 有效期     |
| -------------- | ------------------------- | ---------------------------- | ---------- |
| `account_id`   | 登录返回                  | 账号唯一标识                 | 长期有效   |
| `ltoken`       | stoken 换取               | game_record 接口认证         | ~30 天     |
| `ltuid`        | 登录返回（同 account_id） | 账号标识                     | 长期有效   |
| `cookie_token` | stoken 换取               | 部分接口认证                 | ~30 天     |
| `stoken`       | 登录直接返回              | 用于刷新 ltoken/cookie_token | 24-48 小时 |
| `stuid`        | 登录返回（同 account_id） | 与 stoken 配合使用           | 长期有效   |
| `mid`          | 登录返回                  | 用户标识                     | 长期有效   |

---

## 二、stoken_v1 vs stoken_v2

### stoken_v1（旧版）

- 格式：普通字符串，无特定前缀
- 来源：`loginByMobileCaptcha` 接口（手机号登录）
- 限制：**不能用于 Widget API**

### stoken_v2（新版）

- 格式：`v2_` 开头的字符串
- 来源：
  - `getMultiTokenByLoginTicket` 接口（WebView 登录方式）
  - `getTokenByGameToken` 接口（二维码登录确认后）
- 用途：**Widget API 必须使用 stoken_v2**

### 判断方式

```swift
// PizzaHelperUnited 的判断逻辑
if cookie.contains("stoken=v2_") {
    // 可以使用 Widget API
} else {
    throw MiHoYoAPIError.sTokenV2InvalidOrMissing
}
```

---

## 三、登录方式对比

### 方式 1：WebView 登录（推荐）

1. 打开米游社 WebView 登录页
2. 用户完成登录后，从 Cookie 中提取 `login_ticket` 和 `login_uid`
3. 调用 `getMultiTokenByLoginTicket` → 直接获得 **stoken_v2** + ltoken
4. 调用 `getCookieAccountInfoBySToken` → 获得 cookie_token
5. 组装完整 Cookie

**优点**：直接获得 stoken_v2，Widget API 可用

### 方式 2：手机号登录

1. 发送短信验证码（`createLoginCaptcha`）
2. 提交验证码（`loginByMobileCaptcha`）→ 获得 **stoken_v1** + aid + mid
3. 调用 `getLTokenBySToken` → 获得 ltoken
4. 调用 `getCookieAccountInfoBySToken` → 获得 cookie_token
5. 组装完整 Cookie

**缺点**：获得的是 stoken_v1，Widget API 不可用

> **本项目问题**：手机号登录后 Widget 降级会失败，因为 stoken_v1 不被 Widget API 接受。
> **解决方案**：手机号登录后，额外调用 `getTokenByGameToken` 或其他接口升级为 stoken_v2。

### 方式 3：二维码登录

1. 调用 `fetchQRCode` → 获得二维码 URL（含 ticket）
2. 轮询 `queryQRCode` → 等待用户扫码确认
3. 确认后调用 `getTokenByGameToken` → 直接获得 **stoken_v2**
4. 调用 `getLTokenBySToken` → 获得 ltoken
5. 调用 `getCookieAccountInfoBySToken` → 获得 cookie_token
6. 组装完整 Cookie

**优点**：直接获得 stoken_v2，Widget API 可用

### 方式 4：手动输入 Cookie

- 用户从浏览器复制完整 Cookie 字符串
- 通常包含 `ltoken_v2`（新版 ltoken）和 `cookie_token_v2`
- 无需额外处理，直接存储使用

---

## 四、Widget Cookie 格式

Widget API 需要特殊格式的 Cookie：

```
stuid={uid};stoken=v2_{token};mid={mid}
```

**构造逻辑**（来自 `BBSRepository.buildWidgetCookie`）：

1. 从完整 Cookie 中提取 `stoken`（必须是 `v2_` 开头）
2. 提取 `stuid`（优先级：stuid > account_id > ltuid_v2 > ltuid）
3. 提取 `mid`（优先级：mid > account_mid_v2 > ltmid_v2）
4. 拼接为 `stuid=xxx;stoken=v2_xxx;mid=xxx`

---

## 五、Widget API 降级机制

当 game_record 接口返回 1034（Geetest 验证）时：

```
1034 触发
  ↓
检查 Cookie 是否含 stoken=v2_
  ├─ 是 → 构造 Widget Cookie → 调用 Widget API → 成功
  └─ 否 → 抛出 sTokenV2InvalidOrMissing 错误
              ↓
         触发 Geetest 验证流程（展示验证码 UI）
```

**Widget API 的限制**：

- 返回数据是完整便笺的子集（部分字段缺失）
- 仅支持国服（米游社）
- 需要 stoken_v2

---

## 六、Cookie 刷新机制

当接口返回 `-100` / `10001` / `-10001`（Cookie 失效）时：

```
Cookie 失效
  ↓
检查 Cookie 是否含 stoken
  ├─ 有 stoken → 调用 getLTokenBySToken 刷新 ltoken
  │              调用 getCookieAccountInfoBySToken 刷新 cookie_token
  │              更新 DB 中的 Cookie
  │              重试原始请求
  └─ 无 stoken → 抛出 AuthExpiredError
                  ↓
             提示用户重新登录
```

**刷新并发控制**（`CookieRefreshCoordinator`）：

- 同一账号 60 秒内只发起一次刷新请求
- 并发调用时复用同一个 Promise，避免重复刷新
