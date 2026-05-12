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
 */

import { widgetTheme } from '../utils/WidgetTheme';
import { gameColorRes, gameNameRes, calcIsFull, calcRatio, formatRecoveryDesc, parseCurrent, parseMax, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetSingleGameData } from '../models/WidgetModels';

/** 额外数据行 */
class ExtraRow {
  label: string = '';
  value: string = '';
  color: ResourceColor = $r('app.color.text_on_dark_medium');
}

@Component
export struct Widget2x2SingleGame {

  @Prop data: WidgetSingleGameData = new WidgetSingleGameData();

  private get isFull(): boolean {
    return calcIsFull(this.data.game.currentStr, this.data.game.maxStr, this.data.game.secondsStr);
  }

  private get ratio(): number {
    return calcRatio(this.data.game.currentStr, this.data.game.maxStr);
  }

  private get gameColor(): ResourceColor {
    return gameColorRes(this.data.game.gameId, false);
  }

  /** 当前体力颜色：0-30% 红色，30-70% 橙色，70-100% 游戏主题色 */
  private get staminaColor(): ResourceColor {
    if (this.ratio <= 0.3) {
      return $r('app.color.color_danger');
    }
    if (this.ratio <= 0.7) {
      return $r('app.color.color_warning');
    }
    return this.gameColor;
  }

  /** 额外数据行（最多 2 行） */
  private get extraRows(): ExtraRow[] {
    const rows: ExtraRow[] = [];
    const g = this.data.game;

    if (g.gameId === WIDGET_GAME_ID.GENSHIN) {
      // 原神：探索派遣、洞天宝钱
      const expeditionMax = parseInt(g.expeditionMaxStr);
      if (expeditionMax > 0) {
        const finished = parseInt(g.expeditionFinishedStr);
        rows.push({
          label: '探索派遣',
          value: `${finished}/${expeditionMax}`,
          color: $r('app.color.game_color_starrail')
        });
      }
      const coinMax = parseInt(g.coinMaxStr);
      if (coinMax > 0) {
        const coin = parseInt(g.coinStr);
        rows.push({
          label: '洞天宝钱',
          value: `${coin}/${coinMax}`,
          color: $r('app.color.color_warning')
        });
      }
    } else if (g.gameId === WIDGET_GAME_ID.STARRAIL) {
      // 星铁：每日实训、历战余响（跳过后备开拓力）
      const trainMax = parseInt(g.trainMaxStr);
      if (trainMax > 0) {
        const train = parseInt(g.trainStr);
        rows.push({
          label: '每日实训',
          value: `${train}/${trainMax}`,
          color: $r('app.color.color_warning')
        });
      }
      const cocoonLimit = parseInt(g.cocoonLimitStr);
      if (cocoonLimit > 0) {
        const cocoon = parseInt(g.cocoonStr);
        rows.push({
          label: '历战余响',
          value: `${cocoon}/${cocoonLimit}`,
          color: $r('app.color.accent_refine')
        });
      }
    } else if (g.gameId === WIDGET_GAME_ID.ZZZ) {
      // 绝区零：今日活跃度、刮刮卡
      const vitalityMax = parseInt(g.vitalityMaxStr);
      if (vitalityMax > 0) {
        const vitality = parseInt(g.vitalityStr);
        rows.push({
          label: '今日活跃度',
          value: `${vitality}/${vitalityMax}`,
          color: $r('app.color.game_color_zzz')
        });
      }
      if (g.cardSign && g.cardSign.length > 0) {
        rows.push({
          label: '刮刮卡',
          value: g.cardSign === 'CardSignDone' ? '已完成' : '未完成',
          color: g.cardSign === 'CardSignDone' ? $r('app.color.color_success') : $r('app.color.text_on_dark_muted')
        });
      }
    }

    return rows.slice(0, 2);
  }

  /** 后备开拓力（星铁专用） */
  private get reserveStamina(): string {
    const val = parseInt(this.data.game.reserveStr);
    return isNaN(val) ? '0' : String(val);
  }

  aboutToAppear(): void {
    console.info('[Widget2x2SingleGame] aboutToAppear: gameId=' + this.data.game.gameId + ' accountUid=' + this.data.accountUid + ' currentStr=' + this.data.game.currentStr + ' maxStr=' + this.data.game.maxStr + ' expeditionMax=' + this.data.game.expeditionMaxStr + ' coinMax=' + this.data.game.coinMaxStr);
  }

  build() {
    Column() {
      // ── 头部：游戏名 + UID ──
      Column({ space: widgetTheme.value1 }) {
        Text(gameNameRes(this.data.game.gameId))
          .fontSize(widgetTheme.value12)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_on_dark_high'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('UID ' + this.data.accountUid)
          .fontSize(widgetTheme.value10)
          .fontColor($r('app.color.text_on_dark_muted'))
      }
      .width(widgetTheme.full)
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: widgetTheme.value8 })

      // ── 体力区块 ──
      if (this.data.game.gameId === WIDGET_GAME_ID.STARRAIL) {
        // 星铁特殊布局：左侧体力 + 右侧后备开拓力
        Row() {
          // 左侧：当前/最大 + 恢复时间
          Column({ space: widgetTheme.value2 }) {
            Row({ space: widgetTheme.value3 }) {
              Text(String(parseCurrent(this.data.game.currentStr)))
                .fontSize(widgetTheme.value24)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.staminaColor)

              Text('/' + String(parseMax(this.data.game.maxStr)))
                .fontSize(widgetTheme.value14)
                .fontColor($r('app.color.text_on_dark_muted'))
            }
            .alignItems(VerticalAlign.Bottom)

            Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.data.game.secondsStr))
              .fontSize(widgetTheme.value11)
              .fontColor($r('app.color.text_on_dark_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 右侧：后备开拓力
          Column({ space: widgetTheme.value1 }) {
            Text($r('app.string.widget_reserve_prefix'))
              .fontSize(widgetTheme.value9)
              .fontColor($r('app.color.text_on_dark_muted'))

            Text(this.reserveStamina)
              .fontSize(widgetTheme.value12)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.gameColor)
          }
          .alignItems(HorizontalAlign.End)
        }
        .width(widgetTheme.full)
        .alignItems(VerticalAlign.Top)
        .margin({ bottom: widgetTheme.value8 })
      } else {
        // 原神/绝区零：标准布局
        Column({ space: widgetTheme.value2 }) {
          Row({ space: widgetTheme.value3 }) {
            Text(String(parseCurrent(this.data.game.currentStr)))
              .fontSize(widgetTheme.value24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.staminaColor)

            Text('/' + String(parseMax(this.data.game.maxStr)))
              .fontSize(widgetTheme.value14)
              .fontColor($r('app.color.text_on_dark_muted'))
          }
          .alignItems(VerticalAlign.Bottom)

          Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.data.game.secondsStr))
            .fontSize(widgetTheme.value11)
            .fontColor($r('app.color.text_on_dark_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width(widgetTheme.full)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: widgetTheme.value8 })
      }

      // ── 底部：额外数据行 ──
      Column({ space: widgetTheme.value5 }) {
        ForEach(this.extraRows, (row: ExtraRow, idx: number) => {
          Row() {
            Text(row.label)
              .fontSize(widgetTheme.value11)
              .fontColor($r('app.color.text_on_dark_tertiary'))
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(row.value)
              .fontSize(widgetTheme.value11)
              .fontWeight(FontWeight.Bold)
              .fontColor(row.color)
          }
          .width(widgetTheme.full)
        })
      }
      .width(widgetTheme.full)
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width(widgetTheme.full)
    .height(widgetTheme.full)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }
}

@Preview
@Component
struct Widget2x2SingleGamePreview {
  build() {
    Column({ space: 12 }) {
      Widget2x2SingleGame({ data: new WidgetSingleGameData() })
        .width(168)
        .height(168)
        .padding(12)
        .linearGradient({ angle: 135, colors: [['#152030', 0], ['#1c3350', 1]] })
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
