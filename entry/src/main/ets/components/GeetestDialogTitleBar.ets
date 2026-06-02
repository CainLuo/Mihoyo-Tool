/**
 * GeetestDialogTitleBar — Geetest 弹窗标题栏（标题 + 关闭按钮）
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { ThemeFonts } from '../theme/ThemeFonts'

@ComponentV2
export struct GeetestDialogTitleBar {
  @Param onClose: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Row() {
      Text($r('app.string.geetest_dialog_title'))
        .font(ThemeFonts.fontMedium17)
        .fontColor(this.tm.current.colorTextPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      Button({ type: ButtonType.Circle }) {
        Text($r('app.string.geetest_dialog_close'))
          .font(ThemeFonts.fontBold18)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.value56)
      .height(this.tm.current.value56)
      .backgroundColor(Color.Transparent)
      .onClick(() => { this.onClose() })
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.font16,
      right: this.tm.current.value8,
      top: this.tm.current.value12,
      bottom: this.tm.current.value12
    })
  }
}
