/**
 * ZZZWeaponCard — 绝区零音擎（武器）卡片
 *
 * 图标 + 名称 + 等级/稀有度 + 天赋名称。
 * 仅在 ZZZCharDetailContent 的音擎 section 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZCharDetailWeapon } from '../../../models/CharDetailModels';

@ComponentV2
export struct ZZZWeaponCard {
  @Param weapon: ZZZCharDetailWeapon = new ZZZCharDetailWeapon();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value10 }) {
      if (this.weapon.iconUrl !== '') {
        Image(this.weapon.iconUrl)
          .width(this.tm.current.value52)
          .height(this.tm.current.value52)
          .objectFit(ImageFit.Contain)
          .borderRadius(this.tm.current.value8)
          .backgroundColor(this.tm.current.surfaceGlass)
      }

      Column({ space: this.tm.current.value4 }) {
        Text(this.weapon.name)
          .fontSize(this.tm.current.body13Bold.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: this.tm.current.value8 }) {
          Text(`Lv.${this.weapon.level}`)
            .fontSize(this.tm.current.body10.size)
            .fontColor(this.tm.current.textOnDarkMuted)

          Text(this.weapon.rarity)
            .fontSize(this.tm.current.body10.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.accentRefine)
            .backgroundColor(this.tm.current.accentRefineBg)
            .borderRadius(this.tm.current.value4)
            .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
        }

        if (this.weapon.talentTitle !== '') {
          Text(this.weapon.talentTitle)
            .fontSize(this.tm.current.body12.size)
            .fontColor(this.tm.current.textOnDarkSecondary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .alignItems(VerticalAlign.Center)
  }
}
