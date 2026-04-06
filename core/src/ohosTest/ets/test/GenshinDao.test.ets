import { describe, it, expect, beforeAll, beforeEach } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { RdbManager } from '../../../main/ets/database/RdbManager';
import { AccountDao } from '../../../main/ets/database/BBSDao';
import {
  GenshinCharacterListDao,
  GenshinDailyNoteDao,
  GenshinCharacterDetailDao,
  GenshinCharacterComputeDao
} from '../../../main/ets/database/GenshinDao';
import {
  GenshinCharacterListRow,
  GenshinDailyNoteRow,
  GenshinCharacterDetailRow,
  GenshinCharacterComputeRow
} from '../../../main/ets/models/GenshinRows';
import { AccountRow } from '../../../main/ets/models/AccountRow';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

function getContext(): common.UIAbilityContext {
  return AbilityDelegatorRegistry.getAbilityDelegator().getAppContext() as common.UIAbilityContext;
}

const TEST_ACCOUNT_ID = 10001;
const TEST_ROLE_UID = 'genshin_test_uid';
const TEST_ROLE_UID2 = 'genshin_test_uid2';
const TEST_AVATAR_ID = 'avatar_10000001';

function makeCharListRow(avatarId: string, roleUid: string = TEST_ROLE_UID): GenshinCharacterListRow {
  const row = new GenshinCharacterListRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = roleUid;
  row.avatarId = avatarId;
  row.name = 'char_' + avatarId;
  row.element = 'Pyro';
  row.rarity = 5;
  row.level = 90;
  row.fetter = 10;
  row.activedConstellationNum = 6;
  row.weaponType = 1;
  row.weaponId = 'weapon_001';
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

function makeDailyNoteRow(roleUid: string = TEST_ROLE_UID): GenshinDailyNoteRow {
  const row = new GenshinDailyNoteRow();
  row.accountId = TEST_ACCOUNT_ID;
  row.roleUid = roleUid;
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
  row.weaponId = 'weapon_001';
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

export default function genshinDaoTest() {
  const accountDao = new AccountDao();
  const charListDao = new GenshinCharacterListDao();
  const dailyNoteDao = new GenshinDailyNoteDao();
  const charDetailDao = new GenshinCharacterDetailDao();
  const charComputeDao = new GenshinCharacterComputeDao();

  beforeAll(async () => {
    await RdbManager.init(getContext());
    // 确保测试账号存在（外键约束）
    const acc = new AccountRow();
    acc.id = TEST_ACCOUNT_ID;
    acc.username = 'genshin_dao_test_account';
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

  describe('GenshinCharacterListDao', () => {

    beforeEach(async () => {
      await charListDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      await charListDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID2);
    });

    it('upsertAll_twoRows_findAllReturnsTwo', 0, async () => {
      await charListDao.upsertAll([
        makeCharListRow('avatar_001'),
        makeCharListRow('avatar_002')
      ]);
      const result = await charListDao.findAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(2);
    });

    it('upsertAll_duplicateUniqueKey_updatesExisting', 0, async () => {
      const row = makeCharListRow('avatar_dup');
      await charListDao.upsertAll([row]);
      row.level = 80;
      await charListDao.upsertAll([row]);
      const result = await charListDao.findAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const found = result.filter(r => r.avatarId === 'avatar_dup');
      expect(found.length).assertEqual(1);
      expect(found[0].level).assertEqual(80);
    });

    it('findAll_filterByRoleUid_returnsOnlyMatching', 0, async () => {
      await charListDao.upsertAll([makeCharListRow('avatar_uid1', TEST_ROLE_UID)]);
      await charListDao.upsertAll([makeCharListRow('avatar_uid2', TEST_ROLE_UID2)]);
      const result = await charListDao.findAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(1);
      expect(result[0].avatarId).assertEqual('avatar_uid1');
    });

    it('findByAvatarId_exists_returnsRow', 0, async () => {
      await charListDao.upsertAll([makeCharListRow(TEST_AVATAR_ID)]);
      const result = await charListDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, TEST_AVATAR_ID);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual(TEST_AVATAR_ID);
      }
    });

    it('findByAvatarId_notExists_returnsNull', 0, async () => {
      const result = await charListDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'nonexistent_avatar');
      expect(result === null).assertTrue();
    });

    it('deleteAll_clearsData_findAllReturnsEmpty', 0, async () => {
      await charListDao.upsertAll([makeCharListRow('avatar_del')]);
      await charListDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const result = await charListDao.findAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result.length).assertEqual(0);
    });

  });

  describe('GenshinDailyNoteDao', () => {

    beforeEach(async () => {
      await dailyNoteDao.deleteOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
    });

    it('upsert_newRow_findOneReturnsRow', 0, async () => {
      await dailyNoteDao.upsert(makeDailyNoteRow());
      const result = await dailyNoteDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.currentResin).assertEqual(120);
      }
    });

    it('upsert_duplicateUniqueKey_updatesExisting', 0, async () => {
      await dailyNoteDao.upsert(makeDailyNoteRow());
      const row2 = makeDailyNoteRow();
      row2.currentResin = 160;
      await dailyNoteDao.upsert(row2);
      const result = await dailyNoteDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.currentResin).assertEqual(160);
      }
    });

    it('findOne_notExists_returnsNull', 0, async () => {
      const result = await dailyNoteDao.findOne(TEST_ACCOUNT_ID, 'nonexistent_uid');
      expect(result === null).assertTrue();
    });

    it('deleteOne_exists_findOneReturnsNull', 0, async () => {
      await dailyNoteDao.upsert(makeDailyNoteRow());
      await dailyNoteDao.deleteOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const result = await dailyNoteDao.findOne(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      expect(result === null).assertTrue();
    });

  });

  describe('GenshinCharacterDetailDao', () => {

    beforeEach(async () => {
      await charDetailDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
    });

    it('upsertAll_oneRow_findByAvatarIdReturnsRow', 0, async () => {
      await charDetailDao.upsertAll([makeCharDetailRow('detail_avatar_001')]);
      const result = await charDetailDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'detail_avatar_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('detail_avatar_001');
      }
    });

    it('upsertAll_duplicateUniqueKey_updatesExisting', 0, async () => {
      const row = makeCharDetailRow('detail_dup');
      await charDetailDao.upsertAll([row]);
      row.weaponLevel = 80;
      await charDetailDao.upsertAll([row]);
      const result = await charDetailDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'detail_dup');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.weaponLevel).assertEqual(80);
      }
    });

    it('findByAvatarId_notExists_returnsNull', 0, async () => {
      const result = await charDetailDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'nonexistent_detail');
      expect(result === null).assertTrue();
    });

    it('deleteAll_clearsData_findByAvatarIdReturnsNull', 0, async () => {
      await charDetailDao.upsertAll([makeCharDetailRow('detail_del')]);
      await charDetailDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
      const result = await charDetailDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'detail_del');
      expect(result === null).assertTrue();
    });

  });

  describe('GenshinCharacterComputeDao', () => {

    beforeEach(async () => {
      await charComputeDao.deleteAll(TEST_ACCOUNT_ID, TEST_ROLE_UID);
    });

    it('upsert_newRow_findByAvatarIdReturnsRow', 0, async () => {
      await charComputeDao.upsert(makeCharComputeRow('compute_avatar_001'));
      const result = await charComputeDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'compute_avatar_001');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarId).assertEqual('compute_avatar_001');
      }
    });

    it('upsert_duplicateUniqueKey_updatesExisting', 0, async () => {
      const row = makeCharComputeRow('compute_dup');
      await charComputeDao.upsert(row);
      row.avatarConsumeJson = '[{"id":1}]';
      await charComputeDao.upsert(row);
      const result = await charComputeDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'compute_dup');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.avatarConsumeJson).assertEqual('[{"id":1}]');
      }
    });

    it('findByAvatarId_notExists_returnsNull', 0, async () => {
      const result = await charComputeDao.findByAvatarId(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'nonexistent_compute');
      expect(result === null).assertTrue();
    });

  });
}
