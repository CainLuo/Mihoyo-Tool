/**
 * ZZZCharacterDetail — 绝区零角色详情页（View 层）
 */
import display from '@ohos.display';
import { window, UIContext } from '@kit.ArkUI';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { ZZZCharacterDetailViewModel } from '../viewmodel/ZZZCharacterDetailViewModel';
import { CharDetailLoadingView } from '../components/chardetail/common/CharDetailLoadingView';
import { CharDetailEmptyView } from '../components/chardetail/common/CharDetailEmptyView';
import { ZZZCharDetailContent } from '../components/chardetail/zzz/ZZZCharDetailContent';
import { ZZZCharDetailHero } from '../components/chardetail/zzz/ZZZCharDetailHero';
import { ViewState } from '../constants/ViewStates';
import { CharDetailRouterParam } from '../models/CharDetailModels';

@ComponentV2
export struct ZZZCharacterDetail {
  @Param routerParam: CharDetailRouterParam = new CharDetailRouterParam();
  @Local private tm: ThemeManager = themeManager;
  @Local private vm: ZZZCharacterDetailViewModel = new ZZZCharacterDetailViewModel();
  @Local private windowWidthVp: number = themeManager.current.value360;
  @Local private windowHeightVp: number = 780;

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
          Scroll() {
            Column() {
              ZZZCharDetailHero({ vm: this.vm, heroHeight: this.heroHeight() })
              ZZZCharDetailContent({ vm: this.vm })
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
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.bgPageDeep)
    }
    .title($r('app.string.zzz_char_detail_title'))
    .hideTitleBar(false)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct ZZZCharacterDetailPreview {
  build() {
    ZZZCharacterDetail({ routerParam: new CharDetailRouterParam() })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function ZZZCharacterDetailBuilder(_name: string, param: Object) {
  ZZZCharacterDetail({ routerParam: param as CharDetailRouterParam })
}
