/**
 * Widget2x2ViewModel.test.ets — 2x2 Widget ViewModel 测试
 */

import { describe, it, expect } from '@ohos/hypium';
import { Widget2x2ViewModel } from '../main/ets/widget/viewmodel/Widget2x2ViewModel';
import { Widget2x2UIState, WidgetRoleUIState, Widget1x2RoleUIState, StaminaColorType, parsePayload, ParsedPayload } from 'widgetbase';

/**
 * 测试套件：Widget2x2ViewModel
 */
export default function widget2x2ViewModelTest(): void {
  describe('Widget2x2ViewModel', () => {
    
    // ── buildUIState - 空数据 ─────────────────────────────────────────────
    
    it('buildUIState_emptyPayload_isEmptyTrue', 0, () => {
      const parsed = parsePayload('');
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.isEmpty).assertTrue();
    });
    
    it('buildUIState_emptyAccounts_isEmptyTrue', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[]}';
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.isEmpty).assertTrue();
    });
    
    // ── buildUIState - 单游戏模式 ─────────────────────────────────────────
    
    it('buildUIState_singleGame_isSingleGameTrue', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"旅行者","server":"cn_gf01","rawJson":""}]}]}]}';
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.isSingleGame).assertTrue();
    });
    
    it('buildUIState_singleGame_hasSingleGameState', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"旅行者","server":"cn_gf01","rawJson":""}]}]}]}';
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.singleGameState !== undefined).assertTrue();
    });
    
    it('buildUIState_singleGame_gameIdCorrect', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"旅行者","server":"cn_gf01","rawJson":""}]}]}]}';
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.singleGameState!.gameId).assertEqual('genshin');
    });
    
    it('buildUIState_singleGame_staminaParsed', 0, () => {
      const rawJson = '{"current_resin":140,"max_resin":200,"resin_recovery_time":"3600"}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"旅行者","server":"cn_gf01","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.singleGameState!.currentStamina).assertEqual(140);
      expect(state.singleGameState!.maxStamina).assertEqual(200);
    });
    
    it('buildUIState_singleGame_recoveryTimeFormatted', 0, () => {
      const rawJson = '{"current_resin":100,"max_resin":200,"resin_recovery_time":"7200"}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"旅行者","server":"cn_gf01","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.singleGameState!.recoveryTime.hours).assertEqual(2);
      expect(state.singleGameState!.recoveryTime.minutes).assertEqual(0);
    });
    
    it('buildUIState_singleGame_fullStatusCorrect', 0, () => {
      const rawJson = '{"current_resin":200,"max_resin":200,"resin_recovery_time":"0"}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"旅行者","server":"cn_gf01","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.singleGameState!.isFull).assertTrue();
    });
    
    it('buildUIState_singleGame_staminaColorTypeCorrect', 0, () => {
      // 140/200 = 0.7，应为 MEDIUM
      const rawJson = '{"current_resin":140,"max_resin":200,"resin_recovery_time":"3600"}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"旅行者","server":"cn_gf01","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.singleGameState!.staminaColorType).assertEqual(StaminaColorType.MEDIUM);
    });
    
    it('buildUIState_singleGame_extraRowsParsed', 0, () => {
      const rawJson = '{"current_resin":140,"max_resin":200,"max_expedition_num":5,"expeditions":[{"status":"Finished"}]}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"旅行者","server":"cn_gf01","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.singleGameState!.extraRows.length).assertLarger(0);
    });
    
    it('buildUIState_singleGame_roleIdWithPrefix', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"123456789","nickname":"旅行者","server":"cn_gf01","rawJson":""}]}]}]}';
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.singleGameState!.roleIdWithPrefix).assertEqual('UID 123456789');
    });
    
    // ── buildUIState - 多游戏模式 ─────────────────────────────────────────
    
    it('buildUIState_multiGame_isSingleGameFalse', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"A","server":"","rawJson":""}]},{"gameId":"starrail","roles":[{"roleId":"role2","nickname":"B","server":"","rawJson":""}]}]}]}';
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.isSingleGame).assertFalse();
    });
    
    it('buildUIState_multiGame_hasMultiGameStates', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"A","server":"","rawJson":""}]},{"gameId":"starrail","roles":[{"roleId":"role2","nickname":"B","server":"","rawJson":""}]}]}]}';
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.multiGameStates !== undefined).assertTrue();
    });
    
    it('buildUIState_multiGame_twoGames', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"A","server":"","rawJson":""}]},{"gameId":"starrail","roles":[{"roleId":"role2","nickname":"B","server":"","rawJson":""}]}]}]}';
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.multiGameStates!.length).assertEqual(2);
    });
    
    it('buildUIState_threeGames_truncatesToTwo', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"A","server":"","rawJson":""}]},{"gameId":"starrail","roles":[{"roleId":"role2","nickname":"B","server":"","rawJson":""}]},{"gameId":"zzz","roles":[{"roleId":"role3","nickname":"C","server":"","rawJson":""}]}]}]}';
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.multiGameStates!.length).assertEqual(2);
    });
    
    it('buildUIState_multiGame_uniqueGameIds', 0, () => {
      const json = '{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"A","server":"","rawJson":""}]},{"gameId":"genshin","roles":[{"roleId":"role2","nickname":"B","server":"","rawJson":""}]},{"gameId":"starrail","roles":[{"roleId":"role3","nickname":"C","server":"","rawJson":""}]}]}]}';
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      // 两个原神角色应合并为一个游戏，再加一个星铁，共 2 个
      expect(state.multiGameStates!.length).assertEqual(2);
      expect(state.multiGameStates![0].gameId).assertEqual('genshin');
      expect(state.multiGameStates![1].gameId).assertEqual('starrail');
    });
    
    it('buildUIState_multiGame_1x2StateCorrect', 0, () => {
      const rawJson1 = '{"current_resin":140,"max_resin":200,"resin_recovery_time":"3600"}';
      const rawJson2 = '{"current_stamina":180,"max_stamina":240,"stamina_recover_time":7200}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"role1","nickname":"A","server":"","rawJson":"${rawJson1.replace(/"/g, '\\"')}"}]},{"gameId":"starrail","roles":[{"roleId":"role2","nickname":"B","server":"","rawJson":"${rawJson2.replace(/"/g, '\\"')}"}]}]}]}`;
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      
      expect(state.multiGameStates![0].gameId).assertEqual('genshin');
      expect(state.multiGameStates![0].currentStamina).assertEqual(140);
      expect(state.multiGameStates![1].gameId).assertEqual('starrail');
      expect(state.multiGameStates![1].currentStamina).assertEqual(180);
    });
    
    // ── buildUIState - 星铁专属 ───────────────────────────────────────────
    
    it('buildUIState_starrail_reserveStaminaParsed', 0, () => {
      const rawJson = '{"current_stamina":180,"max_stamina":240,"current_reserve_stamina":2400}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"starrail","roles":[{"roleId":"role1","nickname":"开拓者","server":"prod_gf_cn","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.singleGameState!.reserveStamina).assertEqual('2400');
    });
    
    // ── buildUIState - 绝区零 ──────────────────────────────────────────────
    
    it('buildUIState_zzz_staminaParsed', 0, () => {
      const rawJson = '{"energy":{"progress":{"current":120,"max":240},"restore":5400}}';
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"zzz","roles":[{"roleId":"role1","nickname":"代理人","server":"prod_gf_cn","rawJson":"${rawJson.replace(/"/g, '\\"')}"}]}]}]}`;
      const parsed = parsePayload(json);
      const state = Widget2x2ViewModel.buildUIState(parsed);
      expect(state.singleGameState!.currentStamina).assertEqual(120);
      expect(state.singleGameState!.maxStamina).assertEqual(240);
    });
  });
}
