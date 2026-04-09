/**
 * ZZZDailyNoteParser.test.ets
 */

import { describe, it, expect } from '@ohos/hypium';
import { ZZZDailyNoteParser } from '../main/ets/parsers/zzz/ZZZDailyNoteParser';

const VALID_JSON = JSON.stringify({
  energy: {
    progress: { current: 180, max: 240 },
    restore: 3600
  },
  vitality: { current: 300, max: 400 },
  card_sign: 'CardSignDone',
  vhs_sale: { sale_state: 'SaleStateDoing' },
  abyss_refresh: 86400,
  member_card: { is_open: true, member_card_state: 'active' }
});

export default function zzzDailyNoteParserTest() {
  describe('ZZZDailyNoteParser', () => {

    it('parse_currentEnergy_isCorrect', 0, () => {
      const data = ZZZDailyNoteParser.parse(VALID_JSON);
      expect(data.currentEnergy).assertEqual(180);
    });

    it('parse_maxEnergy_isCorrect', 0, () => {
      const data = ZZZDailyNoteParser.parse(VALID_JSON);
      expect(data.maxEnergy).assertEqual(240);
    });

    it('parse_energyRecoverTime_isCorrect', 0, () => {
      const data = ZZZDailyNoteParser.parse(VALID_JSON);
      expect(data.energyRecoverTime).assertEqual(3600);
    });

    it('parse_currentVitality_isCorrect', 0, () => {
      const data = ZZZDailyNoteParser.parse(VALID_JSON);
      expect(data.currentVitality).assertEqual(300);
    });

    it('parse_maxVitality_isCorrect', 0, () => {
      const data = ZZZDailyNoteParser.parse(VALID_JSON);
      expect(data.maxVitality).assertEqual(400);
    });

    it('parse_cardSign_isCorrect', 0, () => {
      const data = ZZZDailyNoteParser.parse(VALID_JSON);
      expect(data.cardSign).assertEqual('CardSignDone');
    });

    it('parse_videoStoreState_isCorrect', 0, () => {
      const data = ZZZDailyNoteParser.parse(VALID_JSON);
      expect(data.videoStoreState).assertEqual('SaleStateDoing');
    });

    it('parse_abyssRefresh_isCorrect', 0, () => {
      const data = ZZZDailyNoteParser.parse(VALID_JSON);
      expect(data.abyssRefresh).assertEqual(86400);
    });

    it('parse_memberCardIsOpen_isCorrect', 0, () => {
      const data = ZZZDailyNoteParser.parse(VALID_JSON);
      expect(data.memberCardIsOpen).assertTrue();
    });

    it('parse_cardSignNo_isCorrect', 0, () => {
      const json = JSON.stringify({
        energy: { progress: { current: 0, max: 240 }, restore: 0 },
        vitality: { current: 0, max: 400 },
        card_sign: 'CardSignNo',
        vhs_sale: { sale_state: 'SaleStateNo' },
        abyss_refresh: 0,
        member_card: { is_open: false, member_card_state: '' }
      });
      const data = ZZZDailyNoteParser.parse(json);
      expect(data.cardSign).assertEqual('CardSignNo');
      expect(data.videoStoreState).assertEqual('SaleStateNo');
      expect(data.memberCardIsOpen).assertFalse();
    });

    it('parse_invalidJson_returnsDefaultData', 0, () => {
      const data = ZZZDailyNoteParser.parse('invalid');
      expect(data.currentEnergy).assertEqual(0);
      expect(data.maxEnergy).assertEqual(240);
    });

    it('parse_emptyString_returnsDefaultData', 0, () => {
      const data = ZZZDailyNoteParser.parse('');
      expect(data.currentEnergy).assertEqual(0);
    });

    // ── 边界值补充 ───────────────────────────────────────────────

    it('parse_currentEnergy_zero_returns0', 0, () => {
      const json = JSON.stringify({
        energy: { progress: { current: 0, max: 240 }, restore: 0 },
        vitality: { current: 0, max: 400 },
        card_sign: 'CardSignNo',
        vhs_sale: { sale_state: 'SaleStateNo' },
        abyss_refresh: 0,
        member_card: { is_open: false, member_card_state: '' }
      });
      const data = ZZZDailyNoteParser.parse(json);
      expect(data.currentEnergy).assertEqual(0);
    });

    it('parse_energyRestore_zero_returns0', 0, () => {
      // energy.restore=0 表示已满，energyRecoverTime=0
      const json = JSON.stringify({
        energy: { progress: { current: 240, max: 240 }, restore: 0 },
        vitality: { current: 0, max: 400 },
        card_sign: 'CardSignDone',
        vhs_sale: { sale_state: 'SaleStateDone' },
        abyss_refresh: 0,
        member_card: { is_open: true, member_card_state: '' }
      });
      const data = ZZZDailyNoteParser.parse(json);
      expect(data.energyRecoverTime).assertEqual(0);
    });

    it('parse_vhsSale_missing_returnsEmptyString', 0, () => {
      const json = JSON.stringify({
        energy: { progress: { current: 0, max: 240 }, restore: 0 },
        vitality: { current: 0, max: 400 },
        card_sign: 'CardSignNo',
        abyss_refresh: 0,
        member_card: { is_open: false, member_card_state: '' }
        // vhs_sale 故意缺失
      });
      const data = ZZZDailyNoteParser.parse(json);
      expect(data.videoStoreState).assertEqual('');
    });

    it('parse_memberCard_missing_returnsFalse', 0, () => {
      const json = JSON.stringify({
        energy: { progress: { current: 0, max: 240 }, restore: 0 },
        vitality: { current: 0, max: 400 },
        card_sign: 'CardSignNo',
        vhs_sale: { sale_state: 'SaleStateNo' },
        abyss_refresh: 0
        // member_card 故意缺失
      });
      const data = ZZZDailyNoteParser.parse(json);
      expect(data.memberCardIsOpen).assertFalse();
    });

    it('parse_cardSign_SaleStateDone_isCorrect', 0, () => {
      const json = JSON.stringify({
        energy: { progress: { current: 0, max: 240 }, restore: 0 },
        vitality: { current: 0, max: 400 },
        card_sign: 'CardSignDone',
        vhs_sale: { sale_state: 'SaleStateDone' },
        abyss_refresh: 0,
        member_card: { is_open: false, member_card_state: '' }
      });
      const data = ZZZDailyNoteParser.parse(json);
      expect(data.videoStoreState).assertEqual('SaleStateDone');
    });

    it('parse_memberCardIsOpen_true_returnsTrue', 0, () => {
      const json = JSON.stringify({
        energy: { progress: { current: 0, max: 240 }, restore: 0 },
        vitality: { current: 0, max: 400 },
        card_sign: 'CardSignNo',
        vhs_sale: { sale_state: 'SaleStateNo' },
        abyss_refresh: 0,
        member_card: { is_open: true, member_card_state: '' }
      });
      const data = ZZZDailyNoteParser.parse(json);
      expect(data.memberCardIsOpen).assertTrue();
    });

    it('parse_jsonArray_returnsDefaultData', 0, () => {
      const data = ZZZDailyNoteParser.parse('[1, 2, 3]');
      expect(data.currentEnergy).assertEqual(0);
    });
  });
}
