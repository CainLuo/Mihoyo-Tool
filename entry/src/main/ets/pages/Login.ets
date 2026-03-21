/**
 * Login.ets — 登录页
 *
 * 三种登录方式通过 Tab 切换：
 *   - 手机号（国服）
 *   - 二维码（国服）
 *   - 手动 Cookie
 *
 * 国际服（HoYoLAB）：逻辑已在 AuthRepository 预留占位，完成度 0%，UI 暂不展示。
 *
 * 路由：由 HMRouter 管理，通过 AppRoutes.LOGIN 跳转。
 * 登录成功后：监听 vm.loginSuccess，调用 HMRouterMgr.pop() 返回上一页。
 */

import { HMRouterMgr } from '@hadss/hmrouter';
import { LoginViewModel, LoginTab } from '../viewmodel/LoginViewModel';
import { LoginPhone } from '../components/login/LoginPhone';
import { LoginQRCode } from '../components/login/LoginQRCode';
import { LoginCookie } from '../components/login/LoginCookie';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { Logger } from '../utils/Logger';

const TAG: string = 'Login';

@ComponentV2
export struct Login {
  @Local private vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  aboutToAppear(): void {
    // 默认进入手机号 Tab，不需要额外初始化
  }

  aboutToDisappear(): void {
    this.vm.dispose();
  }

  @Monitor(LoginViewModel.KEYS.loginSuccess)
  onLoginSuccess(): void {
    if (this.vm.loginSuccess) {
      Logger.info(TAG, 'login success, pop back');
      HMRouterMgr.pop();
    }
  }

  build() {
    Scroll() {
      Column({ space: this.tm.current.value40 }) {
        // Tab 切换栏
        this.buildTabBar()

        // Tab 内容区
        this.buildTabContent()
      }
      .width(this.tm.current.widthFull)
      .constraintSize({ maxWidth: this.tm.current.contentMaxWidth })
      .padding({
        left: this.tm.current.value20,
        right: this.tm.current.value20,
        top: this.tm.current.value20,
        bottom: this.tm.current.value40
      })
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .align(Alignment.Top)
    .backgroundColor(this.tm.current.colorPageBg)
  }

  @Builder
  private buildTabBar() {
    Row({ space: this.tm.current.value4 }) {
      this.buildTabItem('phone', $r('app.string.login_tab_phone'))
      this.buildTabItem('qrcode', $r('app.string.login_tab_qrcode'))
      this.buildTabItem('cookie', $r('app.string.login_tab_cookie'))
    }
    .width(this.tm.current.widthFull)
    .backgroundColor(this.tm.current.colorCardBg)
    .borderRadius(this.tm.current.radius8)
    .padding(this.tm.current.value4)
  }

  @Builder
  private buildTabItem(tab: LoginTab, label: Resource) {
    Text(label)
      .font(this.tm.current.body13)
      .fontColor(this.vm.activeTab === tab
        ? this.tm.current.colorCardBg
        : this.tm.current.colorTextSecondary)
      .backgroundColor(this.vm.activeTab === tab
        ? this.tm.current.colorPrimary
        : Color.Transparent)
      .borderRadius(this.tm.current.radius8)
      .padding({
        left: this.tm.current.value12,
        right: this.tm.current.value12,
        top: this.tm.current.value8,
        bottom: this.tm.current.value8
      })
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.vm.switchTab(tab);
      })
  }

  @Builder
  private buildTabContent() {
    Column() {
      if (this.vm.activeTab === 'phone') {
        LoginPhone({ vm: this.vm })
      } else if (this.vm.activeTab === 'qrcode') {
        LoginQRCode({ vm: this.vm })
      } else {
        LoginCookie({ vm: this.vm })
      }
    }
    .width(this.tm.current.widthFull)
    .backgroundColor(this.tm.current.colorCardBg)
    .borderRadius(this.tm.current.radius12)
    .padding(this.tm.current.value20)
    .shadow({
      radius: this.tm.current.shadowRadius,
      color: this.tm.current.shadowColor,
      offsetY: this.tm.current.shadowOffsetY
    })
  }
}
