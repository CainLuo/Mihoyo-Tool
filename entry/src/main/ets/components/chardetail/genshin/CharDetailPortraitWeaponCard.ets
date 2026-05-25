/**
 * CharDetailPortraitWeaponCard — 原神竖屏武器卡片
 *
 * 图标 + 名称/等级/精炼/星级 + 基础攻击力/副词条（金色行）。
 * 仅在 CharDetailPortraitLayout 的武器 section 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { CharDetailWeapon } from '../../../models/CharDetailModels';

@ComponentV2
export struct CharDetailPortraitWeaponCard {
  @Param weapon: CharDetailWeapon = new CharDetailWeapon();
  @Local private tm: ThemeManager = themeManager;

  private starsText(n: number): string {
    let s = '';
    for (let i = 0; i < n; i++) { s += '★'; }
    return s;
  }

  build() {
    Row({ space: this.tm.current.value10 }) {
      if (this.weapon.iconUrl !== '') {
        Image(this.weapon.iconUrl)
          .width(this.tm.current.value52)
          .height(this.tm.current.value52)
          .objectFit(ImageFit.Contain)
          .borderRadius(this.tm.current.value8)
          .backgroundColor(this.tm.current.surfaceGlass)
          .flexShrink(0)
      }
      Column({ space: this.tm.current.value4 }) {
        Text(this.weapon.name)
          .fontSize(this.tm.current.fontBold14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: this.tm.current.value8 }) {
          Text(`Lv.${this.weapon.level}`)
            .fontSize(this.tm.current.font11)
            .fontColor(this.tm.current.textOnDarkMuted)
          Text($r('app.string.char_detail_weapon_refine_prefix', this.weapon.affix))
            .fontSize(this.tm.current.font11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.accentRefine)
            .backgroundColor(this.tm.current.accentRefineBg)
            .borderRadius(this.tm.current.value4)
            .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
          Text(this.starsText(this.weapon.rarity))
            .fontSize(this.tm.current.font11)
            .fontColor(this.tm.current.accentRefine)
        }
        if (this.weapon.baseAtk > 0 || this.weapon.subLabel !== null) {
          Row({ space: this.tm.current.value2 }) {
            if (this.weapon.baseAtk > 0) {
              Text($r('app.string.char_detail_weapon_atk'))
                .fontSize(this.tm.current.font11)
                .fontColor(this.tm.current.accentRefine)
              Text(`${this.weapon.baseAtk}`)
                .fontSize(this.tm.current.font11)
                .fontColor(this.tm.current.accentRefine)
            }
            if (this.weapon.subLabel !== null) {
              Text($r('app.string.common_dot_separator'))
                .fontSize(this.tm.current.font11)
                .fontColor(this.tm.current.accentRefine)
              Text(this.weapon.subLabel)
                .fontSize(this.tm.current.font11)
                .fontColor(this.tm.current.accentRefine)
              Text(this.weapon.subVal)
                .fontSize(this.tm.current.font11)
                .fontColor(this.tm.current.accentRefine)
            }
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .backgroundColor(this.tm.current.surfaceDarkLg)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
    .borderRadius(this.tm.current.radius12)
    .alignItems(VerticalAlign.Center)
  }
}
