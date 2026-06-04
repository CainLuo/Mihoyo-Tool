/**
 * Widget2x2StaminaBlock.ets — 2×2 Widget 体力区块组件
 *
 * 根据游戏类型选择不同的布局：
 * - 星铁：使用 Widget2x2StarRailStamina（左侧体力 + 右侧后备开拓力）
 * - 原神/绝区零：使用 Widget2x2StandardStamina（标准布局）
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetRoleUIState, StaminaColorType } from '../models/WidgetUIStates';
import { WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { Widget2x2StarRailStamina } from './Widget2x2StarRailStamina';
import { Widget2x2StandardStamina } from './Widget2x2StandardStamina';

@Component
export struct Widget2x2StaminaBlock {
  /** 角色 UIState */
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();

  build() {
    if (this.role.gameId === WIDGET_GAME_ID.STARRAIL) {
      Widget2x2StarRailStamina({ role: this.role })
    } else {
      Widget2x2StandardStamina({ role: this.role })
    }
  }
}

@Preview
@Component
struct Widget2x2StaminaBlockPreview {
  // Widget 使用 @Component，不能用 @Local，用普通属性
  private role: WidgetRoleUIState = new WidgetRoleUIState();

  aboutToAppear(): void {
    this.role.gameId = WIDGET_GAME_ID.GENSHIN;
    this.role.currentStamina = 140;
    this.role.maxStamina = 160;
    this.role.recoveryTime.isFull = false;
    this.role.recoveryTime.hours = 2;
    this.role.recoveryTime.minutes = 30;
    this.role.staminaColorType = StaminaColorType.HIGH;
    this.role.gameColor = $r('app.color.game_color_genshin');
  }

  build() {
    Column({ space: 12 }) {
      Widget2x2StaminaBlock({ role: this.role })
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
