/**
 * MaterialCalcLoadingView.ets — 材料计算页加载中视图
 *
 * 显示加载动画。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct MaterialCalcLoadingView {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      LoadingProgress()
        .width(32)
        .height(32)
        .color(this.tm.current.colorPrimary)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}

@Preview
@ComponentV2
export struct MaterialCalcLoadingViewPreview {
  build() {
    MaterialCalcLoadingView()
      .backgroundColor('#1a1a2e')
      .height(300)
  }
}
