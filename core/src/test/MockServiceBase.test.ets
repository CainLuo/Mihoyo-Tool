/**
 * MockServiceBase.test.ets
 *
 * 测试 MockServiceBase 的纯静态方法：
 * - pathToFileName：URL 路径 → 文件名映射
 * - extractAccountId：从 Cookie 提取 account_id
 */

import { describe, it, expect } from '@ohos/hypium';
import { MockServiceBase } from '../main/ets/network/v2/mock/MockServiceBase';

export default function mockServiceBaseTest() {
  describe('MockServiceBase.pathToFileName', () => {

    // ── 通用规则 ─────────────────────────────────────────────────

    it('genshinDailyNote_mapsCorrectly', 0, () => {
      const result = MockServiceBase.pathToFileName('/game_record/app/genshin/api/dailyNote');
      expect(result).assertEqual('game_record_app_genshin_api_dailyNote.json');
    });

    it('genshinCharacterList_mapsCorrectly', 0, () => {
      const result = MockServiceBase.pathToFileName('/game_record/app/genshin/api/character/list');
      expect(result).assertEqual('game_record_app_genshin_api_character_list.json');
    });

    it('starRailNote_mapsCorrectly', 0, () => {
      const result = MockServiceBase.pathToFileName('/game_record/app/hkrpg/api/note');
      expect(result).assertEqual('game_record_app_hkrpg_api_note.json');
    });

    it('zzzAvatarBasic_mapsCorrectly', 0, () => {
      const result = MockServiceBase.pathToFileName('/event/game_record_zzz/api/zzz/avatar/basic');
      expect(result).assertEqual('event_game_record_zzz_api_zzz_avatar_basic.json');
    });

    it('userFullInfo_mapsCorrectly', 0, () => {
      const result = MockServiceBase.pathToFileName('/user/api/getUserFullInfo');
      expect(result).assertEqual('user_api_getUserFullInfo.json');
    });

    it('bindingGameRoles_mapsCorrectly', 0, () => {
      const result = MockServiceBase.pathToFileName('/binding/api/getUserGameRolesByCookie');
      expect(result).assertEqual('binding_api_getUserGameRolesByCookie.json');
    });

    // ── 特殊映射表 ───────────────────────────────────────────────

    it('batchCompute_usesSpecialMapping', 0, () => {
      const result = MockServiceBase.pathToFileName('/event/e20200928calculate/v3/batch_compute');
      expect(result).assertEqual('genshin_character_batch_compute.json');
    });

    it('starRailCompute_usesSpecialMapping', 0, () => {
      const result = MockServiceBase.pathToFileName('/event/rpgcalc/compute');
      expect(result).assertEqual('hkrpg_character_compute.json');
    });

    it('zzzCompute_usesSpecialMapping', 0, () => {
      const result = MockServiceBase.pathToFileName('/event/nap_cultivate_tool/avatar_calc');
      expect(result).assertEqual('zzz_character_compute.json');
    });

    it('bbsSignIn_usesSpecialMapping', 0, () => {
      const result = MockServiceBase.pathToFileName('/app/api/signIn');
      expect(result).assertEqual('apihub_app_api_signIn.json');
    });

    it('genshinCharacterDetail_usesSpecialMapping', 0, () => {
      const result = MockServiceBase.pathToFileName('/game_record/app/genshin/api/character/detail');
      expect(result).assertEqual('game_record_app_genshin_api_character_detail_all.json');
    });

    // ── query 参数去除 ───────────────────────────────────────────

    it('pathWithQuery_stripsQueryBeforeMapping', 0, () => {
      const result = MockServiceBase.pathToFileName('/game_record/app/hkrpg/api/note?role_id=123&server=prod_gf_cn');
      expect(result).assertEqual('game_record_app_hkrpg_api_note.json');
    });

    it('computeWithQuery_usesSpecialMappingAfterStrip', 0, () => {
      const result = MockServiceBase.pathToFileName('/event/rpgcalc/compute?game=hkrpg');
      expect(result).assertEqual('hkrpg_character_compute.json');
    });

    it('zzzComputeWithQuery_usesSpecialMappingAfterStrip', 0, () => {
      const result = MockServiceBase.pathToFileName('/event/nap_cultivate_tool/avatar_calc?uid=123&region=prod_gf_cn');
      expect(result).assertEqual('zzz_character_compute.json');
    });
  });

  describe('MockServiceBase.extractAccountId', () => {

    it('cookieWithAccountId1_returns1', 0, () => {
      const cookie = 'account_id=1; ltoken=abc; ltuid=1';
      expect(MockServiceBase.extractAccountId(cookie)).assertEqual(1);
    });

    it('cookieWithAccountId2_returns2', 0, () => {
      const cookie = 'account_id=2; ltoken=xyz; ltuid=2';
      expect(MockServiceBase.extractAccountId(cookie)).assertEqual(2);
    });

    it('cookieWithLargeAccountId_returnsCorrectly', 0, () => {
      const cookie = 'account_id=123456789; ltoken=abc';
      expect(MockServiceBase.extractAccountId(cookie)).assertEqual(123456789);
    });

    it('cookieWithoutAccountId_returns1AsFallback', 0, () => {
      const cookie = 'ltoken=abc; ltuid=1';
      expect(MockServiceBase.extractAccountId(cookie)).assertEqual(1);
    });

    it('emptyCookie_returns1AsFallback', 0, () => {
      expect(MockServiceBase.extractAccountId('')).assertEqual(1);
    });

    it('cookieWithAccountIdNotFirst_extractsCorrectly', 0, () => {
      const cookie = 'ltoken=abc; account_id=5; ltuid=5';
      expect(MockServiceBase.extractAccountId(cookie)).assertEqual(5);
    });
  });
}
