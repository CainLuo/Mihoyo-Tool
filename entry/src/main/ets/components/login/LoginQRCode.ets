/**
 * LoginQRCode.ets — 二维码扫码登录组件
 *
 * 使用 ArkUI 内置 QRCode 组件本地生成二维码（传入米游社返回的 URL 字符串）。
 * ViewModel 负责轮询状态，View 层只做展示。
 */

import { LoginViewModel } from 'entry/ets/viewmodel/LoginViewModel';
import { QRCodeStat } from '../../constants/LoginTabEnum';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { LoginQRCodeLoading } from './LoginQRCodeLoading';
import { LoginQRCodeReady } from './LoginQRCodeReady';
import { LoginQRCodeConfirmed } from './LoginQRCodeConfirmed';
import { LoginQRCodeExpired } from './LoginQRCodeExpired';

@ComponentV2
export struct LoginQRCode {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value16 }) {
      if (this.vm.qrCodeStat === QRCodeStat.LOADING) {
        LoginQRCodeLoading()
      } else if (this.vm.qrCodeStat === QRCodeStat.READY || this.vm.qrCodeStat === QRCodeStat.SCANNED) {
        LoginQRCodeReady({ qrCodeUrl: this.vm.qrCodeUrl, qrCodeStat: this.vm.qrCodeStat })
      } else if (this.vm.qrCodeStat === QRCodeStat.CONFIRMED) {
        LoginQRCodeConfirmed()
      } else if (this.vm.qrCodeStat === QRCodeStat.EXPIRED || this.vm.qrCodeStat === QRCodeStat.ERROR) {
        LoginQRCodeExpired({
          isLoading: this.vm.isLoading,
          onRefresh: () => { this.vm.refreshQRCode(); }
        })
      }
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Center)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct LoginQRCodePreviewLoading {
  @Local private vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  aboutToAppear(): void {
    this.vm.qrCodeStat = QRCodeStat.LOADING;
  }

  build() {
    LoginQRCode({ vm: this.vm })
      .padding(this.tm.current.value24)
      .backgroundColor(this.tm.current.colorPageBg)
      .width(this.tm.current.value360)
  }
}

@Preview
@ComponentV2
export struct LoginQRCodePreviewReady {
  @Local private vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  aboutToAppear(): void {
    this.vm.qrCodeStat = QRCodeStat.READY;
    this.vm.qrCodeUrl = 'https://user.mihoyo.com/qr_code_in_game.html?app_id=4&ticket=mock_ticket_12345';
  }

  build() {
    LoginQRCode({ vm: this.vm })
      .padding(this.tm.current.value24)
      .backgroundColor(this.tm.current.colorPageBg)
      .width(this.tm.current.value360)
  }
}

@Preview
@ComponentV2
export struct LoginQRCodePreviewExpired {
  @Local private vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  aboutToAppear(): void {
    this.vm.qrCodeStat = QRCodeStat.EXPIRED;
  }

  build() {
    LoginQRCode({ vm: this.vm })
      .padding(this.tm.current.value24)
      .backgroundColor(this.tm.current.colorPageBg)
      .width(this.tm.current.value360)
  }
}
