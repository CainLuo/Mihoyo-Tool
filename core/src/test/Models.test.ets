/**
 * Models.test.ets
 *
 * GameDataRow / GameStatsRow 模型常量单元测试。
 * 验证 DataType、GameId、StatKey 枚举常量值正确，
 * 防止重构时意外改变字符串值导致数据库查询失效。
 */

import { describe, it, expect } from '@ohos/hypium';
import { DataType, GameId } from '../main/ets/models/GameDataRow';
import { StatKey } from '../main/ets/models/GameStatsRow';

export default function modelsTest() {
  describe('DataType', () => {

    it('DataType_CHARACTER_isCorrect', 0, () => {
      expect(DataType.CHARACTER).assertEqual('character');
    });

    it('DataType_WEAPON_isCorrect', 0, () => {
      expect(DataType.WEAPON).assertEqual('weapon');
    });

    it('DataType_RELIC_isCorrect', 0, () => {
      expect(DataType.RELIC).assertEqual('relic');
    });

    it('DataType_ACTIVITY_isCorrect', 0, () => {
      expect(DataType.ACTIVITY).assertEqual('activity');
    });

    it('DataType_GACHA_RECORD_isCorrect', 0, () => {
      expect(DataType.GACHA_RECORD).assertEqual('gacha_record');
    });

    it('DataType_GACHA_SUMMARY_isCorrect', 0, () => {
      expect(DataType.GACHA_SUMMARY).assertEqual('gacha_summary');
    });

    it('DataType_DAILY_NOTE_isCorrect', 0, () => {
      expect(DataType.DAILY_NOTE).assertEqual('daily_note');
    });

    it('DataType_ABYSS_isCorrect', 0, () => {
      expect(DataType.ABYSS).assertEqual('abyss');
    });
  });

  describe('GameId', () => {

    it('GameId_GENSHIN_isCorrect', 0, () => {
      expect(GameId.GENSHIN).assertEqual('genshin');
    });

    it('GameId_STARRAIL_isCorrect', 0, () => {
      expect(GameId.STARRAIL).assertEqual('starrail');
    });

    it('GameId_ZZZ_isCorrect', 0, () => {
      expect(GameId.ZZZ).assertEqual('zzz');
    });

    it('GameId_HONKAI3_isCorrect', 0, () => {
      expect(GameId.HONKAI3).assertEqual('honkai3');
    });

    it('GameId_GLOBAL_isCorrect', 0, () => {
      // 活动等公共数据使用 "global" 作为 role_uid
      expect(GameId.GLOBAL).assertEqual('global');
    });
  });

  describe('StatKey', () => {

    it('StatKey_RELIC_SCORE_isCorrect', 0, () => {
      expect(StatKey.RELIC_SCORE).assertEqual('relic_score');
    });

    it('StatKey_IS_GRADUATED_isCorrect', 0, () => {
      expect(StatKey.IS_GRADUATED).assertEqual('is_graduated');
    });

    it('StatKey_CRIT_RATE_isCorrect', 0, () => {
      expect(StatKey.CRIT_RATE).assertEqual('crit_rate');
    });

    it('StatKey_CRIT_DMG_isCorrect', 0, () => {
      expect(StatKey.CRIT_DMG).assertEqual('crit_dmg');
    });

    it('StatKey_PITY_COUNT_isCorrect', 0, () => {
      expect(StatKey.PITY_COUNT).assertEqual('pity_count');
    });

    it('StatKey_UP_PITY_COUNT_isCorrect', 0, () => {
      expect(StatKey.UP_PITY_COUNT).assertEqual('up_pity_count');
    });
  });
}
