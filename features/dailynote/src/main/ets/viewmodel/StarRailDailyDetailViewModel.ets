/**
 * StarRailDailyDetailViewModel.ets
 *
 * 星穹铁道实时便笺详情页 ViewModel。
 * 从 DB 读取 rawJson → StarRailDailyNoteParser.parse() → 转换为 StarRailDailyNoteVM。
 */

import { CoreInitializer, StarRailDailyNoteParser, StarRailDailyNoteData } from 'core'
import { StarRailDailyNoteVM } from '../model/DailyNoteModels'
import { ViewState } from 'basic'
import { loadDailyNote } from '../utils/DailyNoteLoader'
import { toExpeditionVMs } from '../utils/ExpeditionMapper'

const TAG: string = 'StarRailDailyDetailViewModel'

@ObservedV2
export class StarRailDailyDetailViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace note: StarRailDailyNoteVM = new StarRailDailyNoteVM();

  private accountId: string = '';
  private roleUid: string = '';

  init(accountId: string, roleUid: string): void {
    this.accountId = accountId;
    this.roleUid = roleUid;
  }

  async loadData(): Promise<void> {
    this.viewState = ViewState.LOADING;
    const result = await loadDailyNote(
      TAG,
      async (): Promise<string | null> => {
        const row = await CoreInitializer.starRailRepository.getDailyNote(this.accountId, this.roleUid);
        return row === null ? null : row.rawJson;
      },
      (rawJson: string): StarRailDailyNoteVM =>
        StarRailDailyDetailViewModel.toVM(StarRailDailyNoteParser.parse(rawJson)),
    );
    if (result.note !== null) {
      this.note = result.note;
    }
    this.viewState = result.viewState;
  }

  private static toVM(data: StarRailDailyNoteData): StarRailDailyNoteVM {
    const vm = new StarRailDailyNoteVM();
    vm.currentStamina = data.currentStamina;
    vm.maxStamina = data.maxStamina;
    vm.staminaRecoverySeconds = data.currentStamina >= data.maxStamina ? 0 : data.staminaRecoverTime;
    vm.currentReserveStamina = data.currentReserveStamina;
    vm.isReserveStaminaFull = data.isReserveStaminaFull;
    vm.acceptedExpeditionNum = data.acceptedExpeditionNum;
    vm.totalExpeditionNum = data.totalExpeditionNum;
    vm.expeditions = toExpeditionVMs(data.expeditions);
    vm.currentTrainScore = data.currentTrainScore;
    vm.maxTrainScore = data.maxTrainScore;
    vm.currentRogueScore = data.currentRogueScore;
    vm.maxRogueScore = data.maxRogueScore;
    vm.weeklyCocoonCnt = data.weeklyCocoonCnt;
    vm.weeklyCocoonLimit = data.weeklyCocoonLimit;
    vm.isRogueTournWeeklyUnlocked = data.rogueTournWeeklyUnlocked;
    vm.rogueTournWeeklyCur = data.rogueTournWeeklyCur;
    vm.rogueTournWeeklyMax = data.rogueTournWeeklyMax;
    vm.isRogueTournExpFull = data.rogueTournExpIsFull;
    vm.gridFightWeeklyCur = data.gridFightWeeklyCur;
    vm.gridFightWeeklyMax = data.gridFightWeeklyMax;
    return vm;
  }
}
