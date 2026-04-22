/**
 * NotificationStyleBPreview — 样式 B 通知气泡预览（折叠 + 展开）
 *
 * 模拟系统通知气泡的折叠和展开状态，用于通知样式选择卡片中的预览。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct NotificationStyleBPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
      // 折叠状态标签
      Text($r('app.string.notification_style_b_title'))
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
        .opacity(0.7)

      // 折叠状态气泡
      Column({ space: this.tm.current.value4 }) {
        Row({ space: this.tm.current.value5 }) {
          Image($r('app.media.ic_app_logo'))
            .width(this.tm.current.value12)
            .height(this.tm.current.value12)
            .borderRadius(this.tm.current.value4)
          Text($r('app.string.app_name'))
            .font(this.tm.current.body10)
            .fontColor(this.tm.current.colorTextSecondary)
          Text($r('app.string.sync_just_now'))
            .font(this.tm.current.body10)
            .fontColor(this.tm.current.colorTextSecondary)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width(this.tm.current.full)

        Text($r('app.string.notification_content_title_style_b_collapsed', 3))
          .font(this.tm.current.body13Bold)
          .fontColor(this.tm.current.colorTextPrimary)
        Text($r('app.string.notification_content_line_style_b',
          $r('app.string.game_name_genshin'),
          $r('app.string.notification_stamina_genshin'), 200, 200))
          .font(this.tm.current.body12)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.value12)
      .backgroundColor(this.tm.current.colorSurfaceSubtle)
      .borderRadius(this.tm.current.radius8)
      .alignItems(HorizontalAlign.Start)

      // 展开状态标签
      Text($r('app.string.notification_content_title_style_b_expanded'))
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
        .opacity(0.7)
        .margin({ top: this.tm.current.value4 })

      // 展开状态气泡
      Column({ space: this.tm.current.value4 }) {
        Row({ space: this.tm.current.value5 }) {
          Image($r('app.media.ic_app_logo'))
            .width(this.tm.current.value12)
            .height(this.tm.current.value12)
            .borderRadius(this.tm.current.value4)
          Text($r('app.string.app_name'))
            .font(this.tm.current.body10)
            .fontColor(this.tm.current.colorTextSecondary)
          Text($r('app.string.sync_just_now'))
            .font(this.tm.current.body10)
            .fontColor(this.tm.current.colorTextSecondary)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width(this.tm.current.full)

        Text($r('app.string.notification_content_title_style_b_expanded'))
          .font(this.tm.current.body13Bold)
          .fontColor(this.tm.current.colorTextPrimary)
        Divider()
          .color(this.tm.current.colorDivider)
          .margin({ top: this.tm.current.value2, bottom: this.tm.current.value2 })
        Row({ space: this.tm.current.value5 }) {
          Circle({ width: this.tm.current.value5, height: this.tm.current.value5 })
            .fill($r('app.color.game_color_genshin'))
          Text($r('app.string.notification_content_line_style_b',
            $r('app.string.game_name_genshin'),
            $r('app.string.notification_stamina_genshin'), 200, 200))
            .font(this.tm.current.body12)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        Row({ space: this.tm.current.value5 }) {
          Circle({ width: this.tm.current.value5, height: this.tm.current.value5 })
            .fill($r('app.color.game_color_starrail'))
          Text($r('app.string.notification_content_line_style_b',
            $r('app.string.game_name_starrail'),
            $r('app.string.notification_stamina_starrail'), 300, 300))
            .font(this.tm.current.body12)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        Row({ space: this.tm.current.value5 }) {
          Circle({ width: this.tm.current.value5, height: this.tm.current.value5 })
            .fill($r('app.color.game_color_zzz'))
          Text($r('app.string.notification_content_line_style_b',
            $r('app.string.game_name_zzz'),
            $r('app.string.notification_stamina_zzz'), 240, 240))
            .font(this.tm.current.body12)
            .fontColor(this.tm.current.colorTextSecondary)
        }
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.value12)
      .backgroundColor(this.tm.current.colorSurfaceSubtle)
      .borderRadius(this.tm.current.radius8)
      .alignItems(HorizontalAlign.Start)

      Text($r('app.string.notification_style_b_desc'))
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
        .opacity(0.7)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
