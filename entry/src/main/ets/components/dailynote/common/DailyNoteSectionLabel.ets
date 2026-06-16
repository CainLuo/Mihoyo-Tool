/**
 * DailyNoteSectionLabel — 便笺分组标题标签
 *
 * 三个游戏便笺通用，显示"日常"/"宇宙"/"商店"等分组标题。
 * 使用方：DailyNoteStarRail、DailyNoteZZZ
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ThemeFonts } from '../../../theme/ThemeFonts'

@ComponentV2
export struct DailyNoteSectionLabel {
  @Param label: Resource = $r('app.string.app_name');
  @Local private tm: ThemeManager = themeManager;

  build() {
    Text(this.label)
      .font(ThemeFonts.font13)
      .fontColor(this.tm.current.colorTextSecondary)
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value4,
        top: this.tm.current.font16,
        bottom: this.tm.current.value8
      })
  }
}
