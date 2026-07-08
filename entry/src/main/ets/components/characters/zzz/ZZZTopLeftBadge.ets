/**
 * ZZZTopLeftBadge — 绝区零角色卡片左上角稀有度+属性+特性图标
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { zzzElementIcon, zzzProfessionIcon } from '../../../constants/ZZZElement';

@ComponentV2
export struct ZZZTopLeftBadge {
  @Param rarity: number = 0;
  @Param element: number = 0;
  @Param profession: number = 0;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      // 稀有度图标（S/A）
      Image(this.rarity >= 5
        ? $r('app.media.zzz_rarity_s')
        : $r('app.media.zzz_rarity_a'))
        .width(this.tm.current.value22)
        .height(this.tm.current.value22)
        .objectFit(ImageFit.Contain)
        .alt($r('app.string.a11y_rarity_icon', this.rarity >= 5 ? 'S' : 'A'))

      // 属性图标
      if (zzzElementIcon(this.element) !== null) {
        Image(zzzElementIcon(this.element) as Resource)
          .width(this.tm.current.value22)
          .height(this.tm.current.value22)
          .objectFit(ImageFit.Contain)
          .alt($r('app.string.a11y_element_icon_generic'))
      }

      // 特性图标
      if (zzzProfessionIcon(this.profession) !== null) {
        Image(zzzProfessionIcon(this.profession) as Resource)
          .width(this.tm.current.value22)
          .height(this.tm.current.value22)
          .objectFit(ImageFit.Contain)
          .alt($r('app.string.a11y_profession_icon'))
      }
    }
    .alignItems(HorizontalAlign.Start)
    .position({ x: this.tm.current.value8, y: this.tm.current.value8 })
    .zIndex(3)
  }
}

@Preview
@ComponentV2
export struct ZZZTopLeftBadgePreview {
  build() {
    Column({ space: 8 }) {
      ZZZTopLeftBadge({ rarity: 5, element: 200, profession: 1 })
      ZZZTopLeftBadge({ rarity: 4, element: 100, profession: 2 })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
