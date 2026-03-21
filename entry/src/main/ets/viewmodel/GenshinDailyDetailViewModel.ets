/**
 * GenshinDailyDetailViewModel.ets
 *
 * 原神实时便笺详情页 ViewModel。
 * 从 DB 读取 raw_json → GenshinDailyNoteParser.parse() → 转换为 GenshinDailyNoteVM。
 *
 * 时间描述（"X小时Y分钟后恢复"）在此处生成为纯字符串，
 * 因为时间是动态计算值，不适合放资源文件。
 */

import { DailyNoteRepository, GenshinDailyNoteParser, GenshinDailyNoteData, GenshinExpeditionData } from 'core';
import {
  GenshinDailyNoteVM,
  GenshinDailyTaskVM,
  ExpeditionVM
} from '../components/dailynote/DailyNoteModels';
import { Logger } from '../utils/Logger';
import { ViewState } from '../constants/ViewStates';

const TAG: string = 'GenshinDailyDetailViewModel';

@ObservedV2
export class GenshinDailyDetailViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace note: GenshinDailyNoteVM = new GenshinDailyNoteVM();

  private gameId: string = '';
  private roleUid: string = '';

  init(gameId: string, roleUid: string): void {
    this.gameId = gameId;
    this.roleUid = roleUid;
  }

  async loadData(): Promise<void> {
    this.viewState = ViewState.LOADING;
    try {
      const row = await DailyNoteRepository.findDailyNote(this.gameId, this.roleUid);
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
    vm.resinRecoveryDesc = data.currentResin >= data.maxResin
      ? ''
      : GenshinDailyDetailViewModel.formatSeconds(data.resinRecoveryTime);

    vm.currentHomeCoin = data.currentHomeCoin;
    vm.maxHomeCoin = data.maxHomeCoin;
    vm.homeCoinRecoveryDesc = data.currentHomeCoin >= data.maxHomeCoin
      ? ''
      : GenshinDailyDetailViewModel.formatSeconds(data.homeCoinRecoveryTime);

    vm.dailyTask = new GenshinDailyTaskVM(
      data.finishedTaskNum,
      data.totalTaskNum,
      data.isExtraTaskRewardReceived,
      -1
    );

    vm.remainResinDiscountNum = data.remainResinDiscountNum;
    vm.resinDiscountNumLimit = data.resinDiscountNumLimit;

    vm.transformerReady = data.transformer.reached;
    vm.transformerDesc = data.transformer.reached
      ? ''
      : GenshinDailyDetailViewModel.formatTransformer(data.transformer.day, data.transformer.hour, data.transformer.minute);

    vm.expeditions = GenshinDailyDetailViewModel.toExpeditionVMs(data.expeditions);
    vm.maxExpeditionNum = data.maxExpeditionNum;

    return vm;
  }

  private static toExpeditionVMs(raws: GenshinExpeditionData[]): ExpeditionVM[] {
    const result: ExpeditionVM[] = [];
    for (const r of raws) {
      const finished = r.status === 'Finished' || r.remainedTime === '0';
      const remainSec = parseInt(r.remainedTime, 10) || 0;
      const remainDesc = finished ? '' : GenshinDailyDetailViewModel.formatSeconds(remainSec);
      result[result.length] = new ExpeditionVM(r.avatarSideIcon, remainDesc, finished);
    }
    return result;
  }

  /**
   * 将秒数格式化为 "X小时Y分钟后恢复"。
   * 不足1小时只显示分钟，不足1分钟显示"即将恢复"。
   */
  private static formatSeconds(seconds: number): string {
    if (seconds <= 0) {
      return '';
    }
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (h > 0) {
      return `${h}小时${m}分钟后恢复`;
    }
    if (m > 0) {
      return `${m}分钟后恢复`;
    }
    return '即将恢复';
  }

  private static formatTransformer(day: number, hour: number, minute: number): string {
    if (day > 0) {
      return `${day}天${hour}小时后可用`;
    }
    if (hour > 0) {
      return `${hour}小时${minute}分钟后可用`;
    }
    if (minute > 0) {
      return `${minute}分钟后可用`;
    }
    return '即将可用';
  }
}
