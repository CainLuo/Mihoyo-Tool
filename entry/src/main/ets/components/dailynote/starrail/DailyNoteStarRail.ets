/**
 * DailyNoteStarRail — 崩坏：星穹铁道实时便笺组件
 *
 * 分两组展示：
 *   第一组（日常）：开拓力 + 后备 + 派遣 + 实训 + 历战
 *   第二组（宇宙）：模拟宇宙积分 + 差分宇宙 + 黄金与机械
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailDailyNoteVM } from '../../../models/DailyNoteModels';
import { DailyNoteSectionLabel } from '../common/DailyNoteSectionLabel';
import { StarRailStaminaCard } from './StarRailStaminaCard';
import { StarRailUniverseCard } from './StarRailUniverseCard';

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

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct DailyNoteStarRailPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Scroll() {
      DailyNoteStarRail({ data: makeMockSrNote() })
        .padding(this.tm.current.value16)
    }
    .height(this.tm.current.value600)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}

@ComponentV2
export struct DailyNoteStarRail {
  @Param data: StarRailDailyNoteVM = new StarRailDailyNoteVM();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value0 }) {
      DailyNoteSectionLabel({ label: $r('app.string.daily_note_section_daily') })

      StarRailStaminaCard({ data: this.data })

      DailyNoteSectionLabel({ label: $r('app.string.daily_note_section_universe') })

      StarRailUniverseCard({ data: this.data })
    }
    .width(this.tm.current.full)
  }
}
