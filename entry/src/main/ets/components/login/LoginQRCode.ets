/**
 * LoginQRCode.ets — 二维码扫码登录组件
 *
 * 使用 ArkUI 内置 QRCode 组件本地生成二维码（传入米游社返回的 URL 字符串）。
 * ViewModel 负责轮询状态，View 层只做展示。
 */

import { LoginViewModel } from '../../viewmodel/LoginViewModel';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct LoginQRCode {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value16 }) {
      if (this.vm.qrCodeStat === 'loading') {
        this.buildLoading()
      } else if (this.vm.qrCodeStat === 'ready' || this.vm.qrCodeStat === 'scanned') {
        this.buildQRCode()
      } else if (this.vm.qrCodeStat === 'confirmed') {
        this.buildConfirmed()
      } else if (this.vm.qrCodeStat === 'expired' || this.vm.qrCodeStat === 'error') {
        this.buildExpired()
      }
    }
    .width(this.tm.current.widthFull)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildLoading() {
    LoadingProgress()
      .width(this.tm.current.progressSizeMD)
      .height(this.tm.current.progressSizeMD)
      .color(this.tm.current.colorPrimary)

    Text($r('app.string.login_qrcode_loading'))
      .font(this.tm.current.body13)
      .fontColor(this.tm.current.colorTextSecondary)
  }

  @Builder
  private buildQRCode() {
    // ArkUI 内置 QRCode 组件，传入 URL 字符串本地生成二维码
    QRCode(this.vm.qrCodeUrl)
      .width(this.tm.current.qrCodeSize)
      .height(this.tm.current.qrCodeSize)
      .color(this.tm.current.colorTextPrimary)
      .backgroundColor(this.tm.current.colorCardBg)

    if (this.vm.qrCodeStat === 'scanned') {
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

  @Builder
  private buildConfirmed() {
    Text($r('app.string.login_qrcode_confirmed'))
      .font(this.tm.current.body16Medium)
      .fontColor(this.tm.current.colorPrimary)

    LoadingProgress()
      .width(this.tm.current.progressSizeMD)
      .height(this.tm.current.progressSizeMD)
      .color(this.tm.current.colorPrimary)
  }

  @Builder
  private buildExpired() {
    Text($r('app.string.login_qrcode_expired'))
      .font(this.tm.current.body13)
      .fontColor(this.tm.current.colorTextSecondary)
      .textAlign(TextAlign.Center)

    Button($r('app.string.login_qrcode_refresh'), { type: ButtonType.Capsule })
      .width(this.tm.current.widthButtonSM)
      .height(this.tm.current.heightButton)
      .backgroundColor(this.tm.current.colorPrimary)
      .onClick(() => {
        this.vm.refreshQRCode();
      })
  }
}
