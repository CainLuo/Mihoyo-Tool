import { describe, it, expect } from '@ohos/hypium';
import { WidgetConfig, WidgetSize } from '../main/ets/model/WidgetConfigModels';
import { decodeWidgetConfig } from '../main/ets/model/service/WidgetConfigStore';
import { WidgetSlotRef } from '../main/ets/model/WidgetDataStoreModels';

export default function widgetConfigStoreTest() {
  describe('WidgetConfigStore.decodeWidgetConfig', () => {

    it('合法配置可解析', 0, () => {
      const config = new WidgetConfig();
      config.formId = 'form_1';
      config.formName = 'widget_2x2';
      config.size = WidgetSize.SIZE_2X2;
      const slot = new WidgetSlotRef();
      slot.accountId = 'acc1';
      slot.gameId = 'genshin';
      slot.roleId = 'role1';
      config.slots.push(slot);

      const decoded = decodeWidgetConfig(config.toJson());
      expect(decoded !== null).assertTrue();
      if (decoded !== null) {
        expect(decoded.formId).assertEqual('form_1');
        expect(decoded.formName).assertEqual('widget_2x2');
        expect(decoded.size).assertEqual(WidgetSize.SIZE_2X2);
        expect(decoded.slots.length).assertEqual(1);
      }
    });

    it('空串返回 null', 0, () => {
      expect(decodeWidgetConfig('')).assertNull();
    });

    it('非法 JSON 返回 null', 0, () => {
      expect(decodeWidgetConfig('{')).assertNull();
      expect(decodeWidgetConfig('not-json')).assertNull();
    });

    it('缺少 formId 返回 null', 0, () => {
      expect(decodeWidgetConfig('{"formName":"widget_2x2","size":"2x2","slots":[]}')).assertNull();
    });

    it('空 slots 的合法配置仍可解析', 0, () => {
      const decoded = decodeWidgetConfig('{"formId":"form_2","formName":"widget_1x2","size":"1x2","slots":[]}');
      expect(decoded !== null).assertTrue();
      if (decoded !== null) {
        expect(decoded.formId).assertEqual('form_2');
        expect(decoded.slots.length).assertEqual(0);
      }
    });

  });
}
