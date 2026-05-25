/**
 * HomePlaceholderView — 首页空态占位视图
 *
 * 在 HomeContent EMPTY 状态时展示，引导用户去登录账号。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { ThemeFonts } from '../../theme/ThemeFonts'

@Preview
@ComponentV2
export struct HomePlaceholderViewPreview {
  build() {
    HomePlaceholderView()
      .height(themeManager.current.value600)
      .backgroundColor(themeManager.current.colorPageBg)
  }
}

@ComponentV2
export struct HomePlaceholderView {
  @Local private tm: ThemeManager = themeManager
  /** 点击按钮的回调，由父级决定跳转方式（分栏 replace / 单栏 push） */
  @Param onTap: () => void = () => {}

  build() {
    Column({ space: this.tm.current.font20 }) {
      // 图标占位
      Text('🎮')
        .fontSize(this.tm.current.value64)

      Column({ space: this.tm.current.value8 }) {
        Text($r('app.string.home_placeholder_title'))
          .font(ThemeFonts.fontBold18)
          .fontColor(this.tm.current.colorTextPrimary)
          .textAlign(TextAlign.Center)

        Text($r('app.string.home_placeholder_desc'))
          .font(ThemeFonts.font17)
          .fontColor(this.tm.current.colorTextSecondary)
          .textAlign(TextAlign.Center)
          .padding({ left: this.tm.current.value40, right: this.tm.current.value40 })
      }

      Button($r('app.string.home_placeholder_button'))
        .fontSize(this.tm.current.fontMedium17)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.tm.current.textOnDarkHigh)
        .width(this.tm.current.pct90)
        .height(this.tm.current.value50)
        .borderRadius(this.tm.current.radius12)
        .backgroundColor(this.tm.current.colorPrimary)
        .onClick(() => {
          this.onTap()
        })
    }
    .width(this.tm.current.full)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
