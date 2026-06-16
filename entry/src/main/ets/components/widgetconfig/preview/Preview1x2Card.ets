/**
 * Preview1x2Card.ets — Widget 配置预览 1x2 卡片
 *
 * 包含左侧游戏色竖线装饰条 + 右侧内容区。
 */

import { GameId } from 'core';
import { Preview1x2Content } from './Preview1x2Content';
import { DefaultTheme } from '../../../theme/DefaultTheme';
import { gameIdToWidgetColor } from './WidgetPreviewUtils';

@ComponentV2
export struct Preview1x2Card {
  @Param gameId: GameId = GameId.GENSHIN;
  @Param roleId: string = '';

  @Local theme: DefaultTheme = new DefaultTheme();

  build() {
    Row({ space: this.theme.value8 }) {
      // 左侧：游戏色竖线装饰条（3vp 宽，上下 8px padding）
      Stack() {
        Column()
          .width(this.theme.value3)
          .borderRadius(this.theme.value2)
          .backgroundColor(gameIdToWidgetColor(this.gameId))
          .height(this.theme.full)
      }
      .width(this.theme.value3)
      .height(this.theme.full)
      .padding({ top: this.theme.value8, bottom: this.theme.value8 })
      .alignContent(Alignment.Center)
      .flexShrink(0)

      // 右侧：游戏名+UID + 体力 + 恢复时间
      Preview1x2Content({
        gameId: this.gameId,
        roleId: this.roleId
      })
    }
    .width(this.theme.full)
    .height(this.theme.full)
    .alignItems(VerticalAlign.Center)
  }
}
