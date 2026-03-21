/**
 * GenshinCharacterDetail — 角色详情页（View 层）
 *
 * 布局策略（对应 char-detail.html 原型）：
 *   Phone 竖屏（xs）：立绘区固定高 260vp + 下方滚动区（武器+属性+圣遗物）
 *   Phone 横屏（xs 且 windowH < windowW）：左侧立绘 200vp 固定宽 + 右侧滚动区
 *   宽屏（sm/md/lg）：三栏等分（立绘 | 武器+属性 | 圣遗物），8vp padding + gap
 *
 * 通过 HMRouter 路由参数接收 gameId + roleUid + entityId。
 */

import display from '@ohos.display';
import { window, UIContext } from '@kit.ArkUI';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailHeroPanel } from '../components/chardetail/CharDetailHeroPanel';
import { CharDetailStatsPanel } from '../components/chardetail/CharDetailStatsPanel';
import { CharDetailRelicsPanel } from '../components/chardetail/CharDetailRelicsPanel';
import { ViewState } from '../constants/ViewStates';

/** HMRouter 传入的路由参数 */
export class GenshinCharacterDetailParam {
  gameId: string = 'genshin';
  roleUid: string = '';
  entityId: string = '';
}

@ComponentV2
export struct GenshinCharacterDetail {
  @Param routerParam: GenshinCharacterDetailParam = new GenshinCharacterDetailParam();
  @Local private tm: ThemeManager = themeManager;
  @Local private vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Local private windowWidthVp: number = themeManager.current.windowWidthDefault;
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

    this.vm.init(this.routerParam.gameId, this.routerParam.roleUid, this.routerParam.entityId);
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

  /** 是否 Phone 横屏（宽 > 高 且 xs 断点） */
  private isPhoneLandscape(): boolean {
    return this.currentBreakpoint === 'xs' && this.windowWidthVp > this.windowHeightVp;
  }

  /** 是否 Phone 竖屏 */
  private isPhonePortrait(): boolean {
    return this.currentBreakpoint === 'xs' && this.windowWidthVp <= this.windowHeightVp;
  }

  /** 加载中 */
  @Builder
  LoadingView() {
    Row() {
      LoadingProgress()
        .width(this.tm.current.progressSizeMD)
        .height(this.tm.current.progressSizeMD)
        .color(this.tm.current.colorPrimary)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .justifyContent(FlexAlign.Center)
  }

  /** 空态/错误 */
  @Builder
  EmptyView() {
    Row() {
      Text($r('app.string.char_detail_no_data'))
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .justifyContent(FlexAlign.Center)
  }

  /** Phone 竖屏布局 */
  @Builder
  PortraitLayout() {
    Column() {
      // 立绘区（固定高度）
      CharDetailHeroPanel({ vm: this.vm, mode: 'portrait' })
        .height(this.tm.current.charDetailHeroPanelPortraitH)
        .width(this.tm.current.widthFull)

      // 滚动区
      Scroll() {
        Column({ space: this.tm.current.value8 }) {
          CharDetailStatsPanel({ vm: this.vm, isPhone: true, phoneCols: 2 })
          // 圣遗物标题
          Text($r('app.string.character_no_relics'))
            .fontSize(this.tm.current.body12.size)
            .fontColor('rgba(255,255,255,0.5)')
            .width(this.tm.current.widthFull)
            .padding({ left: this.tm.current.value10, top: this.tm.current.value4 })
            .visibility(this.vm.relics.length === 0 ? Visibility.Visible : Visibility.None)
          CharDetailRelicsPanel({ vm: this.vm, isPhone: true })
            .padding({ left: this.tm.current.value10, right: this.tm.current.value10 })
          // 底部留白
          Row().height(this.tm.current.value8)
        }
        .width(this.tm.current.widthFull)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
  }

  /** Phone 横屏布局 */
  @Builder
  LandscapeLayout() {
    Row() {
      // 左侧立绘（固定宽度）
      CharDetailHeroPanel({ vm: this.vm, mode: 'landscape' })
        .width(this.tm.current.charDetailHeroPanelLandscapeW)
        .height(this.tm.current.heightFull)

      // 右侧滚动区
      Scroll() {
        Column({ space: this.tm.current.value8 }) {
          CharDetailStatsPanel({ vm: this.vm, isPhone: true, phoneCols: 4 })
          CharDetailRelicsPanel({ vm: this.vm, isPhone: true })
            .padding({ left: this.tm.current.value8, right: this.tm.current.value8 })
          Row().height(this.tm.current.value20)
        }
        .width(this.tm.current.widthFull)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .height(this.tm.current.heightFull)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
  }

  /** 宽屏三栏布局 */
  @Builder
  WideLayout() {
    Row({ space: this.tm.current.value8 }) {
      // 左栏：立绘
      CharDetailHeroPanel({ vm: this.vm, mode: 'wide' })
        .layoutWeight(1)
        .height(this.tm.current.heightFull)
        .borderRadius(this.tm.current.radius8)
        .clip(true)

      // 中栏：武器 + 属性
      CharDetailStatsPanel({ vm: this.vm, isPhone: false })
        .layoutWeight(1)
        .height(this.tm.current.heightFull)

      // 右栏：圣遗物
      CharDetailRelicsPanel({ vm: this.vm, isPhone: false })
        .layoutWeight(1)
        .height(this.tm.current.heightFull)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .padding(this.tm.current.value8)
  }

  build() {
    Column() {
      if (this.vm.viewState === ViewState.LOADING) {
        this.LoadingView()
      } else if (this.vm.viewState === ViewState.EMPTY || this.vm.viewState === ViewState.ERROR) {
        this.EmptyView()
      } else {
        // 根据断点和方向选择布局
        if (this.isPhonePortrait()) {
          this.PortraitLayout()
        } else if (this.isPhoneLandscape()) {
          this.LandscapeLayout()
        } else {
          this.WideLayout()
        }
      }
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .backgroundColor('#0d0d18')
    .onAreaChange((_old, newArea) => {
      // 通过 onAreaChange 感知断点变化（GridRow 不在此页面，手动判断）
      const w = newArea.width as number;
      if (w < 600) {
        this.currentBreakpoint = 'xs';
      } else if (w < 840) {
        this.currentBreakpoint = 'sm';
      } else if (w < 1200) {
        this.currentBreakpoint = 'md';
      } else {
        this.currentBreakpoint = 'lg';
      }
    })
  }
}
