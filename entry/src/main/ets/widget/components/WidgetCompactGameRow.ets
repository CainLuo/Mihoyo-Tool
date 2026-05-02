/**
 * WidgetCompactGameRow.ets — 多游戏精简行组件
 *
 * 2×2 多游戏模式和 2×4 多游戏模式共用的单行布局：
 * 小进度环 + 数值 + 游戏名 + 右侧额外数据（宝钱/后备体力/活跃度）
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */


import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { calcIsFull, calcRatio, gameColorRes, gameNameRes, parseCurrent, parseMax, formatRecoveryDesc, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetGameData } from '../models/WidgetModels';

@Component
export struct WidgetCompactGameRow {
  private tm: ThemeManager = themeManager;

  @Prop game: WidgetGameData = new WidgetGameData();
  /** 进度环直径（vp），2x2 用 28，2x4 用 24 */
  ringSize: number = 28;
  /** 进度环线宽 */
  strokeWidth: number = 2;

  private get isFull(): boolean {
    return calcIsFull(this.game.currentStr, this.game.maxStr, this.game.secondsStr);
  }

  private get ratio(): number {
    return calcRatio(this.game.currentStr, this.game.maxStr);
  }

  private get displayColor(): ResourceColor {
    return gameColorRes(this.game.gameId, this.isFull);
  }

  build() {
    Row({ space: themeManager.current.value8 }) {
      Stack() {
        Progress({ value: this.ratio * 100, total: 100, type: ProgressType.Ring })
          .width(this.ringSize)
          .height(this.ringSize)
          .color(this.displayColor)
          .backgroundColor($r('app.color.surface_inactive_border'))
          .style({ strokeWidth: this.strokeWidth })

        Text(String(parseCurrent(this.game.currentStr)))
          .fontSize(themeManager.current.value11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.displayColor)
      }
      .width(this.ringSize)
      .height(this.ringSize)

      Column({ space: themeManager.current.value1 }) {
        Text(gameNameRes(this.game.gameId))
          .fontSize(themeManager.current.value11)
          .fontColor($r('app.color.text_on_dark_tertiary'))

        Row({ space: themeManager.current.value2 }) {
          Text(String(parseCurrent(this.game.currentStr)))
            .fontSize(themeManager.current.value14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.displayColor)

          Text('/' + String(parseMax(this.game.maxStr)))
            .fontSize(themeManager.current.value11)
            .fontColor($r('app.color.text_on_dark_muted'))
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.game.gameId === WIDGET_GAME_ID.GENSHIN && parseInt(this.game.coinStr) >= 0) {
        Row({ space: themeManager.current.value2 }) {
          Text($r('app.string.widget_home_coin'))
            .fontSize(themeManager.current.value11)
            .fontColor($r('app.color.accent_refine'))

          Text(this.game.coinStr)
            .fontSize(themeManager.current.value11)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.accent_refine'))
        }
        .flexShrink(0)
      } else if (this.game.gameId === WIDGET_GAME_ID.STARRAIL && parseInt(this.game.reserveStr) >= 0) {
        Row({ space: themeManager.current.value2 }) {
          Text($r('app.string.widget_reserve_prefix'))
            .fontSize(themeManager.current.value11)
            .fontColor($r('app.color.game_color_starrail'))

          Text(this.game.reserveStr)
            .fontSize(themeManager.current.value11)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.game_color_starrail'))
        }
        .flexShrink(0)
      } else if (this.game.gameId === WIDGET_GAME_ID.ZZZ && parseInt(this.game.vitalityStr) >= 0) {
        Text(this.game.vitalityStr + '/' + this.game.vitalityMaxStr)
          .fontSize(themeManager.current.value11)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.game_color_zzz'))
          .flexShrink(0)
      } else {
        Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.game.secondsStr))
          .fontSize(themeManager.current.value11)
          .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: themeManager.current.value64 })
          .flexShrink(0)
      }
    }
    .width(this.tm.current.full)
    .alignItems(VerticalAlign.Center)
  }
}

@Preview
@Component
struct WidgetCompactGameRowPreview {
  build() {
    Column({ space: 8 }) {
      WidgetCompactGameRow({ game: new WidgetGameData(), ringSize: 28, strokeWidth: 2 })
    }
    .padding(16)
    .width(200)
    .backgroundColor('#1a1a2e')
  }
}
