/**
 * AccountActionsSection — 账号详情页操作区块
 */
import { ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct AccountActionsSection {
  @Param tm: ThemeManager = new ThemeManager()
  @Param onDelete: () => void = () => {}

  build() {
    Column() {
      Button($r('app.string.account_detail_delete'), { type: ButtonType.Normal })
        .fontSize(this.tm.current.body16.size)
        .fontWeight(this.tm.current.body16.weight)
        .fontColor(this.tm.current.colorDanger)
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightButton)
        .backgroundColor(this.tm.current.colorSurfaceCard)
        .onClick(() => { this.onDelete() })
    }
    .width(this.tm.current.widthFull)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
  }
}
