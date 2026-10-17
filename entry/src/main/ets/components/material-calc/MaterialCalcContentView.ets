/**
 * MaterialCalcContentView.ets — 材料计算页内容视图
 *
 * 显示角色信息卡、技能目标设置、材料 Section。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MaterialCalcCharacterVM, SkillTargetVM, MaterialSectionVM, LevelOptionVM } from '../../models/MaterialCalcModels';
import { MaterialCalcCharacter } from './MaterialCalcCharacter';
import { MaterialCalcSkills } from './MaterialCalcSkills';
import { MaterialCalcSection } from './MaterialCalcSection';

@ComponentV2
export struct MaterialCalcContentView {
  @Param character: MaterialCalcCharacterVM = new MaterialCalcCharacterVM();
  @Param skills: SkillTargetVM[] = [];
  @Param avatarSection: MaterialSectionVM = new MaterialSectionVM();
  @Param weaponSection: MaterialSectionVM = new MaterialSectionVM();
  @Param onCharacterLevelTap: () => void = () => {};
  @Param onWeaponLevelTap: () => void = () => {};
  @Param onSkillTap: (skillId: string) => void = (_: string) => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // 角色信息卡
        MaterialCalcCharacter({
          character: this.character,
          onLevelTap: this.onCharacterLevelTap
        })

        // 技能目标设置
        MaterialCalcSkills({
          skills: this.skills,
          onSkillTap: this.onSkillTap
        })

        // 角色材料 Section
        MaterialCalcSection({
          section: this.avatarSection,
          iconName: '👤',
          onWeaponLevelTap: null
        })

        // 武器材料 Section
        if (this.weaponSection.hasData) {
          MaterialCalcSection({
            section: this.weaponSection,
            iconName: '⚔️',
            onWeaponLevelTap: this.onWeaponLevelTap
          })
        }

        // 下拉刷新提示
        Text($r('app.string.material_calc_refresh_hint'))
          .fontSize(this.tm.current.font10)
          .fontColor(this.tm.current.colorTextMuted)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 20, bottom: 20 })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }
}

@Preview
@ComponentV2
export struct MaterialCalcContentViewPreview {
  build() {
    MaterialCalcContentView()
      .backgroundColor('#1a1a2e')
      .height(500)
  }
}
