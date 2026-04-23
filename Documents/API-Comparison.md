# 三项目 API 参数对比文档

对比本项目（HarmonyOS）、PizzaHelperUnited（iOS）、TeyvatGuide（TypeScript/Tauri）在 DS 签名、Cookie 字段、请求头、错误处理等方面的实现差异。

---

## 一、App 版本号与 Salt

### 本项目（HarmonyOS）

来源：`core/src/main/ets/network/ApiConfig.ets`、`core/src/main/ets/network/DSUtil.ets`

| 参数                | 值                                                                                                                    |
| ------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `x-rpc-app_version` | `2.104.0`                                                                                                             |
| User-Agent          | `Mozilla/5.0 (iPhone; CPU iPhone OS 16_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.104.0` |
| Widget User-Agent   | `WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0`                                                                |
| salt_v1（K2）       | 从 `rawfile/release/salt_config.json` 读取，**不硬编码**                                                              |
| salt_v2（BBS）      | 同上                                                                                                                  |
| salt_x4（X4）       | 同上                                                                                                                  |
| salt_x6（X6）       | 同上                                                                                                                  |

### PizzaHelperUnited（iOS）

来源：`URLRequestConfig.swift`

| 参数                             | 值                                                                                                                    |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `x-rpc-app_version`（国服）      | `2.40.1`                                                                                                              |
| `x-rpc-app_version`（国际服）    | `2.55.0`                                                                                                              |
| User-Agent                       | `Mozilla/5.0 (iPhone; CPU iPhone OS 17_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/{version}` |
| Widget User-Agent（星铁/绝区零） | `WidgetExtension/434 CFNetwork/1492.0.1 Darwin/23.3.0`                                                                |
| salt（国服）                     | `xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs`（X4，硬编码）                                                                      |
| salt（国际服）                   | `okr4obncj8bw5a65hbnn5oo6ixjc3l9w`（OSX6，硬编码）                                                                    |

### TeyvatGuide（TypeScript）

来源：`TGBbs.ts`

| 参数                 | 值                                                            |
| -------------------- | ------------------------------------------------------------- |
| `x-rpc-app_version`  | `2.102.1`                                                     |
| User-Agent（移动端） | `Mozilla/5.0 (Linux; Android 12) Mobile miHoYoBBS/2.102.1`    |
| User-Agent（PC 端）  | `Mozilla/5.0 (Windows NT 10.0; Win64; x64) miHoYoBBS/2.102.1` |
| K2                   | `lX8m5VO5at5JG7hR8hzqFwzyL5aB1tYo`                            |
| LK2                  | `yBh10ikxtLPoIhgwgPZSv5dmfaOTSJ6a`                            |
| X4                   | `xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs`                            |
| X6                   | `t0qEgfub6cvueAPgR5m9aQWWVciEer7v`                            |
| PROD                 | `t0qEgfub6cvueAPgR5m9aQWWVciEer7v`                            |

> **关键差异**：本项目 salt 从文件读取（不硬编码），PizzaHelperUnited 和 TeyvatGuide 均硬编码。本项目 app_version 是 `2.104.0`，PizzaHelperUnited 国服是 `2.40.1`，TeyvatGuide 是 `2.102.1`。

---

## 二、DS 签名算法

### 本项目（HarmonyOS）

来源：`DSUtil.ets`

| DS 类型 | 方法               | Salt           | random 格式                 | 用途                                                |
| ------- | ------------------ | -------------- | --------------------------- | --------------------------------------------------- |
| V1      | `generateV1()`     | salt_v1（K2）  | 6 位纯数字（100000-199999） | 游戏记录接口（GAME_RECORD Profile）                 |
| V2      | `generateV2()`     | salt_v2（BBS） | 6 位字母数字混合            | BBS 接口、Widget 接口                               |
| X4      | `generateX4()`     | salt_x4（X4）  | 6 位纯数字（100000-199999） | passport 接口（getLToken/getCookieToken）           |
| X6      | `generateX6()`     | salt_x6（X6）  | 6 位字母数字混合            | 签到接口（SIGN Profile）                            |
| K2 Sign | `generateK2Sign()` | salt_v1（K2）  | 6 位字母数字混合            | Geetest createVerification（isSign=true，不含 b/q） |
| K2      | `generateK2()`     | salt_v1（K2）  | 6 位字母数字混合            | Geetest verifyVerification（含 b/q）                |

**hashStr 格式**：

- 普通（含 b/q）：`salt={salt}&t={timestamp}&r={random}&b={body}&q={query}`
- Sign（不含 b/q）：`salt={salt}&t={timestamp}&r={random}`

**注意**：本项目 `generateV1` 的 random 是 6 位纯数字（100000-199999），与 PizzaHelperUnited 一致，但与 TeyvatGuide 的 `isSign=true`（6 位字母数字）不同。

### PizzaHelperUnited（iOS）

来源：`URLRequestHelper.swift`

只有一种 DS 算法，所有接口统一使用：

```
salt={salt}&t={timestamp}&r={random}&b={body}&q={query}
```

- random：`Int.random(in: 100_000 ..< 200_000)`（6 位纯数字）
- salt：由 `URLRequestConfig.salt(region:)` 决定（国服 X4，国际服 OSX6）
- 所有接口（包括游戏记录、便笺）都用同一个 salt，**没有区分 K2/X6/LK2**

### TeyvatGuide（TypeScript）

来源：`getRequestHeader.ts`

有两种模式：

| 模式 | isSign | random                      | hashStr  |
| ---- | ------ | --------------------------- | -------- |
| 普通 | false  | 6 位纯数字（100000-200000） | 含 b/q   |
| Sign | true   | 6 位字母数字混合            | 不含 b/q |

> **关键差异**：
>
> - PizzaHelperUnited 只用 X4 salt，random 纯数字，所有接口统一。
> - TeyvatGuide 区分 K2/X4/X6/LK2，isSign=true 时 random 是字母数字混合。
> - 本项目区分 V1/V2/X4/X6/K2，V1/X4 用纯数字 random，V2/X6/K2 用字母数字混合。

---

## 三、请求头对比（游戏记录接口）

### 本项目（GAME_RECORD Profile）

来源：`MihoyoHeaderBuilder.ets`

```
User-Agent:          Mozilla/5.0 (iPhone; CPU iPhone OS 16_3_1 ...) miHoYoBBS/2.104.0
x-rpc-app_version:   2.104.0
x-rpc-client_type:   5（Web/PC）
x-rpc-device_id:     {UUID，持久化}
x-rpc-device_fp:     {真实设备指纹，通过 DeviceFpService 获取}
x-rpc-sys_version:   16.3.1
x-rpc-language:      zh-cn
x-rpc-tool_verison:  v6.4.2-gr-cn（原神）/ v4.1.1（星铁）
x-rpc-page:          v6.4.2-gr-cn_#/ys（原神便笺）等
Referer:             https://webstatic.mihoyo.com/
Origin:              https://webstatic.mihoyo.com
DS:                  {X4 签名}
Cookie:              {完整 cookie 字符串}
```

### PizzaHelperUnited（国服）

来源：`URLRequestConfig.swift`、`HoyoAPI.swift`

```
User-Agent:          Mozilla/5.0 (iPhone; CPU iPhone OS 17_6 ...) miHoYoBBS/2.40.1
Referer:             https://webstatic.mihoyo.com
Origin:              https://webstatic.mihoyo.com
Accept-Encoding:     gzip, deflate, br
Accept-Language:     zh-CN,zh-Hans;q=0.9
Accept:              application/json, text/plain, */*
Connection:          keep-alive
X-Requested-With:    com.mihoyo.hyperion
x-rpc-app_version:   2.40.1
x-rpc-client_type:   5
x-rpc-page:          3.1.3_#/rpg（固定值，不区分游戏）
x-rpc-device_id:     {设备 UUID}
x-rpc-language:      {当前语言}
x-rpc-device_fp:     {设备指纹}
Sec-Fetch-Dest:      empty
Sec-Fetch-Site:      same-site
Sec-Fetch-Mode:      cors
DS:                  {X4 签名}
Cookie:              {完整 cookie 字符串}
```

### TeyvatGuide（PC 端）

来源：`getRequestHeader.ts`

```
user-agent:          Mozilla/5.0 (Windows NT 10.0; Win64; x64) miHoYoBBS/2.102.1
x-rpc-app_version:   2.102.1
x-rpc-client_type:   5
x-requested-with:    com.mihoyo.hyperion
referer:             https://webstatic.mihoyo.com
x-rpc-device_id:     {设备 UUID}
x-rpc-device_fp:     {设备指纹}
ds:                  {X4 签名}
cookie:              {cookie 字符串}
```

> **关键差异**：
>
> - PizzaHelperUnited 有 `x-rpc-page: 3.1.3_#/rpg`（固定值），本项目按接口类型设置不同的 page 值。
> - PizzaHelperUnited 有 `Sec-Fetch-*` 系列头，本项目和 TeyvatGuide 没有。
> - 本项目 `x-rpc-sys_version: 16.3.1`，PizzaHelperUnited 没有此字段。
> - 本项目 User-Agent 模拟 iPhone iOS 16.3.1，PizzaHelperUnited 模拟 iPhone iOS 17.6，TeyvatGuide 模拟 Windows PC。

---

## 四、便笺接口降级策略（1034 处理）

### 本项目

来源：`GenshinRepository.ets`、`StarRailRepository.ets`、`ZZZRepository.ets`

**流程**：

1. 调用普通便笺接口（`/game_record/app/genshin/api/dailyNote`）
2. 若返回 `retcode=1034` 或 `10035`：
   - 尝试构造 Widget Cookie（`buildWidgetCookie()`）
   - 若 Widget Cookie 可用（有 stoken 或 ltoken_v2）：调用 Widget API 降级
   - 若无法构造 Widget Cookie：抛出错误，触发 Geetest 流程
3. Widget API 成功后调用 `markSuccess()`

**Widget Cookie 构造逻辑**（`BBSRepository.buildWidgetCookie()`）：

- stoken：优先取 `stoken`，其次取 `ltoken_v2`
- stuid：优先取 `stuid`，其次取 `account_id` / `ltuid_v2` / `ltuid`
- mid：优先取 `mid`，其次取 `account_mid_v2` / `ltmid_v2`
- 格式：`stuid={stuid};stoken={stoken};mid={mid}`

**触发 AuthExpiredError 的 retcode**：`-100`、`10001`、`-10001`

### PizzaHelperUnited（iOS）

来源：`NoteAPI4GI.swift`、`NoteAPI4HSR.swift`、`NoteAPI4ZZZ.swift`

**流程**：

1. 调用普通便笺接口（`fullNote4GI/HSR/ZZZ`）
2. 若失败（任何错误，包括 1034）：
   - 检查 cookie 是否包含 `stoken=v2_`
   - 若有：调用 Widget API 降级（`widgetNote4GI/HSR/ZZZ`）
   - 若无：抛出 `MiHoYoAPIError.sTokenV2InvalidOrMissing`

**关键区别**：PizzaHelperUnited 用 `try?` 捕获所有错误后降级，**不区分 1034 和其他错误**。只要普通接口失败，就尝试 Widget 降级。

**Widget Cookie 要求**：cookie 字符串中必须包含 `stoken=v2_`（v2 格式的 stoken）。

**Widget User-Agent**（星铁/绝区零）：`WidgetExtension/434 CFNetwork/1492.0.1 Darwin/23.3.0`

### TeyvatGuide（TypeScript）

来源：`miscReq.ts`

**流程**：

1. 调用普通便笺接口
2. 若返回 `retcode=1034`：
   - 调用 `miscReq.challenge(cookie)` 触发 Geetest 流程
   - 获取 challenge 后，将 `x-rpc-challenge` 附加到请求头重试
3. **没有 Widget API 降级**

> **关键差异**：
>
> - PizzaHelperUnited：普通接口失败 → 直接降级 Widget（不触发 Geetest）
> - 本项目：1034/10035 → 先尝试 Widget 降级，无法降级才触发 Geetest
> - TeyvatGuide：1034 → 触发 Geetest，无 Widget 降级

---

## 五、Cookie 字段与刷新机制

### 本项目

来源：`BBSRepository.ets`、`AuthRepository.ets`

**存储的 Cookie 字段**（手机号/二维码登录）：

```
account_id={uid}; cookie_token={token}; ltoken={ltoken}; ltuid={uid}; stoken={stoken}; stuid={uid}; mid={mid}
```

**Cookie 刷新触发条件**：`retcode=-100`、`10001`、`-10001`（均映射为 `AuthExpiredError`）

**刷新流程**（`BBSRepository.refreshCookieIfNeeded()`）：

1. 从 cookie 提取 `stoken` 和 `mid`
2. 若无 stoken：抛出 `AuthExpiredError`，提示重新登录
3. 调用 `getLTokenBySToken(stoken, mid)` → 获取新 ltoken
4. 调用 `getCookieBySToken(stoken, mid)` → 获取新 cookie_token
5. 替换 cookie 字符串中的 `ltoken`、`ltoken_v2`、`cookie_token`、`cookie_token_v2`
6. 写入 DB

**Widget Cookie 构造**：从完整 cookie 中提取 stoken（或 ltoken_v2）+ stuid + mid，格式 `stuid=xxx;stoken=xxx;mid=xxx`

### PizzaHelperUnited（iOS）

来源：`GetCookieTokenAPI.swift`、`GetTokenAPI.swift`

**Cookie 刷新**：通过 `HoYo.cookieToken()` 调用 `/auth/api/getCookieAccountInfoBySToken` 刷新 cookie_token。

**Widget Cookie 要求**：必须有 `stoken=v2_` 格式的 stoken（v2 格式）。v1 格式的 stoken 不能用于 Widget API。

**关键点**：PizzaHelperUnited 存储的 cookie 中 stoken 是 v2 格式（`stoken=v2_xxx`），这是 Widget 降级能成功的前提。

### TeyvatGuide（TypeScript）

来源：`passportReq.ts`

**Cookie 刷新**：

- `getLTokenBySToken()`：调用 `/account/auth/api/getLTokenBySToken`，需要 `stoken` + `mid`
- `getCookieAccountInfoBySToken()`：调用 `/account/auth/api/getCookieAccountInfoBySToken`，需要 `stoken` + `mid`
- `verifyLToken()`：调用 `passport-api-v4.mihoyo.com/account/ma-cn-session/web/verifyLtoken`，验证 ltoken 有效性

---

## 六、错误码处理对比

### 本项目

来源：`ApiErrors.ets`、`GenshinRepository.ets`

| retcode  | 错误类型                              | 处理方式                                      |
| -------- | ------------------------------------- | --------------------------------------------- |
| `-100`   | `AuthExpiredError`                    | 尝试用 stoken 刷新 cookie，失败则提示重新登录 |
| `10001`  | `AuthExpiredError`                    | 同上                                          |
| `-10001` | `AuthExpiredError`                    | 同上（本项目将 -10001 也视为 auth 失效）      |
| `1034`   | 降级 Widget 或 `GeetestRequiredError` | 先尝试 Widget 降级，无法降级则触发 Geetest    |
| `10035`  | 同 1034                               | 同上                                          |
| `10102`  | `RoleNotPublicError`                  | 提示战绩未公开                                |

### PizzaHelperUnited（iOS）

来源：`APIError.swift`

| retcode                 | 错误类型                         | 处理方式                                            |
| ----------------------- | -------------------------------- | --------------------------------------------------- |
| `1034`, `10035`         | `.verificationNeeded`            | 触发 Geetest 验证（但便笺接口会先尝试 Widget 降级） |
| `5003`, `10041`         | `.fingerPrintInvalidOrMissing`   | 提示设备指纹无效，需要重新获取                      |
| `10102`                 | `.insufficientDataVisibility`    | 提示战绩未公开                                      |
| `-100`, `10001`         | `.reloginRequired`               | 提示重新登录                                        |
| `10307`                 | `.serverUnderMaintenanceUpgrade` | 提示服务器维护                                      |
| `403`（含特定 message） | `.countryRegionRestriction`      | 提示地区限制                                        |

> **关键差异**：PizzaHelperUnited 没有将 `-10001` 映射为 auth 失效，本项目将 `-10001` 也视为 `AuthExpiredError`。PizzaHelperUnited 有 `5003`/`10041`（设备指纹无效）的专门处理，本项目没有。

### TeyvatGuide（TypeScript）

来源：`miscReq.ts`（无统一错误映射）

| retcode  | 处理方式                            |
| -------- | ----------------------------------- |
| `1034`   | 触发 Geetest 流程                   |
| 其他非 0 | `showSnackbar.error()` 显示错误信息 |

---

## 七、设备指纹（device_fp）

### 本项目

来源：`ApiConfig.ets`、`DeviceFpService.ets`

- 通过 `DeviceFpService.init()` 调用 `public-data-api.mihoyo.com/device-fp/api/getFp` 获取真实指纹
- 持久化到 Preferences，下次启动直接读取
- 获取失败时回退到基于 deviceId MD5 的初始指纹

### PizzaHelperUnited（iOS）

来源：`GetDeviceFingerPrint.swift`（目录存在，未读取具体实现）

- 通过 `profile.deviceFingerPrint` 传入，存储在账号 profile 中
- 便笺接口通过 `additionalHeaders` 注入 `x-rpc-device_fp` 和 `x-rpc-device_id`

### TeyvatGuide（TypeScript）

来源：`otherReq.ts`

- 调用 `public-data-api.mihoyo.com/device-fp/api/getFp` 获取
- 传入大量设备信息（模拟小米手机）
- 获取失败时使用 `0000000000000`

---

## 八、x-rpc-challenge 相关头（Geetest 验证后）

### 本项目

来源：`GenshinApiService.ets`

```
x-rpc-challenge: {challenge}
```

只注入 `x-rpc-challenge`，没有 `x-rpc-challenge_path` 和 `x-rpc-challenge_game`。

### PizzaHelperUnited（iOS）

来源：`URLRequestConfig.swift`（`writeXRPCChallengeHeaders4DailyNote`）

```
x-rpc-challenge:      {challenge}
x-rpc-challenge_path: https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/dailyNote
x-rpc-challenge_game: 2（原神）/ 6（星铁）/ 8（绝区零）
```

PizzaHelperUnited 额外注入了 `x-rpc-challenge_path` 和 `x-rpc-challenge_game`，这两个字段告诉服务器 challenge 是针对哪个接口的。

### TeyvatGuide（TypeScript）

来源：`lunaReq.ts`、`apiHubReq.ts`

```
x-rpc-challenge: {challenge}
```

只注入 `x-rpc-challenge`，与本项目一致。

> **潜在问题**：本项目缺少 `x-rpc-challenge_path` 和 `x-rpc-challenge_game`，这可能导致 Geetest 验证通过后服务器仍然拒绝请求（因为无法确认 challenge 对应的接口）。PizzaHelperUnited 的实现更完整。

---

## 九、总结：可能导致 1034 / -10001 的参数差异

| 参数                      | 本项目                         | PizzaHelperUnited  | TeyvatGuide  | 风险说明                               |
| ------------------------- | ------------------------------ | ------------------ | ------------ | -------------------------------------- |
| app_version               | `2.104.0`                      | `2.40.1`           | `2.102.1`    | 版本过高或过低可能触发服务器校验       |
| salt 来源                 | 文件读取                       | 硬编码 X4          | 硬编码各类型 | salt 文件内容是否与 app_version 匹配   |
| x-rpc-page                | 按接口设置                     | 固定 `3.1.3_#/rpg` | 无此字段     | 错误的 page 值可能触发 1034            |
| x-rpc-tool_verison        | 按游戏设置                     | 无此字段           | 无此字段     | 拼写错误（verison），缺失可能触发 1034 |
| x-rpc-challenge_path/game | **缺失**                       | 有                 | 无           | Geetest 验证后重试可能失败             |
| Widget Cookie 格式        | `stuid=xxx;stoken=xxx;mid=xxx` | 需要 `stoken=v2_`  | 无 Widget    | stoken 非 v2 格式时 Widget 降级失败    |
| -10001 处理               | 视为 AuthExpiredError          | 不处理             | 不处理       | 本项目额外处理了 -10001                |
| 5003/10041 处理           | 不处理                         | 视为指纹无效       | 不处理       | 设备指纹问题本项目无专门处理           |
