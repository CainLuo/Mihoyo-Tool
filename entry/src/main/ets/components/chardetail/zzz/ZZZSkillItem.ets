/**
 * ZZZSkillItem — 绝区零技能列表单行（色块 + 技能名 + 等级标签）
 *
 * 仅在 ZZZCharDetailContent 的技能 section 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZCharDetailSkill } from '../../../models/CharDetailModels';

@ComponentV2
export struct ZZZSkillItem {
  @Param skill: ZZZCharDetailSkill = new ZZZCharDetailSkill();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      if (this.skill.items.length > 0) {
        Row({ space: this.tm.current.value8 }) {
          Column()
            .width(this.tm.current.value4)
            .height(this.tm.current.font16)
            .borderRadius(this.tm.current.value2)
            .backgroundColor(this.tm.current.accentPrimaryStrong)

          Text(this.skill.items[0].title)
            .fontSize(this.tm.current.font13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.textOnDarkHigh)
            .layoutWeight(1)

          Text(`Lv.${this.skill.level}`)
            .fontSize(this.tm.current.font13)
            .fontColor(this.tm.current.accentRefine)
            .backgroundColor(this.tm.current.accentRefineBg)
            .borderRadius(this.tm.current.value4)
            .padding({
              left: this.tm.current.value4, right: this.tm.current.value4,
              top: this.tm.current.value1, bottom: this.tm.current.value1
            })
        }
        .width(this.tm.current.full)
        .alignItems(VerticalAlign.Center)
      }
    }
    .width(this.tm.current.full)
  }
}
