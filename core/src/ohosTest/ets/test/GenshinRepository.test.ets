import { describe, it, expect, beforeAll, beforeEach } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { RdbManager } from '../../../main/ets/database/RdbManager';
import { BBSRepository } from '../../../main/ets/repository/BBSRepository';
import { GenshinRepository } from '../../../main/ets/repository/GenshinRepository';
import { AccountRow } from '../../../main/ets/models/AccountRow';
import {
  GenshinCharacterListRow,
  GenshinDailyNoteRow,
  GenshinCharacterDetailRow,
  GenshinCharacterComputeRow
} from '../../../main/ets/models/GenshinRows';
import { SyncMetaDao } from '../../../main/ets/database/SyncMetaDao';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

async function getContext(): Promise<common.UIAbilityContext> {
  const delegator = AbilityDelegatorRegistry.getAbilityDelegator();
  const ability = await delegator.getCurrentTopAbility();
  return ability.context as common.UIAbilityContext;
}

const TEST_ACCOUNT_ID = '20001';
const TEST_ROLE_UID = 'genshin_repo_uid';

function makeCharListRow(avatarId: string): GenshinCharacterListRow {
  const row = new GenshinCharacterListRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.avatarId = avatarId;
  row.name = 'char_' + avatarId;
  row.element = 'Pyro';
  row.rarity = 5;
  row.level = 90;
  row.fetter = 10;
  row.activedConstellationNum = 0;
  row.weaponType = 1;
  row.weaponId = 'w001';
  row.weaponName = '天空之刃';
  row.weaponRarity = 5;
  row.weaponLevel = 90;
  row.weaponAffixLevel = 1;
  row.icon = '';
  row.sideIcon = '';
  row.rawJson = '{}';
  row.updateTime = 0;
  return row;
}

function makeDailyNoteRow(): GenshinDailyNoteRow {
  const row = new GenshinDailyNoteRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.currentResin = 120;
  row.maxResin = 200;
  row.resinRecoveryTime = 3600;
  row.finishedTaskNum = 3;
  row.totalTaskNum = 4;
  row.remainResinDiscountNum = 2;
  row.currentExpeditionNum = 3;
  row.maxExpeditionNum = 5;
  row.currentHomeCoin = 1500;
  row.maxHomeCoin = 2400;
  row.transformerRecoveryDay = 0;
  row.rawJson = '{}';
  row.updateTime = 0;
  return row;
}

function makeCharDetailRow(avatarId: string): GenshinCharacterDetailRow {
  const row = new GenshinCharacterDetailRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.avatarId = avatarId;
  row.weaponId = 'w001';
  row.weaponLevel = 90;
  row.weaponAffixLevel = 1;
  row.relicIds = '[]';
  row.skillLevels = '{}';
  row.rawJson = '{}';
  row.updateTime = 0;
  return row;
}

function makeCharComputeRow(avatarId: string): GenshinCharacterComputeRow {
  const row = new GenshinCharacterComputeRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.avatarId = avatarId;
  row.avatarConsumeJson = '[]';
  row.skillConsumeJson = '[]';
  row.weaponConsumeJson = '[]';
  row.updateTime = 0;
  return row;
}

export default function genshinRepositoryTest() {
  const bbsRepo = new BBSRepository();
  const repo = new GenshinRepository();
  const syncMetaDao = new SyncMetaDao();

  beforeAll(async () => {
    await RdbManager.init(await getContext());
    const acc = new AccountRow();
    acc.id = 20001;
    acc.username = 'genshin_repo_test_account';
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
    await bbsRepo.saveAccount(acc);
  });

  beforeEach(async () => {
    await repo.deleteAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID);
    const store = RdbManager.getRdbStore();
    await store.executeSql(
      'DELETE FROM genshin_daily_note WHERE account_id = ?',
      [TEST_ACCOUNT_ID]
    );
    await store.executeSql(
      'DELETE FROM genshin_character_detail WHERE account_id = ?',
      [TEST_ACCOUNT_ID]
    );
    await store.executeSql(
      'DELETE FROM genshin_character_compute WHERE account_id = ?',
      [TEST_ACCOUNT_ID]
    );
    await store.executeSql(
      'DELETE FROM sync_meta WHERE account_id = ?',
      [TEST_ACCOUNT_ID]
    );
  });

  describe('GenshinRepository', () => {

    it('getAvatarList_emptyTable_returnsEmptyArray', 0, async () => {
      const result = await repo.getAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(0);
    });

    it('upsertAvatarList_oneRow_getAvatarListReturnsOne', 0, async () => {
      await repo.upsertAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID, [makeCharListRow('g_avatar_001')]);
      const result = await repo.getAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(1);
    });

    it('upsertAvatarList_updatesSyncMeta', 0, async () => {
      await repo.upsertAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID, [makeCharListRow('g_avatar_sync')]);
      const meta = await syncMetaDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'genshin_character_list');
      expect(meta !== null).assertTrue();
      if (meta !== null) {
        expect(meta.syncStatus).assertEqual('success');
      }
    });

    it('needsAvatarListSync_noRecord_returnsTrue', 0, async () => {
      const result = await repo.needsAvatarListSync(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result).assertTrue();
    });

    it('needsAvatarListSync_recentSync_returnsFalse', 0, async () => {
      await repo.upsertAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID, [makeCharListRow('g_avatar_recent')]);
      const result = await repo.needsAvatarListSync(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result).assertFalse();
    });

    it('needsAvatarListSync_exceededThreshold_returnsTrue', 0, async () => {
      // 手动写入一条 lastSyncTime 超过阈值的 sync_meta
      const store = RdbManager.getRdbStore();
      const oldTime = Math.floor(Date.now() / 1000) - 400;
      await store.executeSql(
        "INSERT OR REPLACE INTO sync_meta (account_id, role_uid, data_type, last_sync_time, sync_status, error_msg) VALUES (?, ?, ?, ?, ?, ?)",
        [TEST_ACCOUNT_ID, TEST_ROLE_UID, 'genshin_character_list', oldTime, 'success', '']
      );
      const result = await repo.needsAvatarListSync(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result).assertTrue();
    });

    it('getDailyNote_emptyTable_returnsNull', 0, async () => {
      const result = await repo.getDailyNote(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result === null).assertTrue();
    });

    it('upsertDailyNote_row_getDailyNoteReturnsRow', 0, async () => {
      await repo.upsertDailyNote(TEST_ACCOUNT_ID, TEST_ROLE_UID, makeDailyNoteRow());
      const result = await repo.getDailyNote(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.currentResin).assertEqual(120);
      }
    });

    it('upsertDailyNote_updatesSyncMeta', 0, async () => {
      await repo.upsertDailyNote(TEST_ACCOUNT_ID, TEST_ROLE_UID, makeDailyNoteRow());
      const meta = await syncMetaDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'genshin_daily_note');
      expect(meta !== null).assertTrue();
      if (meta !== null) {
        expect(meta.syncStatus).assertEqual('success');
      }
    });

    it('getAvatarDetail_emptyTable_returnsNull', 0, async () => {
      const result = await repo.getAvatarDetail(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'nonexistent');
      expect(result === null).assertTrue();
    });

    it('upsertAvatarDetails_oneRow_getAvatarDetailReturnsRow', 0, async () => {
      await repo.upsertAvatarDetails(TEST_ACCOUNT_ID, TEST_ROLE_UID, [makeCharDetailRow('g_detail_001')]);
      const result = await repo.getAvatarDetail(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'g_detail_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('g_detail_001');
      }
    });

    it('getAvatarCompute_emptyTable_returnsNull', 0, async () => {
      const result = await repo.getAvatarCompute(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'nonexistent');
      expect(result === null).assertTrue();
    });

    it('upsertAvatarCompute_row_getAvatarComputeReturnsRow', 0, async () => {
      await repo.upsertAvatarCompute(TEST_ACCOUNT_ID, TEST_ROLE_UID, makeCharComputeRow('g_compute_001'));
      const result = await repo.getAvatarCompute(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'g_compute_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('g_compute_001');
      }
    });

  });
}
