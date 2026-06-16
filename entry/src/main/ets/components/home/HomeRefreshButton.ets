/**
 * HomeRefreshButton — 首页右上角刷新按钮
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ViewState } from '../../constants/ViewStates'

@ComponentV2
export struct HomeRefreshButton {
  @Param viewState: ViewState = ViewState.LOADING
  @Param isRefreshing: boolean = false
  @Param onRefresh: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    if (this.viewState === ViewState.DATA) {
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_refresh'))
          .width(this.tm.current.value22)
          .height(this.tm.current.value22)
          .fillColor(this.isRefreshing
            ? this.tm.current.colorTextSecondary
            : this.tm.current.colorTextPrimary)
      }
      .width(this.tm.current.value56)
      .height(this.tm.current.value56)
      .backgroundColor(Color.Transparent)
      .enabled(!this.isRefreshing)
      .onClick(() => { this.onRefresh() })
    }
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct HomeRefreshButtonPreview {
  build() {
    Row({ space: 16 }) {
      HomeRefreshButton({ viewState: ViewState.DATA, isRefreshing: false })
      HomeRefreshButton({ viewState: ViewState.DATA, isRefreshing: true })
      HomeRefreshButton({ viewState: ViewState.LOADING, isRefreshing: false })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
