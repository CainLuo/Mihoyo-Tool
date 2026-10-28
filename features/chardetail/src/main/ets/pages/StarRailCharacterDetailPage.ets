/**
 * StarRailCharacterDetailPage — 星穹铁道角色详情页（View 层）
 */
import display from '@ohos.display';
import { window, UIContext } from '@kit.ArkUI';
import { themeManager, ThemeManager, ViewState, showFeedback, FeedbackType } from 'basic';
import { StarRailCharacterDetailViewModel } from '../viewmodel/StarRailCharacterDetailViewModel';
import { CharDetailLoadingView } from '../views/common/CharDetailLoadingView';
import { CharDetailEmptyView } from '../views/common/CharDetailEmptyView';
import { StarRailCharDetailContent } from '../views/starrail/StarRailCharDetailContent';
import { StarRailCharDetailHero } from '../views/starrail/StarRailCharDetailHero';
import { StarRailCharDetailWideLayout } from '../views/starrail/StarRailCharDetailWideLayout';
import { CharDetailRouterParam } from '../model/CharDetailModels';

@ComponentV2
export struct StarRailCharacterDetailPage {
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

  @Monitor('vm.networkErrorMsg')
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

  private getHeroHeight(): number {
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
                StarRailCharDetailHero({ vm: this.vm, heroHeight: this.getHeroHeight() })
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
export struct StarRailCharacterDetailPagePreview {
  build() {
    StarRailCharacterDetailPage({ routerParam: new CharDetailRouterParam() })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function StarRailCharacterDetailPageBuilder(_name: string, param: Object) {
  StarRailCharacterDetailPage({ routerParam: param as CharDetailRouterParam })
}
