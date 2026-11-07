import { describe, it, expect } from '@ohos/hypium';
import {
  getMaxSlots,
  WidgetConfig,
  WidgetSize,
} from '../main/ets/model/WidgetConfigModels';
import { WidgetSlotRef } from '../main/ets/model/WidgetDataStoreModels';

function makeSlot(accountId: string, gameId: string, roleId: string): WidgetSlotRef {
  const slot = new WidgetSlotRef();
  slot.accountId = accountId;
  slot.accountName = 'account';
  slot.gameId = gameId;
  slot.roleId = roleId;
  slot.nickname = roleId;
  slot.server = 'cn_gf01';
  return slot;
}

export default function widgetConfigModelsTest() {
  describe('WidgetConfigModels', () => {

    it('getMaxSlots 各尺寸上限', 0, () => {
      expect(getMaxSlots(WidgetSize.SIZE_1X2)).assertEqual(1);
      expect(getMaxSlots(WidgetSize.SIZE_2X2)).assertEqual(2);
      expect(getMaxSlots(WidgetSize.SIZE_2X4)).assertEqual(2);
      expect(getMaxSlots(WidgetSize.SIZE_4X4)).assertEqual(2);
    });

    it('validate 要求至少 1 个且不超过尺寸上限', 0, () => {
      const config = new WidgetConfig();
      config.size = WidgetSize.SIZE_2X2;
      expect(config.validate()).assertFalse();

      config.addSlot(makeSlot('a', 'genshin', 'r1'));
      expect(config.validate()).assertTrue();

      config.addSlot(makeSlot('a', 'genshin', 'r2'));
      expect(config.validate()).assertTrue();

      // addSlot 会拒绝第 3 个；直接构造超限数组验证 validate 的上限判断
      const third = makeSlot('a', 'genshin', 'r3');
      expect(config.addSlot(third)).assertFalse();
      config.slots.push(third);
      expect(config.validate()).assertFalse();
    });

    it('addSlot 拒绝重复 key 与超上限', 0, () => {
      const config = new WidgetConfig();
      config.size = WidgetSize.SIZE_1X2;

      expect(config.addSlot(makeSlot('a', 'genshin', 'r1'))).assertTrue();
      expect(config.addSlot(makeSlot('a', 'genshin', 'r1'))).assertFalse();
      expect(config.addSlot(makeSlot('a', 'genshin', 'r2'))).assertFalse();
      expect(config.slots.length).assertEqual(1);
    });

    it('removeSlotAt 只移除合法下标', 0, () => {
      const config = new WidgetConfig();
      config.size = WidgetSize.SIZE_2X2;
      config.addSlot(makeSlot('a', 'genshin', 'r1'));
      config.addSlot(makeSlot('a', 'genshin', 'r2'));

      config.removeSlotAt(-1);
      config.removeSlotAt(5);
      expect(config.slots.length).assertEqual(2);

      config.removeSlotAt(0);
      expect(config.slots.length).assertEqual(1);
      expect(config.slots[0].roleId).assertEqual('r2');
    });

    it('isSlotSelected / toggleSlot 行为', 0, () => {
      const config = new WidgetConfig();
      config.size = WidgetSize.SIZE_2X2;
      const first = makeSlot('a', 'genshin', 'r1');
      const second = makeSlot('a', 'genshin', 'r2');
      config.addSlot(first);

      expect(config.isSlotSelected('a', 'genshin', 'r1')).assertTrue();
      expect(config.isSlotSelected('a', 'genshin', 'r2')).assertFalse();

      expect(config.toggleSlot(first)).assertFalse();
      expect(config.isSlotSelected('a', 'genshin', 'r1')).assertFalse();

      expect(config.toggleSlot(second)).assertTrue();
      expect(config.isSlotSelected('a', 'genshin', 'r2')).assertTrue();
    });

    it('toJson / fromJson 往返保留字段', 0, () => {
      const config = new WidgetConfig();
      config.formId = 'form_1';
      config.formName = 'widget_2x2';
      config.size = WidgetSize.SIZE_2X4;
      config.slots = [makeSlot('a', 'genshin', 'r1')];

      const json = config.toJson();
      const parsed = WidgetConfig.fromJson(json);
      expect(parsed.formId).assertEqual('form_1');
      expect(parsed.formName).assertEqual('widget_2x2');
      expect(parsed.size).assertEqual(WidgetSize.SIZE_2X4);
      expect(parsed.slots.length).assertEqual(1);
      expect(parsed.slots[0].key).assertEqual('a/r1');
    });

    it('fromJson 空串 / 非法 JSON 返回默认配置', 0, () => {
      const empty = WidgetConfig.fromJson('');
      expect(empty.formId).assertEqual('');
      expect(empty.size).assertEqual(WidgetSize.SIZE_2X2);
      expect(empty.slots.length).assertEqual(0);

      const invalid = WidgetConfig.fromJson('{bad json');
      expect(invalid.size).assertEqual(WidgetSize.SIZE_2X2);
      expect(invalid.slots.length).assertEqual(0);
    });

  });
}
