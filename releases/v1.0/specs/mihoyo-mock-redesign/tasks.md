# 实施任务：mihoyo-mock-redesign

> 前置依赖：`mihoyo-api-redesign` 的所有任务完成后再执行本 spec 的任务。

## 任务列表

- [x] 1. 创建 MockServiceBase
  - [x] 1.1 新建 `core/src/main/ets/network/mock/MockServiceBase.ets`，继承 `MihoyoApiService`，构造函数注入 `common.UIAbilityContext`
  - [x] 1.2 实现 `delay()` 方法（300ms，使用 `MOCK_DELAY_MS` 常量）
  - [x] 1.3 实现 `pathToFileName(path)` 静态方法：先去掉 query 参数，再检查特殊映射表，最后走通用规则（斜杠替换下划线）
  - [x] 1.4 特殊映射表包含 5 条：`batch_compute`→`genshin_character_batch_compute.json`、`rpgcalc/compute`→`hkrpg_character_compute.json`、`nap_cultivate_tool/avatar_calc`→`zzz_character_compute.json`、`/app/api/signIn`→`apihub_app_api_signIn.json`、`character/detail`→`character_detail_all.json`
  - [x] 1.5 实现 `extractAccountId(cookie)` 静态方法：正则提取 `account_id=(\d+)`，失败时 fallback 到 1（ArkTS 严格模式：`match()` 返回值需要 null 检查）
  - [x] 1.6 实现 `readMockFile(path, cookie)` 方法：`delay()` → 路由子目录 → 读文件 → JSON 解析 → retcode 检查；文件不存在或 JSON 解析失败时返回 `{ retcode: 0, message: 'success', data: {} }`，不抛出错误

- [x] 2. 创建 MihoyoAccountMockService
  - [x] 2.1 新建 `core/src/main/ets/network/mock/MihoyoAccountMockService.ets`，继承 `MockServiceBase`
  - [x] 2.2 实现 `getGameRoles`、`getGameRecordCard`、`getUserFullInfo`：调用 `readMockFile(path, cookie)`
  - [x] 2.3 实现 `createVerification` 和 `verifyVerification`：调用 `readMockFile`，读取对应 mock 文件
  - [x] 2.4 实现 `refreshCookieToken`、`refreshLToken`：直接返回固定 token 字符串（无需读文件）
  - [x] 2.5 实现 `verifyLToken`：直接返回 `{ retcode: 0, data: {} }`（无需读文件）

- [x] 3. 创建 GenshinMockService
  - [x] 3.1 新建 `core/src/main/ets/network/mock/GenshinMockService.ets`，继承 `MockServiceBase`
  - [x] 3.2 实现 `getDailyNote`、`getCharacterList`：调用 `readMockFile`
  - [x] 3.3 实现 `getCharacterDetail`：调用 `readMockFile`，路径传 `GenshinApiPath.CHARACTER_DETAIL`（特殊映射表会自动映射到 `character_detail_all.json`）
  - [x] 3.4 实现 `batchCompute`：调用 `readMockFile`，路径传 `GenshinApiPath.BATCH_COMPUTE`（特殊映射表映射到 `genshin_character_batch_compute.json`）

- [x] 4. 创建 StarRailMockService
  - [x] 4.1 新建 `core/src/main/ets/network/mock/StarRailMockService.ets`，继承 `MockServiceBase`
  - [x] 4.2 实现 `getDailyNote`、`getAvatarBasic`、`getAvatarInfo`：调用 `readMockFile`
  - [x] 4.3 实现 `compute`：调用 `readMockFile`，路径传 `StarRailApiPath.COMPUTE`（映射到 `hkrpg_character_compute.json`）

- [x] 5. 创建 ZZZMockService
  - [x] 5.1 新建 `core/src/main/ets/network/mock/ZZZMockService.ets`，继承 `MockServiceBase`
  - [x] 5.2 实现 `getDailyNote`、`getAvatarBasic`、`getAvatarInfo`：调用 `readMockFile`
  - [x] 5.3 实现 `compute`：调用 `readMockFile`，路径传 `ZZZApiPath.COMPUTE`（映射到 `zzz_character_compute.json`）

- [x] 6. 创建 SignMockService
  - [x] 6.1 新建 `core/src/main/ets/network/mock/SignMockService.ets`，继承 `MockServiceBase`
  - [x] 6.2 实现 `signBBS(cookie, challenge?)`：调用 `readMockFile`，路径传 `SignApiPath.SIGN_BBS`（映射到 `apihub_app_api_signIn.json`）
  - [x] 6.3 实现 `signGame(gameBiz, roleId, server, cookie, challenge?)`：根据 `gameBiz` 动态构造文件路径（如 `hk4e_cn` → `event_luna_hk4e_sign.json`），读取后检查 `data.is_risk` 字段
  - [x] 6.4 实现 `getSignInfo(gameBiz, roleId, server, cookie)`：动态构造路径，读取 `event_luna_{host}_info.json`
  - [x] 6.5 实现 `getSignReward(gameBiz, cookie)`：动态构造路径，读取 `event_luna_{host}_home.json`

- [x] 7. 补充 mock 数据文件
  - [x] 7.1 检查 `core/src/main/resources/rawfile/mock/account1/` 目录，确认以下文件存在：`misc_api_createVerification.json`、`misc_api_verifyVerification.json`、`apihub_app_api_signIn.json`
  - [x] 7.2 补充签到相关 mock 文件（如不存在）：`event_luna_hk4e_sign.json`、`event_luna_hkrpg_sign.json`、`event_luna_zzz_sign.json`、`event_luna_hk4e_info.json`、`event_luna_hkrpg_info.json`、`event_luna_zzz_info.json`、`event_luna_hk4e_home.json`、`event_luna_hkrpg_home.json`、`event_luna_zzz_home.json`
  - [x] 7.3 确认 `genshin_character_batch_compute.json`、`hkrpg_character_compute.json`、`zzz_character_compute.json` 存在于 account1 和 account2 目录
  - [x] 7.4 将 account1 目录下所有 mock 文件同步复制到 account2 目录（结构保持一致）

- [x] 8. 更新 MihoyoApiServiceFactory 注册 Mock Service
  - [x] 8.1 在 `MihoyoApiServiceFactory.ets` 中 import 所有 Mock Service 类
  - [x] 8.2 确认 `createAccountService`、`createGenshinService`、`createStarRailService`、`createZZZService`、`createSignService` 在 `MOCK` 环境下分别返回对应 Mock Service 实例
  - [x] 8.3 运行 `getDiagnostics` 检查 `MihoyoApiServiceFactory.ets` 及所有 Mock Service 文件，确认无编译错误

- [x] 9. 端到端验证（Mock 环境）
  - [x] 9.1 确认 `EntryAbility.onCreate` 调用 `CoreInitializer.initCore({ isMock: true, context })` 时，各 Repository 持有的是 Mock Service 实例
  - [x] 9.2 在 Mock 环境下启动应用，验证首页能正常加载账号数据（来自 mock 文件）
  - [x] 9.3 验证原神、星铁、绝区零的便笺数据能正常显示
  - [x] 9.4 验证修改 mock 文件 retcode 为 `-100` 时，UI 能正确触发重新登录流程
  - [x] 9.5 运行 `bash run.sh` 构建并安装，确认 BUILD SUCCESSFUL
