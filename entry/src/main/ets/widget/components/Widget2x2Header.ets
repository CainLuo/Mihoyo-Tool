/**
 * Widget2x2Header.ets — 2×2 Widget 头部组件
 *
 * 显示游戏名称和角色 UID。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetColors } from '../models/WidgetUIStates';
import { DefaultTheme } from '../../theme/DefaultTheme';

@Component
export struct Widget2x2Header {
  /** 游戏名称资源（已在 ViewModel 中转换） */
  gameNameResource: ResourceStr = '';

  /** 角色 UID（含前缀，已在 ViewModel 中转换） */
  roleIdWithPrefix: string = '';

  /** 主题常量 */
  theme: DefaultTheme = new DefaultTheme();

  build() {
    Column({ space: this.theme.value1 }) {
      Text(this.gameNameResource)
        .fontSize(this.theme.font13)
        .fontWeight(FontWeight.Bold)
        .fontColor(WidgetColors.WHITE)
        .opacity(WidgetColors.OPACITY_TEXT_HIGH)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.roleIdWithPrefix)
        .fontSize(this.theme.font10)
        .fontColor(WidgetColors.WHITE)
        .opacity(WidgetColors.OPACITY_TEXT_MUTED)
    }
    .width(this.theme.full)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: this.theme.value8 })
  }
}

@Preview
@Component
struct Widget2x2HeaderPreview {
  build() {
    Column({ space: 12 }) {
      Widget2x2Header({
        gameNameResource: $r('app.string.widget_game_genshin'),
        roleIdWithPrefix: 'UID 123456789'
      })
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
