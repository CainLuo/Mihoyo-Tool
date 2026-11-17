/**
 * LoginQRCodeReady — 二维码就绪/已扫码状态
 */
import { QRCodeStat } from '../constants/LoginConstants';
import { ThemeFonts, themeManager, ThemeManager } from 'basic'

@ComponentV2
export struct LoginQRCodeReady {
  @Param qrCodeUrl: string = '';
  @Param qrCodeStat: QRCodeStat = QRCodeStat.READY;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.font16 }) {
      QRCode(this.qrCodeUrl)
        .width(this.tm.current.value200)
        .height(this.tm.current.value200)
        .color(this.tm.current.qrCodeFg)
        .backgroundColor(this.tm.current.qrCodeBg)

      if (this.qrCodeStat === QRCodeStat.SCANNED) {
        Text($r('app.string.login_qrcode_scanned'))
          .font(ThemeFonts.FONT_14)
          .fontColor(this.tm.current.colorPrimary)
      } else {
        Text($r('app.string.login_qrcode_hint'))
          .font(ThemeFonts.FONT_14)
          .fontColor(this.tm.current.colorTextSecondary)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Center)
  }
}
