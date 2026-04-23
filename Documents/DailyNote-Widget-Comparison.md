# dailyNote / Widget 接口对比：本项目 vs PizzaHelperUnited

> 仅针对便笺（dailyNote）和 Widget 便笺两个接口，逐字段对比代码实现。
> 来源文件已全部读取，无猜测。

---

## 一、普通便笺接口（fullNote）

### 1.1 请求头对比

| 字段                 | 本项目（修复后）                                                                       | PizzaHelperUnited                                               |
| -------------------- | -------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `User-Agent`         | `Mozilla/5.0 (iPhone; CPU iPhone OS 16_3_1 ...) miHoYoBBS/2.104.0`                     | `Mozilla/5.0 (iPhone; CPU iPhone OS 17_6 ...) miHoYoBBS/2.40.1` |
| `x-rpc-app_version`  | `2.104.0`                                                                              | `2.40.1`                                                        |
| `x-rpc-client_type`  | `5`（CLIENT_WEB）                                                                      | `5`                                                             |
| `x-rpc-device_id`    | UUID，持久化                                                                           | 设备 Vendor UUID                                                |
| `x-rpc-device_fp`    | 真实指纹（DeviceFpService）                                                            | 真实指纹（profile.deviceFingerPrint）                           |
| `x-rpc-language`     | `zh-cn`                                                                                | 当前系统语言（原神/绝区零），星铁固定 `zh-cn`                   |
| `x-rpc-page`         | 原神：`v6.4.2-gr-cn_#/ys`<br>星铁：`v4.1.1_#/rpg`<br>绝区零：`v2.7.1_#/zzz/daily-note` | 固定 `3.1.3_#/rpg`（所有游戏统一）                              |
| `x-rpc-tool_verison` | 原神：`v6.4.2-gr-cn`<br>星铁：`v4.1.1`                                                 | **无此字段**                                                    |
| `x-rpc-sys_version`  | `16.3.1`                                                                               | **无此字段**                                                    |
| `Referer`            | `https://webstatic.mihoyo.com/`                                                        | `https://webstatic.mihoyo.com`                                  |
| `Origin`             | `https://webstatic.mihoyo.com`                                                         | `https://webstatic.mihoyo.com`                                  |
| `X-Requested-With`   | **无此字段**                                                                           | `com.mihoyo.hyperion`                                           |
| `Accept-Encoding`    | **无此字段**                                                                           | `gzip, deflate, br`                                             |
| `Accept-Language`    | **无此字段**                                                                           | `zh-CN,zh-Hans;q=0.9`                                           |
| `Connection`         | **无此字段**                                                                           | `keep-alive`                                                    |
| `Sec-Fetch-Dest`     | **无此字段**                                                                           | `empty`                                                         |
| `Sec-Fetch-Site`     | **无此字段**                                                                           | `same-site`                                                     |
| `Sec-Fetch-Mode`     | **无此字段**                                                                           | `cors`                                                          |
| `DS`                 | X4 salt                                                                                | X4 salt（同一个值）                                             |
| `Cookie`             | 完整 cookie 字符串                                                                     | 完整 cookie 字符串                                              |

### 1.2 Geetest 验证通过后的 challenge 相关 header

| 字段                   | 本项目（修复后）    | PizzaHelperUnited |
| ---------------------- | ------------------- | ----------------- |
| `x-rpc-challenge`      | ✅ 有               | ✅ 有             |
| `x-rpc-challenge_path` | ✅ 有（修复后新增） | ✅ 有             |
| `x-rpc-challenge_game` | ✅ 有（修复后新增） | ✅ 有             |

具体值：

| 游戏   | `x-rpc-challenge_path`                                                       | `x-rpc-challenge_game` |
| ------ | ---------------------------------------------------------------------------- | ---------------------- |
| 原神   | `https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/dailyNote` | `2`                    |
| 星铁   | `https://api-takumi-record.mihoyo.com/game_record/app/hkrpg/api/note`        | `6`                    |
| 绝区零 | `https://api-takumi-record.mihoyo.com/event/game_record_zzz/api/zzz/note`    | `8`                    |

两个项目的值完全一致。✅

### 1.3 降级触发条件

| 项目              | 触发 Widget 降级的条件                                 |
| ----------------- | ------------------------------------------------------ |
| 本项目            | `retcode === '1034'` 或 `retcode === '10035'`          |
| PizzaHelperUnited | `try? fullNote4GI(...)` 失败（**任何错误**都触发降级） |

本项目的逻辑更精确，只在 Geetest 相关 retcode 时降级，不会因为网络超时等无关错误误触发 Widget。这是有意为之的设计差异，不是缺陷。

---

## 二、Widget 便笺接口

### 2.1 Widget Cookie 构造

| 项目              | 构造逻辑                                                   | stoken 格式要求                       |
| ----------------- | ---------------------------------------------------------- | ------------------------------------- |
| 本项目            | `buildWidgetCookie()`：优先取 `stoken`，其次取 `ltoken_v2` | **无格式检查**，v1/v2 均接受          |
| PizzaHelperUnited | 直接检查 `cookie.contains("stoken=v2_")`                   | **必须是 v2 格式**（`stoken=v2_xxx`） |

本项目接受 v1 格式的 stoken，但 Widget API 实际上只支持 v2 格式。如果用户通过 Cookie 登录（无 stoken），本项目会尝试用 `ltoken_v2` 作为 stoken，这个行为是否正确取决于服务器是否接受 `ltoken_v2` 作为 Widget stoken。

### 2.2 Widget 请求头对比

| 字段                | 本项目                                                 | PizzaHelperUnited（原神）             | PizzaHelperUnited（星铁/绝区零）                       |
| ------------------- | ------------------------------------------------------ | ------------------------------------- | ------------------------------------------------------ |
| `User-Agent`        | `WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0` | **普通 miHoYoBBS UA**（未覆盖）       | `WidgetExtension/434 CFNetwork/1492.0.1 Darwin/23.3.0` |
| `x-rpc-client_type` | `1`（CLIENT_IOS）                                      | `5`（defaultHeaders 默认值）          | `5`（defaultHeaders 默认值）                           |
| `x-rpc-app_version` | `2.104.0`                                              | `2.40.1`                              | `2.40.1`                                               |
| `x-rpc-device_fp`   | ✅ 有                                                  | ✅ 有（additionalHeaders 注入）       | ✅ 有（additionalHeaders 注入）                        |
| `x-rpc-device_id`   | ✅ 有                                                  | ✅ 有（additionalHeaders 注入）       | ✅ 有（additionalHeaders 注入）                        |
| `DS`                | ✅ 有（V2 salt）                                       | ✅ 有（X4 salt，defaultHeaders 生成） | ✅ 有（X4 salt，defaultHeaders 生成）                  |
| `Referer`           | `https://app.mihoyo.com`                               | `https://webstatic.mihoyo.com`        | `https://webstatic.mihoyo.com`                         |

**关键发现**：PizzaHelperUnited 的原神 Widget 接口**没有**覆盖 User-Agent，用的是普通 miHoYoBBS UA，而星铁和绝区零覆盖了 WidgetExtension UA。本项目三个游戏统一用 WidgetExtension UA。

### 2.3 Widget 接口路径

| 游戏   | 本项目                                    | PizzaHelperUnited                            |
| ------ | ----------------------------------------- | -------------------------------------------- |
| 原神   | `/game_record/app/genshin/aapi/widget/v2` | `/game_record/app/genshin/aapi/widget/v2` ✅ |
| 星铁   | `/game_record/app/hkrpg/aapi/widget`      | `/game_record/app/hkrpg/aapi/widget` ✅      |
| 绝区零 | `/event/game_record_zzz/api/zzz/widget`   | `/event/game_record_zzz/api/zzz/widget` ✅   |

路径完全一致。✅

---

## 三、修复前后对比

| 问题                   | 修复前  | 修复后    |
| ---------------------- | ------- | --------- |
| `x-rpc-challenge_path` | ❌ 缺失 | ✅ 已补充 |
| `x-rpc-challenge_game` | ❌ 缺失 | ✅ 已补充 |

---

## 四、修复后仍存在的差异

修复 challenge 相关 header 后，两个项目在 dailyNote/Widget 接口上还有以下差异：

### 差异 A：Widget 接口的 User-Agent（原神）

- 本项目：三个游戏统一用 `WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0`
- PizzaHelperUnited：原神 Widget **没有**覆盖 UA（用普通 miHoYoBBS UA），星铁/绝区零用 `WidgetExtension/434 CFNetwork/1492.0.1 Darwin/23.3.0`

本项目的做法（统一 WidgetExtension UA）反而比 PizzaHelperUnited 更一致，不是缺陷。

### 差异 B：Widget Cookie 的 stoken v2 格式检查

- 本项目：无格式检查，v1/v2 均接受，还会尝试用 `ltoken_v2` 降级
- PizzaHelperUnited：明确要求 `stoken=v2_`

如果用户的 cookie 里只有 v1 格式的 stoken，本项目会尝试 Widget 降级但可能失败（服务器拒绝 v1 stoken）。

### 差异 C：普通便笺接口缺少的 header

本项目没有以下 header，PizzaHelperUnited 有：

| 缺失字段                   | PizzaHelperUnited 的值 | 影响评估                                 |
| -------------------------- | ---------------------- | ---------------------------------------- |
| `X-Requested-With`         | `com.mihoyo.hyperion`  | 低风险，服务器通常不强制校验             |
| `Accept-Encoding`          | `gzip, deflate, br`    | 低风险，HTTP 客户端通常自动处理          |
| `Accept-Language`          | `zh-CN,zh-Hans;q=0.9`  | 低风险，影响响应语言，不影响认证         |
| `Connection`               | `keep-alive`           | 低风险，HTTP/1.1 默认行为                |
| `Sec-Fetch-Dest/Site/Mode` | `empty/same-site/cors` | 低风险，浏览器专用字段，服务器通常不校验 |

### 差异 D：`x-rpc-page` 值不同

- 本项目：按游戏和接口类型设置精确值（如 `v6.4.2-gr-cn_#/ys`）
- PizzaHelperUnited：固定 `3.1.3_#/rpg`（所有游戏统一）

本项目的值更精确，与实际 App 版本对应，不是缺陷。

### 差异 E：`x-rpc-tool_verison` 和 `x-rpc-sys_version`

- 本项目：有这两个字段
- PizzaHelperUnited：没有这两个字段

本项目多了这两个字段，不是缺陷。

---

## 五、结论

修复 `x-rpc-challenge_path` 和 `x-rpc-challenge_game` 后，两个项目在 dailyNote/Widget 接口上的**实质性差异只剩一个**：

**Widget Cookie 的 stoken v2 格式检查**（差异 B）。

其余差异（A/C/D/E）均属于无害差异或本项目更优的实现，不需要修改。

---

## 六、待决策方案

针对差异 B（Widget Cookie stoken v2 格式检查），有以下两个方案：

### 方案一：不修改，保持现状

**理由**：

- 手机号登录和二维码登录后，cookie 里的 stoken 本身就是 v2 格式（`stoken=v2_xxx`），正常用户不受影响
- Cookie 登录用户没有 stoken，本项目会尝试用 `ltoken_v2` 降级，如果服务器接受则正常工作
- 即使 Widget 降级失败，也只是回退到 Geetest 流程，不会崩溃

**风险**：Cookie 登录用户在触发 1034 时，Widget 降级可能失败（取决于服务器是否接受 `ltoken_v2` 作为 Widget stoken）。

### 方案二：在 `buildWidgetCookie()` 中加入 v2 格式检查

在 `BBSRepository.buildWidgetCookie()` 里，提取到 stoken 后检查是否以 `v2_` 开头，不是则跳过 Widget 降级，直接走 Geetest 流程。

```typescript
// 修改点：BBSRepository.buildWidgetCookie()
let stoken = BBSRepository.extractCookieField(cookie, "stoken");
if (stoken.length === 0) {
  stoken = BBSRepository.extractCookieField(cookie, "ltoken_v2");
}
// 新增：只有 v2 格式才能用于 Widget API
if (!stoken.startsWith("v2_")) {
  return "";
}
```

**优点**：与 PizzaHelperUnited 行为一致，避免用无效 stoken 发起注定失败的 Widget 请求。
**缺点**：Cookie 登录用户（无 stoken）在触发 1034 时直接走 Geetest，无法享受 Widget 降级的好处。
