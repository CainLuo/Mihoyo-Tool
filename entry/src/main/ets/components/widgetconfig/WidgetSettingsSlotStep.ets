/**
 * WidgetSettingsSlotStep — Widget 配置步骤 3：角色 Slot 选择
 *
 * - 1x2 卡片：显示单一游戏的账号列表（扁平）
 * - 2x2 及以上：按账号分组显示，复用首页的 UserGameSection 组件
 */
import { ThemeManager, themeManager } from '../../theme/ThemeManager';
import { WidgetSize } from '../../widget/models/WidgetConfig';
import { WidgetSlotRef } from '../../widget/models/WidgetDataStore';
import { MihoyoAccountVM } from '../../models/HomeModels';
import { WidgetSlotOption } from './WidgetSlotOption';
import { UserGameSection, UserGameSectionMode } from '../home/UserGameSection';
import { gameIdStrToColor, gameIdStrToName } from '../../utils/GameIdUtil';

@ComponentV2
export struct WidgetSettingsSlotStep {
  @Param selectedSize: WidgetSize = WidgetSize.SIZE_2x2;
  @Param allSlots: WidgetSlotRef[] = [];
  /** 按账号分组的 slots（仅 2x2 及以上尺寸使用，直接复用 MihoyoAccountVM） */
  @Param accountGroups: MihoyoAccountVM[] = [];
  @Param selectedSlots: WidgetSlotRef[] = [];
  @Param maxSlots: number = 4;
  @Param isSlotSelected: (accountId: string, gameId: string, roleId: string) => boolean = (_a: string, _g: string, _r: string) => false;
  @Param onSlotToggle: (slot: WidgetSlotRef) => void = (_slot: WidgetSlotRef) => {};

  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value10 }) {
      // 顶部提示文字
      if (this.selectedSize === WidgetSize.SIZE_1x2) {
        Text($r('app.string.widget_select_account_hint'))
          .fontSize(this.tm.current.font13)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.full)
          .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
          .margin({ bottom: this.tm.current.value8 })
      } else {
        Text($r('app.string.widget_selected_count', this.selectedSlots.length, this.maxSlots))
          .fontSize(this.tm.current.font13)
          .fontColor(this.tm.current.colorPrimary)
          .width(this.tm.current.full)
          .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
          .margin({ bottom: this.tm.current.value8 })
      }

      // 1x2 卡片：扁平列表
      if (this.selectedSize === WidgetSize.SIZE_1x2) {
        Column({ space: this.tm.current.value12 }) {
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
        .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
      } else {
        // 2x2 及以上：按账号分组，复用 UserGameSection（Widget 配置模式）
        ForEach(this.accountGroups, (account: MihoyoAccountVM) => {
          UserGameSection({
            account: account,
            mode: UserGameSectionMode.WIDGET_CONFIG,
            isSlotSelected: this.isSlotSelected,
            onSlotToggle: this.onSlotToggle
          })
        }, (account: MihoyoAccountVM) => account.accountId)
      }
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
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}
