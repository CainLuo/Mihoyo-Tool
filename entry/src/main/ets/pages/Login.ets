/**
 * Login.ets — 登录页
 */
import { AppRoutes } from '../constants/AppRoutes'
import { RouterUtil } from '../utils/RouterUtil'
import { LoginViewModel } from '../viewmodel/LoginViewModel'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { LoginNarrowLayout } from '../components/login/LoginNarrowLayout'
import { LoginWideLayout } from '../components/login/LoginWideLayout'
import { Logger } from '../utils/Logger'

const TAG: string = 'Login'

@ComponentV2
export struct Login {
  @Local private vm: LoginViewModel = new LoginViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private windowWidth: number = 360

  aboutToDisappear(): void {
    this.vm.dispose()
  }

  @Monitor(LoginViewModel.KEYS.loginSuccess)
  onLoginSuccess(): void {
    if (this.vm.loginSuccess) {
      Logger.info(TAG, 'login success, navigate to Main')
      RouterUtil.replace(AppRoutes.MAIN)
    }
  }

  build() {
    Column() {
      if (this.windowWidth <= this.tm.current.loginNarrowBreakpoint) {
        LoginNarrowLayout({ tm: this.tm, vm: this.vm })
      } else {
        LoginWideLayout({ tm: this.tm, vm: this.vm })
      }
    }
    .expandSafeArea([SafeAreaType.SYSTEM])
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .backgroundColor(this.tm.current.colorPageBg)
    .onAreaChange((_old, cur) => {
      this.windowWidth = cur.width as number
    })
  }
}
