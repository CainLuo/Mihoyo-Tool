/**
 * CharDetailSkillItem — 技能图标+等级单项（宽屏纵列和横屏横行通用）
 *
 * 宽屏用较大图标（value40），横屏用较小图标（value34）。
 * 通过 iconSize 参数区分，默认宽屏尺寸。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { CharDetailSkill } from '../../../models/CharDetailModels';
import { GenshinElement, elementColor } from '../../../constants/GenshinElement';

@ComponentV2
export struct CharDetailSkillItem {
  @Param skill: CharDetailSkill = new CharDetailSkill();
  @Param charElement: GenshinElement = GenshinElement.UNKNOWN;
  /** 图标尺寸：宽屏用 value40，横屏用 value34 */
  @Param iconSize: number = 40;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value2 }) {
      if (this.skill.iconUrl !== '') {
        Image(this.skill.iconUrl)
          .width(this.iconSize)
          .height(this.iconSize)
          .objectFit(ImageFit.Contain)
          .borderRadius(this.iconSize / 2)
          .backgroundColor('#99000000')
          .border({ width: this.tm.current.value1p5, color: '#1AFFFFFF' })
      }
      Text(`${this.skill.level}`)
        .fontSize(this.tm.current.font13)
        .fontWeight(FontWeight.Bold)
        .fontColor(elementColor(this.charElement))
    }
    .alignItems(HorizontalAlign.Center)
  }
}
