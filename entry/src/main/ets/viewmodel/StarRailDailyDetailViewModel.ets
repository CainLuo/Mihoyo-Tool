/**
 * StarRailDailyDetailViewModel.ets
 *
 * 星穹铁道实时便笺详情页 ViewModel。
 * 从 DB 读取 rawJson → StarRailDailyNoteParser.parse() → 转换为 StarRailDailyNoteVM。
 */

import { CoreInitializer, StarRailDailyNoteParser, StarRailDailyNoteData, StarRailExpeditionData } from 'core';
import { StarRailDailyNoteVM } from '../components/dailynote/DailyNoteModels';
import { ExpeditionVM } from '../components/dailynote/DailyNoteModels';
import { Logger } from 'core';
import { ViewState } from '../constants/ViewStates';

const TAG: string = 'StarRailDailyDetailViewModel';

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
    try {
      const row = await CoreInitializer.starRailRepository.getDailyNote(this.accountId, this.roleUid);
      if (row === null) {
        this.viewState = ViewState.EMPTY;
        return;
      }
      const data = StarRailDailyNoteParser.parse(row.rawJson);
      this.note = StarRailDailyDetailViewModel.toVM(data);
      this.viewState = ViewState.DATA;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.viewState = ViewState.ERROR;
    }
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
    vm.expeditions = StarRailDailyDetailViewModel.toExpeditionVMs(data.expeditions);
    vm.currentTrainScore = data.currentTrainScore;
    vm.maxTrainScore = data.maxTrainScore;
    vm.currentRogueScore = data.currentRogueScore;
    vm.maxRogueScore = data.maxRogueScore;
    vm.weeklyCocoonCnt = data.weeklyCocoonCnt;
    vm.weeklyCocoonLimit = data.weeklyCocoonLimit;
    vm.rogueTournWeeklyUnlocked = data.rogueTournWeeklyUnlocked;
    vm.rogueTournWeeklyCur = data.rogueTournWeeklyCur;
    vm.rogueTournWeeklyMax = data.rogueTournWeeklyMax;
    vm.rogueTournExpIsFull = data.rogueTournExpIsFull;
    vm.gridFightWeeklyCur = data.gridFightWeeklyCur;
    vm.gridFightWeeklyMax = data.gridFightWeeklyMax;
    return vm;
  }

  private static toExpeditionVMs(raws: StarRailExpeditionData[]): ExpeditionVM[] {
    const result: ExpeditionVM[] = [];
    for (let i = 0; i < raws.length; i++) {
      const r = raws[i];
      const finished = r.status === 'Finished' || r.remainedTime === '0';
      const remainSec = parseInt(r.remainedTime, 10) || 0;
      result[result.length] = new ExpeditionVM(r.avatarSideIcon, remainSec, finished);
    }
    return result;
  }
}
