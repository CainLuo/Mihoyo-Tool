# 实施任务：mihoyo-api-redesign

> 前置依赖：`game-data-database-redesign` 的任务 1-18 完成后再执行本 spec 的任务。

## 任务列表

- [x] 1. 创建 Domain 和 Path 枚举文件
  - [x] 1.1 新建 `core/src/main/ets/network/v2/MihoyoDomain.ets`，定义 7 个 Host 枚举值（`TAKUMI_RECORD`、`TAKUMI`、`BBS`、`BBS_APIHUB`、`ACT_TAKUMI`、`PASSPORT`、`PASSPORT_V4`）
  - [x] 1.2 新建 `core/src/main/ets/network/v2/MihoyoAccountApiPath.ets`，定义 5 个 Path 枚举值（含 `CREATE_VERIFICATION`、`VERIFY_VERIFICATION`）
  - [x] 1.3 新建 `core/src/main/ets/network/v2/PassportApiPath.ets`，定义 `GET_COOKIE_TOKEN_BY_STOKEN`、`GET_LTOKEN_BY_STOKEN`、`VERIFY_LTOKEN` 三个枚举值
  - [x] 1.4 新建 `core/src/main/ets/network/v2/GenshinApiPath.ets`，定义 4 个 Path 枚举值
  - [x] 1.5 新建 `core/src/main/ets/network/v2/StarRailApiPath.ets`，定义 4 个 Path 枚举值
  - [x] 1.6 新建 `core/src/main/ets/network/v2/ZZZApiPath.ets`，定义 4 个 Path 枚举值
  - [x] 1.7 新建 `core/src/main/ets/network/v2/SignApiPath.ets`，定义大别野签到和各游戏签到的 Path 枚举值

- [x] 2. 创建 MihoyoApiService 抽象基类
  - [x] 2.1 新建 `core/src/main/ets/network/v2/MihoyoApiService.ets`，定义 `abstract get()` 和 `abstract post()` 方法（`post` 的 `data` 参数类型为 `string | RequestParams`）

- [x] 3. 创建 ApiErrors
  - [x] 3.1 新建 `core/src/main/ets/errors/ApiErrors.ets`，定义 `AuthExpiredError`、`GeetestRequiredError`、`RoleNotPublicError` 等业务错误类
  - [x] 3.2 在 `GeetestRequiredError` 中包含 `GeetestCreateResult` 类型（`gt`、`challenge`、`new_captcha` 字段）
  - [x] 3.3 定义 `GeetestVerifyInput` 类型（`geetest_challenge`、`geetest_validate`、`geetest_seccode` 字段）

- [x] 4. 创建 ApiConfigV2
  - [x] 4.1 新建 `core/src/main/ets/network/v2/ApiConfigV2.ets`，定义 `APP_VERSION`、`USER_AGENT`、`TOOL_VERSION_GENSHIN`、`TOOL_VERSION_STARRAIL` 常量
  - [x] 4.2 实现 `preloadDeviceId(context)` 和 `getDeviceIdSync()` 方法（从 Preferences 读取或生成 UUID）
  - [x] 4.3 实现 `preloadDeviceFp(context)` 和 `getDeviceFp()` 方法（格式：`38d8xxxxxxxx`）

- [x] 5. 创建 DSUtilV2
  - [x] 5.1 新建 `core/src/main/ets/network/v2/DSUtilV2.ets`，实现 `generateV1(params?, body?)`、`generateV2(params?, body?)`、`generateX6(params?, body?)` 三个静态方法
  - [x] 5.2 DS 格式：`{timestamp},{random},{md5}`，md5 内容：`salt={salt}&t={timestamp}&r={random}&b={body}&q={query}`
  - [x] 5.3 query 参数按字典序排列，使用 `for` 循环替代 `Array.sort()`（ArkTS 严格模式限制）
  - [x] 5.4 salt 从 `rawfile/release/salt_config.json` 读取，禁止硬编码在源码中

- [x] 6. 创建 MihoyoHeaderBuilder
  - [x] 6.1 新建 `core/src/main/ets/network/v2/MihoyoHeaderBuilder.ets`，定义 `HeaderProfile` 枚举（`GAME_RECORD`、`ZZZ_GAME_RECORD`、`CALCULATE`、`BBS`、`SIGN`）
  - [x] 6.2 实现 `MihoyoHeaderBuilder.build(profile, cookie, params?, body?)` 静态方法，按 Profile 差异化注入请求头
  - [x] 6.3 注意：`x-rpc-tool_verison` 使用米游社服务端的拼写错误（`verison` 非 `version`）
  - [x] 6.4 `SIGN` Profile 使用 X6 salt，`client_type=2`；`BBS` Profile 使用 V2 salt，`client_type=1`

- [x] 7. 创建 MihoyoEnvironment 和 MihoyoApiServiceFactory
  - [x] 7.1 新建 `core/src/main/ets/network/v2/MihoyoEnvironment.ets`，定义 `MOCK` 和 `RELEASE` 两个枚举值
  - [x] 7.2 新建 `core/src/main/ets/network/v2/MihoyoApiServiceFactory.ets`，实现 `createAccountService`、`createGenshinService`、`createStarRailService`、`createZZZService`、`createSignService` 五个静态工厂方法
  - [x] 7.3 Mock 环境下 `context` 为必填参数，缺失时抛出 `Error`（禁止 `!` 非空断言）

- [x] 8. 创建 MihoyoAccountApiService
  - [x] 8.1 新建 `core/src/main/ets/network/v2/MihoyoAccountApiService.ets`，继承 `MihoyoApiService`
  - [x] 8.2 实现 `getGameRoles(cookie)`：GET，Domain=TAKUMI，Profile=BBS
  - [x] 8.3 实现 `getGameRecordCard(uid, cookie)`：GET，Domain=TAKUMI_RECORD，Profile=BBS
  - [x] 8.4 实现 `getUserFullInfo(uid, cookie)`：GET，Domain=BBS，Profile=BBS
  - [x] 8.5 实现 `createVerification(cookie)` 和 `verifyVerification(input, cookie)`：GET/POST，Domain=BBS，Profile=BBS
  - [x] 8.6 实现 `refreshCookieToken(stoken, stuid)`、`refreshLToken(stoken, stuid)`、`verifyLToken(ltoken, ltuid)`：Domain=PASSPORT/PASSPORT_V4

- [x] 9. 创建 GenshinApiService
  - [x] 9.1 新建 `core/src/main/ets/network/v2/GenshinApiService.ets`，继承 `MihoyoApiService`
  - [x] 9.2 实现 `getDailyNote(roleId, server, cookie)`：GET，Domain=TAKUMI_RECORD，Profile=GAME_RECORD，注入 `TOOL_VERSION_GENSHIN`
  - [x] 9.3 实现 `getCharacterList(roleId, server, cookie)`：POST，Domain=TAKUMI_RECORD，Profile=GAME_RECORD
  - [x] 9.4 实现 `getCharacterDetail(roleId, server, characterIds, cookie)`：POST，Domain=TAKUMI_RECORD，Profile=GAME_RECORD
  - [x] 9.5 实现 `batchCompute(items, uid, region, cookie)`：POST，Domain=TAKUMI，Profile=CALCULATE，注入 `x-rpc-cal_type: 1`

- [x] 10. 创建 StarRailApiService
  - [x] 10.1 新建 `core/src/main/ets/network/v2/StarRailApiService.ets`，继承 `MihoyoApiService`
  - [x] 10.2 实现 `getDailyNote`、`getAvatarBasic`、`getAvatarInfo`：GET，Domain=TAKUMI_RECORD，Profile=GAME_RECORD，注入 `TOOL_VERSION_STARRAIL` 和 `x-rpc-platform: 5`
  - [x] 10.3 实现 `compute(avatar, skillList, uid, region, cookie)`：POST，Domain=TAKUMI，Profile=CALCULATE，URL 追加 `?game=hkrpg`，覆盖 Referer/Origin 为 `webstatic.mihoyo.com`

- [x] 11. 创建 ZZZApiService
  - [x] 11.1 新建 `core/src/main/ets/network/v2/ZZZApiService.ets`，继承 `MihoyoApiService`
  - [x] 11.2 实现 `getDailyNote`、`getAvatarBasic`、`getAvatarInfo`：GET，Domain=TAKUMI_RECORD，Profile=ZZZ_GAME_RECORD
  - [x] 11.3 实现 `compute(avatarId, avatarLevel, avatarCurrentLevel, avatarCurrentPromotes, skills, uid, region, cookie)`：POST，Domain=ACT_TAKUMI，Profile=ZZZ_GAME_RECORD，`uid`/`region` 作为 URL query 参数，注入 `x-rpc-cultivate_source: bbs`

- [x] 12. 创建 SignApiService
  - [x] 12.1 新建 `core/src/main/ets/network/v2/SignApiService.ets`，继承 `MihoyoApiService`
  - [x] 12.2 实现 `signBBS(cookie, challenge?)`：POST，Domain=BBS_APIHUB，Profile=SIGN
  - [x] 12.3 实现 `signGame(gameBiz, roleId, server, cookie, challenge?)`：POST，Domain=TAKUMI，Profile=SIGN，注入 `x-rpc-signgame: {host}`
  - [x] 12.4 实现 `getSignInfo(gameBiz, roleId, server, cookie)` 和 `getSignReward(gameBiz, cookie)`：GET，Domain=TAKUMI，Profile=SIGN

- [x] 13. 更新 core/Index.ets 导出
  - [x] 13.1 在 `core/Index.ets` 中新增 `network/v2/` 目录下所有公共类和枚举的导出（`MihoyoDomain`、各 ApiPath 枚举、`MihoyoApiService`、`MihoyoHeaderBuilder`、`HeaderProfile`、`ApiConfigV2`、`DSUtilV2`、`MihoyoEnvironment`、`MihoyoApiServiceFactory`、各 Service 类）
  - [x] 13.2 新增 `errors/ApiErrors.ets` 中所有类型的导出
  - [x] 13.3 运行 `getDiagnostics` 检查所有新建文件，确认无编译错误
