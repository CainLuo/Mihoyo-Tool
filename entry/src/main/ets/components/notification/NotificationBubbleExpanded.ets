/**
 * NotificationBubbleExpanded — 样式 B 展开状态气泡
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeFonts } from '../../theme/ThemeFonts'
import { NotificationBubbleHeader } from './NotificationBubbleHeader'
import { NotificationStyleBLine } from './NotificationStyleBLine'

@ComponentV2
export struct NotificationBubbleExpanded {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value4 }) {
      NotificationBubbleHeader()

      Text($r('app.string.notification_content_title_style_b_expanded'))
        .font(ThemeFonts.fontBold14)
        .fontColor(this.tm.current.colorTextPrimary)

      Divider()
        .color(this.tm.current.colorDivider)
        .margin({ top: this.tm.current.value2, bottom: this.tm.current.value2 })

      NotificationStyleBLine({
        dotColor: $r('app.color.game_color_genshin'),
        content: $r('app.string.notification_content_line_style_b',
          $r('app.string.game_name_genshin'),
          $r('app.string.notification_stamina_genshin'), 200, 200)
      })

      NotificationStyleBLine({
        dotColor: $r('app.color.game_color_starrail'),
        content: $r('app.string.notification_content_line_style_b',
          $r('app.string.game_name_starrail'),
          $r('app.string.notification_stamina_starrail'), 300, 300)
      })

      NotificationStyleBLine({
        dotColor: $r('app.color.game_color_zzz'),
        content: $r('app.string.notification_content_line_style_b',
          $r('app.string.game_name_zzz'),
          $r('app.string.notification_stamina_zzz'), 240, 240)
      })
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .backgroundColor(this.tm.current.colorSurfaceSubtle)
    .borderRadius(this.tm.current.radius8)
    .alignItems(HorizontalAlign.Start)
  }
}
