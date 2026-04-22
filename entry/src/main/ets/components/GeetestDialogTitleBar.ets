/**
 * GeetestDialogTitleBar — Geetest 弹窗标题栏（标题 + 关闭按钮）
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'

@ComponentV2
export struct GeetestDialogTitleBar {
  @Param onClose: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Row() {
      Text($r('app.string.geetest_dialog_title'))
        .font(this.tm.current.body16Medium)
        .fontColor(this.tm.current.colorTextPrimary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      Button({ type: ButtonType.Circle }) {
        Text($r('app.string.geetest_dialog_close'))
          .font(this.tm.current.title18Bold)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.value56)
      .height(this.tm.current.value56)
      .backgroundColor(this.tm.current.colorTransparent)
      .onClick(() => { this.onClose() })
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value16,
      right: this.tm.current.value8,
      top: this.tm.current.value12,
      bottom: this.tm.current.value12
    })
  }
}
