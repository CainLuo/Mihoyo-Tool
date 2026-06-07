/**
 * PreviewEmptyContent.ets — Widget 配置预览空态内容
 *
 * 显示"请选择账号"提示。
 */

import { WidgetColors } from '../../../widget/models/WidgetUIStates';
import { DefaultTheme } from '../../../theme/DefaultTheme';

@ComponentV2
export struct PreviewEmptyContent {
  @Local theme: DefaultTheme = new DefaultTheme();

  build() {
    Column() {
      Text($r('app.string.widget_select_account_hint'))
        .fontSize(this.theme.font13)
        .fontColor(WidgetColors.WHITE)
        .opacity(WidgetColors.OPACITY_TEXT_MUTED)
    }
    .width(this.theme.full)
    .height(this.theme.full)
    .justifyContent(FlexAlign.Center)
  }
}
