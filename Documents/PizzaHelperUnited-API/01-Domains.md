# API Domains（基础域名）

## 国服（米游社 / Miyoushe）

| 域名                                        | 用途                                                   | 对应常量                  |
| ------------------------------------------- | ------------------------------------------------------ | ------------------------- |
| `https://api-takumi-record.mihoyo.com`      | 游戏记录 API（便笺、角色列表、战绩卡片、Geetest 验证） | `recordURLAPIHost`        |
| `https://api-takumi.mihoyo.com`             | 账号 API（游戏角色绑定、Token 换取、养成计算、签到）   | `accountAPIURLHost`       |
| `https://passport-api.mihoyo.com`           | Passport API（Cookie 刷新：ltoken / cookie_token）     | 硬编码                    |
| `https://hk4e-sdk.mihoyo.com`               | 原神 SDK（二维码登录）                                 | 硬编码                    |
| `https://public-data-api.mihoyo.com`        | 设备指纹 API（获取真实 device_fp）                     | `publicDataHostURLHeader` |
| `https://hk4e-api.mihoyo.com`               | 原神 Ledger API（原石收支记录）                        | `ledgerAPIURLHost`        |
| `https://hkrpg-api.mihoyo.com`              | 星铁游戏内公告 API                                     | 硬编码                    |
| `https://announcement-api.mihoyo.com`       | 绝区零游戏内公告 API                                   | 硬编码                    |
| `https://public-operation-hk4e.mihoyo.com`  | 原神公开运营 API                                       | `domain4PublicOps`        |
| `https://public-operation-hkrpg.mihoyo.com` | 星铁公开运营 API                                       | `domain4PublicOps`        |
| `https://public-operation-nap.mihoyo.com`   | 绝区零公开运营 API                                     | `domain4PublicOps`        |

> **注意**：星铁 Ledger API 复用 `api-takumi.mihoyo.com`，路径为 `/event/srledger/month_info`。

## 国际服（HoYoLab）

| 域名                                              | 用途                             | 对应常量                  |
| ------------------------------------------------- | -------------------------------- | ------------------------- |
| `https://bbs-api-os.hoyolab.com`                  | 游戏记录 API（便笺、角色列表等） | `recordURLAPIHost`        |
| `https://api-account-os.hoyolab.com`              | 账号 API                         | `accountAPIURLHost`       |
| `https://sg-act-nap-api.hoyolab.com`              | 绝区零便笺 API（国际服专用域名） | 硬编码                    |
| `https://sg-public-data-api.hoyoverse.com`        | 设备指纹 API（国际服）           | `publicDataHostURLHeader` |
| `https://sg-hk4e-api.hoyolab.com`                 | 原神 Ledger API（国际服）        | `ledgerAPIURLHost`        |
| `https://sg-public-api.hoyolab.com`               | 星铁 Ledger API（国际服）        | `ledgerAPIURLHost`        |
| `https://sg-hk4e-api.hoyoverse.com`               | 原神游戏内公告 API（国际服）     | 硬编码                    |
| `https://sg-hkrpg-api.hoyoverse.com`              | 星铁游戏内公告 API（国际服）     | 硬编码                    |
| `https://public-operation-hk4e-sg.hoyoverse.com`  | 原神公开运营 API（国际服）       | `domain4PublicOps`        |
| `https://public-operation-hkrpg-sg.hoyoverse.com` | 星铁公开运营 API（国际服）       | `domain4PublicOps`        |
| `https://public-operation-nap-sg.hoyoverse.com`   | 绝区零公开运营 API（国际服）     | `domain4PublicOps`        |

## Referer / Origin

| 区域   | Referer                        | Origin                         |
| ------ | ------------------------------ | ------------------------------ |
| 国服   | `https://webstatic.mihoyo.com` | `https://webstatic.mihoyo.com` |
| 国际服 | `https://act.hoyolab.com`      | `https://act.hoyolab.com`      |
