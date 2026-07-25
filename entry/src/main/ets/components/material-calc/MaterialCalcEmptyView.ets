/**
 * MaterialCalcEmptyView.ets — 材料计算页空态视图
 *
 * 显示空态提示文字。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct MaterialCalcEmptyView {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: 16 }) {
      Text('📦')
        .fontSize(48)

      Text($r('app.string.material_calc_empty_title'))
        .fontSize(this.tm.current.fontBold16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.colorTextPrimary)

      Text($r('app.string.material_calc_empty_desc'))
        .fontSize(this.tm.current.font12)
        .fontColor(this.tm.current.colorTextSecondary)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .padding(32)
  }
}

@Preview
@ComponentV2
export struct MaterialCalcEmptyViewPreview {
  build() {
    MaterialCalcEmptyView()
      .backgroundColor('#1a1a2e')
      .height(300)
  }
}
