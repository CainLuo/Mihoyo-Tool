import { describe, it, expect, beforeAll } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { RdbManager } from '../../../main/ets/database/RdbManager';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

function getContext(): common.UIAbilityContext {
  return AbilityDelegatorRegistry.getAbilityDelegator().getAppContext() as common.UIAbilityContext;
}

export default function rdbManagerTest() {
  describe('RdbManager', () => {

    beforeAll(async () => {
      await RdbManager.init(getContext());
    });

    it('init_success_getRdbStoreReturnsNonNull', 0, () => {
      const store = RdbManager.getRdbStore();
      expect(store !== null).assertTrue();
    });

    it('init_idempotent_noException', 0, async () => {
      // 重复调用 init 不应抛异常
      let threw = false;
      try {
        await RdbManager.init(getContext());
      } catch (_) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('foreignKeys_enabled_returnsOne', 0, async () => {
      const store = RdbManager.getRdbStore();
      const rs: relationalStore.ResultSet = await store.querySql('PRAGMA foreign_keys', []);
      let val: number = 0;
      try {
        if (rs.goToFirstRow()) {
          const v = rs.getValue(0);
          val = typeof v === 'number' ? v : 0;
        }
      } finally {
        rs.close();
      }
      expect(val).assertEqual(1);
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

    it('runInTransaction_success_dataWritten', 0, async () => {
      const store = RdbManager.getRdbStore();
      // 先清理测试数据
      await store.executeSql("DELETE FROM account_table WHERE username='tx_test_user'", []);

      await RdbManager.runInTransaction(async () => {
        await RdbManager.executeSql(
          "INSERT OR REPLACE INTO account_table (username, cookie, stoken, stuid, mid, is_active, create_time, update_time, uid, nickname, avatar_url, introduce) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
          ['tx_test_user', '', '', '', '', 0, 0, 0, '', '', '', '']
        );
      });

      const rs = await store.querySql("SELECT username FROM account_table WHERE username='tx_test_user'", []);
      let found = false;
      try {
        found = rs.goToFirstRow();
      } finally {
        rs.close();
      }
      expect(found).assertTrue();

      // 清理
      await store.executeSql("DELETE FROM account_table WHERE username='tx_test_user'", []);
    });

    it('runInTransaction_throws_rollsBack', 0, async () => {
      const store = RdbManager.getRdbStore();
      await store.executeSql("DELETE FROM account_table WHERE username='rollback_test_user'", []);

      let threw = false;
      try {
        await RdbManager.runInTransaction(async () => {
          await RdbManager.executeSql(
            "INSERT OR REPLACE INTO account_table (username, cookie, stoken, stuid, mid, is_active, create_time, update_time, uid, nickname, avatar_url, introduce) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ['rollback_test_user', '', '', '', '', 0, 0, 0, '', '', '', '']
          );
          throw new Error('intentional error');
        });
      } catch (_) {
        threw = true;
      }
      expect(threw).assertTrue();

      const rs = await store.querySql("SELECT username FROM account_table WHERE username='rollback_test_user'", []);
      let found = false;
      try {
        found = rs.goToFirstRow();
      } finally {
        rs.close();
      }
      expect(found).assertFalse();
    });

  });
}
