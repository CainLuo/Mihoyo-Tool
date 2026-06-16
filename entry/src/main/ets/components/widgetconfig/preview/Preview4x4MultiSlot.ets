/**
 * Preview4x4MultiSlot.ets — Widget 配置预览 4x4 多游戏布局
 *
 * 两个 Preview2x4SingleGame 纵向排列 + 中间水平分隔线。
 * 与实际 Widget4x4 多游戏布局一致。
 */

import { WidgetSlotRef } from '../../../widget/models/WidgetDataStore';
import { WidgetColors } from '../../../widget/models/WidgetUIStates';
import { Preview2x4SingleGame } from './Preview2x4SingleGame';
import { DefaultTheme } from '../../../theme/DefaultTheme';
import { toGameId } from './WidgetPreviewUtils';

@ComponentV2
export struct Preview4x4MultiSlot {
  @Param slots: WidgetSlotRef[] = [];

  @Local theme: DefaultTheme = new DefaultTheme();

  build() {
    Column() {
      // 第一个游戏（2x4 水平布局）
      if (this.slots.length >= 1) {
        Column() {
          Preview2x4SingleGame({
            gameId: toGameId(this.slots[0].gameId),
            roleId: this.slots[0].roleId
          })
        }
        .layoutWeight(1)
      }

      // 分隔线
      if (this.slots.length >= 2) {
        Row()
          .width('100%')
          .height(1)
          .backgroundColor(WidgetColors.WHITE)
          .opacity(0.1)
          .margin({ top: this.theme.value4, bottom: this.theme.value4 })
      }

      // 第二个游戏（2x4 水平布局）
      if (this.slots.length >= 2) {
        Column() {
          Preview2x4SingleGame({
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
