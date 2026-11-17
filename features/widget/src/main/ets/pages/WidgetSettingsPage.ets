/**
 * WidgetSettingsPage — Widget 卡片配置页
 *
 * 采用步骤流程：
 * 1. 选择卡片尺寸（1×2 / 2×2 / 2×4 / 4×4）
 * 2. 选择要显示的角色 slots（跨账号多选）
 * 3. 完成 → 调用 formProvider.openFormManager()
 *
 * MVVM 架构说明：
 * - WidgetSettingsViewModel 负责：业务逻辑、状态管理、UI State 组装
 * - WidgetSettingsPage 页面只负责：从 ViewModel 获取数据、渲染组件
 *
 * 参数传递方案：
 * - vm.uiState: 封装所有渲染数据（ViewModel 负责组装）
 * - vm.callbacks: 封装所有回调函数（ViewModel 负责初始化）
 * - vm.slotHelper: 封装 Slot 辅助方法（ViewModel 负责初始化）
 */
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { themeManager, ThemeManager, ThemeFonts, PrimaryButtonModifier } from 'basic';
import { WidgetSettingsViewModel } from '../viewmodel/WidgetSettingsViewModel';
import { WidgetSettingsLoading } from '../views/WidgetSettingsLoading';
import { WidgetSettingsMainContent } from '../views/WidgetSettingsMainContent';

@ComponentV2
export struct WidgetSettingsPage {
  @Local private tm: ThemeManager = themeManager;
  @Local private vm: WidgetSettingsViewModel = new WidgetSettingsViewModel();
  @Local private isLoading: boolean = true;
  @Local private loadFailed: boolean = false;
  @Local private retryModifier: PrimaryButtonModifier = new PrimaryButtonModifier(true);
  private localStack: NavPathStack | null = null;

  async aboutToAppear(): Promise<void> {
    this.vm.onConfigComplete = () => {
      this.localStack?.pop();
    };
    this.vm.onConfigError = () => {
      this.showCompleteFailed();
    };
    await this.load();
  }

  /** 加载配置数据；失败时进入错误态，可重试 */
  private async load(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const ok = await this.vm.init(context);
    this.loadFailed = !ok;
    this.isLoading = false;
  }

  private retry(): void {
    this.isLoading = true;
    this.loadFailed = false;
    this.load();
  }

  private showCompleteFailed(): void {
    promptAction.showToast({ message: '添加卡片失败，请重试' });
  }

  build() {
    NavDestination() {
      if (this.isLoading) {
        WidgetSettingsLoading()
      } else if (this.loadFailed) {
        Column({ space: this.tm.current.value12 }) {
          Text('配置数据加载失败，请重试')
            .font(ThemeFonts.FONT_14)
            .fontColor(this.tm.current.colorTextSecondary)
            .textAlign(TextAlign.Center)

          Button('重试', { type: ButtonType.Normal })
            .attributeModifier(this.retryModifier)
            .width(this.tm.current.value120)
            .onClick(() => {
              this.retry();
            })
        }
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(this.tm.current.font20)
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
export function WidgetSettingsPageBuilder(_name: string, _param: Object) {
  WidgetSettingsPage()
}
