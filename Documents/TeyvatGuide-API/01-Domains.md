# TeyvatGuide API 域名列表

所有域名均来自 `TeyvatGuide/src/request/` 源码，按模块分类。

---

## 一、米游社 BBS 相关

| 变量名  | 域名                                     | 用途                               |
| ------- | ---------------------------------------- | ---------------------------------- |
| `mbBu`  | `https://bbs-api.miyoushe.com/`          | BBS 通用接口（用户信息、表情包等） |
| `bamBu` | `https://bbs-api.miyoushe.com/misc/api/` | 极验验证接口                       |
| `Mahbu` | `https://bbs-api.miyoushe.com/apihub/`   | 社区功能（版块、签到、点赞等）     |

> 三个变量实际上都指向同一个根域名 `bbs-api.miyoushe.com`，只是路径前缀不同。

---

## 二、Passport 认证相关

| 变量名  | 域名                                  | 用途                              |
| ------- | ------------------------------------- | --------------------------------- |
| `pAbu`  | `https://passport-api.mihoyo.com/`    | 登录、验证码、二维码、Cookie 刷新 |
| `p4Abu` | `https://passport-api-v4.mihoyo.com/` | ltoken 验证（v4 版本）            |

---

## 三、Takumi 接口相关

| 变量名   | 域名                                                                | 用途                                    |
| -------- | ------------------------------------------------------------------- | --------------------------------------- |
| `taBu`   | `https://api-takumi.mihoyo.com/`                                    | 游戏角色绑定、authKey 生成、stoken 换取 |
| `trgAbu` | `https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/` | 原神战绩记录（角色列表、便笺、深渊等）  |
| `telaBu` | `https://api-takumi.mihoyo.com/event/luna/`                         | 签到活动（原神、星铁、绝区零等）        |

---

## 四、原神专用

| 域名                                                                    | 用途                   |
| ----------------------------------------------------------------------- | ---------------------- |
| `https://hk4e-ann-api.mihoyo.com/common/hk4e_cn/announcement/api`       | 原神国服游戏内公告     |
| `https://sg-hk4e-api.hoyoverse.com/common/hk4e_global/announcement/api` | 原神国际服游戏内公告   |
| `https://hk4e-sdk.mihoyo.com/hk4e_cn/`                                  | 原神 SDK（二维码登录） |
| `https://public-operation-hk4e.mihoyo.com/gacha_info/api/`              | 原神抽卡记录           |

---

## 五、其他公共接口

| 域名                                                              | 用途           |
| ----------------------------------------------------------------- | -------------- |
| `https://public-data-api.mihoyo.com/device-fp/api/getFp`          | 获取设备指纹   |
| `https://api-takumi-static.mihoyo.com/event/miyolive/refreshCode` | 获取直播兑换码 |

---

## 六、域名汇总（去重）

| 域名                               | 主要用途                |
| ---------------------------------- | ----------------------- |
| `bbs-api.miyoushe.com`             | BBS 社区、极验、apihub  |
| `passport-api.mihoyo.com`          | 登录认证、Cookie 管理   |
| `passport-api-v4.mihoyo.com`       | ltoken 验证（v4）       |
| `api-takumi.mihoyo.com`            | 游戏绑定、签到、authKey |
| `api-takumi-record.mihoyo.com`     | 原神战绩记录            |
| `hk4e-ann-api.mihoyo.com`          | 原神国服公告            |
| `sg-hk4e-api.hoyoverse.com`        | 原神国际服公告          |
| `hk4e-sdk.mihoyo.com`              | 原神 SDK                |
| `public-operation-hk4e.mihoyo.com` | 原神抽卡记录            |
| `public-data-api.mihoyo.com`       | 设备指纹                |
| `api-takumi-static.mihoyo.com`     | 静态资源（兑换码）      |
