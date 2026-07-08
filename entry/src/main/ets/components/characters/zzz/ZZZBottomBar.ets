/**
 * ZZZBottomBar — 绝区零角色卡片底部信息栏
 *
 * 显示：等级 | 阵营图标
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ThemeFonts } from '../../../theme/ThemeFonts';

@ComponentV2
export struct ZZZBottomBar {
  @Param level: number = 0;
  @Param groupIconUrl: string = '';
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row({ space: this.tm.current.value8 }) {
      Text($r('app.string.character_level_value', this.level))
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.colorTextSecondary)
        .flexShrink(0)

      if (this.groupIconUrl) {
        Column()
          .width(1)
          .height(this.tm.current.value10)
          .backgroundColor(this.tm.current.colorDivider)
          .flexShrink(0)

        Image(this.groupIconUrl)
          .width(this.tm.current.font20)
          .height(this.tm.current.font20)
          .objectFit(ImageFit.Contain)
          .alt($r('app.string.a11y_faction_icon'))
          .flexShrink(0)
      }
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
export struct ZZZBottomBarPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: 8 }) {
      ZZZBottomBar({ level: 60, groupIconUrl: '' })
      ZZZBottomBar({ level: 60, groupIconUrl: 'https://example.com/icon.png' })
    }
    .padding(16)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}
