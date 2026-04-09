/**
 * Login.ets — 登录页
 */
import { LoginViewModel } from '../viewmodel/LoginViewModel'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { LoginNarrowLayout } from '../components/login/LoginNarrowLayout'
import { LoginWideLayout } from '../components/login/LoginWideLayout'
import { Logger } from '../utils/Logger'
import { AppRoutes } from '../constants/AppRoutes'
import { AccountSignal } from '../utils/AccountSignal'

const TAG: string = 'Login'

@ComponentV2
export struct Login {
  @Local private vm: LoginViewModel = new LoginViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private windowWidth: number = 360
  private localStack: NavPathStack | null = null

  aboutToDisappear(): void {
    this.vm.dispose()
  }

  @Monitor(LoginViewModel.KEYS.loginSuccess)
  onLoginSuccess(_monitor: IMonitor): void {
    if (!this.vm.loginSuccess) { return }
    const stack = this.localStack
    if (stack === null) { return }
    AccountSignal.instance().notify()
    const accountVM = this.vm.loginedAccountVM
    if (accountVM === null) {
      Logger.error(TAG, 'loginedAccountVM is null after loginSuccess')
      stack.pop()
      return
    }
    stack.replacePath({ name: AppRoutes.ACCOUNT_DETAIL, param: accountVM })
  }

  build() {
    NavDestination() {
      Column() {
        if (this.windowWidth <= this.tm.current.value480) {
          LoginNarrowLayout({ tm: this.tm, vm: this.vm })
        } else {
          LoginWideLayout({ tm: this.tm, vm: this.vm })
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.colorPageBg)
      .onAreaChange((_old, cur) => {
        this.windowWidth = cur.width as number
      })
    }
    .title($r('app.string.login_title'))
    .hideTitleBar(false)
    .onReady((ctx: NavDestinationContext) => {
      this.localStack = ctx.pathStack
    })
  }
}
