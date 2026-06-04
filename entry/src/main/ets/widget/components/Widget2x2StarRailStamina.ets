/**
 * Widget2x2StarRailStamina.ets — 2×2 Widget 星铁体力区块组件
 *
 * 星铁特殊布局：左侧体力 + 右侧后备开拓力。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetRoleUIState, StaminaColorType, WidgetColors } from '../models/WidgetUIStates';
import { getGameColor, getStaminaColorByType, formatRecoveryTimeText } from '../utils/WidgetUtils';
import { DefaultTheme } from '../../theme/DefaultTheme';

@Component
export struct Widget2x2StarRailStamina {
  /** 角色 UIState */
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();

  /** 主题常量 */
  theme: DefaultTheme = new DefaultTheme();

  build() {
    Row() {
      // 左侧：当前/最大 + 恢复时间
      Column({ space: this.theme.value2 }) {
        Row({ space: this.theme.value3 }) {
          Text(String(this.role.currentStamina))
            .fontSize(this.theme.font24)
            .fontWeight(FontWeight.Bold)
            .fontColor(getStaminaColorByType(this.role.staminaColorType, this.role.gameId))

          Text('/' + String(this.role.maxStamina))
            .fontSize(this.theme.font14)
            .fontColor(WidgetColors.WHITE)
            .opacity(WidgetColors.OPACITY_TEXT_MUTED)
        }
        .alignItems(VerticalAlign.Bottom)

        Text(formatRecoveryTimeText(this.role.recoveryTime))
          .fontSize(this.theme.font11)
          .fontColor(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_TEXT_MEDIUM)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧：后备开拓力
      Column({ space: this.theme.value1 }) {
        Text($r('app.string.widget_reserve_prefix'))
          .fontSize(this.theme.font9)
          .fontColor(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_TEXT_MUTED)

        Text(this.role.reserveStamina)
          .fontSize(this.theme.font13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.role.gameColor)
      }
      .alignItems(HorizontalAlign.End)
    }
    .width(this.theme.full)
    .alignItems(VerticalAlign.Top)
    .margin({ bottom: this.theme.value8 })
  }
}

@Preview
@Component
struct Widget2x2StarRailStaminaPreview {
  // Widget 使用 @Component，不能用 @Local，用普通属性
  private role: WidgetRoleUIState = new WidgetRoleUIState();

  aboutToAppear(): void {
    this.role.gameId = 'starrail';
    this.role.currentStamina = 180;
    this.role.maxStamina = 240;
    this.role.recoveryTime.isFull = false;
    this.role.recoveryTime.hours = 4;
    this.role.recoveryTime.minutes = 30;
    this.role.staminaColorType = StaminaColorType.HIGH;
    this.role.gameColor = WidgetColors.STARRAIL_PRIMARY;
    this.role.reserveStamina = '2400';
  }

  build() {
    Column({ space: 12 }) {
      Widget2x2StarRailStamina({ role: this.role })
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
