/**
 * HomePlaceholderView — 首页空态占位视图
 *
 * 在 HomeContent EMPTY 状态时展示，引导用户去登录账号。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { AppRoutes } from '../../constants/AppRoutes';
import { RouterUtil } from '../../utils/RouterUtil';

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

  build() {
    Column({ space: this.tm.current.value20 }) {
      // 图标占位
      Text('🎮')
        .fontSize(this.tm.current.value64)

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
        .fontColor(this.tm.current.textOnDarkHigh)
        .width(this.tm.current.pct90)
        .height(this.tm.current.value50)
        .borderRadius(this.tm.current.radius12)
        .backgroundColor(this.tm.current.colorPrimary)
        .onClick(() => {
          RouterUtil.push(AppRoutes.LOGIN)
        })
    }
    .width(this.tm.current.full)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
