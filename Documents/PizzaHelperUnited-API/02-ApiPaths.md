# API Paths（接口路径）

## 一、便笺（Daily Note）

### 原神

| 路径                                      | 方法 | 域名                           | 说明                                       |
| ----------------------------------------- | ---- | ------------------------------ | ------------------------------------------ |
| `/game_record/app/genshin/api/dailyNote`  | GET  | `api-takumi-record.mihoyo.com` | 完整便笺（树脂/委托/派遣/宝钱/参量质变仪） |
| `/game_record/app/genshin/aapi/widget/v2` | GET  | `api-takumi-record.mihoyo.com` | Widget 便笺（无 Geetest，需要 stoken_v2）  |

**Query 参数**：`role_id`（角色 UID）、`server`（服务器，如 `cn_gf01`）

**Challenge 头**（遇到 1034 时携带）：

- `x-rpc-challenge_path`: `https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/dailyNote`
- `x-rpc-challenge_game`: `2`

---

### 星穹铁道

| 路径                                 | 方法 | 域名                           | 说明                                      |
| ------------------------------------ | ---- | ------------------------------ | ----------------------------------------- |
| `/game_record/app/hkrpg/api/note`    | GET  | `api-takumi-record.mihoyo.com` | 完整便笺（开拓力/派遣/实训/模拟宇宙等）   |
| `/game_record/app/hkrpg/aapi/widget` | GET  | `api-takumi-record.mihoyo.com` | Widget 便笺（无 Geetest，需要 stoken_v2） |

**Challenge 头**：

- `x-rpc-challenge_path`: `https://api-takumi-record.mihoyo.com/game_record/app/hkrpg/api/note`
- `x-rpc-challenge_game`: `6`

---

### 绝区零

| 路径                                    | 方法 | 域名                                                                           | 说明                                      |
| --------------------------------------- | ---- | ------------------------------------------------------------------------------ | ----------------------------------------- |
| `/event/game_record_zzz/api/zzz/note`   | GET  | `api-takumi-record.mihoyo.com`（国服）/ `sg-act-nap-api.hoyolab.com`（国际服） | 完整便笺（电量/活跃度/录像店/刮刮卡等）   |
| `/event/game_record_zzz/api/zzz/widget` | GET  | `api-takumi-record.mihoyo.com`                                                 | Widget 便笺（无 Geetest，需要 stoken_v2） |

**Challenge 头**：

- `x-rpc-challenge_path`: `https://api-takumi-record.mihoyo.com/event/game_record_zzz/api/zzz/note`
- `x-rpc-challenge_game`: `8`

---

## 二、Geetest 验证

| 路径                                            | 方法 | 域名                           | 说明                                       |
| ----------------------------------------------- | ---- | ------------------------------ | ------------------------------------------ |
| `/game_record/app/card/wapi/createVerification` | GET  | `api-takumi-record.mihoyo.com` | 申请 Geetest 验证任务，返回 gt + challenge |
| `/game_record/app/card/wapi/verifyVerification` | POST | `api-takumi-record.mihoyo.com` | 提交验证结果，换取新 challenge             |

> **注意**：PizzaHelperUnited 使用 `card/wapi/createVerification`，而非 `misc/api/createVerification`。两者功能相同，但路径不同。

---

## 三、账号与游戏角色

| 路径                                    | 方法 | 域名                    | 说明                   |
| --------------------------------------- | ---- | ----------------------- | ---------------------- |
| `/binding/api/getUserGameRolesByCookie` | GET  | `api-takumi.mihoyo.com` | 获取绑定的游戏角色列表 |

---

## 四、登录相关

### 手机号登录

| 路径                                     | 方法 | 域名                      | 说明                                                        |
| ---------------------------------------- | ---- | ------------------------- | ----------------------------------------------------------- |
| `/auth/api/getMultiTokenByLoginTicket`   | GET  | `api-takumi.mihoyo.com`   | 用 login_ticket 换取 stoken_v2 + ltoken（WebView 登录方式） |
| `/auth/api/getCookieAccountInfoBySToken` | GET  | `api-takumi.mihoyo.com`   | 用 stoken 换取 cookie_token                                 |
| `/account/auth/api/getLTokenBySToken`    | GET  | `passport-api.mihoyo.com` | 用 stoken 换取 ltoken                                       |

### 二维码登录

| 路径                                             | 方法 | 域名                    | 说明                                             |
| ------------------------------------------------ | ---- | ----------------------- | ------------------------------------------------ |
| `/bh2_cn/combo/panda/qrcode/fetch`               | POST | `hk4e-sdk.mihoyo.com`   | 获取二维码 URL（含 ticket）                      |
| `/bh2_cn/combo/panda/qrcode/query`               | POST | `hk4e-sdk.mihoyo.com`   | 轮询扫码状态                                     |
| `/account/ma-cn-session/app/getTokenByGameToken` | POST | `api-takumi.mihoyo.com` | 用 game_token 换取 stoken_v2（二维码确认后调用） |

> **重要**：PizzaHelperUnited 二维码登录使用 `appTag = "bh2_cn"`，而非 `hk4e_cn`。

---

## 五、设备指纹

| 路径                   | 方法 | 域名                                                                               | 说明               |
| ---------------------- | ---- | ---------------------------------------------------------------------------------- | ------------------ |
| `/device-fp/api/getFp` | POST | `public-data-api.mihoyo.com`（国服）/ `sg-public-data-api.hoyoverse.com`（国际服） | 获取真实 device_fp |

---

## 六、Ledger（原石/星琼收支记录）

| 路径                           | 方法 | 域名                                                                   | 说明                   |
| ------------------------------ | ---- | ---------------------------------------------------------------------- | ---------------------- |
| `/event/ys_ledger/monthInfo`   | GET  | `hk4e-api.mihoyo.com`                                                  | 原神月度收支（国服）   |
| `/event/ysledgeros/month_info` | GET  | `sg-hk4e-api.hoyolab.com`                                              | 原神月度收支（国际服） |
| `/event/srledger/month_info`   | GET  | `api-takumi.mihoyo.com`（国服）/ `sg-public-api.hoyolab.com`（国际服） | 星铁月度收支           |
