/**
 * StarRailSkillsSection — 星铁行迹区（主技能/额外能力/属性加成）
 *
 * 仅在 StarRailCharDetailContent 中使用。
 */
import { LengthMetrics } from '@kit.ArkUI';
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailCharacterDetailViewModel } from '../../../viewmodel/StarRailCharacterDetailViewModel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { StarRailSkillNode } from './StarRailSkillNode';
import { StarRailCharDetailSkillNode } from '../../../models/CharDetailModels';

@ComponentV2
export struct StarRailSkillsSection {
  @Param vm: StarRailCharacterDetailViewModel = new StarRailCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.starrail_char_detail_skills_main') })
      Column({ space: this.tm.current.value8 }) {
        if (this.vm.skillsMain.length > 0) {
          Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(this.tm.current.value8), cross: LengthMetrics.vp(this.tm.current.value8) } }) {
            ForEach(this.vm.skillsMain, (skill: StarRailCharDetailSkillNode) => {
              StarRailSkillNode({ skill: skill, iconSize: this.tm.current.value44 })
            }, (skill: StarRailCharDetailSkillNode) => `main_${skill.pointId}`)
          }
          .width(this.tm.current.full)
        }
        if (this.vm.skillsExtra.length > 0) {
          Column({ space: this.tm.current.value4 }) {
            Text($r('app.string.starrail_char_detail_skills_extra'))
              .fontSize(this.tm.current.body12.size)
              .fontColor(this.tm.current.textOnDarkSecondary)
            Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(this.tm.current.value8), cross: LengthMetrics.vp(this.tm.current.value8) } }) {
              ForEach(this.vm.skillsExtra, (skill: StarRailCharDetailSkillNode) => {
                StarRailSkillNode({ skill: skill, iconSize: this.tm.current.value36 })
              }, (skill: StarRailCharDetailSkillNode) => `extra_${skill.pointId}`)
            }
          }
          .width(this.tm.current.full)
          .alignItems(HorizontalAlign.Start)
        }
        if (this.vm.skillsAttr.length > 0) {
          Column({ space: this.tm.current.value4 }) {
            Text($r('app.string.starrail_char_detail_skills_attr'))
              .fontSize(this.tm.current.body12.size)
              .fontColor(this.tm.current.textOnDarkSecondary)
            Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(this.tm.current.value8), cross: LengthMetrics.vp(this.tm.current.value8) } }) {
              ForEach(this.vm.skillsAttr, (skill: StarRailCharDetailSkillNode) => {
                StarRailSkillNode({ skill: skill, iconSize: this.tm.current.value28 })
              }, (skill: StarRailCharDetailSkillNode) => `attr_${skill.pointId}`)
            }
          }
          .width(this.tm.current.full)
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.value12)
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
      .borderRadius(this.tm.current.radius12)
      .alignItems(HorizontalAlign.Start)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
