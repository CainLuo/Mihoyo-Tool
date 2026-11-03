/**
 * GenshinDailyDetailViewModel.ets
 *
 * 原神实时便笺详情页 ViewModel。
 * 从 DB 读取 rawJson → GenshinDailyNoteParser.parse() → 转换为 GenshinDailyNoteVM。
 *
 * 时间描述（"X小时Y分钟后恢复"）在 View 层生成为纯字符串，
 * 因为时间是动态计算值，不适合放资源文件。
 */

import { CoreInitializer, GenshinDailyNoteParser, GenshinDailyNoteData } from 'core'
import { GenshinDailyNoteVM, GenshinDailyTaskVM } from '../model/DailyNoteModels'
import { ViewState } from 'basic'
import { loadDailyNote } from '../utils/DailyNoteLoader'
import { toExpeditionVMs } from '../utils/ExpeditionMapper'

const TAG: string = 'GenshinDailyDetailViewModel'

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
    const result = await loadDailyNote(
      TAG,
      async (): Promise<string | null> => {
        const row = await CoreInitializer.genshinRepository.getDailyNote(this.accountId, this.roleUid);
        return row === null ? null : row.rawJson;
      },
      (rawJson: string): GenshinDailyNoteVM =>
        GenshinDailyDetailViewModel.toVM(GenshinDailyNoteParser.parse(rawJson)),
    );
    if (result.note !== null) {
      this.note = result.note;
    }
    this.viewState = result.viewState;
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

    vm.isTransformerReady = data.transformer.reached;
    vm.transformerDay = data.transformer.day;
    vm.transformerHour = data.transformer.hour;
    vm.transformerMinute = data.transformer.minute;

    vm.expeditions = toExpeditionVMs(data.expeditions);
    vm.maxExpeditionNum = data.maxExpeditionNum;

    return vm;
  }
}
