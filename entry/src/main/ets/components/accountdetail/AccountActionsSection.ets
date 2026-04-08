/**
 * AccountActionsSection — 账号详情页操作区块
 */
import { ThemeManager, themeManager } from '../../theme/ThemeManager'

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
      AccountActionsSection({ tm: themeManager })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
