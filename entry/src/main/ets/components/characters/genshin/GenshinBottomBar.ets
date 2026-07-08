/**
 * GenshinBottomBar — 原神角色卡片底部信息栏
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ThemeFonts } from '../../../theme/ThemeFonts';

@ComponentV2
export struct GenshinBottomBar {
  @Param level: number = 0;
  @Param fetter: number = 0;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value8 }) {
      Text($r('app.string.character_level_value', this.level))
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.colorTextSecondary)

      Column()
        .width(1)
        .height(this.tm.current.value10)
        .backgroundColor(this.tm.current.colorDivider)

      Text($r('app.string.character_fetter_value', this.fetter))
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
export struct GenshinBottomBarPreview {
  build() {
    Column({ space: 8 }) {
      GenshinBottomBar({ level: 90, fetter: 10 })
      GenshinBottomBar({ level: 60, fetter: 5 })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
