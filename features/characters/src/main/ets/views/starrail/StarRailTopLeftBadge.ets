/**
 * StarRailTopLeftBadge — 星穹铁道角色卡片左上角属性+命途图标
 */
import { themeManager, ThemeManager, getStarRailElementIcon, getStarRailPathIcon } from 'basic';

@ComponentV2
export struct StarRailTopLeftBadge {
  @Param element: string = '';
  @Param path: number = 0;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      // 属性图标
      if (getStarRailElementIcon(this.element) !== null) {
        Image(getStarRailElementIcon(this.element) as Resource)
          .width(this.tm.current.value22)
          .height(this.tm.current.value22)
          .objectFit(ImageFit.Contain)
          .alt($r('app.string.a11y_element_icon', this.element))
      }
      // 命途图标
      if (getStarRailPathIcon(this.path) !== null) {
        Image(getStarRailPathIcon(this.path) as Resource)
          .width(this.tm.current.value22)
          .height(this.tm.current.value22)
          .objectFit(ImageFit.Contain)
          .alt($r('app.string.a11y_path_icon'))
      }
    }
    .alignItems(HorizontalAlign.Start)
    .position({ x: this.tm.current.value8, y: this.tm.current.value8 })
    .zIndex(3)
  }
}

@Preview
@ComponentV2
export struct StarRailTopLeftBadgePreview {
  build() {
    Column({ space: 8 }) {
      StarRailTopLeftBadge({ element: 'wind', path: 4 })
      StarRailTopLeftBadge({ element: 'fire', path: 2 })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
