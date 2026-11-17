import { describe, it, expect } from '@ohos/hypium';
import { Widget1x2ViewModel } from '../main/ets/widget/viewmodel/Widget1x2ViewModel';
import { StaminaColorType, parsePayload } from 'widgetbase';

function escaped(rawJson: string): string {
  return rawJson.replace(/"/g, '\\"');
}

function payload(rawJson: string, gameId: string, roleId: string): string {
  const raw = escaped(rawJson);
  return `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"${gameId}","roles":[{"roleId":"${roleId}","nickname":"角色","server":"cn_gf01","rawJson":"${raw}"}]}]}]}`;
}

export default function widget1x2ViewModelTest() {
  describe('Widget1x2ViewModel', () => {

    it('空 payload 时 isEmpty 为 true', 0, () => {
      const state = Widget1x2ViewModel.buildUIState(parsePayload(''), 'genshin');
      expect(state.isEmpty).assertTrue();
    });

    it('过滤不到指定游戏时 isEmpty 为 true', 0, () => {
      const json = payload('{}', 'starrail', 'role1');
      const state = Widget1x2ViewModel.buildUIState(parsePayload(json), 'genshin');
      expect(state.isEmpty).assertTrue();
    });

    it('gameIdFilter 为空时取第一个角色', 0, () => {
      const json = payload('{}', 'starrail', 'role1');
      const state = Widget1x2ViewModel.buildUIState(parsePayload(json), '');
      expect(state.isEmpty).assertFalse();
      expect(state.role.gameId).assertEqual('starrail');
    });

    it('命中游戏时构建角色字段', 0, () => {
      const raw = '{"current_resin":140,"max_resin":200,"resin_recovery_time":"3600"}';
      const state = Widget1x2ViewModel.buildUIState(parsePayload(payload(raw, 'genshin', '123456789')), 'genshin');
      expect(state.isEmpty).assertFalse();
      expect(state.role.gameId).assertEqual('genshin');
      expect(state.role.accountUid).assertEqual('123456789');
      expect(state.role.currentStamina).assertEqual(140);
      expect(state.role.maxStamina).assertEqual(200);
      expect(state.role.recoverySeconds).assertEqual(3600);
      expect(state.role.isFull).assertFalse();
      expect(state.role.ratio).assertEqual(0.7);
      expect(state.role.staminaColorType).assertEqual(StaminaColorType.MEDIUM);
      expect(state.role.recoveryTime.hours).assertEqual(1);
      expect(state.role.recoveryTime.minutes).assertEqual(0);
    });

    it('满体力时 isFull 为 true', 0, () => {
      const raw = '{"current_resin":200,"max_resin":200,"resin_recovery_time":"0"}';
      const state = Widget1x2ViewModel.buildUIState(parsePayload(payload(raw, 'genshin', '1')), 'genshin');
      expect(state.role.isFull).assertTrue();
      expect(state.role.ratio).assertEqual(1);
      expect(state.role.staminaColorType).assertEqual(StaminaColorType.HIGH);
    });

    it('多游戏 payload 只返回过滤后的角色', 0, () => {
      const rawGenshin = escaped('{"current_resin":100,"max_resin":200}');
      const rawStarRail = escaped('{"current_stamina":180,"max_stamina":240}');
      const json = `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"genshin","roles":[{"roleId":"g1","nickname":"原神","server":"","rawJson":"${rawGenshin}"}]},{"gameId":"starrail","roles":[{"roleId":"s1","nickname":"星铁","server":"","rawJson":"${rawStarRail}"}]}]}]}`;
      const state = Widget1x2ViewModel.buildUIState(parsePayload(json), 'starrail');
      expect(state.isEmpty).assertFalse();
      expect(state.role.gameId).assertEqual('starrail');
      expect(state.role.accountUid).assertEqual('s1');
    });

  });
}
