/**
 * Widget1x2ContentView.ets — 1×2 迷你卡片内容组件
 *
 * 严格按原型 wr-1x2.js 实现：
 * - 左侧：游戏色竖线（3vp 宽，充满内容高度，圆角，上下 8px padding）
 * - 第一行：游戏名（10px）+ UID（9px）同一行
 * - 第二行：当前体力（18px Bold）+ "/" + 最大体力（18px）
 * - 第三行：恢复时间（10px）
 * - 体力颜色：0-30% 红色，30-70% 橙色，70-100% 游戏主题色
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { Widget1x2RoleUIState, WidgetColors } from '../models/WidgetUIStates';
import { getStaminaColorByType, formatRecoveryTimeText } from '../utils/WidgetUtils';
import { DefaultTheme } from '../../theme/DefaultTheme';

/** 默认主题实例 */
const theme = new DefaultTheme();

@Component
export struct Widget1x2ContentView {
  @Prop state: Widget1x2RoleUIState = new Widget1x2RoleUIState();

  /** 游戏主题色（由父组件传入） */
  gameColor: Resource = WidgetColors.GENSHIN_PRIMARY;

  build() {
    Row({ space: theme.value8 }) {
      // 左侧：游戏色竖线装饰条（3vp 宽，上下 8px padding）
      Stack() {
        Column()
          .width(theme.value3)
          .borderRadius(theme.value2)
          .backgroundColor(this.gameColor)
          .height(theme.full)
      }
      .width(theme.value3)
      .height(theme.full)
      .padding({ top: theme.value8, bottom: theme.value8 })
      .alignContent(Alignment.Center)
      .flexShrink(0)

      // 右侧：游戏名+UID + 体力 + 恢复时间
      Column() {
        // 第一行：游戏名 + UID
        Row({ space: theme.value4 }) {
          Text(this.state.gameName)
            .fontSize(theme.font10)
            .fontWeight(FontWeight.Medium)
            .fontColor(WidgetColors.WHITE)
            .opacity(WidgetColors.OPACITY_TEXT_MUTED)

          Text('UID ' + this.state.accountUid)
            .fontSize(theme.font9)
            .fontColor(WidgetColors.WHITE)
            .opacity(WidgetColors.OPACITY_TEXT_GHOST)
        }

        // 第二行：当前体力 / 最大体力
        Row({ space: theme.value2 }) {
          Text(String(this.state.currentStamina))
            .fontSize(theme.fontBold18)
            .fontWeight(FontWeight.Bold)
            .fontColor(getStaminaColorByType(this.state.staminaColorType, this.state.gameId))

          Text('/' + String(this.state.maxStamina))
            .fontSize(theme.fontBold18)
            .fontColor(WidgetColors.WHITE)
            .opacity(WidgetColors.OPACITY_TEXT_FAINT)
        }
        .alignItems(VerticalAlign.Bottom)

        // 第三行：恢复时间
        Text(formatRecoveryTimeText(this.state.recoveryTime))
          .fontSize(theme.font10)
          .fontColor(this.state.recoveryTime.isFull ? WidgetColors.STAMINA_LOW : WidgetColors.WHITE)
          .opacity(this.state.recoveryTime.isFull ? WidgetColors.OPACITY_TEXT_HIGH : WidgetColors.OPACITY_TEXT_FAINT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
    }
    .width(theme.full)
    .height(theme.full)
    .alignItems(VerticalAlign.Center)
  }
}

@Preview
@Component
struct Widget1x2ContentViewPreview {
  private state: Widget1x2RoleUIState = new Widget1x2RoleUIState();

  aboutToAppear(): void {
    this.state.gameId = 'genshin';
    this.state.gameName = '原神';
    this.state.accountUid = '123456789';
    this.state.currentStamina = 140;
    this.state.maxStamina = 160;
    this.state.recoveryTime.isFull = false;
    this.state.recoveryTime.hours = 2;
    this.state.recoveryTime.minutes = 30;
  }

  build() {
    Column({ space: 8 }) {
      Widget1x2ContentView({
        state: this.state,
        gameColor: WidgetColors.GENSHIN_PRIMARY
      })
        .width(168)
        .height(56)
        .padding(12)
        .linearGradient({ angle: 135, colors: [[$r('app.color.widget_gradient_1'), 0], [$r('app.color.widget_gradient_2'), 1]] })
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
