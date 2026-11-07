import { describe, it, expect } from '@ohos/hypium';
import { GameId } from 'core';
import { getPreviewStaminaData, PreviewStamina } from '../main/ets/model/WidgetPreviewModels';

export default function widgetPreviewModelsTest() {
  describe('WidgetPreviewModels', () => {

    it('PreviewStamina 构造函数赋值', 0, () => {
      const data = new PreviewStamina(10, 20, 1, 30);
      expect(data.cur).assertEqual(10);
      expect(data.max).assertEqual(20);
      expect(data.recHours).assertEqual(1);
      expect(data.recMinutes).assertEqual(30);
    });

    it('原神预览数据', 0, () => {
      const data = getPreviewStaminaData(GameId.GENSHIN);
      expect(data.cur).assertEqual(140);
      expect(data.max).assertEqual(160);
      expect(data.recHours).assertEqual(2);
      expect(data.recMinutes).assertEqual(30);
    });

    it('星铁预览数据', 0, () => {
      const data = getPreviewStaminaData(GameId.STARRAIL);
      expect(data.cur).assertEqual(200);
      expect(data.max).assertEqual(240);
      expect(data.recHours).assertEqual(3);
      expect(data.recMinutes).assertEqual(15);
    });

    it('绝区零预览数据', 0, () => {
      const data = getPreviewStaminaData(GameId.ZZZ);
      expect(data.cur).assertEqual(180);
      expect(data.max).assertEqual(240);
      expect(data.recHours).assertEqual(2);
      expect(data.recMinutes).assertEqual(0);
    });

    it('未知游戏返回空占位数据', 0, () => {
      const data = getPreviewStaminaData(GameId.HONKAI3);
      expect(data.cur).assertEqual(0);
      expect(data.max).assertEqual(160);
      expect(data.recHours).assertEqual(0);
      expect(data.recMinutes).assertEqual(0);
    });

  });
}
