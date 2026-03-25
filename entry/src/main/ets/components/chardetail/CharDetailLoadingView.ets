/**
 * CharDetailLoadingView — 角色详情加载中视图
 */
import { ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct CharDetailLoadingView {
  @Param tm: ThemeManager = new ThemeManager()

  build() {
    Row() {
      LoadingProgress()
        .width(this.tm.current.progressSizeMD)
        .height(this.tm.current.progressSizeMD)
        .color(this.tm.current.colorPrimary)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .justifyContent(FlexAlign.Center)
  }
}
