import { describe, it, expect, beforeAll } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { RdbManager } from '../../../main/ets/database/RdbManager';
import { TableName } from '../../../main/ets/database/TableSchema';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

async function getContext(): Promise<common.UIAbilityContext> {
  const delegator = AbilityDelegatorRegistry.getAbilityDelegator();
  // getAppContext() 返回 ApplicationContext，不能用于 getRdbStore
  // 需要通过 getCurrentTopAbility 获取 UIAbilityContext
  const ability = await delegator.getCurrentTopAbility();
  return ability.context as common.UIAbilityContext;
}

/** 插入一条测试账号，返回 username */
async function insertTestAccount(username: string): Promise<void> {
  await RdbManager.upsertRow(
    TableName.ACCOUNT,
    ['username', 'cookie', 'stoken', 'stuid', 'mid', 'is_active', 'create_time', 'update_time', 'uid', 'nickname', 'avatar_url', 'introduce'],
    [username, 'cookie_val', '', '', '', 0, 1000, 1000, 'uid_' + username, 'nick_' + username, '', '']
  );
}

/** 清理测试账号 */
async function deleteTestAccount(username: string): Promise<void> {
  const store = RdbManager.getRdbStore();
  await store.executeSql(`DELETE FROM account_table WHERE username=?`, [username]);
}

export default function rdbManagerTest() {
  describe('RdbManager', () => {

    beforeAll(async () => {
      try {
        await RdbManager.init(await getContext());
        console.info('[RdbManager.test] beforeAll init SUCCESS');
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`;
        console.error(`[RdbManager.test] beforeAll init FAILED: ${msg}`);
      }
    });

    // ── 初始化 ────────────────────────────────────────────────────

    it('init_success_getRdbStoreReturnsNonNull', 0, () => {
      const store = RdbManager.getRdbStore();
      expect(store !== null).assertTrue();
    });

    it('init_idempotent_noException', 0, async () => {
      let threw = false;
      try {
        await RdbManager.init(await getContext());
      } catch (_) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('foreignKeys_enabled_insertViolation_throws', 0, async () => {
      // 验证外键约束实际生效：向 game_role_table 插入不存在的 account_id，应抛出错误
      // HarmonyOS RDB 使用连接池，PRAGMA foreign_keys 无法通过 querySql 跨连接验证，
      // 改为行为验证：外键约束生效时插入违规数据会抛出异常
      let threw = false;
      try {
        await RdbManager.executeSql(
          "INSERT INTO game_role_table (account_id, game_id, game_biz, game_type, role_id, nickname, level, server, region_name, is_chosen, is_public, bg_image_url, stats_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
          ['999999999', 'genshin', 'hk4e_cn', 2, 'fk_test_role', 'test', 1, 'cn_gf01', '天空岛', 0, 0, '', '']
        );
      } catch (_) {
        threw = true;
      }
      // 外键约束生效时应抛出异常（account_id=999999999 不存在于 account_table）
      expect(threw).assertTrue();
    });

    it('userVersion_firstInstall_returnsOne', 0, async () => {
      const store = RdbManager.getRdbStore();
      const rs: relationalStore.ResultSet = await store.querySql('PRAGMA user_version', []);
      let version: number = 0;
      try {
        if (rs.goToFirstRow()) {
          const v = rs.getValue(0);
          version = typeof v === 'number' ? v : 0;
        }
      } finally {
        rs.close();
      }
      expect(version).assertEqual(1);
    });

    it('allTables_exist_fifteenTables', 0, async () => {
      const store = RdbManager.getRdbStore();
      const rs: relationalStore.ResultSet = await store.querySql(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
        []
      );
      const tableNames: string[] = [];
      try {
        while (rs.goToNextRow()) {
          const v = rs.getValue(0);
          if (typeof v === 'string') {
            tableNames.push(v);
          }
        }
      } finally {
        rs.close();
      }
      const expectedTables = [
        'account_table', 'game_role_table',
        'genshin_character_list', 'genshin_daily_note',
        'genshin_character_detail', 'genshin_character_compute',
        'starrail_avatar_basic', 'starrail_daily_note',
        'starrail_avatar_info', 'starrail_avatar_compute',
        'zzz_avatar_basic', 'zzz_daily_note',
        'zzz_avatar_info', 'zzz_avatar_compute',
        'sync_meta'
      ];
      for (let i = 0; i < expectedTables.length; i++) {
        expect(tableNames.indexOf(expectedTables[i]) >= 0).assertTrue();
      }
      expect(tableNames.length >= 15).assertTrue();
    });

    // ── upsertRow（INSERT OR REPLACE）────────────────────────────

    it('upsertRow_newRow_canBeQueried', 0, async () => {
      const username = 'rdb_upsert_new';
      await deleteTestAccount(username);

      await insertTestAccount(username);

      const pred = new relationalStore.RdbPredicates('account_table');
      pred.equalTo('username', username);
      const row = await RdbManager.queryFirst(pred, ['username', 'nickname'], (rs) => {
        return rs.getString(rs.getColumnIndex('nickname'));
      });
      expect(row).assertEqual('nick_' + username);

      await deleteTestAccount(username);
    });

    it('upsertRow_existingRow_updatesFields', 0, async () => {
      const username = 'rdb_upsert_update';
      await deleteTestAccount(username);
      await insertTestAccount(username);

      // 再次 upsert，nickname 改变
      await RdbManager.upsertRow(
        TableName.ACCOUNT,
        ['username', 'cookie', 'stoken', 'stuid', 'mid', 'is_active', 'create_time', 'update_time', 'uid', 'nickname', 'avatar_url', 'introduce'],
        [username, 'cookie_val', '', '', '', 0, 1000, 2000, 'uid_' + username, 'updated_nick', '', '']
      );

      const pred = new relationalStore.RdbPredicates('account_table');
      pred.equalTo('username', username);
      const nick = await RdbManager.queryFirst(pred, ['nickname'], (rs) => rs.getString(rs.getColumnIndex('nickname')));
      expect(nick).assertEqual('updated_nick');

      await deleteTestAccount(username);
    });

    // ── deleteRows ────────────────────────────────────────────────

    it('deleteRows_existingRow_rowGone', 0, async () => {
      const username = 'rdb_delete_test';
      await deleteTestAccount(username);
      await insertTestAccount(username);

      const pred = new relationalStore.RdbPredicates('account_table');
      pred.equalTo('username', username);
      await RdbManager.deleteRows(pred);

      const row = await RdbManager.queryFirst(pred, ['username'], (rs) => rs.getString(0));
      expect(row).assertNull();
    });

    it('deleteRows_nonExistingRow_noException', 0, async () => {
      let threw = false;
      try {
        const pred = new relationalStore.RdbPredicates('account_table');
        pred.equalTo('username', 'rdb_delete_nonexist_xyz');
        await RdbManager.deleteRows(pred);
      } catch (_) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    // ── updateRows ────────────────────────────────────────────────

    it('updateRows_existingRow_fieldUpdated', 0, async () => {
      const username = 'rdb_update_test';
      await deleteTestAccount(username);
      await insertTestAccount(username);

      await RdbManager.updateRows(
        TableName.ACCOUNT,
        ['nickname', 'update_time'],
        ['new_nickname', 9999],
        ['username'],
        [username]
      );

      const pred = new relationalStore.RdbPredicates('account_table');
      pred.equalTo('username', username);
      const nick = await RdbManager.queryFirst(pred, ['nickname'], (rs) => rs.getString(rs.getColumnIndex('nickname')));
      expect(nick).assertEqual('new_nickname');

      await deleteTestAccount(username);
    });

    it('updateRows_nonExistingRow_noException', 0, async () => {
      let threw = false;
      try {
        await RdbManager.updateRows(
          TableName.ACCOUNT,
          ['nickname'],
          ['x'],
          ['username'],
          ['rdb_update_nonexist_xyz']
        );
      } catch (_) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    // ── queryFirst ────────────────────────────────────────────────

    it('queryFirst_existingRow_returnsData', 0, async () => {
      const username = 'rdb_qfirst_test';
      await deleteTestAccount(username);
      await insertTestAccount(username);

      const pred = new relationalStore.RdbPredicates('account_table');
      pred.equalTo('username', username);
      const uid = await RdbManager.queryFirst(pred, ['uid'], (rs) => rs.getString(rs.getColumnIndex('uid')));
      expect(uid).assertEqual('uid_' + username);

      await deleteTestAccount(username);
    });

    it('queryFirst_nonExistingRow_returnsNull', 0, async () => {
      const pred = new relationalStore.RdbPredicates('account_table');
      pred.equalTo('username', 'rdb_qfirst_nonexist_xyz');
      const result = await RdbManager.queryFirst(pred, ['username'], (rs) => rs.getString(0));
      expect(result).assertNull();
    });

    // ── queryAll ──────────────────────────────────────────────────

    it('queryAll_multipleRows_returnsAll', 0, async () => {
      const u1 = 'rdb_qall_1';
      const u2 = 'rdb_qall_2';
      await deleteTestAccount(u1);
      await deleteTestAccount(u2);
      await insertTestAccount(u1);
      await insertTestAccount(u2);

      const pred = new relationalStore.RdbPredicates('account_table');
      pred.in('username', [u1, u2]);
      const rows = await RdbManager.queryAll(pred, ['username'], (rs) => rs.getString(rs.getColumnIndex('username')));
      expect(rows.length).assertEqual(2);

      await deleteTestAccount(u1);
      await deleteTestAccount(u2);
    });

    it('queryAll_emptyTable_returnsEmptyArray', 0, async () => {
      const pred = new relationalStore.RdbPredicates('account_table');
      pred.equalTo('username', 'rdb_qall_nonexist_xyz');
      const rows = await RdbManager.queryAll(pred, ['username'], (rs) => rs.getString(0));
      expect(rows.length).assertEqual(0);
    });

    // ── 事务 ──────────────────────────────────────────────────────

    it('runInTransaction_success_dataWritten', 0, async () => {
      const username = 'rdb_tx_success';
      await deleteTestAccount(username);

      await RdbManager.runInTransaction(async () => {
        await insertTestAccount(username);
      });

      const pred = new relationalStore.RdbPredicates('account_table');
      pred.equalTo('username', username);
      const row = await RdbManager.queryFirst(pred, ['username'], (rs) => rs.getString(0));
      expect(row).assertEqual(username);

      await deleteTestAccount(username);
    });

    it('runInTransaction_throws_rollsBack', 0, async () => {
      const username = 'rdb_tx_rollback';
      await deleteTestAccount(username);

      let threw = false;
      try {
        await RdbManager.runInTransaction(async () => {
          await insertTestAccount(username);
          throw new Error('intentional rollback');
        });
      } catch (_) {
        threw = true;
      }
      expect(threw).assertTrue();

      const pred = new relationalStore.RdbPredicates('account_table');
      pred.equalTo('username', username);
      const row = await RdbManager.queryFirst(pred, ['username'], (rs) => rs.getString(0));
      expect(row).assertNull();
    });

    // ── executeSql 直接 SQL ───────────────────────────────────────

    it('executeSql_insertAndQuery_works', 0, async () => {
      const username = 'rdb_execsql_test';
      await deleteTestAccount(username);

      await RdbManager.executeSql(
        "INSERT OR REPLACE INTO account_table (username, cookie, stoken, stuid, mid, is_active, create_time, update_time, uid, nickname, avatar_url, introduce) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        [username, '', '', '', '', 0, 0, 0, '', 'exec_nick', '', '']
      );

      const pred = new relationalStore.RdbPredicates('account_table');
      pred.equalTo('username', username);
      const nick = await RdbManager.queryFirst(pred, ['nickname'], (rs) => rs.getString(rs.getColumnIndex('nickname')));
      expect(nick).assertEqual('exec_nick');

      await deleteTestAccount(username);
    });

  });
}

