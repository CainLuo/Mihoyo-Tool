/**
 * GameDataRow — 游戏数据行（emoji icon + 标签 + 值）
 * 供 GenshinGameToolCardContent、StarRailGameToolCardContent 复用
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct GameDataRow {
  @Param emoji: string = ''
  @Param label: Resource = $r('app.string.app_name')
  @Param value: ResourceStr = ''
  @Param valueColor: ResourceColor = $r('app.color.color_text_primary')
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.value8 }) {
      Text(this.emoji)
        .width(this.tm.current.value32)
        .height(this.tm.current.value32)
        .textAlign(TextAlign.Center)
        .fontSize(this.tm.current.value32 - 4)
        .borderRadius(this.tm.current.value8)
        .backgroundColor($r('app.color.surface_glass_xs'))
      Text(this.label)
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextSecondary)
        .layoutWeight(1)
      Text(this.value)
        .font(this.tm.current.body13Bold)
        .fontColor(this.valueColor)
    }
    .width(this.tm.current.full)
    .alignItems(VerticalAlign.Center)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct GameDataRowPreview {
  build() {
    Column({ space: 8 }) {
      GameDataRow({ emoji: '🌙', label: $r('app.string.daily_note_resin_title'), value: '140/200', valueColor: $r('app.color.color_primary') })
      GameDataRow({ emoji: '🏡', label: $r('app.string.daily_note_home_coin_title'), value: '2400/2400', valueColor: $r('app.color.color_danger') })
      GameDataRow({ emoji: '📋', label: $r('app.string.daily_note_daily_task_title'), value: '4/4', valueColor: $r('app.color.color_primary') })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
