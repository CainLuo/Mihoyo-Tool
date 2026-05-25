/**
 * StarRailSkillNode — 星铁行迹单个技能节点（图标+激活状态+等级+类型标签）
 *
 * iconSize 决定节点大小：主技能 value44，额外能力 value36，属性加成 value28。
 * 仅在 StarRailCharDetailContent 的行迹 section 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailCharDetailSkillNode } from '../../../models/CharDetailModels';

@ComponentV2
export struct StarRailSkillNode {
  @Param skill: StarRailCharDetailSkillNode = new StarRailCharDetailSkillNode();
  @Param iconSize: number = 44;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      if (this.skill.iconUrl !== '') {
        Stack() {
          Image(this.skill.iconUrl)
            .width(this.iconSize)
            .height(this.iconSize)
            .objectFit(ImageFit.Contain)
            .borderRadius(this.iconSize / 2)
            .backgroundColor(this.skill.isActivated ? this.tm.current.surfaceActivePrimary : this.tm.current.surfaceDarkLg)
            .border({ width: this.tm.current.value1p5, color: this.skill.isActivated ? this.tm.current.surfaceActiveBorder : this.tm.current.surfaceInactiveBorder })
            .opacity(this.skill.isActivated ? 1.0 : this.tm.current.charDetailConsInactiveOpacity)
          if (!this.skill.isActivated) {
            SymbolGlyph($r('sys.symbol.lock'))
              .fontSize(this.iconSize * this.tm.current.charDetailLockIconRatio)
              .fontColor([this.tm.current.textLockIcon])
          }
        }
        .width(this.iconSize)
        .height(this.iconSize)
      }
      if (this.iconSize >= this.tm.current.value36) {
        Text(`${this.skill.level}`)
          .fontSize(this.tm.current.font13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.skill.isActivated ? this.tm.current.accentRefine : this.tm.current.textOnDarkMuted)
        if (this.skill.remake !== '') {
          Text(this.skill.remake)
            .fontSize(this.tm.current.font11)
            .fontColor(this.tm.current.textOnDarkMuted)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
    }
    .width(this.iconSize + this.tm.current.value12)
    .alignItems(HorizontalAlign.Center)
  }
}
