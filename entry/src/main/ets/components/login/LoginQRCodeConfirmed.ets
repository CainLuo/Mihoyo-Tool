/**
 * LoginQRCodeConfirmed — 二维码已确认登录状态
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { ThemeFonts } from '../../theme/ThemeFonts'

@ComponentV2
export struct LoginQRCodeConfirmed {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.font16 }) {
      Text($r('app.string.login_qrcode_confirmed'))
        .font(ThemeFonts.fontMedium17)
        .fontColor(this.tm.current.colorPrimary)

      LoadingProgress()
        .width(this.tm.current.value52)
        .height(this.tm.current.value52)
        .color(this.tm.current.colorPrimary)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Center)
  }
}
