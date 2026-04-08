/**
 * LoginQRCode.ets — 二维码扫码登录组件
 *
 * 使用 ArkUI 内置 QRCode 组件本地生成二维码（传入米游社返回的 URL 字符串）。
 * ViewModel 负责轮询状态，View 层只做展示。
 */

import { LoginViewModel } from '../../viewmodel/LoginViewModel';
import { QRCodeStat } from '../../constants/LoginTabEnum';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

// ── Preview：加载中 ──
@Preview
@ComponentV2
export struct LoginQRCodePreviewLoading {
  @Local private vm: LoginViewModel = (() => {
    const v = new LoginViewModel();
    v.qrCodeStat = QRCodeStat.LOADING;
    return v;
  })()
  build() {
    LoginQRCode({ vm: this.vm })
      .padding(themeManager.current.value24)
      .backgroundColor(themeManager.current.colorCardBg)
      .width(themeManager.current.value360)
  }
}

// ── Preview：二维码就绪 ──
@Preview
@ComponentV2
export struct LoginQRCodePreviewReady {
  @Local private vm: LoginViewModel = (() => {
    const v = new LoginViewModel();
    v.qrCodeStat = QRCodeStat.READY;
    v.qrCodeUrl = 'https://user.mihoyo.com/qr_code_in_game.html?app_id=4&ticket=mock_ticket_12345';
    return v;
  })()
  build() {
    LoginQRCode({ vm: this.vm })
      .padding(themeManager.current.value24)
      .backgroundColor(themeManager.current.colorCardBg)
      .width(themeManager.current.value360)
  }
}

// ── Preview：已扫码待确认 ──
@Preview
@ComponentV2
export struct LoginQRCodePreviewScanned {
  @Local private vm: LoginViewModel = (() => {
    const v = new LoginViewModel();
    v.qrCodeStat = QRCodeStat.SCANNED;
    v.qrCodeUrl = 'https://user.mihoyo.com/qr_code_in_game.html?app_id=4&ticket=mock_ticket_12345';
    return v;
  })()
  build() {
    LoginQRCode({ vm: this.vm })
      .padding(themeManager.current.value24)
      .backgroundColor(themeManager.current.colorCardBg)
      .width(themeManager.current.value360)
  }
}

// ── Preview：已过期 ──
@Preview
@ComponentV2
export struct LoginQRCodePreviewExpired {
  @Local private vm: LoginViewModel = (() => {
    const v = new LoginViewModel();
    v.qrCodeStat = QRCodeStat.EXPIRED;
    return v;
  })()
  build() {
    LoginQRCode({ vm: this.vm })
      .padding(themeManager.current.value24)
      .backgroundColor(themeManager.current.colorCardBg)
      .width(themeManager.current.value360)
  }
}

@ComponentV2
export struct LoginQRCode {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value16 }) {
      if (this.vm.qrCodeStat === QRCodeStat.LOADING) {
        this.buildLoading()
      } else if (this.vm.qrCodeStat === QRCodeStat.READY || this.vm.qrCodeStat === QRCodeStat.SCANNED) {
        this.buildQRCode()
      } else if (this.vm.qrCodeStat === QRCodeStat.CONFIRMED) {
        this.buildConfirmed()
      } else if (this.vm.qrCodeStat === QRCodeStat.EXPIRED || this.vm.qrCodeStat === QRCodeStat.ERROR) {
        this.buildExpired()
      }
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildLoading() {
    LoadingProgress()
      .width(this.tm.current.value52)
      .height(this.tm.current.value52)
      .color(this.tm.current.colorPrimary)

    Text($r('app.string.login_qrcode_loading'))
      .font(this.tm.current.body13)
      .fontColor(this.tm.current.colorTextSecondary)
  }

  @Builder
  private buildQRCode() {
    // ArkUI 内置 QRCode 组件，传入 URL 字符串本地生成二维码
    QRCode(this.vm.qrCodeUrl)
      .width(this.tm.current.value200)
      .height(this.tm.current.value200)
      .color(this.tm.current.qrCodeFg)
      .backgroundColor(this.tm.current.qrCodeBg)

    if (this.vm.qrCodeStat === QRCodeStat.SCANNED) {
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
      .width(this.tm.current.value52)
      .height(this.tm.current.value52)
      .color(this.tm.current.colorPrimary)
  }

  @Builder
  private buildExpired() {
    // 底层：低透明度的占位二维码（视觉上表示"有二维码但已失效"）
    // 上层：半透明遮罩 + 过期提示 + 刷新按钮
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
          .enabled(!this.vm.isLoading)
          .onClick(() => {
            this.vm.refreshQRCode();
          })
      }
      .width(this.tm.current.value200)
      .height(this.tm.current.value200)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.tm.current.surfaceDark2xl)
    }
    .width(this.tm.current.value200)
    .height(this.tm.current.value200)
  }
}
