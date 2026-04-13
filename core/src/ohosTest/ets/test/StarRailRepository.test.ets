import { describe, it, expect, beforeAll, beforeEach } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { RdbManager } from '../../../main/ets/database/RdbManager';
import { BBSRepository } from '../../../main/ets/repository/BBSRepository';
import { StarRailRepository } from '../../../main/ets/repository/StarRailRepository';
import { AccountRow } from '../../../main/ets/models/AccountRow';
import {
  StarRailAvatarBasicRow,
  StarRailDailyNoteRow,
  StarRailAvatarInfoRow,
  StarRailAvatarComputeRow
} from '../../../main/ets/models/StarRailRows';
import { SyncMetaDao } from '../../../main/ets/database/SyncMetaDao';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

async function getContext(): Promise<common.UIAbilityContext> {
  const delegator = AbilityDelegatorRegistry.getAbilityDelegator();
  const ability = await delegator.getCurrentTopAbility();
  return ability.context as common.UIAbilityContext;
}

const TEST_ACCOUNT_ID = '20002';
const TEST_ROLE_UID = 'sr_repo_uid';

function makeAvatarBasicRow(avatarId: string): StarRailAvatarBasicRow {
  const row = new StarRailAvatarBasicRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.avatarId = avatarId;
  row.name = 'sr_char_' + avatarId;
  row.element = 'Fire';
  row.rarity = 5;
  row.level = 80;
  row.rank = 0;
  row.baseType = 3;
  row.equipId = 'e001';
  row.equipName = '银河铁道之夜';
  row.equipRarity = 5;
  row.equipLevel = 80;
  row.equipRank = 1;
  row.icon = '';
  row.figurePath = '';
  row.elementId = 2;
  row.rawJson = '{}';
  row.updateTime = 0;
  return row;
}

function makeDailyNoteRow(): StarRailDailyNoteRow {
  const row = new StarRailDailyNoteRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.currentStamina = 180;
  row.maxStamina = 300;
  row.staminaRecoverTime = 1800;
  row.staminaFullTs = 0;
  row.currentReserveStamina = 2400;
  row.acceptedExpeditionNum = 2;
  row.totalExpeditionNum = 4;
  row.currentTrainScore = 400;
  row.maxTrainScore = 500;
  row.currentRogueScore = 0;
  row.maxRogueScore = 0;
  row.weeklyCocoonCnt = 2;
  row.weeklyCocoonLimit = 3;
  row.rogueTournWeeklyCur = 800;
  row.rogueTournWeeklyMax = 1000;
  row.gridFightWeeklyCur = 1;
  row.gridFightWeeklyMax = 3;
  row.rawJson = '{}';
  row.updateTime = 0;
  return row;
}

function makeAvatarInfoRow(avatarId: string): StarRailAvatarInfoRow {
  const row = new StarRailAvatarInfoRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.avatarId = avatarId;
  row.equipId = 'e001';
  row.equipLevel = 80;
  row.equipRank = 1;
  row.relicIds = '[]';
  row.skillTreeJson = '{}';
  row.rawJson = '{}';
  row.updateTime = 0;
  return row;
}

function makeAvatarComputeRow(avatarId: string): StarRailAvatarComputeRow {
  const row = new StarRailAvatarComputeRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.avatarId = avatarId;
  row.avatarConsumeJson = '[]';
  row.skillConsumeJson = '[]';
  row.equipmentConsumeJson = '[]';
  row.updateTime = 0;
  return row;
}

export default function starRailRepositoryTest() {
  const bbsRepo = new BBSRepository();
  const repo = new StarRailRepository();
  const syncMetaDao = new SyncMetaDao();

  beforeAll(async () => {
    await RdbManager.init(await getContext());
    const acc = new AccountRow();
    acc.id = 20002;
    acc.username = 'sr_repo_test_account';
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
    await store.executeSql('DELETE FROM starrail_daily_note WHERE account_id = ?', [TEST_ACCOUNT_ID]);
    await store.executeSql('DELETE FROM starrail_avatar_info WHERE account_id = ?', [TEST_ACCOUNT_ID]);
    await store.executeSql('DELETE FROM starrail_avatar_compute WHERE account_id = ?', [TEST_ACCOUNT_ID]);
    await store.executeSql('DELETE FROM sync_meta WHERE account_id = ?', [TEST_ACCOUNT_ID]);
  });

  describe('StarRailRepository', () => {

    it('getAvatarList_emptyTable_returnsEmptyArray', 0, async () => {
      const result = await repo.getAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(0);
    });

    it('upsertAvatarList_oneRow_getAvatarListReturnsOne', 0, async () => {
      await repo.upsertAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID, [makeAvatarBasicRow('sr_avatar_001')]);
      const result = await repo.getAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(1);
    });

    it('upsertAvatarList_updatesSyncMeta', 0, async () => {
      await repo.upsertAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID, [makeAvatarBasicRow('sr_avatar_sync')]);
      const meta = await syncMetaDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'starrail_avatar_basic');
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
      await repo.upsertAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID, [makeAvatarBasicRow('sr_avatar_recent')]);
      const result = await repo.needsAvatarListSync(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result).assertFalse();
    });

    it('needsAvatarListSync_exceededThreshold_returnsTrue', 0, async () => {
      const store = RdbManager.getRdbStore();
      const oldTime = Math.floor(Date.now() / 1000) - 400;
      await store.executeSql(
        "INSERT OR REPLACE INTO sync_meta (account_id, role_uid, data_type, last_sync_time, sync_status, error_msg) VALUES (?, ?, ?, ?, ?, ?)",
        [TEST_ACCOUNT_ID, TEST_ROLE_UID, 'starrail_avatar_basic', oldTime, 'success', '']
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
        expect(result.currentStamina).assertEqual(180);
      }
    });

    it('upsertDailyNote_updatesSyncMeta', 0, async () => {
      await repo.upsertDailyNote(TEST_ACCOUNT_ID, TEST_ROLE_UID, makeDailyNoteRow());
      const meta = await syncMetaDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'starrail_daily_note');
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
      await repo.upsertAvatarDetails(TEST_ACCOUNT_ID, TEST_ROLE_UID, [makeAvatarInfoRow('sr_info_001')]);
      const result = await repo.getAvatarDetail(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'sr_info_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('sr_info_001');
      }
    });

    it('getAvatarCompute_emptyTable_returnsNull', 0, async () => {
      const result = await repo.getAvatarCompute(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'nonexistent');
      expect(result === null).assertTrue();
    });

    it('upsertAvatarCompute_row_getAvatarComputeReturnsRow', 0, async () => {
      await repo.upsertAvatarCompute(TEST_ACCOUNT_ID, TEST_ROLE_UID, makeAvatarComputeRow('sr_compute_001'));
      const result = await repo.getAvatarCompute(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'sr_compute_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('sr_compute_001');
      }
    });

  });
}
