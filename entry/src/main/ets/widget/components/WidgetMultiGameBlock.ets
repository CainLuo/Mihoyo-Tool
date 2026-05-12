/**
 * WidgetMultiGameBlock.ets — 4×4 多游戏模式单个游戏区块
 *
 * 严格按原型 wr-4x4.js 多游戏分支实现（纯文本，无圆圈）：
 * - 游戏名（14px Bold）+ 体力数字（22px）+ /上限 + 恢复时间
 * - 数据行（11px，space-evenly）
 * - flex:1 均分父容器高度
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { widgetTheme } from '../utils/WidgetTheme';
import { WidgetGenshinExtraRows } from './WidgetGenshinExtraRows';
import { WidgetStarRailExtraRows } from './WidgetStarRailExtraRows';
import { WidgetZZZExtraRows } from './WidgetZZZExtraRows';
import { gameColorRes, gameNameRes, calcIsFull, formatRecoveryDesc, parseCurrent, parseMax, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetGameData } from '../models/WidgetModels';

@Component
export struct WidgetMultiGameBlock {

  @Prop game: WidgetGameData = new WidgetGameData();
  /** 总游戏数，影响额外数据行数 */
  totalGameCount: number = 2;

  private get isFull(): boolean {
    return calcIsFull(this.game.currentStr, this.game.maxStr, this.game.secondsStr);
  }

  private get gameColor(): ResourceColor {
    return gameColorRes(this.game.gameId, false);
  }

  private get maxExtraRows(): number {
    return this.totalGameCount <= 2 ? 3 : 2;
  }

  build() {
    Column() {
      // 游戏名 + 体力数字 + 恢复时间（一行）
      Row({ space: widgetTheme.value8 }) {
        Text(gameNameRes(this.game.gameId))
          .fontSize(widgetTheme.value12)
          .fontColor($r('app.color.text_on_dark_secondary'))
          .flexShrink(0)

        Row({ space: widgetTheme.value2 }) {
          Text(String(parseCurrent(this.game.currentStr)))
            .fontSize(widgetTheme.value22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isFull ? $r('app.color.color_danger') : this.gameColor)
            .lineHeight(widgetTheme.value24)

          Text('/ ' + String(parseMax(this.game.maxStr)))
            .fontSize(widgetTheme.value11)
            .fontColor($r('app.color.text_on_dark_muted'))
            .alignSelf(ItemAlign.End)
            .margin({ bottom: widgetTheme.value2 })
        }
        .alignItems(VerticalAlign.Bottom)

        Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.game.secondsStr))
          .fontSize(widgetTheme.value11)
          .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width(widgetTheme.full)
      .alignItems(VerticalAlign.Center)
      .flexShrink(0)
      .margin({ bottom: widgetTheme.value4 })

      // 额外数据行（flex:1 space-evenly）
      Column() {
        if (this.game.gameId === WIDGET_GAME_ID.GENSHIN) {
          WidgetGenshinExtraRows({ game: this.game, fontSize: widgetTheme.value11 })
            .height(widgetTheme.full)
        } else if (this.game.gameId === WIDGET_GAME_ID.STARRAIL) {
          WidgetStarRailExtraRows({ game: this.game, fontSize: widgetTheme.value11 })
            .height(widgetTheme.full)
        } else if (this.game.gameId === WIDGET_GAME_ID.ZZZ) {
          WidgetZZZExtraRows({ game: this.game, fontSize: widgetTheme.value11 })
            .height(widgetTheme.full)
        }
      }
      .width(widgetTheme.full)
      .layoutWeight(1)
    }
    .width(widgetTheme.full)
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .padding({ top: widgetTheme.value8, bottom: widgetTheme.value8 })
  }
}

@Preview
@Component
struct WidgetMultiGameBlockPreview {
  build() {
    Column({ space: 8 }) {
      WidgetMultiGameBlock({ game: new WidgetGameData(), totalGameCount: 3 })
    }
    .padding(16)
    .width(352)
    .backgroundColor('#181820')
  }
}
