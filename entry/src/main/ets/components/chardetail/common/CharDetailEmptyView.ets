/**
 * CharDetailEmptyView — 角色详情空态/错误视图
 */
import { ThemeManager, themeManager } from '../../../theme/ThemeManager';
import { ThemeFonts } from '../../../theme/ThemeFonts'

@ComponentV2
export struct CharDetailEmptyView {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row() {
      Text($r('app.string.char_detail_no_data'))
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .justifyContent(FlexAlign.Center)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct CharDetailEmptyViewPreview {
  build() {
    CharDetailEmptyView()
      .width('100%')
      .height(200)
      .backgroundColor('#1a1a2e')
  }
}
