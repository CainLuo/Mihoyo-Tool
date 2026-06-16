/**
 * NotificationAccountHeader — 账号折叠区块的标题行（头像 + 昵称 + 展开箭头）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeFonts } from '../../theme/ThemeFonts'
import { AccountNotificationConfig } from '../../notification/NotificationModels'

@ComponentV2
export struct NotificationAccountHeader {
  @Param acct: AccountNotificationConfig = new AccountNotificationConfig()
  @Param collapsed: boolean = false
  @Param onToggle: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.value12 }) {
      if (this.acct.avatarUrl.length > 0) {
        Image(this.acct.avatarUrl)
          .width(this.tm.current.value32)
          .height(this.tm.current.value32)
          .borderRadius(this.tm.current.value8)
          .objectFit(ImageFit.Cover)
          .border({ width: this.tm.current.value1p5, color: this.tm.current.colorPrimary })
      } else {
        Row()
          .width(this.tm.current.value32)
          .height(this.tm.current.value32)
          .borderRadius(this.tm.current.value8)
          .backgroundColor(this.tm.current.colorPrimary)
          .opacity(0.5)
      }

      Column({ space: this.tm.current.value2 }) {
        Text(this.acct.nickname)
          .font(ThemeFonts.fontBold14)
          .fontColor(this.tm.current.colorTextPrimary)

        Text($r('app.string.my_account_role_count', this.acct.games.length))
          .font(ThemeFonts.font11)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      SymbolGlyph($r('sys.symbol.chevron_down'))
        .fontSize(this.tm.current.font16)
        .fontColor([this.tm.current.colorTextSecondary])
        .rotate({ angle: this.collapsed ? -90 : 0 })
        .animation({ duration: 250, curve: Curve.EaseInOut })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value56)
    .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
    .onClick(() => { this.onToggle() })
  }
}
