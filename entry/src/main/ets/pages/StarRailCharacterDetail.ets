/**
 * StarRailCharacterDetail — 星穹铁道角色详情页（View 层）
 */
import display from '@ohos.display';
import { window, UIContext } from '@kit.ArkUI';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { StarRailCharacterDetailViewModel } from '../viewmodel/StarRailCharacterDetailViewModel';
import { CharDetailLoadingView } from '../components/chardetail/common/CharDetailLoadingView';
import { CharDetailEmptyView } from '../components/chardetail/common/CharDetailEmptyView';
import { StarRailCharDetailContent } from '../components/chardetail/starrail/StarRailCharDetailContent';
import { StarRailCharDetailHero } from '../components/chardetail/starrail/StarRailCharDetailHero';
import { StarRailCharDetailWideLayout } from '../components/chardetail/starrail/StarRailCharDetailWideLayout';
import { ViewState } from '../constants/ViewStates';
import { CharDetailRouterParam } from '../models/CharDetailModels';
import { showFeedback } from '../utils/FeedbackUtil';
import { FeedbackType } from '../constants/FeedbackType';

@ComponentV2
export struct StarRailCharacterDetail {
  @Param routerParam: CharDetailRouterParam = new CharDetailRouterParam();
  @Local private tm: ThemeManager = themeManager;
  @Local private vm: StarRailCharacterDetailViewModel = new StarRailCharacterDetailViewModel();
  @Local private windowWidthVp: number = themeManager.current.value360;
  @Local private windowHeightVp: number = 780;
  @Local private currentBreakpoint: string = 'xs';

  private uiCtx: UIContext | null = null;

  private sizeCallback: (size: window.Size) => void = (size: window.Size) => {
    const ctx = this.uiCtx;
    if (ctx !== null) {
      this.windowWidthVp = ctx.px2vp(size.width);
      this.windowHeightVp = ctx.px2vp(size.height);
    }
  };

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext();
    const ctx = this.uiCtx;
    try {
      const d = display.getDefaultDisplaySync();
      this.windowWidthVp = ctx.px2vp(d.width);
      this.windowHeightVp = ctx.px2vp(d.height);
    } catch (_e) {}
    try {
      window.getLastWindow(ctx.getHostContext(), (err, win) => {
        if (err.code !== 0 || win === undefined) { return; }
        try { win.on('windowSizeChange', this.sizeCallback); } catch (_e) {}
      });
    } catch (_e) {}
    this.vm.init(this.routerParam.accountId, this.routerParam.roleUid, this.routerParam.entityId);
    this.vm.loadData();
  }

  @Monitor(StarRailCharacterDetailViewModel.KEYS.networkErrorMsg)
  onNetworkError(_monitor: IMonitor): void {
    const msg = this.vm.networkErrorMsg;
    if (msg === '') { return; }
    this.vm.networkErrorMsg = '';
    const ctx = this.uiCtx;
    if (ctx === null) { return; }
    showFeedback(ctx, FeedbackType.ERROR, msg);
  }

  aboutToDisappear(): void {
    const ctx = this.uiCtx;
    if (ctx === null) { return; }
    try {
      window.getLastWindow(ctx.getHostContext(), (err, win) => {
        if (err.code !== 0 || win === undefined) { return; }
        try { win.off('windowSizeChange', this.sizeCallback); } catch (_e) {}
      });
    } catch (_e) {}
  }

  private heroHeight(): number {
    return this.windowWidthVp <= this.windowHeightVp
      ? this.tm.current.value260
      : this.tm.current.value200;
  }

  build() {
    NavDestination() {
      Column() {
        if (this.vm.viewState === ViewState.LOADING) {
          CharDetailLoadingView()
        } else if (this.vm.viewState === ViewState.EMPTY || this.vm.viewState === ViewState.ERROR) {
          CharDetailEmptyView()
        } else {
          if (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') {
            StarRailCharDetailWideLayout({ vm: this.vm })
          } else {
            Scroll() {
              Column() {
                StarRailCharDetailHero({ vm: this.vm, heroHeight: this.heroHeight() })
                StarRailCharDetailContent({ vm: this.vm })
              }
              .width(this.tm.current.full)
            }
            .scrollBar(BarState.Off)
            .width(this.tm.current.full)
            .height(this.tm.current.full)
            .align(Alignment.Top)
            .edgeEffect(EdgeEffect.Spring)
          }
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.bgPageDeep)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .onAreaChange((_old, newArea) => {
        const w = newArea.width as number
        if (w < 600) { this.currentBreakpoint = 'xs' }
        else if (w < 840) { this.currentBreakpoint = 'sm' }
        else if (w < 1200) { this.currentBreakpoint = 'md' }
        else { this.currentBreakpoint = 'lg' }
      })
    }
    .title($r('app.string.starrail_char_detail_title'))
    .hideTitleBar(false)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct StarRailCharacterDetailPreview {
  build() {
    StarRailCharacterDetail({ routerParam: new CharDetailRouterParam() })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function StarRailCharacterDetailBuilder(_name: string, param: Object) {
  StarRailCharacterDetail({ routerParam: param as CharDetailRouterParam })
}
