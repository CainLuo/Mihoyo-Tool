import { describe, it, expect } from '@ohos/hypium';
import { GameId } from 'core';
import { NotificationStyle, GameStaminaConstants } from '../main/ets/model/NotificationModels';
import {
  buildGameSettingKey,
  normalizeNotificationStyle,
  resolveThreshold
} from '../main/ets/model/service/NotificationSettingsStore';

export default function notificationSettingsStoreTest() {
  describe('NotificationSettingsStore helpers', () => {

    it('游戏设置 key 格式为 game_{accountId}_{gameId}', 0, () => {
      expect(buildGameSettingKey('acc1', GameId.GENSHIN)).assertEqual('game_acc1_genshin');
      expect(buildGameSettingKey('123', GameId.STARRAIL)).assertEqual('game_123_starrail');
    });

    it('有真实上限时阈值取 80% 向下取整', 0, () => {
      expect(resolveThreshold(GameId.GENSHIN, 200)).assertEqual(160);
      expect(resolveThreshold(GameId.STARRAIL, 300)).assertEqual(240);
      expect(resolveThreshold(GameId.ZZZ, 241)).assertEqual(192);
      expect(resolveThreshold(GameId.GENSHIN, 199)).assertEqual(159);
    });

    it('没有真实上限时使用游戏 fallback 常量', 0, () => {
      expect(resolveThreshold(GameId.GENSHIN, 0)).assertEqual(GameStaminaConstants.GENSHIN_DEFAULT_THRESHOLD);
      expect(resolveThreshold(GameId.STARRAIL, 0)).assertEqual(GameStaminaConstants.STARRAIL_DEFAULT_THRESHOLD);
      expect(resolveThreshold(GameId.ZZZ, 0)).assertEqual(GameStaminaConstants.ZZZ_DEFAULT_THRESHOLD);
    });

    it('未知游戏且无上限时阈值为 0', 0, () => {
      expect(resolveThreshold(GameId.HONKAI3, 0)).assertEqual(0);
    });

    it('通知样式只接受已知值', 0, () => {
      expect(normalizeNotificationStyle(NotificationStyle.STYLE_B)).assertEqual(NotificationStyle.STYLE_B);
      expect(normalizeNotificationStyle(NotificationStyle.STYLE_A)).assertEqual(NotificationStyle.STYLE_A);
      expect(normalizeNotificationStyle('unknown')).assertEqual(NotificationStyle.STYLE_A);
      expect(normalizeNotificationStyle('')).assertEqual(NotificationStyle.STYLE_A);
    });

  });
}
