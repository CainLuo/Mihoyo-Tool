/**
 * Widget4x4StaminaBlock.ets — 4×4 Widget 体力区块
 *
 * 标签 + 体力数值 + 恢复时间；星铁额外显示后备开拓力。
 * 固定高度（由内容决定），底部带分隔线。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetRoleUIState, WidgetGameId, StaminaColorType, WidgetColors,
  formatRecoveryTimeText, getStaminaColorByType } from 'widgetbase';

@Component
export struct Widget4x4StaminaBlock {
  /** 角色 UIState（已解析好的数据） */
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();

  /** 获取体力颜色 */
  private getStaminaColor(): Resource {
    return getStaminaColorByType(this.role.staminaColorType, this.role.gameId);
  }

  /** 获取体力标签文字 */
  private getStaminaLabel(): string {
    if (this.role.gameId === WidgetGameId.STARRAIL) {
      return '开拓力';
    } else if (this.role.gameId === WidgetGameId.ZZZ) {
      return '电量';
    }
    return '原粹树脂';
  }

  build() {
    Column() {
      // 标签（10fp）
      Text(this.getStaminaLabel())
        .fontSize(10)
        .fontColor(WidgetColors.WHITE)
        .opacity(0.3)
        .margin({ bottom: 4 })

      // 数值行
      Row() {
        Text(this.role.currentStamina.toString())
          .fontSize(40)
          .fontWeight(700)
          .fontColor(this.getStaminaColor())

        Text('/ ' + this.role.maxStamina.toString())
          .fontSize(14)
          .fontColor(WidgetColors.WHITE)
          .opacity(0.3)
          .margin({ left: 4 })
      }
      .alignItems(VerticalAlign.Bottom)
      .margin({ bottom: 3 })

      // 恢复时间
      Text(formatRecoveryTimeText(this.role.recoveryTime))
        .fontSize(12)
        .fontColor(WidgetColors.WHITE)
        .opacity(0.5)

      // 星铁：后备开拓力
      if (this.role.gameId === WidgetGameId.STARRAIL && this.role.reserveStamina.length > 0) {
        Row() {
          Text('后备开拓力')
            .fontSize(11)
            .fontColor(WidgetColors.WHITE)
            .opacity(0.35)

          Text(this.role.reserveStamina)
            .fontSize(13)
            .fontWeight(600)
            .fontColor(this.role.gameColor)
            .margin({ left: 6 })
        }
        .margin({ top: 3 })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 8, bottom: 8 })
    .border({ width: { bottom: 1 }, color: 'rgba(255,255,255,0.1)' })
  }
}

@Preview
@Component
struct Widget4x4StaminaBlockPreview {
  private role: WidgetRoleUIState = new WidgetRoleUIState();

  aboutToAppear(): void {
    this.role.gameId = WidgetGameId.GENSHIN;
    this.role.currentStamina = 140;
    this.role.maxStamina = 160;
    this.role.recoveryTime.isFull = false;
    this.role.recoveryTime.hours = 4;
    this.role.recoveryTime.minutes = 30;
    this.role.staminaColorType = StaminaColorType.HIGH;
    this.role.gameColor = $r('app.color.game_color_genshin');
  }

  build() {
    Column() {
      Widget4x4StaminaBlock({ role: this.role })
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
