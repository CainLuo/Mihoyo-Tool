import { describe, it, expect, beforeAll, beforeEach } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { RdbManager } from '../../../main/ets/database/RdbManager';
import { BBSRepository } from '../../../main/ets/repository/BBSRepository';
import { AccountRow } from '../../../main/ets/models/AccountRow';
import { GameRoleRow } from '../../../main/ets/models/GameRoleRow';
import { GameRoleDao } from '../../../main/ets/database/BBSDao';
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

export default function bbsRepositoryTest() {
  const repo = new BBSRepository();
  const gameRoleDao = new GameRoleDao();

  beforeAll(async () => {
    await RdbManager.init(await getContext());
  });

  beforeEach(async () => {
    const store = RdbManager.getRdbStore();
    await store.executeSql("DELETE FROM account_table WHERE username LIKE 'repo_test_%'", []);
  });

  describe('BBSRepository', () => {

    it('saveAccount_newAccount_getAllAccountsReturnsOne', 0, async () => {
      await repo.saveAccount(makeAccount('repo_test_u1'));
      const all = await repo.getAllAccounts();
      const found = all.filter(r => r.username === 'repo_test_u1');
      expect(found.length).assertEqual(1);
    });

    it('saveAccount_duplicateUsername_updatesExisting', 0, async () => {
      const row = makeAccount('repo_test_dup');
      await repo.saveAccount(row);
      row.nickname = 'updated_nick';
      await repo.saveAccount(row);
      const all = await repo.getAllAccounts();
      const found = all.filter(r => r.username === 'repo_test_dup');
      expect(found.length).assertEqual(1);
      expect(found[0].nickname).assertEqual('updated_nick');
    });

    it('getAllAccounts_emptyTable_returnsEmptyArray', 0, async () => {
      const all = await repo.getAllAccounts();
      const testRows = all.filter(r => r.username.startsWith('repo_test_'));
      expect(testRows.length).assertEqual(0);
    });

    it('getAccountById_exists_returnsRow', 0, async () => {
      await repo.saveAccount(makeAccount('repo_test_byid'));
      const all = await repo.getAllAccounts();
      const found = all.find(r => r.username === 'repo_test_byid');
      expect(found !== undefined).assertTrue();
      if (found !== undefined) {
        const result = await repo.getAccountById(found.id);
        expect(result !== null).assertTrue();
        if (result !== null) {
          expect(result.username).assertEqual('repo_test_byid');
        }
      }
    });

    it('getAccountById_notExists_returnsNull', 0, async () => {
      const result = await repo.getAccountById(999999);
      expect(result === null).assertTrue();
    });

    it('getAccountByUsername_exists_returnsRow', 0, async () => {
      await repo.saveAccount(makeAccount('repo_test_byname'));
      const result = await repo.getAccountByUsername('repo_test_byname');
      expect(result !== null).assertTrue();
      if (result !== null) {
        expect(result.username).assertEqual('repo_test_byname');
      }
    });

    it('deleteAccount_exists_cascadeDeletesGameRoles', 0, async () => {
      await repo.saveAccount(makeAccount('repo_test_cascade'));
      const acc = await repo.getAccountByUsername('repo_test_cascade');
      expect(acc !== null).assertTrue();
      if (acc !== null) {
        const accIdStr = String(acc.id);
        await gameRoleDao.upsertAll([makeGameRole(accIdStr, 'genshin', 'r_cascade')]);
        const rolesBefore = await repo.getGameRoles(accIdStr);
        expect(rolesBefore.length).assertEqual(1);

        await repo.deleteAccount(acc.uid);

        // 级联删除：game_role_table 中的数据应同步删除
        const rolesAfter = await repo.getGameRoles(accIdStr);
        expect(rolesAfter.length).assertEqual(0);
      }
    });

    it('upsertGameRoles_twoRows_getGameRolesReturnsTwo', 0, async () => {
      await repo.saveAccount(makeAccount('repo_test_roles'));
      const acc = await repo.getAccountByUsername('repo_test_roles');
      expect(acc !== null).assertTrue();
      if (acc !== null) {
        const accIdStr = String(acc.id);
        await gameRoleDao.upsertAll([
          makeGameRole(accIdStr, 'genshin', 'r1'),
          makeGameRole(accIdStr, 'starrail', 'r2')
        ]);
        const result = await repo.getGameRoles(accIdStr);
        expect(result.length).assertEqual(2);
      }
    });

    it('getGameRoles_filterByAccountId_returnsOnlyMatching', 0, async () => {
      await repo.saveAccount(makeAccount('repo_test_filter1'));
      await repo.saveAccount(makeAccount('repo_test_filter2'));
      const acc1 = await repo.getAccountByUsername('repo_test_filter1');
      const acc2 = await repo.getAccountByUsername('repo_test_filter2');
      expect(acc1 !== null && acc2 !== null).assertTrue();
      if (acc1 !== null && acc2 !== null) {
        const acc1IdStr = String(acc1.id);
        const acc2IdStr = String(acc2.id);
        await gameRoleDao.upsertAll([makeGameRole(acc1IdStr, 'genshin', 'r_f1')]);
        await gameRoleDao.upsertAll([makeGameRole(acc2IdStr, 'genshin', 'r_f2')]);
        const result = await repo.getGameRoles(acc1IdStr);
        expect(result.length).assertEqual(1);
        expect(result[0].accountId).assertEqual(acc1IdStr);
      }
    });

    it('getGameRolesByGame_filterByGame_returnsOnlyMatching', 0, async () => {
      await repo.saveAccount(makeAccount('repo_test_bygame'));
      const acc = await repo.getAccountByUsername('repo_test_bygame');
      expect(acc !== null).assertTrue();
      if (acc !== null) {
        const accIdStr = String(acc.id);
        await gameRoleDao.upsertAll([
          makeGameRole(accIdStr, 'genshin', 'r_g'),
          makeGameRole(accIdStr, 'starrail', 'r_s')
        ]);
        const result = await repo.getGameRolesByGame(accIdStr, 'genshin');
        expect(result.length).assertEqual(1);
        expect(result[0].gameId).assertEqual('genshin');
      }
    });

    it('deleteGameRoles_clearsAll_getGameRolesReturnsEmpty', 0, async () => {
      await repo.saveAccount(makeAccount('repo_test_delroles'));
      const acc = await repo.getAccountByUsername('repo_test_delroles');
      expect(acc !== null).assertTrue();
      if (acc !== null) {
        const accIdStr = String(acc.id);
        await gameRoleDao.upsertAll([makeGameRole(accIdStr, 'genshin', 'r_del')]);
        await repo.deleteGameRoles(accIdStr);
        const result = await repo.getGameRoles(accIdStr);
        expect(result.length).assertEqual(0);
      }
    });

  });
}
