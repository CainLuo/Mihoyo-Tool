/**
 * Login.ets — 登录页
 */
import { LoginViewModel } from '../viewmodel/LoginViewModel'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { LoginNarrowLayout } from '../components/login/LoginNarrowLayout'
import { LoginWideLayout } from '../components/login/LoginWideLayout'
import { Logger } from 'core'
import { AppRoutes } from '../constants/AppRoutes'
import { AccountSignal } from '../utils/AccountSignal'
import { WebViewParam } from './WebViewPage'
import { i18n } from '@kit.LocalizationKit'

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

  private pushWebView(type: 'terms' | 'privacy'): void {
    const stack = this.localStack
    if (stack === null) { return }
    const lang = i18n.System.getSystemLanguage()
    let suffix = '-en'
    if (lang.startsWith('zh')) {
      const script = i18n.System.getSystemRegion()
      if (lang.includes('Hant') || script === 'HK' || script === 'TW' || script === 'MO') {
        suffix = '-zh-hant'
      } else {
        suffix = '-zh'
      }
    }
    const param = new WebViewParam()
    param.htmlFile = `legal/${type}${suffix}.html`
    param.titleResource = type === 'terms'
      ? $r('app.string.login_agreement_terms')
      : $r('app.string.login_agreement_privacy')
    stack.pushPathByName(AppRoutes.WEB_VIEW, param)
  }

  @Monitor(LoginViewModel.KEYS.loginSuccess)
  onLoginSuccess(_monitor: IMonitor): void {    if (!this.vm.loginSuccess) { return }
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

  @Monitor(LoginViewModel.KEYS.showNoStokenDialog)
  onShowNoStokenDialog(_monitor: IMonitor): void {
    if (!this.vm.showNoStokenDialog) { return }
    this.vm.showNoStokenDialog = false
    this.getUIContext().showAlertDialog({
      title: $r('app.string.login_cookie_no_stoken_title'),
      message: $r('app.string.login_cookie_no_stoken'),
      confirm: {
        value: $r('app.string.dialog_confirm'),
        action: () => {}
      }
    })
  }

  build() {
    NavDestination() {
      Column() {
        if (this.windowWidth <= this.tm.current.value480) {
          LoginNarrowLayout({
            vm: this.vm,
            onTapTerms: () => { this.pushWebView('terms') },
            onTapPrivacy: () => { this.pushWebView('privacy') }
          })
        } else {
          LoginWideLayout({
            vm: this.vm,
            onTapTerms: () => { this.pushWebView('terms') },
            onTapPrivacy: () => { this.pushWebView('privacy') }
          })
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.colorPageBg)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
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

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct LoginPreview {
  build() {
    Login()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function LoginBuilder(_name: string, _param: Object) {
  Login()
}
