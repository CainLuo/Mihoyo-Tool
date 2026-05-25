/**
 * WidgetSettings — Widget 卡片配置页
 *
 * 采用步骤流程：
 * 1. 选择卡片尺寸（1×2 / 2×2 / 2×4 / 4×4）
 * 2. 选择要显示的角色 slots（跨账号多选）
 * 3. 完成 → 调用 formProvider.openFormManager()
 *
 * MVVM 架构说明：
 * - WidgetConfigViewModel 负责：业务逻辑、状态管理、UI State 组装
 * - WidgetSettings 页面只负责：从 ViewModel 获取数据、渲染组件
 *
 * 参数传递方案：
 * - vm.uiState: 封装所有渲染数据（ViewModel 负责组装）
 * - vm.callbacks: 封装所有回调函数（ViewModel 负责初始化）
 * - vm.slotHelper: 封装 Slot 辅助方法（ViewModel 负责初始化）
 */
import { common } from '@kit.AbilityKit';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { WidgetConfigViewModel } from '../viewmodel/WidgetConfigViewModel';
import { WidgetSettingsLoading } from '../components/widgetconfig/WidgetSettingsLoading';
import { WidgetSettingsMainContent } from '../components/widgetconfig/WidgetSettingsMainContent';

@ComponentV2
export struct WidgetSettings {
  @Local private tm: ThemeManager = themeManager;
  @Local private vm: WidgetConfigViewModel = new WidgetConfigViewModel();
  @Local private isLoading: boolean = true;
  private localStack: NavPathStack | null = null;

  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    await this.vm.init(context);
    this.isLoading = false;
    this.vm.onConfigComplete = () => {
      this.localStack?.pop();
    };
  }

  build() {
    NavDestination() {
      if (this.isLoading) {
        WidgetSettingsLoading()
      } else {
        WidgetSettingsMainContent({
          state: this.vm.uiState,
          callbacks: this.vm.callbacks,
          slotHelper: this.vm.slotHelper
        })
      }
    }
    .title($r('app.string.widget_config_title'))
    .hideTitleBar(false)
    .onReady((ctx: NavDestinationContext) => {
      this.localStack = ctx.pathStack;
    })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function WidgetSettingsBuilder(_name: string, _param: Object) {
  WidgetSettings()
}
