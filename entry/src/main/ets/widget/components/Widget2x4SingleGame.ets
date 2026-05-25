/**
 * Widget2x4SingleGame.ets — 2×4 单游戏详细布局
 *
 * 严格按原型 wr-2x4.js 单游戏分支实现：
 * - 左侧：体力环（88vp，stroke 8）+ 恢复时间（环下方居中）
 * - 右侧：游戏色圆点+游戏名+账号名 → 星铁后备 → 数据行（gap:5px）
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { DefaultTheme } from '../../theme/DefaultTheme';

/** 主题常量实例 */
const theme = new DefaultTheme();
import { WidgetStaminaRing } from './WidgetStaminaRing';
import { WidgetGenshinExtraRows } from './WidgetGenshinExtraRows';
import { WidgetStarRailExtraRows } from './WidgetStarRailExtraRows';
import { WidgetZZZExtraRows } from './WidgetZZZExtraRows';
import { gameColorRes, gameNameRes, calcIsFull, formatRecoveryDesc, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetSingleGameData } from '../models/WidgetModels';

@Component
export struct Widget2x4SingleGame {

  @Prop data: WidgetSingleGameData = new WidgetSingleGameData();

  private get displayName(): string {
    return this.data.accountName.length > 0 ? this.data.accountName : this.data.accountUid;
  }

  private get isFull(): boolean {
    return calcIsFull(this.data.game.currentStr, this.data.game.maxStr, this.data.game.secondsStr);
  }

  private get gameColor(): ResourceColor {
    return gameColorRes(this.data.game.gameId, false);
  }

  build() {
    Row({ space: theme.value14 }) {
      // ── 左侧：体力环 + 恢复时间 ──
      Column({ space: theme.value5 }) {
        WidgetStaminaRing({
          game: this.data.game,
          gameColor: this.gameColor,
          ringSize: theme.value80,
          strokeWidth: theme.value8,
          valueFontSize: theme.value22,
          maxFontSize: theme.value11
        })

        Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.data.game.secondsStr))
          .fontSize(theme.value9)
          .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: theme.value90 })
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .flexShrink(0)

      // ── 右侧：游戏标题 + 数据行 ──
      Column() {
        // 游戏色圆点 + 游戏名 + 账号名
        Row({ space: theme.value5 }) {
          Column()
            .width(theme.value5)
            .height(theme.value5)
            .borderRadius(theme.value5)
            .backgroundColor(this.gameColor)
            .flexShrink(0)

          Text(gameNameRes(this.data.game.gameId))
            .fontSize(theme.value13)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_on_dark_high'))

          Text(this.displayName)
            .fontSize(theme.value10)
            .fontColor($r('app.color.text_on_dark_muted'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width(theme.full)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: theme.value8 })

        // 星铁：后备开拓力
        if (this.data.game.gameId === WIDGET_GAME_ID.STARRAIL && parseInt(this.data.game.reserveStr) >= 0) {
          Row({ space: theme.value4 }) {
            Text($r('app.string.widget_reserve_stamina'))
              .fontSize(theme.value10)
              .fontColor($r('app.color.text_on_dark_muted'))

            Text(this.data.game.reserveStr)
              .fontSize(theme.value12)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.game_color_starrail'))
          }
          .margin({ bottom: theme.value5 })
        }

        // 额外数据行
        if (this.data.game.gameId === WIDGET_GAME_ID.GENSHIN) {
          WidgetGenshinExtraRows({ game: this.data.game, fontSize: theme.value11 })
            .layoutWeight(1)
        } else if (this.data.game.gameId === WIDGET_GAME_ID.STARRAIL) {
          WidgetStarRailExtraRows({ game: this.data.game, fontSize: theme.value11 })
            .layoutWeight(1)
        } else if (this.data.game.gameId === WIDGET_GAME_ID.ZZZ) {
          WidgetZZZExtraRows({ game: this.data.game, fontSize: theme.value11 })
            .layoutWeight(1)
        }
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
struct Widget2x4SingleGamePreview {
  build() {
    Column() {
      Widget2x4SingleGame({ data: new WidgetSingleGameData() })
    }
    .padding(12)
    .width(352)
    .height(168)
    .linearGradient({ angle: 135, colors: [['#152030', 0], ['#1c3350', 1]] })
    .borderRadius(16)
  }
}
