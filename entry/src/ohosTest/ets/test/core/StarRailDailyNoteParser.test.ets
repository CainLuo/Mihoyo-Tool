/**
 * StarRailDailyNoteParser.test.ets
 */

import { describe, it, expect } from '@ohos/hypium';
import { StarRailDailyNoteParser } from 'core';

const VALID_JSON =
  '{"current_stamina":180,"max_stamina":300,"stamina_recover_time":1800,"stamina_full_ts":1700000000,"current_reserve_stamina":2400,"is_reserve_stamina_full":true,"current_train_score":400,"max_train_score":500,"current_rogue_score":10000,"max_rogue_score":14000,"weekly_cocoon_cnt":2,"weekly_cocoon_limit":3,"rogue_tourn_weekly_cur":800,"rogue_tourn_weekly_max":1000,"rogue_tourn_exp_is_full":false,"grid_fight_weekly_cur":1,"grid_fight_weekly_max":3,"current_ts":1700000100}';

export default function starRailDailyNoteParserTest() {
  describe('StarRailDailyNoteParser', () => {

    it('parse_currentStamina_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.currentStamina).assertEqual(180);
    });

    it('parse_maxStamina_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.maxStamina).assertEqual(300);
    });

    it('parse_staminaRecoverTime_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.staminaRecoverTime).assertEqual(1800);
    });

    it('parse_currentReserveStamina_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.currentReserveStamina).assertEqual(2400);
    });

    it('parse_isReserveStaminaFull_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.isReserveStaminaFull).assertTrue();
    });

    it('parse_currentTrainScore_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.currentTrainScore).assertEqual(400);
    });

    it('parse_maxTrainScore_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.maxTrainScore).assertEqual(500);
    });

    it('parse_weeklyCocoonCnt_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.weeklyCocoonCnt).assertEqual(2);
    });

    it('parse_weeklyCocoonLimit_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.weeklyCocoonLimit).assertEqual(3);
    });

    it('parse_rogueTournWeeklyCur_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.rogueTournWeeklyCur).assertEqual(800);
    });

    it('parse_rogueTournWeeklyMax_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.rogueTournWeeklyMax).assertEqual(1000);
    });

    it('parse_gridFightWeeklyCur_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.gridFightWeeklyCur).assertEqual(1);
    });

    it('parse_gridFightWeeklyMax_isCorrect', 0, () => {
      const data = StarRailDailyNoteParser.parse(VALID_JSON);
      expect(data.gridFightWeeklyMax).assertEqual(3);
    });

    it('parse_invalidJson_returnsDefaultData', 0, () => {
      const data = StarRailDailyNoteParser.parse('invalid');
      expect(data.currentStamina).assertEqual(0);
      expect(data.maxStamina).assertEqual(240);
    });

    it('parse_emptyString_returnsDefaultData', 0, () => {
      const data = StarRailDailyNoteParser.parse('');
      expect(data.currentStamina).assertEqual(0);
    });

    it('parse_currentStamina_zero_returns0', 0, () => {
      const json =
        '{"current_stamina":0,"max_stamina":300,"stamina_recover_time":0,"stamina_full_ts":0,"current_reserve_stamina":0,"is_reserve_stamina_full":false,"current_train_score":0,"max_train_score":500,"current_rogue_score":0,"max_rogue_score":14000,"weekly_cocoon_cnt":0,"weekly_cocoon_limit":3,"rogue_tourn_weekly_cur":0,"rogue_tourn_weekly_max":1000,"rogue_tourn_exp_is_full":false,"grid_fight_weekly_cur":0,"grid_fight_weekly_max":3,"current_ts":0}';
      const data = StarRailDailyNoteParser.parse(json);
      expect(data.currentStamina).assertEqual(0);
    });

    it('parse_gridFightWeeklyCur_missing_returns0', 0, () => {
      const json =
        '{"current_stamina":180,"max_stamina":300,"stamina_recover_time":1800,"stamina_full_ts":0,"current_reserve_stamina":0,"is_reserve_stamina_full":false,"current_train_score":0,"max_train_score":500,"current_rogue_score":0,"max_rogue_score":14000,"weekly_cocoon_cnt":0,"weekly_cocoon_limit":3,"rogue_tourn_weekly_cur":0,"rogue_tourn_weekly_max":1000,"rogue_tourn_exp_is_full":false,"current_ts":0}';
      const data = StarRailDailyNoteParser.parse(json);
      expect(data.gridFightWeeklyCur).assertEqual(0);
    });

    it('parse_maxStamina_zero_doesNotCrash', 0, () => {
      const json =
        '{"current_stamina":0,"max_stamina":0,"stamina_recover_time":0,"stamina_full_ts":0,"current_reserve_stamina":0,"is_reserve_stamina_full":false,"current_train_score":0,"max_train_score":0,"current_rogue_score":0,"max_rogue_score":0,"weekly_cocoon_cnt":0,"weekly_cocoon_limit":0,"rogue_tourn_weekly_cur":0,"rogue_tourn_weekly_max":0,"rogue_tourn_exp_is_full":false,"grid_fight_weekly_cur":0,"grid_fight_weekly_max":0,"current_ts":0}';
      const data = StarRailDailyNoteParser.parse(json);
      expect(data.maxStamina).assertEqual(0);
    });
  });
}
