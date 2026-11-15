import { describe, it, expect } from '@ohos/hypium';
import { decodeNotifyMarker, decodeStateEntry } from '../main/ets/model/service/NotificationStateStore';

export default function notificationStateStoreTest() {
  describe('NotificationStateStore.decodeStateEntry', () => {

    it('reminderId 为负表示没有有效调度', 0, () => {
      expect(decodeStateEntry(-1, 100, 160, 1000)).assertNull();
      expect(decodeStateEntry(-100, 100, 160, 1000)).assertNull();
    });

    it('有效 reminderId 还原全部字段', 0, () => {
      const entry = decodeStateEntry(42, 3600, 160, 1700000000);
      expect(entry !== null).assertTrue();
      if (entry !== null) {
        expect(entry.reminderId).assertEqual(42);
        expect(entry.recoveryTimeSnapshot).assertEqual(3600);
        expect(entry.threshold).assertEqual(160);
        expect(entry.scheduledAt).assertEqual(1700000000);
      }
    });

    it('reminderId 为 0 也是有效值', 0, () => {
      const entry = decodeStateEntry(0, 0, 0, 0);
      expect(entry !== null).assertTrue();
      if (entry !== null) {
        expect(entry.reminderId).assertEqual(0);
      }
    });

  });

  describe('NotificationStateStore.decodeNotifyMarker', () => {

    it('threshold 为负表示从未发送即时通知', 0, () => {
      expect(decodeNotifyMarker(-1, 0) === null).assertTrue();
      expect(decodeNotifyMarker(-100, 1700000000) === null).assertTrue();
    });

    it('有效标记还原阈值与通知时间', 0, () => {
      const marker = decodeNotifyMarker(160, 1700000000);
      expect(marker !== null).assertTrue();
      if (marker !== null) {
        expect(marker.threshold).assertEqual(160);
        expect(marker.notifiedAt).assertEqual(1700000000);
      }
    });

    it('threshold 为 0 也是有效值', 0, () => {
      const marker = decodeNotifyMarker(0, 0);
      expect(marker !== null).assertTrue();
      if (marker !== null) {
        expect(marker.threshold).assertEqual(0);
      }
    });

  });
}
