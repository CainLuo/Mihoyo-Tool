/**
 * Tools.ets — 工具页主页面
 *
 * 展示三个游戏的材料总汇入口，处理空态。
 * 作为 Tab 子页面嵌入 Main。
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { ViewState } from '../constants/ViewStates'
import { ToolsViewModel } from '../viewmodel/ToolsViewModel'
import { PlaceholderView, PlaceholderState } from '../components/common/PlaceholderView'
import { GameEntryCard } from '../components/tools/GameEntryCard'
import { AppRoutes } from '../constants/AppRoutes'
import { AccountSignal } from '../utils/AccountSignal'
import { GameId } from 'core'
import { GameEntryVM, MaterialTargetConfigParam } from '../models/ToolsModels'

@ComponentV2
export struct Tools {
  @Local private vm: ToolsViewModel = new ToolsViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private signal: AccountSignal = AccountSignal.instance()
  /** Navigation stack from Main */
  @Param detailStack: NavPathStack | null = null

  aboutToAppear(): void {
    this.vm.loadData()
  }

  @Monitor('signal.version')
  onAccountDataChanged(_monitor: IMonitor): void {
    this.vm.loadData()
  }

  build() {
    Column() {
      if (this.vm.viewState === ViewState.LOADING) {
        // 加载中视图 — 只有 5 行，直接内联
        Column() {
          LoadingProgress()
            .width(this.tm.current.value32)
            .height(this.tm.current.value32)
            .color(this.tm.current.colorPrimary)
        }
        .width(this.tm.current.full)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.vm.viewState === ViewState.EMPTY) {
        // 空态视图
        PlaceholderView({
          state: {
            icon: '🧰',
            title: $r('app.string.home_placeholder_title'),
            description: $r('app.string.home_placeholder_desc'),
            buttonText: $r('app.string.home_placeholder_button'),
            onButtonTap: () => {
              if (this.detailStack !== null) {
                this.detailStack.pushPathByName(AppRoutes.LOGIN, null)
              }
            }
          } as PlaceholderState
        })
      } else {
        // 内容视图 — 游戏入口列表
        Scroll() {
          Column({ space: this.tm.current.value12 }) {
            ForEach(this.vm.gameEntries, (entry: GameEntryVM) => {
              GameEntryCard({
                entry: entry,
                onTap: () => {
                  this.onEntryTap(entry)
                }
              })
            }, (entry: GameEntryVM) => entry.gameId)
          }
          .width(this.tm.current.full)
          .padding({
            top: this.tm.current.value8,
            left: this.tm.current.value16,
            right: this.tm.current.value16,
            bottom: this.tm.current.value16
          })
        }
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Top)
      }
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .backgroundColor(this.tm.current.colorPageBg)
  }

  /**
   * 游戏入口点击处理
   */
  private onEntryTap(entry: GameEntryVM): void {
    if (!entry.hasData) {
      return
    }
    if (this.detailStack !== null) {
      const params: MaterialTargetConfigParam = { gameId: entry.gameId }
      this.detailStack.pushPathByName(AppRoutes.MATERIAL_TARGET_CONFIG, params)
    }
  }
}

@Preview
@ComponentV2
export struct ToolsPreview {
  build() {
    Tools()
  }
}
