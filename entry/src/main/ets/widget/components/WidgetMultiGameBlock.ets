/**
 * WidgetMultiGameBlock.ets — 多游戏模式单个游戏区块
 *
 * 4×4 多游戏模式下，每款游戏占一个区块：体力环 + 游戏名 + 恢复时间 + 额外数据行。
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */


import { WidgetStaminaRing } from './WidgetStaminaRing';
import { WidgetGenshinExtraRows } from './WidgetGenshinExtraRows';
import { WidgetStarRailExtraRows } from './WidgetStarRailExtraRows';
import { WidgetZZZExtraRows } from './WidgetZZZExtraRows';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { gameColorRes, gameNameRes, calcIsFull, formatRecoveryDesc, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetGameData } from '../models/WidgetModels';

@Component
export struct WidgetMultiGameBlock {
  private tm: ThemeManager = themeManager;

  @Prop game: WidgetGameData = new WidgetGameData();
  /** 总游戏数，影响环的大小 */
  totalGameCount: number = 2;

  private get isFull(): boolean {
    return calcIsFull(this.game.currentStr, this.game.maxStr, this.game.secondsStr);
  }

  private get ringSize(): number {
    return this.totalGameCount <= 2 ? themeManager.current.value56 : themeManager.current.value44;
  }

  private get valueFontSize(): number {
    return this.totalGameCount <= 2 ? themeManager.current.value16 : themeManager.current.value14;
  }

  build() {
    Row({ space: themeManager.current.value14 }) {
      WidgetStaminaRing({
        game: this.game,
        gameColor: gameColorRes(this.game.gameId, false),
        ringSize: this.ringSize,
        strokeWidth: themeManager.current.value4,
        valueFontSize: this.valueFontSize,
        maxFontSize: themeManager.current.value11
      })

      Column({ space: 0 }) {
        Text(gameNameRes(this.game.gameId))
          .fontSize(themeManager.current.value14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_on_dark_high'))

        Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.game.secondsStr))
          .fontSize(themeManager.current.value13)
          .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_secondary'))
          .margin({ top: this.tm.current.value2 })

        Column({ space: 0 }) {
          if (this.game.gameId === WIDGET_GAME_ID.GENSHIN) {
            WidgetGenshinExtraRows({ game: this.game, fontSize: themeManager.current.value11 })
          } else if (this.game.gameId === WIDGET_GAME_ID.STARRAIL) {
            WidgetStarRailExtraRows({ game: this.game, fontSize: themeManager.current.value11 })
          } else if (this.game.gameId === WIDGET_GAME_ID.ZZZ) {
            WidgetZZZExtraRows({ game: this.game, fontSize: themeManager.current.value11 })
          }
        }
        .margin({ top: this.tm.current.value4 })
        .justifyContent(FlexAlign.SpaceEvenly)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width(this.tm.current.full)
    .alignItems(VerticalAlign.Center)
  }
}

@Preview
@Component
struct WidgetMultiGameBlockPreview {
  build() {
    Column({ space: 8 }) {
      WidgetMultiGameBlock({ game: new WidgetGameData(), totalGameCount: 2 })
    }
    .padding(16)
    .width(352)
    .backgroundColor('#1a1a2e')
  }
}
