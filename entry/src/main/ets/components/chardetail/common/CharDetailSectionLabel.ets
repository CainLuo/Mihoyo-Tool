/**
 * CharDetailSectionLabel — 角色详情各 Section 的标题标签
 *
 * 三个游戏的内容区（原神/星铁/绝区零）共用同一样式。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';

@ComponentV2
export struct CharDetailSectionLabel {
  @Param title: Resource = $r('app.string.char_detail_no_data');
  @Local private tm: ThemeManager = themeManager;

  build() {
    Text(this.title)
      .fontSize(this.tm.current.body12.size)
      .fontColor(this.tm.current.textOnDarkSecondary)
      .width(this.tm.current.full)
      .padding({ bottom: this.tm.current.value4 })
  }
}
