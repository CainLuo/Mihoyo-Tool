/**
 * WidgetSettingsLoading — Widget 配置页加载状态组件
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct WidgetSettingsLoading {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      LoadingProgress()
        .width(this.tm.current.value48)
        .height(this.tm.current.value48)
        .color(this.tm.current.colorPrimary)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .justifyContent(FlexAlign.Center)
  }
}
