/**
 * WidgetSettingsSlotStep — Widget 配置步骤 3：角色 Slot 选择
 *
 * 使用 GameIdUtil 工具函数获取游戏颜色和名称，避免硬编码。
 */
import { ThemeManager, themeManager } from '../../theme/ThemeManager';
import { WidgetSize } from '../../widget/models/WidgetConfig';
import { WidgetSlotRef } from '../../widget/models/WidgetDataStore';
import { WidgetSlotOption } from './WidgetSlotOption';
import { gameIdStrToColor, gameIdStrToName } from '../../utils/GameIdUtil';

@ComponentV2
export struct WidgetSettingsSlotStep {
  @Param selectedSize: WidgetSize = WidgetSize.SIZE_2x2;
  @Param allSlots: WidgetSlotRef[] = [];
  @Param selectedSlots: WidgetSlotRef[] = [];
  @Param maxSlots: number = 4;
  @Param isSlotSelected: (accountId: string, gameId: string, roleId: string) => boolean = (_a: string, _g: string, _r: string) => false;
  @Param onSlotToggle: (slot: WidgetSlotRef) => void = (_slot: WidgetSlotRef) => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value10 }) {
      if (this.selectedSize === WidgetSize.SIZE_1x2) {
        Text($r('app.string.widget_select_account_hint'))
          .fontSize(this.tm.current.body12.size)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.full)
          .margin({ bottom: this.tm.current.value8 })
      } else {
        Text($r('app.string.widget_selected_count', this.selectedSlots.length, this.maxSlots))
          .fontSize(this.tm.current.body12.size)
          .fontColor(this.tm.current.colorPrimary)
          .width(this.tm.current.full)
          .margin({ bottom: this.tm.current.value8 })
      }

      ForEach(this.allSlots, (slot: WidgetSlotRef) => {
        WidgetSlotOption({
          slot: slot,
          gameColor: gameIdStrToColor(slot.gameId),
          gameName: gameIdStrToName(slot.gameId),
          isSelected: this.isSlotSelected(slot.accountId, slot.gameId, slot.roleId),
          onTap: () => { this.onSlotToggle(slot); }
        })
      }, (slot: WidgetSlotRef) => slot.key)
    }
    .width(this.tm.current.full)
  }
}

@Preview
@ComponentV2
export struct WidgetSettingsSlotStepPreview {
  @Local private tm: ThemeManager = themeManager;
  @Local private selectedSlots: WidgetSlotRef[] = [];

  build() {
    Column() {
      WidgetSettingsSlotStep({
        selectedSize: WidgetSize.SIZE_2x2,
        allSlots: [],
        selectedSlots: this.selectedSlots,
        maxSlots: 4,
        isSlotSelected: () => false,
        onSlotToggle: () => {}
      })
    }
    .width(this.tm.current.value360)
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
