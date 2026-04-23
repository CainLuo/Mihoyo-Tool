/**
 * DailyNoteZZZ — 绝区零实时便笺组件
 *
 * 分三组展示：
 *   第一组（日常）：电量 + 活跃度
 *   第二组（商店）：录像店 + 刮刮卡
 *   第三组（其他）：式舆防卫战 + 会员卡 + 咖啡厅
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZDailyNoteVM } from '../../../models/DailyNoteModels';
import { DailyNoteSectionLabel } from '../common/DailyNoteSectionLabel';
import { ZZZDailyCard } from './ZZZDailyCard';
import { ZZZShopCard } from './ZZZShopCard';
import { ZZZOtherCard } from './ZZZOtherCard';

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

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct DailyNoteZZZPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Scroll() {
      DailyNoteZZZ({ data: makeMockZzzNote() })
        .padding(this.tm.current.value16)
    }
    .height(this.tm.current.value600)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}

@ComponentV2
export struct DailyNoteZZZ {
  @Param data: ZZZDailyNoteVM = new ZZZDailyNoteVM();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value0 }) {
      DailyNoteSectionLabel({ label: $r('app.string.daily_note_section_daily') })

      ZZZDailyCard({ data: this.data })

      DailyNoteSectionLabel({ label: $r('app.string.daily_note_section_shop') })

      ZZZShopCard({ data: this.data })

      DailyNoteSectionLabel({ label: $r('app.string.daily_note_section_other') })

      ZZZOtherCard({ data: this.data })
    }
    .width(this.tm.current.full)
  }
}
