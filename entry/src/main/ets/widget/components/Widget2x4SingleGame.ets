/**
 * Widget2x4SingleGame.ets — 2×4 单游戏详细布局
 *
 * 左侧：大体力环（80vp）+ 恢复描述
 * 右侧：账号名 + 游戏名 + 分割线 + 额外数据行
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */


import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetStaminaRing } from './WidgetStaminaRing';
import { WidgetGenshinExtraRows } from './WidgetGenshinExtraRows';
import { WidgetStarRailExtraRows } from './WidgetStarRailExtraRows';
import { WidgetZZZExtraRows } from './WidgetZZZExtraRows';
import { gameColorRes, gameNameRes, calcIsFull, formatRecoveryDesc, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetSingleGameData } from '../models/WidgetModels';

@Component
export struct Widget2x4SingleGame {
  private tm: ThemeManager = themeManager;

  @Prop data: WidgetSingleGameData = new WidgetSingleGameData();

  private get displayName(): string {
    return this.data.accountName.length > 0 ? this.data.accountName : this.data.accountUid;
  }

  private get isFull(): boolean {
    return calcIsFull(this.data.game.currentStr, this.data.game.maxStr, this.data.game.secondsStr);
  }

  build() {
    Row({ space: themeManager.current.value12 }) {
      Column({ space: themeManager.current.value4 }) {
        WidgetStaminaRing({
          game: this.data.game,
          gameColor: gameColorRes(this.data.game.gameId, false),
          ringSize: themeManager.current.value80,
          strokeWidth: themeManager.current.value8,
          valueFontSize: themeManager.current.value20,
          maxFontSize: themeManager.current.value11
        })

        Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.data.game.secondsStr))
          .fontSize(themeManager.current.value11)
          .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: themeManager.current.value90 })
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .flexShrink(0)

      Column({ space: 0 }) {
        Text(this.displayName)
          .fontSize(themeManager.current.value11)
          .fontColor($r('app.color.text_on_dark_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(gameNameRes(this.data.game.gameId))
          .fontSize(themeManager.current.value14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_on_dark_high'))
          .margin({ top: this.tm.current.value2, bottom: this.tm.current.value8 })

        Divider()
          .color($r('app.color.surface_inactive_border'))
          .margin({ bottom: this.tm.current.value8 })

        if (this.data.game.gameId === WIDGET_GAME_ID.GENSHIN) {
          WidgetGenshinExtraRows({ game: this.data.game, fontSize: themeManager.current.value13 })
        } else if (this.data.game.gameId === WIDGET_GAME_ID.STARRAIL) {
          WidgetStarRailExtraRows({ game: this.data.game, fontSize: themeManager.current.value13 })
        } else if (this.data.game.gameId === WIDGET_GAME_ID.ZZZ) {
          WidgetZZZExtraRows({ game: this.data.game, fontSize: themeManager.current.value13 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
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
    .backgroundColor('#2E3033')
    .borderRadius(16)
  }
}
