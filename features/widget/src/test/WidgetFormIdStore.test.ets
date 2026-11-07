import { describe, it, expect } from '@ohos/hypium';
import { formIdFromStorageKey } from '../main/ets/model/service/WidgetFormIdStore';

export default function widgetFormIdStoreTest() {
  describe('WidgetFormIdStore.formIdFromStorageKey', () => {

    it('form_ 前缀的 key 提取 formId', 0, () => {
      expect(formIdFromStorageKey('form_123456')).assertEqual('123456');
      expect(formIdFromStorageKey('form_abc-def')).assertEqual('abc-def');
    });

    it('非卡片 key 返回 null', 0, () => {
      expect(formIdFromStorageKey('other_123')).assertNull();
      expect(formIdFromStorageKey('123456')).assertNull();
      expect(formIdFromStorageKey('')).assertNull();
    });

    it('只有前缀、没有 formId 时返回 null', 0, () => {
      expect(formIdFromStorageKey('form_')).assertNull();
    });

  });
}
