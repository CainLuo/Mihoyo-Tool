/**
 * CharDetailRelicRow — 圣遗物宽屏行（左侧图标+主词条，右侧副词条网格）
 *
 * 仅在 CharDetailRelicsPanel 宽屏模式下使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { CharDetailRelic, RelicSubStat } from '../../../models/CharDetailModels';

@ComponentV2
export struct CharDetailRelicRow {
  @Param relic: CharDetailRelic = new CharDetailRelic();
  @Local private tm: ThemeManager = themeManager;

  private starsText(n: number): string {
    let s = '';
    for (let i = 0; i < n; i++) { s += '★'; }
    return s;
  }

  build() {
    Row() {
      // 左侧：图标 + 主词条 + 星级 + 强化等级
      Column({ space: this.tm.current.value2 }) {
        if (this.relic.iconUrl !== '') {
          Image(this.relic.iconUrl)
            .width(this.tm.current.value40)
            .height(this.tm.current.value40)
            .objectFit(ImageFit.Contain)
        } else {
          Column()
            .width(this.tm.current.value40)
            .height(this.tm.current.value40)
            .backgroundColor(this.tm.current.surfaceGlass)
            .borderRadius(this.tm.current.value4)
        }
        Text(this.relic.mainStatLabel ?? $r('app.string.char_detail_no_data'))
          .fontSize(this.tm.current.value9)
          .fontColor(this.tm.current.textOnDarkMuted)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.relic.mainStatValue)
          .fontSize(this.tm.current.body16.size)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .maxLines(1)
        Text(this.starsText(this.relic.rarity))
          .fontSize(this.tm.current.body10.size)
          .fontColor(this.tm.current.accentRefine)
        Text($r('app.string.char_detail_relic_lv_prefix', this.relic.level))
          .fontSize(this.tm.current.value9)
          .fontColor(this.tm.current.textOnDarkFaint)
      }
      .width(this.tm.current.value90)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding({ top: this.tm.current.value4, bottom: this.tm.current.value4 })
      .border({ width: { right: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })

      // 右侧：副词条网格
      Grid() {
        ForEach(this.relic.subStats, (sub: RelicSubStat) => {
          GridItem() {
            Row() {
              Text(sub.label ?? $r('app.string.char_detail_no_data'))
                .fontSize(this.tm.current.body10.size)
                .fontColor(this.tm.current.textOnDarkTertiary)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(sub.value)
                .fontSize(this.tm.current.body12.size)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.tm.current.textOnDarkHigh)
            }
            .width(this.tm.current.full)
            .padding({ left: this.tm.current.value8, right: this.tm.current.value4, top: this.tm.current.value2, bottom: this.tm.current.value2 })
          }
        }, (sub: RelicSubStat, idx: number) => `sub_${this.relic.pos}_${idx}`)
      }
      .columnsTemplate('1fr 1fr')
      .layoutWeight(1)
    }
    .width(this.tm.current.full)
    .layoutWeight(1)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.tm.current.surfaceDarkMd)
    .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })
  }
}
