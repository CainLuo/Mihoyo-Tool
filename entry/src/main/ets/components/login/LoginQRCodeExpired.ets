/**
 * LoginQRCodeExpired — 二维码已过期状态
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct LoginQRCodeExpired {
  @Param isLoading: boolean = false;
  @Param onRefresh: () => void = () => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Stack() {
      QRCode('https://user.mihoyo.com/qr_code_in_game.html?app_id=4&ticket=expired')
        .width(this.tm.current.value200)
        .height(this.tm.current.value200)
        .color(this.tm.current.qrCodeFg)
        .backgroundColor(this.tm.current.qrCodeBg)
        .opacity(this.tm.current.charDetailConsInactiveOpacity)

      Column({ space: this.tm.current.value12 }) {
        Text($r('app.string.login_qrcode_expired'))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextPrimary)
          .textAlign(TextAlign.Center)

        Button($r('app.string.login_qrcode_refresh'), { type: ButtonType.Capsule })
          .height(this.tm.current.value50)
          .backgroundColor(this.tm.current.colorPrimary)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.onRefresh();
          })
      }
      .width(this.tm.current.value200)
      .height(this.tm.current.value200)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.tm.current.surfaceDarkLg)
    }
    .width(this.tm.current.value200)
    .height(this.tm.current.value200)
  }
}
