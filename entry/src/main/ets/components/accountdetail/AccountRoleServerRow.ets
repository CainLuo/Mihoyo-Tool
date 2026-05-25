/**
 * AccountRoleServerRow — 服务器/UID 信息行
 *
 * 展示：服务器标签 + 分隔符 + UID
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeFonts } from '../../theme/ThemeFonts'

@ComponentV2
export struct AccountRoleServerRow {
  /** 服务器显示名称（ResourceStr 支持国际化） */
  @Param server: ResourceStr = ''
  /** 游戏角色 UID */
  @Param roleUid: string = ''
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.value8 }) {
      Text(this.server)
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.textOnDarkHigh)
        .padding({
          left: this.tm.current.value8,
          right: this.tm.current.value8,
          top: this.tm.current.value2,
          bottom: this.tm.current.value2
        })
        .borderRadius(this.tm.current.value4)
        .backgroundColor(this.tm.current.roleCardServerBg)

      Text($r('app.string.common_dot_separator'))
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.textOnDarkMuted)

      Text($r('app.string.common_uid_format', this.roleUid))
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.textOnDarkSecondary)
    }
    .width(this.tm.current.full)
    .alignItems(VerticalAlign.Center)
  }
}
