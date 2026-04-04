# 实施任务：game-data-database-redesign

## 任务列表

- [x] 1. 创建 RdbManagerV2 和基础表
  - [x] 1.1 新建 `core/src/main/ets/database/v2/RdbManagerV2.ets`，实现 `init(context)` 方法，使用 `SecurityLevel.S2` 打开数据库，执行 `PRAGMA foreign_keys = ON`
  - [x] 1.2 实现 `createTables()` 方法，使用 `CREATE TABLE IF NOT EXISTS` 创建 `account_table` 和 `game_role_table`（含外键约束和索引）
  - [x] 1.3 实现 `runInTransaction(fn)` 方法，支持事务回滚
  - [x] 1.4 实现 `runMigrations()` 方法，检查 `user_version`，首次安装时建全部 15 张表并设 `user_version=1`

- [x] 2. 创建原神专用表（DDL）
  - [x] 2.1 在 `RdbManagerV2.createTables()` 中添加 `genshin_character_list` 建表语句（含唯一索引和查询索引）
  - [x] 2.2 添加 `genshin_daily_note` 建表语句（含唯一索引）
  - [x] 2.3 添加 `genshin_character_detail` 建表语句（含唯一索引）
  - [x] 2.4 添加 `genshin_character_compute` 建表语句（含唯一索引）

- [x] 3. 创建星穹铁道专用表（DDL）
  - [x] 3.1 添加 `starrail_avatar_basic` 建表语句（含唯一索引和查询索引）
  - [x] 3.2 添加 `starrail_daily_note` 建表语句（含 `grid_fight_weekly_cur`/`grid_fight_weekly_max` 字段，含唯一索引）
  - [x] 3.3 添加 `starrail_avatar_info` 建表语句（含唯一索引）
  - [x] 3.4 添加 `starrail_avatar_compute` 建表语句（含唯一索引）

- [x] 4. 创建绝区零专用表（DDL）
  - [x] 4.1 添加 `zzz_avatar_basic` 建表语句（含唯一索引和查询索引）
  - [x] 4.2 添加 `zzz_daily_note` 建表语句（含唯一索引）
  - [x] 4.3 添加 `zzz_avatar_info` 建表语句（含唯一索引）
  - [x] 4.4 添加 `zzz_avatar_compute` 建表语句（含唯一索引）

- [x] 5. 创建 sync_meta 表（DDL）
  - [x] 5.1 添加 `sync_meta` 建表语句（含唯一索引）
  - [x] 5.2 新建 `core/src/main/ets/constants/SyncDataType.ets`，定义 `SyncDataType` 枚举（15 个值，对应 15 张专用表名）

- [x] 6. 创建 BBSDao
  - [x] 6.1 新建 `core/src/main/ets/database/v2/BBSDao.ets`，实现 `AccountDao` 类：`upsert(row: AccountRowV2)`、`findAll()`、`findById(id)`、`deleteById(id)`
  - [x] 6.2 实现 `GameRoleDao` 类：`upsertAll(rows: GameRoleRowV2[])`、`findByAccountId(accountId)`、`deleteByAccountId(accountId)`

- [x] 7. 创建 GenshinDao
  - [x] 7.1 新建 `core/src/main/ets/database/v2/GenshinDao.ets`，实现 `GenshinCharacterListDao`：`upsertAll(rows)`、`findAll(accountId, roleUid)`、`deleteAll(accountId, roleUid)`
  - [x] 7.2 实现 `GenshinDailyNoteDao`：`upsert(row)`、`findOne(accountId, roleUid)`、`deleteOne(accountId, roleUid)`
  - [x] 7.3 实现 `GenshinCharacterDetailDao`：`upsertAll(rows)`、`findByAvatarId(accountId, roleUid, avatarId)`、`deleteAll(accountId, roleUid)`
  - [x] 7.4 实现 `GenshinCharacterComputeDao`：`upsert(row)`、`findByAvatarId(accountId, roleUid, avatarId)`、`deleteAll(accountId, roleUid)`

- [x] 8. 创建 StarRailDao
  - [x] 8.1 新建 `core/src/main/ets/database/v2/StarRailDao.ets`，实现 `StarRailAvatarBasicDao`：`upsertAll(rows)`、`findAll(accountId, roleUid)`、`deleteAll(accountId, roleUid)`
  - [x] 8.2 实现 `StarRailDailyNoteDao`：`upsert(row)`、`findOne(accountId, roleUid)`、`deleteOne(accountId, roleUid)`
  - [x] 8.3 实现 `StarRailAvatarInfoDao`：`upsertAll(rows)`、`findByAvatarId(accountId, roleUid, avatarId)`、`deleteAll(accountId, roleUid)`
  - [x] 8.4 实现 `StarRailAvatarComputeDao`：`upsert(row)`、`findByAvatarId(accountId, roleUid, avatarId)`、`deleteAll(accountId, roleUid)`

- [x] 9. 创建 ZZZDao
  - [x] 9.1 新建 `core/src/main/ets/database/v2/ZZZDao.ets`，实现 `ZZZAvatarBasicDao`：`upsertAll(rows)`、`findAll(accountId, roleUid)`、`deleteAll(accountId, roleUid)`
  - [x] 9.2 实现 `ZZZDailyNoteDao`：`upsert(row)`、`findOne(accountId, roleUid)`、`deleteOne(accountId, roleUid)`
  - [x] 9.3 实现 `ZZZAvatarInfoDao`：`upsertAll(rows)`、`findByAvatarId(accountId, roleUid, avatarId)`、`deleteAll(accountId, roleUid)`
  - [x] 9.4 实现 `ZZZAvatarComputeDao`：`upsert(row)`、`findByAvatarId(accountId, roleUid, avatarId)`、`deleteAll(accountId, roleUid)`

- [x] 10. 创建 SyncMetaDaoV2
  - [x] 10.1 新建 `core/src/main/ets/database/v2/SyncMetaDaoV2.ets`，实现 `upsert(row)`、`findOne(accountId, roleUid, dataType)`、`updateStatus(accountId, roleUid, dataType, status, errorMsg?)`

- [x] 11. 创建数据行模型（Row 类）
  - [x] 11.1 新建 `core/src/main/ets/models/v2/AccountRowV2.ets`，定义 `AccountRowV2` 类，字段对应 `account_table` 所有列
  - [x] 11.2 新建 `core/src/main/ets/models/v2/GameRoleRowV2.ets`，定义 `GameRoleRowV2` 类，字段对应 `game_role_table` 所有列
  - [x] 11.3 新建 `core/src/main/ets/models/v2/GenshinRows.ets`，定义 `GenshinCharacterListRow`、`GenshinDailyNoteRow`、`GenshinCharacterDetailRow`、`GenshinCharacterComputeRow` 四个类
  - [x] 11.4 新建 `core/src/main/ets/models/v2/StarRailRows.ets`，定义 `StarRailAvatarBasicRow`、`StarRailDailyNoteRow`、`StarRailAvatarInfoRow`、`StarRailAvatarComputeRow` 四个类
  - [x] 11.5 新建 `core/src/main/ets/models/v2/ZZZRows.ets`，定义 `ZZZAvatarBasicRow`、`ZZZDailyNoteRow`、`ZZZAvatarInfoRow`、`ZZZAvatarComputeRow` 四个类
  - [x] 11.6 新建 `core/src/main/ets/models/v2/SyncMetaRow.ets`，定义 `SyncMetaRow` 类

- [x] 12. 创建 GameRepository 抽象基类
  - [x] 12.1 新建 `core/src/main/ets/repository/v2/GameRepository.ets`，定义 `abstract class GameRepository`，包含 `abstract findAll()`、`abstract upsertAll()`、`abstract deleteAll()` 方法，以及 `handleApiErrorWithRefresh()` 公共方法

- [x] 13. 创建 BBSRepository
  - [x] 13.1 新建 `core/src/main/ets/repository/v2/BBSRepository.ets`，实现账号登录、查询、删除方法
  - [x] 13.2 实现游戏角色查询和更新方法（`getGameRoles`、`refreshGameRoles`）
  - [x] 13.3 实现 `createVerification()` 和 `verifyVerification()` 方法（Geetest 流程）
  - [x] 13.4 实现 Cookie 刷新逻辑（`refreshCookieToken`、`refreshLToken`、`verifyLToken`）

- [x] 14. 创建 GenshinRepository
  - [x] 14.1 新建 `core/src/main/ets/repository/v2/GenshinRepository.ets`，继承 `GameRepository`
  - [x] 14.2 实现 `getDailyNote(accountId, roleUid, cookie)`：检查 sync_meta → 触发网络请求 → 事务写入 `genshin_daily_note` + 更新 `sync_meta`
  - [x] 14.3 实现 `getCharacterList(accountId, roleUid, cookie)`：同步策略同上，写入 `genshin_character_list`
  - [x] 14.4 实现 `getCharacterDetail(accountId, roleUid, avatarIds, cookie)`：写入 `genshin_character_detail`
  - [x] 14.5 实现 `batchCompute(accountId, roleUid, items, uid, region, cookie)`：写入 `genshin_character_compute`

- [x] 15. 创建 StarRailRepository
  - [x] 15.1 新建 `core/src/main/ets/repository/v2/StarRailRepository.ets`，继承 `GameRepository`
  - [x] 15.2 实现 `getDailyNote`、`getAvatarBasic`、`getAvatarInfo`、`compute` 四个方法，各自写入对应专用表并更新 `sync_meta`

- [x] 16. 创建 ZZZRepository
  - [x] 16.1 新建 `core/src/main/ets/repository/v2/ZZZRepository.ets`，继承 `GameRepository`
  - [x] 16.2 实现 `getDailyNote`、`getAvatarBasic`、`getAvatarInfo`、`compute` 四个方法，各自写入对应专用表并更新 `sync_meta`

- [x] 17. 创建 SignRepository
  - [x] 17.1 新建 `core/src/main/ets/repository/v2/SignRepository.ets`，持有 `SignApiService` 实例
  - [x] 17.2 实现 `signGame(gameBiz, roleId, server, cookie)`、`signBBS(cookie)`、`getSignInfo()`、`getSignReward()` 方法
  - [x] 17.3 实现 Geetest 重试逻辑（`processGeetestQueue`，使用 `splice(0,1)[0]` 替代 `shift()`）

- [x] 18. 创建 CoreInitializerV2
  - [x] 18.1 新建 `core/src/main/ets/CoreInitializerV2.ets`，实现 `initCore({ isMock, context })` 方法
  - [x] 18.2 初始化流程：`RdbManagerV2.init()` → `ApiConfigV2.preloadDeviceId/Fp()` → `MihoyoApiServiceFactory.create*()` → 各 Repository `setService()`
  - [x] 18.3 根据 `isMock` 参数决定使用 Mock Service 还是 Release Service

- [x] 19. 更新 core/Index.ets 导出
  - [x] 19.1 在 `core/Index.ets` 中新增所有 v2 目录下的类和枚举的导出（`CoreInitializerV2`、各 Repository、各 Row 类、`SyncDataType`、`ApiErrors` 等）

- [x] 20. 将 entry 模块切换到新 Repository
  - [x] 20.1 将 `entry` 模块中所有 ViewModel 的 Repository 引用从旧版切换到 `v2/` 版本（依赖 mihoyo-api-redesign spec 完成后执行，届时 v2 Repository 网络方法才有完整实现）
  - [x] 20.2 将 `EntryAbility.onCreate` 中的初始化调用从 `CoreInitializer` 切换到 `CoreInitializerV2`
  - [x] 20.3 运行 `getDiagnostics` 检查所有修改文件，确认无编译错误
