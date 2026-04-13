/**
 * ZZZDailyDetailViewModel.ets
 *
 * 绝区零实时便笺详情页 ViewModel。
 * 从 DB 读取 rawJson → ZZZDailyNoteParser.parse() → 转换为 ZZZDailyNoteVM。
 */

import { CoreInitializer, ZZZDailyNoteParser, ZZZDailyNoteData } from 'core';
import { ZZZDailyNoteVM } from '../components/dailynote/DailyNoteModels';
import { Logger } from 'core';
import { ViewState } from '../constants/ViewStates';

const TAG: string = 'ZZZDailyDetailViewModel';

@ObservedV2
export class ZZZDailyDetailViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace note: ZZZDailyNoteVM = new ZZZDailyNoteVM();

  private accountId: string = '';
  private roleUid: string = '';

  init(accountId: string, roleUid: string): void {
    this.accountId = accountId;
    this.roleUid = roleUid;
  }

  async loadData(): Promise<void> {
    this.viewState = ViewState.LOADING;
    try {
      const row = await CoreInitializer.zzzRepository.getDailyNote(this.accountId, this.roleUid);
      if (row === null) {
        this.viewState = ViewState.EMPTY;
        return;
      }
      const data = ZZZDailyNoteParser.parse(row.rawJson);
      this.note = ZZZDailyDetailViewModel.toVM(data);
      this.viewState = ViewState.DATA;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.viewState = ViewState.ERROR;
    }
  }

  private static toVM(data: ZZZDailyNoteData): ZZZDailyNoteVM {
    const vm = new ZZZDailyNoteVM();
    vm.currentEnergy = data.currentEnergy;
    vm.maxEnergy = data.maxEnergy;
    vm.energyRecoverySeconds = data.currentEnergy >= data.maxEnergy ? 0 : data.energyRecoverTime;
    vm.currentVitality = data.currentVitality;
    vm.maxVitality = data.maxVitality;
    vm.vhsSaleState = data.videoStoreState;
    vm.cardSign = data.cardSign;
    vm.abyssRefresh = data.abyssRefresh;
    vm.memberCardIsOpen = data.memberCardIsOpen;
    vm.memberCardState = data.memberCardState;
    vm.cafeState = data.cafeState;
    vm.templeExpeditionState = data.templeExpeditionState;
    vm.templeCurrentCurrency = data.templeCurrentCurrency;
    return vm;
  }
}
