import { describe, it, expect } from '@ohos/hypium';
import {
  getStaminaColorType,
  getWidgetBgColors,
  getWidgetGameColor,
  isSingleGame,
  toGameId,
} from '../main/ets/utils/WidgetPreviewUtil';
import { StaminaColorType } from 'widgetbase';
import { GameId } from 'core';

export default function widgetPreviewUtilTest() {
  describe('WidgetPreviewUtil', () => {

    it('toGameId 识别三个游戏与未知值', 0, () => {
      expect(toGameId(GameId.GENSHIN)).assertEqual(GameId.GENSHIN);
      expect(toGameId('genshin')).assertEqual(GameId.GENSHIN);
      expect(toGameId(GameId.STARRAIL)).assertEqual(GameId.STARRAIL);
      expect(toGameId('starrail')).assertEqual(GameId.STARRAIL);
      expect(toGameId(GameId.ZZZ)).assertEqual(GameId.ZZZ);
      expect(toGameId('zzz')).assertEqual(GameId.ZZZ);
      expect(toGameId('unknown')).assertEqual(GameId.GENSHIN);
    });

    it('isSingleGame 空数组 / 单元素 / 同游戏为 true', 0, () => {
      expect(isSingleGame([])).assertTrue();
      expect(isSingleGame(['genshin'])).assertTrue();
      expect(isSingleGame(['genshin', 'genshin'])).assertTrue();
    });

    it('isSingleGame 混合游戏为 false', 0, () => {
      expect(isSingleGame(['genshin', 'starrail'])).assertFalse();
      expect(isSingleGame(['genshin', 'genshin', 'zzz'])).assertFalse();
    });

    it('getStaminaColorType 按 30% / 70% 分档', 0, () => {
      expect(getStaminaColorType(0)).assertEqual(StaminaColorType.LOW);
      expect(getStaminaColorType(0.3)).assertEqual(StaminaColorType.LOW);
      expect(getStaminaColorType(0.31)).assertEqual(StaminaColorType.MEDIUM);
      expect(getStaminaColorType(0.7)).assertEqual(StaminaColorType.MEDIUM);
      expect(getStaminaColorType(0.71)).assertEqual(StaminaColorType.HIGH);
      expect(getStaminaColorType(1)).assertEqual(StaminaColorType.HIGH);
    });

    it('getWidgetGameColor 三个游戏与未知值都返回非空资源', 0, () => {
      expect(getWidgetGameColor(GameId.GENSHIN) !== null).assertTrue();
      expect(getWidgetGameColor(GameId.STARRAIL) !== null).assertTrue();
      expect(getWidgetGameColor(GameId.ZZZ) !== null).assertTrue();
      expect(getWidgetGameColor(GameId.HONKAI3) !== null).assertTrue();
    });

    it('getWidgetBgColors 始终返回 3 个颜色', 0, () => {
      expect(getWidgetBgColors(GameId.GENSHIN).length).assertEqual(3);
      expect(getWidgetBgColors(GameId.STARRAIL).length).assertEqual(3);
      expect(getWidgetBgColors(GameId.ZZZ).length).assertEqual(3);
      expect(getWidgetBgColors(GameId.HONKAI3).length).assertEqual(3);
    });

  });
}
