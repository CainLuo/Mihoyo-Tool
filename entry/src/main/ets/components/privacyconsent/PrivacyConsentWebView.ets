/**
 * PrivacyConsentWebView — 隐私合规页 Web 内容区
 *
 * 加载指定 rawfile HTML，注册 scrollBridge，页面加载完成后注入主题色和滚动检测脚本。
 * 主题通过 JS 注入实现，不使用 forceDarkAccess（避免影响外部 ArkTS 组件）。
 */
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { ConfigurationConstant, common } from '@kit.AbilityKit';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { Logger } from 'core';

const TAG: string = 'PrivacyConsentWebView';

/** 滚动到底部检测脚本 */
const SCROLL_SCRIPT: string =
  '(function(){' +
  '  function check(){' +
  '    var sh=Math.max(document.body.scrollHeight,document.documentElement.scrollHeight);' +
  '    var st=window.pageYOffset||document.documentElement.scrollTop||document.body.scrollTop||0;' +
  '    var ih=window.innerHeight||document.documentElement.clientHeight;' +
  '    if(sh>ih && st+ih>=sh-50){' +
  '      if(window.scrollBridge){window.scrollBridge.onReachedBottom();}' +
  '    }' +
  '  }' +
  '  window.addEventListener("scroll",check,{passive:true});' +
  '  setTimeout(check,500);' +
  '})();';

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

/** 注册到 Web 的 JS Bridge 对象 */
export class ScrollBridge {
  private callback: () => void;

  constructor(callback: () => void) {
    this.callback = callback;
  }

  onReachedBottom(): void {
    Logger.info(TAG, 'onReachedBottom');
    this.callback();
  }
}

@ComponentV2
export struct PrivacyConsentWebView {
  @Param htmlFile: string = '';
  @Event onReachedBottom: () => void = () => {};

  @Local private tm: ThemeManager = themeManager;
  private controller: webview.WebviewController = new webview.WebviewController();
  private bridge: ScrollBridge = new ScrollBridge(() => { this.onReachedBottom(); });
  private pageLoaded: boolean = false;

  private isDark(): boolean {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    if (!ctx) { return false; }
    return ctx.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  private injectAll(): void {
    const script = buildThemeScript(this.isDark()) + SCROLL_SCRIPT;
    this.controller.runJavaScript(script, (err: BusinessError) => {
      if (err) { Logger.warn(TAG, `inject failed: ${err.message}`); }
    });
  }

  @Monitor('tm.current.colorPageBg')
  onThemeChanged(_m: IMonitor): void {
    if (this.pageLoaded) { this.injectAll(); }
  }

  build() {
    Web({
      src: `resource://rawfile/${this.htmlFile}`,
      controller: this.controller,
    })
      .width(this.tm.current.full)
      .layoutWeight(1)
      .darkMode(WebDarkMode.Off)
      .javaScriptAccess(true)
      .onControllerAttached(() => {
        this.controller.registerJavaScriptProxy(
          this.bridge, 'scrollBridge', ['onReachedBottom']
        );
      })
      .onPageEnd((_event: OnPageEndEvent) => {
        this.pageLoaded = true;
        this.injectAll();
      })
  }
}
