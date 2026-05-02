/**
 * Widget4x4SingleGame.ets — 4×4 单游戏完整布局
 *
 * 顶部账号名+游戏名标题行 → 分割线 → 大体力环+恢复描述 → 分割线 → 额外数据行 → 原神派遣格子
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */


import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetStaminaRing } from './WidgetStaminaRing';
import { WidgetGenshinExtraRows } from './WidgetGenshinExtraRows';
import { WidgetStarRailExtraRows } from './WidgetStarRailExtraRows';
import { WidgetZZZExtraRows } from './WidgetZZZExtraRows';
import { WidgetExpeditions } from './WidgetExpeditions';
import { gameColorRes, gameNameRes, staminaLabelRes, calcIsFull, formatRecoveryDesc, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetSingleGameData } from '../models/WidgetModels';

@Component
export struct Widget4x4SingleGame {
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
      Row() {
        Column({ space: themeManager.current.value2 }) {
          Text(this.displayName)
            .fontSize(themeManager.current.value13)
            .fontColor($r('app.color.text_on_dark_tertiary'))

          Text(gameNameRes(this.data.game.gameId))
            .fontSize(themeManager.current.value18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_on_dark_high'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text($r('app.string.widget_just_now'))
          .fontSize(themeManager.current.value11)
          .fontColor($r('app.color.text_on_dark_muted'))
      }
      .width(this.tm.current.full)
      .margin({ bottom: this.tm.current.value10 })

      Divider()
        .color($r('app.color.surface_inactive_border'))
        .margin({ bottom: this.tm.current.value10 })

      Row({ space: themeManager.current.value14 }) {
        WidgetStaminaRing({
          game: this.data.game,
          gameColor: gameColorRes(this.data.game.gameId, false),
          ringSize: themeManager.current.value80,
          strokeWidth: themeManager.current.value8,
          valueFontSize: themeManager.current.value24,
          maxFontSize: themeManager.current.value13
        })

        Column({ space: themeManager.current.value4 }) {
          Text(staminaLabelRes(this.data.game.gameId))
            .fontSize(themeManager.current.value13)
            .fontColor($r('app.color.text_on_dark_tertiary'))

          Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.data.game.secondsStr))
            .fontSize(themeManager.current.value13)
            .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_secondary'))

          if (this.data.game.gameId === WIDGET_GAME_ID.STARRAIL && parseInt(this.data.game.reserveStr) >= 0) {
            Row({ space: themeManager.current.value4 }) {
              Text($r('app.string.widget_reserve_stamina'))
                .fontSize(themeManager.current.value13)
                .fontColor($r('app.color.game_color_starrail'))

              Text(this.data.game.reserveStr)
                .fontSize(themeManager.current.value13)
                .fontColor($r('app.color.game_color_starrail'))
            }
            .margin({ top: this.tm.current.value4 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .margin({ bottom: this.tm.current.value10 })

      Divider()
        .color($r('app.color.surface_inactive_border'))
        .margin({ bottom: this.tm.current.value8 })

      if (this.data.game.gameId === WIDGET_GAME_ID.GENSHIN) {
        WidgetGenshinExtraRows({ game: this.data.game, fontSize: themeManager.current.value14 })
      } else if (this.data.game.gameId === WIDGET_GAME_ID.STARRAIL) {
        WidgetStarRailExtraRows({ game: this.data.game, fontSize: themeManager.current.value14 })
      } else if (this.data.game.gameId === WIDGET_GAME_ID.ZZZ) {
        WidgetZZZExtraRows({ game: this.data.game, fontSize: themeManager.current.value14 })
      }

      if (this.data.game.gameId === WIDGET_GAME_ID.GENSHIN) {
        WidgetExpeditions({
          expeditionMax: this.data.game.expeditionMaxStr,
          expeditionFinishedFlags: this.data.game.expeditionFlagsStr
        })
      }
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview
@Component
struct Widget4x4SingleGamePreview {
  build() {
    Column() {
      Widget4x4SingleGame({ data: new WidgetSingleGameData() })
    }
    .padding(12)
    .width(352)
    .height(352)
    .backgroundColor('#2E3033')
    .borderRadius(16)
  }
}
