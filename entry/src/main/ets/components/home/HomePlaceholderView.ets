import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { AppRoutes } from '../../constants/AppRoutes'
import { RouterUtil } from '../../utils/RouterUtil'

@Preview
@ComponentV2
struct HomePlaceholderViewPreview {
  build() {
    HomePlaceholderView()
      .height(600)
      .backgroundColor('#F5F5F5')
  }
}

@ComponentV2
export struct HomePlaceholderView {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value20 }) {
      // 图标占位
      Text('🎮')
        .fontSize(this.tm.current.iconSizeXL)

      Column({ space: this.tm.current.value8 }) {
        Text($r('app.string.home_placeholder_title'))
          .font(this.tm.current.title18Bold)
          .fontColor(this.tm.current.colorTextPrimary)
          .textAlign(TextAlign.Center)

        Text($r('app.string.home_placeholder_desc'))
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextSecondary)
          .textAlign(TextAlign.Center)
          .padding({ left: this.tm.current.value40, right: this.tm.current.value40 })
      }

      Button($r('app.string.home_placeholder_button'))
        .fontSize(this.tm.current.body16Medium.size)
        .fontWeight(this.tm.current.body16Medium.weight)
        .fontColor(Color.White)
        .width(this.tm.current.widthButton)
        .height(this.tm.current.heightButton)
        .borderRadius(this.tm.current.radius12)
        .backgroundColor(this.tm.current.colorPrimary)
        .onClick(() => {
          RouterUtil.push(AppRoutes.LOGIN)
        })
    }
    .width(this.tm.current.widthFull)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
