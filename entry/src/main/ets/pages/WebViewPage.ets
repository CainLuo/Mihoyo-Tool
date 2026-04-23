/**
 * WebViewPage.ets — 通用 WebView 页面
 * 用于展示本地 rawfile HTML 文件（用户协议、隐私政策等）
 *
 * 路由参数：WebViewParam { title: string, htmlFile: string }
 * htmlFile 为 rawfile/legal/ 下的文件名，如 'terms.html'
 */
import { webview } from '@kit.ArkWeb'
import { themeManager, ThemeManager } from '../theme/ThemeManager'

/** 路由参数 */
export class WebViewParam {
  /** 页面标题（多语言 Resource） */
  titleResource: ResourceStr = ''
  /** rawfile 路径，如 'legal/terms.html' */
  htmlFile: string = ''
}

@ComponentV2
export struct WebViewPage {
  @Param routerParam: WebViewParam = new WebViewParam()
  @Local private tm: ThemeManager = themeManager
  private controller: webview.WebviewController = new webview.WebviewController()
  private localStack: NavPathStack | null = null

  build() {
    NavDestination() {
      Web({
        src: `resource://rawfile/${this.routerParam.htmlFile}`,
        controller: this.controller,
      })
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.colorPageBg)
      .darkMode(WebDarkMode.Auto)
      .overScrollMode(OverScrollMode.ALWAYS)
    }
    .title(this.routerParam.titleResource)
    .hideTitleBar(false)
    .backgroundColor(this.tm.current.colorPageBg)
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
