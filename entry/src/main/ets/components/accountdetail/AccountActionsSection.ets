/**
 * AccountActionsSection — 账号详情页操作区块
 *
 * 展示删除账号按钮，点击后触发 onDelete 回调。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct AccountActionsSection {
  @Param onDelete: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      Button($r('app.string.account_detail_delete'), { type: ButtonType.Normal })
        .fontSize(this.tm.current.font17)
        .fontWeight(FontWeight.Normal)
        .fontColor(this.tm.current.colorDanger)
        .width(this.tm.current.full)
        .height(this.tm.current.value50)
        .backgroundColor(this.tm.current.colorSurfaceCard)
        .onClick(() => { this.onDelete() })
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct AccountActionsSectionPreview {
  build() {
    Column() {
      AccountActionsSection()
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
