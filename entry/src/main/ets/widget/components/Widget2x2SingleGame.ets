/**
 * Widget2x2SingleGame.ets — 2×2 单游戏详细布局
 *
 * 严格按原型 wr-2x2.js 单游戏分支实现：
 * - 头部：游戏名（12px）+ UID（10px，换行显示）
 * - 体力区块：当前（24px Bold）/ 最大（14px）+ 恢复时间（11px）
 *   - 星铁特殊：后备开拓力放在右侧
 * - 数据行：最多 2 行（11px），居中对齐
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 *
 * 重构说明：
 * - 所有数据通过 WidgetRoleUIState 传入，组件内部不做任何数据转换
 * - gameNameResource/labelResource/displayValue 已在 ViewModel 中转换为资源
 * - 组件只负责渲染，不包含业务逻辑
 * - 子组件拆分：Widget2x2Header、Widget2x2StaminaBlock、WidgetExtraDataRows
 */

import { WidgetRoleUIState, StaminaColorType, WidgetColors } from '../models/WidgetUIStates';
import { WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { DefaultTheme } from '../../theme/DefaultTheme';
import { Widget2x2Header } from './Widget2x2Header';
import { Widget2x2StaminaBlock } from './Widget2x2StaminaBlock';
import { WidgetExtraDataRows } from './WidgetExtraDataRows';

@Component
export struct Widget2x2SingleGame {
  /** 角色 UIState（已解析好的数据） */
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();

  /** 是否在嵌套容器中使用（不使用 layoutWeight 和 100% 高度） */
  inNestedContainer: boolean = false;

  /** 主题常量 */
  theme: DefaultTheme = new DefaultTheme();

  aboutToAppear(): void {
    // Widget 组件初始化
  }

  build() {
    Column() {
      // ── 头部：游戏名 + UID ──
      Widget2x2Header({
        gameNameResource: this.role.gameNameResource,
        roleIdWithPrefix: this.role.roleIdWithPrefix,
        theme: this.theme
      })

      // ── 体力区块 ──
      Widget2x2StaminaBlock({
        role: this.role
      })

      // ── 底部：额外数据行 ──
      WidgetExtraDataRows({
        extraRows: this.role.extraRows,
        inNestedContainer: this.inNestedContainer,
        theme: this.theme
      })
    }
    .width(this.theme.full)
    .height(this.inNestedContainer ? undefined : this.theme.full)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }
}

@Preview
@Component
struct Widget2x2SingleGamePreview {
  // Widget 使用 @Component，不能用 @Local，用普通属性
  private role: WidgetRoleUIState = new WidgetRoleUIState();

  aboutToAppear(): void {
    // 初始化预览数据
    this.role.gameId = WIDGET_GAME_ID.GENSHIN;
    this.role.gameName = '原神';
    this.role.gameNameResource = $r('app.string.widget_game_genshin');
    this.role.gameColor = WidgetColors.GENSHIN_PRIMARY;
    this.role.roleId = '123456789';
    this.role.roleIdWithPrefix = 'UID 123456789';
    this.role.currentStamina = 140;
    this.role.maxStamina = 160;
    this.role.recoveryTime.isFull = true;
    this.role.staminaColorType = StaminaColorType.HIGH;
  }

  build() {
    Column({ space: 12 }) {
      Widget2x2SingleGame({ role: this.role })
        .width(168)
        .height(168)
        .padding(12)
        .linearGradient({ angle: 135, colors: [[$r('app.color.widget_bg_genshin_1'), 0], [$r('app.color.widget_bg_genshin_3'), 1]] })
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
