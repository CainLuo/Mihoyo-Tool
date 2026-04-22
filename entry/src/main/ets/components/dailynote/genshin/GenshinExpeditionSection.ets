/**
 * GenshinExpeditionSection — 原神派遣列表区（标题行 + 派遣条目列表）
 *
 * 仅在 DailyNoteGenshin 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ExpeditionVM } from '../../../models/DailyNoteModels';
import { ExpeditionItem } from '../common/ExpeditionItem';

@ComponentV2
export struct GenshinExpeditionSection {
  @Param expeditions: ExpeditionVM[] = [];
  @Param maxExpeditionNum: number = 5;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      Row() {
        Text($r('app.string.daily_note_expedition_title'))
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextPrimary)

        Text(' (' + this.expeditions.length.toString() +
          '/' + this.maxExpeditionNum.toString() + ')')
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value16,
        right: this.tm.current.value16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value8
      })

      ForEach(this.expeditions, (item: ExpeditionVM) => {
        ExpeditionItem({ expedition: item })
      })

      Row().height(this.tm.current.value8)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }
}
