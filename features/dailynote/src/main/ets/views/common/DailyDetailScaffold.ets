/**
 * DailyDetailScaffold — 三游戏便笺详情页共用骨架
 *
 * 统一 NavDestination 标题栏、LOADING / EMPTY+ERROR / DATA 三态分支与滚动容器；
 * 游戏内容通过 content 插槽注入，页面只保留参数、ViewModel 与内容组件。
 */
import { themeManager, ThemeFonts, ThemeManager, ViewState } from 'basic'
import { DailyNoteEmptyView } from './DailyNoteEmptyView'
import { DailyNoteLoadingView } from './DailyNoteLoadingView'

@Builder
function emptyContent() {}

@ComponentV2
export struct DailyDetailScaffold {
  /** 标题栏文案 */
  @Param title: ResourceStr = ''
  /** 页面 ViewModel 的加载状态 */
  @Param viewState: ViewState = ViewState.LOADING
  /** 游戏内容插槽（仅在 DATA 态渲染） */
  @BuilderParam content: () => void = emptyContent

  @Local private tm: ThemeManager = themeManager

  build() {
    NavDestination() {
      Column() {
        if (this.viewState === ViewState.LOADING) {
          DailyNoteLoadingView()
        } else if (this.viewState === ViewState.EMPTY || this.viewState === ViewState.ERROR) {
          DailyNoteEmptyView()
        } else {
          Scroll() {
            Column({ space: this.tm.current.value8 }) {
              Text($r('app.string.genshin_daily_data_delay_hint'))
                .font(ThemeFonts.FONT_14)
                .fontColor(this.tm.current.colorTextSecondary)
                .width(this.tm.current.full)
                .padding({
                  left: this.tm.current.font16,
                  right: this.tm.current.font16,
                  top: this.tm.current.value12
                })

              this.content()
            }
            .width(this.tm.current.full)
            .constraintSize({ maxWidth: this.tm.current.value600 })
            .padding({ bottom: this.tm.current.value40 })
            .alignSelf(ItemAlign.Center)
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .width(this.tm.current.full)
          .align(Alignment.Top)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.colorPageBg)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .title(this.title)
    .hideTitleBar(false)
  }
}
