/**
 * WidgetSettings — Widget 卡片设置二级页
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { WidgetSection } from '../components/my/WidgetSection';
import { MyAccountVM } from '../models/MyModels';

@ComponentV2
export struct WidgetSettings {
  @Param accounts: MyAccountVM[] = [];
  @Local private tm: ThemeManager = themeManager;
  private localStack: NavPathStack | null = null;

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: this.tm.current.value16 }) {
          WidgetSection({ accounts: this.accounts })

          Row().height(this.tm.current.value40)
        }
        .width(this.tm.current.full)
        .padding({
          top: this.tm.current.value16,
          left: this.tm.current.value20,
          right: this.tm.current.value20,
        })
      }
      .scrollBar(BarState.Off)
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
    }
    .title($r('app.string.my_section_widget'))
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
export function WidgetSettingsBuilder(_name: string, param: Object) {
  WidgetSettings({ accounts: param as MyAccountVM[] })
}
