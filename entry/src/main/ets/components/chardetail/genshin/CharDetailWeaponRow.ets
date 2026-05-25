/**
 * CharDetailWeaponRow — 原神武器行（Phone 紧凑样式）
 *
 * 小图标 + 名称/等级/精炼/副词条 + 右侧基础攻击力。
 * 仅在 CharDetailStatsPanel Phone 模式下使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { CharDetailWeapon } from '../../../models/CharDetailModels';
import { GenshinElement, elementColor } from '../../../constants/GenshinElement';

@ComponentV2
export struct CharDetailWeaponRow {
  @Param weapon: CharDetailWeapon = new CharDetailWeapon();
  @Param charElement: GenshinElement = GenshinElement.UNKNOWN;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value8 }) {
      if (this.weapon.iconUrl !== '') {
        Image(this.weapon.iconUrl)
          .width(this.tm.current.value36)
          .height(this.tm.current.value36)
          .objectFit(ImageFit.Contain)
          .borderRadius(this.tm.current.value8)
          .backgroundColor(this.tm.current.surfaceGlass)
      }
      Column({ space: this.tm.current.value2 }) {
        Text(this.weapon.name)
          .fontSize(this.tm.current.font14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: this.tm.current.value4 }) {
          Text(`Lv.${this.weapon.level}`)
            .fontSize(this.tm.current.font11)
            .fontColor(this.tm.current.textOnDarkGhost)
          Text($r('app.string.char_detail_weapon_refine_prefix', this.weapon.affix))
            .fontSize(this.tm.current.font11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.accentRefine)
            .backgroundColor(this.tm.current.accentRefineBg)
            .borderRadius(this.tm.current.value4)
            .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
          if (this.weapon.subLabel !== null) {
            Text(this.weapon.subLabel)
              .fontSize(this.tm.current.font11)
              .fontColor(this.tm.current.textOnDarkMuted)
            Text(this.weapon.subVal)
              .fontSize(this.tm.current.font11)
              .fontColor(elementColor(this.charElement))
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.weapon.baseAtk > 0) {
        Text(`${this.weapon.baseAtk}`)
          .fontSize(this.tm.current.fontBold14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .flexShrink(0)
      }
    }
    .width(this.tm.current.full)
    .padding({ top: this.tm.current.value8, bottom: this.tm.current.value8 })
    .backgroundColor(this.tm.current.surfaceDarkSm)
    .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })
  }
}
