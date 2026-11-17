/**
 * Widget2x2Header.ets — 2×2 Widget 头部组件
 *
 * 显示游戏名称和角色 UID。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetColors, DefaultTheme, formatUpdatedAtCompactText, isWidgetDataStale } from 'widgetbase';

@Component
export struct Widget2x2Header {
  /** 游戏名称资源（已在 ViewModel 中转换） */
  gameNameResource: ResourceStr = '';

  /** 角色 UID（含前缀，已在 ViewModel 中转换） */
  roleIdWithPrefix: string = '';

  /** 数据拉取时间（秒），0 表示不显示新鲜度 */
  dataUpdatedAt: number = 0;

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

      Row() {
        Text(this.roleIdWithPrefix)
          .fontSize(this.theme.font10)
          .fontColor(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_TEXT_MUTED)
          .maxLines(1)
          .layoutWeight(1)

        // 数据新鲜度：2x2 宽度有限，用紧凑文案（刚刚 / 12分钟前）
        if (this.dataUpdatedAt > 0) {
          Text(formatUpdatedAtCompactText(this.dataUpdatedAt, Math.floor(Date.now() / 1000)))
            .fontSize(this.theme.font9)
            .fontColor(isWidgetDataStale(this.dataUpdatedAt, Math.floor(Date.now() / 1000))
              ? WidgetColors.STAMINA_MEDIUM : WidgetColors.WHITE)
            .opacity(isWidgetDataStale(this.dataUpdatedAt, Math.floor(Date.now() / 1000))
              ? WidgetColors.OPACITY_TEXT_HIGH : WidgetColors.OPACITY_TEXT_GHOST)
            .maxLines(1)
        }
      }
      .width(this.theme.full)
      .alignItems(VerticalAlign.Center)
    }
    .width(this.theme.full)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: this.theme.value6 })
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
