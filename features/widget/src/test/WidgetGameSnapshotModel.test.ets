import { describe, it, expect } from '@ohos/hypium';
import { WidgetGameSnapshot } from '../main/ets/model/WidgetGameSnapshotModel';
import { GameId } from 'core';

export default function widgetGameSnapshotModelTest() {
  describe('WidgetGameSnapshot', () => {

    it('默认字段值', 0, () => {
      const snapshot = new WidgetGameSnapshot();
      expect(snapshot.gameId).assertEqual('');
      expect(snapshot.currentStr).assertEqual('0');
      expect(snapshot.maxStr).assertEqual('200');
      expect(snapshot.secondsStr).assertEqual('0');
      expect(snapshot.coinStr).assertEqual('-1');
      expect(snapshot.taskStr).assertEqual('-1');
      expect(snapshot.reserveStr).assertEqual('-1');
      expect(snapshot.vitalityStr).assertEqual('-1');
    });

    it('toJson / fromJson 往返保留字段', 0, () => {
      const snapshot = new WidgetGameSnapshot();
      snapshot.gameId = GameId.STARRAIL;
      snapshot.currentStr = '120';
      snapshot.maxStr = '240';
      snapshot.secondsStr = '3600';
      snapshot.reserveStr = '10';
      snapshot.trainStr = '500';
      snapshot.cardSign = 'CardSignDone';

      const parsed = WidgetGameSnapshot.fromJson(snapshot.toJson());
      expect(parsed.gameId).assertEqual(GameId.STARRAIL);
      expect(parsed.currentStr).assertEqual('120');
      expect(parsed.maxStr).assertEqual('240');
      expect(parsed.secondsStr).assertEqual('3600');
      expect(parsed.reserveStr).assertEqual('10');
      expect(parsed.trainStr).assertEqual('500');
      expect(parsed.cardSign).assertEqual('CardSignDone');
    });

    it('fromJson 空串 / 非法 JSON 返回默认值', 0, () => {
      const empty = WidgetGameSnapshot.fromJson('');
      expect(empty.maxStr).assertEqual('200');

      const invalid = WidgetGameSnapshot.fromJson('{bad json');
      expect(invalid.maxStr).assertEqual('200');
    });

    it('writeToPayload 写入 JSON 字符串', 0, () => {
      const snapshot = new WidgetGameSnapshot();
      snapshot.gameId = GameId.ZZZ;
      const payload: Record<string, string | number | boolean> = {};
      snapshot.writeToPayload(payload, 'game0Json');
      const value = payload['game0Json'];
      expect(typeof value === 'string').assertTrue();
      expect(`${value}`.includes('zzz')).assertTrue();
    });

  });
}
