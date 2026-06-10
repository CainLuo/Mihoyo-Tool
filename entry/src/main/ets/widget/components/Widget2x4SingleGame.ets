/**
 * Widget2x4SingleGame.ets — 2×4 单游戏水平布局
 *
 * 严格按原型 wr-2x4.js 单游戏分支实现：
 * - 左侧：体力环（Progress Ring，80px，stroke=7）+ 恢复时间（10px）
 * - 右侧：游戏名（12px）+ UID（10px）+ 星铁后备开拓力 + 额外数据行（最多4条，12px）
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 *
 * 重构说明：
 * - 所有数据通过 WidgetRoleUIState 传入，组件内部不做任何数据转换
 * - 组件只负责渲染，不包含业务逻辑
 */

import {
  WidgetRoleUIState,
  WidgetExtraRow,
  StaminaColorType,
  WidgetColors
} from '../models/WidgetUIStates';
import { WIDGET_GAME_ID, formatRecoveryTimeText } from '../utils/WidgetUtils';
import { DefaultTheme } from '../../theme/DefaultTheme';

/** 体力环尺寸常量 */
const RING_SIZE: number = 80;
const RING_STROKE: number = 7;

@Component
export struct Widget2x4SingleGame {
  /** 角色 UIState（已解析好的数据） */
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();

  /** 是否在嵌套容器中（用于 4x4 多游戏模式，移除左右 margin） */
  @Prop inNestedContainer: boolean = false;

  /** 主题常量 */
  theme: DefaultTheme = new DefaultTheme();

  /** 获取体力颜色 */
  private getStaminaColor(): ResourceColor {
    switch (this.role.staminaColorType) {
      case StaminaColorType.LOW:
        return WidgetColors.STAMINA_LOW;
      case StaminaColorType.MEDIUM:
        return WidgetColors.STAMINA_MEDIUM;
      case StaminaColorType.HIGH:
      default:
        return this.role.gameColor;
    }
  }

  build() {
    Row({ space: 12 }) {
      // ── 左侧：体力环 + 恢复时间 ──
      Column() {
        // 体力环
        Stack() {
          // 背景环
          Progress({ value: 100, total: 100, type: ProgressType.Ring })
            .width(RING_SIZE)
            .height(RING_SIZE)
            .color(WidgetColors.WHITE)
            .opacity(0.15)
            .style({ strokeWidth: RING_STROKE })

          // 前景环
          Progress({
            value: this.role.currentStamina,
            total: this.role.maxStamina,
            type: ProgressType.Ring
          })
            .width(RING_SIZE)
            .height(RING_SIZE)
            .color(this.getStaminaColor())
            .style({ strokeWidth: RING_STROKE })

          // 中心数值（垂直布局，当前值在上，/max 在下）
          Column({ space: 2 }) {
            Text(this.role.currentStamina.toString())
              .fontSize(Math.round(RING_SIZE * 0.32))
              .fontWeight(700)
              .fontColor(this.getStaminaColor())

            Text('/' + this.role.maxStamina.toString())
              .fontSize(Math.round(RING_SIZE * 0.14))
              .fontColor(WidgetColors.WHITE)
              .opacity(0.35)
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width(RING_SIZE)
        .height(RING_SIZE)

        // 恢复时间
        if (!this.role.recoveryTime.isFull) {
          Text(formatRecoveryTimeText(this.role.recoveryTime))
            .fontSize(this.theme.font10)
            .fontColor(WidgetColors.WHITE)
            .opacity(0.4)
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: this.theme.value4 })
        }
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .flexShrink(0)

      // ── 右侧：游戏信息 + 数据行 ──
      Column() {
        // 游戏名 + UID
        Row() {
          Text(this.role.gameName)
            .fontSize(this.theme.font12)
            .fontWeight(500)
            .fontColor(WidgetColors.WHITE)
            .opacity(0.7)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.role.roleIdWithPrefix)
            .fontSize(this.theme.font10)
            .fontColor(WidgetColors.WHITE)
            .opacity(0.35)
            .margin({ left: this.theme.value4 })
        }
        .alignItems(VerticalAlign.Bottom)
        .margin({ bottom: this.theme.value6 })

        // 星铁特殊：后备开拓力
        if (this.role.gameId === WIDGET_GAME_ID.STARRAIL && this.role.reserveStamina !== undefined) {
          Row() {
            Text($r('app.string.widget_reserve_stamina'))
              .fontSize(this.theme.font10)
              .fontColor(WidgetColors.WHITE)
              .opacity(0.4)

            Text(this.role.reserveStamina.toString())
              .fontSize(this.theme.font12)
              .fontWeight(600)
              .fontColor(this.role.gameColor)
              .margin({ left: this.theme.value4 })
          }
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: this.theme.value4 })
        }

        // 额外数据行（最多4条）
        Column({ space: 4 }) {
          ForEach(this.role.extraRows.slice(0, 4), (row: WidgetExtraRow) => {
            Row() {
              Text(row.labelResource)
                .fontSize(this.theme.font10)
                .fontColor(WidgetColors.WHITE)
                .opacity(0.4)
                .layoutWeight(1)

              Text(row.displayValue)
                .fontSize(this.theme.font12)
                .fontWeight(600)
                .fontColor(row.valueColor)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center)
    .margin(this.inNestedContainer ? 0 : { left: this.theme.value12, right: this.theme.value12 })
  }
}

@Preview
@Component
struct Widget2x4SingleGamePreview {
  private role: WidgetRoleUIState = new WidgetRoleUIState();

  aboutToAppear(): void {
    this.role.gameId = WIDGET_GAME_ID.GENSHIN;
    this.role.gameName = '原神';
    this.role.gameColor = WidgetColors.GENSHIN_PRIMARY;
    this.role.roleId = '123456789';
    this.role.roleIdWithPrefix = 'UID 123456789';
    this.role.currentStamina = 140;
    this.role.maxStamina = 160;
    this.role.recoveryTime.isFull = false;
    this.role.recoveryTime.hours = 4;
    this.role.recoveryTime.minutes = 30;
    this.role.staminaColorType = StaminaColorType.HIGH;
  }

  build() {
    Column({ space: 12 }) {
      Widget2x4SingleGame({ role: this.role })
        .width(316)
        .height(146)
        .padding(12)
        .linearGradient({ angle: 135, colors: [[$r('app.color.widget_bg_genshin_1'), 0], [$r('app.color.widget_bg_genshin_3'), 1]] })
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
