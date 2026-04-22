/**
 * StarRailEquipCard — 星铁光锥卡片
 *
 * 图标 + 名称 + 等级/叠影行。
 * 仅在 StarRailCharDetailContent 的光锥 section 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailCharDetailEquip } from '../../../models/CharDetailModels';

@ComponentV2
export struct StarRailEquipCard {
  @Param equip: StarRailCharDetailEquip = new StarRailCharDetailEquip();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value10 }) {
      if (this.equip.iconUrl !== '') {
        Image(this.equip.iconUrl)
          .width(this.tm.current.value52)
          .height(this.tm.current.value52)
          .objectFit(ImageFit.Contain)
          .borderRadius(this.tm.current.value8)
          .backgroundColor(this.tm.current.surfaceGlass)
      }
      Column({ space: this.tm.current.value4 }) {
        Text(this.equip.name)
          .fontSize(this.tm.current.body13Bold.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: this.tm.current.value8 }) {
          Text(`Lv.${this.equip.level}`)
            .fontSize(this.tm.current.body10.size)
            .fontColor(this.tm.current.textOnDarkMuted)

          Text(`S${this.equip.rank}`)
            .fontSize(this.tm.current.body10.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.accentRefine)
            .backgroundColor(this.tm.current.accentRefineBg)
            .borderRadius(this.tm.current.value4)
            .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
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
