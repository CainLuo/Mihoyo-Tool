import { describe, it, expect } from '@ohos/hypium';
import { GenshinMaterialTargetConfigViewModel } from '../main/ets/viewmodel/GenshinMaterialTargetConfigViewModel';
import { SkillLevelConfigVM } from '../main/ets/model/MaterialTargetConfigModels';
import { GenshinTalentSlot, MaterialTargetConfigParam } from '../main/ets/model/ToolsModels';
import { MaterialComputeResult } from '../main/ets/model/MaterialComputeResult';
import { GameId } from 'core';

function makeSkill(skillType: number, max: number): SkillLevelConfigVM {
  const skill = new SkillLevelConfigVM();
  skill.skillType = skillType;
  skill.current = 1;
  skill.target = max;
  skill.max = max;
  return skill;
}

function makeSelection(): MaterialTargetConfigParam {
  const param = new MaterialTargetConfigParam();
  param.accountId = 'account';
  param.roleUid = 'role';
  param.gameId = GameId.GENSHIN;
  param.avatarIds = ['1001'];
  return param;
}

export default function genshinMaterialTargetConfigViewModelTest() {
  describe('GenshinMaterialTargetConfigViewModel', () => {

    it('初始 isSyncing 为 false', 0, () => {
      const vm = new GenshinMaterialTargetConfigViewModel();
      expect(vm.isSyncing).assertFalse();
    });

    it('初始 skills 为空，等级配置为默认值', 0, () => {
      const vm = new GenshinMaterialTargetConfigViewModel();
      expect(vm.skills.length).assertEqual(0);
      expect(vm.avatarLevel.current).assertEqual(1);
      expect(vm.avatarLevel.target).assertEqual(1);
      expect(vm.avatarLevel.max).assertEqual(90);
      expect(vm.weaponLevel.max).assertEqual(90);
    });

    it('updateCurrent avatar 超过 target 时自动抬高 target', 0, () => {
      const vm = new GenshinMaterialTargetConfigViewModel();
      vm.avatarLevel.target = 20;
      vm.updateCurrent('avatar', 50);
      expect(vm.avatarLevel.current).assertEqual(50);
      expect(vm.avatarLevel.target).assertEqual(50);
    });

    it('updateTarget avatar 只修改 target', 0, () => {
      const vm = new GenshinMaterialTargetConfigViewModel();
      vm.avatarLevel.current = 10;
      vm.updateTarget('avatar', 80);
      expect(vm.avatarLevel.current).assertEqual(10);
      expect(vm.avatarLevel.target).assertEqual(80);
    });

    it('updateCurrent / updateTarget weapon 正确', 0, () => {
      const vm = new GenshinMaterialTargetConfigViewModel();
      vm.updateCurrent('weapon', 20);
      vm.updateTarget('weapon', 90);
      expect(vm.weaponLevel.current).assertEqual(20);
      expect(vm.weaponLevel.target).assertEqual(90);
    });

    it('updateCurrent skill{skillType} 命中对应天赋', 0, () => {
      const vm = new GenshinMaterialTargetConfigViewModel();
      const normal = makeSkill(GenshinTalentSlot.NORMAL_ATTACK, 10);
      const skill = makeSkill(GenshinTalentSlot.ELEMENTAL_SKILL, 10);
      const burst = makeSkill(GenshinTalentSlot.ELEMENTAL_BURST, 10);
      vm.skills = [normal, skill, burst];

      normal.setTarget(5);
      vm.updateCurrent('skill0', 8);
      vm.updateTarget('skill1', 9);
      expect(normal.current).assertEqual(8);
      expect(normal.target).assertEqual(8);
      expect(skill.target).assertEqual(9);
      expect(burst.target).assertEqual(10);
    });

    it('未知 key 不修改任何配置', 0, () => {
      const vm = new GenshinMaterialTargetConfigViewModel();
      vm.avatarLevel.current = 10;
      vm.avatarLevel.target = 20;
      vm.updateCurrent('unknown', 50);
      vm.updateTarget('unknown', 50);
      expect(vm.avatarLevel.current).assertEqual(10);
      expect(vm.avatarLevel.target).assertEqual(20);
    });

    it('isSyncing=true 时 computeSelected 返回 BUSY', 0, async (done: Function) => {
      const vm = new GenshinMaterialTargetConfigViewModel();
      vm.isSyncing = true;
      const result = await vm.computeSelected(makeSelection());
      expect(result).assertEqual(MaterialComputeResult.BUSY);
      expect(vm.isSyncing).assertTrue();
      done();
    });

  });
}
