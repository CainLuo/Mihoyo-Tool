/**
 * Widget2x4InfoColumn.ets — 2×4 卡片左侧角色信息列
 *
 * 游戏名（14fp）→ 角色名（12fp，可选）→ UID（12fp）→ 体力数值（22fp）→ 恢复时间（12fp）。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetRoleUIState, WidgetColors, formatRecoveryTimeText, getStaminaColorByType } from 'widgetbase';

@Component
export struct Widget2x4InfoColumn {
  /** 角色 UIState（已解析好的数据） */
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();

  /** 获取体力颜色 */
  private getStaminaColor(): Resource {
    return getStaminaColorByType(this.role.staminaColorType, this.role.gameId);
  }

  build() {
    // 原型：gap: 2px，体力区域 margin-top: 4px
    Column() {
      // 游戏名 14fp
      Text(this.role.gameName)
        .fontSize(14)
        .fontWeight(500)
        .fontColor(WidgetColors.WHITE)
        .opacity(WidgetColors.OPACITY_TEXT_MEDIUM)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 角色名 12fp（如果有）
      if (this.role.roleName.length > 0) {
        Text(this.role.roleName)
          .fontSize(12)
          .fontColor(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_TEXT_MUTED)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }

      // UID 12fp
      Text(this.role.roleIdWithPrefix)
        .fontSize(12)
        .fontColor(WidgetColors.WHITE)
        .opacity(WidgetColors.OPACITY_TEXT_GHOST)
        .maxLines(1)
        .margin({ top: 2 })

      // 体力数值 22fp（原型：margin-top: 4px）
      Row() {
        Text(this.role.currentStamina.toString())
          .fontSize(22)
          .fontWeight(700)
          .fontColor(this.getStaminaColor())

        Text('/' + this.role.maxStamina.toString())
          .fontSize(14)
          .fontColor(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_TEXT_GHOST)
          .margin({ left: 2 })
      }
      .alignItems(VerticalAlign.Bottom)
      .margin({ top: 4 })

      // 恢复时间 12fp（始终显示，满时显示"已满"）
      Text(formatRecoveryTimeText(this.role.recoveryTime))
        .fontSize(12)
        .fontColor(WidgetColors.WHITE)
        .opacity(WidgetColors.OPACITY_TEXT_FAINT)
        .maxLines(1)
        .margin({ top: 2 })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
    .flexShrink(0)
  }
}

@Preview
@Component
struct Widget2x4InfoColumnPreview {
  private role: WidgetRoleUIState = new WidgetRoleUIState();

  aboutToAppear(): void {
    this.role.gameId = 'genshin';
    this.role.gameName = '原神';
    this.role.roleName = '旅行者 · Lv.60';
    this.role.roleIdWithPrefix = 'UID 123456789';
    this.role.currentStamina = 140;
    this.role.maxStamina = 160;
    this.role.recoveryTime.isFull = false;
    this.role.recoveryTime.hours = 4;
    this.role.recoveryTime.minutes = 30;
  }

  build() {
    Column() {
      Widget2x4InfoColumn({ role: this.role })
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
