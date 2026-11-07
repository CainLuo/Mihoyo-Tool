import { describe, it, expect } from '@ohos/hypium';
import {
  applySavedLevel,
  LevelConfigVM,
  SkillLevelConfigVM,
} from '../main/ets/model/MaterialTargetConfigModels';
import {
  MaterialComputeTargets,
  StarRailSkillSlot,
  ZZZSkillType,
} from '../main/ets/model/MaterialTargetModels';
import { GameId } from 'core';

export default function materialTargetConfigModelsTest() {
  describe('MaterialTargetConfigModels', () => {

    // ─── LevelConfigVM ──────────────────────────────────────────

    it('初始 current / target 为 1，max 为 90', 0, () => {
      const config = new LevelConfigVM();
      expect(config.current).assertEqual(1);
      expect(config.target).assertEqual(1);
      expect(config.max).assertEqual(90);
      expect(config.labelKey).assertEqual('');
    });

    it('setCurrent 超过 target 时自动抬高 target', 0, () => {
      const config = new LevelConfigVM();
      config.setTarget(50);
      config.setCurrent(60);
      expect(config.current).assertEqual(60);
      expect(config.target).assertEqual(60);
    });

    it('setCurrent 低于 target 时不降低 target', 0, () => {
      const config = new LevelConfigVM();
      config.setTarget(80);
      config.setCurrent(20);
      expect(config.current).assertEqual(20);
      expect(config.target).assertEqual(80);
    });

    it('setTarget 不修改 current', 0, () => {
      const config = new LevelConfigVM();
      config.setCurrent(30);
      config.setTarget(70);
      expect(config.current).assertEqual(30);
      expect(config.target).assertEqual(70);
    });

    // ─── applySavedLevel ───────────────────────────────────────

    it('applySavedLevel 按 1 ~ max 截断', 0, () => {
      const config = new LevelConfigVM();
      config.max = 80;
      applySavedLevel(config, -5, 999);
      expect(config.current).assertEqual(1);
      expect(config.target).assertEqual(80);
    });

    it('applySavedLevel 保证 target 不低于 current', 0, () => {
      const config = new LevelConfigVM();
      config.max = 90;
      applySavedLevel(config, 60, 30);
      expect(config.current).assertEqual(60);
      expect(config.target).assertEqual(60);
    });

    it('applySavedLevel 在合法范围内直接采用', 0, () => {
      const config = new LevelConfigVM();
      config.max = 90;
      applySavedLevel(config, 20, 70);
      expect(config.current).assertEqual(20);
      expect(config.target).assertEqual(70);
    });

    it('SkillLevelConfigVM 继承 LevelConfigVM 并带 skillType', 0, () => {
      const config = new SkillLevelConfigVM();
      config.skillType = 3;
      config.setCurrent(5);
      expect(config.skillType).assertEqual(3);
      expect(config.current).assertEqual(5);
    });

    // ─── ZZZSkillType ──────────────────────────────────────────

    it('绝区零核心技最高 7 级，其余 12 级', 0, () => {
      expect(ZZZSkillType.getMaxLevel(ZZZSkillType.CORE)).assertEqual(7);
      expect(ZZZSkillType.getMaxLevel(ZZZSkillType.NORMAL_ATTACK)).assertEqual(12);
      expect(ZZZSkillType.getMaxLevel(ZZZSkillType.SPECIAL)).assertEqual(12);
      expect(ZZZSkillType.getMaxLevel(ZZZSkillType.DODGE)).assertEqual(12);
      expect(ZZZSkillType.getMaxLevel(ZZZSkillType.CHAIN)).assertEqual(12);
      expect(ZZZSkillType.getMaxLevel(ZZZSkillType.ASSIST)).assertEqual(12);
    });

    // ─── MaterialComputeTargets ────────────────────────────────

    it('原神默认目标为 90 / [10,10,10] / 90', 0, () => {
      const targets = MaterialComputeTargets.createDefault(GameId.GENSHIN);
      expect(targets.avatarLevel).assertEqual(90);
      expect(targets.skillLevels.length).assertEqual(3);
      expect(targets.skillLevels[0]).assertEqual(10);
      expect(targets.skillLevels[1]).assertEqual(10);
      expect(targets.skillLevels[2]).assertEqual(10);
      expect(targets.weaponLevel).assertEqual(90);
      expect(targets.zzzSkills.length).assertEqual(0);
    });

    it('星铁默认目标为 80 / 技能上限 / 80', 0, () => {
      const targets = MaterialComputeTargets.createDefault(GameId.STARRAIL);
      expect(targets.avatarLevel).assertEqual(80);
      expect(targets.skillLevels.length).assertEqual(StarRailSkillSlot.COUNT);
      expect(targets.skillLevels[0]).assertEqual(6);
      expect(targets.skillLevels[1]).assertEqual(10);
      expect(targets.skillLevels[2]).assertEqual(10);
      expect(targets.skillLevels[3]).assertEqual(10);
      expect(targets.weaponLevel).assertEqual(80);
    });

    it('绝区零默认目标为 60 / 60，并生成 6 个技能', 0, () => {
      const targets = MaterialComputeTargets.createDefault(GameId.ZZZ);
      expect(targets.avatarLevel).assertEqual(60);
      expect(targets.weaponLevel).assertEqual(60);
      expect(targets.zzzSkills.length).assertEqual(6);
      expect(targets.zzzSkills[4].skillType).assertEqual(ZZZSkillType.CORE);
      expect(targets.zzzSkills[4].target).assertEqual(7);
      expect(targets.zzzSkills[0].target).assertEqual(12);
    });

  });
}
