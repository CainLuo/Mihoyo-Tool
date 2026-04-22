/**
 * ZZZSuitSummaryRow — 绝区零驱动盘套装摘要单行
 *
 * 套装名 + 2件/4件激活标签 + 件数统计。
 * 仅在 ZZZCharDetailContent 的驱动盘 section 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZSuitSummary } from '../../../models/CharDetailModels';

@ComponentV2
export struct ZZZSuitSummaryRow {
  @Param suit: ZZZSuitSummary = new ZZZSuitSummary();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value8 }) {
      Text(this.suit.suitName)
        .fontSize(this.tm.current.body13Bold.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.textOnDarkHigh)
        .layoutWeight(1)

      Text($r('app.string.zzz_char_detail_suit_pieces', 2))
        .fontSize(this.tm.current.body10.size)
        .fontColor(this.suit.count >= 2 ? this.tm.current.accentRefine : this.tm.current.textOnDarkMuted)
        .backgroundColor(this.suit.count >= 2 ? this.tm.current.accentRefineBg : this.tm.current.surfaceDarkLg)
        .border({ width: this.tm.current.value1, color: this.suit.count >= 2 ? this.tm.current.accentRefine : this.tm.current.surfaceInactiveBorder })
        .borderRadius(this.tm.current.value4)
        .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })

      if (this.suit.suitOwn >= 4) {
        Text($r('app.string.zzz_char_detail_suit_pieces', 4))
          .fontSize(this.tm.current.body10.size)
          .fontColor(this.suit.count >= 4 ? this.tm.current.accentRefine : this.tm.current.textOnDarkMuted)
          .backgroundColor(this.suit.count >= 4 ? this.tm.current.accentRefineBg : this.tm.current.surfaceDarkLg)
          .border({ width: this.tm.current.value1, color: this.suit.count >= 4 ? this.tm.current.accentRefine : this.tm.current.surfaceInactiveBorder })
          .borderRadius(this.tm.current.value4)
          .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
      }
      Text(`${this.suit.count}/${this.suit.suitOwn}`)
        .fontSize(this.tm.current.body13Bold.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.accentRefine)
    }
    .width(this.tm.current.full)
    .padding({ left: this.tm.current.value12, right: this.tm.current.value12, top: this.tm.current.value8, bottom: this.tm.current.value8 })
  }
}
