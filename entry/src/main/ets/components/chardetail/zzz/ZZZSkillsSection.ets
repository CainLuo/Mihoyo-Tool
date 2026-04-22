/**
 * ZZZSkillsSection — 绝区零技能区
 *
 * 仅在 ZZZCharDetailContent 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZCharacterDetailViewModel } from '../../../viewmodel/ZZZCharacterDetailViewModel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { ZZZSkillItem } from './ZZZSkillItem';
import { ZZZCharDetailSkill } from '../../../models/CharDetailModels';

@ComponentV2
export struct ZZZSkillsSection {
  @Param vm: ZZZCharacterDetailViewModel = new ZZZCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.zzz_char_detail_skills_title') })
      Column() {
        ForEach(this.vm.skills, (skill: ZZZCharDetailSkill, idx: number) => {
          ZZZSkillItem({ skill: skill })
            .width(this.tm.current.full)
            .border({ width: { bottom: idx < this.vm.skills.length - 1 ? this.tm.current.value1 : 0 }, color: this.tm.current.surfaceGlass })
            .padding({ top: this.tm.current.value8, bottom: this.tm.current.value8 })
        }, (skill: ZZZCharDetailSkill, idx: number) => `skill_${idx}`)
      }
      .width(this.tm.current.full)
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
      .borderRadius(this.tm.current.radius12)
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
