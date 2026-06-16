/**
 * GameDataRow — 游戏数据行（标签 + 值）
 *
 * 供 GameToolCardContent 渲染 dataRows 列表使用。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { ThemeFonts } from '../../theme/ThemeFonts'

@ComponentV2
export struct GameDataRow {
  @Param label: Resource = $r('app.string.app_name');
  @Param value: ResourceStr = '';
  @Param valueColor: ResourceColor = $r('app.color.gray_900');
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value8 }) {
      Text(this.label)
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.colorTextSecondary)
        .layoutWeight(1)

      Text(this.value)
        .font(ThemeFonts.fontBold14)
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
    Column({ space: this.tm.current.value8 }) {
      GameDataRow({ label: $r('app.string.daily_note_resin_title'), value: '140/200', valueColor: $r('app.color.color_primary') })

      GameDataRow({ label: $r('app.string.daily_note_home_coin_title'), value: '2400/2400', valueColor: $r('app.color.color_danger') })

      GameDataRow({ label: $r('app.string.daily_note_daily_task_title'), value: '4/4', valueColor: $r('app.color.color_primary') })
    }
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }

  @Local private tm: ThemeManager = themeManager;
}
