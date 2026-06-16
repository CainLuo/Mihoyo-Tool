/**
 * Preview2x4MultiSlot.ets — Widget 配置预览 2x4 多游戏布局
 *
 * 两个 2x2 单游戏布局横向排列 + 中间垂直分隔线。
 */

import { WidgetSlotRef } from '../../../widget/models/WidgetDataStore';
import { WidgetColors } from '../../../widget/models/WidgetUIStates';
import { Preview2x2SingleGame } from './Preview2x2SingleGame';
import { DefaultTheme } from '../../../theme/DefaultTheme';
import { toGameId } from './WidgetPreviewUtils';

@ComponentV2
export struct Preview2x4MultiSlot {
  @Param slots: WidgetSlotRef[] = [];

  @Local theme: DefaultTheme = new DefaultTheme();

  build() {
    Row() {
      // 第一个游戏
      if (this.slots.length >= 1) {
        Column() {
          Preview2x2SingleGame({
            gameId: toGameId(this.slots[0].gameId),
            roleId: this.slots[0].roleId
          })
        }
        .layoutWeight(1)
      }

      // 分隔线
      if (this.slots.length >= 2) {
        Divider()
          .vertical(true)
          .color(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_BORDER)
          .strokeWidth(1)
          .height(this.theme.pct80)
          .margin({ left: this.theme.value8, right: this.theme.value8 })
      }

      // 第二个游戏
      if (this.slots.length >= 2) {
        Column() {
          Preview2x2SingleGame({
            gameId: toGameId(this.slots[1].gameId),
            roleId: this.slots[1].roleId
          })
        }
        .layoutWeight(1)
      }
    }
    .width(this.theme.full)
    .height(this.theme.full)
  }
}
