/**
 * LoginQRCodeLoading — 二维码加载中状态
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct LoginQRCodeLoading {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value16 }) {
      LoadingProgress()
        .width(this.tm.current.value52)
        .height(this.tm.current.value52)
        .color(this.tm.current.colorPrimary)

      Text($r('app.string.login_qrcode_loading'))
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Center)
  }
}
