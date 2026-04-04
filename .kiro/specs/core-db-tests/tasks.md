# Tasks

## Task List

### 1. DB 层设备端测试（core/src/ohosTest/）

- [ ] 1.1 新建 `core/src/ohosTest/ets/test/RdbManagerV2.test.ets`
  - 测试 `init(context)` 成功，`getRdbStore()` 返回非 null
  - 测试 `init` 幂等（重复调用不抛异常）
  - 测试 `createTables` 幂等（IF NOT EXISTS 保证，再次调用不抛异常）
  - 测试 `runInTransaction` 成功提交（数据写入成功，事务后可读取）
  - 测试 `runInTransaction` 失败回滚（事务中抛异常，数据未写入）
  - 测试 `user_version` 首次安装为 1（`PRAGMA user_version` 返回 1）
  - 测试 15 张表全部存在（查询 sqlite_master，验证所有表名）
  - 测试 `PRAGMA foreign_keys` 已开启（返回 1）

- [ ] 1.2 新建 `core/src/ohosTest/ets/test/BBSDao.test.ets`
  - **AccountDao 测试**
    - `upsert_newAccount_findAllReturns1`：upsert 新账号，findAll 返回 1 条
    - `upsert_duplicateUsername_updatesExisting`：upsert 相同 username，仍只有 1 条且字段更新
    - `findAll_emptyTable_returnsEmptyArray`：空表 findAll 返回空数组
    - `findAll_threeRecords_returnsThree`：3 条记录 findAll 返回 3 条
    - `findById_exists_returnsRow`：findById 存在的 id 返回对应行
    - `findById_notExists_returnsNull`：findById 不存在的 id 返回 null
    - `findByUsername_exists_returnsRow`：findByUsername 存在返回对应行
    - `findByUsername_notExists_returnsNull`：findByUsername 不存在返回 null
    - `deleteById_exists_rowRemoved`：deleteById 存在的 id，findById 返回 null
    - `deleteById_notExists_noException`：deleteById 不存在的 id 不抛异常
  - **GameRoleDao 测试**
    - `upsertAll_twoRows_findByAccountIdReturnsTwo`：批量写入 2 条，findByAccountId 返回 2 条
    - `upsertAll_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `upsertAll_emptyArray_noException`：空数组不抛异常
    - `findByAccountId_exists_returnsRows`：findByAccountId 存在返回对应行
    - `findByAccountId_notExists_returnsEmptyArray`：findByAccountId 不存在返回空数组
    - `findByAccountAndGame_exists_returnsRows`：findByAccountAndGame 存在返回对应行
    - `findByAccountAndGame_notExists_returnsEmptyArray`：findByAccountAndGame 不存在返回空数组
    - `deleteByAccountId_exists_rowsRemoved`：deleteByAccountId 后 findByAccountId 返回空数组

- [ ] 1.3 新建 `core/src/ohosTest/ets/test/GenshinDao.test.ets`
  - **GenshinCharacterListDao 测试**
    - `upsertAll_twoRows_findAllReturnsTwo`：写入 2 条，findAll 返回 2 条
    - `upsertAll_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `findAll_filterByRoleUid_returnsOnlyMatching`：不同 roleUid 数据，只返回指定 roleUid 的数据
    - `findByAvatarId_exists_returnsRow`：findByAvatarId 存在返回对应行
    - `findByAvatarId_notExists_returnsNull`：空表 findByAvatarId 返回 null
    - `deleteAll_clearsData_findAllReturnsEmpty`：deleteAll 后 findAll 返回空数组
  - **GenshinDailyNoteDao 测试**
    - `upsert_newRow_findOneReturnsRow`：upsert 写入，findOne 返回对应行
    - `upsert_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `findOne_notExists_returnsNull`：空表 findOne 返回 null
    - `deleteOne_exists_findOneReturnsNull`：deleteOne 后 findOne 返回 null
  - **GenshinCharacterDetailDao 测试**
    - `upsertAll_oneRow_findByAvatarIdReturnsRow`：写入 1 条，findByAvatarId 返回对应行
    - `upsertAll_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `findByAvatarId_notExists_returnsNull`：空表 findByAvatarId 返回 null
    - `deleteAll_clearsData_findByAvatarIdReturnsNull`：deleteAll 后 findByAvatarId 返回 null
  - **GenshinCharacterComputeDao 测试**
    - `upsert_newRow_findByAvatarIdReturnsRow`：upsert 写入，findByAvatarId 返回对应行
    - `upsert_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `findByAvatarId_notExists_returnsNull`：空表 findByAvatarId 返回 null

- [ ] 1.4 新建 `core/src/ohosTest/ets/test/StarRailDao.test.ets`
  - **StarRailAvatarBasicDao 测试**
    - `upsertAll_twoRows_findAllReturnsTwo`：写入 2 条，findAll 返回 2 条
    - `upsertAll_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `findAll_filterByRoleUid_returnsOnlyMatching`：不同 roleUid 数据，只返回指定 roleUid 的数据
    - `findByAvatarId_exists_returnsRow`：findByAvatarId 存在返回对应行
    - `findByAvatarId_notExists_returnsNull`：空表 findByAvatarId 返回 null
    - `deleteAll_clearsData_findAllReturnsEmpty`：deleteAll 后 findAll 返回空数组
  - **StarRailDailyNoteDao 测试**
    - `upsert_newRow_findOneReturnsRow`：upsert 写入，findOne 返回对应行
    - `upsert_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `findOne_notExists_returnsNull`：空表 findOne 返回 null
    - `deleteOne_exists_findOneReturnsNull`：deleteOne 后 findOne 返回 null
  - **StarRailAvatarInfoDao 测试**
    - `upsertAll_oneRow_findByAvatarIdReturnsRow`：写入 1 条，findByAvatarId 返回对应行
    - `upsertAll_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `findByAvatarId_notExists_returnsNull`：空表 findByAvatarId 返回 null
    - `deleteAll_clearsData_findByAvatarIdReturnsNull`：deleteAll 后 findByAvatarId 返回 null
  - **StarRailAvatarComputeDao 测试**
    - `upsert_newRow_findByAvatarIdReturnsRow`：upsert 写入，findByAvatarId 返回对应行
    - `upsert_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `findByAvatarId_notExists_returnsNull`：空表 findByAvatarId 返回 null
    - `deleteAll_clearsData_findByAvatarIdReturnsNull`：deleteAll 后 findByAvatarId 返回 null

- [ ] 1.5 新建 `core/src/ohosTest/ets/test/ZZZDao.test.ets`
  - **ZZZAvatarBasicDao 测试**
    - `upsertAll_twoRows_findAllReturnsTwo`：写入 2 条，findAll 返回 2 条
    - `upsertAll_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `findAll_filterByRoleUid_returnsOnlyMatching`：不同 roleUid 数据，只返回指定 roleUid 的数据
    - `findByAvatarId_exists_returnsRow`：findByAvatarId 存在返回对应行
    - `findByAvatarId_notExists_returnsNull`：空表 findByAvatarId 返回 null
    - `deleteAll_clearsData_findAllReturnsEmpty`：deleteAll 后 findAll 返回空数组
    - `upsertAll_awakenState1_storedAsString`：写入 awakenState=1，数据库存储为字符串 '1'
    - `findByAvatarId_awakenStateString_returnsNumber`：读取 awaken_state='1'，返回 number 类型 1
  - **ZZZDailyNoteDao 测试**
    - `upsert_newRow_findOneReturnsRow`：upsert 写入，findOne 返回对应行
    - `upsert_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `findOne_notExists_returnsNull`：空表 findOne 返回 null
    - `deleteOne_exists_findOneReturnsNull`：deleteOne 后 findOne 返回 null
  - **ZZZAvatarInfoDao 测试**
    - `upsertAll_oneRow_findByAvatarIdReturnsRow`：写入 1 条，findByAvatarId 返回对应行
    - `upsertAll_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `findByAvatarId_notExists_returnsNull`：空表 findByAvatarId 返回 null
    - `deleteAll_clearsData_findByAvatarIdReturnsNull`：deleteAll 后 findByAvatarId 返回 null
  - **ZZZAvatarComputeDao 测试**
    - `upsert_newRow_findByAvatarIdReturnsRow`：upsert 写入，findByAvatarId 返回对应行
    - `upsert_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
    - `findByAvatarId_notExists_returnsNull`：空表 findByAvatarId 返回 null
    - `deleteAll_clearsData_findByAvatarIdReturnsNull`：deleteAll 后 findByAvatarId 返回 null

- [ ] 1.6 新建 `core/src/ohosTest/ets/test/SyncMetaDaoV2.test.ets`
  - `upsert_newRow_findOneReturnsRow`：upsert 写入，findOne 返回对应行
  - `upsert_duplicateUniqueKey_updatesExisting`：相同唯一键再次写入，仍只有 1 条
  - `findOne_exists_returnsMatchingRow`：findOne 存在，返回字段与写入一致
  - `findOne_notExists_returnsNull`：空表 findOne 返回 null
  - `updateStatus_syncing_updatesSyncStatus`：updateStatus 为 syncing，syncStatus 变为 'syncing'，lastSyncTime 不变
  - `updateStatus_success_updatesSyncStatusAndTime`：updateStatus 为 success，syncStatus 变为 'success'，lastSyncTime 更新为当前时间戳
  - `updateStatus_failed_updatesSyncStatusAndErrorMsg`：updateStatus 为 failed，syncStatus 变为 'failed'，errorMsg 更新
  - `updateStatus_notExists_noException`：记录不存在时 updateStatus 不抛异常

- [ ] 1.7 更新 `core/src/ohosTest/ets/test/List.test.ets`
  - import 并注册以上 6 个新 DB 测试套件（RdbManagerV2、BBSDao、GenshinDao、StarRailDao、ZZZDao、SyncMetaDaoV2）

---

### 2. Repository 层设备端测试（core/src/ohosTest/）

- [ ] 2.1 新建 `core/src/ohosTest/ets/test/BBSRepository.test.ets`
  - `saveAccount_newAccount_getAllAccountsReturnsOne`：saveAccount 写入新账号，getAllAccounts 返回 1 条
  - `saveAccount_duplicateUsername_updatesExisting`：saveAccount 相同 username，仍只有 1 条且字段更新
  - `getAllAccounts_emptyTable_returnsEmptyArray`：空表 getAllAccounts 返回空数组
  - `getAccountById_exists_returnsRow`：getAccountById 存在返回对应行
  - `getAccountById_notExists_returnsNull`：getAccountById 不存在返回 null
  - `getAccountByUsername_exists_returnsRow`：getAccountByUsername 存在返回对应行
  - `deleteAccount_exists_cascadeDeletesGameRoles`：deleteAccount 存在（验证级联删除：子表数据同步删除）
  - `saveGameRoles_twoRows_getGameRolesReturnsTwo`：saveGameRoles 批量写入 2 条，getGameRoles 返回 2 条
  - `getGameRoles_filterByAccountId_returnsOnlyMatching`：getGameRoles 按 accountId 过滤
  - `getGameRolesByGame_filterByGame_returnsOnlyMatching`：getGameRolesByGame 按游戏过滤
  - `deleteGameRoles_clearsAll_getGameRolesReturnsEmpty`：deleteGameRoles 清空，getGameRoles 返回空数组

- [ ] 2.2 新建 `core/src/ohosTest/ets/test/GenshinRepository.test.ets`
  - `getAvatarList_emptyTable_returnsEmptyArray`：getAvatarList 空表返回空数组
  - `upsertAvatarList_oneRow_getAvatarListReturnsOne`：upsertAvatarList 写入，getAvatarList 返回 1 条
  - `upsertAvatarList_updatesSyncMeta`：upsertAvatarList 同时更新 sync_meta 为 success
  - `needsAvatarListSync_noRecord_returnsTrue`：无 sync_meta 记录，needsAvatarListSync 返回 true
  - `needsAvatarListSync_recentSync_returnsFalse`：lastSyncTime=now，needsAvatarListSync 返回 false
  - `needsAvatarListSync_exceededThreshold_returnsTrue`：lastSyncTime=now-400，needsAvatarListSync 返回 true
  - `getDailyNote_emptyTable_returnsNull`：getDailyNote 空表返回 null
  - `upsertDailyNote_row_getDailyNoteReturnsRow`：upsertDailyNote 写入，getDailyNote 返回对应行
  - `upsertDailyNote_updatesSyncMeta`：upsertDailyNote 同时更新 sync_meta 为 success
  - `getAvatarDetail_emptyTable_returnsNull`：getAvatarDetail 空表返回 null
  - `upsertAvatarDetails_oneRow_getAvatarDetailReturnsRow`：upsertAvatarDetails 写入，getAvatarDetail 返回对应行
  - `getAvatarCompute_emptyTable_returnsNull`：getAvatarCompute 空表返回 null
  - `upsertAvatarCompute_row_getAvatarComputeReturnsRow`：upsertAvatarCompute 写入，getAvatarCompute 返回对应行

- [ ] 2.3 新建 `core/src/ohosTest/ets/test/StarRailRepository.test.ets`
  - 与 GenshinRepository.test.ets 结构对称，方法名相同，测试用例命名规则相同
  - `getAvatarList_emptyTable_returnsEmptyArray`
  - `upsertAvatarList_oneRow_getAvatarListReturnsOne`
  - `upsertAvatarList_updatesSyncMeta`
  - `needsAvatarListSync_noRecord_returnsTrue`
  - `needsAvatarListSync_recentSync_returnsFalse`
  - `needsAvatarListSync_exceededThreshold_returnsTrue`
  - `getDailyNote_emptyTable_returnsNull`
  - `upsertDailyNote_row_getDailyNoteReturnsRow`
  - `upsertDailyNote_updatesSyncMeta`
  - `getAvatarDetail_emptyTable_returnsNull`
  - `upsertAvatarDetails_oneRow_getAvatarDetailReturnsRow`
  - `getAvatarCompute_emptyTable_returnsNull`
  - `upsertAvatarCompute_row_getAvatarComputeReturnsRow`

- [ ] 2.4 新建 `core/src/ohosTest/ets/test/ZZZRepository.test.ets`
  - 与 StarRailRepository.test.ets 结构完全对称，测试用例命名规则相同
  - `getAvatarList_emptyTable_returnsEmptyArray`
  - `upsertAvatarList_oneRow_getAvatarListReturnsOne`
  - `upsertAvatarList_updatesSyncMeta`
  - `needsAvatarListSync_noRecord_returnsTrue`
  - `needsAvatarListSync_recentSync_returnsFalse`
  - `needsAvatarListSync_exceededThreshold_returnsTrue`
  - `getDailyNote_emptyTable_returnsNull`
  - `upsertDailyNote_row_getDailyNoteReturnsRow`
  - `upsertDailyNote_updatesSyncMeta`
  - `getAvatarDetail_emptyTable_returnsNull`
  - `upsertAvatarDetails_oneRow_getAvatarDetailReturnsRow`
  - `getAvatarCompute_emptyTable_returnsNull`
  - `upsertAvatarCompute_row_getAvatarComputeReturnsRow`

- [ ] 2.5 更新 `core/src/ohosTest/ets/test/List.test.ets`
  - import 并注册以上 4 个新 Repository 测试套件（BBSRepository、GenshinRepository、StarRailRepository、ZZZRepository）
