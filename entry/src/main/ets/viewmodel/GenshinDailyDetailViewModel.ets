/**
 * GenshinDailyDetailViewModel.ets
 *
 * 原神实时便笺详情页 ViewModel。
 * 从 DB 读取 rawJson → GenshinDailyNoteParser.parse() → 转换为 GenshinDailyNoteVM。
 *
 * 时间描述（"X小时Y分钟后恢复"）在此处生成为纯字符串，
 * 因为时间是动态计算值，不适合放资源文件。
 */

import { CoreInitializer, GenshinDailyNoteParser, GenshinDailyNoteData, GenshinExpeditionData } from 'core';
import {
  GenshinDailyNoteVM,
  GenshinDailyTaskVM,
  ExpeditionVM
} from '../components/dailynote/DailyNoteModels';
import { Logger } from 'core';
import { ViewState } from '../constants/ViewStates';

const TAG: string = 'GenshinDailyDetailViewModel';

@ObservedV2
export class GenshinDailyDetailViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace note: GenshinDailyNoteVM = new GenshinDailyNoteVM();

  private accountId: string = '';
  private roleUid: string = '';

  init(accountId: string, roleUid: string): void {
    this.accountId = accountId;
    this.roleUid = roleUid;
  }

  async loadData(): Promise<void> {
    this.viewState = ViewState.LOADING;
    try {
      const row = await CoreInitializer.genshinRepository.getDailyNote(this.accountId, this.roleUid);
      if (row === null) {
        this.viewState = ViewState.EMPTY;
        return;
      }
      const data = GenshinDailyNoteParser.parse(row.rawJson);
      this.note = GenshinDailyDetailViewModel.toVM(data);
      this.viewState = ViewState.DATA;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.viewState = ViewState.ERROR;
    }
  }

  // ─── 数据转换 ────────────────────────────────────────────────

  private static toVM(data: GenshinDailyNoteData): GenshinDailyNoteVM {
    const vm = new GenshinDailyNoteVM();

    vm.currentResin = data.currentResin;
    vm.maxResin = data.maxResin;
    vm.resinRecoverySeconds = data.currentResin >= data.maxResin ? 0 : data.resinRecoveryTime;

    vm.currentHomeCoin = data.currentHomeCoin;
    vm.maxHomeCoin = data.maxHomeCoin;
    vm.homeCoinRecoverySeconds = data.currentHomeCoin >= data.maxHomeCoin ? 0 : data.homeCoinRecoveryTime;

    vm.dailyTask = new GenshinDailyTaskVM(
      data.finishedTaskNum,
      data.totalTaskNum,
      data.isExtraTaskRewardReceived,
      -1
    );

    vm.remainResinDiscountNum = data.remainResinDiscountNum;
    vm.resinDiscountNumLimit = data.resinDiscountNumLimit;

    vm.transformerReady = data.transformer.reached;
    vm.transformerDay = data.transformer.day;
    vm.transformerHour = data.transformer.hour;
    vm.transformerMinute = data.transformer.minute;

    vm.expeditions = GenshinDailyDetailViewModel.toExpeditionVMs(data.expeditions);
    vm.maxExpeditionNum = data.maxExpeditionNum;

    return vm;
  }

  private static toExpeditionVMs(raws: GenshinExpeditionData[]): ExpeditionVM[] {
    const result: ExpeditionVM[] = [];
    for (const r of raws) {
      const finished = r.status === 'Finished' || r.remainedTime === '0';
      const remainSec = parseInt(r.remainedTime, 10) || 0;
      result[result.length] = new ExpeditionVM(r.avatarSideIcon, remainSec, finished);
    }
    return result;
  }
}
