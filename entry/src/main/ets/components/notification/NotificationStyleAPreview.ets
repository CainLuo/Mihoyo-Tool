/**
 * NotificationStyleAPreview — 样式 A 通知气泡预览
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct NotificationStyleAPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
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

        Text($r('app.string.notification_content_title_style_a',
          $r('app.string.game_name_genshin'), '昵称'))
          .font(this.tm.current.body13Bold)
          .fontColor(this.tm.current.colorTextPrimary)
        Text($r('app.string.notification_content_body_style_a',
          $r('app.string.notification_stamina_genshin'), 200, 200))
          .font(this.tm.current.body12)
          .fontColor(this.tm.current.colorTextSecondary)
        Text($r('app.string.notification_content_sub_style_a',
          $r('app.string.server_genshin_cn_official'), '100000001'))
          .font(this.tm.current.body10)
          .fontColor(this.tm.current.colorTextSecondary)
          .opacity(0.7)
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.value12)
      .backgroundColor(this.tm.current.colorSurfaceSubtle)
      .borderRadius(this.tm.current.radius8)
      .alignItems(HorizontalAlign.Start)

      Text($r('app.string.notification_style_a_desc'))
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
        .opacity(0.7)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
