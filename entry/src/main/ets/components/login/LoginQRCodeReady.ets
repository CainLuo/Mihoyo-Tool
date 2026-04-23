/**
 * LoginQRCodeReady — 二维码就绪/已扫码状态
 */
import { QRCodeStat } from '../../constants/LoginTabEnum';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct LoginQRCodeReady {
  @Param qrCodeUrl: string = '';
  @Param qrCodeStat: QRCodeStat = QRCodeStat.READY;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value16 }) {
      QRCode(this.qrCodeUrl)
        .width(this.tm.current.value200)
        .height(this.tm.current.value200)
        .color(this.tm.current.qrCodeFg)
        .backgroundColor(this.tm.current.qrCodeBg)

      if (this.qrCodeStat === QRCodeStat.SCANNED) {
        Text($r('app.string.login_qrcode_scanned'))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorPrimary)
      } else {
        Text($r('app.string.login_qrcode_hint'))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Center)
  }
}
