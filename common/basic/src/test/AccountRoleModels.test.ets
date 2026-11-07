import { describe, it, expect } from '@ohos/hypium';
import { GameId, ZZZCardSign, ZZZVideoStoreState } from 'core';
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

    it('GameNoteSnapshotVM 默认专属字段为 -1', 0, () => {
      const vm = new GameNoteSnapshotVM('树脂', 0, 200, 0, '', '', true);
      expect(vm.expeditionCurrent).assertEqual(-1);
      expect(vm.homeCoinCurrent).assertEqual(-1);
      expect(vm.dailyTaskFinished).assertEqual(-1);
      expect(vm.reserveStamina).assertEqual(-1);
      expect(vm.vitalityCurrent).assertEqual(-1);
      expect(vm.scratchCardSign).assertEqual(ZZZCardSign.UNKNOWN);
      expect(vm.videoStoreState).assertEqual(ZZZVideoStoreState.UNKNOWN);
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

  });
}
