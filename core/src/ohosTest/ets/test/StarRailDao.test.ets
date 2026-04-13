import { describe, it, expect, beforeAll, beforeEach } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { RdbManager } from '../../../main/ets/database/RdbManager';
import { AccountDao } from '../../../main/ets/database/BBSDao';
import {
  StarRailAvatarBasicDao,
  StarRailDailyNoteDao,
  StarRailAvatarInfoDao,
  StarRailAvatarComputeDao
} from '../../../main/ets/database/StarRailDao';
import {
  StarRailAvatarBasicRow,
  StarRailDailyNoteRow,
  StarRailAvatarInfoRow,
  StarRailAvatarComputeRow
} from '../../../main/ets/models/StarRailRows';
import { AccountRow } from '../../../main/ets/models/AccountRow';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

async function getContext(): Promise<common.UIAbilityContext> {
  const delegator = AbilityDelegatorRegistry.getAbilityDelegator();
  const ability = await delegator.getCurrentTopAbility();
  return ability.context as common.UIAbilityContext;
}

const TEST_ACCOUNT_ID = '10002';
const TEST_ROLE_UID = 'sr_test_uid';
const TEST_ROLE_UID2 = 'sr_test_uid2';

function makeAvatarBasicRow(avatarId: string, roleUid: string = TEST_ROLE_UID): StarRailAvatarBasicRow {
  const row = new StarRailAvatarBasicRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = roleUid;
  row.avatarId = avatarId;
  row.name = 'sr_char_' + avatarId;
  row.element = 'Fire';
  row.rarity = 5;
  row.level = 80;
  row.rank = 0;
  row.baseType = 3;
  row.equipId = 'equip_001';
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

function makeDailyNoteRow(roleUid: string = TEST_ROLE_UID): StarRailDailyNoteRow {
  const row = new StarRailDailyNoteRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = roleUid;
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
  row.equipId = 'equip_001';
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

export default function starRailDaoTest() {
  const accountDao = new AccountDao();
  const avatarBasicDao = new StarRailAvatarBasicDao();
  const dailyNoteDao = new StarRailDailyNoteDao();
  const avatarInfoDao = new StarRailAvatarInfoDao();
  const avatarComputeDao = new StarRailAvatarComputeDao();

  beforeAll(async () => {
    await RdbManager.init(await getContext());
    const acc = new AccountRow();
    acc.id = 10002;
    acc.username = 'sr_dao_test_account';
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

  describe('StarRailAvatarBasicDao', () => {

    beforeEach(async () => {
      await avatarBasicDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      await avatarBasicDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID2);
    });

    it('upsertAll_twoRows_findAllReturnsTwo', 0, async () => {
      await avatarBasicDao.upsertAll([
        makeAvatarBasicRow('sr_avatar_001'),
        makeAvatarBasicRow('sr_avatar_002')
      ]);
      const result = await avatarBasicDao.findAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(2);
    });

    it('upsertAll_duplicateUniqueKey_updatesExisting', 0, async () => {
      const row = makeAvatarBasicRow('sr_dup');
      await avatarBasicDao.upsertAll([row]);
      row.level = 60;
      await avatarBasicDao.upsertAll([row]);
      const result = await avatarBasicDao.findAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const found = result.filter(r => r.avatarId === 'sr_dup');
      expect(found.length).assertEqual(1);
      expect(found[0].level).assertEqual(60);
    });

    it('findAll_filterByRoleUid_returnsOnlyMatching', 0, async () => {
      await avatarBasicDao.upsertAll([makeAvatarBasicRow('sr_uid1', TEST_ROLE_UID)]);
      await avatarBasicDao.upsertAll([makeAvatarBasicRow('sr_uid2', TEST_ROLE_UID2)]);
      const result = await avatarBasicDao.findAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(1);
      expect(result[0].avatarId).assertEqual('sr_uid1');
    });

    it('findByAvatarId_exists_returnsRow', 0, async () => {
      await avatarBasicDao.upsertAll([makeAvatarBasicRow('sr_find_001')]);
      const result = await avatarBasicDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'sr_find_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('sr_find_001');
      }
    });

    it('findByAvatarId_notExists_returnsNull', 0, async () => {
      const result = await avatarBasicDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'sr_nonexistent');
      expect(result === null).assertTrue();
    });

    it('deleteAll_clearsData_findAllReturnsEmpty', 0, async () => {
      await avatarBasicDao.upsertAll([makeAvatarBasicRow('sr_del')]);
      await avatarBasicDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const result = await avatarBasicDao.findAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(0);
    });

  });

  describe('StarRailDailyNoteDao', () => {

    beforeEach(async () => {
      await dailyNoteDao.deleteOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
    });

    it('upsert_newRow_findOneReturnsRow', 0, async () => {
      await dailyNoteDao.upsert(makeDailyNoteRow());
      const result = await dailyNoteDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.currentStamina).assertEqual(180);
      }
    });

    it('upsert_duplicateUniqueKey_updatesExisting', 0, async () => {
      await dailyNoteDao.upsert(makeDailyNoteRow());
      const row2 = makeDailyNoteRow();
      row2.currentStamina = 240;
      await dailyNoteDao.upsert(row2);
      const result = await dailyNoteDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.currentStamina).assertEqual(240);
      }
    });

    it('findOne_notExists_returnsNull', 0, async () => {
      const result = await dailyNoteDao.findOne(TEST_ACCOUNT_ID, 'sr_nonexistent_uid');
      expect(result === null).assertTrue();
    });

    it('deleteOne_exists_findOneReturnsNull', 0, async () => {
      await dailyNoteDao.upsert(makeDailyNoteRow());
      await dailyNoteDao.deleteOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const result = await dailyNoteDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result === null).assertTrue();
    });

  });

  describe('StarRailAvatarInfoDao', () => {

    beforeEach(async () => {
      await avatarInfoDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
    });

    it('upsertAll_oneRow_findByAvatarIdReturnsRow', 0, async () => {
      await avatarInfoDao.upsertAll([makeAvatarInfoRow('sr_info_001')]);
      const result = await avatarInfoDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'sr_info_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('sr_info_001');
      }
    });

    it('upsertAll_duplicateUniqueKey_updatesExisting', 0, async () => {
      const row = makeAvatarInfoRow('sr_info_dup');
      await avatarInfoDao.upsertAll([row]);
      row.equipLevel = 60;
      await avatarInfoDao.upsertAll([row]);
      const result = await avatarInfoDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'sr_info_dup');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.equipLevel).assertEqual(60);
      }
    });

    it('findByAvatarId_notExists_returnsNull', 0, async () => {
      const result = await avatarInfoDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'sr_info_nonexistent');
      expect(result === null).assertTrue();
    });

    it('deleteAll_clearsData_findByAvatarIdReturnsNull', 0, async () => {
      await avatarInfoDao.upsertAll([makeAvatarInfoRow('sr_info_del')]);
      await avatarInfoDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const result = await avatarInfoDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'sr_info_del');
      expect(result === null).assertTrue();
    });

  });

  describe('StarRailAvatarComputeDao', () => {

    beforeEach(async () => {
      await avatarComputeDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
    });

    it('upsert_newRow_findByAvatarIdReturnsRow', 0, async () => {
      await avatarComputeDao.upsert(makeAvatarComputeRow('sr_compute_001'));
      const result = await avatarComputeDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'sr_compute_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('sr_compute_001');
      }
    });

    it('upsert_duplicateUniqueKey_updatesExisting', 0, async () => {
      const row = makeAvatarComputeRow('sr_compute_dup');
      await avatarComputeDao.upsert(row);
      row.avatarConsumeJson = '[{"id":2}]';
      await avatarComputeDao.upsert(row);
      const result = await avatarComputeDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'sr_compute_dup');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarConsumeJson).assertEqual('[{"id":2}]');
      }
    });

    it('findByAvatarId_notExists_returnsNull', 0, async () => {
      const result = await avatarComputeDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'sr_compute_nonexistent');
      expect(result === null).assertTrue();
    });

    it('deleteAll_clearsData_findByAvatarIdReturnsNull', 0, async () => {
      await avatarComputeDao.upsert(makeAvatarComputeRow('sr_compute_del'));
      await avatarComputeDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const result = await avatarComputeDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'sr_compute_del');
      expect(result === null).assertTrue();
    });

  });
}
