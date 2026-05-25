/**
 * LoginLogoSection — 登录页 Logo 区
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { ThemeFonts } from '../../theme/ThemeFonts'

@ComponentV2
export struct LoginLogoSection {
  @Param logoSize: number = 64;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value8 }) {
      Image($r('app.media.ic_app_logo'))
        .width(this.logoSize)
        .height(this.logoSize)
        .borderRadius(this.tm.current.value28)

      Text($r('app.string.app_name'))
        .font(ThemeFonts.fontBold20)
        .fontColor(this.tm.current.colorTextPrimary)

      Text($r('app.string.launch_subtitle'))
        .font(ThemeFonts.font13)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .alignItems(HorizontalAlign.Center)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct LoginLogoSectionPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      LoginLogoSection({ logoSize: 64 })
    }
    .padding(this.tm.current.value32)
    .backgroundColor('#1a1a2e')
  }
}
