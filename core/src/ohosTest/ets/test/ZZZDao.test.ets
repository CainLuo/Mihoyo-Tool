import { describe, it, expect, beforeAll, beforeEach } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { RdbManager } from '../../../main/ets/database/RdbManager';
import { AccountDao } from '../../../main/ets/database/BBSDao';
import {
  ZZZAvatarBasicDao,
  ZZZDailyNoteDao,
  ZZZAvatarInfoDao,
  ZZZAvatarComputeDao
} from '../../../main/ets/database/ZZZDao';
import {
  ZZZAvatarBasicRow,
  ZZZDailyNoteRow,
  ZZZAvatarInfoRow,
  ZZZAvatarComputeRow
} from '../../../main/ets/models/ZZZRows';
import { AccountRow } from '../../../main/ets/models/AccountRow';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

function getContext(): common.UIAbilityContext {
  return AbilityDelegatorRegistry.getAbilityDelegator().getAppContext() as common.UIAbilityContext;
}

const TEST_ACCOUNT_ID = 10003;
const TEST_ROLE_UID = 'zzz_test_uid';
const TEST_ROLE_UID2 = 'zzz_test_uid2';

function makeAvatarBasicRow(avatarId: string, roleUid: string = TEST_ROLE_UID): ZZZAvatarBasicRow {
  const row = new ZZZAvatarBasicRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = roleUid;
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

function makeDailyNoteRow(roleUid: string = TEST_ROLE_UID): ZZZDailyNoteRow {
  const row = new ZZZDailyNoteRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = roleUid;
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
  row.weaponId = 'zzz_weapon_001';
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

export default function zzzDaoTest() {
  const accountDao = new AccountDao();
  const avatarBasicDao = new ZZZAvatarBasicDao();
  const dailyNoteDao = new ZZZDailyNoteDao();
  const avatarInfoDao = new ZZZAvatarInfoDao();
  const avatarComputeDao = new ZZZAvatarComputeDao();

  beforeAll(async () => {
    await RdbManager.init(getContext());
    const acc = new AccountRow();
    acc.id = TEST_ACCOUNT_ID;
    acc.username = 'zzz_dao_test_account';
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

  describe('ZZZAvatarBasicDao', () => {

    beforeEach(async () => {
      await avatarBasicDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      await avatarBasicDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID2);
    });

    it('upsertAll_twoRows_findAllReturnsTwo', 0, async () => {
      await avatarBasicDao.upsertAll([
        makeAvatarBasicRow('zzz_avatar_001'),
        makeAvatarBasicRow('zzz_avatar_002')
      ]);
      const result = await avatarBasicDao.findAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(2);
    });

    it('upsertAll_duplicateUniqueKey_updatesExisting', 0, async () => {
      const row = makeAvatarBasicRow('zzz_dup');
      await avatarBasicDao.upsertAll([row]);
      row.level = 40;
      await avatarBasicDao.upsertAll([row]);
      const result = await avatarBasicDao.findAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const found = result.filter(r => r.avatarId === 'zzz_dup');
      expect(found.length).assertEqual(1);
      expect(found[0].level).assertEqual(40);
    });

    it('findAll_filterByRoleUid_returnsOnlyMatching', 0, async () => {
      await avatarBasicDao.upsertAll([makeAvatarBasicRow('zzz_uid1', TEST_ROLE_UID)]);
      await avatarBasicDao.upsertAll([makeAvatarBasicRow('zzz_uid2', TEST_ROLE_UID2)]);
      const result = await avatarBasicDao.findAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(1);
      expect(result[0].avatarId).assertEqual('zzz_uid1');
    });

    it('findByAvatarId_exists_returnsRow', 0, async () => {
      await avatarBasicDao.upsertAll([makeAvatarBasicRow('zzz_find_001')]);
      const result = await avatarBasicDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_find_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('zzz_find_001');
      }
    });

    it('findByAvatarId_notExists_returnsNull', 0, async () => {
      const result = await avatarBasicDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_nonexistent');
      expect(result === null).assertTrue();
    });

    it('deleteAll_clearsData_findAllReturnsEmpty', 0, async () => {
      await avatarBasicDao.upsertAll([makeAvatarBasicRow('zzz_del')]);
      await avatarBasicDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const result = await avatarBasicDao.findAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(0);
    });

    it('upsertAll_awakenState1_storedAndReadAsNumber', 0, async () => {
      const row = makeAvatarBasicRow('zzz_awaken');
      row.awakenState = 1;
      await avatarBasicDao.upsertAll([row]);
      const result = await avatarBasicDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_awaken');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(typeof result.awakenState).assertEqual('number');
        expect(result.awakenState).assertEqual(1);
      }
    });

  });

  describe('ZZZDailyNoteDao', () => {

    beforeEach(async () => {
      await dailyNoteDao.deleteOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
    });

    it('upsert_newRow_findOneReturnsRow', 0, async () => {
      await dailyNoteDao.upsert(makeDailyNoteRow());
      const result = await dailyNoteDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.energyCurrent).assertEqual(180);
        expect(result.vhsSaleState).assertEqual('SaleStateDoing');
        expect(result.cardSign).assertEqual('CardSignNo');
      }
    });

    it('upsert_duplicateUniqueKey_updatesExisting', 0, async () => {
      await dailyNoteDao.upsert(makeDailyNoteRow());
      const row2 = makeDailyNoteRow();
      row2.energyCurrent = 200;
      await dailyNoteDao.upsert(row2);
      const result = await dailyNoteDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.energyCurrent).assertEqual(200);
      }
    });

    it('findOne_notExists_returnsNull', 0, async () => {
      const result = await dailyNoteDao.findOne(TEST_ACCOUNT_ID, 'zzz_nonexistent_uid');
      expect(result === null).assertTrue();
    });

    it('deleteOne_exists_findOneReturnsNull', 0, async () => {
      await dailyNoteDao.upsert(makeDailyNoteRow());
      await dailyNoteDao.deleteOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const result = await dailyNoteDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result === null).assertTrue();
    });

  });

  describe('ZZZAvatarInfoDao', () => {

    beforeEach(async () => {
      await avatarInfoDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
    });

    it('upsertAll_oneRow_findByAvatarIdReturnsRow', 0, async () => {
      await avatarInfoDao.upsertAll([makeAvatarInfoRow('zzz_info_001')]);
      const result = await avatarInfoDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_info_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('zzz_info_001');
      }
    });

    it('upsertAll_duplicateUniqueKey_updatesExisting', 0, async () => {
      const row = makeAvatarInfoRow('zzz_info_dup');
      await avatarInfoDao.upsertAll([row]);
      row.weaponLevel = 40;
      await avatarInfoDao.upsertAll([row]);
      const result = await avatarInfoDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_info_dup');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.weaponLevel).assertEqual(40);
      }
    });

    it('findByAvatarId_notExists_returnsNull', 0, async () => {
      const result = await avatarInfoDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_info_nonexistent');
      expect(result === null).assertTrue();
    });

    it('deleteAll_clearsData_findByAvatarIdReturnsNull', 0, async () => {
      await avatarInfoDao.upsertAll([makeAvatarInfoRow('zzz_info_del')]);
      await avatarInfoDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const result = await avatarInfoDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_info_del');
      expect(result === null).assertTrue();
    });

  });

  describe('ZZZAvatarComputeDao', () => {

    beforeEach(async () => {
      await avatarComputeDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
    });

    it('upsert_newRow_findByAvatarIdReturnsRow', 0, async () => {
      await avatarComputeDao.upsert(makeAvatarComputeRow('zzz_compute_001'));
      const result = await avatarComputeDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_compute_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('zzz_compute_001');
      }
    });

    it('upsert_duplicateUniqueKey_updatesExisting', 0, async () => {
      const row = makeAvatarComputeRow('zzz_compute_dup');
      await avatarComputeDao.upsert(row);
      row.weaponConsumeJson = '[{"id":3}]';
      await avatarComputeDao.upsert(row);
      const result = await avatarComputeDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_compute_dup');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.weaponConsumeJson).assertEqual('[{"id":3}]');
      }
    });

    it('findByAvatarId_notExists_returnsNull', 0, async () => {
      const result = await avatarComputeDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_compute_nonexistent');
      expect(result === null).assertTrue();
    });

    it('deleteAll_clearsData_findByAvatarIdReturnsNull', 0, async () => {
      await avatarComputeDao.upsert(makeAvatarComputeRow('zzz_compute_del'));
      await avatarComputeDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const result = await avatarComputeDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'zzz_compute_del');
      expect(result === null).assertTrue();
    });

  });
}
