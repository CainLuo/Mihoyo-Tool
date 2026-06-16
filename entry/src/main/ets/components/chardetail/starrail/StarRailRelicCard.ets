/**
 * StarRailRelicCard — 星铁遗器/饰品卡片
 *
 * 图标+名称+强化等级 + 主词条行 + 副词条列表。
 * 仅在 StarRailCharDetailContent 的遗器 section 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailCharDetailRelic, StarRailRelicSubStat } from '../../../models/CharDetailModels';
import { starRailPropertyTypeToResource } from '../../../utils/StarRailPropertyUtil';

@ComponentV2
export struct StarRailRelicCard {
  @Param relic: StarRailCharDetailRelic = new StarRailCharDetailRelic();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      Row({ space: this.tm.current.value4 }) {
        if (this.relic.iconUrl !== '') {
          Image(this.relic.iconUrl)
            .width(this.tm.current.value32)
            .height(this.tm.current.value32)
            .objectFit(ImageFit.Contain)
        }
        Text(this.relic.name)
          .fontSize(this.tm.current.font13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text(`+${this.relic.level}`)
          .fontSize(this.tm.current.value9)
          .fontColor(this.tm.current.textOnDarkGhost)
          .backgroundColor(this.tm.current.surfaceGlass)
          .borderRadius(this.tm.current.value4)
          .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
      }
      .width(this.tm.current.full)
      .alignItems(VerticalAlign.Center)

      Row() {
        Text(starRailPropertyTypeToResource(this.relic.mainPropertyType) ?? '')
          .fontSize(this.tm.current.font11)
          .fontColor(this.tm.current.accentPrimaryStrong)
          .layoutWeight(1)
        Text(this.relic.mainPropertyValue)
          .fontSize(this.tm.current.fontBold14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
      }
      .width(this.tm.current.full)
      .padding({ top: this.tm.current.value2, bottom: this.tm.current.value2 })
      .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })

      Column() {
        ForEach(this.relic.subStats, (sub: StarRailRelicSubStat) => {
          Row() {
            Text(sub.name)
              .fontSize(this.tm.current.font11)
              .fontColor(this.tm.current.textOnDarkGhost)
              .layoutWeight(1)
            Text(sub.value)
              .fontSize(this.tm.current.font11)
              .fontColor(this.tm.current.textOnDarkHigh)
            if (sub.times > 0) {
              Text(`  ×${sub.times}`)
                .fontSize(this.tm.current.font11)
                .fontColor(this.tm.current.accentRefine)
            }
          }
          .width(this.tm.current.full)
          .padding({ top: this.tm.current.value1, bottom: this.tm.current.value1 })
        }, (_sub: StarRailRelicSubStat, idx: number) => `sub_${idx}`)
      }
      .width(this.tm.current.full)
    }
    .layoutWeight(1)
    .padding(this.tm.current.value8)
    .backgroundColor(this.tm.current.surfaceGlass)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
    .borderRadius(this.tm.current.radius8)
  }
}
