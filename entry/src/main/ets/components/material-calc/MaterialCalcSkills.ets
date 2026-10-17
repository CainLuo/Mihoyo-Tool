/**
 * MaterialCalcSkills.ets — 技能目标设置组件
 *
 * 显示三个技能的目标等级设置。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { SkillTargetVM } from '../../models/MaterialCalcModels';

@ComponentV2
export struct MaterialCalcSkills {
  @Param skills: SkillTargetVM[] = [];
  @Param onSkillTap: (skillId: string) => void = (_: string) => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: 10 }) {
      // 标题
      Text($r('app.string.skill_target_title'))
        .fontSize(this.tm.current.font12)
        .fontColor(this.tm.current.colorTextMuted)
        .width('100%')

      // 技能列表
      Row({ space: 8 }) {
        ForEach(this.skills, (skill: SkillTargetVM) => {
          MaterialCalcSkillItem({
            skill: skill,
            onTap: () => {
              this.onSkillTap(skill.skillId);
            }
          })
        }, (skill: SkillTargetVM) => skill.skillId)
      }
      .width('100%')
    }
    .width('100%')
  }
}

/**
 * MaterialCalcSkillItem — 技能目标项
 *
 * 单个技能的目标等级显示，支持点击选择目标等级。
 */
@ComponentV2
struct MaterialCalcSkillItem {
  @Param skill: SkillTargetVM = new SkillTargetVM();
  @Param onTap: () => void = () => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: 4 }) {
      // 技能名称
      Text(this.skill.skillName)
        .fontSize(this.tm.current.font10)
        .fontColor(this.tm.current.colorTextMuted)

      // 等级
      Text(`${this.skill.currentLevel}/${this.skill.targetLevel}`)
        .fontSize(this.tm.current.fontBold16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.skill.isComplete ? this.tm.current.colorSuccess : this.tm.current.colorTextPrimary)

      // 完成标记
      if (this.skill.isComplete) {
        Text('✓')
          .fontSize(this.tm.current.font12)
          .fontColor(this.tm.current.colorSuccess)
      }
    }
    .layoutWeight(1)
    .padding({ top: 10, bottom: 10, left: 8, right: 8 })
    .backgroundColor(this.skill.isComplete ? this.tm.current.colorSuccess + '18' : this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: 1, color: this.skill.isComplete ? this.tm.current.colorSuccess + '44' : this.tm.current.colorDivider })
    .onClick(this.onTap)
  }
}

@Preview
@ComponentV2
export struct MaterialCalcSkillsPreview {
  @Local skills: SkillTargetVM[] = [];

  aboutToAppear(): void {
    this.skills = [
      { skillId: 'normal', skillName: '普攻', currentLevel: 10, targetLevel: 10, maxLevel: 10 } as SkillTargetVM,
      { skillId: 'skill', skillName: '战技', currentLevel: 8, targetLevel: 10, maxLevel: 10 } as SkillTargetVM,
      { skillId: 'burst', skillName: '爆发', currentLevel: 10, targetLevel: 10, maxLevel: 10 } as SkillTargetVM,
    ];
  }

  build() {
    Column() {
      MaterialCalcSkills({
        skills: this.skills,
        onSkillTap: (_: string) => {}
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
