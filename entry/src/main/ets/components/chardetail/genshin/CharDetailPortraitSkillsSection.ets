/**
 * CharDetailPortraitSkillsSection — 技能区 Section
 *
 * Phone 竖屏布局的技能区块，包含标题和技能列表。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { CharDetailPortraitSkillItem } from './CharDetailPortraitSkillItem';
import { CharDetailSkill } from '../../../models/CharDetailModels';

@ComponentV2
export struct CharDetailPortraitSkillsSection {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.char_detail_section_skills') })

      Column() {
        ForEach(this.vm.skills, (skill: CharDetailSkill, idx: number) => {
          CharDetailPortraitSkillItem({
            skill: skill,
            skillIndex: idx,
            charElement: this.vm.charElement,
            isHighlight: idx > 0
          })
        }, (_skill: CharDetailSkill, idx: number) => `skill_${idx}`)
      }
      .width(this.tm.current.full)
      .padding({ left: this.tm.current.value12, right: this.tm.current.value12 })
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
      .borderRadius(this.tm.current.radius12)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
