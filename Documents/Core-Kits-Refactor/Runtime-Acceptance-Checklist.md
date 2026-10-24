# 运行时验收清单

> 用法：
> - 测试通过后，把 `[ ]` 改成 `[x]`。
> - `Request Header` 和 `Response` 留空，测试后填入；只填脱敏摘要，完整内容可写抓包文件名。
> - 不适用写 `[x] N/A`；失败保持 `[ ]`，在 `Response` 里写现象。
> - 建议顺序：二维码 → BBS → 便笺 / Widget → 角色 / 计算 → 签到 → 重启 / 错误路径。

> 2026-10-24：真机 API 回归通过（第 1～28 项）；签到（第 29～33 项）功能未实现，暂不验收；第 34～39 项仍待测。Header / Response 未单独记录，后续需要用 Proxyman 补采。

## 1. 登录

| # | 测试点 | 通过 | Request Header | Response |
| --- | --- | --- | --- | --- |
| 1 | 创建二维码 `POST /account/ma-cn-passport/app/createQRLogin` | [x] | | |
| 2 | 轮询扫码状态 `POST /account/ma-cn-passport/app/queryQRLoginStatus` | [x] | | |
| 3 | stoken 换 ltoken `GET /account/auth/api/getLTokenBySToken` | [x] | | |
| 4 | stoken 换 cookie_token `GET /account/auth/api/getCookieAccountInfoBySToken` | [x] | | |
| 5 | 登录后 Cookie 完整（stoken / ltoken / cookie_token / mid） | [x] | | |
| 6 | 二维码请求 header 符合预期（app_id / UA / client_type / game_biz / DS） | [x] | | |
| 7 | 发送手机验证码 `POST /account/ma-cn-verifier/verifier/createLoginCaptcha` | [x] | | |
| 8 | 手机号登录 `POST /account/ma-cn-passport/app/loginByMobileCaptcha` | [x] | | |
| 9 | 手机号登录后 ltoken / cookie_token | [x] | | |

> 没有测试手机号时，7 ~ 9 记 `N/A`。

## 2. BBS

| # | 测试点 | 通过 | Request Header | Response |
| --- | --- | --- | --- | --- |
| 10 | 账号信息 `GET /user/wapi/getUserFullInfo` | [x] | | |
| 11 | 角色列表 `GET /binding/api/getUserGameRolesByCookie` | [x] | | |
| 12 | 战绩卡片 `GET /game_record/app/card/wapi/getGameRecordCard` | [x] | | |

## 3. 便笺 / Widget

| # | 测试点 | 通过 | Request Header | Response |
| --- | --- | --- | --- | --- |
| 13 | 原神便笺 `GET /game_record/app/genshin/api/dailyNote` | [x] | | |
| 14 | 原神 Widget `GET /game_record/app/genshin/aapi/widget/v2` | [x] | | |
| 15 | 星铁便笺 `GET /game_record/app/hkrpg/api/note` | [x] | | |
| 16 | 星铁 Widget `GET /game_record/app/hkrpg/aapi/widget` | [x] | | |
| 17 | 绝区零便笺 `GET /event/game_record_zzz/api/zzz/note` | [x] | | |
| 18 | 绝区零 Widget `GET /event/game_record_zzz/api/zzz/widget` | [x] | | |

> 没有添加 Widget 时，14 / 16 / 18 记 `N/A`。

## 4. 角色 / 养成计算

| # | 测试点 | 通过 | Request Header | Response |
| --- | --- | --- | --- | --- |
| 19 | 原神角色列表 `POST /game_record/app/genshin/api/character/list` | [x] | | |
| 20 | 原神角色详情 `POST /game_record/app/genshin/api/character/detail` | [x] | | |
| 21 | 原神养成计算 `POST /event/e20200928calculate/v3/batch_compute` | [x] | | |
| 22 | 星铁角色列表 `GET /game_record/app/hkrpg/api/avatar/basic` | [x] | | |
| 23 | 星铁角色详情 `GET /game_record/app/hkrpg/api/avatar/info` | [x] | | |
| 24 | 星铁养成计算 `POST /event/rpgcalc/compute?game=hkrpg` | [x] | | |
| 25 | 绝区零角色列表 `GET /event/game_record_zzz/api/zzz/avatar/basic` | [x] | | |
| 26 | 绝区零角色详情 `GET /event/game_record_zzz/api/zzz/avatar/info` | [x] | | |
| 27 | 绝区零邦布列表 `GET /event/game_record_zzz/api/zzz/buddy/info` | [x] | | |
| 28 | 绝区零养成计算 `POST /event/nap_cultivate_tool/avatar_calc?uid=&region=` | [x] | | |

> 账号没有某个游戏的角色时，对应项记 `N/A`。

## 5. 签到

| # | 测试点 | 通过 | Request Header | Response |
| --- | --- | --- | --- | --- |
| 29 | 大别野签到 `POST /apihub/app/api/signIn` | [ ] | | |
| 30 | 原神签到 `POST /event/luna/hk4e/sign` | [ ] | | |
| 31 | 星铁签到 `POST /event/luna/hkrpg/sign` | [ ] | | |
| 32 | 绝区零签到 `POST /event/luna/zzz/sign` | [ ] | | |
| 33 | 签到状态 / 奖励 `GET /event/luna/{host}/info`、`/home` | [ ] | | |

> 已签到属于正常业务结果，在 `Response` 里注明即可。

> 签到功能尚未实现，29～33 暂不验收；API 保留供后续接入。

## 6. 重启 / 错误路径

| # | 测试点 | 通过 | Request Header | Response |
| --- | --- | --- | --- | --- |
| 34 | 杀进程重开仍保持登录 | [ ] | | |
| 35 | Cookie 过期后自动刷新 ltoken / cookie_token | [ ] | | |
| 36 | 二维码过期 | [ ] | | |
| 37 | 取消扫码 | [ ] | | |
| 38 | 断网 / 超时提示 | [ ] | | |
| 39 | 无效 Cookie / `-100` 处理 | [ ] | | |

> P1（Geetest、设备指纹）只在自然触发时补测；P2 无业务调用方接口不测。
