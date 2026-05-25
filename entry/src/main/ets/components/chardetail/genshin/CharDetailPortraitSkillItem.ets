/**
 * CharDetailPortraitSkillItem — 原神竖屏技能列表单行
 *
 * 图标 + 技能名 + 等级标签，等级颜色由 isHighlight 决定。
 * 仅在 CharDetailPortraitLayout 的技能 section 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { CharDetailSkill } from '../../../models/CharDetailModels';
import { GenshinElement, elementColor } from '../../../constants/GenshinElement';

@ComponentV2
export struct CharDetailPortraitSkillItem {
  @Param skill: CharDetailSkill = new CharDetailSkill();
  @Param skillIndex: number = 0;
  @Param charElement: GenshinElement = GenshinElement.UNKNOWN;
  /** 是否高亮等级（普攻为 false，战技/爆发为 true） */
  @Param isHighlight: boolean = false;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value8 }) {
      if (this.skill.iconUrl !== '') {
        Image(this.skill.iconUrl)
          .width(this.tm.current.value28)
          .height(this.tm.current.value28)
          .objectFit(ImageFit.Contain)
          .borderRadius(this.tm.current.font14)
          .backgroundColor(this.tm.current.surfaceDarkLg)
          .border({ width: this.tm.current.value1p5, color: elementColor(this.charElement) })
          .flexShrink(0)
      }
      Text(this.skill.name !== '' ? this.skill.name : $r('app.string.char_detail_skill_default_name', this.skillIndex + 1))
        .fontSize(this.tm.current.font13)
        .fontColor(this.tm.current.textOnDarkHigh)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(`Lv.${this.skill.level}`)
        .fontSize(this.tm.current.font13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isHighlight ? elementColor(this.charElement) : this.tm.current.textOnDarkSecondary)
        .backgroundColor(this.tm.current.surfaceDarkLg)
        .borderRadius(this.tm.current.value4)
        .padding({ left: this.tm.current.value8, right: this.tm.current.value8, top: this.tm.current.value2, bottom: this.tm.current.value2 })
        .flexShrink(0)
    }
    .width(this.tm.current.full)
    .padding({ top: this.tm.current.value8, bottom: this.tm.current.value8 })
    .alignItems(VerticalAlign.Center)
  }
}
