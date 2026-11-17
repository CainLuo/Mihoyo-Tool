/**
 * DailyNoteSectionLabel — 便笺分组标题标签
 *
 * 三个游戏便笺通用，显示"日常"/"宇宙"/"商店"等分组标题。
 * 使用方：DailyNoteStarRail、DailyNoteZZZ
 */
import { themeManager, ThemeManager, ThemeFonts } from 'basic';

@ComponentV2
export struct DailyNoteSectionLabel {
  @Require @Param label: Resource;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Text(this.label)
      .font(ThemeFonts.FONT_13)
      .fontColor(this.tm.current.colorTextSecondary)
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value4,
        top: this.tm.current.font16,
        bottom: this.tm.current.value8
      })
  }
}
