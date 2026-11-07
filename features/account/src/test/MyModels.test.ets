import { describe, it, expect } from '@ohos/hypium';
import { GameId } from 'core';
import { GameStatItem, MyAccountVM, MyGameRoleVM } from '../main/ets/model/MyModels';

export default function myModelsTest() {
  describe('MyModels', () => {

    it('GameStatItem 构造函数赋值', 0, () => {
      const item = new GameStatItem('活跃天数', '100');
      expect(item.name).assertEqual('活跃天数');
      expect(item.value).assertEqual('100');
    });

    it('MyGameRoleVM 完整赋值', 0, () => {
      const vm = new MyGameRoleVM(
        GameId.STARRAIL,
        $r('app.string.game_name_starrail'),
        $r('app.color.game_color_starrail'),
        '100000001',
        '开拓者',
        '星穹列车',
        70,
        'https://example.com/bg.png',
        [new GameStatItem('等级', '70')],
        $r('app.media.logo_starrail')
      );
      expect(vm.gameId).assertEqual(GameId.STARRAIL);
      expect(vm.roleUid).assertEqual('100000001');
      expect(vm.nickname).assertEqual('开拓者');
      expect(vm.level).assertEqual(70);
      expect(vm.stats.length).assertEqual(1);
    });

    it('MyGameRoleVM 可选参数默认值', 0, () => {
      const vm = new MyGameRoleVM(
        GameId.GENSHIN,
        $r('app.string.game_name_genshin'),
        $r('app.color.game_color_genshin'),
        '123456789',
        '旅行者',
        '天空岛'
      );
      expect(vm.level).assertEqual(0);
      expect(vm.bgImageUrl).assertEqual('');
      expect(vm.stats.length).assertEqual(0);
    });

    it('MyAccountVM 完整赋值', 0, () => {
      const role = new MyGameRoleVM(
        GameId.ZZZ,
        $r('app.string.game_name_zzz'),
        $r('app.color.game_color_zzz'),
        '150000001',
        '绳匠',
        '新艾利都'
      );
      const account = new MyAccountVM('acc1', 'user', [role], '昵称', 'https://example.com/a.png', '12345');
      expect(account.accountId).assertEqual('acc1');
      expect(account.username).assertEqual('user');
      expect(account.nickname).assertEqual('昵称');
      expect(account.avatarUrl).assertEqual('https://example.com/a.png');
      expect(account.uid).assertEqual('12345');
      expect(account.roles.length).assertEqual(1);
    });

    it('MyAccountVM 可选参数默认值', 0, () => {
      const account = new MyAccountVM('acc1', 'user', []);
      expect(account.nickname).assertEqual('');
      expect(account.avatarUrl).assertEqual('');
      expect(account.uid).assertEqual('');
      expect(account.roles.length).assertEqual(0);
    });

  });
}
