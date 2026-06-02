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
 * - 所有数据通过 WidgetRoleUIState 传入，组件内部不解析数据
 * - gameName/recoveryDesc 是字符串（不是 Resource），直接显示或转换为资源文字
 * - gameColor 是十六进制字符串，staminaColorType 是枚举，组件自行决定显示颜色
 */

import { WidgetRoleUIState, WidgetExtraRow, StaminaColorType, RecoveryTimeData, WidgetColors } from '../models/WidgetUIStates';
import { WIDGET_GAME_ID, getGameColor } from '../utils/WidgetUtils';
import { DefaultTheme } from '../../theme/DefaultTheme';

/**
 * 根据体力颜色类型和游戏 ID 获取显示颜色
 */
function getStaminaColor(colorType: StaminaColorType, gameId: string): Resource {
  if (colorType === StaminaColorType.LOW) {
    return WidgetColors.STAMINA_LOW;
  }
  if (colorType === StaminaColorType.MEDIUM) {
    return WidgetColors.STAMINA_MEDIUM;
  }
  // HIGH 状态使用游戏主色
  return getGameColor(gameId);
}

/**
 * 格式化恢复时间文字（使用 $r() 获取翻译）
 */
function formatRecoveryTimeText(recoveryTime: RecoveryTimeData): ResourceStr {
  if (recoveryTime.isFull) {
    return $r('app.string.widget_stamina_full');
  }

  const hours = recoveryTime.hours;
  const minutes = recoveryTime.minutes;

  if (hours > 0 && minutes > 0) {
    return $r('app.string.widget_recovery_hours_minutes', hours, minutes);
  }
  if (hours > 0) {
    return $r('app.string.widget_recovery_hours', hours);
  }
  return $r('app.string.widget_recovery_minutes', minutes);
}

@Component
export struct Widget2x2SingleGame {
  /** 角色 UIState（已解析好的数据） */
  @Prop role: WidgetRoleUIState = new WidgetRoleUIState();

  /** 主题常量 */
  theme: DefaultTheme = new DefaultTheme();

  aboutToAppear(): void {
    // Widget 组件初始化
  }

  /**
   * 获取游戏名称资源
   * gameName 字段存储的是 gameId key，需要转换为资源文字
   */
  private getGameNameText(): Resource | string {
    // 使用 WIDGET_GAME_ID 常量判断
    if (this.role.gameName === WIDGET_GAME_ID.GENSHIN) {
      return $r('app.string.widget_game_genshin');
    }
    if (this.role.gameName === WIDGET_GAME_ID.STARRAIL) {
      return $r('app.string.widget_game_starrail');
    }
    if (this.role.gameName === WIDGET_GAME_ID.ZZZ) {
      return $r('app.string.widget_game_zzz');
    }
    // 否则直接返回原字符串
    return this.role.gameName;
  }

  /**
   * 获取额外数据行标签文字
   * label 字段存储的是 key，需要转换为资源文字
   */
  private getExtraRowLabel(label: string): Resource | string {
    if (label === 'expedition') {
      return $r('app.string.widget_expedition');
    }
    if (label === 'home_coin') {
      return $r('app.string.widget_home_coin');
    }
    if (label === 'train_score') {
      return $r('app.string.widget_train_score');
    }
    if (label === 'cocoon') {
      return $r('app.string.widget_cocoon');
    }
    if (label === 'vitality') {
      return $r('app.string.widget_vitality');
    }
    if (label === 'card_sign') {
      return $r('app.string.widget_card_sign');
    }
    // 未知 key 直接返回
    return label;
  }

  /**
   * 获取额外数据行数值文字
   * value 字段可能是 key（如 'done'）或格式化字符串（如 '3/5'）
   */
  private getExtraRowValue(value: string): string {
    if (value === 'done') {
      return '已完成';
    }
    if (value === 'not_done') {
      return '未完成';
    }
    return value;
  }

  build() {
    Column() {
      // ── 头部：游戏名 + UID ──
      Column({ space: this.theme.value1 }) {
        Text(this.getGameNameText())
          .fontSize(this.theme.font13)
          .fontWeight(FontWeight.Bold)
          .fontColor(WidgetColors.WHITE)
          .opacity(0.95)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('UID ' + this.role.roleId)
          .fontSize(this.theme.font10)
          .fontColor(WidgetColors.WHITE)
          .opacity(0.5)
      }
      .width(this.theme.full)
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: this.theme.value8 })

      // ── 体力区块 ──
      if (this.role.gameId === WIDGET_GAME_ID.STARRAIL) {
        // 星铁特殊布局：左侧体力 + 右侧后备开拓力
        Row() {
          // 左侧：当前/最大 + 恢复时间
          Column({ space: this.theme.value2 }) {
            Row({ space: this.theme.value3 }) {
              Text(String(this.role.currentStamina))
                .fontSize(this.theme.font24)
                .fontWeight(FontWeight.Bold)
                .fontColor(getStaminaColor(this.role.staminaColorType, this.role.gameId))

              Text('/' + String(this.role.maxStamina))
                .fontSize(this.theme.font14)
                .fontColor(WidgetColors.WHITE)
                .opacity(0.5)
            }
            .alignItems(VerticalAlign.Bottom)

            Text(formatRecoveryTimeText(this.role.recoveryTime))
              .fontSize(this.theme.font11)
              .fontColor(WidgetColors.WHITE)
              .opacity(0.7)
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
              .opacity(0.5)

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
      } else {
        // 原神/绝区零：标准布局
        Column({ space: this.theme.value2 }) {
          Row({ space: this.theme.value3 }) {
            Text(String(this.role.currentStamina))
              .fontSize(this.theme.font24)
              .fontWeight(FontWeight.Bold)
              .fontColor(getStaminaColor(this.role.staminaColorType, this.role.gameId))

            Text('/' + String(this.role.maxStamina))
              .fontSize(this.theme.font14)
              .fontColor(WidgetColors.WHITE)
              .opacity(0.5)
          }
          .alignItems(VerticalAlign.Bottom)

          Text(formatRecoveryTimeText(this.role.recoveryTime))
            .fontSize(this.theme.font11)
            .fontColor(WidgetColors.WHITE)
            .opacity(0.7)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width(this.theme.full)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: this.theme.value8 })
      }

      // ── 底部：额外数据行 ──
      Column({ space: this.theme.value5 }) {
        ForEach(this.role.extraRows, (row: WidgetExtraRow, idx: number) => {
          Row() {
            Text(this.getExtraRowLabel(row.label))
              .fontSize(this.theme.font11)
              .fontColor(WidgetColors.WHITE)
              .opacity(0.55)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.getExtraRowValue(row.value))
              .fontSize(this.theme.font11)
              .fontWeight(FontWeight.Bold)
              .fontColor(row.valueColor)
          }
          .width(this.theme.full)
        })
      }
      .width(this.theme.full)
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width(this.theme.full)
    .height(this.theme.full)
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
    this.role.gameName = WIDGET_GAME_ID.GENSHIN;
    this.role.gameColor = WidgetColors.GENSHIN_PRIMARY;
    this.role.roleId = '123456789';
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
