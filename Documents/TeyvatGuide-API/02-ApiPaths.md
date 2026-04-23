# TeyvatGuide API 接口路径

按 request 文件分类，列出所有接口路径、请求方法、所需 Cookie 字段和 DS salt 类型。

---

## 一、bbsReq.ts — BBS 社区接口

基础域名：`https://bbs-api.miyoushe.com/`

| 接口             | 方法 | 路径                                | Cookie 字段                  | DS Salt           | 说明                    |
| ---------------- | ---- | ----------------------------------- | ---------------------------- | ----------------- | ----------------------- |
| 获取表情包列表   | GET  | `misc/api/emoticon_set`             | 无                           | 无                | 公开接口                |
| 获取用户完整信息 | GET  | `user/wapi/getUserFullInfo`         | `cookie_token`, `account_id` | X4（isSign=true） | 需要登录                |
| 获取其他用户信息 | GET  | `user/wapi/getUserFullInfo`         | 无                           | X4（isSign=true） | 公开，传 `gids` + `uid` |
| 获取合集详情     | GET  | `collection/wapi/collection/detail` | 无                           | X4（isSign=true） | 传 `gids` + `id`        |

---

## 二、passportReq.ts — 登录认证接口

基础域名：`https://passport-api.mihoyo.com/`（v4：`https://passport-api-v4.mihoyo.com/`）

| 接口                          | 方法 | 路径                                                   | Cookie 字段       | DS Salt             | 说明              |
| ----------------------------- | ---- | ------------------------------------------------------ | ----------------- | ------------------- | ----------------- |
| 创建游戏 auth ticket          | POST | `account/ma-cn-verifier/app/createAuthTicketByGameBiz` | `stoken`, `mid`   | 无（自定义 header） | 需要 stoken       |
| 发送短信验证码                | POST | `account/ma-cn-verifier/verifier/createLoginCaptcha`   | 无                | 无（自定义 header） | 手机号 RSA 加密   |
| 创建二维码登录                | POST | `account/ma-cn-passport/app/createQRLogin`             | 无                | 无                  | `@deprecated`     |
| 通过 stoken 获取 cookie_token | GET  | `account/auth/api/getCookieAccountInfoBySToken`        | `stoken`, `mid`   | X4（默认）          | 刷新 cookie_token |
| 通过 stoken 获取 ltoken       | GET  | `account/auth/api/getLTokenBySToken`                   | `stoken`, `mid`   | X4（默认）          | 刷新 ltoken       |
| 短信验证码登录                | POST | `account/ma-cn-passport/app/loginByMobileCaptcha`      | 无                | 无（自定义 header） | 手机号 RSA 加密   |
| 查询二维码登录状态            | POST | `account/ma-cn-passport/app/queryQRLoginStatus`        | 无                | 无                  | `@deprecated`     |
| 验证 ltoken 有效性            | POST | `account/ma-cn-session/web/verifyLtoken`（v4）         | `ltoken`, `ltuid` | X4（默认）          | 返回 mid          |

---

## 三、recordReq.ts — 原神战绩记录接口

基础域名：`https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/`

| 接口             | 方法 | 路径（相对）                | Cookie 字段                                     | DS Salt    | 说明                            |
| ---------------- | ---- | --------------------------- | ----------------------------------------------- | ---------- | ------------------------------- |
| 获取角色详情     | POST | `character/detail`          | `account_id`, `cookie_token`                    | X4（默认） | 传角色 ID 列表                  |
| 获取角色列表     | POST | `character/list`            | `account_id`, `cookie_token`                    | X4（默认） |                                 |
| 获取首页战绩     | GET  | `index`                     | `account_id`, `cookie_token`                    | X4（默认） |                                 |
| 获取真境剧诗     | GET  | `role_combat`               | `account_id`, `cookie_token`, `ltoken`, `ltuid` | X4（默认） |                                 |
| 获取绘想游迹     | GET  | `char_master`               | `account_id`, `cookie_token`, `ltoken`, `ltuid` | X4（默认） |                                 |
| 获取深渊螺旋     | GET  | `spiralAbyss`               | `account_id`, `cookie_token`, `ltoken`, `ltuid` | X4（默认） | `schedule_type`: 1=本期, 2=上期 |
| 获取赋光之人排行 | GET  | `hard_challenge/popularity` | 无                                              | 无         | 公开接口，固定 role_id          |
| 获取幽境危战     | GET  | `hard_challenge`            | `account_id`, `cookie_token`                    | X4（默认） |                                 |
| 获取活动日历     | POST | `act_calendar`              | `account_id`, `cookie_token`                    | X4（默认） |                                 |
| 获取实时便笺     | GET  | `dailyNote`                 | `account_id`, `cookie_token`                    | X4（默认） |                                 |

---

## 四、miscReq.ts — 极验验证接口

基础域名：`https://bbs-api.miyoushe.com/misc/api/`

| 接口         | 方法 | 路径（相对）         | Cookie 字段     | DS Salt                               | 说明                                    |
| ------------ | ---- | -------------------- | --------------- | ------------------------------------- | --------------------------------------- |
| 创建极验验证 | GET  | `createVerification` | 任意有效 Cookie | K2（isSign=true）或 X4（isSign=true） | `is_high=true`                          |
| 验证极验结果 | POST | `verifyVerification` | 任意有效 Cookie | K2 或 X4                              | 传极验返回的 challenge/validate/seccode |

> `useK2=true` 时使用 K2 salt 并强制 `x-rpc-client_type: 2`；`useK2=false` 时使用 X4 salt。

---

## 五、lunaReq.ts — 签到活动接口

基础域名：`https://api-takumi.mihoyo.com/event/luna/`

路径格式：`{host}/{action}`，其中 `host` 由游戏 biz 决定（见 [05-SignIn.md](./05-SignIn.md)）。

| 接口             | 方法 | 路径（相对）            | Cookie 字段 | DS Salt                    | 说明                 |
| ---------------- | ---- | ----------------------- | ----------- | -------------------------- | -------------------- |
| 获取签到奖励列表 | GET  | `{host}/home` 或 `home` | 任意 Cookie | 无（直接传 cookie 字符串） |                      |
| 获取签到状态     | GET  | `{host}/info` 或 `info` | 任意 Cookie | 无                         |                      |
| 执行签到         | POST | `{host}/sign` 或 `sign` | 任意 Cookie | X6，`x-rpc-client_type: 2` | 可附带极验 challenge |
| 获取补签信息     | GET  | `{host}/resign_info`    | 任意 Cookie | 无                         |                      |
| 执行补签         | POST | `{host}/resign`         | 任意 Cookie | X6，`x-rpc-client_type: 2` | 可附带极验 challenge |

---

## 六、hk4eReq.ts — 原神专用接口

| 接口                   | 方法 | 完整路径                                                                              | Cookie 字段   | DS Salt | 说明            |
| ---------------------- | ---- | ------------------------------------------------------------------------------------- | ------------- | ------- | --------------- |
| 获取公告列表（国服）   | GET  | `https://hk4e-ann-api.mihoyo.com/common/hk4e_cn/announcement/api/getAnnList`          | 无            | 无      |                 |
| 获取公告内容（国服）   | GET  | `https://hk4e-ann-api.mihoyo.com/common/hk4e_cn/announcement/api/getAnnContent`       | 无            | 无      |                 |
| 获取公告列表（国际服） | GET  | `https://sg-hk4e-api.hoyoverse.com/common/hk4e_global/announcement/api/getAnnList`    | 无            | 无      |                 |
| 获取公告内容（国际服） | GET  | `https://sg-hk4e-api.hoyoverse.com/common/hk4e_global/announcement/api/getAnnContent` | 无            | 无      |                 |
| 获取抽卡记录           | GET  | `https://public-operation-hk4e.mihoyo.com/gacha_info/api/getGachaLog`                 | 无（authKey） | 无      | 用 authKey 鉴权 |
| 获取千星奇域抽卡记录   | GET  | `https://public-operation-hk4e.mihoyo.com/gacha_info/api/getBeyondGachaLog`           | 无（authKey） | 无      |                 |
| 创建二维码登录         | POST | `https://hk4e-sdk.mihoyo.com/hk4e_cn/combo/panda/qrcode/fetch`                        | 无            | 无      |                 |
| 查询二维码登录状态     | POST | `https://hk4e-sdk.mihoyo.com/hk4e_cn/combo/panda/qrcode/query`                        | 无            | 无      |                 |

---

## 七、takumiReq.ts — Takumi 通用接口

基础域名：`https://api-takumi.mihoyo.com/`

| 接口                           | 方法 | 路径（相对）                                    | Cookie 字段                  | DS Salt                    | 说明                  |
| ------------------------------ | ---- | ----------------------------------------------- | ---------------------------- | -------------------------- | --------------------- |
| 通过 game_token 获取 stoken    | POST | `account/ma-cn-session/app/getTokenByGameToken` | 无                           | X6，`x-rpc-client_type: 4` | 二维码登录后换 stoken |
| 通过 stoken 获取 action_ticket | GET  | `auth/api/getActionTicketBySToken`              | `stoken`, `mid`              | K2（默认）                 |                       |
| 生成 authKey（抽卡用）         | POST | `binding/api/genAuthKey`                        | `stoken`, `mid`              | LK2（isSign=true）         |                       |
| 生成 authKey v2（JSBridge）    | POST | `binding/api/genAuthKey`                        | 任意 Cookie                  | LK2（isSign=true）         |                       |
| 通过 Cookie 获取游戏角色       | GET  | `binding/api/getUserGameRolesByCookie`          | `account_id`, `cookie_token` | X4（默认）                 |                       |
| 获取卡池信息（OBC）            | GET  | `common/blackboard/ys_obc/v1/gacha_pool`        | 无                           | 无                         | `app_sn=ys_obc`       |
| 获取热点追踪（OBC）            | GET  | `common/blackboard/ys_obc/v1/home/position`     | 无                           | 无                         | `app_sn=ys_obc`       |

---

## 八、apiHubReq.ts — 社区 apihub 接口

基础域名：`https://bbs-api.miyoushe.com/apihub/`

| 接口                   | 方法 | 路径（相对）                | Cookie 字段 | DS Salt                                   | 说明                 |
| ---------------------- | ---- | --------------------------- | ----------- | ----------------------------------------- | -------------------- |
| 获取所有版块           | GET  | `wapi/getAllGamesForums`    | 无          | 无                                        |                      |
| 获取应用配置           | GET  | `api/getAppConfig`          | 无          | 无                                        | 可传 `gid`           |
| 获取分区列表           | GET  | `wapi/getGameList`          | 无          | 无                                        |                      |
| 获取米游币任务列表     | GET  | `wapi/getMissions`          | 任意 Cookie | X4（默认）                                | `point_sn=myb`       |
| 获取分享配置           | GET  | `api/getShareConf`          | 任意 Cookie | K2（isSign=true），`x-rpc-client_type: 2` |                      |
| 获取米游币任务完成状态 | GET  | `wapi/getUserMissionsState` | 任意 Cookie | X4（默认）                                | `point_sn=myb`       |
| 获取投票信息           | GET  | `api/getVotes`              | 无          | 无                                        |                      |
| 获取投票结果           | GET  | `api/getVotesResult`        | 无          | 无                                        |                      |
| 获取首页导航           | GET  | `api/home/new`              | 无          | 无                                        | `gids=2`             |
| 社区签到（米游币）     | POST | `app/api/signIn`            | 任意 Cookie | X6，`x-rpc-client_type: 2`                | 可附带极验 challenge |
| 帖子点赞               | POST | `api/upvotePost`            | 任意 Cookie | K2（isSign=true），`x-rpc-client_type: 2` |                      |

---

## 九、otherReq.ts — 其他公共接口

| 接口           | 方法 | 完整路径                                                          | Cookie 字段 | DS Salt | 说明                     |
| -------------- | ---- | ----------------------------------------------------------------- | ----------- | ------- | ------------------------ |
| 获取设备指纹   | POST | `https://public-data-api.mihoyo.com/device-fp/api/getFp`          | 无          | 无      | 传设备信息 JSON          |
| 获取直播兑换码 | GET  | `https://api-takumi-static.mihoyo.com/event/miyolive/refreshCode` | 无          | 无      | 传 `x-rpc-act_id` header |

---

## 十、painterReq.ts — 社区内容接口

基础域名：`https://bbs-api.miyoushe.com/painter/wapi/`

| 接口             | 方法 | 路径（相对）             | Cookie 字段       | DS Salt           | 说明                                |
| ---------------- | ---- | ------------------------ | ----------------- | ----------------- | ----------------------------------- |
| 获取资讯列表     | GET  | `getNewsList`            | 无                | 无                | `type`: 1=资讯, 2=活动, 3=公告      |
| 获取版块热门帖子 | GET  | `getHotForumPostList`    | 可选              | X4（可选）        |                                     |
| 获取版块最新帖子 | GET  | `getRecentForumPostList` | 可选              | X4（可选）        | `sort_type`: 1=最新回复, 2=最新发布 |
| 获取关注动态     | GET  | `timeline/list`          | `ltoken`, `ltuid` | X4（isSign=true） |                                     |
| 获取抽奖信息     | GET  | `lottery/user/show`      | 无                | 无                |                                     |

---

## 十一、postReq.ts — 帖子接口

基础域名：`https://bbs-api.miyoushe.com/post/wapi/`

| 接口             | 方法 | 路径（相对）              | Cookie 字段                  | DS Salt                                   | 说明                         |
| ---------------- | ---- | ------------------------- | ---------------------------- | ----------------------------------------- | ---------------------------- |
| 获取帖子详情     | GET  | `getPostFull`             | 可选                         | K2（isSign=true），`x-rpc-client_type: 2` |                              |
| 获取合集帖子     | GET  | `getPostFullInCollection` | 无                           | 无                                        |                              |
| 获取帖子回复     | GET  | `getPostReplies`          | 无                           | 无                                        |                              |
| 获取子回复       | GET  | `getSubReplies`           | 无                           | 无                                        |                              |
| 获取话题帖子列表 | GET  | `getTopicPostList`        | 无                           | 无                                        |                              |
| 获取用户发布帖子 | GET  | `userPost`                | 无                           | 无                                        |                              |
| 搜索帖子         | GET  | `searchPosts`             | 无                           | 无                                        | `order_type`: 1=最热, 2=最新 |
| 获取用户收藏帖子 | GET  | `userFavouritePost`       | `cookie_token`, `account_id` | X4（默认）                                |                              |

---

## 十二、topicReq.ts — 话题接口

基础域名：`https://bbs-api.miyoushe.com/topic/wapi/`

| 接口         | 方法 | 路径（相对）       | Cookie 字段 | DS Salt | 说明 |
| ------------ | ---- | ------------------ | ----------- | ------- | ---- |
| 获取话题详情 | GET  | `getTopicFullInfo` | 无          | 无      |      |
