import { describe, it, expect } from '@ohos/hypium';
import { NotificationSettingsViewModel } from '../main/ets/viewmodel/NotificationSettingsViewModel';
import {
  AccountNotificationConfig,
  GameNotificationConfig,
  NotificationStyle,
} from '../main/ets/model/NotificationModels';
import { GameId } from 'core';

function makeAccount(accountId: string): AccountNotificationConfig {
  const account = new AccountNotificationConfig();
  account.accountId = accountId;
  account.uid = accountId;
  account.nickname = accountId;
  account.isExpanded = true;
  return account;
}

function makeGame(gameId: GameId): GameNotificationConfig {
  const game = new GameNotificationConfig();
  game.gameId = gameId;
  game.isEnabled = true;
  game.threshold = 100;
  game.maxStamina = 200;
  return game;
}

export default function notificationSettingsViewModelTest() {
  describe('NotificationSettingsViewModel', () => {

    it('初始状态', 0, () => {
      const vm = new NotificationSettingsViewModel();
      expect(vm.isEnabled).assertFalse();
      expect(vm.style).assertEqual(NotificationStyle.STYLE_A);
      expect(vm.isPermissionDenied).assertFalse();
      expect(vm.accounts.length).assertEqual(0);
      expect(vm.reminderUsed).assertEqual(0);
      expect(vm.reminderLimit).assertEqual(30);
      expect(vm.shouldShowLimitDialog).assertFalse();
    });

    it('getSlotColor 按使用比例返回非空资源', 0, () => {
      const vm = new NotificationSettingsViewModel();
      vm.reminderUsed = 0;
      expect(vm.getSlotColor() !== null).assertTrue();
      vm.reminderUsed = 24;
      expect(vm.getSlotColor() !== null).assertTrue();
      vm.reminderUsed = 30;
      expect(vm.getSlotColor() !== null).assertTrue();
    });

    it('onToggleAccountExpanded 切换指定账号的展开状态', 0, () => {
      const vm = new NotificationSettingsViewModel();
      const account = makeAccount('a1');
      vm.accounts = [account];

      vm.onToggleAccountExpanded('a1');
      expect(account.isExpanded).assertFalse();
      vm.onToggleAccountExpanded('a1');
      expect(account.isExpanded).assertTrue();
    });

    it('onToggleAccountExpanded 未知账号不改变其他账号', 0, () => {
      const vm = new NotificationSettingsViewModel();
      const first = makeAccount('a1');
      const second = makeAccount('a2');
      vm.accounts = [first, second];

      vm.onToggleAccountExpanded('unknown');
      expect(first.isExpanded).assertTrue();
      expect(second.isExpanded).assertTrue();
    });

    it('账号内多个游戏配置互不影响', 0, () => {
      const vm = new NotificationSettingsViewModel();
      const account = makeAccount('a1');
      account.games = [makeGame(GameId.GENSHIN), makeGame(GameId.STARRAIL)];
      vm.accounts = [account];

      vm.onToggleAccountExpanded('a1');
      expect(account.games.length).assertEqual(2);
      expect(account.games[0].gameId).assertEqual(GameId.GENSHIN);
      expect(account.games[1].gameId).assertEqual(GameId.STARRAIL);
    });

  });
}
