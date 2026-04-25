/**
 * NotificationSettings — 通知设置二级页
 */
import { common } from '@kit.AbilityKit';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { NotificationSection } from '../components/my/NotificationSection';

@ComponentV2
export struct NotificationSettings {
  @Local private tm: ThemeManager = themeManager;
  @Local private abilityContext: common.UIAbilityContext | null = null;
  private localStack: NavPathStack | null = null;
  private uiCtx: UIContext | null = null;

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext();
    const hostCtx = this.uiCtx.getHostContext();
    if (hostCtx !== undefined) {
      this.abilityContext = hostCtx as common.UIAbilityContext;
    }
  }

  build() {
    NavDestination() {
      NotificationSection({ context: this.abilityContext })
    }
    .title($r('app.string.my_section_notification'))
    .hideTitleBar(false)
    .backgroundColor(this.tm.current.colorPageBg)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .onReady((ctx: NavDestinationContext) => {
      this.localStack = ctx.pathStack;
    })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function NotificationSettingsBuilder(_name: string, _param: Object) {
  NotificationSettings()
}
