/**
 * DailyNoteStarRail — 崩坏：星穹铁道实时便笺组件
 *
 * 分两组展示：
 *   第一组（日常）：开拓力 + 恢复倒计时、后备开拓力、委托派遣、每日实训、历战余响
 *   第二组（宇宙）：模拟宇宙积分、差分宇宙（含经验已满标签）、黄金与机械
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { StarRailDailyNoteVM } from './DailyNoteModels'
import { TimeFormatUtil } from '../../utils/TimeFormatUtil'

// ─── Preview ─────────────────────────────────────────────────────

function makeMockSrNote(): StarRailDailyNoteVM {
  const vm = new StarRailDailyNoteVM();
  vm.currentStamina = 300;
  vm.maxStamina = 300;
  vm.staminaRecoverySeconds = 0;
  vm.currentReserveStamina = 2400;
  vm.isReserveStaminaFull = true;
  vm.acceptedExpeditionNum = 0;
  vm.totalExpeditionNum = 4;
  vm.currentTrainScore = 0;
  vm.maxTrainScore = 500;
  vm.currentRogueScore = 0;
  vm.maxRogueScore = 14000;
  vm.weeklyCocoonCnt = 3;
  vm.weeklyCocoonLimit = 3;
  vm.rogueTournWeeklyUnlocked = false;
  vm.rogueTournWeeklyCur = 0;
  vm.rogueTournWeeklyMax = 1000;
  vm.rogueTournExpIsFull = false;
  vm.gridFightWeeklyCur = 0;
  vm.gridFightWeeklyMax = 0;
  return vm;
}

@Preview
@ComponentV2
export struct DailyNoteStarRailPreview {
  @Local private tm: ThemeManager = themeManager
  build() {
    Scroll() {
      DailyNoteStarRail({ data: makeMockSrNote() })
        .padding(this.tm.current.value16)
    }
    .height(this.tm.current.value600)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}

// ─── 主组件 ──────────────────────────────────────────────────────

@ComponentV2
export struct DailyNoteStarRail {
  @Param data: StarRailDailyNoteVM = new StarRailDailyNoteVM()
  @Local private tm: ThemeManager = themeManager

  private staminaColor(): ResourceColor {
    if (this.data.maxStamina <= 0) { return this.tm.current.colorPrimary }
    const ratio = this.data.currentStamina / this.data.maxStamina
    if (ratio < 0.3) { return this.tm.current.colorDanger }
    if (ratio < 0.7) { return this.tm.current.colorWarning }
    return this.tm.current.colorPrimary
  }

  @Builder
  staminaCard() {
    Column({ space: this.tm.current.value0 }) {
      // 开拓力
      Row() {
        Column({ space: this.tm.current.value2 }) {
          Text($r('app.string.daily_note_stamina'))
            .font(this.tm.current.body16Medium)
            .fontColor(this.tm.current.colorTextPrimary)
          if (this.data.staminaRecoverySeconds > 0) {
            Text(TimeFormatUtil.formatSeconds(this.data.staminaRecoverySeconds, this.getUIContext()))
              .font(this.tm.current.body12)
              .fontColor(this.tm.current.colorTextSecondary)
          } else {
            Text($r('app.string.daily_note_expedition_finished'))
              .font(this.tm.current.body12)
              .fontColor(this.tm.current.colorPrimary)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row({ space: this.tm.current.value2 }) {
          Text(this.data.currentStamina.toString())
            .font(this.tm.current.title20Bold)
            .fontColor(this.staminaColor())
          Text('/' + this.data.maxStamina.toString())
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value16,
        right: this.tm.current.value16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value8
      })

      // 后备开拓力
      this.dataRow(
        $r('app.string.daily_note_reserve_stamina'),
        this.data.isReserveStaminaFull
          ? this.data.currentReserveStamina.toString() + ' (已满)'
          : this.data.currentReserveStamina.toString(),
        this.data.isReserveStaminaFull ? this.tm.current.colorPrimary : this.tm.current.colorTextPrimary
      )
      // 委托派遣
      this.dataRow(
        $r('app.string.daily_note_expedition_sr'),
        this.data.acceptedExpeditionNum.toString() + ' / ' + this.data.totalExpeditionNum.toString(),
        this.tm.current.colorTextPrimary
      )
      // 每日实训
      this.dataRow(
        $r('app.string.daily_note_train_score'),
        this.data.currentTrainScore.toString() + ' / ' + this.data.maxTrainScore.toString(),
        this.tm.current.colorTextPrimary
      )
      // 历战余响
      this.dataRow(
        $r('app.string.daily_note_cocoon'),
        this.data.weeklyCocoonCnt.toString() + ' / ' + this.data.weeklyCocoonLimit.toString(),
        this.data.weeklyCocoonCnt >= this.data.weeklyCocoonLimit
          ? this.tm.current.colorPrimary : this.tm.current.colorTextPrimary
      )
      Row().height(this.tm.current.value4)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }

  @Builder
  universeCard() {
    Column({ space: this.tm.current.value0 }) {
      // 模拟宇宙积分
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
        this.dataRow(
          $r('app.string.daily_note_rogue_tourn'),
          $r('app.string.daily_note_rogue_tourn_locked'),
          this.tm.current.colorTextSecondary
        )
      }

      // 黄金与机械
      if (this.data.gridFightWeeklyMax > 0) {
        this.dataRow(
          $r('app.string.daily_note_grid_fight'),
          this.data.gridFightWeeklyCur.toString() + ' / ' + this.data.gridFightWeeklyMax.toString(),
          this.tm.current.colorTextPrimary
        )
      } else {
        this.dataRow(
          $r('app.string.daily_note_grid_fight'),
          $r('app.string.daily_note_grid_fight_locked'),
          this.tm.current.colorTextSecondary
        )
      }

      Row().height(this.tm.current.value4)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }

  @Builder
  dataRow(label: ResourceStr, value: ResourceStr, valueColor: ResourceColor) {
    Row() {
      Text(label)
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextSecondary)
        .layoutWeight(1)
      Text(value)
        .font(this.tm.current.body16Medium)
        .fontColor(valueColor)
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value16,
      right: this.tm.current.value16,
      top: this.tm.current.value8,
      bottom: this.tm.current.value8
    })
    .border({ width: { top: this.tm.current.value1 }, color: this.tm.current.colorDivider })
  }

  @Builder
  sectionLabel(label: Resource) {
    Text(label)
      .font(this.tm.current.body12)
      .fontColor(this.tm.current.colorTextSecondary)
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value4,
        top: this.tm.current.value16,
        bottom: this.tm.current.value8
      })
  }

  build() {
    Column({ space: this.tm.current.value0 }) {
      this.sectionLabel($r('app.string.daily_note_section_daily'))
      this.staminaCard()
      this.sectionLabel($r('app.string.daily_note_section_universe'))
      this.universeCard()
    }
    .width(this.tm.current.full)
  }
}
