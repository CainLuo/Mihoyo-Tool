import { describe, it, expect } from '@ohos/hypium';
import { StarRailMaterialTargetConfigViewModel } from '../main/ets/viewmodel/StarRailMaterialTargetConfigViewModel';
import { SkillLevelConfigVM } from '../main/ets/model/MaterialTargetConfigModels';
import { MaterialTargetConfigParam, StarRailSkillSlot } from '../main/ets/model/ToolsModels';
import { MaterialComputeResult } from '../main/ets/model/service/MaterialComputeService';
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
  param.gameId = GameId.STARRAIL;
  param.avatarIds = ['1001'];
  return param;
}

export default function starRailMaterialTargetConfigViewModelTest() {
  describe('StarRailMaterialTargetConfigViewModel', () => {

    it('初始 isSyncing 为 false', 0, () => {
      const vm = new StarRailMaterialTargetConfigViewModel();
      expect(vm.isSyncing).assertFalse();
    });

    it('初始 skills 为空，等级配置为默认值', 0, () => {
      const vm = new StarRailMaterialTargetConfigViewModel();
      expect(vm.skills.length).assertEqual(0);
      expect(vm.avatarLevel.current).assertEqual(1);
      expect(vm.avatarLevel.target).assertEqual(1);
      expect(vm.avatarLevel.max).assertEqual(90);
      expect(vm.lightConeLevel.max).assertEqual(90);
    });

    it('updateCurrent avatar 超过 target 时自动抬高 target', 0, () => {
      const vm = new StarRailMaterialTargetConfigViewModel();
      vm.avatarLevel.target = 20;
      vm.updateCurrent('avatar', 50);
      expect(vm.avatarLevel.current).assertEqual(50);
      expect(vm.avatarLevel.target).assertEqual(50);
    });

    it('updateTarget avatar 只修改 target', 0, () => {
      const vm = new StarRailMaterialTargetConfigViewModel();
      vm.avatarLevel.current = 10;
      vm.updateTarget('avatar', 80);
      expect(vm.avatarLevel.current).assertEqual(10);
      expect(vm.avatarLevel.target).assertEqual(80);
    });

    it('updateCurrent / updateTarget lightCone 正确', 0, () => {
      const vm = new StarRailMaterialTargetConfigViewModel();
      vm.updateCurrent('lightCone', 20);
      vm.updateTarget('lightCone', 80);
      expect(vm.lightConeLevel.current).assertEqual(20);
      expect(vm.lightConeLevel.target).assertEqual(80);
    });

    it('updateCurrent skill{skillType} 命中对应行迹', 0, () => {
      const vm = new StarRailMaterialTargetConfigViewModel();
      const basic = makeSkill(1, StarRailSkillSlot.MAX_LEVELS[0]);
      const skill = makeSkill(2, StarRailSkillSlot.MAX_LEVELS[1]);
      const ultimate = makeSkill(3, StarRailSkillSlot.MAX_LEVELS[2]);
      const talent = makeSkill(4, StarRailSkillSlot.MAX_LEVELS[3]);
      vm.skills = [basic, skill, ultimate, talent];

      basic.setTarget(3);
      vm.updateCurrent('skill1', 5);
      vm.updateTarget('skill3', 9);
      expect(basic.current).assertEqual(5);
      expect(basic.target).assertEqual(5);
      expect(ultimate.target).assertEqual(9);
      expect(talent.target).assertEqual(10);
    });

    it('未知 key 不修改任何配置', 0, () => {
      const vm = new StarRailMaterialTargetConfigViewModel();
      vm.avatarLevel.current = 10;
      vm.avatarLevel.target = 20;
      vm.updateCurrent('unknown', 50);
      vm.updateTarget('unknown', 50);
      expect(vm.avatarLevel.current).assertEqual(10);
      expect(vm.avatarLevel.target).assertEqual(20);
    });

    it('isSyncing=true 时 computeSelected 返回 BUSY', 0, async (done: Function) => {
      const vm = new StarRailMaterialTargetConfigViewModel();
      vm.isSyncing = true;
      const result = await vm.computeSelected(makeSelection());
      expect(result).assertEqual(MaterialComputeResult.BUSY);
      expect(vm.isSyncing).assertTrue();
      done();
    });

  });
}
