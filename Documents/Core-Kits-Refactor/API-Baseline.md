# API Header / Retcode 基线清单

> 状态：**运行时未采集（NOT DONE）；静态参考对照已完成；按用户决定延后到整个迁移任务完成后**
> 用途：记录关键接口的真实 header / retcode / 上报行为，作为后续真实设备回归和旧 transport 删除后的对比材料。
> 采集方式：用户使用 **Proxyman + 米游社 App** 逐项抓取，把结果填入下表对应位置；debug 与 internal/release 至少各确认一轮，同一接口不同构建的结果不要混填。
> 范围：`core/src/main/ets` + `core/src/internal/ets` overlay 的构建链路；不含根目录 `internal/core` 历史副本。
> 更新时间：2026-10-21
>
> **执行决定（2026-10-21）**：用户明确要求先完成整个 BaseApiService 迁移，header / retcode 基线采集推迟到整个任务完成后。本文原先“P0 未完成前不进入 Stage 1 / 删除旧 transport 前必须补采”的门槛已被覆盖，不再阻塞代码迁移；采集本身仍未完成，后续必须补做。
> 当前代码状态：Stage 0-3 已完成，`HttpClient` / `HttpService` / `NetworkFactory` 已删除，四产品和两个测试脚本构建通过。
> 原始 HAR、Cookie、token、`device_fp`、`device_id` 不进入仓库；只填写脱敏后的摘要。
>
> **静态参考对照（2026-10-21，用户指定）**：不再等待 Proxyman 才开始核对。已使用仓库内三个已验证项目和本项目历史抓包做**静态对照**：
>
> - `mihoyo-api-sdk/src/*.tsp`：接口契约，确认 Cookie / DS 必填与路径；
> - `TeyvatGuide/src/utils/getRequestHeader.ts`、`src/utils/TGBbs.ts`、`src/request/*.ts`：X4 / X6 / K2 salt、passport、签到、养成计算；
> - `PizzaHelperUnited/Packages/PZKit/Sources/PZAccountKit/HoYoAPIs/...`：game_record / widget 默认 header、DS、Geetest / 指纹 retcode；
> - `core/src/main/resources/rawfile/release/mihoyo_apis.md`：本项目历史 App 抓包，用于判断 BBS `client_type=1` 等变体。
>
> 静态对照只能说明“当前代码与某个已验证实现一致 / 不一致”，**不能证明本机实际发出的 header 或服务端实际返回的 retcode**。下表的 HTTP / retcode / 最终 header 仍保持“待填”；状态列只写“静态参考已核对；运行时未采集”或“参考有分歧；运行时未采集”，不得改成“已采集”。

---

## 1. 填写规则

每一行至少记录：

- **HTTP status**：200 / 401 / 500 / 超时等；
- **retcode / message**：响应体里的业务 `retcode` 和 `message`；
- **最终 header 摘要**：实际发出的 header 键集合 + 关键值；不要只写代码里“应该发什么”；
- **Cookie 字段**：只写字段名，例如 `account_id,cookie_token,ltoken,ltuid,mid`，不写值；
- **DS**：`absent` / `present(v1)` / `present(v2)` / `present(x4)` / `present(x6)`，不要记录完整 DS；
- **上报**：`none` / `geetest` / `fingerprint` / `suppressed`，以及是否真的弹框；
- **备注**：与预期不一致、空 `uid`、challenge 重放、debug/release 差异等。

安全规则：

- 不记录完整 Cookie、`stoken`、`ltoken`、`cookie_token`、`ticket`、`device_fp`、`device_id`；
- URL 只保留 host + path + query 键名，敏感 query 值打码；
- 请求体 / 响应体只记录顶层键名和 `retcode` / `message`，不粘贴完整 body；
- 不把 Proxyman HAR 原文件提交到仓库。

---

## 2. 采集优先级

| 优先级 | 含义 | 时间点 |
| --- | --- | --- |
| **P0** | 当前流程会走，或迁移后必须对比的 BBS account service 新路径；header / DS / 上报可能变化 | **已延后：任务完成后补采；不阻塞代码迁移** |
| **P1** | 旧 fallback、Geetest、设备指纹、ZZZ 首次注册等低频/旧路径；P1-01/02 原为登录正常流程（旧路径已删除） | **已延后；可触发的新路径任务完成后补采，旧路径标“不可采集”** |
| **P2** | 当前未调用、历史遗留或难触发 | 可记录为“未覆盖”，不要用推测值 |

推荐顺序：登录 → BBS 账号/角色 → 三游戏便笺/Widget → 三游戏角色 → 三游戏养成计算 → 签到 → 设备指纹/Geetest → 旧 fallback。

### 2.1 错误分支也要记录

正常路径只证明 header 能通，不能证明删除旧 transport 后错误处理不变。至少覆盖：

- **Cookie 失效**：登录过期后请求便笺 / 角色 / 账号，记录 HTTP status、retcode、message，以及是否弹登录失效；
- **角色不存在 / 未公开**：用无效 `role_id` 或测试账号，记录 retcode；
- **HTTP 非 200**：至少记录一次 401/403/500（可用代理或临时调试入口构造），确认新 `BaseApiService` 抛出的 `HttpError` 是否带真实 `statusCode` / `body`，以及 App 的提示行为；旧 transport 的错误形态只能从历史日志 / 提交补录；
- **网络断开 / 超时**：断网或代理挂起时记录新 Base 的错误形态（`statusCode = 0`、可读 `message`）、是否重试、App 提示；不要为了对比恢复旧 transport；
- **Geetest**：自然触发 1034 / 10035 时记录 challenge 头、是否弹框、验证后是否重放；
- **设备指纹无效**：5003 / 10041 时记录是否触发指纹重新生成。

无法安全触发时写“未覆盖 + 原因”，不要用推测值；不要为了采集对主账号高频刷请求。

### 2.2 静态参考对照（非抓包）

本节只记录代码级对照，不替代第 3 节以后的运行记录。参考优先级：接口契约以 `mihoyo-api-sdk` 为准；具体 header / DS 以 TeyvatGuide、PizzaHelperUnited 和本项目历史抓包三方交叉判断；三方冲突时保留当前实现并标记“参考有分歧”，等运行时确认。

#### 2.2.1 Header / DS 静态对照

| 链路 | 参考来源 | 参考关键值 | 当前实现 | 静态结论 |
| --- | --- | --- | --- | --- |
| 原神 / 星铁便笺、Widget | PizzaHelperUnited `URLRequestConfig.swift`、`NoteAPI4GI.swift`、`NoteAPI4HSR.swift` | `x-rpc-app_version=2.40.1`，`client_type=5`，DS X4，UA `miHoYoBBS/2.40.1`，Referer `webstatic`，`x-rpc-page=3.1.3_#/rpg`，完整 Cookie | `MihoyoHeaderBuilder.buildPizza()` 与参考值一致 | 与 Pizza 一致；与历史 App 抓包（2.102.0 / 2.115.0、`x-rpc-tool_verison` + 按游戏 page、`x-rpc-device_name`）有差异；运行时未采集 |
| 原神 / 星铁角色列表、详情 | TeyvatGuide `recordReq.ts`、`takumiReq.ts`；`mihoyo_apis.md` 历史抓包 | `client_type=5`，DS X4，`x-rpc-tool_verison`，`x-rpc-page`，UA 2.102.0 / 2.115.0，`x-rpc-device_name` | `GAME_RECORD` profile：`client_type=5`、X4、tool_verison、page；UA 为 2.104.0，无 `device_name` | 基本一致；UA 版本和 `device_name` 有差异；运行时未采集 |
| 原神 / 星铁养成计算 | TeyvatGuide `takumiReq.ts` | `client_type=5`，DS X4，`x-rpc-cal_type=0`，完整 Cookie，Referer `webstatic` | `CALCULATE` profile 与参考值一致，UA 为 2.104.0 | 基本一致；UA 版本有差异；运行时未采集 |
| BBS 账号详情、角色、战绩卡片 | `mihoyo_apis.md` 历史抓包（BBS 账号详情 / 战绩卡片） vs TeyvatGuide `recordReq.ts`、PizzaHelperUnited `UserGameRolesAPI.swift` | 历史抓包：`client_type=1`、DS、Referer `app.mihoyo.com`、UA `Hyperion/547`、Cookie `stoken/mid`；TeyvatGuide / Pizza：`client_type=5`、DS X4、Referer `webstatic`、Cookie `ltoken/account_id` | `BBS` profile：`client_type=1`、DS v2（当前 `salt_v2`）、Referer `app.mihoyo.com`、完整 Cookie、UA 2.104.0 | 参考有分歧；当前保留历史 App 变体；P0-07 / P0-08 / P0-09 运行时必测 |
| 手机号验证码 / 登录 | TeyvatGuide `passportReq.ts` | `x-rpc-app_id=bll8iq97cem8`，`client_type=2`，`app_version=2.115.0`，Android UA，Referer `user.miyoushe.com`，设备字段 | 当前手写 header 与参考值一致 | 一致；运行时未采集 |
| stoken 换 ltoken / cookie_token | TeyvatGuide `passportReq.ts`；PizzaHelperUnited | ltoken：`client_type=5`；cookie_token：TeyvatGuide 默认 `2`，Pizza 当前用 `5`；DS X4，Cookie `mid/stoken`，Referer `webstatic` | 两种换取都用 `client_type=5` + DS X4 | 部分分歧（cookie_token 的 client_type）；运行时未采集 |
| 二维码创建 / 轮询 | TeyvatGuide `passportReq.ts`（当前源码） vs PizzaHelperUnited | TeyvatGuide：`app_id=bll8iq97cem8`、UA `miHoYoBBS/2.115.0 Capture/2.2.0`、`client_type=3`、DS X4；Pizza：`app_id=ddxf5dufpuyo`、UA `HYPContainer/1.3.3.182`、`client_type=3`、无 DS | `QRCodeConfig.buildOptions()` 已切到 TeyvatGuide 变体 | 静态参考已对齐 TeyvatGuide；扫码 stoken 运行时未采集 |
| 大别野 / 游戏签到 | TeyvatGuide `lunaReq.ts`、`apiHubReq.ts` | DS X6，`client_type=2`，游戏签到 Referer `act.mihoyo.com` + `x-rpc-signgame`；大别野 Referer `app.mihoyo.com` | `SIGN` profile 与参考值一致；`getSignInfo` / `getSignReward` 的参数与参考不同，且当前无业务调用方 | header 一致；参数和调用链未验证 |
| 绝区零战绩 raw header | ZZZure/ZZZ-Plugin（三个指定项目未覆盖） | `app_version=2.73.1`，`client_type=2`，Android WebView UA，DS X4，Referer `act.mihoyo.com` | `ZZZRecordRequest` 与 ZZZ-Plugin 一致 | 与 ZZZ-Plugin 一致；P0-21 / P0-23 / P0-24 / P0-25 运行时未采集 |
| 绝区零 Widget / 养成计算 | PizzaHelperUnited `NoteAPI4ZZZ.swift`；TeyvatGuide / ZZZ-Plugin | Widget：`buildPizza` + X4 + WidgetExtension UA；养成计算：无 DS、`x-rpc-cultivate_source=bbs` | 当前与参考一致 | 基本一致；运行时未采集 |

#### 2.2.2 Retcode 静态对照

| retcode | 参考结论 | 当前实现 | 静态结论 |
| --- | --- | --- | --- |
| `0` | 成功 | `MihoyoRetcode.SUCCESS`；统一用 `RetcodeRegistry.isSuccess()` 判断 | 一致 |
| `-100` / `10001` / `-111` | Cookie 失效，需要重新登录（PizzaHelperUnited、TeyvatGuide、`mihoyo-api-collect`） | `RetcodeKind.AUTH_EXPIRED`；`ApiErrorHandler` 抛 `AuthExpiredError`，`BBSRepository` 尝试刷新 | 一致；`-111` 来自 `mihoyo-api-collect` |
| `-10001` | 请求无效 / header / DS 错误，不是登录失效（`mihoyo-api-collect`；Pizza 不映射为 relogin） | `RetcodeKind.INVALID_REQUEST`；不刷新 Cookie、不弹登录过期 | 一致；`-100` 与 `-10001` 精确区分 |
| `1034` / `10035` | Geetest 验证 | `RetcodeKind.VERIFICATION_REQUIRED`；`GeetestReporter` + Repository 降级 / 上报；ZZZ 战绩按 `10035` 走专用接口 | 一致 |
| `5003` / `10041` | 设备指纹无效 / 账号异常 | `RetcodeKind.FINGERPRINT_INVALID`；`FingerprintReporter` 统一上报；`SyncQueueRunner` 归为 `fingerprint` failure；`ApiErrorHandler` 仍按普通错误抛出 | 上报和队列一致；错误类型保持现状 |
| `10102` | 战绩数据可见性不足 / 角色未公开 | `MihoyoRetcode.ROLE_NOT_PUBLIC` / `RetcodeKind.ROLE_NOT_PUBLIC` | 一致 |
| `10307` | 服务器维护（PizzaHelperUnited 有专门映射） | `MihoyoRetcode.MAINTENANCE` / `RetcodeKind.MAINTENANCE`；当前仍按普通错误展示 | 已登记；UI 专用提示待后续接入 |
| `-1002` | 游戏账号未绑定 Cookie 对应账号（`mihoyo-api-collect`） | `MihoyoRetcode.ACCOUNT_NOT_FOUND` / `RetcodeKind.ACCOUNT_NOT_FOUND`，当前无调用方 | 值正确；不是 `1008`，也不是登录失效 |
| `1008` | 用户信息不匹配（例如无效 `role_id` / UID） | `MihoyoRetcode.USER_INFO_MISMATCH`，归为参数错误 | 已映射；不能当成“账号不存在” |
| `-106` | 二维码已过期（`mihoyo-api-collect`） | `MihoyoRetcode.QR_EXPIRED`；`AuthRepository` 用 `RetcodeRegistry.isQrExpired()` 转成 `expired` 状态 | 已使用 |
| `-110` / `-502` / `1002` | 限流 / 服务端异常 | `RATE_LIMITED` / `SERVER_ERROR`；提供 `isRetryable()` | 已登记；是否重试仍由调用方决定 |
| `-1` / `-101` / `1000` | 参数错误 | `INVALID_PARAM` 系列 | 已登记 |
| `-3208` | 短信 / 登录验证码错误或过期 | `MihoyoRetcode.CAPTCHA_INVALID` | 已登记 |
| `403` | HTTP 403 + 地区限制 message（PizzaHelperUnited） | `MihoyoRetcode.HTTP_REGION_RESTRICTED` + `RetcodeRegistry.isRegionRestricted()` | 语义已登记；当前无调用方 |

> 结论：`MihoyoRetcode` 是唯一数字来源，`RetcodeRegistry` 是唯一语义/处理说明来源；`ApiErrorCodes` 仅作为旧 import 的 deprecated 转发层。`MihoyoApiService` 只通过 `RetcodeRegistry` 做成功判断和 Geetest / 指纹上报分派，不再硬编码码值；具体业务错误仍由 Repository 转换。静态参考未发现 `-10001` 被误判为登录失效。

---

## 3. 登录 / Passport（P0）

| ID | API（方法 + 路径） | 调用点 / App 触发入口 | 当前 header / transport | HTTP | retcode | 最终 header 摘要（脱敏） | 上报 | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P0-01 | `POST /account/ma-cn-verifier/verifier/createLoginCaptcha` | `MihoyoAccountApiService.createLoginCaptcha`；登录页输入手机号发送验证码 | Passport 手写 header：`Content-Type`、`x-rpc-app_id`、`app_version`、`client_type`、设备字段、UA、Referer | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-02 | `POST /account/ma-cn-passport/app/loginByMobileCaptcha` | `MihoyoAccountApiService.loginByMobileCaptcha`；登录页提交验证码 | Passport 手写 header；service 路径为 `application/json` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-03 | `GET /account/auth/api/getLTokenBySToken` | `MihoyoAccountApiService.getLTokenBySToken`；手机号/二维码登录后换取 ltoken | 手写 header + Cookie(`mid`,`stoken`) + DS X4 | 待填 | 待填 | 待填 | 待填 | 参考有分歧；运行时未采集 |
| P0-04 | `GET /account/auth/api/getCookieAccountInfoBySToken` | `MihoyoAccountApiService.getCookieTokenBySToken`；同上换取 cookie_token | 手写 header + Cookie(`mid`,`stoken`) + DS X4 | 待填 | 待填 | 待填 | 待填 | 参考有分歧；运行时未采集 |
| P0-05 | `POST /account/ma-cn-passport/app/createQRLogin` | `MihoyoAccountApiService.fetchQRCode` / `AuthRepository.fetchQRCode`；登录页二维码 | `QRCodeConfig`：TeyvatGuide 变体（`bll8iq97cem8`、Capture UA、`client_type=3`、X4 DS、设备字段） | 待填 | 待填 | 待填 | 待填 | 静态参考已对齐（TeyvatGuide）；运行时未采集 |
| P0-06 | `POST /account/ma-cn-passport/app/queryQRLoginStatus` | `MihoyoAccountApiService.queryQRCode` / `AuthRepository.queryQRCode`；二维码轮询 | 同 P0-05，POST body `{ticket}` | 待填 | 待填 | 待填 | 待填 | 静态参考已对齐（TeyvatGuide）；运行时未采集 |

> 登录/Passport 不应触发 Geetest / 指纹上报；如果实际出现，单独记录。

---

## 4. BBS 账号 / 角色 / 战绩卡片（P0 + 旧路径 P1）

这三条原本要分别记录 **account service 新路径** 和 **旧 `NetworkFactory` 路径**；旧路径只有 Cookie + `HttpService` 默认 header，新路径是 BBS profile + DS v2。旧 transport 已于 2026-10-21 删除，P1-01 / P1-02 / P1-03 只能保留历史行，不能再补采；不要把新路径结果混成旧路径。

| ID | API（方法 + 路径） | 调用点 / App 触发入口 | 当前 header / transport | HTTP | retcode | 最终 header 摘要（脱敏） | 上报 | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P0-07 | `GET /binding/api/getUserGameRolesByCookie`（account service 新路径） | `BBSRepository.getUserGameRoles` 迁移后 → `MihoyoAccountApiService.getGameRoles`；首页/角色列表加载账号角色 | BBS profile + DS v2；当前旧路径见 P1-01 | 待填 | 待填 | 待填 | 待填 | 参考有分歧；运行时未采集 |
| P0-08 | `GET /game_record/app/card/wapi/getGameRecordCard`（account service 新路径） | `BBSRepository.getGameRecordCard` 迁移后 → account service；账号详情/战绩卡片 | BBS profile + DS v2；当前旧路径见 P1-02 | 待填 | 待填 | 待填 | 待填 | 参考有分歧；运行时未采集 |
| P0-09 | `GET /user/wapi/getUserFullInfo`（account service 新路径） | `BBSRepository.getBbsAccountDetail` service 分支；我的/账号详情 | BBS profile + DS v2；旧 fallback 见 P1-03 | 待填 | 待填 | 待填 | 待填 | 参考有分歧；运行时未采集 |
| P1-01 | `GET /binding/api/getUserGameRolesByCookie`（旧路径） | `BBSRepository.getUserGameRoles`；**登录 `BBSRepository.login` 会调用**（补充角色/回退），属于正常流程 | `NetworkFactory` + `HttpService` 默认 header + Cookie（无 DS） | 待填 | 待填 | 待填 | 待填 | 不可采集（旧路径已删除） |
| P1-02 | `GET /game_record/app/card/wapi/getGameRecordCard`（旧路径） | `BBSRepository.getGameRecordCard`；**登录 `BBSRepository.login` 首先调用**，属于正常流程 | `NetworkFactory` + Cookie（无 DS，SDK 标注 DS 必填） | 待填 | 待填 | 待填 | 待填 | 不可采集（旧路径已删除） |
| P1-03 | `GET /user/wapi/getUserFullInfo`（旧路径） | `BBSRepository.getBbsAccountDetail` fallback；`accountService === null` 时 | `NetworkFactory` + Cookie；`uid` 为空时不传 `uid/gids`；无 DS | 待填 | 待填 | 待填 | 待填 | 不可采集（旧路径已删除） |

> P1-01 / P1-02 原本是登录正常流程（旧 `NetworkFactory`），P1-03 是 `accountService === null` 的 fallback；这些旧路径已删除，状态统一记为“不可采集（旧路径已删除）”。不要再为了补采恢复旧 transport。
>
> **当前代码现状（2026-10-21）**：`BBSRepository.getUserGameRoles` / `getGameRecordCard` 已切换到 `MihoyoAccountApiService`，`getBbsAccountDetail` 也不再走 fallback；`BBSRepository.login` 现在走 account service 新路径。P0-07 / P0-08 / P0-09 的新路径仍可在任务完成后补采。

---

## 5. 原神（P0）

| ID | API（方法 + 路径） | 调用点 / App 触发入口 | 当前 header / transport | HTTP | retcode | 最终 header 摘要（脱敏） | 上报 | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P0-10 | `GET /game_record/app/genshin/api/dailyNote` | `GenshinApiService.getDailyNote`；首页便笺 | `buildPizza` + DS X4 + `hk4e_cn` 游戏指纹 + `suppressGeetestReport=true` | 待填 | 待填 | 待填 | suppressed / repository 后置 | 参考有分歧；运行时未采集 |
| P0-11 | `GET /game_record/app/genshin/aapi/widget/v2` | `GenshinApiService.getDailyNoteWidget`；Widget 刷新 | `buildPizza` + DS X4 + 游戏指纹；Widget 入口 Cookie 可能为完整 Cookie | 待填 | 待填 | 待填 | suppressed | 参考有分歧；运行时未采集 |
| P0-12 | `POST /game_record/app/genshin/api/character/list` | `GenshinApiService.getCharacterList`；角色页 | GAME_RECORD profile + DS X4 + `x-rpc-tool_verison` + `x-rpc-page` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-13 | `POST /game_record/app/genshin/api/character/detail` | `GenshinApiService.getCharacterDetail`；角色详情 | GAME_RECORD + DS X4 + `x-rpc-page` 带 avatarId | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-14 | `POST /event/e20200928calculate/v3/batch_compute` | `GenshinApiService.batchCompute`；养成计算 | CALCULATE profile + 完整 Cookie + DS X4 + `x-rpc-cal_type=0` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-15 | `POST /event/e20200928calculate/v1/sync/avatar/list` | `GenshinApiService.syncCalcAvatarList`；养成计算前同步角色 | CALCULATE profile + 完整 Cookie + DS X4；不带 `x-rpc-cal_type` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |

> P0-10 如果自然触发 1034 / 10035，记录 `x-rpc-challenge*` 是否存在；不要在正常账号上刻意刷请求。

---

## 6. 星铁（P0）

| ID | API（方法 + 路径） | 调用点 / App 触发入口 | 当前 header / transport | HTTP | retcode | 最终 header 摘要（脱敏） | 上报 | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P0-16 | `GET /game_record/app/hkrpg/api/note` | `StarRailApiService.getDailyNote`；首页便笺 | `buildPizza` + DS X4 + `hkrpg_cn` 指纹 + `suppressGeetestReport=true` | 待填 | 待填 | 待填 | suppressed / repository 后置 | 参考有分歧；运行时未采集 |
| P0-17 | `GET /game_record/app/hkrpg/aapi/widget` | `StarRailApiService.getDailyNoteWidget`；Widget 刷新 | `buildPizza` + `WidgetExtension/434` UA + DS X4 | 待填 | 待填 | 待填 | suppressed | 参考有分歧；运行时未采集 |
| P0-18 | `GET /game_record/app/hkrpg/api/avatar/basic` | `StarRailApiService.getAvatarBasic`；角色页 | GAME_RECORD + DS X4 + `x-rpc-page` / `platform` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-19 | `GET /game_record/app/hkrpg/api/avatar/info` | `StarRailApiService.getAvatarInfo`；角色详情 | GAME_RECORD + DS X4 + `x-rpc-page` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-20 | `POST /event/rpgcalc/compute?game=hkrpg` | `StarRailApiService.compute`；养成计算 | CALCULATE + DS X4；Referer/Origin 覆盖为 `webstatic.mihoyo.com` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |

---

## 7. 绝区零（P0）

| ID | API（方法 + 路径） | 调用点 / App 触发入口 | 当前 header / transport | HTTP | retcode | 最终 header 摘要（脱敏） | 上报 | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P0-21 | `GET /event/game_record_zzz/api/zzz/note` | `ZZZApiService.getDailyNote`；首页便笺 | `ZZZRecordRequest` raw header：`app_version=2.73.1`、`client_type=2`、Android WebView UA、`bbs_cn` 指纹、DS X4、`suppressGeetestReport=true` | 待填 | 待填 | 待填 | suppressed / repository 后置 | 静态参考已核对；运行时未采集 |
| P0-22 | `GET /event/game_record_zzz/api/zzz/widget` | `ZZZApiService.getDailyNoteWidget`；Widget 刷新 | `buildPizza` + `nap_cn` 指纹 + `WidgetExtension/434` UA + DS X4 | 待填 | 待填 | 待填 | suppressed | 静态参考已核对；运行时未采集 |
| P0-23 | `GET /event/game_record_zzz/api/zzz/avatar/basic` | `ZZZApiService.getAvatarBasic`；角色页 | `ZZZRecordRequest` raw header + DS X4 | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-24 | `GET /event/game_record_zzz/api/zzz/avatar/info` | `ZZZApiService.getAvatarInfo`；角色详情 | raw header + DS X4；`id_list[]` 追加 query 不参与 DS | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-25 | `GET /event/game_record_zzz/api/zzz/buddy/info` | `ZZZApiService.getBuddyList`；邦布列表 | raw header + DS X4 | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-26 | `POST /event/nap_cultivate_tool/avatar_calc?uid=&region=` | `ZZZApiService.compute`；养成计算 | ZZZ_GAME_RECORD + **无 DS** + `x-rpc-cultivate_source=bbs` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |

---

## 8. 签到（P0）

| ID | API（方法 + 路径） | 调用点 / App 触发入口 | 当前 header / transport | HTTP | retcode | 最终 header 摘要（脱敏） | 上报 | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P0-27 | `POST /apihub/app/api/signIn` | `SignApiService.signBBS`；大别野签到 | SIGN profile + DS X6 + `client_type=2` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-28 | `POST /event/luna/{host}/sign` | `SignApiService.signGame`；游戏签到，`host=hk4e/hkrpg/zzz` | SIGN + DS X6 + `x-rpc-signgame`（每游戏不同） | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-29 | `GET /event/luna/{host}/info` | `SignApiService.getSignInfo`；签到状态 | SIGN + DS X6 + `x-rpc-signgame` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P0-30 | `GET /event/luna/{host}/home` | `SignApiService.getSignReward`；签到奖励 | SIGN + DS X6 + `x-rpc-signgame` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |

> P0-28 ~ P0-30 每个 game host 各抓一次；如果只抓一个，必须在备注写“仅 hk4e，hkrpg/zzz 未覆盖”。

---

## 9. 设备指纹 / Geetest / ZZZ 风险接口（P1）

| ID | API（方法 + 路径） | 调用点 / App 触发入口 | 当前 header / transport | HTTP | retcode | 最终 header 摘要（脱敏） | 上报 | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1-04 | `POST /device-fp/api/getFp`（`app_name=account_cn`） | `DeviceFpService.fetchFromApi`；首次启动/登录/重新生成指纹 | 仅 `Content-Type: application/json`；无 DS、无 Cookie | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P1-05 | `POST /device-fp/api/getFp`（`app_name=hk4e_cn/hkrpg_cn/nap_cn`） | `DeviceFpService.fetchGameFpFromApi`；重新生成全部指纹 | 仅 `Content-Type`；body 为 iOS ext_fields | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P1-06 | `POST /device-fp/api/getFp`（`app_name=bbs_cn`） | `ZZZRecordRequest.fetchFp`；首次绝区零请求/指纹过期 | ZZZ raw header（Referer act、Android WebView UA）；body `app_name=bbs_cn`、`platform=2` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P1-07 | `GET /game_record/app/card/wapi/createVerification` | `GeetestService.createVerification`；1034 / 非 ZZZ 10035 | TAKUMI_RECORD + Cookie + `x-rpc-challenge_path/game` + DS X4 | 待填 | 待填 | 待填 | 待填（当前未 suppress） | 静态参考已核对；运行时未采集 |
| P1-08 | `POST /game_record/app/card/wapi/verifyVerification` | `GeetestService.verifyVerification`；提交 Geetest 结果 | 同 P1-07 + body `geetest_*` | 待填 | 待填 | 待填 | 待填（当前未 suppress） | 静态参考已核对；运行时未采集 |
| P1-09 | `GET /event/toolcomsrv/risk/createGeetest` | `ZZZRecordRequest.createGeetest`；ZZZ `retcode=10035` | TAKUMI + `app_key=game_record_zzz` + `x-rpc-challenge_game=8` | 待填 | 待填 | 待填 | suppressed | 静态参考已核对；运行时未采集 |
| P1-10 | `POST /event/toolcomsrv/risk/verifyGeetest` | `ZZZRecordRequest.verifyGeetest`；ZZZ 10035 验证 | TAKUMI + ZZZ Geetest header（`client_type=5`、`x-rpc-device_fp`、`x-rpc-challenge_game=8`）+ DS X4 | 待填 | 待填 | 待填 | suppressed | 静态参考已核对；运行时未采集 |
| P1-14 | `POST /apihub/api/deviceLogin`、`POST /apihub/api/saveDevice` | `ZZZRecordRequest.registerDevice`；申请 ZZZ 指纹后登记设备（首次绝区零请求会走） | BBS + Cookie + DS X4 + `content-type` | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |

> P1-07 ~ P1-10 只有在真实触发 1034 / 10035 时才容易抓到；不要为了采集对主账号高频刷请求。抓不到时写“未覆盖”。
>
> **注意**：P1-07 / P1-08 当前 `GeetestService` 没有设置 `suppressGeetestReport`，迁移后也没有调用 `reportBusinessError`，因此这两个自调用不再触发上报，避免验证递归。后续记录时按实际行为填写，不要把“旧 HttpClient 可能自动上报”写成现状。

---

## 10. 旧 fallback / 未使用变体（P1 / P2）

| ID | API（方法 + 路径） | 调用点 / App 触发入口 | 当前 header / transport | HTTP | retcode | 最终 header 摘要（脱敏） | 上报 | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1-11 | 登录 P0-01/P0-02 的 `AuthRepository` fallback | `AuthRepository` 在 `accountService === null` 时；普通 App 流程不触发 | 手写 header 但字段少于 service；`loginByMobileCaptcha` 使用 `text/plain` | 待填 | 待填 | 待填 | 待填 | 不可采集（旧路径已删除） |
| P1-12 | P0-03/P0-04 的 `AuthRepository` fallback（`getLTokenBySToken` / `getCookieBySToken`） | `accountService === null`；普通 App 流程在初始化完成后不触发 | 旧路径 `NetworkFactory` + `Cookie: mid=...;stoken=...` + `client_type=web` + Referer；无 DS，缺少 service 的 app_version / device 字段；UA 由 HttpService 默认头补 | 待填 | 待填 | 待填 | 待填 | 不可采集（旧路径已删除） |
| P1-13 | `GET /account/auth/api/getLTokenBySToken`（`getLTokenBySTokenLegacy`） | 无调用方；只能手动调用 | 旧路径 `NetworkFactory` + `Cookie: stoken=...;stuid=...`（不是 service 的 `mid` + `stoken`）；无 DS | 待填 | 待填 | 待填 | 待填 | 不可采集（旧路径已删除） |
| P2-01 | `POST /account/ma-cn-session/app/verify` | `MihoyoAccountApiService.verifyLToken`；当前无业务调用方 | 仅空 header / 默认 transport | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P2-02 | `GET/POST /game_record/app/card/wapi/createVerification`、`verifyVerification` 的 BBS 域名变体 | `MihoyoAccountApiService.createVerification` / `verifyVerification`；当前无业务调用方 | BBS profile + DS v2 | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |
| P2-03 | P0-03/P0-04 的 `refreshLToken` / `refreshCookieToken` 变体 | `MihoyoAccountApiService.refreshLToken` / `refreshCookieToken`；当前无业务调用方 | 仅 params(`stoken`,`uid`)，无显式 header / 无 DS | 待填 | 待填 | 待填 | 待填 | 静态参考已核对；运行时未采集 |

> 2026-10-21：`AuthRepository` 的旧 fallback 和 `getLTokenBySTokenLegacy` 已删除，P1-11 / P1-12 / P1-13 状态已改为“不可采集（旧路径已删除）”；保留行仅作历史对照。不要为了采集恢复旧 transport。

---

## 11. 每条记录的详细模板

需要更完整 header 时，在对应 ID 下复制以下模板（不要把值写进表格单元格）：

```text
ID:
采集时间 / 环境（debug / internal / release）:
App 版本 / API 入口:
HTTP status:
retcode / message:
最终 header 键（按实际顺序，大小写保持）:
关键值（只写安全值）:
  Content-Type:
  User-Agent:
  Referer / Origin:
  x-rpc-app_version / client_type:
  x-rpc-tool_verison / page / platform:
  x-rpc-signgame / cal_type / cultivate_source:
  x-rpc-challenge*:
  x-rpc-device_fp / device_id（只写 present / masked）:
Cookie 字段名:
DS: absent / v1 / v2 / x4 / x6
上报: none / geetest / fingerprint / suppressed
是否弹框 / 是否重放:
备注:
```

---

## 12. 完成标准

- [x] 已完成 `mihoyo-api-sdk`、TeyvatGuide、PizzaHelperUnited 三个项目的静态 header / retcode 对照，并记录在本文件 §2.2；历史 App 抓包作为 BBS 变体证据
- [ ] P0-01 ~ P0-30 全部有运行时记录，或明确标注“未覆盖 + 原因”；按用户决定延后，BBS 新路径在任务完成后补采
- [ ] §2.2 中标为“参考有分歧”的链路（二维码、BBS 三个接口、stoken 换 cookie_token、便笺 header）在真机 / 代理中确认
- [ ] 至少包含一条 Cookie 失效 / 角色不存在 / HTTP 非 200 / 网络断开或超时 / Geetest（如自然触发）的错误分支记录
- [ ] P1-01 ~ P1-14 在任务完成后补采可触发的新路径，或明确标注“不可采集 / 未覆盖（旧路径已删除）”；P1-01/02/03/11/12/13 已标记为不可采集
- [ ] P2-01 ~ P2-03 可记录为“未覆盖 + 原因”，不要用推测值
- [ ] 每个游戏至少一条便笺、角色、养成计算、签到记录
- [ ] BBS 三个接口的新旧路径分别记录，未混为一条；新路径在任务完成后补采，旧路径已删除时标记“未覆盖（旧路径已删除）”
- [ ] 所有 `suppressGeetestReport` 接口记录实际是否上报
- [ ] 所有记录已脱敏；仓库中没有 HAR、Cookie、token、`device_fp`、`device_id`
- [ ] 与本文件配套的 `APIService.md` §4.6 / §4.7 状态一致

> 基线采集按用户决定延后到整个任务完成后；它仍是后续真实回归的必做项，但不阻塞当前代码迁移。§2.2 的静态结论只表示“与某个参考实现一致 / 不一致”；任何“运行时 header 已对齐”的结论仍必须有对应抓包记录，不能靠静态对照或推测。
