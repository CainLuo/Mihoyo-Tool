import { describe, it, expect, beforeAll, beforeEach } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { RdbManager } from '../../../main/ets/database/RdbManager';
import { AccountDao, GameRoleDao } from '../../../main/ets/database/BBSDao';
import { AccountRow } from '../../../main/ets/models/AccountRow';
import { GameRoleRow } from '../../../main/ets/models/GameRoleRow';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

async function getContext(): Promise<common.UIAbilityContext> {
  const delegator = AbilityDelegatorRegistry.getAbilityDelegator();
  const ability = await delegator.getCurrentTopAbility();
  return ability.context as common.UIAbilityContext;
}

function makeAccount(username: string): AccountRow {
  const row = new AccountRow();
  row.username = username;
  row.cookie = 'cookie_' + username;
  row.stoken = '';
  row.stuid = '';
  row.mid = '';
  row.isActive = 0;
  row.createTime = 0;
  row.updateTime = 0;
  row.uid = 'uid_' + username;
  row.nickname = 'nick_' + username;
  row.avatarUrl = '';
  row.introduce = '';
  return row;
}

function makeGameRole(accountId: string, gameId: string, roleId: string): GameRoleRow {
  const row = new GameRoleRow();
  row.accountId = accountId;
  row.gameId = gameId;
  row.gameBiz = gameId + '_cn';
  row.gameType = 2;
  row.roleId = roleId;
  row.nickname = 'role_' + roleId;
  row.level = 60;
  row.server = 'cn_gf01';
  row.regionName = '天空岛';
  row.isChosen = 1;
  row.isPublic = 1;
  row.bgImageUrl = '';
  row.statsJson = '';
  return row;
}

// 提取到模块级别，避免嵌套函数（arkts-no-nested-funcs）
const _accountDao = new AccountDao();

async function insertTestAccount(username: string): Promise<string> {
  await _accountDao.upsert(makeAccount(username));
  const row = await _accountDao.findByUsername(username);
  return row !== null ? String(row.id) : '0';
}

export default function bbsDaoTest() {
  const accountDao = new AccountDao();
  const gameRoleDao = new GameRoleDao();

  describe('AccountDao', () => {

    beforeAll(async () => {
      await RdbManager.init(await getContext());
    });

    beforeEach(async () => {
      // 清理测试数据
      const store = RdbManager.getRdbStore();
      await store.executeSql("DELETE FROM account_table WHERE username LIKE 'test_%'", []);
    });

    it('upsert_newAccount_findAllReturns1', 0, async () => {
      await accountDao.upsert(makeAccount('test_user1'));
      const all = await accountDao.findAll();
      const found = all.filter(r => r.username === 'test_user1');
      expect(found.length).assertEqual(1);
    });

    it('upsert_duplicateUsername_updatesExisting', 0, async () => {
      const row = makeAccount('test_dup');
      await accountDao.upsert(row);
      row.nickname = 'updated_nick';
      await accountDao.upsert(row);
      const all = await accountDao.findAll();
      const found = all.filter(r => r.username === 'test_dup');
      expect(found.length).assertEqual(1);
      expect(found[0].nickname).assertEqual('updated_nick');
    });

    it('findAll_emptyTable_returnsEmptyArray', 0, async () => {
      const all = await accountDao.findAll();
      const testRows = all.filter(r => r.username.startsWith('test_'));
      expect(testRows.length).assertEqual(0);
    });

    it('findAll_threeRecords_returnsThree', 0, async () => {
      await accountDao.upsert(makeAccount('test_a'));
      await accountDao.upsert(makeAccount('test_b'));
      await accountDao.upsert(makeAccount('test_c'));
      const all = await accountDao.findAll();
      const testRows = all.filter(r => r.username.startsWith('test_'));
      expect(testRows.length).assertEqual(3);
    });

    it('findById_exists_returnsRow', 0, async () => {
      await accountDao.upsert(makeAccount('test_findbyid'));
      const all = await accountDao.findAll();
      const found = all.find(r => r.username === 'test_findbyid');
      expect(found !== undefined).assertTrue();
      if (found !== undefined) {
        const byId = await accountDao.findById(found.id);
        expect(byId !== null).assertTrue();
        if (byId !== null) {
          expect(byId.username).assertEqual('test_findbyid');
        }
      }
    });

    it('findById_notExists_returnsNull', 0, async () => {
      const result = await accountDao.findById(999999);
      expect(result === null).assertTrue();
    });

    it('findByUsername_exists_returnsRow', 0, async () => {
      await accountDao.upsert(makeAccount('test_byname'));
      const result = await accountDao.findByUsername('test_byname');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.username).assertEqual('test_byname');
      }
    });

    it('findByUsername_notExists_returnsNull', 0, async () => {
      const result = await accountDao.findByUsername('test_nonexistent_xyz');
      expect(result === null).assertTrue();
    });

    it('deleteById_exists_rowRemoved', 0, async () => {
      await accountDao.upsert(makeAccount('test_delete'));
      const found = await accountDao.findByUsername('test_delete');
      expect(found !== null).assertTrue();
      if (found !== null) {
        await accountDao.deleteById(found.id);
        const afterDelete = await accountDao.findById(found.id);
        expect(afterDelete === null).assertTrue();
      }
    });

    it('deleteById_notExists_noException', 0, async () => {
      let threw = false;
      try {
        await accountDao.deleteById(999999);
      } catch (_) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

  });

  describe('GameRoleDao', () => {

    beforeAll(async () => {
      await RdbManager.init(await getContext());
    });

    beforeEach(async () => {
      const store = RdbManager.getRdbStore();
      // 先清理测试账号（级联删除 game_role_table）
      await store.executeSql("DELETE FROM account_table WHERE username LIKE 'grtest_%'", []);
    });

    it('upsertAll_twoRows_findByAccountIdReturnsTwo', 0, async () => {
      const accountId = await insertTestAccount('grtest_acc1');
      const rows = [
        makeGameRole(accountId, 'genshin', 'role1'),
        makeGameRole(accountId, 'starrail', 'role2')
      ];
      await gameRoleDao.upsertAll(rows);
      const result = await gameRoleDao.findByAccountId(accountId);
      expect(result.length).assertEqual(2);
    });

    it('upsertAll_duplicateUniqueKey_updatesExisting', 0, async () => {
      const accountId = await insertTestAccount('grtest_acc2');
      const row = makeGameRole(accountId, 'genshin', 'role_dup');
      await gameRoleDao.upsertAll([row]);
      row.level = 90;
      await gameRoleDao.upsertAll([row]);
      const result = await gameRoleDao.findByAccountId(accountId);
      const genshinRoles = result.filter(r => r.gameId === 'genshin');
      expect(genshinRoles.length).assertEqual(1);
      expect(genshinRoles[0].level).assertEqual(90);
    });

    it('upsertAll_emptyArray_noException', 0, async () => {
      let threw = false;
      try {
        await gameRoleDao.upsertAll([]);
      } catch (_) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('findByAccountId_exists_returnsRows', 0, async () => {
      const accountId = await insertTestAccount('grtest_acc3');
      await gameRoleDao.upsertAll([makeGameRole(accountId, 'genshin', 'r1')]);
      const result = await gameRoleDao.findByAccountId(accountId);
      expect(result.length >= 1).assertTrue();
    });

    it('findByAccountId_notExists_returnsEmptyArray', 0, async () => {
      const result = await gameRoleDao.findByAccountId('999998');
      expect(result.length).assertEqual(0);
    });

    it('findByAccountAndGame_exists_returnsRows', 0, async () => {
      const accountId = await insertTestAccount('grtest_acc4');
      await gameRoleDao.upsertAll([
        makeGameRole(accountId, 'genshin', 'r_g'),
        makeGameRole(accountId, 'starrail', 'r_s')
      ]);
      const result = await gameRoleDao.findByAccountAndGame(accountId, 'genshin');
      expect(result.length).assertEqual(1);
      expect(result[0].gameId).assertEqual('genshin');
    });

    it('findByAccountAndGame_notExists_returnsEmptyArray', 0, async () => {
      const result = await gameRoleDao.findByAccountAndGame('999997', 'zzz');
      expect(result.length).assertEqual(0);
    });

    it('deleteByAccountId_exists_rowsRemoved', 0, async () => {
      const accountId = await insertTestAccount('grtest_acc5');
      await gameRoleDao.upsertAll([makeGameRole(accountId, 'genshin', 'r_del')]);
      await gameRoleDao.deleteByAccountId(accountId);
      const result = await gameRoleDao.findByAccountId(accountId);
      expect(result.length).assertEqual(0);
    });

  });
}
