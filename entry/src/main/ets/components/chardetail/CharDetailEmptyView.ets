/**
 * CharDetailEmptyView — 角色详情空态/错误视图
 */
import { ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct CharDetailEmptyView {
  @Param tm: ThemeManager = new ThemeManager()

  build() {
    Row() {
      Text($r('app.string.char_detail_no_data'))
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .justifyContent(FlexAlign.Center)
  }
}
