# Requirements Document

## Introduction

本 Spec 专门覆盖 `core/src/ohosTest/` 下的设备端测试，分两层：DB 层（DAO + RdbManagerV2）和 Repository 层。所有测试需要真实 RDB，在模拟器上运行，使用 `@ohos/hypium` 框架。

## Glossary

- **RdbManagerV2**: 数据库管理器，负责初始化、建表、事务管理
- **AccountDao**: 操作 `account_table` 的 DAO 类
- **GameRoleDao**: 操作 `game_role_table` 的 DAO 类
- **GenshinCharacterListDao**: 操作 `genshin_character_list` 的 DAO 类
- **GenshinDailyNoteDao**: 操作 `genshin_daily_note` 的 DAO 类
- **GenshinCharacterDetailDao**: 操作 `genshin_character_detail` 的 DAO 类
- **GenshinCharacterComputeDao**: 操作 `genshin_character_compute` 的 DAO 类
- **StarRailAvatarBasicDao**: 操作 `starrail_avatar_basic` 的 DAO 类
- **StarRailDailyNoteDao**: 操作 `starrail_daily_note` 的 DAO 类
- **StarRailAvatarInfoDao**: 操作 `starrail_avatar_info` 的 DAO 类
- **StarRailAvatarComputeDao**: 操作 `starrail_avatar_compute` 的 DAO 类
- **ZZZAvatarBasicDao**: 操作 `zzz_avatar_basic` 的 DAO 类
- **ZZZDailyNoteDao**: 操作 `zzz_daily_note` 的 DAO 类
- **ZZZAvatarInfoDao**: 操作 `zzz_avatar_info` 的 DAO 类
- **ZZZAvatarComputeDao**: 操作 `zzz_avatar_compute` 的 DAO 类
- **SyncMetaDaoV2**: 操作 `sync_meta` 的 DAO 类
- **BBSRepository**: 账号和游戏角色的 Repository 层
- **GenshinRepository**: 原神数据的 Repository 层
- **StarRailRepository**: 星穹铁道数据的 Repository 层
- **ZZZRepository**: 绝区零数据的 Repository 层
- **ohosTest**: HarmonyOS 设备端测试目录，需要真实 RDB 环境
- **upsert**: INSERT OR REPLACE 操作，按唯一键冲突时更新已有记录
- **sync_meta**: 同步状态元数据表，记录每种数据类型的最后同步时间和状态

## Requirements

### Requirement 1: RdbManagerV2 初始化与基础功能

**User Story:** As a developer, I want RdbManagerV2 to correctly initialize the database and manage transactions, so that all DAO operations have a reliable database foundation.

#### Acceptance Criteria

1. WHEN `RdbManagerV2.init(context)` is called on an uninitialized database, THE RdbManagerV2 SHALL complete without throwing an exception and `getRdbStore()` SHALL return a non-null store instance.
2. WHEN `RdbManagerV2.init(context)` is called a second time on an already-initialized database, THE RdbManagerV2 SHALL complete without throwing an exception (idempotent behavior).
3. WHEN `createTables()` is called on a database that already has all tables, THE RdbManagerV2 SHALL complete without throwing an exception (IF NOT EXISTS guarantees idempotence).
4. WHEN `runInTransaction` is called with a function that executes SQL without throwing, THE RdbManagerV2 SHALL commit the transaction and the data SHALL be readable after the transaction.
5. WHEN `runInTransaction` is called with a function that throws an exception, THE RdbManagerV2 SHALL rollback the transaction and the data SHALL NOT be written to the database.
6. WHEN `runMigrations()` is called on a brand-new database, THE RdbManagerV2 SHALL set `PRAGMA user_version` to 1.
7. WHEN the database is initialized, THE RdbManagerV2 SHALL create exactly 15 tables, all of which SHALL be queryable from `sqlite_master`.
8. WHEN the database is initialized, THE RdbManagerV2 SHALL execute `PRAGMA foreign_keys = ON`, and querying `PRAGMA foreign_keys` SHALL return 1.

### Requirement 2: AccountDao CRUD 操作

**User Story:** As a developer, I want AccountDao to correctly persist and retrieve account records, so that user account data is reliably stored and queryable.

#### Acceptance Criteria

1. WHEN `AccountDao.upsert(row)` is called with a new account on an empty table, THE AccountDao SHALL insert the record and `findAll()` SHALL return exactly 1 row with fields matching the inserted values.
2. WHEN `AccountDao.upsert(row)` is called with the same `username` as an existing record, THE AccountDao SHALL update the existing record and `findAll()` SHALL still return exactly 1 row with the updated field values.
3. WHEN `AccountDao.findAll()` is called on an empty table, THE AccountDao SHALL return an empty array.
4. WHEN `AccountDao.findAll()` is called on a table with 3 records, THE AccountDao SHALL return an array of 3 rows.
5. WHEN `AccountDao.findById(id)` is called with an existing id, THE AccountDao SHALL return the corresponding row.
6. WHEN `AccountDao.findById(id)` is called with a non-existent id, THE AccountDao SHALL return null.
7. WHEN `AccountDao.findByUsername(username)` is called with an existing username, THE AccountDao SHALL return the corresponding row.
8. WHEN `AccountDao.findByUsername(username)` is called with a non-existent username, THE AccountDao SHALL return null.
9. WHEN `AccountDao.deleteById(id)` is called with an existing id, THE AccountDao SHALL delete the record and `findById(id)` SHALL return null.
10. WHEN `AccountDao.deleteById(id)` is called with a non-existent id, THE AccountDao SHALL complete without throwing an exception.

### Requirement 3: GameRoleDao CRUD 操作

**User Story:** As a developer, I want GameRoleDao to correctly persist and retrieve game role records, so that each account's game roles are reliably stored and queryable.

#### Acceptance Criteria

1. WHEN `GameRoleDao.upsertAll([row1, row2])` is called on an empty table, THE GameRoleDao SHALL insert both records and `findByAccountId` SHALL return 2 rows.
2. WHEN `GameRoleDao.upsertAll` is called with rows having the same `(accountId, gameId, roleId)` unique key as existing records, THE GameRoleDao SHALL update the existing records and the table SHALL still contain only 1 row with updated field values.
3. WHEN `GameRoleDao.upsertAll([])` is called with an empty array, THE GameRoleDao SHALL complete without throwing an exception and the table SHALL remain empty.
4. WHEN `GameRoleDao.findByAccountId(accountId)` is called with an accountId that has 2 records, THE GameRoleDao SHALL return 2 rows.
5. WHEN `GameRoleDao.findByAccountId(accountId)` is called with a non-existent accountId, THE GameRoleDao SHALL return an empty array.
6. WHEN `GameRoleDao.findByAccountAndGame(accountId, gameId)` is called with matching records, THE GameRoleDao SHALL return the corresponding rows.
7. WHEN `GameRoleDao.findByAccountAndGame(accountId, gameId)` is called with no matching records, THE GameRoleDao SHALL return an empty array.
8. WHEN `GameRoleDao.deleteByAccountId(accountId)` is called with an accountId that has 2 records, THE GameRoleDao SHALL delete all records and `findByAccountId(accountId)` SHALL return an empty array.

### Requirement 4: GenshinDao CRUD 操作

**User Story:** As a developer, I want GenshinDao classes to correctly persist and retrieve Genshin Impact game data, so that character lists, daily notes, character details, and compute data are reliably stored.

#### Acceptance Criteria

1. WHEN `GenshinCharacterListDao.upsertAll([row1, row2])` is called, THE GenshinCharacterListDao SHALL insert both records and `findAll(accountId, roleUid)` SHALL return 2 rows.
2. WHEN `GenshinCharacterListDao.upsertAll` is called with rows having the same `(accountId, roleUid, avatarId)` unique key, THE GenshinCharacterListDao SHALL update the existing record and only 1 row SHALL exist.
3. WHEN `GenshinCharacterListDao.findAll(accountId, roleUid)` is called with data from multiple roleUids, THE GenshinCharacterListDao SHALL return only rows matching the specified roleUid.
4. WHEN `GenshinCharacterListDao.findByAvatarId(accountId, roleUid, avatarId)` is called with an existing avatarId, THE GenshinCharacterListDao SHALL return the corresponding row.
5. WHEN `GenshinCharacterListDao.findByAvatarId` is called on an empty table, THE GenshinCharacterListDao SHALL return null.
6. WHEN `GenshinCharacterListDao.deleteAll(accountId, roleUid)` is called, THE GenshinCharacterListDao SHALL delete all matching records and `findAll` SHALL return an empty array.
7. WHEN `GenshinDailyNoteDao.upsert(row)` is called, THE GenshinDailyNoteDao SHALL insert the record and `findOne(accountId, roleUid)` SHALL return the corresponding row.
8. WHEN `GenshinDailyNoteDao.upsert` is called with the same `(accountId, roleUid)` unique key, THE GenshinDailyNoteDao SHALL update the existing record and only 1 row SHALL exist.
9. WHEN `GenshinDailyNoteDao.findOne` is called on an empty table, THE GenshinDailyNoteDao SHALL return null.
10. WHEN `GenshinDailyNoteDao.deleteOne(accountId, roleUid)` is called on an existing record, THE GenshinDailyNoteDao SHALL delete the record and `findOne` SHALL return null.
11. WHEN `GenshinCharacterDetailDao.upsertAll([row])` is called, THE GenshinCharacterDetailDao SHALL insert the record and `findByAvatarId` SHALL return the corresponding row.
12. WHEN `GenshinCharacterDetailDao.upsertAll` is called with the same `(accountId, roleUid, avatarId)` unique key, THE GenshinCharacterDetailDao SHALL update the existing record and only 1 row SHALL exist.
13. WHEN `GenshinCharacterDetailDao.findByAvatarId` is called on an empty table, THE GenshinCharacterDetailDao SHALL return null.
14. WHEN `GenshinCharacterDetailDao.deleteAll(accountId, roleUid)` is called, THE GenshinCharacterDetailDao SHALL delete all records and `findByAvatarId` SHALL return null.
15. WHEN `GenshinCharacterComputeDao.upsert(row)` is called, THE GenshinCharacterComputeDao SHALL insert the record and `findByAvatarId` SHALL return the corresponding row.
16. WHEN `GenshinCharacterComputeDao.upsert` is called with the same `(accountId, roleUid, avatarId)` unique key, THE GenshinCharacterComputeDao SHALL update the existing record and only 1 row SHALL exist.
17. WHEN `GenshinCharacterComputeDao.findByAvatarId` is called on an empty table, THE GenshinCharacterComputeDao SHALL return null.

### Requirement 5: StarRailDao CRUD 操作

**User Story:** As a developer, I want StarRailDao classes to correctly persist and retrieve Star Rail game data, so that avatar basics, daily notes, avatar info, and compute data are reliably stored.

#### Acceptance Criteria

1. WHEN `StarRailAvatarBasicDao.upsertAll([row1, row2])` is called, THE StarRailAvatarBasicDao SHALL insert both records and `findAll` SHALL return 2 rows.
2. WHEN `StarRailAvatarBasicDao.upsertAll` is called with the same `(accountId, roleUid, avatarId)` unique key, THE StarRailAvatarBasicDao SHALL update the existing record and only 1 row SHALL exist.
3. WHEN `StarRailAvatarBasicDao.findAll(accountId, roleUid)` is called with data from multiple roleUids, THE StarRailAvatarBasicDao SHALL return only rows matching the specified roleUid.
4. WHEN `StarRailAvatarBasicDao.findByAvatarId` is called with an existing avatarId, THE StarRailAvatarBasicDao SHALL return the corresponding row.
5. WHEN `StarRailAvatarBasicDao.findByAvatarId` is called on an empty table, THE StarRailAvatarBasicDao SHALL return null.
6. WHEN `StarRailAvatarBasicDao.deleteAll(accountId, roleUid)` is called, THE StarRailAvatarBasicDao SHALL delete all matching records and `findAll` SHALL return an empty array.
7. WHEN `StarRailDailyNoteDao.upsert(row)` is called, THE StarRailDailyNoteDao SHALL insert the record and `findOne` SHALL return the corresponding row.
8. WHEN `StarRailDailyNoteDao.upsert` is called with the same `(accountId, roleUid)` unique key, THE StarRailDailyNoteDao SHALL update the existing record and only 1 row SHALL exist.
9. WHEN `StarRailDailyNoteDao.findOne` is called on an empty table, THE StarRailDailyNoteDao SHALL return null.
10. WHEN `StarRailDailyNoteDao.deleteOne(accountId, roleUid)` is called on an existing record, THE StarRailDailyNoteDao SHALL delete the record and `findOne` SHALL return null.
11. WHEN `StarRailAvatarInfoDao.upsertAll([row])` is called, THE StarRailAvatarInfoDao SHALL insert the record and `findByAvatarId` SHALL return the corresponding row.
12. WHEN `StarRailAvatarInfoDao.upsertAll` is called with the same unique key, THE StarRailAvatarInfoDao SHALL update the existing record and only 1 row SHALL exist.
13. WHEN `StarRailAvatarInfoDao.findByAvatarId` is called on an empty table, THE StarRailAvatarInfoDao SHALL return null.
14. WHEN `StarRailAvatarInfoDao.deleteAll(accountId, roleUid)` is called, THE StarRailAvatarInfoDao SHALL delete all records and `findByAvatarId` SHALL return null.
15. WHEN `StarRailAvatarComputeDao.upsert(row)` is called, THE StarRailAvatarComputeDao SHALL insert the record and `findByAvatarId` SHALL return the corresponding row.
16. WHEN `StarRailAvatarComputeDao.upsert` is called with the same unique key, THE StarRailAvatarComputeDao SHALL update the existing record and only 1 row SHALL exist.
17. WHEN `StarRailAvatarComputeDao.findByAvatarId` is called on an empty table, THE StarRailAvatarComputeDao SHALL return null.
18. WHEN `StarRailAvatarComputeDao.deleteAll(accountId, roleUid)` is called, THE StarRailAvatarComputeDao SHALL delete all records and `findByAvatarId` SHALL return null.

### Requirement 6: ZZZDao CRUD 操作

**User Story:** As a developer, I want ZZZDao classes to correctly persist and retrieve ZZZ game data, including the special awakenState type conversion, so that all ZZZ data is reliably stored.

#### Acceptance Criteria

1. WHEN `ZZZAvatarBasicDao.upsertAll([row1, row2])` is called, THE ZZZAvatarBasicDao SHALL insert both records and `findAll` SHALL return 2 rows.
2. WHEN `ZZZAvatarBasicDao.upsertAll` is called with the same `(accountId, roleUid, avatarId)` unique key, THE ZZZAvatarBasicDao SHALL update the existing record and only 1 row SHALL exist.
3. WHEN `ZZZAvatarBasicDao.findAll(accountId, roleUid)` is called with data from multiple roleUids, THE ZZZAvatarBasicDao SHALL return only rows matching the specified roleUid.
4. WHEN `ZZZAvatarBasicDao.findByAvatarId` is called with an existing avatarId, THE ZZZAvatarBasicDao SHALL return the corresponding row.
5. WHEN `ZZZAvatarBasicDao.findByAvatarId` is called on an empty table, THE ZZZAvatarBasicDao SHALL return null.
6. WHEN `ZZZAvatarBasicDao.deleteAll(accountId, roleUid)` is called, THE ZZZAvatarBasicDao SHALL delete all matching records and `findAll` SHALL return an empty array.
7. WHEN `ZZZAvatarBasicDao.upsertAll` is called with a row where `awakenState=1`, THE ZZZAvatarBasicDao SHALL store the value as the string `'1'` in the database column.
8. WHEN `ZZZAvatarBasicDao.findByAvatarId` reads a row with `awaken_state='1'` from the database, THE ZZZAvatarBasicDao SHALL return the `awakenState` field as the number `1`.
9. WHEN `ZZZDailyNoteDao.upsert(row)` is called, THE ZZZDailyNoteDao SHALL insert the record and `findOne` SHALL return the corresponding row.
10. WHEN `ZZZDailyNoteDao.upsert` is called with the same `(accountId, roleUid)` unique key, THE ZZZDailyNoteDao SHALL update the existing record and only 1 row SHALL exist.
11. WHEN `ZZZDailyNoteDao.findOne` is called on an empty table, THE ZZZDailyNoteDao SHALL return null.
12. WHEN `ZZZDailyNoteDao.deleteOne(accountId, roleUid)` is called on an existing record, THE ZZZDailyNoteDao SHALL delete the record and `findOne` SHALL return null.
13. WHEN `ZZZAvatarInfoDao.upsertAll([row])` is called, THE ZZZAvatarInfoDao SHALL insert the record and `findByAvatarId` SHALL return the corresponding row.
14. WHEN `ZZZAvatarInfoDao.upsertAll` is called with the same unique key, THE ZZZAvatarInfoDao SHALL update the existing record and only 1 row SHALL exist.
15. WHEN `ZZZAvatarInfoDao.findByAvatarId` is called on an empty table, THE ZZZAvatarInfoDao SHALL return null.
16. WHEN `ZZZAvatarInfoDao.deleteAll(accountId, roleUid)` is called, THE ZZZAvatarInfoDao SHALL delete all records and `findByAvatarId` SHALL return null.
17. WHEN `ZZZAvatarComputeDao.upsert(row)` is called, THE ZZZAvatarComputeDao SHALL insert the record and `findByAvatarId` SHALL return the corresponding row.
18. WHEN `ZZZAvatarComputeDao.upsert` is called with the same unique key, THE ZZZAvatarComputeDao SHALL update the existing record and only 1 row SHALL exist.
19. WHEN `ZZZAvatarComputeDao.findByAvatarId` is called on an empty table, THE ZZZAvatarComputeDao SHALL return null.
20. WHEN `ZZZAvatarComputeDao.deleteAll(accountId, roleUid)` is called, THE ZZZAvatarComputeDao SHALL delete all records and `findByAvatarId` SHALL return null.

### Requirement 7: SyncMetaDaoV2 CRUD 操作

**User Story:** As a developer, I want SyncMetaDaoV2 to correctly persist and update sync status records, so that the application can track the synchronization state of each data type.

#### Acceptance Criteria

1. WHEN `SyncMetaDaoV2.upsert(row)` is called with a new record, THE SyncMetaDaoV2 SHALL insert the record and `findOne` SHALL return the corresponding row with matching fields.
2. WHEN `SyncMetaDaoV2.upsert` is called with the same `(accountId, roleUid, dataType)` unique key, THE SyncMetaDaoV2 SHALL update the existing record and only 1 row SHALL exist.
3. WHEN `SyncMetaDaoV2.findOne(accountId, roleUid, dataType)` is called with an existing record, THE SyncMetaDaoV2 SHALL return the row with all fields matching the inserted values.
4. WHEN `SyncMetaDaoV2.findOne` is called on an empty table, THE SyncMetaDaoV2 SHALL return null.
5. WHEN `SyncMetaDaoV2.updateStatus` is called with status `'syncing'` on an existing record, THE SyncMetaDaoV2 SHALL update `syncStatus` to `'syncing'` and SHALL NOT update `lastSyncTime`.
6. WHEN `SyncMetaDaoV2.updateStatus` is called with status `'success'` on an existing record, THE SyncMetaDaoV2 SHALL update `syncStatus` to `'success'` and SHALL update `lastSyncTime` to the current Unix timestamp.
7. WHEN `SyncMetaDaoV2.updateStatus` is called with status `'failed'` and an error message on an existing record, THE SyncMetaDaoV2 SHALL update `syncStatus` to `'failed'` and `errorMsg` to the provided message.
8. WHEN `SyncMetaDaoV2.updateStatus` is called on a non-existent record, THE SyncMetaDaoV2 SHALL complete without throwing an exception (UPDATE affects 0 rows).

### Requirement 8: BBSRepository 操作

**User Story:** As a developer, I want BBSRepository to correctly orchestrate account and game role persistence, so that the application can reliably manage user accounts and their associated game roles.

#### Acceptance Criteria

1. WHEN `BBSRepository.saveAccount(row)` is called with a new account, THE BBSRepository SHALL persist the account and `getAllAccounts()` SHALL return 1 row.
2. WHEN `BBSRepository.saveAccount(row)` is called with the same username as an existing account, THE BBSRepository SHALL update the existing account and `getAllAccounts()` SHALL still return 1 row with updated values.
3. WHEN `BBSRepository.getAllAccounts()` is called on an empty table, THE BBSRepository SHALL return an empty array.
4. WHEN `BBSRepository.getAccountById(id)` is called with an existing id, THE BBSRepository SHALL return the corresponding account row.
5. WHEN `BBSRepository.getAccountById(id)` is called with a non-existent id, THE BBSRepository SHALL return null.
6. WHEN `BBSRepository.getAccountByUsername(username)` is called with an existing username, THE BBSRepository SHALL return the corresponding account row.
7. WHEN `BBSRepository.deleteAccount(id)` is called with an existing account that has associated game roles, THE BBSRepository SHALL delete the account and `getAccountById(id)` SHALL return null, and the associated game roles SHALL also be deleted (cascade delete).
8. WHEN `BBSRepository.saveGameRoles([row1, row2])` is called, THE BBSRepository SHALL persist both roles and `getGameRoles(accountId)` SHALL return 2 rows.
9. WHEN `BBSRepository.getGameRoles(accountId)` is called with data from multiple accountIds, THE BBSRepository SHALL return only rows matching the specified accountId.
10. WHEN `BBSRepository.getGameRolesByGame(accountId, gameId)` is called, THE BBSRepository SHALL return only rows matching both accountId and gameId.
11. WHEN `BBSRepository.deleteGameRoles(accountId)` is called, THE BBSRepository SHALL delete all game roles for that accountId and `getGameRoles(accountId)` SHALL return an empty array.

### Requirement 9: GenshinRepository 操作

**User Story:** As a developer, I want GenshinRepository to correctly orchestrate Genshin Impact data persistence and sync state management, so that the application can reliably cache and track synchronization of all Genshin data types.

#### Acceptance Criteria

1. WHEN `GenshinRepository.getAvatarList(accountId, roleUid)` is called on an empty table, THE GenshinRepository SHALL return an empty array.
2. WHEN `GenshinRepository.upsertAvatarList(accountId, roleUid, [row])` is called, THE GenshinRepository SHALL persist the row and `getAvatarList` SHALL return 1 row.
3. WHEN `GenshinRepository.upsertAvatarList` is called, THE GenshinRepository SHALL also update the `sync_meta` record for `GENSHIN_CHARACTER_LIST` with `syncStatus='success'`.
4. WHEN `GenshinRepository.needsAvatarListSync(accountId, roleUid)` is called with no sync_meta record, THE GenshinRepository SHALL return `true`.
5. WHEN `GenshinRepository.needsAvatarListSync` is called with a `lastSyncTime` equal to the current time, THE GenshinRepository SHALL return `false`.
6. WHEN `GenshinRepository.needsAvatarListSync` is called with a `lastSyncTime` more than 300 seconds in the past, THE GenshinRepository SHALL return `true`.
7. WHEN `GenshinRepository.getDailyNote(accountId, roleUid)` is called on an empty table, THE GenshinRepository SHALL return null.
8. WHEN `GenshinRepository.upsertDailyNote(accountId, roleUid, row)` is called, THE GenshinRepository SHALL persist the row and `getDailyNote` SHALL return the corresponding row.
9. WHEN `GenshinRepository.upsertDailyNote` is called, THE GenshinRepository SHALL also update the `sync_meta` record for `GENSHIN_DAILY_NOTE` with `syncStatus='success'`.
10. WHEN `GenshinRepository.getAvatarDetail(accountId, roleUid, avatarId)` is called on an empty table, THE GenshinRepository SHALL return null.
11. WHEN `GenshinRepository.upsertAvatarDetails(accountId, roleUid, [row])` is called, THE GenshinRepository SHALL persist the row and `getAvatarDetail` SHALL return the corresponding row.
12. WHEN `GenshinRepository.getAvatarCompute(accountId, roleUid, avatarId)` is called on an empty table, THE GenshinRepository SHALL return null.
13. WHEN `GenshinRepository.upsertAvatarCompute(accountId, roleUid, row)` is called, THE GenshinRepository SHALL persist the row and `getAvatarCompute` SHALL return the corresponding row.

### Requirement 10: StarRailRepository 操作

**User Story:** As a developer, I want StarRailRepository to correctly orchestrate Star Rail data persistence and sync state management, symmetric to GenshinRepository, so that all Star Rail data types are reliably cached and tracked.

#### Acceptance Criteria

1. WHEN `StarRailRepository.getAvatarList(accountId, roleUid)` is called on an empty table, THE StarRailRepository SHALL return an empty array.
2. WHEN `StarRailRepository.upsertAvatarList(accountId, roleUid, [row])` is called, THE StarRailRepository SHALL persist the row and `getAvatarList` SHALL return 1 row.
3. WHEN `StarRailRepository.upsertAvatarList` is called, THE StarRailRepository SHALL also update the `sync_meta` record for `STARRAIL_AVATAR_BASIC` with `syncStatus='success'`.
4. WHEN `StarRailRepository.needsAvatarListSync(accountId, roleUid)` is called with no sync_meta record, THE StarRailRepository SHALL return `true`.
5. WHEN `StarRailRepository.needsAvatarListSync` is called with a `lastSyncTime` equal to the current time, THE StarRailRepository SHALL return `false`.
6. WHEN `StarRailRepository.needsAvatarListSync` is called with a `lastSyncTime` more than 300 seconds in the past, THE StarRailRepository SHALL return `true`.
7. WHEN `StarRailRepository.getDailyNote(accountId, roleUid)` is called on an empty table, THE StarRailRepository SHALL return null.
8. WHEN `StarRailRepository.upsertDailyNote(accountId, roleUid, row)` is called, THE StarRailRepository SHALL persist the row and `getDailyNote` SHALL return the corresponding row.
9. WHEN `StarRailRepository.upsertDailyNote` is called, THE StarRailRepository SHALL also update the `sync_meta` record for `STARRAIL_DAILY_NOTE` with `syncStatus='success'`.
10. WHEN `StarRailRepository.getAvatarDetail(accountId, roleUid, avatarId)` is called on an empty table, THE StarRailRepository SHALL return null.
11. WHEN `StarRailRepository.upsertAvatarDetails(accountId, roleUid, [row])` is called, THE StarRailRepository SHALL persist the row and `getAvatarDetail` SHALL return the corresponding row.
12. WHEN `StarRailRepository.getAvatarCompute(accountId, roleUid, avatarId)` is called on an empty table, THE StarRailRepository SHALL return null.
13. WHEN `StarRailRepository.upsertAvatarCompute(accountId, roleUid, row)` is called, THE StarRailRepository SHALL persist the row and `getAvatarCompute` SHALL return the corresponding row.

### Requirement 11: ZZZRepository 操作

**User Story:** As a developer, I want ZZZRepository to correctly orchestrate ZZZ data persistence and sync state management, symmetric to StarRailRepository, so that all ZZZ data types are reliably cached and tracked.

#### Acceptance Criteria

1. WHEN `ZZZRepository.getAvatarList(accountId, roleUid)` is called on an empty table, THE ZZZRepository SHALL return an empty array.
2. WHEN `ZZZRepository.upsertAvatarList(accountId, roleUid, [row])` is called, THE ZZZRepository SHALL persist the row and `getAvatarList` SHALL return 1 row.
3. WHEN `ZZZRepository.upsertAvatarList` is called, THE ZZZRepository SHALL also update the `sync_meta` record for `ZZZ_AVATAR_BASIC` with `syncStatus='success'`.
4. WHEN `ZZZRepository.needsAvatarListSync(accountId, roleUid)` is called with no sync_meta record, THE ZZZRepository SHALL return `true`.
5. WHEN `ZZZRepository.needsAvatarListSync` is called with a `lastSyncTime` equal to the current time, THE ZZZRepository SHALL return `false`.
6. WHEN `ZZZRepository.needsAvatarListSync` is called with a `lastSyncTime` more than 300 seconds in the past, THE ZZZRepository SHALL return `true`.
7. WHEN `ZZZRepository.getDailyNote(accountId, roleUid)` is called on an empty table, THE ZZZRepository SHALL return null.
8. WHEN `ZZZRepository.upsertDailyNote(accountId, roleUid, row)` is called, THE ZZZRepository SHALL persist the row and `getDailyNote` SHALL return the corresponding row.
9. WHEN `ZZZRepository.upsertDailyNote` is called, THE ZZZRepository SHALL also update the `sync_meta` record for `ZZZ_DAILY_NOTE` with `syncStatus='success'`.
10. WHEN `ZZZRepository.getAvatarDetail(accountId, roleUid, avatarId)` is called on an empty table, THE ZZZRepository SHALL return null.
11. WHEN `ZZZRepository.upsertAvatarDetails(accountId, roleUid, [row])` is called, THE ZZZRepository SHALL persist the row and `getAvatarDetail` SHALL return the corresponding row.
12. WHEN `ZZZRepository.getAvatarCompute(accountId, roleUid, avatarId)` is called on an empty table, THE ZZZRepository SHALL return null.
13. WHEN `ZZZRepository.upsertAvatarCompute(accountId, roleUid, row)` is called, THE ZZZRepository SHALL persist the row and `getAvatarCompute` SHALL return the corresponding row.

### Requirement 12: 测试隔离与基础设施

**User Story:** As a developer, I want each test case to run in isolation with a clean database state, so that test results are reliable and not affected by other tests.

#### Acceptance Criteria

1. THE Test_Suite SHALL initialize the database via `RdbManagerV2.init(context)` in `beforeAll` before any test cases run.
2. WHEN each test case starts, THE Test_Suite SHALL clear all relevant table data via `beforeEach` to ensure test independence.
3. THE DB_Layer_Tests SHALL be placed in `core/src/ohosTest/ets/test/` and SHALL NOT import or depend on Repository layer classes.
4. THE Repository_Layer_Tests SHALL be placed in `core/src/ohosTest/ets/test/` and SHALL NOT be mixed with DB layer test files.
5. THE List_Test_File at `core/src/ohosTest/ets/test/List.test.ets` SHALL import and register all DB layer and Repository layer test suites.
