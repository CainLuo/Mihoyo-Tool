/**
 * LoginPage.ets — 登录页
 */
import { LoginViewModel } from '../viewmodel/LoginViewModel'
import { themeManager, ThemeManager, AppRoutes, AccountSignal } from 'basic'
import { LoginNarrowLayout } from '../views/LoginNarrowLayout'
import { LoginWideLayout } from '../views/LoginWideLayout'
import { Logger } from 'core'
import { WebViewParam } from 'legal'
import { i18n } from '@kit.LocalizationKit'

const TAG: string = 'Login'

@ComponentV2
export struct LoginPage {
  @Local private vm: LoginViewModel = new LoginViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private windowWidth: number = 360
  private localStack: NavPathStack | null = null

  aboutToAppear(): void {
    this.vm.init()
  }

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

  @Monitor('vm.isLoginSuccess')
  onLoginSuccess(_monitor: IMonitor): void {
    if (!this.vm.isLoginSuccess) { return }
    const stack = this.localStack
    if (stack === null) { return }
    AccountSignal.getInstance().notify()
    const accountVM = this.vm.loginedAccountVM
    if (accountVM === null) {
      Logger.error(TAG, 'loginedAccountVM is null after loginSuccess')
      stack.pop()
      return
    }
    stack.replacePath({ name: AppRoutes.ACCOUNT_DETAIL, param: accountVM })
  }

  @Monitor('vm.shouldShowStokenMissingDialog')
  onShowNoStokenDialog(_monitor: IMonitor): void {
    if (!this.vm.shouldShowStokenMissingDialog) { return }
    this.vm.shouldShowStokenMissingDialog = false
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
      .onAreaChange((_old: Area, cur: Area) => {
        this.windowWidth = cur.width as number
      })
    }
    .id('login_page')
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
export struct LoginPagePreview {
  build() {
    LoginPage()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function LoginPageBuilder(_name: string, _param: Object) {
  LoginPage()
}
