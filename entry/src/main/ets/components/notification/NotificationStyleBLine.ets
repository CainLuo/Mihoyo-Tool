/**
 * NotificationStyleBLine — 样式 B 展开状态中的单游戏行
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeFonts } from '../../theme/ThemeFonts'

@ComponentV2
export struct NotificationStyleBLine {
  @Param dotColor: Resource = $r('app.color.game_color_genshin')
  @Param content: ResourceStr = ''
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.value5 }) {
      Circle({ width: this.tm.current.value5, height: this.tm.current.value5 })
        .fill(this.dotColor)

      Text(this.content)
        .font(ThemeFonts.font13)
        .fontColor(this.tm.current.colorTextSecondary)
    }
  }
}
