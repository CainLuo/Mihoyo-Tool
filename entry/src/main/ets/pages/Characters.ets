/**
 * Characters — 角色 Tab 页（View 层，普通内容组件）
 *
 * ViewModel 由 Characters 自己持有。
 * 通过 @Param 回调把操作函数和状态上报给 Main，由 Main 挂到 Navigation.menus()。
 * onCardTap 路由逻辑由 ViewModel.buildCardTapRoute() 决定，View 层只负责执行跳转。
 */
import { BusinessError } from '@kit.BasicServicesKit';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { CharactersViewModel } from '../viewmodel/CharactersViewModel';
import { AccountOption } from '../models/AccountOption';
import { CharactersContent } from '../components/characters/CharactersContent';
import { Logger, GameDataSummary } from 'core';
import { AccountSignal } from '../utils/AccountSignal';
import { showFeedback } from '../utils/FeedbackUtil';
import { FeedbackType } from '../constants/FeedbackType';

@ComponentV2
export struct Characters {
  @Param detailStack: NavPathStack = new NavPathStack();
  @Param isSplit: boolean = false;
  @Param onReady: (doRefresh: () => void, doSelectAccount: (idx: number) => void) => void =
    (_r: () => void, _s: (idx: number) => void) => {};
  @Param onMenuStateChange: (
    showRefresh: boolean,
    showSwitcher: boolean,
    isRefreshing: boolean,
    accountOptions: AccountOption[],
    selectedIdx: number
  ) => void = (_sr: boolean, _ss: boolean, _ir: boolean, _ao: AccountOption[], _si: number) => {};

  @Local private tm: ThemeManager = themeManager;
  @Local private vm: CharactersViewModel = new CharactersViewModel();
  @Local private signal: AccountSignal = AccountSignal.instance();
  private uiCtx: UIContext | null = null;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext();
    this.onReady(
      () => { this.vm.refresh() },
      (idx: number) => { this.vm.selectAccount(idx).catch((_: Error | object) => {}) }
    );
    this.vm.loadData().then(() => {
      this.notifyMenuState();
    }).catch((_: Error | object) => {});
  }

  @Monitor('signal.version')
  onAccountDataChanged(_monitor: IMonitor): void {
    this.vm.loadData().then(() => {
      this.notifyMenuState();
    }).catch((_: Error | object) => {});
  }

  @Monitor('vm.showRefreshButton')
  onShowRefreshChanged(_monitor: IMonitor): void { this.notifyMenuState(); }

  @Monitor('vm.showAccountSwitcher')
  onShowSwitcherChanged(_monitor: IMonitor): void { this.notifyMenuState(); }

  @Monitor('vm.isRefreshing')
  onIsRefreshingChanged(_monitor: IMonitor): void { this.notifyMenuState(); }

  @Monitor('vm.accountOptions')
  onAccountOptionsChanged(_monitor: IMonitor): void { this.notifyMenuState(); }

  @Monitor('vm.selectedAccountIdx')
  onSelectedAccountIdxChanged(_monitor: IMonitor): void { this.notifyMenuState(); }

  private notifyMenuState(): void {
    this.onMenuStateChange(
      this.vm.showRefreshButton,
      this.vm.showAccountSwitcher,
      this.vm.isRefreshing,
      this.vm.accountOptions,
      this.vm.selectedAccountIdx
    );
  }

  @Monitor(CharactersViewModel.KEYS.networkErrorMsg)
  onNetworkError(_monitor: IMonitor): void {
    const msg = this.vm.networkErrorMsg;
    if (msg === '') { return; }
    this.vm.networkErrorMsg = '';
    const ctx = this.uiCtx;
    if (ctx === null) { return; }
    showFeedback(ctx, FeedbackType.ERROR, msg);
  }

  @Monitor(CharactersViewModel.KEYS.refreshCoolingDown)
  onRefreshCoolingDown(_monitor: IMonitor): void {
    const ctx = this.uiCtx;
    if (ctx === null) { return; }
    ctx.getPromptAction().showDialog({
      title: $r('app.string.characters_refresh_cooldown_title'),
      message: $r('app.string.characters_refresh_cooldown_msg'),
      buttons: [
        { text: $r('app.string.dialog_cancel'), color: $r('app.color.color_text_secondary') },
        { text: $r('app.string.dialog_sync'), color: $r('app.color.color_accent') }
      ]
    }).then((result) => {
      if (result.index === 1) { this.vm.forceRefresh(); }
    }).catch((e: BusinessError) => {
      Logger.warn('Characters', 'showDialog cooldown failed: ' + e.message);
    });
  }

  @Monitor(CharactersViewModel.KEYS.refreshResult)
  onRefreshResultChanged(_monitor: IMonitor): void {
    const result = this.vm.refreshResult;
    if (result === '') { return; }
    this.vm.refreshResult = '';
    const ctx = this.uiCtx;
    if (ctx === null) { return; }
    if (result === 'success') {
      showFeedback(ctx, FeedbackType.SUCCESS, $r('app.string.feedback_characters_refresh_success'));
    } else {
      showFeedback(ctx, FeedbackType.ERROR, $r('app.string.feedback_refresh_error'));
    }
  }

  /**
   * 点击角色卡片：由 ViewModel 决定路由目标，View 层只负责执行跳转。
   * 不支持跳转的游戏（如 honkai3）返回 null，静默忽略。
   */
  private onCardTap(character: GameDataSummary): void {
    const route = this.vm.buildCardTapRoute(character);
    if (route === null) { return; }
    if (this.isSplit) {
      this.detailStack.replacePath({ name: route.routeName, param: route.param });
    } else {
      this.detailStack.pushPath({ name: route.routeName, param: route.param });
    }
  }

  build() {
    CharactersContent({
      vm: this.vm,
      scroller: this.scroller,
      onCardTap: (c: GameDataSummary) => { this.onCardTap(c) },
      detailStack: this.detailStack,
      isSplit: this.isSplit
    })
  }
}
