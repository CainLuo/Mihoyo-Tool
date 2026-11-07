import { describe, it, expect } from '@ohos/hypium';
import { Widget2x4ViewModel } from '../main/ets/widget/viewmodel/Widget2x4ViewModel';
import { parsePayload } from 'widgetbase';

function escaped(rawJson: string): string {
  return rawJson.replace(/"/g, '\\"');
}

function singlePayload(rawJson: string, gameId: string, roleId: string): string {
  const raw = escaped(rawJson);
  return `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[{"gameId":"${gameId}","roles":[{"roleId":"${roleId}","nickname":"角色名","server":"cn_gf01","rawJson":"${raw}"}]}]}]}`;
}

function multiPayload(): string {
  const rawGenshin = escaped('{"current_resin":140,"max_resin":200,"resin_recovery_time":"3600"}');
  const rawStarRail = escaped('{"current_stamina":180,"max_stamina":240,"current_reserve_stamina":2400}');
  const rawZZZ = escaped('{"energy":{"progress":{"current":120,"max":240},"restore":5400}}');
  return `{"version":1,"updatedAt":0,"accounts":[{"accountId":"acc1","accountName":"Test","games":[` +
    `{"gameId":"genshin","roles":[{"roleId":"g1","nickname":"原神","server":"","rawJson":"${rawGenshin}"}]},` +
    `{"gameId":"starrail","roles":[{"roleId":"s1","nickname":"星铁","server":"","rawJson":"${rawStarRail}"}]},` +
    `{"gameId":"zzz","roles":[{"roleId":"z1","nickname":"绝区零","server":"","rawJson":"${rawZZZ}"}]}` +
    `]}]}`;
}

export default function widget2x4ViewModelTest() {
  describe('Widget2x4ViewModel', () => {

    it('空 payload 时 isEmpty 为 true', 0, () => {
      const state = Widget2x4ViewModel.buildUIState(parsePayload(''));
      expect(state.isEmpty).assertTrue();
    });

    it('单游戏模式构建详细状态', 0, () => {
      const raw = '{"current_resin":140,"max_resin":200,"resin_recovery_time":"3600"}';
      const state = Widget2x4ViewModel.buildUIState(parsePayload(singlePayload(raw, 'genshin', '123456789')));
      expect(state.isEmpty).assertFalse();
      expect(state.isSingleGame).assertTrue();
      expect(state.singleGameState.gameId).assertEqual('genshin');
      expect(state.singleGameState.roleId).assertEqual('123456789');
      expect(state.singleGameState.roleIdWithPrefix).assertEqual('UID 123456789');
      expect(state.singleGameState.roleName).assertEqual('角色名');
      expect(state.singleGameState.currentStamina).assertEqual(140);
      expect(state.singleGameState.maxStamina).assertEqual(200);
      expect(state.singleGameState.isFull).assertFalse();
      expect(state.singleGameState.recoveryTime.hours).assertEqual(1);
    });

    it('单游戏满体力时 isFull 为 true', 0, () => {
      const raw = '{"current_resin":200,"max_resin":200,"resin_recovery_time":"0"}';
      const state = Widget2x4ViewModel.buildUIState(parsePayload(singlePayload(raw, 'genshin', '1')));
      expect(state.singleGameState.isFull).assertTrue();
    });

    it('星铁单游戏解析后备开拓力', 0, () => {
      const raw = '{"current_stamina":180,"max_stamina":240,"current_reserve_stamina":2400}';
      const state = Widget2x4ViewModel.buildUIState(parsePayload(singlePayload(raw, 'starrail', '1')));
      expect(state.singleGameState.reserveStamina).assertEqual('2400');
    });

    it('多游戏模式每个游戏只取第一个角色，最多 2 个', 0, () => {
      const state = Widget2x4ViewModel.buildUIState(parsePayload(multiPayload()));
      expect(state.isEmpty).assertFalse();
      expect(state.isSingleGame).assertFalse();
      expect(state.multiGameStates.length).assertEqual(2);
      expect(state.multiGameStates[0].gameId).assertEqual('genshin');
      expect(state.multiGameStates[1].gameId).assertEqual('starrail');
    });

    it('多游戏模式包含星铁后备开拓力', 0, () => {
      const state = Widget2x4ViewModel.buildUIState(parsePayload(multiPayload()));
      expect(state.multiGameStates[1].reserveStamina).assertEqual('2400');
    });

  });
}
