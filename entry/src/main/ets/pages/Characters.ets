/**
 * Characters — 角色 Tab 页（View 层）
 *
 * 布局：
 *   NavBar（标题 + 账号选择器 + 刷新按钮）
 *   游戏 Tab 选择器（横向滚动，仅当前账号有角色的游戏）
 *   内容区（loading → 骨架屏 | empty → Placeholder | data → GridRow）
 *
 * 多账号：NavBar 右侧 Select 组件切换账号
 * 多游戏：游戏 Tab 切换，每个 Tab 对应一个 gameId + roleUid
 */

import { BusinessError } from '@kit.BasicServicesKit';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { CharactersViewModel } from '../viewmodel/CharactersViewModel';
import { GameDataSummary } from 'core';
import { HomePlaceholderView } from '../components/home/HomePlaceholderView';
import { CharacterCard } from '../components/characters/CharacterCard';
import { CharactersSkeleton } from '../components/characters/CharactersSkeleton';
import { GameTabBar } from '../components/characters/GameTabBar';
import { ViewState } from '../constants/ViewStates';
import { Logger } from '../utils/Logger';
import { AppConstants } from '../constants/AppConstants';

@ComponentV2
export struct Characters {
  @Local private tm: ThemeManager = themeManager;
  @Local private vm: CharactersViewModel = new CharactersViewModel();
  /** 当前断点：xs = Phone，sm/md/lg = 非 Phone */
  @Local private currentBreakpoint: string = 'xs';
  private uiCtx: UIContext | null = null;

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext();
    this.vm.loadData();
  }

  @Monitor(CharactersViewModel.KEYS.networkErrorMsg)
  onNetworkError(_monitor: IMonitor): void {
    const msg = this.vm.networkErrorMsg;
    if (msg === '') {
      return;
    }
    this.vm.networkErrorMsg = '';
    const ctx = this.uiCtx;
    if (ctx === null) {
      return;
    }
    ctx.getPromptAction().showDialog({
      title: $r('app.string.home_network_error_title'),
      message: msg,
      buttons: [{ text: $r('app.string.dialog_confirm'), color: $r('app.color.color_accent') }]
    }).catch((e: BusinessError) => {
      Logger.warn('Characters', 'showDialog failed: ' + e.message);
    });
  }

  build() {
    Column() {
      // ── NavBar ────────────────────────────────────────────────
      Row() {
        Text($r('app.string.characters_tab_title'))
          .font(this.tm.current.title24Bold)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)
          .padding({ left: this.tm.current.value16 })

        // 账号选择器（多账号时显示）
        if (this.vm.accountOptions.length > 1) {
          Select(CharactersViewModel.toSelectOptions(this.vm.accountOptions))
            .selected(this.vm.selectedAccountIdx)
            .value(this.vm.accountOptions.length > 0
              ? this.vm.accountOptions[this.vm.selectedAccountIdx].username
              : '')
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextPrimary)
            .onSelect((idx: number) => {
              this.vm.selectAccount(idx);
            })
        }

        // 刷新按钮
        if (this.vm.viewState === ViewState.DATA) {
          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.ic_refresh'))
              .width(this.tm.current.iconSizeMD)
              .height(this.tm.current.iconSizeMD)
              .fillColor(this.vm.isRefreshing
                ? this.tm.current.colorTextSecondary
                : this.tm.current.colorTextPrimary)
          }
          .width(this.tm.current.heightNavBar)
          .height(this.tm.current.heightNavBar)
          .backgroundColor(Color.Transparent)
          .enabled(!this.vm.isRefreshing)
          .onClick(() => { this.vm.refresh(); })
        } else {
          Row().width(this.tm.current.heightNavBar)
        }
      }
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightNavBar)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.tm.current.colorCardBg)

      Divider().color(this.tm.current.colorDivider)

      // ── 游戏 Tab（有多个游戏时显示） ─────────────────────────
      if (this.vm.gameTabs.length > 1) {
        GameTabBar({
          tabs: this.vm.gameTabs,
          selectedIdx: this.vm.selectedGameIdx,
          onSelect: (idx: number) => { this.vm.selectGame(idx); }
        })
        Divider().color(this.tm.current.colorDivider)
      }

      // ── 内容区 ────────────────────────────────────────────────
      if (this.vm.viewState === ViewState.LOADING) {
        Scroll() {
          Column({ space: this.tm.current.value16 }) {
            CharactersSkeleton()
          }
          .width(this.tm.current.widthFull)
          .padding({ top: this.tm.current.value16 })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Top)
      } else if (this.vm.viewState === ViewState.EMPTY) {
        if (this.vm.accountOptions.length === 0) {
          HomePlaceholderView()
        } else {
          Column({ space: this.tm.current.value20 }) {
            Text('📋')
              .fontSize(this.tm.current.iconSizeXL)
            Column({ space: this.tm.current.value8 }) {
              Text($r('app.string.characters_placeholder_title'))
                .font(this.tm.current.title18Bold)
                .fontColor(this.tm.current.colorTextPrimary)
                .textAlign(TextAlign.Center)
              Text($r('app.string.characters_placeholder_desc'))
                .font(this.tm.current.body16)
                .fontColor(this.tm.current.colorTextSecondary)
                .textAlign(TextAlign.Center)
                .padding({ left: this.tm.current.value40, right: this.tm.current.value40 })
            }
            Button($r('app.string.characters_no_data_hint'))
              .fontSize(this.tm.current.body16Medium.size)
              .fontWeight(this.tm.current.body16Medium.weight)
              .fontColor(Color.White)
              .width(this.tm.current.widthButton)
              .height(this.tm.current.heightButton)
              .borderRadius(this.tm.current.radius12)
              .backgroundColor(this.tm.current.colorPrimary)
              .onClick(() => { this.vm.refresh(); })
          }
          .width(this.tm.current.widthFull)
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      } else {
        Scroll() {
          Column({ space: this.tm.current.value16 }) {
            GridRow({
              columns: { xs: 2, sm: 3, md: 4, lg: 5 },
              gutter: { x: this.tm.current.value12, y: this.tm.current.value12 },
              breakpoints: {
                value: AppConstants.GRID_BREAKPOINTS,
                reference: BreakpointsReference.WindowSize
              }
            }) {
              ForEach(this.vm.characters, (character: GameDataSummary) => {
                GridCol({ span: 1 }) {
                  CharacterCard({
                    character: character,
                    isPhone: this.currentBreakpoint === 'xs',
                    breakpoint: this.currentBreakpoint,
                    gameId: this.vm.gameTabs.length > 0 ? this.vm.gameTabs[this.vm.selectedGameIdx].gameId : 'genshin',
                    roleUid: this.vm.gameTabs.length > 0 ? this.vm.gameTabs[this.vm.selectedGameIdx].roleUid : ''
                  })
                }
              }, (character: GameDataSummary) => character.entityId)
            }
            .width(this.tm.current.widthFull)
            .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
            .onBreakpointChange((bp: string) => {
              this.currentBreakpoint = bp;
            })

            Row().height(this.tm.current.value40)
          }
          .width(this.tm.current.widthFull)
          .padding({ top: this.tm.current.value16 })
        }
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Top)
      }
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}
