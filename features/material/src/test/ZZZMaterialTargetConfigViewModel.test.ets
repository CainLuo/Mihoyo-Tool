import { describe, it, expect } from '@ohos/hypium';
import { ZZZMaterialTargetConfigViewModel } from '../main/ets/viewmodel/ZZZMaterialTargetConfigViewModel';
import { SkillLevelConfigVM } from '../main/ets/model/MaterialTargetConfigModels';
import { MaterialTargetConfigParam, ZZZSkillType } from '../main/ets/model/ToolsModels';
import { MaterialComputeResult } from '../main/ets/model/service/MaterialComputeService';
import { GameId } from 'core';

function makeSkill(skillType: number): SkillLevelConfigVM {
  const max = ZZZSkillType.getMaxLevel(skillType);
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
  param.gameId = GameId.ZZZ;
  param.avatarIds = ['1001'];
  return param;
}

export default function zzzMaterialTargetConfigViewModelTest() {
  describe('ZZZMaterialTargetConfigViewModel', () => {

    it('初始 isSyncing 为 false', 0, () => {
      const vm = new ZZZMaterialTargetConfigViewModel();
      expect(vm.isSyncing).assertFalse();
    });

    it('初始 skills 为空，等级配置为默认值', 0, () => {
      const vm = new ZZZMaterialTargetConfigViewModel();
      expect(vm.skills.length).assertEqual(0);
      expect(vm.avatarLevel.current).assertEqual(1);
      expect(vm.avatarLevel.target).assertEqual(1);
      expect(vm.avatarLevel.max).assertEqual(90);
      expect(vm.weaponLevel.max).assertEqual(90);
    });

    it('updateCurrent avatar 超过 target 时自动抬高 target', 0, () => {
      const vm = new ZZZMaterialTargetConfigViewModel();
      vm.avatarLevel.target = 20;
      vm.updateCurrent('avatar', 50);
      expect(vm.avatarLevel.current).assertEqual(50);
      expect(vm.avatarLevel.target).assertEqual(50);
    });

    it('updateTarget avatar 只修改 target', 0, () => {
      const vm = new ZZZMaterialTargetConfigViewModel();
      vm.avatarLevel.current = 10;
      vm.updateTarget('avatar', 60);
      expect(vm.avatarLevel.current).assertEqual(10);
      expect(vm.avatarLevel.target).assertEqual(60);
    });

    it('updateCurrent / updateTarget weapon 正确', 0, () => {
      const vm = new ZZZMaterialTargetConfigViewModel();
      vm.updateCurrent('weapon', 20);
      vm.updateTarget('weapon', 60);
      expect(vm.weaponLevel.current).assertEqual(20);
      expect(vm.weaponLevel.target).assertEqual(60);
    });

    it('updateCurrent skill5 命中核心技', 0, () => {
      const vm = new ZZZMaterialTargetConfigViewModel();
      const normal = makeSkill(ZZZSkillType.NORMAL_ATTACK);
      const core = makeSkill(ZZZSkillType.CORE);
      vm.skills = [normal, core];

      core.setTarget(3);
      vm.updateCurrent('skill5', 5);
      vm.updateTarget('skill0', 9);
      expect(core.current).assertEqual(5);
      expect(core.target).assertEqual(5);
      expect(normal.target).assertEqual(9);
    });

    it('未知 key 不修改任何配置', 0, () => {
      const vm = new ZZZMaterialTargetConfigViewModel();
      vm.avatarLevel.current = 10;
      vm.avatarLevel.target = 20;
      vm.updateCurrent('unknown', 50);
      vm.updateTarget('unknown', 50);
      expect(vm.avatarLevel.current).assertEqual(10);
      expect(vm.avatarLevel.target).assertEqual(20);
    });

    it('isSyncing=true 时 computeSelected 返回 BUSY', 0, async (done: Function) => {
      const vm = new ZZZMaterialTargetConfigViewModel();
      vm.isSyncing = true;
      const result = await vm.computeSelected(makeSelection());
      expect(result).assertEqual(MaterialComputeResult.BUSY);
      expect(vm.isSyncing).assertTrue();
      done();
    });

  });
}
