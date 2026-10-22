# 三项目 API 参数对比文档

对比本项目（HarmonyOS）、PizzaHelperUnited（iOS）、TeyvatGuide（TypeScript/Tauri）在 DS 签名、Cookie 字段、请求头、错误处理等方面的实现差异。

> **2026-10-21 更新**：本文保留历史对比结构；BaseApiService 迁移后的当前实现、静态参考矩阵和未决分歧以 [`Core-Kits-Refactor/API-Baseline.md`](Core-Kits-Refactor/API-Baseline.md) §2.2 为准。本轮已修正 `-10001` / `5003` / `10041` / `10102` 的错误描述、当前 App 版本号和 TeyvatGuide 当前 salt；仍标“参考有分歧”的链路需要运行时确认。

---

## 一、App 版本号与 Salt

### 本项目（HarmonyOS）

来源：`core/src/main/ets/network/ApiConfig.ets`、`core/src/main/ets/network/DSUtil.ets`

| 参数                | 值                                                                                                                    |
| ------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `x-rpc-app_version` | `2.115.0`（`ApiConfig.APP_VERSION`）                                                                                  |
| User-Agent          | `Mozilla/5.0 (iPhone; CPU iPhone OS 16_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.104.0` |
| 便笺 / Widget UA    | 便笺对齐 PizzaHelperUnited：`miHoYoBBS/2.40.1`；星铁 / 绝区零 Widget：`WidgetExtension/434 ...`                        |
| salt_v1（旧 K2）    | 从 `rawfile/release/salt_config.json` 读取，**不硬编码**；当前无业务调用方                                             |
| salt_v2（BBS）      | 同上；当前 `BBS` profile 使用                                                                                         |
| salt_x4（X4）       | 同上；GAME_RECORD / CALCULATE / passport / Geetest 使用                                                               |
| salt_x6（X6）       | 同上；SIGN profile 使用                                                                                               |

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
| `x-rpc-app_version`  | `2.115.0`                                                     |
| User-Agent（移动端） | `Mozilla/5.0 (Linux; Android 12) Mobile miHoYoBBS/2.115.0`    |
| User-Agent（PC 端）  | `Mozilla/5.0 (Windows NT 10.0; Win64; x64) miHoYoBBS/2.115.0` |
| K2                   | `09d39d16528ca0e4900a39ecc07d5062`                            |
| LK2                  | `b99b74d9023a6511231be2c7209b6fdb`                            |
| X4                   | `xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs`                            |
| X6                   | `t0qEgfub6cvueAPgR5m9aQWWVciEer7v`                            |
| PROD                 | `t0qEgfub6cvueAPgR5m9aQWWVciEer7v`                            |

> **关键差异**：本项目 salt 从文件读取（不硬编码），PizzaHelperUnited 和 TeyvatGuide 均硬编码。本项目 app_version 是 `2.115.0`，PizzaHelperUnited 国服是 `2.40.1`（本项目便笺 / Widget 另用此 profile），TeyvatGuide 是 `2.115.0`。
>
> 本项目 `salt_v1` / `salt_v2` 是 `lX8m...` / `yBh...`，与 TeyvatGuide 当前 K2 / LK2 不同；`generateV1` / `generateK2Sign` / `generateK2` 当前无业务调用方，不能据此推断线上 K2 行为。

---

## 二、DS 签名算法

### 本项目（HarmonyOS）

来源：`DSUtil.ets`

| DS 类型 | 方法               | Salt                         | random 格式                 | 用途                                                |
| ------- | ------------------ | ---------------------------- | --------------------------- | --------------------------------------------------- |
| V1      | `generateV1()`     | salt_v1（旧 salt，未使用）   | 6 位纯数字（100000-199999） | 当前无业务调用方                                    |
| V2      | `generateV2()`     | salt_v2（BBS profile）       | 6 位字母数字混合            | BBS 账号 / 角色 / 战绩卡片                          |
| X4      | `generateX4()`     | salt_x4（X4）                | 6 位纯数字（100000-199999） | GAME_RECORD / CALCULATE / passport / Geetest        |
| X6      | `generateX6()`     | salt_x6（X6）                | 6 位字母数字混合            | 签到接口（SIGN Profile）                            |
| K2 Sign | `generateK2Sign()` | salt_v1（旧 salt，未使用）   | 6 位字母数字混合            | 当前无业务调用方；不是 TeyvatGuide 当前 K2 salt     |
| K2      | `generateK2()`     | salt_v1（旧 salt，未使用）   | 6 位字母数字混合            | 当前无业务调用方；不是 TeyvatGuide 当前 K2 salt     |

**hashStr 格式**：

- 普通（含 b/q）：`salt={salt}&t={timestamp}&r={random}&b={body}&q={query}`
- Sign（不含 b/q）：`salt={salt}&t={timestamp}&r={random}`

**注意**：本项目数字 random 是 `100000-199999`，与 PizzaHelperUnited 的 `100_000 ..< 200_000` 一致；TeyvatGuide 的数字 random 上界为 `200000`。`GAME_RECORD` 实际使用 X4，不是 V1；`generateV1` / `generateK2*` 当前没有调用方，不能当作已验证的线上签名路径。

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
x-rpc-app_version:   2.115.0
x-rpc-client_type:   5（Web/PC）
x-rpc-device_id:     {UUID，持久化}
x-rpc-device_fp:     {真实设备指纹，通过 DeviceFpService 获取}
x-rpc-sys_version:   16.3.1
x-rpc-language:      zh-cn
x-rpc-tool_verison:  v6.4.2-gr-cn（原神）/ v4.1.1（星铁）
x-rpc-page:          原神 / 星铁角色列表、详情按接口设置；便笺改用 Pizza profile
Referer:             https://webstatic.mihoyo.com/
Origin:              https://webstatic.mihoyo.com
DS:                  {X4 签名}
Cookie:              {完整 cookie 字符串}
```

> 便笺 / Widget 另走 `buildPizza`：`x-rpc-app_version=2.40.1`、UA `miHoYoBBS/2.40.1`、`x-rpc-page=3.1.3_#/rpg`，与 PizzaHelperUnited 一致。BBS 账号 / 角色 / 战绩卡片另走 `BBS` profile：`client_type=1` + DS v2 + `Referer: app.mihoyo.com`，与下面的 GAME_RECORD 不同。

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
user-agent:          Mozilla/5.0 (Windows NT 10.0; Win64; x64) miHoYoBBS/2.115.0
x-rpc-app_version:   2.115.0
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
> - 本项目便笺 / Widget 直接套用 Pizza profile（page `3.1.3_#/rpg`、app_version 2.40.1）；GAME_RECORD 角色接口才使用按游戏设置的 page 和 tool_verison。
> - PizzaHelperUnited 有 `Sec-Fetch-*` 系列头，本项目和 TeyvatGuide 没有。
> - 本项目 `x-rpc-sys_version: 16.3.1`，PizzaHelperUnited 没有此字段。
> - 本项目 User-Agent 模拟 iPhone iOS 16.3.1（`miHoYoBBS/2.104.0`），PizzaHelperUnited 模拟 iPhone iOS 17.6，TeyvatGuide 模拟 Windows PC；三者的 UA 版本都与各自 `x-rpc-app_version` 不完全一致，服务器目前可接受多种组合。

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

**触发 AuthExpiredError 的 retcode**：`-100`、`10001`。`-10001` 是请求无效（DS / header / 参数），不触发刷新。

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

**Cookie 刷新触发条件**：`retcode=-100`、`10001`（映射为 `AuthExpiredError`）。`-10001` 不在此列，按 `INVALID_REQUEST` 处理。

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

来源：`MihoyoRetcode.ets`、`RetcodeRegistry.ets`、`ApiErrorHandler.ets`、`ApiErrors.ets`、`GenshinRepository.ets`

| retcode        | 语义分类 / 错误类型                    | 处理方式                                      |
| -------------- | ------------------------------------- | --------------------------------------------- |
| `-100`         | `AUTH_EXPIRED` / `AuthExpiredError`   | 尝试用 stoken 刷新 cookie，失败则提示重新登录 |
| `10001`        | `AUTH_EXPIRED` / `AuthExpiredError`   | 同上                                          |
| `-111`         | `AUTH_EXPIRED`                        | 同上；来自 `api-takumi.mihoyo.com` 旧接口     |
| `-10001`       | `INVALID_REQUEST` / 普通业务错误      | 不刷新 Cookie，检查 DS / header / 参数        |
| `1034`         | `VERIFICATION_REQUIRED`               | 先尝试 Widget 降级，无法降级则触发 Geetest    |
| `10035`        | `VERIFICATION_REQUIRED`               | 同上；绝区零战绩走 `createGeetest` / `verifyGeetest` |
| `5003`/`10041` | `FINGERPRINT_INVALID`                 | 上报指纹无效 / 账号异常；`SyncQueueRunner` 归为 `fingerprint` |
| `10102`        | `ROLE_NOT_PUBLIC`                     | 提示战绩未公开                                |
| `10307`        | `MAINTENANCE`                         | 已登记；当前仍按普通业务错误展示，后续可接维护提示 |
| `-1002`        | `ACCOUNT_NOT_FOUND`（当前未使用）     | 游戏账号未绑定，不是 `1008`，也不是登录失效   |
| `1008`         | `USER_INFO_MISMATCH` / 参数错误        | 用户信息不匹配（如无效 role_id），不是账号不存在 |
| `-106`         | `QR_EXPIRED`                          | 二维码登录轮询转成 `expired` 状态             |
| `-110`/`-502`/`1002` | `RATE_LIMITED` / `SERVER_ERROR`  | 已登记；是否重试由调用方决定                  |
| `-1`/`-101`/`1000` | `INVALID_PARAM`                    | 参数错误，展示服务端 message                  |

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

> **关键差异**：PizzaHelperUnited 和本项目都没有把 `-10001` 映射为 auth 失效；本项目使用 `INVALID_REQUEST`。PizzaHelperUnited 有 `5003`/`10041` 的专门错误类型；本项目通过 `FingerprintReporter` 上报、`SyncQueueRunner` 归类为 `fingerprint` 失败，但 `ApiErrorHandler` 仍未单独建错误类型。`10102` 是战绩可见性不足，不是账号封禁。

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

| 参数                      | 本项目                                                   | PizzaHelperUnited  | TeyvatGuide  | 风险说明                               |
| ------------------------- | -------------------------------------------------------- | ------------------ | ------------ | -------------------------------------- |
| app_version               | GAME_RECORD / BBS / passport `2.115.0`；便笺 / Widget `2.40.1` | `2.40.1`           | `2.115.0`    | 版本过高或过低可能触发服务器校验       |
| salt 来源                 | 文件读取（X4 / V2 / X6）                                 | 硬编码 X4          | 硬编码各类型 | salt 文件内容是否与 app_version 匹配   |
| x-rpc-page                | 便笺固定 `3.1.3_#/rpg`；角色按接口设置                    | 固定 `3.1.3_#/rpg` | 无此字段     | 错误的 page 值可能触发 1034            |
| x-rpc-tool_verison        | 原神 / 星铁角色接口按游戏设置                            | 无此字段           | 无此字段     | 拼写错误（verison），缺失可能触发 1034 |
| x-rpc-challenge_path/game | 便笺 / ZZZ 已实现；其他接口未逐条验证                    | 有                 | 无           | Geetest 验证后重试可能失败             |
| Widget Cookie 格式        | `stuid=xxx;stoken=xxx;mid=xxx`                           | 需要 `stoken=v2_`  | 无 Widget    | stoken 非 v2 格式时 Widget 降级失败    |
| -10001 处理               | `INVALID_REQUEST`，不刷新 Cookie                         | 不处理             | 不处理       | 本项目单独识别，避免误判登录失效       |
| 5003/10041 处理           | `FingerprintReporter` + `SyncQueueRunner`                | 视为指纹无效       | 不处理       | 已上报 / 归队，但未建专门错误类型      |
| 10102 处理                | `RoleNotPublicError`                                     | 数据可见性不足     | 提示未公开   | 不是账号封禁                           |
