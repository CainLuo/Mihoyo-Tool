import { describe, it, expect } from '@ohos/hypium';
import { GameId } from 'core';
import { GameDataRowVM, GameNoteSnapshotVM, GameRoleCardVM, MihoyoAccountVM } from '../main/ets/model/AccountRoleModels';

export default function accountRoleModelsTest() {
  describe('AccountRoleModels', () => {

    it('GameDataRowVM 构造函数赋值', 0, () => {
      const row = new GameDataRowVM($r('app.string.dialog_confirm'), '12', $r('app.color.color_primary'));
      expect(row.value).assertEqual('12');
      expect(row.label !== null).assertTrue();
    });

    it('GameNoteSnapshotVM 构造函数赋值', 0, () => {
      const vm = new GameNoteSnapshotVM('树脂', 140, 200, 3600, '派遣', '5/5', false);
      expect(vm.primaryLabel).assertEqual('树脂');
      expect(vm.primaryCurrent).assertEqual(140);
      expect(vm.primaryMax).assertEqual(200);
      expect(vm.primaryRecoverySeconds).assertEqual(3600);
      expect(vm.secondaryLabel).assertEqual('派遣');
      expect(vm.isFull).assertFalse();
    });

    it('GameRoleCardVM 构造函数赋值', 0, () => {
      const snapshot = new GameNoteSnapshotVM('开拓力', 180, 240, 0, '', '', false);
      const role = new GameRoleCardVM(
        GameId.STARRAIL,
        '星穹铁道',
        $r('app.color.color_primary'),
        '100000001',
        '开拓者',
        '星穹列车',
        snapshot,
        '5 分钟前'
      );
      expect(role.gameId).assertEqual(GameId.STARRAIL);
      expect(role.gameName).assertEqual('星穹铁道');
      expect(role.roleUid).assertEqual('100000001');
      expect(role.nickname).assertEqual('开拓者');
      expect(role.snapshot !== null).assertTrue();
      expect(role.lastSyncDesc).assertEqual('5 分钟前');
    });

    it('GameRoleCardVM snapshot 可为 null', 0, () => {
      const role = new GameRoleCardVM(
        GameId.GENSHIN,
        '原神',
        $r('app.color.color_primary'),
        '123456789',
        '旅行者',
        '天空岛',
        null,
        ''
      );
      expect(role.snapshot).assertNull();
    });

    it('MihoyoAccountVM 构造函数赋值', 0, () => {
      const role = new GameRoleCardVM(
        GameId.ZZZ,
        '绝区零',
        $r('app.color.color_primary'),
        '150000001',
        '绳匠',
        '新艾利都',
        null,
        ''
      );
      const account = new MihoyoAccountVM('acc1', 'user1', [role], '昵称', 'https://example.com/a.png');
      expect(account.accountId).assertEqual('acc1');
      expect(account.username).assertEqual('user1');
      expect(account.nickname).assertEqual('昵称');
      expect(account.avatarUrl).assertEqual('https://example.com/a.png');
      expect(account.roles.length).assertEqual(1);
    });

    it('MihoyoAccountVM 可选参数默认值', 0, () => {
      const account = new MihoyoAccountVM('acc1', 'user1', []);
      expect(account.nickname).assertEqual('');
      expect(account.avatarUrl).assertEqual('');
      expect(account.roles.length).assertEqual(0);
    });

    // ─── renderKey（ForEach key 覆盖全部展示字段） ───────────────────

    it('renderKey: 内容相同则 key 相同', 0, () => {
      const a = new GameNoteSnapshotVM('树脂', 140, 200, 3600, '派遣', '5/5', false);
      const b = new GameNoteSnapshotVM('树脂', 140, 200, 3600, '派遣', '5/5', false);
      expect(a.renderKey()).assertEqual(b.renderKey());
    });

    it('renderKey: 次要指标变化会改变 key', 0, () => {
      const a = new GameNoteSnapshotVM('树脂', 140, 200, 3600, '派遣', '3/5', false);
      const b = new GameNoteSnapshotVM('树脂', 140, 200, 3600, '派遣', '5/5', false);
      expect(a.renderKey() === b.renderKey()).assertFalse();
    });

    it('renderKey: 数据行值变化会改变 key', 0, () => {
      const a = new GameNoteSnapshotVM('树脂', 140, 200, 3600, '', '', false);
      a.dataRows = [new GameDataRowVM($r('app.string.dialog_confirm'), '3/5', $r('app.color.color_primary'))];
      const b = new GameNoteSnapshotVM('树脂', 140, 200, 3600, '', '', false);
      b.dataRows = [new GameDataRowVM($r('app.string.dialog_confirm'), '5/5', $r('app.color.color_primary'))];
      expect(a.renderKey() === b.renderKey()).assertFalse();
    });

    it('renderKey: 数据行数量变化会改变 key', 0, () => {
      const a = new GameNoteSnapshotVM('树脂', 140, 200, 3600, '', '', false);
      const b = new GameNoteSnapshotVM('树脂', 140, 200, 3600, '', '', false);
      b.dataRows = [new GameDataRowVM($r('app.string.dialog_confirm'), '5/5', $r('app.color.color_primary'))];
      expect(a.renderKey() === b.renderKey()).assertFalse();
    });

    it('renderKey: 角色快照从 null 变为有数据会改变 key', 0, () => {
      const withoutSnap = new GameRoleCardVM(
        GameId.GENSHIN, '原神', $r('app.color.color_primary'), '1', '旅行者', '天空岛', null, ''
      );
      const withSnap = new GameRoleCardVM(
        GameId.GENSHIN, '原神', $r('app.color.color_primary'), '1', '旅行者', '天空岛',
        new GameNoteSnapshotVM('树脂', 0, 200, 0, '', '', false), ''
      );
      expect(withoutSnap.renderKey() === withSnap.renderKey()).assertFalse();
    });

    it('renderKey: 账号昵称与头像变化会改变 key', 0, () => {
      const a = new MihoyoAccountVM('acc1', 'user1', [], '昵称', 'https://example.com/a.png');
      const b = new MihoyoAccountVM('acc1', 'user1', [], '新昵称', 'https://example.com/a.png');
      const c = new MihoyoAccountVM('acc1', 'user1', [], '昵称', 'https://example.com/b.png');
      expect(a.renderKey() === b.renderKey()).assertFalse();
      expect(a.renderKey() === c.renderKey()).assertFalse();
    });

    it('headerKey: 不受角色内容影响', 0, () => {
      const a = new MihoyoAccountVM('acc1', 'user1', [
        new GameRoleCardVM(GameId.GENSHIN, '原神', $r('app.color.color_primary'), '1', '甲', '天空岛', null, '')
      ], '昵称', '');
      const b = new MihoyoAccountVM('acc1', 'user1', [
        new GameRoleCardVM(GameId.GENSHIN, '原神', $r('app.color.color_primary'), '1', '乙', '天空岛', null, '')
      ], '昵称', '');
      expect(a.headerKey()).assertEqual(b.headerKey());
      expect(a.renderKey() === b.renderKey()).assertFalse();
    });

    it('headerKey: 角色数量变化会改变 key', 0, () => {
      const a = new MihoyoAccountVM('acc1', 'user1', [], '昵称', '');
      const b = new MihoyoAccountVM('acc1', 'user1', [
        new GameRoleCardVM(GameId.GENSHIN, '原神', $r('app.color.color_primary'), '1', '甲', '天空岛', null, '')
      ], '昵称', '');
      expect(a.headerKey() === b.headerKey()).assertFalse();
    });

  });
}
