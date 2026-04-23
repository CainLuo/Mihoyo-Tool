/**
 * StarRailUniverseCard — 星铁宇宙卡片（模拟宇宙 + 差分宇宙 + 黄金与机械）
 *
 * 仅在 DailyNoteStarRail 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailDailyNoteVM } from '../../../models/DailyNoteModels';
import { DailyNoteDataRow } from '../common/DailyNoteDataRow';

@ComponentV2
export struct StarRailUniverseCard {
  @Param data: StarRailDailyNoteVM = new StarRailDailyNoteVM();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value0 }) {
      // 模拟宇宙积分（首行，无分割线）
      Row() {
        Text($r('app.string.daily_note_rogue_score'))
          .font(this.tm.current.body16Medium)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)

        Row({ space: this.tm.current.value2 }) {
          Text(this.data.currentRogueScore.toString())
            .font(this.tm.current.body16Medium)
            .fontColor(this.tm.current.colorTextPrimary)

          Text('/ ' + this.data.maxRogueScore.toString())
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)
        }
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value16,
        right: this.tm.current.value16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value8
      })

      // 差分宇宙
      if (this.data.rogueTournWeeklyUnlocked) {
        Row() {
          Text($r('app.string.daily_note_rogue_tourn'))
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)
            .layoutWeight(1)

          Column({ space: this.tm.current.value2 }) {
            Text(this.data.rogueTournWeeklyCur.toString() + ' / ' + this.data.rogueTournWeeklyMax.toString())
              .font(this.tm.current.body16Medium)
              .fontColor(this.tm.current.colorTextPrimary)

            if (this.data.rogueTournExpIsFull) {
              Text($r('app.string.daily_note_rogue_exp_full'))
                .font(this.tm.current.body12)
                .fontColor(this.tm.current.colorPrimary)
            }
          }
          .alignItems(HorizontalAlign.End)
        }
        .width(this.tm.current.full)
        .padding({
          left: this.tm.current.value16,
          right: this.tm.current.value16,
          top: this.tm.current.value8,
          bottom: this.tm.current.value8
        })
        .border({ width: { top: this.tm.current.value1 }, color: this.tm.current.colorDivider })
      } else {
        DailyNoteDataRow({
          label: $r('app.string.daily_note_rogue_tourn'),
          value: $r('app.string.daily_note_rogue_tourn_locked'),
          valueColor: this.tm.current.colorTextSecondary
        })
      }

      // 黄金与机械
      if (this.data.gridFightWeeklyMax > 0) {
        DailyNoteDataRow({
          label: $r('app.string.daily_note_grid_fight'),
          value: this.data.gridFightWeeklyCur.toString() + ' / ' + this.data.gridFightWeeklyMax.toString(),
          valueColor: this.tm.current.colorTextPrimary
        })
      } else {
        DailyNoteDataRow({
          label: $r('app.string.daily_note_grid_fight'),
          value: $r('app.string.daily_note_grid_fight_locked'),
          valueColor: this.tm.current.colorTextSecondary
        })
      }

      Row().height(this.tm.current.value4)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }
}
