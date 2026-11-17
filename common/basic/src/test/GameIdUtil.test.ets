import { describe, it, expect } from '@ohos/hypium';
import { GameId } from 'core';
import { parseGameIdFromApiUrl } from '../main/ets/utils/GameIdUtil';

export default function gameIdUtilTest() {
  describe('GameIdUtil.parseGameIdFromApiUrl', () => {

    it('hkrpg 地址识别为星铁', 0, () => {
      expect(parseGameIdFromApiUrl('https://api-takumi-record.mihoyo.com/game_record/app/hkrpg/api/note'))
        .assertEqual(GameId.STARRAIL);
    });

    it('zzz 地址识别为绝区零', 0, () => {
      expect(parseGameIdFromApiUrl('https://api-takumi-record.mihoyo.com/game_record/app/zzz/api/note'))
        .assertEqual(GameId.ZZZ);
    });

    it('nap_ 地址识别为绝区零', 0, () => {
      expect(parseGameIdFromApiUrl('https://example.com/nap_cn/api/note'))
        .assertEqual(GameId.ZZZ);
    });

    it('其他地址回落原神', 0, () => {
      expect(parseGameIdFromApiUrl('https://api-takumi-record.mihoyo.com/game_record/app/genshin/api/dailyNote'))
        .assertEqual(GameId.GENSHIN);
      expect(parseGameIdFromApiUrl('')).assertEqual(GameId.GENSHIN);
    });

  });
}
