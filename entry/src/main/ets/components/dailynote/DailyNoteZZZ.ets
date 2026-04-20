/**
 * DailyNoteZZZ — 绝区零实时便笺组件
 *
 * 分三组展示：
 *   第一组（日常）：电量 + 恢复倒计时、活跃度
 *   第二组（商店）：录像店、刮刮卡
 *   第三组（其他）：式舆防卫战、会员卡、咖啡厅
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ZZZDailyNoteVM } from './DailyNoteModels'
import { TimeFormatUtil } from '../../utils/TimeFormatUtil'

// ─── Preview ─────────────────────────────────────────────────────

function makeMockZzzNote(): ZZZDailyNoteVM {
  const vm = new ZZZDailyNoteVM();
  vm.currentEnergy = 240;
  vm.maxEnergy = 240;
  vm.energyRecoverySeconds = 0;
  vm.currentVitality = 0;
  vm.maxVitality = 400;
  vm.vhsSaleState = 'SaleStateDone';
  vm.cardSign = 'CardSignNo';
  vm.abyssRefresh = 0;
  vm.memberCardIsOpen = false;
  vm.memberCardState = 'MemberCardStateNo';
  vm.cafeState = 'CafeStateNo';
  vm.templeExpeditionState = 'ExpeditionStateUnknown';
  vm.templeCurrentCurrency = 0;
  return vm;
}

@Preview
@ComponentV2
export struct DailyNoteZZZPreview {
  @Local private tm: ThemeManager = themeManager
  build() {
    Scroll() {
      DailyNoteZZZ({ data: makeMockZzzNote() })
        .padding(this.tm.current.value16)
    }
    .height(this.tm.current.value600)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}

// ─── 主组件 ──────────────────────────────────────────────────────

@ComponentV2
export struct DailyNoteZZZ {
  @Param data: ZZZDailyNoteVM = new ZZZDailyNoteVM()
  @Local private tm: ThemeManager = themeManager

  private energyColor(): ResourceColor {
    if (this.data.maxEnergy <= 0) { return this.tm.current.colorPrimary }
    const ratio = this.data.currentEnergy / this.data.maxEnergy
    if (ratio < 0.3) { return this.tm.current.colorDanger }
    if (ratio < 0.7) { return this.tm.current.colorWarning }
    return this.tm.current.colorPrimary
  }

  private vhsLabel(): ResourceStr {
    if (this.data.vhsSaleState === 'SaleStateDone') { return $r('app.string.daily_note_vhs_done') }
    if (this.data.vhsSaleState === 'SaleStateDoing') { return $r('app.string.daily_note_vhs_doing') }
    return $r('app.string.daily_note_vhs_no')
  }

  private vhsColor(): ResourceColor {
    if (this.data.vhsSaleState === 'SaleStateDone') { return this.tm.current.colorPrimary }
    if (this.data.vhsSaleState === 'SaleStateDoing') { return this.tm.current.colorWarning }
    return this.tm.current.colorTextSecondary
  }

  private cardSignLabel(): ResourceStr {
    if (this.data.cardSign === 'CardSignDone') { return $r('app.string.daily_note_card_done') }
    return $r('app.string.daily_note_card_no')
  }

  private cardSignColor(): ResourceColor {
    if (this.data.cardSign === 'CardSignDone') { return this.tm.current.colorPrimary }
    return this.tm.current.colorTextSecondary
  }

  private templeLabel(): ResourceStr {
    if (this.data.templeExpeditionState === 'ExpeditionStateRunning') { return $r('app.string.daily_note_temple_running') }
    if (this.data.templeExpeditionState === 'ExpeditionStateDone') { return $r('app.string.daily_note_temple_done') }
    if (this.data.templeExpeditionState === 'ExpeditionStateIdle') { return $r('app.string.daily_note_temple_idle') }
    return $r('app.string.daily_note_temple_unknown')
  }

  private templeColor(): ResourceColor {
    if (this.data.templeExpeditionState === 'ExpeditionStateDone') { return this.tm.current.colorPrimary }
    if (this.data.templeExpeditionState === 'ExpeditionStateRunning') { return this.tm.current.colorWarning }
    return this.tm.current.colorTextSecondary
  }

  private memberCardLabel(): ResourceStr {
    if (this.data.memberCardState === 'MemberCardStateActive') { return $r('app.string.daily_note_member_active') }
    if (this.data.memberCardState === 'MemberCardStateExpired') { return $r('app.string.daily_note_member_expired') }
    return $r('app.string.daily_note_member_no')
  }

  private memberCardColor(): ResourceColor {
    if (this.data.memberCardState === 'MemberCardStateActive') { return this.tm.current.colorPrimary }
    if (this.data.memberCardState === 'MemberCardStateExpired') { return this.tm.current.colorDanger }
    return this.tm.current.colorTextSecondary
  }

  private cafeLabel(): ResourceStr {
    if (this.data.cafeState === 'CafeStateOpen') { return $r('app.string.daily_note_cafe_open') }
    if (this.data.cafeState === 'CafeStateDone') { return $r('app.string.daily_note_cafe_done') }
    return $r('app.string.daily_note_cafe_no')
  }

  private cafeColor(): ResourceColor {
    if (this.data.cafeState === 'CafeStateDone') { return this.tm.current.colorPrimary }
    if (this.data.cafeState === 'CafeStateOpen') { return this.tm.current.colorWarning }
    return this.tm.current.colorTextSecondary
  }

  @Builder
  dailyCard() {
    Column({ space: this.tm.current.value0 }) {
      // 电量
      Row() {
        Column({ space: this.tm.current.value2 }) {
          Text($r('app.string.daily_note_energy'))
            .font(this.tm.current.body16Medium)
            .fontColor(this.tm.current.colorTextPrimary)
          if (this.data.energyRecoverySeconds > 0) {
            Text(TimeFormatUtil.formatSeconds(this.data.energyRecoverySeconds, this.getUIContext()))
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
          Text(this.data.currentEnergy.toString())
            .font(this.tm.current.title20Bold)
            .fontColor(this.energyColor())
          Text('/' + this.data.maxEnergy.toString())
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

      // 活跃度
      Row() {
        Column({ space: this.tm.current.value2 }) {
          Text($r('app.string.daily_note_vitality'))
            .font(this.tm.current.body16Medium)
            .fontColor(this.tm.current.colorTextPrimary)
          Text(this.data.currentVitality >= this.data.maxVitality
            ? $r('app.string.daily_note_vitality_done')
            : $r('app.string.daily_note_vitality_hint'))
            .font(this.tm.current.body12)
            .fontColor(this.data.currentVitality >= this.data.maxVitality
              ? this.tm.current.colorPrimary : this.tm.current.colorTextSecondary)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row({ space: this.tm.current.value2 }) {
          Text(this.data.currentVitality.toString())
            .font(this.tm.current.title20Bold)
            .fontColor(this.data.currentVitality >= this.data.maxVitality
              ? this.tm.current.colorPrimary : this.tm.current.colorTextSecondary)
          Text('/' + this.data.maxVitality.toString())
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
      .border({ width: { top: this.tm.current.value1 }, color: this.tm.current.colorDivider })

      Row().height(this.tm.current.value4)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }

  @Builder
  shopCard() {
    Column({ space: this.tm.current.value0 }) {
      this.dataRowFirst($r('app.string.daily_note_vhs_sale'), this.vhsLabel(), this.vhsColor())
      this.dataRow($r('app.string.daily_note_card_sign'), this.cardSignLabel(), this.cardSignColor())
      Row().height(this.tm.current.value4)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }

  @Builder
  otherCard() {
    Column({ space: this.tm.current.value0 }) {
      // 式舆防卫战（含货币数量）
      Row() {
        Text($r('app.string.daily_note_temple'))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
          .layoutWeight(1)
        Column({ space: this.tm.current.value2 }) {
          Text(this.templeLabel())
            .font(this.tm.current.body16Medium)
            .fontColor(this.templeColor())
          if (this.data.templeCurrentCurrency > 0) {
            Text('货币: ' + this.data.templeCurrentCurrency.toString())
              .font(this.tm.current.body12)
              .fontColor(this.tm.current.colorTextSecondary)
          }
        }
        .alignItems(HorizontalAlign.End)
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value16,
        right: this.tm.current.value16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value8
      })

      this.dataRow($r('app.string.daily_note_member_card'), this.memberCardLabel(), this.memberCardColor())
      this.dataRow($r('app.string.daily_note_cafe'), this.cafeLabel(), this.cafeColor())
      Row().height(this.tm.current.value4)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }

  @Builder
  dataRowFirst(label: ResourceStr, value: ResourceStr, valueColor: ResourceColor) {
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
      top: this.tm.current.value12,
      bottom: this.tm.current.value8
    })
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
      this.dailyCard()
      this.sectionLabel($r('app.string.daily_note_section_shop'))
      this.shopCard()
      this.sectionLabel($r('app.string.daily_note_section_other'))
      this.otherCard()
    }
    .width(this.tm.current.full)
  }
}
