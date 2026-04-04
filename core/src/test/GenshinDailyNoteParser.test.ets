/**
 * GenshinDailyNoteParser.test.ets
 *
 * 测试 GenshinDailyNoteParser.parse() 的 JSON 解析逻辑。
 */

import { describe, it, expect } from '@ohos/hypium';
import { GenshinDailyNoteParser } from '../main/ets/parsers/genshin/GenshinDailyNoteParser';

// 标准测试 JSON（来自真实 API 响应结构）
const VALID_JSON = JSON.stringify({
  current_resin: 120,
  max_resin: 200,
  resin_recovery_time: '3600',
  current_home_coin: 1500,
  max_home_coin: 2400,
  home_coin_recovery_time: '7200',
  finished_task_num: 3,
  total_task_num: 4,
  is_extra_task_reward_received: false,
  remain_resin_discount_num: 2,
  resin_discount_num_limit: 3,
  transformer: {
    obtained: true,
    recovery_time: {
      Day: 1,
      Hour: 2,
      Minute: 30,
      Second: 0,
      reached: false
    }
  },
  expeditions: [
    { avatar_side_icon: 'https://example.com/icon1.png', status: 'Ongoing', remained_time: '3600' },
    { avatar_side_icon: 'https://example.com/icon2.png', status: 'Finished', remained_time: '0' }
  ],
  max_expedition_num: 5
});

export default function genshinDailyNoteParserTest() {
  describe('GenshinDailyNoteParser', () => {

    // ── 正常解析 ─────────────────────────────────────────────────

    it('parse_currentResin_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.currentResin).assertEqual(120);
    });

    it('parse_maxResin_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.maxResin).assertEqual(200);
    });

    it('parse_resinRecoveryTime_parsedFromString', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.resinRecoveryTime).assertEqual(3600);
    });

    it('parse_currentHomeCoin_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.currentHomeCoin).assertEqual(1500);
    });

    it('parse_maxHomeCoin_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.maxHomeCoin).assertEqual(2400);
    });

    it('parse_finishedTaskNum_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.finishedTaskNum).assertEqual(3);
    });

    it('parse_totalTaskNum_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.totalTaskNum).assertEqual(4);
    });

    it('parse_isExtraTaskRewardReceived_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.isExtraTaskRewardReceived).assertFalse();
    });

    it('parse_remainResinDiscountNum_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.remainResinDiscountNum).assertEqual(2);
    });

    it('parse_maxExpeditionNum_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.maxExpeditionNum).assertEqual(5);
    });

    // ── 派遣解析 ─────────────────────────────────────────────────

    it('parse_expeditions_countIsCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.expeditions.length).assertEqual(2);
    });

    it('parse_expedition_ongoingStatus_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.expeditions[0].status).assertEqual('Ongoing');
    });

    it('parse_expedition_finishedStatus_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.expeditions[1].status).assertEqual('Finished');
    });

    it('parse_expedition_remainedTime_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.expeditions[0].remainedTime).assertEqual('3600');
    });

    // ── 参量质变仪解析 ───────────────────────────────────────────

    it('parse_transformer_obtained_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.transformer.obtained).assertTrue();
    });

    it('parse_transformer_reached_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.transformer.reached).assertFalse();
    });

    it('parse_transformer_day_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.transformer.day).assertEqual(1);
    });

    it('parse_transformer_hour_isCorrect', 0, () => {
      const data = GenshinDailyNoteParser.parse(VALID_JSON);
      expect(data.transformer.hour).assertEqual(2);
    });

    // ── 容错处理 ─────────────────────────────────────────────────

    it('parse_invalidJson_returnsDefaultData', 0, () => {
      const data = GenshinDailyNoteParser.parse('not valid json');
      expect(data.currentResin).assertEqual(0);
      expect(data.maxResin).assertEqual(160);
    });

    it('parse_emptyString_returnsDefaultData', 0, () => {
      const data = GenshinDailyNoteParser.parse('');
      expect(data.currentResin).assertEqual(0);
    });

    it('parse_emptyObject_doesNotCrash', 0, () => {
      const data = GenshinDailyNoteParser.parse('{}');
      expect(data.currentResin).assertEqual(0);
    });

    it('parse_resinRecoveryTime_invalidString_returns0', 0, () => {
      const json = JSON.stringify({
        current_resin: 0, max_resin: 200, resin_recovery_time: 'invalid',
        current_home_coin: 0, max_home_coin: 2400, home_coin_recovery_time: '0',
        finished_task_num: 0, total_task_num: 4, is_extra_task_reward_received: false,
        remain_resin_discount_num: 0, resin_discount_num_limit: 3,
        transformer: { obtained: false, recovery_time: { Day: 0, Hour: 0, Minute: 0, Second: 0, reached: false } },
        expeditions: [], max_expedition_num: 5
      });
      const data = GenshinDailyNoteParser.parse(json);
      expect(data.resinRecoveryTime).assertEqual(0);
    });
  });
}
