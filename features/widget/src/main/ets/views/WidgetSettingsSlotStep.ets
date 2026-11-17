/**
 * WidgetSettingsSlotStep — Widget 配置步骤 3：角色 Slot 选择
 *
 * - 1x2 卡片：显示单一游戏的账号列表（扁平）
 * - 2x2 及以上：按账号分组显示，复用通用的 UserGameSection 容器，角色卡片渲染为 WidgetSlotOption
 */
import { ThemeManager, themeManager, MihoyoAccountVM, GameRoleCardVM, UserGameSection, getGameColorByStr, getGameNameByStr } from 'basic';
import { WidgetSize } from '../model/WidgetConfigModels';
import { WidgetSlotRef } from '../model/WidgetDataStoreModels';
import { WidgetSlotOption } from './WidgetSlotOption';

@ComponentV2
export struct WidgetSettingsSlotStep {
  @Param selectedSize: WidgetSize = WidgetSize.SIZE_2X2;
  @Param allSlots: WidgetSlotRef[] = [];
  /** 按账号分组的 slots（仅 2x2 及以上尺寸使用，直接复用 MihoyoAccountVM） */
  @Param accountGroups: MihoyoAccountVM[] = [];
  @Param selectedSlots: WidgetSlotRef[] = [];
  @Param maxSlots: number = 4;
  @Param isSlotSelected: (accountId: string, gameId: string, roleId: string) => boolean = (_a: string, _g: string, _r: string) => false;
  @Param onSlotToggle: (slot: WidgetSlotRef) => void = (_slot: WidgetSlotRef) => {};

  @Local private tm: ThemeManager = themeManager;

  /** 由账号 + 角色构建 WidgetSlotRef */
  private buildSlotRef(account: MihoyoAccountVM, role: GameRoleCardVM): WidgetSlotRef {
    const slot = new WidgetSlotRef();
    slot.accountId = account.accountId;
    slot.accountName = account.nickname !== '' ? account.nickname : account.username;
    slot.gameId = role.gameId;
    slot.roleId = role.roleUid;
    slot.nickname = role.nickname;
    slot.server = role.server as string;
    return slot;
  }

  /** 按账号分组时的角色卡片：点击切换选中 */
  @Builder
  slotRoleBuilder(account: MihoyoAccountVM, role: GameRoleCardVM) {
    WidgetSlotOption({
      slot: this.buildSlotRef(account, role),
      gameColor: getGameColorByStr(role.gameId),
      gameName: getGameNameByStr(role.gameId),
      isSelected: this.isSlotSelected(account.accountId, role.gameId, role.roleUid),
      onTap: () => {
        this.onSlotToggle(this.buildSlotRef(account, role));
      }
    })
  }

  build() {
    Column({ space: this.tm.current.value10 }) {
      // 顶部提示文字
      if (this.selectedSize === WidgetSize.SIZE_1X2) {
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
      if (this.selectedSize === WidgetSize.SIZE_1X2) {
        Column({ space: this.tm.current.value12 }) {
          ForEach(this.allSlots, (slot: WidgetSlotRef) => {
            WidgetSlotOption({
              slot: slot,
              gameColor: getGameColorByStr(slot.gameId),
              gameName: getGameNameByStr(slot.gameId),
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
            roleBuilder: (role: GameRoleCardVM): void => { this.slotRoleBuilder(account, role) }
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
        selectedSize: WidgetSize.SIZE_2X2,
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
