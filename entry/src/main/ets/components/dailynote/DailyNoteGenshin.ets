import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GenshinDailyNoteVM, ExpeditionVM, GenshinDailyTaskVM } from './DailyNoteModels'
import { DailyNoteCard } from './DailyNoteCard'
import { ExpeditionItem } from './ExpeditionItem'
import { GenshinConstants } from '../../constants/GenshinConstants'
import { TimeFormatUtil } from '../../utils/TimeFormatUtil'
import { common } from '@kit.AbilityKit'

/** 构造完整 mock 便签数据 */
function makeMockNote(resin: number): GenshinDailyNoteVM {
  const note = new GenshinDailyNoteVM();
  note.currentResin = resin;
  note.maxResin = 200;
  note.resinRecoverySeconds = resin >= 200 ? 0 : 14400; // 4小时
  note.currentHomeCoin = 1800;
  note.maxHomeCoin = 2400;
  note.homeCoinRecoverySeconds = 43200; // 12小时
  note.dailyTask = new GenshinDailyTaskVM(4, 4, true, 2);
  note.remainResinDiscountNum = 1;
  note.resinDiscountNumLimit = 3;
  note.transformerReady = true;
  note.transformerDay = 0;
  note.transformerHour = 0;
  note.transformerMinute = 0;
  note.expeditions = [
    new ExpeditionVM('', 29640, false),  // 8小时14分钟
    new ExpeditionVM('', 0, true),
    new ExpeditionVM('', 9000, false),   // 2小时30分钟
  ];
  note.maxExpeditionNum = 5;
  note.archonQuestDone = false;
  note.archonQuestDesc = '第四幕：永恒的终章';
  return note;
}

// ── Preview：正常状态（树脂未满）──
@Preview
@ComponentV2
struct DailyNoteGenshinPreviewNormal {
  @Local private tm: ThemeManager = themeManager
  build() {
    Scroll() {
      DailyNoteGenshin({ data: makeMockNote(140) })
        .padding(this.tm.current.value16)
    }
    .height(this.tm.current.value600)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}

// ── Preview：树脂已满（红色警告）──
@Preview
@ComponentV2
struct DailyNoteGenshinPreviewFull {
  build() {
    Scroll() {
      DailyNoteGenshin({ data: makeMockNote(200) })
        .padding(themeManager.current.value16)
    }
    .height(themeManager.current.value600)
    .backgroundColor(themeManager.current.colorPageBg)
  }
}

@ComponentV2
export struct DailyNoteGenshin {
  @Param data: GenshinDailyNoteVM = new GenshinDailyNoteVM()
  @Local private tm: ThemeManager = themeManager
  @Local private ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext

  private resinColor(): ResourceColor {
    if (this.data.currentResin >= this.data.maxResin) return this.tm.current.colorDanger
    if (this.data.currentResin >= GenshinConstants.RESIN_WARNING_THRESHOLD) return this.tm.current.colorWarning
    return this.tm.current.colorPrimary
  }

  @Builder
  taskDotsContent() {
    Column({ space: this.tm.current.value4 }) {
      Row({ space: this.tm.current.value8 }) {
        Text($r('app.string.daily_note_task_label'))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.value56)
        ForEach([0, 1, 2, 3] as number[], (i: number) => {
          Text(i < this.data.dailyTask.finishedNum ? '✓' : '◇')
            .font(this.tm.current.body13)
            .fontColor(i < this.data.dailyTask.finishedNum
              ? this.tm.current.colorPrimary : this.tm.current.colorPlaceholder)
        })
        Blank()
        Text(this.data.dailyTask.isExtraTaskRewardReceived
          ? $r('app.string.daily_note_task_all_received')
          : $r('app.string.daily_note_task_not_received'))
          .font(this.tm.current.body13)
          .fontColor(this.data.dailyTask.isExtraTaskRewardReceived
            ? this.tm.current.colorTextSecondary : this.tm.current.colorPrimary)
      }
      .width(this.tm.current.full)

      Row({ space: this.tm.current.value8 }) {
        Text($r('app.string.daily_note_adventure_label'))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.value56)
        ForEach([0, 1, 2, 3] as number[], (i: number) => {
          Text(i < this.data.dailyTask.finishedNum ? '✓' : '◇')
            .font(this.tm.current.body13)
            .fontColor(i < this.data.dailyTask.finishedNum
              ? this.tm.current.colorPrimary : this.tm.current.colorPlaceholder)
        })
      }
      .width(this.tm.current.full)

      if (this.data.dailyTask.storedAdventure >= 0) {
        Row({ space: this.tm.current.value4 }) {
          Text($r('app.string.daily_note_stored_adventure_label'))
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)
          Text('×' + this.data.dailyTask.storedAdventure.toString())
            .font(this.tm.current.body16Medium)
            .fontColor(this.tm.current.colorPrimary)
        }
        .width(this.tm.current.full)
        .margin({ top: this.tm.current.value2 })
      }
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value16,
      right: this.tm.current.value16,
      bottom: this.tm.current.value12
    })
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    // 每个模块独立卡片，间距由 Column space 控制
    Column({ space: this.tm.current.value8 }) {

      DailyNoteCard({
        title: $r('app.string.daily_note_archon_quest_title'),
        valueText: this.data.archonQuestDone
          ? $r('app.string.daily_note_archon_quest_done') : this.data.archonQuestDesc,
        hasValueText: true,
        valueColor: this.data.archonQuestDone
          ? this.tm.current.colorTextSecondary : this.tm.current.colorPrimary,
      })

      DailyNoteCard({
        title: $r('app.string.daily_note_resin_title'),
        subtitle: TimeFormatUtil.formatSeconds(this.data.resinRecoverySeconds, this.ctx),
        hasSubtitle: this.data.resinRecoverySeconds > 0,
        valueText: this.data.currentResin.toString() + '/' + this.data.maxResin.toString(),
        hasValueText: true,
        valueColor: this.resinColor(),
      })

      DailyNoteCard({
        title: $r('app.string.daily_note_home_coin_title'),
        subtitle: TimeFormatUtil.formatSeconds(this.data.homeCoinRecoverySeconds, this.ctx),
        hasSubtitle: this.data.homeCoinRecoverySeconds > 0,
        valueText: this.data.currentHomeCoin.toString() + '/' + this.data.maxHomeCoin.toString(),
        hasValueText: true,
      })

      DailyNoteCard({
        title: $r('app.string.daily_note_daily_task_title'),
        hasCustomBottom: true,
        customBottom: () => { this.taskDotsContent() },
      })

      DailyNoteCard({
        title: $r('app.string.daily_note_weekly_boss_title'),
        subtitle: $r('app.string.daily_note_weekly_boss_subtitle'),
        hasSubtitle: true,
        valueText: this.data.remainResinDiscountNum.toString() + '/' +
          this.data.resinDiscountNumLimit.toString(),
        hasValueText: true,
      })

      DailyNoteCard({
        title: $r('app.string.daily_note_transformer_title'),
        subtitle: this.data.transformerReady
          ? $r('app.string.daily_note_transformer_done')
          : TimeFormatUtil.formatTransformer(this.data.transformerDay, this.data.transformerHour, this.data.transformerMinute, this.ctx),
        hasSubtitle: true,
        valueText: this.data.transformerReady ? $r('app.string.daily_note_transformer_ready') : '',
        hasValueText: this.data.transformerReady,
        valueColor: this.tm.current.colorPrimary,
      })

      if (this.data.expeditions.length > 0) {
        Column() {
          Row() {
            Text($r('app.string.daily_note_expedition_title'))
              .font(this.tm.current.body16)
              .fontColor(this.tm.current.colorTextPrimary)
            Text(' (' + this.data.expeditions.length.toString() +
              '/' + this.data.maxExpeditionNum.toString() + ')')
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

          ForEach(this.data.expeditions, (item: ExpeditionVM) => {
            ExpeditionItem({ expedition: item })
          })

          Row().height(this.tm.current.value8)
        }
        .width(this.tm.current.full)
        .backgroundColor(this.tm.current.colorSurfaceCard)
        .borderRadius(this.tm.current.radius12)
      }
    }
    .width(this.tm.current.full)
  }
}
