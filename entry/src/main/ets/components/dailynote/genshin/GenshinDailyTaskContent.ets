/**
 * GenshinDailyTaskContent — 原神每日委托内容区（勾选格子 + 领取状态）
 *
 * 仅在 DailyNoteGenshin 的 DailyNoteCard customBottom 插槽中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ThemeFonts } from '../../../theme/ThemeFonts'
import { GenshinDailyTaskVM } from '../../../models/DailyNoteModels';

@ComponentV2
export struct GenshinDailyTaskContent {
  @Param task: GenshinDailyTaskVM = new GenshinDailyTaskVM(0, 0, false, 0);
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      Row({ space: this.tm.current.value8 }) {
        Text($r('app.string.daily_note_task_label'))
          .font(ThemeFonts.font14)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.value56)

        ForEach([0, 1, 2, 3] as number[], (i: number) => {
          Text(i < this.task.finishedNum ? '✓' : '◇')
            .font(ThemeFonts.font14)
            .fontColor(i < this.task.finishedNum
              ? this.tm.current.colorPrimary : this.tm.current.colorPlaceholder)
        })

        Blank()

        Text(this.task.isExtraTaskRewardReceived
          ? $r('app.string.daily_note_task_all_received')
          : $r('app.string.daily_note_task_not_received'))
          .font(ThemeFonts.font14)
          .fontColor(this.task.isExtraTaskRewardReceived
            ? this.tm.current.colorTextSecondary : this.tm.current.colorPrimary)
      }
      .width(this.tm.current.full)

      Row({ space: this.tm.current.value8 }) {
        Text($r('app.string.daily_note_adventure_label'))
          .font(ThemeFonts.font14)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.value56)

        ForEach([0, 1, 2, 3] as number[], (i: number) => {
          Text(i < this.task.finishedNum ? '✓' : '◇')
            .font(ThemeFonts.font14)
            .fontColor(i < this.task.finishedNum
              ? this.tm.current.colorPrimary : this.tm.current.colorPlaceholder)
        })
      }
      .width(this.tm.current.full)

      if (this.task.storedAdventure >= 0) {
        Row({ space: this.tm.current.value4 }) {
          Text($r('app.string.daily_note_stored_adventure_label'))
            .font(ThemeFonts.font14)
            .fontColor(this.tm.current.colorTextSecondary)

          Text('×' + this.task.storedAdventure.toString())
            .font(ThemeFonts.fontMedium17)
            .fontColor(this.tm.current.colorPrimary)
        }
        .width(this.tm.current.full)
        .margin({ top: this.tm.current.value2 })
      }
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.font16,
      right: this.tm.current.font16,
      bottom: this.tm.current.value12
    })
    .alignItems(HorizontalAlign.Start)
  }
}
