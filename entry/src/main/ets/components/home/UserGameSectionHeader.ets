/**
 * UserGameSectionHeader — 账号区块标题行（头像 + 昵称 + 游戏数 + 折叠箭头）
 *
 * 仅在 UserGameSection 中使用。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { ThemeFonts } from '../../theme/ThemeFonts'
import { MihoyoAccountVM } from '../../models/HomeModels';

@ComponentV2
export struct UserGameSectionHeader {
  @Param account: MihoyoAccountVM = new MihoyoAccountVM('', '', []);
  @Param collapsed: boolean = false;
  @Param onToggle: () => void = () => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value8 }) {
      if (this.account.avatarUrl !== '') {
        Image(this.account.avatarUrl)
          .width(this.tm.current.value28)
          .height(this.tm.current.value28)
          .borderRadius(this.tm.current.radius8)
          .objectFit(ImageFit.Cover)
          .border({ width: this.tm.current.value1, color: this.tm.current.colorPrimary })
          .accessibilityText($r('app.string.home_account_avatar_desc'))
      } else {
        Row()
          .width(this.tm.current.value28)
          .height(this.tm.current.value28)
          .borderRadius(this.tm.current.radius8)
          .backgroundColor(this.tm.current.colorPrimary)
          .accessibilityText($r('app.string.home_account_avatar_desc'))
      }

      Text(this.account.nickname !== '' ? this.account.nickname : this.account.username)
        .font(ThemeFonts.fontMedium17)
        .fontColor(this.tm.current.colorTextPrimary)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text($r('app.string.home_game_count_format', this.account.roles.length))
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.colorTextSecondary)

      SymbolGlyph($r('sys.symbol.chevron_down'))
        .fontSize(this.tm.current.font16)
        .fontColor([this.tm.current.colorTextSecondary])
        .rotate({ angle: this.collapsed ? -90 : 0 })
        .animation({ duration: 250, curve: Curve.EaseInOut })
    }
    .width(this.tm.current.full)
    .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => { this.onToggle() })
  }
}
