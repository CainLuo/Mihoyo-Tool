import { describe, it, expect, beforeAll, beforeEach } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { RdbManager } from '../../../main/ets/database/RdbManager';
import { BBSRepository } from '../../../main/ets/repository/BBSRepository';
import { ZZZRepository } from '../../../main/ets/repository/ZZZRepository';
import { AccountRow } from '../../../main/ets/models/AccountRow';
import {
  ZZZAvatarBasicRow,
  ZZZDailyNoteRow,
  ZZZAvatarInfoRow,
  ZZZAvatarComputeRow
} from '../../../main/ets/models/ZZZRows';
import { SyncMetaDao } from '../../../main/ets/database/SyncMetaDao';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

async function getContext(): Promise<common.UIAbilityContext> {
  const delegator = AbilityDelegatorRegistry.getAbilityDelegator();
  const ability = await delegator.getCurrentTopAbility();
  return ability.context as common.UIAbilityContext;
}

const TEST_ACCOUNT_ID = '20003';
const TEST_ROLE_UID = 'zzz_repo_uid';

function makeAvatarBasicRow(avatarId: string): ZZZAvatarBasicRow {
  const row = new ZZZAvatarBasicRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.avatarId = avatarId;
  row.nameMi18n = 'zzz_char_' + avatarId;
  row.fullNameMi18n = 'zzz_full_' + avatarId;
  row.elementType = 200;
  row.subElementType = 0;
  row.avatarProfession = 1;
  row.rarity = 'S';
  row.level = 60;
  row.rank = 0;
  row.campNameMi18n = '';
  row.groupIconPath = '';
  row.hollowIconPath = '';
  row.roleSquareUrl = '';
  row.awakenState = 1;
  row.rawJson = '{}';
  row.updateTime = 0;
  return row;
}

function makeDailyNoteRow(): ZZZDailyNoteRow {
  const row = new ZZZDailyNoteRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.energyCurrent = 180;
  row.energyMax = 240;
  row.energyRestore = 3600;
  row.vitalityCurrent = 300;
  row.vitalityMax = 400;
  row.vhsSaleState = 'SaleStateDoing';
  row.cardSign = 'CardSignNo';
  row.rawJson = '{}';
  row.updateTime = 0;
  return row;
}

function makeAvatarInfoRow(avatarId: string): ZZZAvatarInfoRow {
  const row = new ZZZAvatarInfoRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.avatarId = avatarId;
  row.weaponId = 'zzz_w001';
  row.weaponLevel = 60;
  row.weaponStar = 5;
  row.equipIds = '[]';
  row.skillLevelsJson = '{}';
  row.verticalPaintingUrl = '';
  row.rawJson = '{}';
  row.updateTime = 0;
  return row;
}

function makeAvatarComputeRow(avatarId: string): ZZZAvatarComputeRow {
  const row = new ZZZAvatarComputeRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = TEST_ROLE_UID;
  row.avatarId = avatarId;
  row.avatarConsumeJson = '[]';
  row.weaponConsumeJson = '[]';
  row.skillConsumeJson = '[]';
  row.updateTime = 0;
  return row;
}

export default function zzzRepositoryTest() {
  const bbsRepo = new BBSRepository();
  const repo = new ZZZRepository();
  const syncMetaDao = new SyncMetaDao();

  beforeAll(async () => {
    await RdbManager.init(await getContext());
    const acc = new AccountRow();
    acc.id = 20003;
    acc.username = 'zzz_repo_test_account';
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
    await store.executeSql('DELETE FROM zzz_daily_note WHERE account_id = ?', [TEST_ACCOUNT_ID]);
    await store.executeSql('DELETE FROM zzz_avatar_info WHERE account_id = ?', [TEST_ACCOUNT_ID]);
    await store.executeSql('DELETE FROM zzz_avatar_compute WHERE account_id = ?', [TEST_ACCOUNT_ID]);
    await store.executeSql('DELETE FROM sync_meta WHERE account_id = ?', [TEST_ACCOUNT_ID]);
  });

  describe('ZZZRepository', () => {

    it('getAvatarList_emptyTable_returnsEmptyArray', 0, async () => {
      const result = await repo.getAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(0);
    });

    it('upsertAvatarList_oneRow_getAvatarListReturnsOne', 0, async () => {
      await repo.upsertAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID, [makeAvatarBasicRow('zzz_avatar_001')]);
      const result = await repo.getAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(1);
    });

    it('upsertAvatarList_updatesSyncMeta', 0, async () => {
      await repo.upsertAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID, [makeAvatarBasicRow('zzz_avatar_sync')]);
      const meta = await syncMetaDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_avatar_basic');
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
      await repo.upsertAvatarList(TEST_ACCOUNT_ID, TEST_ROLE_UID, [makeAvatarBasicRow('zzz_avatar_recent')]);
      const result = await repo.needsAvatarListSync(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result).assertFalse();
    });

    it('needsAvatarListSync_exceededThreshold_returnsTrue', 0, async () => {
      const store = RdbManager.getRdbStore();
      const oldTime = Math.floor(Date.now() / 1000) - 400;
      await store.executeSql(
        "INSERT OR REPLACE INTO sync_meta (account_id, role_uid, data_type, last_sync_time, sync_status, error_msg) VALUES (?, ?, ?, ?, ?, ?)",
        [TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_avatar_basic', oldTime, 'success', '']
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
        expect(result.energyCurrent).assertEqual(180);
      }
    });

    it('upsertDailyNote_updatesSyncMeta', 0, async () => {
      await repo.upsertDailyNote(TEST_ACCOUNT_ID, TEST_ROLE_UID, makeDailyNoteRow());
      const meta = await syncMetaDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_daily_note');
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
      await repo.upsertAvatarDetails(TEST_ACCOUNT_ID, TEST_ROLE_UID, [makeAvatarInfoRow('zzz_info_001')]);
      const result = await repo.getAvatarDetail(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_info_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('zzz_info_001');
      }
    });

    it('getAvatarCompute_emptyTable_returnsNull', 0, async () => {
      const result = await repo.getAvatarCompute(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'nonexistent');
      expect(result === null).assertTrue();
    });

    it('upsertAvatarCompute_row_getAvatarComputeReturnsRow', 0, async () => {
      await repo.upsertAvatarCompute(TEST_ACCOUNT_ID, TEST_ROLE_UID, makeAvatarComputeRow('zzz_compute_001'));
      const result = await repo.getAvatarCompute(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_compute_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('zzz_compute_001');
      }
    });

  });
}
