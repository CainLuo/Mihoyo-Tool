/**
 * LoginLogoSection — 登录页 Logo 区
 */
import { ThemeManager, themeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct LoginLogoSection {
  @Param tm: ThemeManager = new ThemeManager()
  @Param logoSize: number = 64

  build() {
    Column({ space: this.tm.current.value8 }) {
      Image($r('app.media.ic_app_logo'))
        .width(this.logoSize)
        .height(this.logoSize)
        .borderRadius(this.tm.current.value28)
      Text($r('app.string.app_name'))
        .font(this.tm.current.title20Bold)
        .fontColor(this.tm.current.colorTextPrimary)
      Text($r('app.string.launch_subtitle'))
        .font(this.tm.current.body12)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .alignItems(HorizontalAlign.Center)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct LoginLogoSectionPreview {
  build() {
    Column() {
      LoginLogoSection({ tm: themeManager, logoSize: 64 })
    }
    .padding(32)
    .backgroundColor('#1a1a2e')
  }
}
