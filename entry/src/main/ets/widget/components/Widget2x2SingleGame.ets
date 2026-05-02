/**
 * Widget2x2SingleGame.ets — 2×2 单游戏详细布局
 *
 * 账号名 → 体力环+恢复描述 → 分割线 → 额外数据行
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */


import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetStaminaRing } from './WidgetStaminaRing';
import { WidgetGenshinExtraRows } from './WidgetGenshinExtraRows';
import { WidgetStarRailExtraRows } from './WidgetStarRailExtraRows';
import { WidgetZZZExtraRows } from './WidgetZZZExtraRows';
import { gameColorRes, calcIsFull, formatRecoveryDesc, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetSingleGameData } from '../models/WidgetModels';

@Component
export struct Widget2x2SingleGame {
  private tm: ThemeManager = themeManager;

  @Prop data: WidgetSingleGameData = new WidgetSingleGameData();

  private get displayName(): string {
    return this.data.accountName.length > 0 ? this.data.accountName : this.data.accountUid;
  }

  private get isFull(): boolean {
    return calcIsFull(this.data.game.currentStr, this.data.game.maxStr, this.data.game.secondsStr);
  }

  build() {
    Column({ space: 0 }) {
      Text(this.displayName)
        .fontSize(themeManager.current.value11)
        .fontColor($r('app.color.text_on_dark_tertiary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: this.tm.current.value8 })

      Row({ space: themeManager.current.value10 }) {
        WidgetStaminaRing({
          game: this.data.game,
          gameColor: gameColorRes(this.data.game.gameId, false),
          ringSize: themeManager.current.value56,
          strokeWidth: themeManager.current.value5,
          valueFontSize: themeManager.current.value18,
          maxFontSize: themeManager.current.value11
        })

        Column({ space: themeManager.current.value2 }) {
          Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.data.game.secondsStr))
            .fontSize(themeManager.current.value13)
            .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_secondary'))
            .maxLines(1)

          if (this.data.game.gameId === WIDGET_GAME_ID.STARRAIL && parseInt(this.data.game.reserveStr) >= 0) {
            Row({ space: themeManager.current.value2 }) {
              Text($r('app.string.widget_reserve_prefix'))
                .fontSize(themeManager.current.value11)
                .fontColor($r('app.color.game_color_starrail'))

              Text(this.data.game.reserveStr)
                .fontSize(themeManager.current.value11)
                .fontColor($r('app.color.game_color_starrail'))
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }

      Divider()
        .color($r('app.color.surface_inactive_border'))
        .margin({ top: this.tm.current.value8, bottom: this.tm.current.value8 })

      if (this.data.game.gameId === WIDGET_GAME_ID.GENSHIN) {
        WidgetGenshinExtraRows({ game: this.data.game, fontSize: themeManager.current.value13 })
      } else if (this.data.game.gameId === WIDGET_GAME_ID.STARRAIL) {
        WidgetStarRailExtraRows({ game: this.data.game, fontSize: themeManager.current.value13 })
      } else if (this.data.game.gameId === WIDGET_GAME_ID.ZZZ) {
        WidgetZZZExtraRows({ game: this.data.game, fontSize: themeManager.current.value13 })
      }
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview
@Component
struct Widget2x2SingleGamePreview {
  build() {
    Column() {
      Widget2x2SingleGame({ data: new WidgetSingleGameData() })
    }
    .padding(12)
    .width(168)
    .height(168)
    .backgroundColor('#2E3033')
    .borderRadius(16)
  }
}
