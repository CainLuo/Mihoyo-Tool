/**
 * Preview2x2MultiSlot.ets — Widget 配置预览 2x2 多游戏布局
 *
 * 两个 1x2 卡片纵向排列 + 中间分隔线。
 * 每个 1x2 卡片包含左侧游戏色装饰条 + 内容区。
 */

import { WidgetSlotRef } from '../../../widget/models/WidgetDataStore';
import { WidgetColors } from '../../../widget/models/WidgetUIStates';
import { Preview1x2Card } from './Preview1x2Card';
import { DefaultTheme } from '../../../theme/DefaultTheme';
import { toGameId } from './WidgetPreviewUtils';

@ComponentV2
export struct Preview2x2MultiSlot {
  @Param slots: WidgetSlotRef[] = [];

  @Local theme: DefaultTheme = new DefaultTheme();

  build() {
    Column() {
      // 第一个游戏
      if (this.slots.length >= 1) {
        Preview1x2Card({
          gameId: toGameId(this.slots[0].gameId),
          roleId: this.slots[0].roleId
        })
          .layoutWeight(1)
      }

      // 分隔线
      if (this.slots.length >= 2) {
        Divider()
          .color(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_BORDER)
          .strokeWidth(1)
          .margin({ top: this.theme.value4, bottom: this.theme.value4 })
      }

      // 第二个游戏
      if (this.slots.length >= 2) {
        Preview1x2Card({
          gameId: toGameId(this.slots[1].gameId),
          roleId: this.slots[1].roleId
        })
          .layoutWeight(1)
      }
    }
    .width(this.theme.full)
    .height(this.theme.full)
  }
}
