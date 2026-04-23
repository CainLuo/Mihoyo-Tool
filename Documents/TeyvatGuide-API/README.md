# TeyvatGuide API 参考文档

本目录整理自 TeyvatGuide（Tauri 桌面 App，TypeScript/Vue）的源码，供本项目（HarmonyOS）对照参考。

## 文档列表

| 文件                                         | 内容                                                   |
| -------------------------------------------- | ------------------------------------------------------ |
| [01-Domains.md](./01-Domains.md)             | 所有 API 基础域名（按模块分类）                        |
| [02-ApiPaths.md](./02-ApiPaths.md)           | 所有 API 接口路径（按 request 文件分类，共 12 个模块） |
| [03-DSSignature.md](./03-DSSignature.md)     | DS 签名机制（所有 salt 值、算法、标准请求头）          |
| [04-ErrorHandling.md](./04-ErrorHandling.md) | 错误处理机制（retcode 含义、极验流程）                 |
| [05-SignIn.md](./05-SignIn.md)               | 签到模块（各游戏 actId、host 配置、请求格式）          |

## 数据来源

- 源码路径：`TeyvatGuide/src/request/`、`TeyvatGuide/src/utils/`
- BBS App 版本：`2.102.1`
- 技术栈：TypeScript + Vue 3 + Tauri（桌面端）

## 覆盖的 request 文件

| 文件             | 说明                                 |
| ---------------- | ------------------------------------ |
| `bbsReq.ts`      | BBS 用户信息、表情包、合集           |
| `passportReq.ts` | 登录认证、Cookie 刷新、二维码登录    |
| `recordReq.ts`   | 原神战绩记录（角色、便笺、深渊等）   |
| `miscReq.ts`     | 极验验证                             |
| `lunaReq.ts`     | 游戏签到（原神/星铁/绝区零等）       |
| `hk4eReq.ts`     | 原神公告、抽卡记录、SDK 登录         |
| `takumiReq.ts`   | 游戏角色绑定、authKey、stoken 换取   |
| `apiHubReq.ts`   | 社区功能（版块、签到、点赞等）       |
| `otherReq.ts`    | 设备指纹、直播兑换码                 |
| `painterReq.ts`  | 社区内容（资讯、帖子列表、关注动态） |
| `postReq.ts`     | 帖子详情、回复、搜索                 |
| `topicReq.ts`    | 话题信息                             |
