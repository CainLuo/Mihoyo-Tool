/**
 * NotificationBubbleCollapsed — 样式 B 折叠状态气泡
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeFonts } from '../../theme/ThemeFonts'
import { NotificationBubbleHeader } from './NotificationBubbleHeader'

@ComponentV2
export struct NotificationBubbleCollapsed {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value4 }) {
      NotificationBubbleHeader()

      Text($r('app.string.notification_content_title_style_b_collapsed', 3))
        .font(ThemeFonts.fontBold14)
        .fontColor(this.tm.current.colorTextPrimary)

      Text($r('app.string.notification_content_line_style_b',
        $r('app.string.game_name_genshin'),
        $r('app.string.notification_stamina_genshin'), 200, 200))
        .font(ThemeFonts.font13)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .backgroundColor(this.tm.current.colorSurfaceSubtle)
    .borderRadius(this.tm.current.radius8)
    .alignItems(HorizontalAlign.Start)
  }
}
