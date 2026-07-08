/**
 * StarRailBottomBar — 星穹铁道角色卡片底部信息栏
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ThemeFonts } from '../../../theme/ThemeFonts';

@ComponentV2
export struct StarRailBottomBar {
  @Param level: number = 0;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row() {
      Text($r('app.string.character_level_value', this.level))
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .alignItems(VerticalAlign.Center)
    .padding({
      top: this.tm.current.value8,
      bottom: this.tm.current.value8,
      left: this.tm.current.value10,
      right: this.tm.current.value10
    })
  }
}

@Preview
@ComponentV2
export struct StarRailBottomBarPreview {
  build() {
    Column({ space: 8 }) {
      StarRailBottomBar({ level: 80 })
      StarRailBottomBar({ level: 60 })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
