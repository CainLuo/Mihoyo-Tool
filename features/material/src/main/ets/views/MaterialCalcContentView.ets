/**
 * MaterialCalcContentView.ets — 材料计算页内容视图
 *
 * 显示角色信息卡、技能目标等级（只读）与材料 Section；
 * 目标等级的修改统一走养成目标配置页，由 onEditTargets 触发跳转。
 */

import { themeManager, ThemeManager } from 'basic';
import { MaterialCalcCharacterVM, SkillTargetVM, MaterialCalcSectionVM } from '../model/MaterialCalcModels';
import { MaterialCalcCharacter } from './MaterialCalcCharacter';
import { MaterialCalcSkills } from './MaterialCalcSkills';
import { MaterialCalcSection } from './MaterialCalcSection';

@ComponentV2
export struct MaterialCalcContentView {
  @Param character: MaterialCalcCharacterVM = new MaterialCalcCharacterVM();
  @Param skills: SkillTargetVM[] = [];
  @Param avatarSection: MaterialCalcSectionVM = new MaterialCalcSectionVM();
  @Param weaponSection: MaterialCalcSectionVM = new MaterialCalcSectionVM();
  @Param onEditTargets: () => void = () => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // 角色信息卡
        MaterialCalcCharacter({
          character: this.character
        })

        // 技能目标等级（只读）
        MaterialCalcSkills({
          skills: this.skills
        })

        // 角色材料 Section
        if (this.avatarSection.hasData) {
          MaterialCalcSection({
            section: this.avatarSection,
            iconName: '👤'
          })
        }

        // 武器材料 Section
        if (this.weaponSection.hasData) {
          MaterialCalcSection({
            section: this.weaponSection,
            iconName: '⚔️'
          })
        }

        // 该角色还没有计算结果（例如未加入养成目标配置）
        if (!this.avatarSection.hasData && !this.weaponSection.hasData) {
          Text($r('app.string.material_calc_no_compute_hint'))
            .fontSize(this.tm.current.font12)
            .fontColor(this.tm.current.colorTextSecondary)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 24, bottom: 8 })
        }

        // 调整养成目标入口
        Button($r('app.string.material_calc_edit_targets'))
          .id('material_calc_edit_targets')
          .type(ButtonType.Normal)
          .width('100%')
          .height(44)
          .backgroundColor(this.tm.current.surfaceActivePrimary)
          .fontColor(this.tm.current.colorPrimary)
          .fontSize(this.tm.current.font14)
          .borderRadius(this.tm.current.radius8)
          .onClick(() => { this.onEditTargets() })
      }
      .width('100%')
      .padding(16)
    }
    .id('material_calc_content')
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
