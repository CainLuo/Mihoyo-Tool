/**
 * ZZZEquipCardHeader — 绝区零驱动盘卡片头部（图标 + 套装名 + 强化等级）
 *
 * 仅在 ZZZEquipCard 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZCharDetailEquip } from '../../../models/CharDetailModels';

@ComponentV2
export struct ZZZEquipCardHeader {
  @Param equip: ZZZCharDetailEquip = new ZZZCharDetailEquip();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value4 }) {
      if (this.equip.iconUrl !== '') {
        Image(this.equip.iconUrl)
          .width(this.tm.current.value32)
          .height(this.tm.current.value32)
          .objectFit(ImageFit.Contain)
      }

      Text(this.equip.suitName)
        .fontSize(this.tm.current.body12.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.textOnDarkHigh)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      Text(`+${this.equip.level}`)
        .fontSize(this.tm.current.value9)
        .fontColor(this.tm.current.textOnDarkGhost)
        .backgroundColor(this.tm.current.surfaceGlass)
        .borderRadius(this.tm.current.value4)
        .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
    }
    .width(this.tm.current.full)
    .alignItems(VerticalAlign.Center)
  }
}
