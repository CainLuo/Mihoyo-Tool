import { describe, it, expect } from '@ohos/hypium';
import {
  getDimension,
  getFormName,
  getPresetKey,
} from '../main/ets/model/WidgetSettingsSizeConfig';
import { WidgetSize } from '../main/ets/model/WidgetConfigModels';
import { GameId } from 'core';

export default function widgetSettingsSizeConfigTest() {
  describe('WidgetSettingsSizeConfig', () => {

    it('1x2 按游戏返回三个独立模板', 0, () => {
      expect(getFormName(WidgetSize.SIZE_1X2, GameId.GENSHIN)).assertEqual('widget_1x2_genshin');
      expect(getFormName(WidgetSize.SIZE_1X2, GameId.STARRAIL)).assertEqual('widget_1x2_starrail');
      expect(getFormName(WidgetSize.SIZE_1X2, GameId.ZZZ)).assertEqual('widget_1x2_zzz');
      expect(getFormName(WidgetSize.SIZE_1X2, 'unknown')).assertEqual('widget_1x2_genshin');
    });

    it('其他尺寸返回通用模板', 0, () => {
      expect(getFormName(WidgetSize.SIZE_2X2, GameId.GENSHIN)).assertEqual('widget_2x2');
      expect(getFormName(WidgetSize.SIZE_2X4, GameId.ZZZ)).assertEqual('widget_2x4');
      expect(getFormName(WidgetSize.SIZE_4X4, GameId.STARRAIL)).assertEqual('widget_4x4');
    });

    it('getDimension 映射到 FormDimension', 0, () => {
      expect(getDimension(WidgetSize.SIZE_1X2)).assertEqual(1);
      expect(getDimension(WidgetSize.SIZE_2X2)).assertEqual(2);
      expect(getDimension(WidgetSize.SIZE_2X4)).assertEqual(3);
      expect(getDimension(WidgetSize.SIZE_4X4)).assertEqual(4);
    });

    it('getPresetKey 映射到 widgets 存储 key', 0, () => {
      expect(getPresetKey(WidgetSize.SIZE_1X2)).assertEqual('widget12');
      expect(getPresetKey(WidgetSize.SIZE_2X2)).assertEqual('widget22');
      expect(getPresetKey(WidgetSize.SIZE_2X4)).assertEqual('widget24');
      expect(getPresetKey(WidgetSize.SIZE_4X4)).assertEqual('widget44');
    });

  });
}
