/**
 * CharDetailLoadingView — 角色详情加载中视图
 */
import { ThemeManager, themeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct CharDetailLoadingView {
  @Param tm: ThemeManager = new ThemeManager()

  build() {
    Row() {
      LoadingProgress()
        .width(this.tm.current.value52)
        .height(this.tm.current.value52)
        .color(this.tm.current.colorPrimary)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .justifyContent(FlexAlign.Center)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct CharDetailLoadingViewPreview {
  build() {
    Column() {
      CharDetailLoadingView({ tm: themeManager })
    }
    .width('100%')
    .height(200)
    .backgroundColor('#1a1a2e')
  }
}
