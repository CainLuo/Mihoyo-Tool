/**
 * CharDetailRelicCard — 圣遗物 Phone 卡片（2列网格中的单个卡片）
 *
 * 图标+套装名+强化等级 + 主词条行 + 副词条列表。
 * 仅在 CharDetailRelicsPanel Phone 模式下使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { CharDetailRelic, RelicSubStat } from '../../../models/CharDetailModels';

@ComponentV2
export struct CharDetailRelicCard {
  @Param relic: CharDetailRelic = new CharDetailRelic();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      // 顶部：图标 + 套装名 + 强化等级
      Row({ space: this.tm.current.value4 }) {
        if (this.relic.iconUrl !== '') {
          Image(this.relic.iconUrl)
            .width(this.tm.current.value32)
            .height(this.tm.current.value32)
            .objectFit(ImageFit.Contain)
        }
        Column({ space: this.tm.current.value2 }) {
          Text(this.relic.setName !== '' ? this.relic.setName : (this.relic.mainStatLabel ?? $r('app.string.char_detail_no_data')))
            .fontSize(this.tm.current.font13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.textOnDarkHigh)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.relic.mainStatLabel ?? $r('app.string.char_detail_no_data'))
            .fontSize(this.tm.current.value9)
            .fontColor(this.tm.current.textOnDarkMuted)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text($r('app.string.char_detail_relic_lv_prefix', this.relic.level))
          .fontSize(this.tm.current.value9)
          .fontColor(this.tm.current.textOnDarkGhost)
          .backgroundColor(this.tm.current.surfaceGlass)
          .borderRadius(this.tm.current.value4)
          .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
      }
      .width(this.tm.current.full)
      .alignItems(VerticalAlign.Center)

      // 主词条行
      Row() {
        Text(this.relic.mainStatLabel ?? $r('app.string.char_detail_no_data'))
          .fontSize(this.tm.current.font11)
          .fontColor(this.tm.current.accentPrimaryStrong)
          .layoutWeight(1)
        Text(this.relic.mainStatValue)
          .fontSize(this.tm.current.fontBold14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
      }
      .width(this.tm.current.full)
      .padding({ top: this.tm.current.value2, bottom: this.tm.current.value2 })
      .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })

      // 副词条列表
      Column() {
        ForEach(this.relic.subStats, (sub: RelicSubStat) => {
          Row() {
            Text(sub.label ?? $r('app.string.char_detail_no_data'))
              .fontSize(this.tm.current.font11)
              .fontColor(this.tm.current.textOnDarkGhost)
              .layoutWeight(1)
            Text(sub.value)
              .fontSize(this.tm.current.font11)
              .fontColor(this.tm.current.textOnDarkHigh)
          }
          .width(this.tm.current.full)
          .padding({ top: this.tm.current.value1, bottom: this.tm.current.value1 })
        }, (sub: RelicSubStat, idx: number) => `psub_${this.relic.pos}_${idx}`)
      }
      .width(this.tm.current.full)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value8)
    .backgroundColor(this.tm.current.surfaceGlass)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
    .borderRadius(this.tm.current.radius8)
  }
}
