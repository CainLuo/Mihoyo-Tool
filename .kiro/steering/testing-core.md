# core 模块测试设计文档

## 说明

core 模块测试严格按层级隔离，DB 层和 API 层不混用。
测试文件位置：`core/src/test/`（本地单元测试，不依赖设备）
入口文件：`core/src/test/List.test.ets`，所有测试套件必须在此注册。

---

## 一、常量与模型层（core/src/test/）

### 1.1 SyncDataType 枚举（SyncDataType.test.ets）

被测类：`core/src/main/ets/constants/SyncDataType.ets`

| 测试用例                         | 输入                                     | 预期输出                      |
| -------------------------------- | ---------------------------------------- | ----------------------------- |
| ACCOUNT 值正确                   | `SyncDataType.ACCOUNT`                   | `'account_table'`             |
| GAME_ROLE 值正确                 | `SyncDataType.GAME_ROLE`                 | `'game_role_table'`           |
| GENSHIN_CHARACTER_LIST 值正确    | `SyncDataType.GENSHIN_CHARACTER_LIST`    | `'genshin_character_list'`    |
| GENSHIN_DAILY_NOTE 值正确        | `SyncDataType.GENSHIN_DAILY_NOTE`        | `'genshin_daily_note'`        |
| GENSHIN_CHARACTER_DETAIL 值正确  | `SyncDataType.GENSHIN_CHARACTER_DETAIL`  | `'genshin_character_detail'`  |
| GENSHIN_CHARACTER_COMPUTE 值正确 | `SyncDataType.GENSHIN_CHARACTER_COMPUTE` | `'genshin_character_compute'` |
| STARRAIL_AVATAR_BASIC 值正确     | `SyncDataType.STARRAIL_AVATAR_BASIC`     | `'starrail_avatar_basic'`     |
| STARRAIL_DAILY_NOTE 值正确       | `SyncDataType.STARRAIL_DAILY_NOTE`       | `'starrail_daily_note'`       |
| STARRAIL_AVATAR_INFO 值正确      | `SyncDataType.STARRAIL_AVATAR_INFO`      | `'starrail_avatar_info'`      |
| STARRAIL_AVATAR_COMPUTE 值正确   | `SyncDataType.STARRAIL_AVATAR_COMPUTE`   | `'starrail_avatar_compute'`   |
| ZZZ_AVATAR_BASIC 值正确          | `SyncDataType.ZZZ_AVATAR_BASIC`          | `'zzz_avatar_basic'`          |
| ZZZ_DAILY_NOTE 值正确            | `SyncDataType.ZZZ_DAILY_NOTE`            | `'zzz_daily_note'`            |
| ZZZ_AVATAR_INFO 值正确           | `SyncDataType.ZZZ_AVATAR_INFO`           | `'zzz_avatar_info'`           |
| ZZZ_AVATAR_COMPUTE 值正确        | `SyncDataType.ZZZ_AVATAR_COMPUTE`        | `'zzz_avatar_compute'`        |
| SYNC_META 值正确                 | `SyncDataType.SYNC_META`                 | `'sync_meta'`                 |

### 1.2 v2 Row 模型默认值（RowModels.test.ets）

被测类：`core/src/main/ets/models/v2/` 下所有 Row 类

**AccountRowV2**

| 测试用例                 | 字段                           | 预期默认值 |
| ------------------------ | ------------------------------ | ---------- |
| id 默认为 0              | `new AccountRowV2().id`        | `0`        |
| username 默认为空字符串  | `new AccountRowV2().username`  | `''`       |
| cookie 默认为空字符串    | `new AccountRowV2().cookie`    | `''`       |
| stoken 默认为空字符串    | `new AccountRowV2().stoken`    | `''`       |
| isActive 默认为 0        | `new AccountRowV2().isActive`  | `0`        |
| uid 默认为空字符串       | `new AccountRowV2().uid`       | `''`       |
| nickname 默认为空字符串  | `new AccountRowV2().nickname`  | `''`       |
| avatarUrl 默认为空字符串 | `new AccountRowV2().avatarUrl` | `''`       |

**GameRoleRowV2**

| 测试用例              | 字段                            | 预期默认值 |
| --------------------- | ------------------------------- | ---------- |
| id 默认为 0           | `new GameRoleRowV2().id`        | `0`        |
| accountId 默认为 0    | `new GameRoleRowV2().accountId` | `0`        |
| gameId 默认为空字符串 | `new GameRoleRowV2().gameId`    | `''`       |
| roleId 默认为空字符串 | `new GameRoleRowV2().roleId`    | `''`       |
| level 默认为 0        | `new GameRoleRowV2().level`     | `0`        |
| isChosen 默认为 0     | `new GameRoleRowV2().isChosen`  | `0`        |
| isPublic 默认为 0     | `new GameRoleRowV2().isPublic`  | `0`        |

**GenshinCharacterListRow**

| 测试用例                         | 字段                                                    | 预期默认值 |
| -------------------------------- | ------------------------------------------------------- | ---------- |
| id 默认为 0                      | `new GenshinCharacterListRow().id`                      | `0`        |
| avatarId 默认为空字符串          | `new GenshinCharacterListRow().avatarId`                | `''`       |
| rarity 默认为 0                  | `new GenshinCharacterListRow().rarity`                  | `0`        |
| level 默认为 0                   | `new GenshinCharacterListRow().level`                   | `0`        |
| fetter 默认为 0                  | `new GenshinCharacterListRow().fetter`                  | `0`        |
| activedConstellationNum 默认为 0 | `new GenshinCharacterListRow().activedConstellationNum` | `0`        |
| rawJson 默认为空字符串           | `new GenshinCharacterListRow().rawJson`                 | `''`       |

**GenshinDailyNoteRow**

| 测试用例                   | 字段                                          | 预期默认值 |
| -------------------------- | --------------------------------------------- | ---------- |
| currentResin 默认为 0      | `new GenshinDailyNoteRow().currentResin`      | `0`        |
| maxResin 默认为 0          | `new GenshinDailyNoteRow().maxResin`          | `0`        |
| resinRecoveryTime 默认为 0 | `new GenshinDailyNoteRow().resinRecoveryTime` | `0`        |
| rawJson 默认为空字符串     | `new GenshinDailyNoteRow().rawJson`           | `''`       |

**GenshinCharacterDetailRow**

| 测试用例                   | 字段                                          | 预期默认值 |
| -------------------------- | --------------------------------------------- | ---------- |
| avatarId 默认为空字符串    | `new GenshinCharacterDetailRow().avatarId`    | `''`       |
| weaponId 默认为空字符串    | `new GenshinCharacterDetailRow().weaponId`    | `''`       |
| relicIds 默认为空字符串    | `new GenshinCharacterDetailRow().relicIds`    | `''`       |
| skillLevels 默认为空字符串 | `new GenshinCharacterDetailRow().skillLevels` | `''`       |
| rawJson 默认为空字符串     | `new GenshinCharacterDetailRow().rawJson`     | `''`       |

**GenshinCharacterComputeRow**

| 测试用例                         | 字段                                                 | 预期默认值 |
| -------------------------------- | ---------------------------------------------------- | ---------- |
| avatarId 默认为空字符串          | `new GenshinCharacterComputeRow().avatarId`          | `''`       |
| avatarConsumeJson 默认为空字符串 | `new GenshinCharacterComputeRow().avatarConsumeJson` | `''`       |
| skillConsumeJson 默认为空字符串  | `new GenshinCharacterComputeRow().skillConsumeJson`  | `''`       |
| weaponConsumeJson 默认为空字符串 | `new GenshinCharacterComputeRow().weaponConsumeJson` | `''`       |

**StarRailAvatarBasicRow**

| 测试用例                | 字段                                     | 预期默认值 |
| ----------------------- | ---------------------------------------- | ---------- |
| avatarId 默认为空字符串 | `new StarRailAvatarBasicRow().avatarId`  | `''`       |
| rarity 默认为 0         | `new StarRailAvatarBasicRow().rarity`    | `0`        |
| level 默认为 0          | `new StarRailAvatarBasicRow().level`     | `0`        |
| rank 默认为 0           | `new StarRailAvatarBasicRow().rank`      | `0`        |
| baseType 默认为 0       | `new StarRailAvatarBasicRow().baseType`  | `0`        |
| elementId 默认为 0      | `new StarRailAvatarBasicRow().elementId` | `0`        |

**StarRailDailyNoteRow**

| 测试用例                    | 字段                                            | 预期默认值 |
| --------------------------- | ----------------------------------------------- | ---------- |
| currentStamina 默认为 0     | `new StarRailDailyNoteRow().currentStamina`     | `0`        |
| maxStamina 默认为 0         | `new StarRailDailyNoteRow().maxStamina`         | `0`        |
| gridFightWeeklyCur 默认为 0 | `new StarRailDailyNoteRow().gridFightWeeklyCur` | `0`        |
| gridFightWeeklyMax 默认为 0 | `new StarRailDailyNoteRow().gridFightWeeklyMax` | `0`        |

**StarRailAvatarInfoRow**

| 测试用例                     | 字段                                        | 预期默认值 |
| ---------------------------- | ------------------------------------------- | ---------- |
| avatarId 默认为空字符串      | `new StarRailAvatarInfoRow().avatarId`      | `''`       |
| equipId 默认为空字符串       | `new StarRailAvatarInfoRow().equipId`       | `''`       |
| relicIds 默认为空字符串      | `new StarRailAvatarInfoRow().relicIds`      | `''`       |
| skillTreeJson 默认为空字符串 | `new StarRailAvatarInfoRow().skillTreeJson` | `''`       |

**StarRailAvatarComputeRow**

| 测试用例                            | 字段                                                  | 预期默认值 |
| ----------------------------------- | ----------------------------------------------------- | ---------- |
| avatarConsumeJson 默认为空字符串    | `new StarRailAvatarComputeRow().avatarConsumeJson`    | `''`       |
| skillConsumeJson 默认为空字符串     | `new StarRailAvatarComputeRow().skillConsumeJson`     | `''`       |
| equipmentConsumeJson 默认为空字符串 | `new StarRailAvatarComputeRow().equipmentConsumeJson` | `''`       |

**ZZZAvatarBasicRow**

| 测试用例                           | 字段                                       | 预期默认值 |
| ---------------------------------- | ------------------------------------------ | ---------- |
| avatarId 默认为空字符串            | `new ZZZAvatarBasicRow().avatarId`         | `''`       |
| rarity 默认为空字符串（TEXT 类型） | `new ZZZAvatarBasicRow().rarity`           | `''`       |
| level 默认为 0                     | `new ZZZAvatarBasicRow().level`            | `0`        |
| rank 默认为 0                      | `new ZZZAvatarBasicRow().rank`             | `0`        |
| elementType 默认为 0               | `new ZZZAvatarBasicRow().elementType`      | `0`        |
| avatarProfession 默认为 0          | `new ZZZAvatarBasicRow().avatarProfession` | `0`        |

**ZZZDailyNoteRow**

| 测试用例                    | 字段                                  | 预期默认值 |
| --------------------------- | ------------------------------------- | ---------- |
| energyCurrent 默认为 0      | `new ZZZDailyNoteRow().energyCurrent` | `0`        |
| energyMax 默认为 0          | `new ZZZDailyNoteRow().energyMax`     | `0`        |
| vhsSaleState 默认为空字符串 | `new ZZZDailyNoteRow().vhsSaleState`  | `''`       |
| cardSign 默认为空字符串     | `new ZZZDailyNoteRow().cardSign`      | `''`       |

**ZZZAvatarInfoRow**

| 测试用例                       | 字段                                     | 预期默认值 |
| ------------------------------ | ---------------------------------------- | ---------- |
| avatarId 默认为空字符串        | `new ZZZAvatarInfoRow().avatarId`        | `''`       |
| weaponId 默认为空字符串        | `new ZZZAvatarInfoRow().weaponId`        | `''`       |
| equipIds 默认为空字符串        | `new ZZZAvatarInfoRow().equipIds`        | `''`       |
| skillLevelsJson 默认为空字符串 | `new ZZZAvatarInfoRow().skillLevelsJson` | `''`       |

**ZZZAvatarComputeRow**

| 测试用例                         | 字段                                          | 预期默认值 |
| -------------------------------- | --------------------------------------------- | ---------- |
| avatarConsumeJson 默认为空字符串 | `new ZZZAvatarComputeRow().avatarConsumeJson` | `''`       |
| weaponConsumeJson 默认为空字符串 | `new ZZZAvatarComputeRow().weaponConsumeJson` | `''`       |
| skillConsumeJson 默认为空字符串  | `new ZZZAvatarComputeRow().skillConsumeJson`  | `''`       |

**SyncMetaRow**

| 测试用例                  | 字段                             | 预期默认值 |
| ------------------------- | -------------------------------- | ---------- |
| id 默认为 0               | `new SyncMetaRow().id`           | `0`        |
| accountId 默认为 0        | `new SyncMetaRow().accountId`    | `0`        |
| roleUid 默认为空字符串    | `new SyncMetaRow().roleUid`      | `''`       |
| dataType 默认为空字符串   | `new SyncMetaRow().dataType`     | `''`       |
| lastSyncTime 默认为 0     | `new SyncMetaRow().lastSyncTime` | `0`        |
| syncStatus 默认为空字符串 | `new SyncMetaRow().syncStatus`   | `''`       |
| errorMsg 默认为空字符串   | `new SyncMetaRow().errorMsg`     | `''`       |

---

## 二、DB 层（core/src/ohosTest/）

> DB 层测试需要真实 RDB，必须在设备端运行（`core/src/ohosTest/`）。
> 不得与 API 层测试混用同一测试文件。

### 2.1 RdbManagerV2（RdbManagerV2.test.ets）

被测类：`core/src/main/ets/database/v2/RdbManagerV2.ets`

| 测试用例                   | 前置条件   | 操作                         | 预期结果                              |
| -------------------------- | ---------- | ---------------------------- | ------------------------------------- |
| init 成功                  | 未初始化   | `RdbManagerV2.init(context)` | 不抛异常，`getRdbStore()` 返回非 null |
| init 幂等                  | 已初始化   | 再次调用 `init(context)`     | 不抛异常，不重复建表                  |
| createTables 幂等          | 已建表     | 再次调用 `createTables()`    | 不抛异常（IF NOT EXISTS 保证）        |
| runInTransaction 成功提交  | 已初始化   | 在事务中执行 SQL，不抛异常   | 数据写入成功                          |
| runInTransaction 失败回滚  | 已初始化   | 在事务中抛出异常             | 数据未写入，事务回滚                  |
| user_version 首次安装为 1  | 全新数据库 | `runMigrations()`            | `PRAGMA user_version` 返回 1          |
| 15 张表全部存在            | 已初始化   | 查询 sqlite_master           | 15 张表均存在                         |
| PRAGMA foreign_keys 已开启 | 已初始化   | 查询 `PRAGMA foreign_keys`   | 返回 1                                |

### 2.2 BBSDao — AccountDao（BBSDao.test.ets）

被测类：`core/src/main/ets/database/v2/BBSDao.ets` → `AccountDao`

| 测试用例              | 前置条件           | 操作                        | 预期结果                              |
| --------------------- | ------------------ | --------------------------- | ------------------------------------- |
| upsert 新账号         | 表为空             | `upsert(row)`               | `findAll()` 返回 1 条，字段与写入一致 |
| upsert 更新已有账号   | 已有 username='u1' | 再次 `upsert` 相同 username | 仍只有 1 条，字段更新为新值           |
| findAll 空表          | 表为空             | `findAll()`                 | 返回空数组                            |
| findAll 多条          | 已有 3 条          | `findAll()`                 | 返回 3 条                             |
| findById 存在         | 已有 id=1          | `findById(1)`               | 返回对应行                            |
| findById 不存在       | 表为空             | `findById(999)`             | 返回 null                             |
| findByUsername 存在   | 已有 username='u1' | `findByUsername('u1')`      | 返回对应行                            |
| findByUsername 不存在 | 表为空             | `findByUsername('none')`    | 返回 null                             |
| deleteById 存在       | 已有 id=1          | `deleteById(1)`             | `findById(1)` 返回 null               |
| deleteById 不存在     | 表为空             | `deleteById(999)`           | 不抛异常                              |

### 2.3 BBSDao — GameRoleDao（BBSDao.test.ets）

被测类：`core/src/main/ets/database/v2/BBSDao.ets` → `GameRoleDao`

| 测试用例                    | 前置条件                                           | 操作                                 | 预期结果                        |
| --------------------------- | -------------------------------------------------- | ------------------------------------ | ------------------------------- |
| upsertAll 批量写入          | 表为空                                             | `upsertAll([row1, row2])`            | `findByAccountId` 返回 2 条     |
| upsertAll 更新已有          | 已有 (accountId=1, gameId='genshin', roleId='123') | 再次 upsertAll 相同唯一键            | 仍只有 1 条，字段更新           |
| upsertAll 空数组            | 表为空                                             | `upsertAll([])`                      | 不抛异常，表仍为空              |
| findByAccountId 存在        | 已有 accountId=1 的 2 条                           | `findByAccountId(1)`                 | 返回 2 条                       |
| findByAccountId 不存在      | 表为空                                             | `findByAccountId(999)`               | 返回空数组                      |
| findByAccountAndGame 存在   | 已有 (accountId=1, gameId='genshin')               | `findByAccountAndGame(1, 'genshin')` | 返回对应行                      |
| findByAccountAndGame 不存在 | 表为空                                             | `findByAccountAndGame(1, 'zzz')`     | 返回空数组                      |
| deleteByAccountId 存在      | 已有 accountId=1 的 2 条                           | `deleteByAccountId(1)`               | `findByAccountId(1)` 返回空数组 |

### 2.4 GenshinDao（GenshinDao.test.ets）

被测类：`core/src/main/ets/database/v2/GenshinDao.ets`

**GenshinCharacterListDao**

| 测试用例                          | 操作                                         | 预期结果                                |
| --------------------------------- | -------------------------------------------- | --------------------------------------- |
| upsertAll 写入                    | `upsertAll([row1, row2])`                    | `findAll(accountId, roleUid)` 返回 2 条 |
| upsertAll 唯一键冲突更新          | 相同 (accountId, roleUid, avatarId) 再次写入 | 仍只有 1 条，字段更新                   |
| findAll 按 accountId+roleUid 过滤 | 已有不同 roleUid 的数据                      | 只返回指定 roleUid 的数据               |
| findByAvatarId 存在               | 已有 avatarId='10000125'                     | 返回对应行                              |
| findByAvatarId 不存在             | 表为空                                       | 返回 null                               |
| deleteAll 清空指定角色            | 已有 2 条                                    | `findAll` 返回空数组                    |

**GenshinDailyNoteDao**

| 测试用例              | 操作                               | 预期结果                                 |
| --------------------- | ---------------------------------- | ---------------------------------------- |
| upsert 写入           | `upsert(row)`                      | `findOne(accountId, roleUid)` 返回对应行 |
| upsert 唯一键冲突更新 | 相同 (accountId, roleUid) 再次写入 | 仍只有 1 条，字段更新                    |
| findOne 不存在        | 表为空                             | 返回 null                                |
| deleteOne 存在        | 已有 1 条                          | `findOne` 返回 null                      |

**GenshinCharacterDetailDao**

| 测试用例                 | 操作                                         | 预期结果                    |
| ------------------------ | -------------------------------------------- | --------------------------- |
| upsertAll 写入           | `upsertAll([row])`                           | `findByAvatarId` 返回对应行 |
| upsertAll 唯一键冲突更新 | 相同 (accountId, roleUid, avatarId) 再次写入 | 仍只有 1 条，字段更新       |
| findByAvatarId 不存在    | 表为空                                       | 返回 null                   |
| deleteAll 清空           | 已有 2 条                                    | `findByAvatarId` 返回 null  |

**GenshinCharacterComputeDao**

| 测试用例              | 操作                                         | 预期结果                    |
| --------------------- | -------------------------------------------- | --------------------------- |
| upsert 写入           | `upsert(row)`                                | `findByAvatarId` 返回对应行 |
| upsert 唯一键冲突更新 | 相同 (accountId, roleUid, avatarId) 再次写入 | 仍只有 1 条，字段更新       |
| findByAvatarId 不存在 | 表为空                                       | 返回 null                   |

### 2.5 StarRailDao（StarRailDao.test.ets）

被测类：`core/src/main/ets/database/v2/StarRailDao.ets`

**StarRailAvatarBasicDao**

| 测试用例                          | 操作                                         | 预期结果                  |
| --------------------------------- | -------------------------------------------- | ------------------------- |
| upsertAll 写入                    | `upsertAll([row1, row2])`                    | `findAll` 返回 2 条       |
| upsertAll 唯一键冲突更新          | 相同 (accountId, roleUid, avatarId) 再次写入 | 仍只有 1 条，字段更新     |
| findAll 按 accountId+roleUid 过滤 | 已有不同 roleUid 的数据                      | 只返回指定 roleUid 的数据 |
| findByAvatarId 存在               | 已有 avatarId='8006'                         | 返回对应行                |
| findByAvatarId 不存在             | 表为空                                       | 返回 null                 |
| deleteAll 清空                    | 已有 2 条                                    | `findAll` 返回空数组      |

**StarRailDailyNoteDao**

| 测试用例              | 操作                               | 预期结果              |
| --------------------- | ---------------------------------- | --------------------- |
| upsert 写入           | `upsert(row)`                      | `findOne` 返回对应行  |
| upsert 唯一键冲突更新 | 相同 (accountId, roleUid) 再次写入 | 仍只有 1 条，字段更新 |
| findOne 不存在        | 表为空                             | 返回 null             |
| deleteOne 存在        | 已有 1 条                          | `findOne` 返回 null   |

**StarRailAvatarInfoDao / StarRailAvatarComputeDao**

| 测试用例              | 操作               | 预期结果                    |
| --------------------- | ------------------ | --------------------------- |
| upsertAll/upsert 写入 | 写入 1 条          | `findByAvatarId` 返回对应行 |
| 唯一键冲突更新        | 相同唯一键再次写入 | 仍只有 1 条，字段更新       |
| findByAvatarId 不存在 | 表为空             | 返回 null                   |
| deleteAll 清空        | 已有数据           | `findByAvatarId` 返回 null  |

### 2.6 ZZZDao（ZZZDao.test.ets）

被测类：`core/src/main/ets/database/v2/ZZZDao.ets`

与 StarRailDao 结构对称，测试用例相同，仅表名和字段不同：

| DAO 类              | 唯一键                         | 特殊字段                                               |
| ------------------- | ------------------------------ | ------------------------------------------------------ |
| ZZZAvatarBasicDao   | (accountId, roleUid, avatarId) | awakenState 写入时转 string，读取时转 number           |
| ZZZDailyNoteDao     | (accountId, roleUid)           | vhsSaleState、cardSign 为 TEXT                         |
| ZZZAvatarInfoDao    | (accountId, roleUid, avatarId) | skillLevelsJson、verticalPaintingUrl                   |
| ZZZAvatarComputeDao | (accountId, roleUid, avatarId) | avatarConsumeJson、weaponConsumeJson、skillConsumeJson |

**ZZZAvatarBasicDao 特殊测试**

| 测试用例             | 操作                  | 预期结果                 |
| -------------------- | --------------------- | ------------------------ |
| awakenState 写入转换 | 写入 `awakenState=1`  | 数据库存储为字符串 `'1'` |
| awakenState 读取转换 | 读取 awakenState 字段 | 返回 number 类型 `1`     |

### 2.7 SyncMetaDaoV2（SyncMetaDaoV2.test.ets）

被测类：`core/src/main/ets/database/v2/SyncMetaDaoV2.ets`

| 测试用例                    | 操作                                         | 预期结果                                                 |
| --------------------------- | -------------------------------------------- | -------------------------------------------------------- |
| upsert 写入                 | `upsert(row)`                                | `findOne` 返回对应行                                     |
| upsert 唯一键冲突更新       | 相同 (accountId, roleUid, dataType) 再次写入 | 仍只有 1 条，字段更新                                    |
| findOne 存在                | 已有 1 条                                    | 返回对应行，字段与写入一致                               |
| findOne 不存在              | 表为空                                       | 返回 null                                                |
| updateStatus 更新为 syncing | 已有 1 条                                    | syncStatus 变为 'syncing'，lastSyncTime 不变             |
| updateStatus 更新为 success | 已有 1 条                                    | syncStatus 变为 'success'，lastSyncTime 更新为当前时间戳 |
| updateStatus 更新为 failed  | 已有 1 条                                    | syncStatus 变为 'failed'，errorMsg 更新                  |
| updateStatus 记录不存在     | 表为空                                       | 不抛异常（UPDATE 0 行）                                  |

---

## 三、API 层（core/src/test/）

> API 层测试只测试纯函数和静态方法，不依赖设备。
> 不得与 DB 层测试混用同一测试文件。

### 3.1 DSUtilV2（DSUtilV2.test.ets）

被测类：`core/src/main/ets/network/v2/DSUtilV2.ets`

**DS 格式验证**

| 测试用例                               | 操作                    | 预期结果                      |
| -------------------------------------- | ----------------------- | ----------------------------- |
| generateV1 格式为 timestamp,random,md5 | `DSUtilV2.generateV1()` | 以逗号分隔，共 3 段           |
| generateV1 timestamp 为近期 Unix 秒    | 取第 1 段               | 与 `Date.now()/1000` 差值 < 5 |
| generateV1 random 为 6 位字符          | 取第 2 段               | 长度为 6                      |
| generateV1 md5 为 32 位十六进制        | 取第 3 段               | 长度 32，只含 0-9a-f          |
| generateV2 格式正确                    | `DSUtilV2.generateV2()` | 以逗号分隔，共 3 段           |
| generateX6 格式正确                    | `DSUtilV2.generateX6()` | 以逗号分隔，共 3 段           |

**query 参数序列化**

| 测试用例           | 输入                                  | 预期结果            |
| ------------------ | ------------------------------------- | ------------------- |
| 多参数按字典序排列 | `{server: 'cn_gf01', role_id: '123'}` | DS 正常生成，不崩溃 |
| 单参数             | `{uid: '100000001'}`                  | DS 正常生成         |
| 空 RequestParams   | `new RequestParams()`                 | DS 正常生成         |
| undefined params   | `undefined`                           | DS 正常生成         |

**POST body 参数**

| 测试用例       | 输入                           | 预期结果    |
| -------------- | ------------------------------ | ----------- |
| 有 body 字符串 | `body = JSON.stringify({...})` | DS 正常生成 |
| 空 body 字符串 | `body = ''`                    | DS 正常生成 |
| undefined body | `undefined`                    | DS 正常生成 |

### 3.2 MockServiceBase 静态方法（MockServiceBase.test.ets）

被测类：`core/src/main/ets/network/v2/mock/MockServiceBase.ets`

**pathToFileName — 通用规则**

| 测试用例         | 输入 path                                     | 预期文件名                                        |
| ---------------- | --------------------------------------------- | ------------------------------------------------- |
| 原神便笺         | `/game_record/app/genshin/api/dailyNote`      | `game_record_app_genshin_api_dailyNote.json`      |
| 原神角色列表     | `/game_record/app/genshin/api/character/list` | `game_record_app_genshin_api_character_list.json` |
| 星铁便笺         | `/game_record/app/hkrpg/api/note`             | `game_record_app_hkrpg_api_note.json`             |
| 绝区零代理人列表 | `/event/game_record_zzz/api/zzz/avatar/basic` | `event_game_record_zzz_api_zzz_avatar_basic.json` |
| BBS 账号详情     | `/user/api/getUserFullInfo`                   | `user_api_getUserFullInfo.json`                   |
| 游戏角色绑定     | `/binding/api/getUserGameRolesByCookie`       | `binding_api_getUserGameRolesByCookie.json`       |

**pathToFileName — 特殊映射表（5 条）**

| 测试用例                 | 输入 path                                       | 预期文件名                                              |
| ------------------------ | ----------------------------------------------- | ------------------------------------------------------- |
| 原神养成计算             | `/event/e20200928calculate/v3/batch_compute`    | `genshin_character_batch_compute.json`                  |
| 星铁养成计算             | `/event/rpgcalc/compute`                        | `hkrpg_character_compute.json`                          |
| 绝区零养成计算           | `/event/nap_cultivate_tool/avatar_calc`         | `zzz_character_compute.json`                            |
| 大别野签到               | `/app/api/signIn`                               | `apihub_app_api_signIn.json`                            |
| 原神角色详情（批量映射） | `/game_record/app/genshin/api/character/detail` | `game_record_app_genshin_api_character_detail_all.json` |

**pathToFileName — query 参数去除**

| 测试用例                  | 输入 path                                                         | 预期文件名                            |
| ------------------------- | ----------------------------------------------------------------- | ------------------------------------- |
| 带 query 的普通路径       | `/game_record/app/hkrpg/api/note?role_id=123&server=prod_gf_cn`   | `game_record_app_hkrpg_api_note.json` |
| 带 query 的特殊映射路径   | `/event/rpgcalc/compute?game=hkrpg`                               | `hkrpg_character_compute.json`        |
| 带 query 的绝区零计算路径 | `/event/nap_cultivate_tool/avatar_calc?uid=123&region=prod_gf_cn` | `zzz_character_compute.json`          |

**extractAccountId**

| 测试用例            | 输入 cookie                           | 预期结果        |
| ------------------- | ------------------------------------- | --------------- |
| account_id=1        | `'account_id=1; ltoken=abc'`          | `1`             |
| account_id=2        | `'account_id=2; ltoken=xyz'`          | `2`             |
| 大数字 account_id   | `'account_id=123456789; ltoken=abc'`  | `123456789`     |
| 无 account_id       | `'ltoken=abc; ltuid=1'`               | `1`（fallback） |
| 空字符串            | `''`                                  | `1`（fallback） |
| account_id 不在首位 | `'ltoken=abc; account_id=5; ltuid=5'` | `5`             |

### 3.3 GenshinDailyNoteParser（GenshinDailyNoteParser.test.ets）

被测类：`core/src/main/ets/parsers/genshin/GenshinDailyNoteParser.ets`

**正常解析**

| 测试用例                           | 字段                             | 预期值                  |
| ---------------------------------- | -------------------------------- | ----------------------- |
| currentResin 解析正确              | `data.currentResin`              | `120`                   |
| maxResin 解析正确                  | `data.maxResin`                  | `200`                   |
| resinRecoveryTime 从字符串转整数   | `data.resinRecoveryTime`         | `3600`（输入 `'3600'`） |
| currentHomeCoin 解析正确           | `data.currentHomeCoin`           | `1500`                  |
| maxHomeCoin 解析正确               | `data.maxHomeCoin`               | `2400`                  |
| finishedTaskNum 解析正确           | `data.finishedTaskNum`           | `3`                     |
| totalTaskNum 解析正确              | `data.totalTaskNum`              | `4`                     |
| isExtraTaskRewardReceived 解析正确 | `data.isExtraTaskRewardReceived` | `false`                 |
| remainResinDiscountNum 解析正确    | `data.remainResinDiscountNum`    | `2`                     |
| maxExpeditionNum 解析正确          | `data.maxExpeditionNum`          | `5`                     |

**派遣列表解析**

| 测试用例               | 字段                               | 预期值       |
| ---------------------- | ---------------------------------- | ------------ |
| 派遣数量正确           | `data.expeditions.length`          | `2`          |
| 进行中派遣 status 正确 | `data.expeditions[0].status`       | `'Ongoing'`  |
| 已完成派遣 status 正确 | `data.expeditions[1].status`       | `'Finished'` |
| 派遣剩余时间正确       | `data.expeditions[0].remainedTime` | `'3600'`     |

**参量质变仪解析**

| 测试用例          | 字段                        | 预期值  |
| ----------------- | --------------------------- | ------- |
| obtained 解析正确 | `data.transformer.obtained` | `true`  |
| reached 解析正确  | `data.transformer.reached`  | `false` |
| day 解析正确      | `data.transformer.day`      | `1`     |
| hour 解析正确     | `data.transformer.hour`     | `2`     |

**容错处理**

| 测试用例                         | 输入               | 预期结果                                          |
| -------------------------------- | ------------------ | ------------------------------------------------- |
| 无效 JSON                        | `'not valid json'` | 返回默认 `GenshinDailyNoteData`，`currentResin=0` |
| 空字符串                         | `''`               | 返回默认值，不抛异常                              |
| 空对象                           | `'{}'`             | 返回默认值，不抛异常                              |
| resinRecoveryTime 为非数字字符串 | `'invalid'`        | `resinRecoveryTime=0`                             |

### 3.4 StarRailDailyNoteParser（StarRailDailyNoteParser.test.ets）

被测类：`core/src/main/ets/parsers/starrail/StarRailDailyNoteParser.ets`

**正常解析**

| 测试用例                       | 字段                         | 预期值 |
| ------------------------------ | ---------------------------- | ------ |
| currentStamina 解析正确        | `data.currentStamina`        | `180`  |
| maxStamina 解析正确            | `data.maxStamina`            | `300`  |
| staminaRecoverTime 解析正确    | `data.staminaRecoverTime`    | `1800` |
| currentReserveStamina 解析正确 | `data.currentReserveStamina` | `2400` |
| isReserveStaminaFull 解析正确  | `data.isReserveStaminaFull`  | `true` |
| currentTrainScore 解析正确     | `data.currentTrainScore`     | `400`  |
| maxTrainScore 解析正确         | `data.maxTrainScore`         | `500`  |
| weeklyCocoonCnt 解析正确       | `data.weeklyCocoonCnt`       | `2`    |
| weeklyCocoonLimit 解析正确     | `data.weeklyCocoonLimit`     | `3`    |
| rogueTournWeeklyCur 解析正确   | `data.rogueTournWeeklyCur`   | `800`  |
| rogueTournWeeklyMax 解析正确   | `data.rogueTournWeeklyMax`   | `1000` |
| gridFightWeeklyCur 解析正确    | `data.gridFightWeeklyCur`    | `1`    |
| gridFightWeeklyMax 解析正确    | `data.gridFightWeeklyMax`    | `3`    |

**容错处理**

| 测试用例  | 输入        | 预期结果                                         |
| --------- | ----------- | ------------------------------------------------ |
| 无效 JSON | `'invalid'` | 返回默认值，`currentStamina=0`，`maxStamina=240` |
| 空字符串  | `''`        | 返回默认值，不抛异常                             |

### 3.5 ZZZDailyNoteParser（ZZZDailyNoteParser.test.ets）

被测类：`core/src/main/ets/parsers/zzz/ZZZDailyNoteParser.ets`

**正常解析**

| 测试用例                   | 字段                     | 预期值             |
| -------------------------- | ------------------------ | ------------------ |
| currentEnergy 解析正确     | `data.currentEnergy`     | `180`              |
| maxEnergy 解析正确         | `data.maxEnergy`         | `240`              |
| energyRecoverTime 解析正确 | `data.energyRecoverTime` | `3600`             |
| currentVitality 解析正确   | `data.currentVitality`   | `300`              |
| maxVitality 解析正确       | `data.maxVitality`       | `400`              |
| cardSign 解析正确          | `data.cardSign`          | `'CardSignDone'`   |
| videoStoreState 解析正确   | `data.videoStoreState`   | `'SaleStateDoing'` |
| abyssRefresh 解析正确      | `data.abyssRefresh`      | `86400`            |
| memberCardIsOpen 解析正确  | `data.memberCardIsOpen`  | `true`             |

**边界值**

| 测试用例                       | 输入                        | 预期结果                               |
| ------------------------------ | --------------------------- | -------------------------------------- |
| cardSign 为 CardSignNo         | `card_sign: 'CardSignNo'`   | `data.cardSign = 'CardSignNo'`         |
| videoStoreState 为 SaleStateNo | `sale_state: 'SaleStateNo'` | `data.videoStoreState = 'SaleStateNo'` |
| memberCardIsOpen 为 false      | `is_open: false`            | `data.memberCardIsOpen = false`        |

**容错处理**

| 测试用例  | 输入        | 预期结果                                       |
| --------- | ----------- | ---------------------------------------------- |
| 无效 JSON | `'invalid'` | 返回默认值，`currentEnergy=0`，`maxEnergy=240` |
| 空字符串  | `''`        | 返回默认值，不抛异常                           |

---

## 四、Repository 层（core/src/ohosTest/）

> Repository 层依赖 DAO（需要真实 RDB），必须在设备端运行。
> 不得与 API 层测试混用同一测试文件。

### 4.1 BBSRepository（BBSRepository.test.ets）

被测类：`core/src/main/ets/repository/v2/BBSRepository.ets`

| 测试用例                       | 前置条件                  | 操作                               | 预期结果                            |
| ------------------------------ | ------------------------- | ---------------------------------- | ----------------------------------- |
| saveAccount 写入新账号         | 表为空                    | `saveAccount(row)`                 | `getAllAccounts()` 返回 1 条        |
| saveAccount 更新已有账号       | 已有 username='u1'        | 再次 `saveAccount` 相同 username   | 仍只有 1 条，字段更新               |
| getAllAccounts 空表            | 表为空                    | `getAllAccounts()`                 | 返回空数组                          |
| getAccountById 存在            | 已有 id=1                 | `getAccountById(1)`                | 返回对应行                          |
| getAccountById 不存在          | 表为空                    | `getAccountById(999)`              | 返回 null                           |
| getAccountByUsername 存在      | 已有 username='u1'        | `getAccountByUsername('u1')`       | 返回对应行                          |
| deleteAccount 存在             | 已有 id=1                 | `deleteAccount(1)`                 | `getAccountById(1)` 返回 null       |
| saveGameRoles 批量写入         | 表为空                    | `saveGameRoles([row1, row2])`      | `getGameRoles(accountId)` 返回 2 条 |
| getGameRoles 按 accountId 过滤 | 已有不同 accountId 的数据 | `getGameRoles(1)`                  | 只返回 accountId=1 的数据           |
| getGameRolesByGame 过滤        | 已有原神和星铁角色        | `getGameRolesByGame(1, 'genshin')` | 只返回原神角色                      |
| deleteGameRoles 清空           | 已有 2 条                 | `deleteGameRoles(1)`               | `getGameRoles(1)` 返回空数组        |

### 4.2 GenshinRepository（GenshinRepository.test.ets）

被测类：`core/src/main/ets/repository/v2/GenshinRepository.ets`

| 测试用例                            | 操作                                       | 预期结果                                    |
| ----------------------------------- | ------------------------------------------ | ------------------------------------------- |
| getAvatarList 空表                  | `getAvatarList(1, 'uid1')`                 | 返回空数组                                  |
| upsertAvatarList 写入               | `upsertAvatarList(1, 'uid1', [row])`       | `getAvatarList` 返回 1 条                   |
| upsertAvatarList 同时更新 sync_meta | `upsertAvatarList(...)`                    | `sync_meta` 中对应记录 syncStatus='success' |
| needsAvatarListSync 无记录          | 表为空                                     | 返回 `true`                                 |
| needsAvatarListSync 刚同步          | lastSyncTime=now                           | 返回 `false`                                |
| needsAvatarListSync 超过阈值        | lastSyncTime=now-400                       | 返回 `true`                                 |
| getDailyNote 空表                   | `getDailyNote(1, 'uid1')`                  | 返回 null                                   |
| upsertDailyNote 写入                | `upsertDailyNote(1, 'uid1', row)`          | `getDailyNote` 返回对应行                   |
| upsertDailyNote 同时更新 sync_meta  | `upsertDailyNote(...)`                     | `sync_meta` 中对应记录 syncStatus='success' |
| getAvatarDetail 空表                | `getAvatarDetail(1, 'uid1', 'avatarId1')`  | 返回 null                                   |
| upsertAvatarDetails 写入            | `upsertAvatarDetails(1, 'uid1', [row])`    | `getAvatarDetail` 返回对应行                |
| getAvatarCompute 空表               | `getAvatarCompute(1, 'uid1', 'avatarId1')` | 返回 null                                   |
| upsertAvatarCompute 写入            | `upsertAvatarCompute(1, 'uid1', row)`      | `getAvatarCompute` 返回对应行               |

### 4.3 StarRailRepository（StarRailRepository.test.ets）

与 GenshinRepository 结构对称，测试用例相同，方法名对应：

| GenshinRepository     | StarRailRepository    |
| --------------------- | --------------------- |
| `getAvatarList`       | `getAvatarList`       |
| `upsertAvatarList`    | `upsertAvatarList`    |
| `needsAvatarListSync` | `needsAvatarListSync` |
| `getDailyNote`        | `getDailyNote`        |
| `upsertDailyNote`     | `upsertDailyNote`     |
| `getAvatarDetail`     | `getAvatarDetail`     |
| `upsertAvatarDetails` | `upsertAvatarDetails` |
| `getAvatarCompute`    | `getAvatarCompute`    |
| `upsertAvatarCompute` | `upsertAvatarCompute` |

### 4.4 ZZZRepository（ZZZRepository.test.ets）

与 StarRailRepository 结构完全对称，测试用例相同。

---

## 五、测试命名规范

```
{被测方法}_{测试场景}_{预期结果}

示例（本地单元测试）：
  parse_currentResin_isCorrect
  pathToFileName_batchCompute_usesSpecialMapping
  extractAccountId_emptyCookie_returns1AsFallback
  generateV1_format_isTimestampRandomMd5

示例（设备端测试）：
  upsert_newAccount_findAllReturns1
  upsert_duplicateUsername_updatesExisting
  findById_notExists_returnsNull
  runInTransaction_throws_rollsBack
```

## 六、测试文件注册

所有本地单元测试必须在 `core/src/test/List.test.ets` 中注册：

```typescript
import dsUtilV2Test from "./DSUtilV2.test";
import mockServiceBaseTest from "./MockServiceBase.test";
import genshinDailyNoteParserTest from "./GenshinDailyNoteParser.test";
import starRailDailyNoteParserTest from "./StarRailDailyNoteParser.test";
import zzzDailyNoteParserTest from "./ZZZDailyNoteParser.test";
import syncDataTypeTest from "./SyncDataType.test";
import rowModelsTest from "./RowModels.test";

export default function testsuite() {
  dsUtilV2Test();
  mockServiceBaseTest();
  genshinDailyNoteParserTest();
  starRailDailyNoteParserTest();
  zzzDailyNoteParserTest();
  syncDataTypeTest();
  rowModelsTest();
}
```

---

## 六、Unhappy Flow 和边界场景补充

> 以下用例补充到对应测试文件中，与 happy flow 用例并列。

### 6.1 DB 层 — 字段校验和约束违反

**AccountDao**

| 用例                       | 操作                                       | 预期结果                                                                |
| -------------------------- | ------------------------------------------ | ----------------------------------------------------------------------- |
| username 为空字符串时写入  | `upsert(row)` where `username=''`          | 写入成功（username 有 UNIQUE 约束但允许空字符串，需确认业务层是否拦截） |
| 重复 username 触发 REPLACE | 已有 username='u1'，再次写入 username='u1' | 旧记录被替换，id 可能变化                                               |
| cookie 为空字符串时写入    | `upsert(row)` where `cookie=''`            | 写入成功（DB 层不校验，业务层负责）                                     |
| deleteById 后 id 不复用    | 删除 id=1，再写入新账号                    | 新账号 id 不为 1（AUTOINCREMENT）                                       |

**GameRoleDao**

| 用例                              | 操作                         | 预期结果                  |
| --------------------------------- | ---------------------------- | ------------------------- |
| account_id 不存在于 account_table | 写入 accountId=999（不存在） | 抛出外键约束错误          |
| upsertAll 部分行失败              | 第 2 行 accountId 不存在     | 事务回滚，第 1 行也不写入 |

**GenshinCharacterListDao**

| 用例                         | 操作                                   | 预期结果                                      |
| ---------------------------- | -------------------------------------- | --------------------------------------------- |
| avatarId 为空字符串          | `upsertAll([row])` where `avatarId=''` | 写入成功（DB 层不校验，唯一索引允许空字符串） |
| roleUid 为空字符串           | `upsertAll([row])` where `roleUid=''`  | 写入成功（DB 层不校验）                       |
| rawJson 为空字符串           | `upsertAll([row])` where `rawJson=''`  | 写入成功（NOT NULL 约束，空字符串不是 NULL）  |
| rawJson 为超长字符串（>1MB） | 写入 1MB 的 rawJson                    | 写入成功（SQLite TEXT 无长度限制）            |

**SyncMetaDaoV2**

| 用例                         | 操作                                                 | 预期结果            |
| ---------------------------- | ---------------------------------------------------- | ------------------- |
| updateStatus 记录不存在时    | `updateStatus(999, 'uid', 'type', 'success')`        | 不抛异常，影响 0 行 |
| findOne 三个参数都匹配才返回 | 已有 (1, 'uid1', 'type1')，查询 (1, 'uid1', 'type2') | 返回 null           |

---

### 6.2 DB 层 — 事务和并发

| 用例                        | 操作                                                   | 预期结果                                      |
| --------------------------- | ------------------------------------------------------ | --------------------------------------------- |
| runInTransaction 内部抛异常 | 事务中执行 SQL 后抛 Error                              | 事务回滚，数据未写入                          |
| runInTransaction 嵌套调用   | 在事务内再次调用 runInTransaction                      | 不崩溃（SQLite 不支持嵌套事务，外层事务生效） |
| 连续快速写入同一唯一键      | 循环 100 次 upsert 同一 (accountId, roleUid, avatarId) | 最终只有 1 条记录，值为最后一次写入           |

---

### 6.3 API 层 — DSUtilV2 边界场景

| 用例                   | 操作                                   | 预期结果                                           |
| ---------------------- | -------------------------------------- | -------------------------------------------------- |
| salt 未预加载时生成 DS | 不调用 preloadSalts，直接 generateV1() | 返回格式正确的 DS（salt 为空字符串，MD5 仍可计算） |
| params 含特殊字符      | `params.set('key', 'val=ue&test')`     | DS 正常生成，不崩溃                                |
| params 含中文值        | `params.set('name', '旅行者')`         | DS 正常生成，不崩溃                                |
| body 为超长字符串      | body 为 10KB JSON 字符串               | DS 正常生成，不崩溃                                |
| 同一毫秒内两次调用     | 连续调用 generateV1() 两次             | 两次 DS 的 random 字段大概率不同（6 位随机）       |

---

### 6.4 API 层 — MockServiceBase.pathToFileName 边界场景

| 用例                       | 输入 path                  | 预期结果                                                   |
| -------------------------- | -------------------------- | ---------------------------------------------------------- |
| 路径只有斜杠               | `/`                        | `'.json'`（去掉首斜杠后为空字符串）                        |
| 路径为空字符串             | `''`                       | `'.json'`                                                  |
| 路径含多个连续斜杠         | `//game//record`           | `_game__record.json`（斜杠替换为下划线）                   |
| 路径含 query 但 query 为空 | `/game_record/api?`        | `game_record_api.json`（? 后为空，去掉后正常映射）         |
| 路径含 # fragment          | `/game_record/api#section` | `game_record_api#section.json`（# 不处理，保留在文件名中） |

---

### 6.5 API 层 — Parser 字段缺失和类型错误

**GenshinDailyNoteParser**

| 用例                                 | 输入 JSON                             | 预期结果                                                        |
| ------------------------------------ | ------------------------------------- | --------------------------------------------------------------- |
| current_resin 字段缺失               | `{}`                                  | `currentResin=0`（默认值）                                      |
| current_resin 为 null                | `{"current_resin": null}`             | `currentResin=0`（null 转为 0）                                 |
| resin_recovery_time 为数字而非字符串 | `{"resin_recovery_time": 3600}`       | `resinRecoveryTime=0`（parseInt 对数字返回 NaN，fallback 为 0） |
| expeditions 为 null                  | `{"expeditions": null}`               | `expeditions=[]`（不崩溃）                                      |
| expeditions 为空数组                 | `{"expeditions": []}`                 | `expeditions.length=0`                                          |
| transformer 字段缺失                 | `{}`                                  | 返回默认 GenshinTransformerData，不崩溃                         |
| transformer.recovery_time 字段缺失   | `{"transformer": {"obtained": true}}` | 不崩溃，day/hour/minute 为 0                                    |

**StarRailDailyNoteParser**

| 用例                           | 输入 JSON                        | 预期结果                                           |
| ------------------------------ | -------------------------------- | -------------------------------------------------- |
| grid_fight_weekly_cur 字段缺失 | 无此字段                         | `gridFightWeeklyCur=0`（`?? 0` 兜底）              |
| rogue_tourn_weekly_cur 为负数  | `{"rogue_tourn_weekly_cur": -1}` | `rogueTournWeeklyCur=-1`（不过滤负数，业务层处理） |
| max_stamina 为 0               | `{"max_stamina": 0}`             | `maxStamina=0`（不崩溃）                           |

**ZZZDailyNoteParser**

| 用例                     | 输入 JSON                       | 预期结果                                             |
| ------------------------ | ------------------------------- | ---------------------------------------------------- |
| energy 字段缺失          | `{}`                            | 不崩溃，`currentEnergy=0`                            |
| energy.progress 字段缺失 | `{"energy": {}}`                | 不崩溃，`currentEnergy=0`                            |
| vhs_sale 字段缺失        | 无此字段                        | `videoStoreState=''`                                 |
| member_card 字段缺失     | 无此字段                        | `memberCardIsOpen=false`                             |
| card_sign 为未知值       | `{"card_sign": "UnknownState"}` | `cardSign='UnknownState'`（透传，UI 层处理未知状态） |

---

### 6.6 Repository 层 — 边界场景

**GenshinRepository**

| 用例                               | 操作                              | 预期结果                           |
| ---------------------------------- | --------------------------------- | ---------------------------------- |
| upsertAvatarList 空数组            | `upsertAvatarList(1, 'uid1', [])` | 不崩溃，sync_meta 仍更新为 success |
| needsAvatarListSync lastSyncTime=0 | sync_meta 存在但 lastSyncTime=0   | 返回 true（0 距当前超过 300 秒）   |
| needsAvatarListSync 刚好 300 秒    | lastSyncTime=now-300              | 返回 false（等于阈值不触发）       |
| needsAvatarListSync 超过 300 秒    | lastSyncTime=now-301              | 返回 true                          |
| markAvatarListSyncing 记录不存在   | sync_meta 无对应记录              | 不崩溃（UPDATE 0 行）              |
| upsertDailyNote 覆盖旧数据         | 已有 (1, 'uid1') 的便笺           | 旧数据被覆盖，只保留 1 条          |
| getAvatarDetail 不存在             | DB 无对应 avatarId                | 返回 null，不崩溃                  |

---

## 七、DB 层极端测试场景（core/src/ohosTest/）

### 7.1 大批量写入和性能

| 用例                         | 操作                                            | 预期结果                            |
| ---------------------------- | ----------------------------------------------- | ----------------------------------- |
| 批量写入 100 条角色          | `upsertAll` 传入 100 条 GenshinCharacterListRow | 全部写入成功，`findAll` 返回 100 条 |
| 批量写入 500 条角色          | `upsertAll` 传入 500 条                         | 全部写入成功，不超时（< 5 秒）      |
| 批量 upsert 100 条相同唯一键 | 100 条 avatarId 相同                            | 最终只有 1 条，值为最后一次写入     |
| 批量写入后立即查询           | `upsertAll` 后立即 `findAll`                    | 查询结果与写入数量一致              |
| 连续 1000 次单条 upsert      | 循环 1000 次 `upsert`                           | 全部成功，不崩溃，不内存泄漏        |

---

### 7.2 数据隔离验证

| 用例                                      | 操作                                         | 预期结果                                          |
| ----------------------------------------- | -------------------------------------------- | ------------------------------------------------- |
| 不同 accountId 数据不互相污染             | 写入 accountId=1 和 accountId=2 的数据       | `findAll(1, 'uid1')` 只返回 accountId=1 的数据    |
| 不同 roleUid 数据不互相污染               | 写入 roleUid='uid1' 和 roleUid='uid2' 的数据 | `findAll(1, 'uid1')` 只返回 roleUid='uid1' 的数据 |
| 不同游戏数据不互相污染                    | 写入原神和星铁数据                           | 原神 DAO 查询不返回星铁数据                       |
| 删除 accountId=1 不影响 accountId=2       | `deleteByAccountId(1)`                       | accountId=2 的数据完整保留                        |
| 删除 roleUid='uid1' 不影响 roleUid='uid2' | `deleteAll(1, 'uid1')`                       | roleUid='uid2' 的数据完整保留                     |

---

### 7.3 级联删除验证（需要 RdbManagerV2 + 多个 DAO 配合）

> 级联删除由数据库层 `ON DELETE CASCADE` 保证，无需应用层手动删除关联数据。
> 测试前确认 `PRAGMA foreign_keys = ON` 已执行（`RdbManagerV2.init` 会自动执行）。

| 用例                           | 前置条件                                   | 操作                                   | 预期结果                                             |
| ------------------------------ | ------------------------------------------ | -------------------------------------- | ---------------------------------------------------- |
| 删除账号后角色数据级联删除     | accountId=1 有 game_role_table 数据        | 删除 account_table 中 id=1             | game_role_table 中 accountId=1 的数据全部删除        |
| 删除账号后原神数据级联删除     | accountId=1 有 genshin_character_list 数据 | 删除 account_table 中 id=1             | genshin_character_list 中 accountId=1 的数据全部删除 |
| 删除账号后星铁数据级联删除     | accountId=1 有 starrail_avatar_basic 数据  | 删除 account_table 中 id=1             | starrail_avatar_basic 中 accountId=1 的数据全部删除  |
| 删除账号后绝区零数据级联删除   | accountId=1 有 zzz_avatar_basic 数据       | 删除 account_table 中 id=1             | zzz_avatar_basic 中 accountId=1 的数据全部删除       |
| 删除账号后 sync_meta 级联删除  | accountId=1 有 sync_meta 数据              | 删除 account_table 中 id=1             | sync_meta 中 accountId=1 的数据全部删除              |
| 删除不存在的账号不影响其他数据 | accountId=2 有数据                         | 删除 account_table 中 id=999（不存在） | accountId=2 的数据完整保留                           |
| 级联删除不影响其他账号数据     | accountId=1 和 accountId=2 均有数据        | 删除 account_table 中 id=1             | accountId=2 的所有子表数据完整保留                   |
| 14 张子表全部级联删除          | accountId=1 在所有 14 张子表均有数据       | 删除 account_table 中 id=1             | 14 张子表中 accountId=1 的数据全部删除，无孤儿数据   |

---

### 7.4 数据完整性验证

| 用例                                 | 操作                                            | 预期结果                                   |
| ------------------------------------ | ----------------------------------------------- | ------------------------------------------ |
| rawJson 含 Unicode 字符              | 写入含中文/emoji 的 rawJson                     | 读取后内容与写入完全一致                   |
| rawJson 含换行符和制表符             | 写入含 `\n\t` 的 rawJson                        | 读取后内容与写入完全一致                   |
| rawJson 含单引号                     | 写入含 `'` 的 rawJson                           | 读取后内容与写入完全一致（SQL 注入防护）   |
| rawJson 含双引号                     | 写入含 `"` 的 rawJson                           | 读取后内容与写入完全一致                   |
| rawJson 含反斜杠                     | 写入含 `\\` 的 rawJson                          | 读取后内容与写入完全一致                   |
| 数值字段为 Integer.MAX（2147483647） | 写入 level=2147483647                           | 读取后值与写入一致                         |
| 数值字段为 0                         | 写入 level=0                                    | 读取后值为 0，不被过滤                     |
| 数值字段为负数                       | 写入 level=-1                                   | 读取后值为 -1（DB 层不校验正负）           |
| TEXT 字段为超长字符串（1MB）         | 写入 1MB 的 rawJson                             | 写入和读取成功，不崩溃                     |
| TEXT 字段含 SQL 注入尝试             | 写入 `'; DROP TABLE genshin_character_list; --` | 数据正常写入，表不被删除（参数化查询防护） |

---

### 7.5 SyncMetaDaoV2 极端场景

| 用例                                                      | 操作                            | 预期结果                                           |
| --------------------------------------------------------- | ------------------------------- | -------------------------------------------------- |
| 同一 (accountId, roleUid, dataType) 快速连续 updateStatus | 连续 10 次 updateStatus         | 最终状态为最后一次更新的值                         |
| updateStatus 为 success 时 lastSyncTime 精度              | `updateStatus(..., 'success')`  | lastSyncTime 为 Unix 秒级时间戳，精度正确          |
| lastSyncTime 为 0 时 needsSync 判断                       | sync_meta 存在但 lastSyncTime=0 | 距当前时间超过 300 秒，返回 true                   |
| lastSyncTime 为未来时间戳                                 | lastSyncTime=now+1000           | 距当前时间为负数，返回 false（未来时间不触发同步） |
| dataType 为未知枚举值                                     | 写入 dataType='unknown_table'   | 写入成功（DB 层不校验枚举值）                      |

---

## 八、API 层极端测试场景（core/src/test/）

### 8.1 DSUtilV2 极端场景

| 用例                      | 操作                                       | 预期结果                                     |
| ------------------------- | ------------------------------------------ | -------------------------------------------- |
| random 字符集只含字母数字 | 调用 100 次 generateV1()，检查 random 字段 | 每次 random 只含 a-z A-Z 0-9                 |
| MD5 结果始终为 32 位      | 调用 100 次 generateV1()                   | 每次 md5 段长度均为 32                       |
| timestamp 为合理 Unix 秒  | 调用 generateV1()                          | timestamp 在 [2020-01-01, 2100-01-01] 范围内 |
| params 含 100 个键值对    | 传入 100 个参数                            | DS 正常生成，不崩溃，不超时                  |
| params 键名含特殊字符     | `params.set('key=1', 'val')`               | DS 正常生成，不崩溃                          |
| params 值为数字 0         | `params.set('level', 0)`                   | 序列化为 `level=0`，不被过滤                 |
| params 值为负数           | `params.set('offset', -1)`                 | 序列化为 `offset=-1`                         |
| params 值为布尔 false     | `params.set('flag', false)`                | 序列化为 `flag=false`                        |
| params 值为 null          | `params.set('key', null)`                  | 序列化为 `key=null`，不崩溃                  |
| body 为空 JSON 对象       | `body = '{}'`                              | DS 正常生成                                  |
| body 含 Unicode           | `body = '{"name":"旅行者"}'`               | DS 正常生成，MD5 计算正确                    |
| 字典序排列验证            | params 含 `{z: 1, a: 2, m: 3}`             | query 序列化为 `a=2&m=3&z=1`                 |
| 单字符键名排序            | params 含 `{b: 1, a: 2}`                   | query 序列化为 `a=2&b=1`                     |
| 相同前缀键名排序          | params 含 `{role_id: 1, role: 2}`          | query 序列化为 `role=2&role_id=1`            |

---

### 8.2 MockServiceBase.pathToFileName 极端场景

| 用例                    | 输入 path                                   | 预期结果                                           |
| ----------------------- | ------------------------------------------- | -------------------------------------------------- |
| 路径含大写字母          | `/Game_Record/App`                          | `Game_Record_App.json`（不转小写，保留原始大小写） |
| 路径含数字              | `/api/v3/data`                              | `api_v3_data.json`                                 |
| 路径含连字符            | `/game-record/api`                          | `game-record_api.json`（连字符保留，斜杠转下划线） |
| 路径含点号              | `/api/v1.0/data`                            | `api_v1.0_data.json`（点号保留）                   |
| 路径含多个 query 参数   | `/api?a=1&b=2&c=3`                          | `api.json`（去掉所有 query）                       |
| 路径含 query 参数值为空 | `/api?key=`                                 | `api.json`                                         |
| 特殊映射路径含 query    | `/event/rpgcalc/compute?game=hkrpg&uid=123` | `hkrpg_character_compute.json`（特殊映射优先）     |
| 路径为特殊映射的前缀    | `/event/rpgcalc`                            | `event_rpgcalc.json`（不匹配特殊映射，走通用规则） |

---

### 8.3 MockServiceBase.extractAccountId 极端场景

| 用例                   | 输入 cookie                    | 预期结果                                                                     |
| ---------------------- | ------------------------------ | ---------------------------------------------------------------------------- |
| account_id=0           | `'account_id=0'`               | `0`（0 是有效值，不 fallback）                                               |
| account_id 为负数      | `'account_id=-1'`              | `1`（parseInt('-1') 为 -1，isNaN 为 false，返回 -1；需确认业务是否接受负数） |
| account_id 为浮点数    | `'account_id=1.5'`             | `1`（parseInt 截断小数部分）                                                 |
| account_id 为超大数    | `'account_id=99999999999'`     | `99999999999`（JavaScript 数字精度范围内）                                   |
| account_id 出现多次    | `'account_id=1; account_id=2'` | `1`（取第一个匹配）                                                          |
| account_id 值含字母    | `'account_id=abc'`             | `1`（parseInt('abc') 为 NaN，fallback）                                      |
| Cookie 含换行符        | `'account_id=1\nltoken=abc'`   | `1`（正则 `\d+` 不匹配换行，但 account_id=1 在换行前，应返回 1）             |
| Cookie 含 Unicode      | `'account_id=1; name=旅行者'`  | `1`                                                                          |
| Cookie 只有 account_id | `'account_id=5'`               | `5`                                                                          |
| Cookie 含空格          | `'account_id = 1'`             | `1`（fallback，因为正则匹配 `account_id=(\d+)` 不含空格）                    |

---

### 8.4 Parser 极端数值场景

**GenshinDailyNoteParser**

| 用例                               | 输入                               | 预期结果                                        |
| ---------------------------------- | ---------------------------------- | ----------------------------------------------- |
| current_resin 为 0                 | `{"current_resin": 0}`             | `currentResin=0`                                |
| current_resin 为最大值 200         | `{"current_resin": 200}`           | `currentResin=200`                              |
| current_resin 超过上限             | `{"current_resin": 999}`           | `currentResin=999`（Parser 不校验，业务层处理） |
| current_resin 为负数               | `{"current_resin": -1}`            | `currentResin=-1`（Parser 不校验）              |
| resin_recovery_time 为 "0"         | `{"resin_recovery_time": "0"}`     | `resinRecoveryTime=0`                           |
| resin_recovery_time 为 "86400"     | `{"resin_recovery_time": "86400"}` | `resinRecoveryTime=86400`（24 小时）            |
| max_expedition_num 为 0            | `{"max_expedition_num": 0}`        | `maxExpeditionNum=0`                            |
| expeditions 含 5 个元素            | 5 个派遣                           | `expeditions.length=5`                          |
| expeditions 含重复 avatarSideIcon  | 多个相同图标                       | 全部保留，不去重                                |
| transformer.recovery_time.Day 为 7 | `{"Day": 7}`                       | `transformer.day=7`                             |

**StarRailDailyNoteParser**

| 用例                                       | 输入                                                               | 预期结果                     |
| ------------------------------------------ | ------------------------------------------------------------------ | ---------------------------- |
| current_stamina 为 0                       | `{"current_stamina": 0}`                                           | `currentStamina=0`           |
| current_stamina 等于 max_stamina           | `{"current_stamina": 300, "max_stamina": 300}`                     | 两者相等，不崩溃             |
| current_reserve_stamina 为 2400（满）      | `{"current_reserve_stamina": 2400}`                                | `currentReserveStamina=2400` |
| is_reserve_stamina_full 为 true            | `{"is_reserve_stamina_full": true}`                                | `isReserveStaminaFull=true`  |
| weekly_cocoon_cnt 等于 weekly_cocoon_limit | `{"weekly_cocoon_cnt": 3, "weekly_cocoon_limit": 3}`               | 两者相等，不崩溃             |
| grid_fight_weekly_cur 为 0                 | `{"grid_fight_weekly_cur": 0}`                                     | `gridFightWeeklyCur=0`       |
| grid_fight_weekly_max 为 0                 | `{"grid_fight_weekly_max": 0}`                                     | `gridFightWeeklyMax=0`       |
| rogue_tourn_weekly_cur 超过 max            | `{"rogue_tourn_weekly_cur": 1001, "rogue_tourn_weekly_max": 1000}` | 两者均保留，不校验           |

**ZZZDailyNoteParser**

| 用例                                    | 输入                                                                 | 预期结果                                   |
| --------------------------------------- | -------------------------------------------------------------------- | ------------------------------------------ |
| energy.progress.current 为 0            | `{"energy": {"progress": {"current": 0, "max": 240}, "restore": 0}}` | `currentEnergy=0`                          |
| energy.progress.current 等于 max        | `{"current": 240, "max": 240}`                                       | `currentEnergy=240`，`energyRecoverTime=0` |
| energy.restore 为 0（已满）             | `{"restore": 0}`                                                     | `energyRecoverTime=0`                      |
| vitality.current 为 0                   | `{"vitality": {"current": 0, "max": 400}}`                           | `currentVitality=0`                        |
| vitality.current 等于 max               | `{"current": 400, "max": 400}`                                       | `currentVitality=400`                      |
| abyss_refresh 为 0                      | `{"abyss_refresh": 0}`                                               | `abyssRefresh=0`                           |
| card_sign 为 'CardSignDone'             | `{"card_sign": "CardSignDone"}`                                      | `cardSign='CardSignDone'`                  |
| card_sign 为 'CardSignNo'               | `{"card_sign": "CardSignNo"}`                                        | `cardSign='CardSignNo'`                    |
| vhs_sale.sale_state 为 'SaleStateDone'  | `{"vhs_sale": {"sale_state": "SaleStateDone"}}`                      | `videoStoreState='SaleStateDone'`          |
| vhs_sale.sale_state 为 'SaleStateDoing' | `{"vhs_sale": {"sale_state": "SaleStateDoing"}}`                     | `videoStoreState='SaleStateDoing'`         |
| vhs_sale.sale_state 为 'SaleStateNo'    | `{"vhs_sale": {"sale_state": "SaleStateNo"}}`                        | `videoStoreState='SaleStateNo'`            |
| member_card.is_open 为 false            | `{"member_card": {"is_open": false}}`                                | `memberCardIsOpen=false`                   |
| member_card.is_open 为 true             | `{"member_card": {"is_open": true}}`                                 | `memberCardIsOpen=true`                    |

---

### 8.5 Parser 类型错误和异常 JSON 场景

**通用（适用于三个 Parser）**

| 用例                        | 输入                           | 预期结果                                       |
| --------------------------- | ------------------------------ | ---------------------------------------------- |
| JSON 为数组而非对象         | `'[1, 2, 3]'`                  | 返回默认值，不崩溃                             |
| JSON 为数字                 | `'42'`                         | 返回默认值，不崩溃                             |
| JSON 为布尔值               | `'true'`                       | 返回默认值，不崩溃                             |
| JSON 为 null                | `'null'`                       | 返回默认值，不崩溃                             |
| JSON 含 BOM 头              | `'\uFEFF{"current_resin": 1}'` | 返回默认值或正确解析（取决于 JSON.parse 行为） |
| JSON 含注释（非标准）       | `'{"key": 1 // comment}'`      | 返回默认值（JSON.parse 不支持注释）            |
| JSON 含尾随逗号（非标准）   | `'{"key": 1,}'`                | 返回默认值（JSON.parse 不支持尾随逗号）        |
| JSON 嵌套层级极深（100 层） | 100 层嵌套的 JSON              | 不崩溃（栈溢出保护）                           |
| JSON 字符串含 \u0000        | `'{"key": "\u0000"}'`          | 正常解析，不崩溃                               |

**GenshinDailyNoteParser 特有**

| 用例                                   | 输入                                                         | 预期结果                                                      |
| -------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------- |
| expeditions 元素类型错误               | `{"expeditions": [1, 2, 3]}`                                 | 不崩溃，expeditions 解析失败时返回 []                         |
| expeditions 元素缺少字段               | `{"expeditions": [{}]}`                                      | 不崩溃，缺失字段使用默认值                                    |
| transformer 为 null                    | `{"transformer": null}`                                      | 不崩溃，返回默认 GenshinTransformerData                       |
| transformer.recovery_time 为 null      | `{"transformer": {"obtained": true, "recovery_time": null}}` | 不崩溃，day/hour/minute 为 0                                  |
| resin_recovery_time 为数字（非字符串） | `{"resin_recovery_time": 3600}`                              | `resinRecoveryTime=0`（parseInt(3600) 实际返回 3600，需确认） |
| home_coin_recovery_time 为 "0"         | `{"home_coin_recovery_time": "0"}`                           | `homeCoinRecoveryTime=0`                                      |
