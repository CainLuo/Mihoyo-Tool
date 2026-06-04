/**
 * Widget2x2StandardStamina.ets — 2×2 Widget 标准体力区块组件
 *
 * 原神/绝区零标准布局：当前体力 + 恢复时间。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetRoleUIState, StaminaColorType, WidgetColors } from '../models/WidgetUIStates';
import { getStaminaColorByType, formatRecoveryTimeText } from '../utils/WidgetUtils';
import { DefaultTheme } from '../../theme/DefaultTheme';

@Component
export struct Widget2x2StandardStamina {
  /** 角色 UIState */
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();

  /** 主题常量 */
  theme: DefaultTheme = new DefaultTheme();

  build() {
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
    .width(this.theme.full)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: this.theme.value8 })
  }
}

@Preview
@Component
struct Widget2x2StandardStaminaPreview {
  // Widget 使用 @Component，不能用 @Local，用普通属性
  private role: WidgetRoleUIState = new WidgetRoleUIState();

  aboutToAppear(): void {
    this.role.gameId = 'genshin';
    this.role.currentStamina = 140;
    this.role.maxStamina = 160;
    this.role.recoveryTime.isFull = false;
    this.role.recoveryTime.hours = 2;
    this.role.recoveryTime.minutes = 30;
    this.role.staminaColorType = StaminaColorType.HIGH;
  }

  build() {
    Column({ space: 12 }) {
      Widget2x2StandardStamina({ role: this.role })
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
