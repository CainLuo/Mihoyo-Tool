/**
 * DailyNoteGenshin — 原神实时便笺组件
 *
 * 展示：魔神任务、原粹树脂、洞天宝钱、每日委托、周本、参量质变仪、派遣
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinDailyNoteVM, ExpeditionVM, GenshinDailyTaskVM } from '../../../models/DailyNoteModels';
import { DailyNoteCard } from '../common/DailyNoteCard';
import { GenshinDailyTaskContent } from './GenshinDailyTaskContent';
import { GenshinExpeditionSection } from './GenshinExpeditionSection';
import { TimeFormatUtil } from '../../../utils/TimeFormatUtil';

function makeMockNote(resin: number): GenshinDailyNoteVM {
  const note = new GenshinDailyNoteVM();
  note.currentResin = resin;
  note.maxResin = 200;
  note.resinRecoverySeconds = resin >= 200 ? 0 : 14400;
  note.currentHomeCoin = 1800;
  note.maxHomeCoin = 2400;
  note.homeCoinRecoverySeconds = 43200;
  note.dailyTask = new GenshinDailyTaskVM(4, 4, true, 2);
  note.remainResinDiscountNum = 1;
  note.resinDiscountNumLimit = 3;
  note.transformerReady = true;
  note.transformerDay = 0;
  note.transformerHour = 0;
  note.transformerMinute = 0;
  note.expeditions = [
    new ExpeditionVM('', 29640, false),
    new ExpeditionVM('', 0, true),
    new ExpeditionVM('', 9000, false),
  ];
  note.maxExpeditionNum = 5;
  note.archonQuestDone = false;
  note.archonQuestDesc = '第四幕：永恒的终章';
  return note;
}

// ── Preview：正常状态（树脂未满）──
@Preview
@ComponentV2
export struct DailyNoteGenshinPreviewNormal {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Scroll() {
      DailyNoteGenshin({ data: makeMockNote(140) })
        .padding(this.tm.current.font16)
    }
    .height(this.tm.current.value600)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}

// ── Preview：树脂已满（红色警告）──
@Preview
@ComponentV2
export struct DailyNoteGenshinPreviewFull {
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
  @Param data: GenshinDailyNoteVM = new GenshinDailyNoteVM();
  @Local private tm: ThemeManager = themeManager;

  private resinColor(): ResourceColor {
    if (this.data.maxResin <= 0) { return this.tm.current.colorPrimary; }
    const ratio = this.data.currentResin / this.data.maxResin;
    if (ratio < 0.3) { return this.tm.current.colorDanger; }
    if (ratio < 0.7) { return this.tm.current.colorWarning; }
    return this.tm.current.colorPrimary;
  }

  @Builder
  taskContent() {
    GenshinDailyTaskContent({ task: this.data.dailyTask })
  }

  build() {
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
        subtitle: TimeFormatUtil.formatSeconds(this.data.resinRecoverySeconds, this.getUIContext()),
        hasSubtitle: this.data.resinRecoverySeconds > 0,
        valueText: this.data.currentResin.toString() + '/' + this.data.maxResin.toString(),
        hasValueText: true,
        valueColor: this.resinColor(),
      })

      DailyNoteCard({
        title: $r('app.string.daily_note_home_coin_title'),
        subtitle: TimeFormatUtil.formatSeconds(this.data.homeCoinRecoverySeconds, this.getUIContext()),
        hasSubtitle: this.data.homeCoinRecoverySeconds > 0,
        valueText: this.data.currentHomeCoin.toString() + '/' + this.data.maxHomeCoin.toString(),
        hasValueText: true,
      })

      DailyNoteCard({
        title: $r('app.string.daily_note_daily_task_title'),
        hasCustomBottom: true,
        customBottom: () => { this.taskContent() },
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
          : TimeFormatUtil.formatTransformer(this.data.transformerDay, this.data.transformerHour, this.data.transformerMinute, this.getUIContext()),
        hasSubtitle: true,
        valueText: this.data.transformerReady ? $r('app.string.daily_note_transformer_ready') : '',
        hasValueText: this.data.transformerReady,
        valueColor: this.tm.current.colorPrimary,
      })

      if (this.data.expeditions.length > 0) {
        GenshinExpeditionSection({
          expeditions: this.data.expeditions,
          maxExpeditionNum: this.data.maxExpeditionNum
        })
      }
    }
    .width(this.tm.current.full)
  }
}
