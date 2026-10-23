# 运行时验收清单（Runtime Acceptance Checklist）

> 状态：**待执行**
>
> 代码基线：`3ac32ee`（QR token flow + RowModels test fix）
>
> 适用环境：**UAT / 真实 API**；真机优先，模拟器只能作为补充。Mock 只验证路由和错误处理，不能替代真实服务端验收。
>
> 关联文档：[`API-Baseline.md`](API-Baseline.md)、[`Known-Issues.md`](Known-Issues.md)、[`APIService.md`](APIService.md)

---

## 0. 怎么使用这份文档

1. 先填第 1 节的环境信息；不确定的项目留空，不要猜。
2. 按第 3 节的顺序测试，尽量不要跳着测，减少重复登录和重复清数据。
3. 每完成一项：
   - **通过**：把 `[ ]` 改成 `[x]`，并在“实测 / 证据”里填关键结果。
   - **失败**：保持 `[ ]`，在“实测 / 证据”里写实际现象、HTTP、retcode、message。
   - **不适用**：写成 `[x] N/A`，并在备注里说明原因。
4. 只有实际验证过才打勾；没测的项目不要打勾。
5. 所有 Cookie、token、`device_fp`、`device_id`、完整 HAR 都必须脱敏，不能提交到仓库。
6. 全部测完后填第 6 节，把文档发回；失败项附时间、API、HTTP、retcode、message、截图或抓包编号。

### 判定“通过”的最低标准

一个接口不能只看 HTTP 200，至少同时满足：

- HTTP 200；
- `retcode` 为 0，或属于该接口预期的业务状态（例如“今天已签到”）；
- 返回数据属于当前测试账号，字段和米游社 App 一致；
- 不出现 `-100` / Cookie 失效 / 空 `ltoken` / 空 `cookie_token`；
- App 不崩溃，数据库不被写坏；
- 失败时能给出正确提示，而不是静默成功。

> 二维码登录是本次重点：**登录成功不等于通过**，必须继续验证换到的 `ltoken` 能被 BBS / 米游社接口接受。

---

## 1. 环境记录（测试者填写）

| 项目 | 填写 |
| --- | --- |
| 测试日期 | |
| 测试人 | |
| 设备型号 | |
| 系统版本 | |
| App 版本 / build 号 | |
| Bundle ID | |
| 运行环境 | UAT / Mock / Release（圈选） |
| 构建 commit | |
| 安装包路径 | |
| 测试账号 UID（脱敏） | |
| 米游社 App 版本（扫码用） | |
| 代理工具 | Proxyman / Charles / 无 |
| 网络环境 | Wi-Fi / 蜂窝 |
| 是否使用测试账号 | 是 / 否 |
| 备注 | |

---

## 2. 前置检查

- [ ] 已安装可用的签名包；真机二维码验收优先使用 UAT，不使用关闭日志的 release 包
- [ ] 已记录构建 commit、版本号和安装包路径
- [ ] 已准备测试账号，避免用主账号做签到、同步等写操作
- [ ] 已退出旧账号，或确认当前账号就是要测试的账号
- [ ] 已清空 App 日志，方便定位失败
- [ ] 如需抓包：代理证书已安装并信任，HTTPS 抓包可用
- [ ] 二维码测试：第二台设备已安装米游社 App，并登录要测试的账号
- [ ] 已确认当前自动化基线：`bash test-core.sh` 构建通过，模拟器测试 226/226（代码未改可跳过）
- [ ] 已确认失败时不会把完整 Cookie / token 写进文档

> UAT / Mock 签名材料未配置时，先解决签名；不要用 unsigned HAP，也不要用关闭日志 / 抓包的 release 包代替 UAT 做运行时验收。

---

## 3. 建议执行顺序

1. 二维码登录
2. 二维码登录后的 BBS 账号 / 角色 / 战绩
3. 首页便笺与 Widget
4. 三游戏角色列表 / 详情 / 养成计算
5. 签到
6. 杀进程重启 / 冷启动
7. 手机号登录（有测试手机号时）
8. Cookie 过期刷新
9. 错误路径（二维码过期、取消、断网、无效 Cookie）

---

## 4. 手工验收

### 4.1 二维码登录（P0，本次重点）

**操作步骤**

1. 打开登录页，切到二维码 Tab，等待二维码出现。
2. 用第二台设备的米游社 App 扫码，并确认登录。
3. 观察 App 是否自动登录成功，是否回到首页或账号页。
4. 查看 App 日志，确认扫码确认后依次出现：
   - `getLTokenBySToken`
   - `getCookieAccountInfoBySToken`
5. 进入“我的 / 账号详情”，确认账号 UID、昵称、头像正确。
6. 进入角色列表、战绩卡片，确认数据属于当前账号。
7. 如果测试账号当天未签到，执行一次签到；已签到则记录“已签到”业务状态。
8. 杀掉 App 进程，重新打开，确认仍然登录。
9. 再测一次二维码过期或取消扫码，确认 UI 能恢复，不崩溃。

**检查项**

| # | 检查项 | 预期 | 实测 / 证据 | 通过 |
| --- | --- | --- | --- | --- |
| A1 | 创建二维码 | `createQRLogin` HTTP 200、retcode 0，返回 URL 和 ticket | | [ ] |
| A2 | 轮询扫码状态 | `queryQRLoginStatus` 最终返回 confirmed，包含 stoken 和 user_info | | [ ] |
| A3 | 换取 ltoken | `getLTokenBySToken` HTTP 200、retcode 0，`ltoken` 非空 | | [ ] |
| A4 | 换取 cookie_token | `getCookieAccountInfoBySToken` HTTP 200、retcode 0，`cookie_token` 非空 | | [ ] |
| A5 | Cookie 持久化 | Cookie 中 `stoken`、`ltoken`、`cookie_token`、`mid`、`ltuid`、`account_id` 均非空 | | [ ] |
| A6 | 账号信息 | `getUserFullInfo` retcode 0，UID / 昵称与测试账号一致 | | [ ] |
| A7 | 角色列表 | `getUserGameRolesByCookie` retcode 0，角色列表正确 | | [ ] |
| A8 | 战绩卡片 | `getGameRecordCard` retcode 0，卡片数据正确 | | [ ] |
| A9 | 签到 | 签到成功，或返回“今天已签到”等预期业务状态 | | [ ] |
| A10 | 重启 / 冷启动 | 杀进程重开后仍保持登录，不要求重新扫码 | | [ ] |
| A11 | 二维码过期 / 取消 | UI 提示正确，可刷新二维码，不崩溃 | | [ ] |
| A12 | QR header 抓包 | 关键 header 与第 4.2 节一致 | | [ ] |

> A9 如果当天已经签到，记录服务端返回的“已签到”信息即可，不要为了测试重复刷签到接口。

### 4.2 二维码关键 header 核对（抓包时填写）

只记录脱敏后的摘要，不要写完整 Cookie / DS / device_fp。没有抓包时，本节和 A12 留空或记 `N/A`，不要根据代码猜实际值。

| 项目 | 期望 | 实测 |
| --- | --- | --- |
| `createQRLogin` 路径 | `/account/ma-cn-passport/app/createQRLogin` | |
| `queryQRLoginStatus` 路径 | `/account/ma-cn-passport/app/queryQRLoginStatus` | |
| `x-rpc-app_id` | `bll8iq97cem8` | |
| `User-Agent` | 包含 `miHoYoBBS/2.115.0 Capture/2.2.0` | |
| `x-rpc-client_type` | `3` | |
| `x-rpc-game_biz` | `bbs_cn` | |
| `x-rpc-app_version` | `2.115.0` | |
| `x-rpc-sdk_version` | `2.115.0` | |
| `x-rpc-account_version` | `2.115.0` | |
| `x-rpc-device_id` | 非空 | |
| `x-rpc-device_fp` | 非空 | |
| `DS` | X4 格式，存在且非空 | |
| `content-type` | `application/json` | |
| `getLTokenBySToken` Cookie | 同时包含 `mid` 和 `stoken` | |
| `getLTokenBySToken` `x-rpc-client_type` | `5` | |
| `getLTokenBySToken` `DS` | X4 格式 | |

### 4.3 BBS 账号 / 角色 / 战绩（P0）

| # | 检查项 | 预期 | 实测 / 证据 | 通过 |
| --- | --- | --- | --- | --- |
| B1 | 账号详情 | `getUserFullInfo` 数据正确，不返回 `-100` | | [ ] |
| B2 | 游戏角色 | `getUserGameRolesByCookie` 返回当前账号角色，没有串号 | | [ ] |
| B3 | 战绩卡片 | `getGameRecordCard` 返回正确 UID / 游戏 / 等级信息 | | [ ] |
| B4 | Cookie 刷新后 BBS | 如果发生 `-100`，刷新后重试成功 | | [ ] |

### 4.4 首页便笺 / Widget

| # | 游戏 | 检查项 | 预期 | 实测 / 证据 | 通过 |
| --- | --- | --- | --- | --- | --- |
| C1 | 原神 | 首页便笺 | `dailyNote` retcode 0，树脂 / 委托 / 派遣数据正确 | | [ ] |
| C2 | 原神 | Widget | Widget 能显示便笺，刷新后数据更新 | | [ ] |
| C3 | 星铁 | 首页便笺 | `note` retcode 0，体力 / 派遣数据正确 | | [ ] |
| C4 | 星铁 | Widget | Widget 能显示便笺，刷新后数据更新 | | [ ] |
| C5 | 绝区零 | 首页便笺 | `zzz/note` retcode 0，电量 / 活跃度数据正确 | | [ ] |
| C6 | 绝区零 | Widget | Widget 能显示便笺，刷新后数据更新 | | [ ] |

> 没有添加 Widget 时，C2 / C4 / C6 记 `N/A`，不要直接判失败。

### 4.5 角色列表 / 详情 / 养成计算

| # | 游戏 | 检查项 | 预期 | 实测 / 证据 | 通过 |
| --- | --- | --- | --- | --- | --- |
| D1 | 原神 | 角色列表 | 角色数量、等级、命座、武器与米游社一致 | | [ ] |
| D2 | 原神 | 角色详情 | 详情页能打开，天赋 / 圣遗物 / 武器数据正确 | | [ ] |
| D3 | 原神 | 养成计算 | 计算结果能生成，不崩溃 | | [ ] |
| D4 | 星铁 | 角色列表 | 角色数量、等级、星魂、光锥正确 | | [ ] |
| D5 | 星铁 | 角色详情 | 详情页能打开，行迹 / 遗器数据正确 | | [ ] |
| D6 | 星铁 | 养成计算 | 计算结果能生成，不崩溃 | | [ ] |
| D7 | 绝区零 | 角色列表 | 代理人 / 邦布数据正确 | | [ ] |
| D8 | 绝区零 | 角色详情 | 详情页能打开，技能 / 驱动盘数据正确 | | [ ] |
| D9 | 绝区零 | 养成计算 | 计算结果能生成，不崩溃 | | [ ] |

> 没有某个游戏的角色时，对应项记 `N/A`，并在备注说明“账号无该游戏角色”。

### 4.6 签到

| # | 检查项 | 预期 | 实测 / 证据 | 通过 |
| --- | --- | --- | --- | --- |
| E1 | 大别野签到 | `signIn` 成功，或返回“今天已签到” | | [ ] |
| E2 | 原神签到 | `luna/hk4e/sign` 成功，或“今天已签到” | | [ ] |
| E3 | 星铁签到 | `luna/hkrpg/sign` 成功，或“今天已签到” | | [ ] |
| E4 | 绝区零签到 | `luna/zzz/sign` 成功，或“今天已签到” | | [ ] |
| E5 | 签到状态 | `luna/{host}/info` 状态与实际一致 | | [ ] |
| E6 | 签到奖励 | `luna/{host}/home` 奖励信息能显示 | | [ ] |

> 每个游戏 host 各测一次；如果只测了原神，必须在备注写“仅 hk4e，hkrpg / zzz 未覆盖”。

### 4.7 杀进程 / 冷启动

| # | 检查项 | 预期 | 实测 / 证据 | 通过 |
| --- | --- | --- | --- | --- |
| F1 | 杀进程重开 | 账号仍在，不需要重新扫码 / 登录 | | [ ] |
| F2 | 冷启动 Cookie 检查 | 不误报过期，不把有效账号清掉 | | [ ] |
| F3 | 冷启动刷新 | 需要刷新时能自动换 ltoken / cookie_token | | [ ] |

### 4.8 手机号登录（有测试手机号时）

没有可用测试手机号时，本节全部记 `N/A`，不要用主账号反复收验证码。

| # | 检查项 | 预期 | 实测 / 证据 | 通过 |
| --- | --- | --- | --- | --- |
| G1 | 发送验证码 | `createLoginCaptcha` retcode 0 | | [ ] |
| G2 | 提交验证码 | `loginByMobileCaptcha` retcode 0，返回 stoken / aid / mid | | [ ] |
| G3 | 换取 ltoken | `getLTokenBySToken` retcode 0，ltoken 非空 | | [ ] |
| G4 | 换取 cookie_token | `getCookieAccountInfoBySToken` retcode 0，cookie_token 非空 | | [ ] |
| G5 | 登录后 BBS | 账号 / 角色 / 战绩接口正常 | | [ ] |

### 4.9 Cookie 过期刷新

| # | 检查项 | 预期 | 实测 / 证据 | 通过 |
| --- | --- | --- | --- | --- |
| H1 | 触发 `-100` | 使用测试账号或等待自然过期，不修改生产账号 | | [ ] |
| H2 | 刷新 ltoken | 使用 stoken + mid 换取成功 | | [ ] |
| H3 | 刷新 cookie_token | 获取成功 | | [ ] |
| H4 | 写回数据库 | Cookie 更新，后续请求不再 `-100` | | [ ] |
| H5 | 无法刷新时 | 提示重新登录，不崩溃、不写坏账号 | | [ ] |

> 如果无法自然触发过期，H1 ~ H5 记 `N/A`，不要为了测试伪造或破坏生产 Cookie。

### 4.10 错误路径

| # | 检查项 | 预期 | 实测 / 证据 | 通过 |
| --- | --- | --- | --- | --- |
| I1 | 二维码过期 | 提示过期，可刷新，不崩溃 | | [ ] |
| I2 | 取消扫码 | 回到等待状态，不登录 | | [ ] |
| I3 | 断网 / 超时 | 提示网络错误，不崩溃 | | [ ] |
| I4 | 无效 Cookie | 返回 `-100` 后走刷新或提示重新登录 | | [ ] |
| I5 | HTTP 401 / 500 | 有明确错误提示，不写坏数据库 | | [ ] |
| I6 | Geetest 1034 / 10035 | 自然触发时能完成验证；未触发则记 N/A | | [ ] |

> 不要为了抓 Geetest 对主账号高频刷请求。

---

## 5. API 覆盖记录

> 预期统一为：HTTP 200、retcode 0、数据属于当前测试账号。  
> 已签到、未绑定角色、无 Widget 等业务状态在“结果 / 证据”说明，不要直接判失败。

### 5.1 Passport / 登录

| ID | API | 触发入口 | HTTP | retcode | 结果 / 证据 | 通过 |
| --- | --- | --- | --- | --- | --- | --- |
| P0-01 | `POST /account/ma-cn-verifier/verifier/createLoginCaptcha` | 登录页发送验证码 | | | | [ ] |
| P0-02 | `POST /account/ma-cn-passport/app/loginByMobileCaptcha` | 登录页提交验证码 | | | | [ ] |
| P0-03 | `GET /account/auth/api/getLTokenBySToken` | QR / 手机号登录后 | | | | [ ] |
| P0-04 | `GET /account/auth/api/getCookieAccountInfoBySToken` | QR / 手机号登录后 | | | | [ ] |
| P0-05 | `POST /account/ma-cn-passport/app/createQRLogin` | 登录页二维码 | | | | [ ] |
| P0-06 | `POST /account/ma-cn-passport/app/queryQRLoginStatus` | 二维码轮询 | | | | [ ] |

### 5.2 BBS 账号 / 角色 / 战绩

| ID | API | 触发入口 | HTTP | retcode | 结果 / 证据 | 通过 |
| --- | --- | --- | --- | --- | --- | --- |
| P0-07 | `GET /binding/api/getUserGameRolesByCookie` | 首页 / 角色列表 | | | | [ ] |
| P0-08 | `GET /game_record/app/card/wapi/getGameRecordCard` | 账号详情 / 战绩卡片 | | | | [ ] |
| P0-09 | `GET /user/wapi/getUserFullInfo` | 我的 / 账号详情 | | | | [ ] |

### 5.3 原神

| ID | API | 触发入口 | HTTP | retcode | 结果 / 证据 | 通过 |
| --- | --- | --- | --- | --- | --- | --- |
| P0-10 | `GET /game_record/app/genshin/api/dailyNote` | 首页便笺 | | | | [ ] |
| P0-11 | `GET /game_record/app/genshin/aapi/widget/v2` | 原神 Widget | | | | [ ] |
| P0-12 | `POST /game_record/app/genshin/api/character/list` | 角色页 | | | | [ ] |
| P0-13 | `POST /game_record/app/genshin/api/character/detail` | 角色详情 | | | | [ ] |
| P0-14 | `POST /event/e20200928calculate/v3/batch_compute` | 养成计算 | | | | [ ] |
| P0-15 | `POST /event/e20200928calculate/v1/sync/avatar/list` | 养成计算前同步角色 | | | | [ ] |

### 5.4 星铁

| ID | API | 触发入口 | HTTP | retcode | 结果 / 证据 | 通过 |
| --- | --- | --- | --- | --- | --- | --- |
| P0-16 | `GET /game_record/app/hkrpg/api/note` | 首页便笺 | | | | [ ] |
| P0-17 | `GET /game_record/app/hkrpg/aapi/widget` | 星铁 Widget | | | | [ ] |
| P0-18 | `GET /game_record/app/hkrpg/api/avatar/basic` | 角色页 | | | | [ ] |
| P0-19 | `GET /game_record/app/hkrpg/api/avatar/info` | 角色详情 | | | | [ ] |
| P0-20 | `POST /event/rpgcalc/compute?game=hkrpg` | 养成计算 | | | | [ ] |

### 5.5 绝区零

| ID | API | 触发入口 | HTTP | retcode | 结果 / 证据 | 通过 |
| --- | --- | --- | --- | --- | --- | --- |
| P0-21 | `GET /event/game_record_zzz/api/zzz/note` | 首页便笺 | | | | [ ] |
| P0-22 | `GET /event/game_record_zzz/api/zzz/widget` | 绝区零 Widget | | | | [ ] |
| P0-23 | `GET /event/game_record_zzz/api/zzz/avatar/basic` | 角色页 | | | | [ ] |
| P0-24 | `GET /event/game_record_zzz/api/zzz/avatar/info` | 角色详情 | | | | [ ] |
| P0-25 | `GET /event/game_record_zzz/api/zzz/buddy/info` | 邦布列表 | | | | [ ] |
| P0-26 | `POST /event/nap_cultivate_tool/avatar_calc?uid=&region=` | 养成计算 | | | | [ ] |

### 5.6 签到

| ID | API | 触发入口 | HTTP | retcode | 结果 / 证据 | 通过 |
| --- | --- | --- | --- | --- | --- | --- |
| P0-27 | `POST /apihub/app/api/signIn` | 大别野签到 | | | | [ ] |
| P0-28 | `POST /event/luna/{host}/sign` | 游戏签到，host=hk4e / hkrpg / zzz | | | | [ ] |
| P0-29 | `GET /event/luna/{host}/info` | 签到状态 | | | | [ ] |
| P0-30 | `GET /event/luna/{host}/home` | 签到奖励 | | | | [ ] |

### 5.7 P1 条件项

只在自然触发时记录；没有触发就记 `N/A`，不要为了采集高频刷请求。

| ID | API / 功能 | 触发条件 | HTTP | retcode | 结果 / 证据 | 通过 |
| --- | --- | --- | --- | --- | --- | --- |
| P1-04 | `POST /device-fp/api/getFp`（account_cn） | 首次启动 / 登录 / 重新生成指纹 | | | | [ ] |
| P1-05 | `POST /device-fp/api/getFp`（游戏指纹） | 重新生成全部指纹 | | | | [ ] |
| P1-06 | `POST /device-fp/api/getFp`（bbs_cn） | 首次绝区零请求 / 指纹过期 | | | | [ ] |
| P1-07 | `GET /game_record/app/card/wapi/createVerification` | 原神 / 星铁 1034 或 10035 | | | | [ ] |
| P1-08 | `POST /game_record/app/card/wapi/verifyVerification` | 提交 Geetest 结果 | | | | [ ] |
| P1-09 | `GET /event/toolcomsrv/risk/createGeetest` | 绝区零 10035 | | | | [ ] |
| P1-10 | `POST /event/toolcomsrv/risk/verifyGeetest` | 绝区零 Geetest 验证 | | | | [ ] |
| P1-14 | `POST /apihub/api/deviceLogin`、`POST /apihub/api/saveDevice` | 首次绝区零请求 / 设备登记 | | | | [ ] |

### 5.8 P2 无业务调用方

以下接口当前没有业务调用方，**不要为了“每个 API 都走一遍”手动调用**，直接记 `N/A`：

- [ ] `POST /account/ma-cn-session/app/verify`
- [ ] BBS 域名变体的 `createVerification` / `verifyVerification`
- [ ] `refreshLToken` / `refreshCookieToken` 变体

---

## 6. 验收总结（测试者填写）

### 6.1 统计

| 项目 | 数量 |
| --- | --- |
| P0 总项 | |
| 通过 | |
| 失败 | |
| N/A | |
| P1 已覆盖 | |
| P1 未覆盖 | |

### 6.2 关键结论

| 检查项 | 结果 |
| --- | --- |
| 二维码登录是否成功 | |
| `getLTokenBySToken` 是否返回非空 ltoken | |
| `getCookieAccountInfoBySToken` 是否返回非空 cookie_token | |
| BBS 账号 / 角色 / 战绩是否正常 | |
| 签到是否正常 | |
| 重启 / 冷启动是否保持登录 | |
| 是否存在 `-100` 未恢复 | |
| 是否有崩溃 / 数据库异常 | |

### 6.3 失败项记录

| # | 时间 | API / 页面 | HTTP | retcode | 现象 | 证据 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | | | | | | |
| 2 | | | | | | |
| 3 | | | | | | |

### 6.4 总体结论

- [ ] 通过：P0 全部通过，或 N/A 有合理说明；没有未解决的 P0 失败
- [ ] 有条件通过：P0 通过，但存在已记录的非阻塞问题
- [ ] 不通过：存在 P0 失败，或二维码 / ltoken / BBS 链路未打通

测试人签名：____________________  
日期：____________________

---

## 7. 回传说明

把填好的本文档发回即可。失败项请附：

- 操作时间；
- 页面 / API；
- HTTP 和 retcode；
- 服务端 message；
- 截图或 Proxyman 会话编号；
- 是否可稳定复现。

不要粘贴完整 Cookie、token、`device_fp`、`device_id` 或完整 HAR。

---

## 附录 A：命令参考

### A.1 自动化基线（代码未改可跳过）

```bash
bash test-core.sh
node scripts/check-architecture.mjs
hdc install -r entry/build/default/outputs/ohosTest/entry-ohosTest-signed.hap
hdc shell aa test -b com.cainluo.miyoyo.tools -m entry_test -s unittest OpenHarmonyTestRunner
```

预期：构建成功；架构检查 0 cycle；测试 226/226。

### A.2 手工 UAT 构建 / 安装

```bash
bash run.sh uat
```

> `run.sh uat` 需要 UAT 签名材料；签名未配置时会失败。真机二维码优先用真机，模拟器结果只能作为补充。  
> 如果使用代理，按 `run.sh` 的 `--proxy` 参数或设备系统代理设置执行；证书必须安装并信任。

