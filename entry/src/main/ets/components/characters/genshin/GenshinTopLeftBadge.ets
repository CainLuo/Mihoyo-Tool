/**
 * GenshinTopLeftBadge — 原神角色卡片左上角元素图标
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { genshinElementFromString, elementIcon } from '../../../constants/GenshinElement';

@ComponentV2
export struct GenshinTopLeftBadge {
  @Param element: string = '';
  @Local private tm: ThemeManager = themeManager;

  build() {
    if (elementIcon(genshinElementFromString(this.element)) !== null) {
      Image(elementIcon(genshinElementFromString(this.element)) as Resource)
        .width(this.tm.current.font24)
        .height(this.tm.current.font24)
        .objectFit(ImageFit.Contain)
        .alt($r('app.string.a11y_element_icon', this.element))
        .position({ x: this.tm.current.value8, y: this.tm.current.value8 })
        .zIndex(3)
    }
  }
}

@Preview
@ComponentV2
export struct GenshinTopLeftBadgePreview {
  build() {
    Column({ space: 8 }) {
      GenshinTopLeftBadge({ element: 'Hydro' })
      GenshinTopLeftBadge({ element: 'Pyro' })
      GenshinTopLeftBadge({ element: 'Dendro' })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
