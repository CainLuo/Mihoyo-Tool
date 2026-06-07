/**
 * WidgetConfigPreviewPreview.ets — WidgetConfigPreview 预览组件
 *
 * 展示 WidgetConfigPreview 的多种状态：
 * - 空态
 * - 单游戏
 * - 多游戏
 * - 不同尺寸
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetSize } from '../../widget/models/WidgetConfig';
import { WidgetSlotRef } from '../../widget/models/WidgetDataStore';
import { GameId } from 'core';
import { WidgetConfigPreview } from './WidgetConfigPreview';

@Preview
@ComponentV2
export struct WidgetConfigPreviewPreview {
  @Local private tm: ThemeManager = themeManager;
  @Local private sampleSlots: WidgetSlotRef[] = [];

  aboutToAppear(): void {
    const slot1 = new WidgetSlotRef();
    slot1.accountId = '1';
    slot1.accountName = '旅行者A';
    slot1.gameId = GameId.GENSHIN;
    slot1.roleId = '123456789';
    slot1.nickname = '荧';
    slot1.server = 'cn_gf01';

    const slot2 = new WidgetSlotRef();
    slot2.accountId = '1';
    slot2.accountName = '旅行者A';
    slot2.gameId = GameId.STARRAIL;
    slot2.roleId = '987654321';
    slot2.nickname = '开拓者';
    slot2.server = 'prod_gf_cn';

    this.sampleSlots = [slot1, slot2];
  }

  build() {
    Column({ space: 16 }) {
      // 空态
      WidgetConfigPreview({
        selectedSize: WidgetSize.SIZE_2x2,
        selectedSlots: []
      })

      // 单游戏
      WidgetConfigPreview({
        selectedSize: WidgetSize.SIZE_2x2,
        selectedSlots: [this.sampleSlots[0]]
      })

      // 多游戏
      WidgetConfigPreview({
        selectedSize: WidgetSize.SIZE_2x2,
        selectedSlots: this.sampleSlots
      })

      // 2x4 多游戏
      WidgetConfigPreview({
        selectedSize: WidgetSize.SIZE_2x4,
        selectedSlots: this.sampleSlots
      })

      // 4x4 多游戏
      WidgetConfigPreview({
        selectedSize: WidgetSize.SIZE_4x4,
        selectedSlots: this.sampleSlots
      })
    }
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}
