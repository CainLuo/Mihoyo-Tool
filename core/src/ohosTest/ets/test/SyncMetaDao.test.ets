import { describe, it, expect, beforeAll, beforeEach } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { RdbManager } from '../../../main/ets/database/RdbManager';
import { AccountDao } from '../../../main/ets/database/BBSDao';
import { SyncMetaDao } from '../../../main/ets/database/SyncMetaDao';
import { SyncMetaRow } from '../../../main/ets/models/SyncMetaRow';
import { AccountRow } from '../../../main/ets/models/AccountRow';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

async function getContext(): Promise<common.UIAbilityContext> {
  const delegator = AbilityDelegatorRegistry.getAbilityDelegator();
  const ability = await delegator.getCurrentTopAbility();
  return ability.context as common.UIAbilityContext;
}

const TEST_ACCOUNT_ID = '10004';
const TEST_ROLE_UID = 'sync_test_uid';
const TEST_DATA_TYPE = 'genshin_character_list';

function makeSyncMetaRow(dataType: string = TEST_DATA_TYPE): SyncMetaRow {
  const row = new SyncMetaRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.dataType = dataType;
  row.lastSyncTime = 0;
  row.syncStatus = 'syncing';
  row.errorMsg = '';
  return row;
}

export default function syncMetaDaoTest() {
  const accountDao = new AccountDao();
  const syncMetaDao = new SyncMetaDao();

  beforeAll(async () => {
    await RdbManager.init(await getContext());
    const acc = new AccountRow();
    acc.id = 10004;
    acc.username = 'sync_dao_test_account';
    acc.cookie = '';
    acc.stoken = '';
    acc.stuid = '';
    acc.mid = '';
    acc.isActive = 0;
    acc.createTime = 0;
    acc.updateTime = 0;
    acc.uid = '';
    acc.nickname = '';
    acc.avatarUrl = '';
    acc.introduce = '';
    await accountDao.upsert(acc);
  });

  beforeEach(async () => {
    // 清理测试数据
    const store = RdbManager.getRdbStore();
    await store.executeSql(
      'DELETE FROM sync_meta WHERE account_id = ?',
      [TEST_ACCOUNT_ID]
    );
  });

  describe('SyncMetaDao', () => {

    it('upsert_newRow_findOneReturnsRow', 0, async () => {
      await syncMetaDao.upsert(makeSyncMetaRow());
      const result = await syncMetaDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, TEST_DATA_TYPE);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.accountId).assertEqual(TEST_ACCOUNT_ID);
        expect(result.roleUid).assertEqual(TEST_ROLE_UID);
        expect(result.dataType).assertEqual(TEST_DATA_TYPE);
      }
    });

    it('upsert_duplicateUniqueKey_updatesExisting', 0, async () => {
      await syncMetaDao.upsert(makeSyncMetaRow());
      const row2 = makeSyncMetaRow();
      row2.syncStatus = 'success';
      row2.lastSyncTime = 1000;
      await syncMetaDao.upsert(row2);
      const result = await syncMetaDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, TEST_DATA_TYPE);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.syncStatus).assertEqual('success');
        expect(result.lastSyncTime).assertEqual(1000);
      }
    });

    it('findOne_exists_returnsMatchingRow', 0, async () => {
      const row = makeSyncMetaRow();
      row.syncStatus = 'success';
      row.lastSyncTime = 9999;
      await syncMetaDao.upsert(row);
      const result = await syncMetaDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, TEST_DATA_TYPE);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.syncStatus).assertEqual('success');
        expect(result.lastSyncTime).assertEqual(9999);
        expect(result.errorMsg).assertEqual('');
      }
    });

    it('findOne_notExists_returnsNull', 0, async () => {
      const result = await syncMetaDao.findOne(TEST_ACCOUNT_ID, 'nonexistent_uid', TEST_DATA_TYPE);
      expect(result === null).assertTrue();
    });

    it('updateStatus_syncing_updatesSyncStatus', 0, async () => {
      const row = makeSyncMetaRow();
      row.lastSyncTime = 5000;
      await syncMetaDao.upsert(row);
      await syncMetaDao.updateStatus(TEST_ACCOUNT_ID, TEST_ROLE_UID, TEST_DATA_TYPE, 'syncing');
      const result = await syncMetaDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, TEST_DATA_TYPE);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.syncStatus).assertEqual('syncing');
        // lastSyncTime 不应被 syncing 更新
        expect(result.lastSyncTime).assertEqual(5000);
      }
    });

    it('updateStatus_success_updatesSyncStatusAndTime', 0, async () => {
      await syncMetaDao.upsert(makeSyncMetaRow());
      const beforeTime = Math.floor(Date.now() / 1000);
      await syncMetaDao.updateStatus(TEST_ACCOUNT_ID, TEST_ROLE_UID, TEST_DATA_TYPE, 'success');
      const afterTime = Math.floor(Date.now() / 1000);
      const result = await syncMetaDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, TEST_DATA_TYPE);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.syncStatus).assertEqual('success');
        expect(result.lastSyncTime >= beforeTime).assertTrue();
        expect(result.lastSyncTime <= afterTime + 1).assertTrue();
      }
    });

    it('updateStatus_failed_updatesSyncStatusAndErrorMsg', 0, async () => {
      await syncMetaDao.upsert(makeSyncMetaRow());
      await syncMetaDao.updateStatus(TEST_ACCOUNT_ID, TEST_ROLE_UID, TEST_DATA_TYPE, 'failed', 'network error');
      const result = await syncMetaDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, TEST_DATA_TYPE);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.syncStatus).assertEqual('failed');
        expect(result.errorMsg).assertEqual('network error');
      }
    });

    it('updateStatus_notExists_noException', 0, async () => {
      let threw = false;
      try {
        await syncMetaDao.updateStatus(TEST_ACCOUNT_ID, 'nonexistent_uid', 'nonexistent_type', 'success');
      } catch (_) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

  });
}
