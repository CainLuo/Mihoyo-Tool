# PizzaHelperUnited API 参考文档

本目录整理自 PizzaHelperUnited（iOS App）的源码，供本项目（HarmonyOS）对照参考。

## 文档列表

| 文件                                           | 内容                                         |
| ---------------------------------------------- | -------------------------------------------- |
| [01-Domains.md](./01-Domains.md)               | 所有 API 基础域名（国服 + 国际服）           |
| [02-ApiPaths.md](./02-ApiPaths.md)             | 所有 API 接口路径（按功能分类）              |
| [03-ErrorCodes.md](./03-ErrorCodes.md)         | 所有 retcode 错误码及处理方式                |
| [04-RequestHeaders.md](./04-RequestHeaders.md) | 请求头配置（DS 签名、UA、Challenge 头等）    |
| [05-CookieAndAuth.md](./05-CookieAndAuth.md)   | Cookie 格式、stoken_v2 说明、Widget 降级机制 |

## 数据来源

- 源码路径：`PizzaHelperUnited/Packages/PZKit/Sources/PZAccountKit/HoYoAPIs/`
- 版本：截至 2026 年 4 月
- 米游社 App 版本：`2.40.1`（国服）/ `2.55.0`（国际服）
