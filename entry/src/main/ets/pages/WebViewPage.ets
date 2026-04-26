/**
 * WebViewPage.ets — 通用 WebView 页面
 * 用于展示本地 rawfile HTML 文件（用户协议、隐私政策等）
 *
 * 路由参数：WebViewParam { titleResource: ResourceStr, htmlFile: string }
 * 主题通过 JS 注入实现，不使用 forceDarkAccess（避免影响外部 ArkTS 组件）。
 */
import { webview } from '@kit.ArkWeb'
import { BusinessError } from '@kit.BasicServicesKit'
import { ConfigurationConstant, common } from '@kit.AbilityKit'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { Logger } from 'core'

const TAG: string = 'WebViewPage'

/** 路由参数 */
export class WebViewParam {
  titleResource: ResourceStr = ''
  htmlFile: string = ''
}

function buildThemeScript(isDark: boolean): string {
  if (isDark) {
    return '(function(){' +
      'var s=document.getElementById("ark-theme");' +
      'if(!s){s=document.createElement("style");s.id="ark-theme";document.head.appendChild(s);}' +
      's.textContent="html,body{background-color:#000000!important;color:#e8e8f0!important}"' +
      '+"h1{color:#ffffff!important}h2{color:#c0c8e8!important;border-left-color:#3a6fd8!important}"' +
      '+"hr{border-top-color:#2a2a40!important}.effective{color:#8888b8!important}"' +
      '+"a{color:#7090e8!important}";' +
      '})();';
  } else {
    return '(function(){' +
      'var s=document.getElementById("ark-theme");' +
      'if(!s){s=document.createElement("style");s.id="ark-theme";document.head.appendChild(s);}' +
      's.textContent="html,body{background-color:#ffffff!important}";' +
      '})();';
  }
}

@ComponentV2
export struct WebViewPage {
  @Param routerParam: WebViewParam = new WebViewParam()
  @Local private tm: ThemeManager = themeManager
  private controller: webview.WebviewController = new webview.WebviewController()
  private localStack: NavPathStack | null = null
  private pageLoaded: boolean = false

  private isDark(): boolean {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext
    if (!ctx) { return false }
    return ctx.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
  }

  private injectTheme(): void {
    const script = buildThemeScript(this.isDark())
    this.controller.runJavaScript(script, (err: BusinessError) => {
      if (err) { Logger.warn(TAG, `inject failed: ${err.message}`) }
    })
  }

  @Monitor('tm.current.colorPageBg')
  onThemeChanged(_m: IMonitor): void {
    if (this.pageLoaded) { this.injectTheme() }
  }

  build() {
    NavDestination() {
      Column() {
        Web({
          src: `resource://rawfile/${this.routerParam.htmlFile}`,
          controller: this.controller,
        })
        .width(this.tm.current.full)
        .layoutWeight(1)
        .backgroundColor(this.tm.current.colorPageBg)
        .darkMode(WebDarkMode.Off)
        .onPageEnd((_event: OnPageEndEvent) => {
          this.pageLoaded = true
          this.injectTheme()
        })
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
    }
    .title(this.routerParam.titleResource)
    .hideTitleBar(false)
    .backgroundColor(this.tm.current.colorPageBg)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .onReady((ctx: NavDestinationContext) => {
      this.localStack = ctx.pathStack
    })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function WebViewPageBuilder(_name: string, param: Object) {
  WebViewPage({ routerParam: param as WebViewParam })
}
