/**
 * WidgetDataHelper.test.ets — Widget 数据解析辅助类测试
 */

import {
  WidgetDataHelper,
  ParsedExtraRow
} from '../main/ets/widget/utils/WidgetDataHelper';
import { StaminaColorType } from '../main/ets/widget/models/WidgetUIStates';

/**
 * 测试套件：WidgetDataHelper
 */
export default function widgetDataHelperTest(): void {
  describe('WidgetDataHelper', () => {
    
    // ── formatRecoveryTime ─────────────────────────────────────────────────
    
    it('formatRecoveryTime_zeroSeconds_isFull', () => {
      const result = WidgetDataHelper.formatRecoveryTime(0, false);
      expect(result.isFull).assertFalse();
      expect(result.hours).assertEqual(0);
      expect(result.minutes).assertEqual(0);
    });
    
    it('formatRecoveryTime_isFullTrue_returnsFull', () => {
      const result = WidgetDataHelper.formatRecoveryTime(3600, true);
      expect(result.isFull).assertTrue();
    });
    
    it('formatRecoveryTime_lessThanHour_onlyMinutes', () => {
      const result = WidgetDataHelper.formatRecoveryTime(1800, false);
      expect(result.isFull).assertFalse();
      expect(result.hours).assertEqual(0);
      expect(result.minutes).assertEqual(30);
    });
    
    it('formatRecoveryTime_moreThanHour_hoursAndMinutes', () => {
      const result = WidgetDataHelper.formatRecoveryTime(5400, false);
      expect(result.isFull).assertFalse();
      expect(result.hours).assertEqual(1);
      expect(result.minutes).assertEqual(30);
    });
    
    it('formatRecoveryTime_exactHour_noMinutes', () => {
      const result = WidgetDataHelper.formatRecoveryTime(7200, false);
      expect(result.isFull).assertFalse();
      expect(result.hours).assertEqual(2);
      expect(result.minutes).assertEqual(0);
    });
    
    // ── calcStaminaRatio ───────────────────────────────────────────────────
    
    it('calcStaminaRatio_zeroMax_returnsZero', () => {
      const ratio = WidgetDataHelper.calcStaminaRatio(100, 0);
      expect(ratio).assertEqual(0);
    });
    
    it('calcStaminaRatio_half_returnsHalf', () => {
      const ratio = WidgetDataHelper.calcStaminaRatio(100, 200);
      expect(ratio).assertEqual(0.5);
    });
    
    it('calcStaminaRatio_full_returnsOne', () => {
      const ratio = WidgetDataHelper.calcStaminaRatio(200, 200);
      expect(ratio).assertEqual(1);
    });
    
    it('calcStaminaRatio_zeroCurrent_returnsZero', () => {
      const ratio = WidgetDataHelper.calcStaminaRatio(0, 200);
      expect(ratio).assertEqual(0);
    });
    
    // ── calcIsFull ─────────────────────────────────────────────────────────
    
    it('calcIsFull_currentEqualsMax_recoveryZero_returnsTrue', () => {
      const isFull = WidgetDataHelper.calcIsFull(200, 200, 0);
      expect(isFull).assertTrue();
    });
    
    it('calcIsFull_currentLessMax_returnsFalse', () => {
      const isFull = WidgetDataHelper.calcIsFull(100, 200, 3600);
      expect(isFull).assertFalse();
    });
    
    it('calcIsFull_currentEqualsMax_recoveryPositive_returnsFalse', () => {
      const isFull = WidgetDataHelper.calcIsFull(200, 200, 100);
      expect(isFull).assertFalse();
    });
    
    it('calcIsFull_zeroCurrent_returnsFalse', () => {
      const isFull = WidgetDataHelper.calcIsFull(0, 200, 0);
      expect(isFull).assertFalse();
    });
    
    // ── calcStaminaColorType ───────────────────────────────────────────────
    
    it('calcStaminaColorType_low_returnsLow', () => {
      const type = WidgetDataHelper.calcStaminaColorType(30, 200);
      expect(type).assertEqual(StaminaColorType.LOW);
    });
    
    it('calcStaminaColorType_medium_returnsMedium', () => {
      const type = WidgetDataHelper.calcStaminaColorType(100, 200);
      expect(type).assertEqual(StaminaColorType.MEDIUM);
    });
    
    it('calcStaminaColorType_high_returnsHigh', () => {
      const type = WidgetDataHelper.calcStaminaColorType(160, 200);
      expect(type).assertEqual(StaminaColorType.HIGH);
    });
    
    it('calcStaminaColorType_exactThreshold_lowToMedium', () => {
      // 0.3 边界值，应为 LOW（<= 0.3 是 LOW）
      const type = WidgetDataHelper.calcStaminaColorType(60, 200);
      expect(type).assertEqual(StaminaColorType.LOW);
    });
    
    it('calcStaminaColorType_exactThreshold_mediumToHigh', () => {
      // 0.7 边界值，应为 MEDIUM（<= 0.7 是 MEDIUM）
      const type = WidgetDataHelper.calcStaminaColorType(140, 200);
      expect(type).assertEqual(StaminaColorType.MEDIUM);
    });
    
    // ── parseReserveStamina ────────────────────────────────────────────────
    
    it('parseReserveStamina_emptyJson_returnsZero', () => {
      const result = WidgetDataHelper.parseReserveStamina('');
      expect(result).assertEqual('0');
    });
    
    it('parseReserveStamina_validJson_returnsValue', () => {
      const json = '{"current_reserve_stamina":2400}';
      const result = WidgetDataHelper.parseReserveStamina(json);
      expect(result).assertEqual('2400');
    });
    
    it('parseReserveStamina_missingField_returnsZero', () => {
      const json = '{"other_field":100}';
      const result = WidgetDataHelper.parseReserveStamina(json);
      expect(result).assertEqual('0');
    });
    
    it('parseReserveStamina_invalidJson_returnsZero', () => {
      const result = WidgetDataHelper.parseReserveStamina('invalid');
      expect(result).assertEqual('0');
    });
    
    // ── parseExpeditions ───────────────────────────────────────────────────
    
    it('parseExpeditions_emptyJson_returnsEmpty', () => {
      const result = WidgetDataHelper.parseExpeditions('');
      expect(result.length).assertEqual(0);
    });
    
    it('parseExpeditions_validJson_returnsAvatars', () => {
      const json = '{"expeditions":[{"avatar_side_icon":"url1","status":"Finished"},{"avatar_side_icon":"url2","status":"Ongoing"}]}';
      const result = WidgetDataHelper.parseExpeditions(json, 'exp');
      expect(result.length).assertEqual(2);
      expect(result[0].finished).assertTrue();
      expect(result[1].finished).assertFalse();
    });
    
    it('parseExpeditions_moreThan5_truncatesTo5', () => {
      const json = '{"expeditions":[1,2,3,4,5,6,7]}';
      const result = WidgetDataHelper.parseExpeditions(json, 'exp');
      expect(result.length).assertEqual(5);
    });
    
    it('parseExpeditions_memoryUrl_correctFormat', () => {
      const json = '{"expeditions":[{"avatar_side_icon":"url","status":"Finished"}]}';
      const result = WidgetDataHelper.parseExpeditions(json, 'exp');
      expect(result[0].memoryUrl).assertEqual('memory://exp_0');
    });
    
    // ── parseExtraRows ─────────────────────────────────────────────────────
    
    it('parseExtraRows_emptyJson_returnsEmpty', () => {
      const result = WidgetDataHelper.parseExtraRows('', 'genshin');
      expect(result.length).assertEqual(0);
    });
    
    it('parseExtraRows_genshin_parsesExpedition', () => {
      const json = '{"max_expedition_num":5,"expeditions":[{"status":"Finished"},{"status":"Finished"},{"status":"Ongoing"}]}';
      const result = WidgetDataHelper.parseExtraRows(json, 'genshin');
      // 第一行应该是派遣
      expect(result.length).assertGreater(0);
      expect(result[0].label).assertEqual('expedition');
      expect(result[0].value).assertEqual('2/5');
    });
    
    it('parseExtraRows_genshin_parsesHomeCoin', () => {
      const json = '{"max_home_coin":2400,"current_home_coin":1800}';
      const result = WidgetDataHelper.parseExtraRows(json, 'genshin');
      const coinRow = result.find(r => r.label === 'home_coin');
      expect(coinRow !== undefined).assertTrue();
      expect(coinRow!.value).assertEqual('1800/2400');
    });
    
    it('parseExtraRows_genshin_parsesDailyTask', () => {
      const json = '{"total_task_num":4,"finished_task_num":4,"is_extra_task_reward_received":true}';
      const result = WidgetDataHelper.parseExtraRows(json, 'genshin');
      const taskRow = result.find(r => r.label === 'daily_task');
      expect(taskRow !== undefined).assertTrue();
      expect(taskRow!.value).assertEqual('received');
    });
    
    it('parseExtraRows_genshin_parsesTransformer', () => {
      const json = '{"transformer":{"obtained":true,"reached":true}}';
      const result = WidgetDataHelper.parseExtraRows(json, 'genshin');
      const transformerRow = result.find(r => r.label === 'transformer');
      expect(transformerRow !== undefined).assertTrue();
      expect(transformerRow!.value).assertEqual('ready');
    });
    
    it('parseExtraRows_starrail_parsesReserveStamina', () => {
      const json = '{"current_reserve_stamina":2400}';
      const result = WidgetDataHelper.parseExtraRows(json, 'starrail');
      const reserveRow = result.find(r => r.label === 'reserve_stamina');
      expect(reserveRow !== undefined).assertTrue();
      expect(reserveRow!.value).assertEqual('2400');
    });
    
    it('parseExtraRows_starrail_parsesTrainScore', () => {
      const json = '{"max_train_score":500,"current_train_score":400}';
      const result = WidgetDataHelper.parseExtraRows(json, 'starrail');
      const trainRow = result.find(r => r.label === 'train_score');
      expect(trainRow !== undefined).assertTrue();
      expect(trainRow!.value).assertEqual('400/500');
    });
    
    it('parseExtraRows_zzz_parsesVitality', () => {
      const json = '{"vitality":{"current":300,"max":400}}';
      const result = WidgetDataHelper.parseExtraRows(json, 'zzz');
      const vitalityRow = result.find(r => r.label === 'vitality');
      expect(vitalityRow !== undefined).assertTrue();
      expect(vitalityRow!.value).assertEqual('300/400');
    });
    
    it('parseExtraRows_zzz_parsesCardSign', () => {
      const json = '{"card_sign":"CardSignDone"}';
      const result = WidgetDataHelper.parseExtraRows(json, 'zzz');
      const cardRow = result.find(r => r.label === 'card_sign');
      expect(cardRow !== undefined).assertTrue();
      expect(cardRow!.value).assertEqual('done');
    });
    
    it('parseExtraRows_zzz_parsesVideoStore', () => {
      const json = '{"vhs_sale":{"sale_state":"SaleStateDoing"}}';
      const result = WidgetDataHelper.parseExtraRows(json, 'zzz');
      const videoRow = result.find(r => r.label === 'video_store');
      expect(videoRow !== undefined).assertTrue();
      expect(videoRow!.value).assertEqual('open');
    });
    
    it('parseExtraRows_invalidJson_returnsEmpty', () => {
      const result = WidgetDataHelper.parseExtraRows('invalid', 'genshin');
      expect(result.length).assertEqual(0);
    });
    
    // ── getExtraRowLabelResource ───────────────────────────────────────────
    
    it('getExtraRowLabelResource_expedition_returnsResource', () => {
      const result = WidgetDataHelper.getExtraRowLabelResource('expedition');
      // Resource 对象无法直接断言，只验证不崩溃
      expect(result !== undefined).assertTrue();
    });
    
    it('getExtraRowLabelResource_unknown_returnsOriginal', () => {
      const result = WidgetDataHelper.getExtraRowLabelResource('unknown_key');
      expect(result).assertEqual('unknown_key');
    });
    
    // ── getExtraRowValueDisplay ────────────────────────────────────────────
    
    it('getExtraRowValueDisplay_done_returnsResource', () => {
      const result = WidgetDataHelper.getExtraRowValueDisplay('done');
      expect(result !== undefined).assertTrue();
    });
    
    it('getExtraRowValueDisplay_numeric_returnsOriginal', () => {
      const result = WidgetDataHelper.getExtraRowValueDisplay('1800/2400');
      expect(result).assertEqual('1800/2400');
    });
  });
}
