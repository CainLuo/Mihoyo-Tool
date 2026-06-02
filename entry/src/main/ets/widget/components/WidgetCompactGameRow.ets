/**
 * WidgetCompactGameRow.ets — 多游戏精简行
 *
 * 严格按原型 wr-2x2.js 实现：
 * - 2×2：竖线（3vp 宽）+ 中间列（游戏名 + 体力数字 + 恢复时间）
 * - 2×4（2 游戏）：小环（36vp）+ 中间列（游戏名 + 体力数字 + 恢复时间） + 右侧列（额外数据）
 * - 2×4（3 游戏）：更小环（24vp）+ 中间列（游戏名 + 体力数字 + 恢复时间）
 *
 * 体力颜色规则（原型）：
 * - 0-30%：红色 #ef5350
 * - 30-70%：橙色 #ffca28
 * - 70-100%：游戏主题色
 * - 满：红色 #ef5350
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { calcIsFull, calcRatio, gameNameRes, parseCurrent, parseMax, formatRecoveryDesc, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetGameData } from '../models/WidgetModels';
import { DefaultTheme } from '../../theme/DefaultTheme';
import { WidgetColors } from '../models/WidgetUIStates';

/** 主题常量实例 */
const theme = new DefaultTheme();

class ExtraDataItem {
  label: ResourceStr = '';
  value: string = '';
  color: ResourceColor = Color.White;
}

/**
 * 根据体力比例计算颜色类型
 * 原型规则：0-30% 红色，30-70% 橙色，70-100% 游戏主题色
 */
function getStaminaColorType(ratio: number, isFull: boolean): 'low' | 'medium' | 'high' {
  if (isFull || ratio <= 0.3) {
    return 'low';
  }
  if (ratio <= 0.7) {
    return 'medium';
  }
  return 'high';
}

/**
 * 获取体力颜色 Resource
 */
function getStaminaColorResource(gameId: string, ratio: number, isFull: boolean): Resource {
  const type = getStaminaColorType(ratio, isFull);
  if (type === 'low') {
    return WidgetColors.STAMINA_LOW;
  }
  if (type === 'medium') {
    return WidgetColors.STAMINA_MEDIUM;
  }
  // HIGH: 使用游戏主题色
  return getGameThemeColorResource(gameId);
}

/**
 * 获取游戏主题色 Resource（用于竖线/进度环）
 */
function getGameThemeColorResource(gameId: string): Resource {
  if (gameId === WIDGET_GAME_ID.GENSHIN) {
    return WidgetColors.GENSHIN_PRIMARY;
  }
  if (gameId === WIDGET_GAME_ID.STARRAIL) {
    return WidgetColors.STARRAIL_PRIMARY;
  }
  return WidgetColors.ZZZ_PRIMARY;
}

@Component
export struct WidgetCompactGameRow {

  @Prop game: WidgetGameData = new WidgetGameData();
  /** 0 = 竖线模式（2×2），>0 = 小环模式（2×4） */
  ringSize: number = 0;
  strokeWidth: number = 3;
  /** 总游戏数，影响 2×4 右侧内容 */
  totalGameCount: number = 2;

  private get isFull(): boolean {
    return calcIsFull(this.game.currentStr, this.game.maxStr, this.game.secondsStr);
  }

  private get ratio(): number {
    return calcRatio(this.game.currentStr, this.game.maxStr);
  }

  /** 当前体力颜色（按比例） */
  private get staminaColor(): Resource {
    return getStaminaColorResource(this.game.gameId, this.ratio, this.isFull);
  }

  /** 游戏主题色（用于竖线/进度环） */
  private get gameThemeColor(): Resource {
    return getGameThemeColorResource(this.game.gameId);
  }

  /** 获取第一条额外数据（2×4 两游戏时右侧显示） */
  private getFirstExtra(): ExtraDataItem | null {
    if (this.game.gameId === WIDGET_GAME_ID.GENSHIN) {
      if (parseInt(this.game.coinStr) >= 0) {
        const item = new ExtraDataItem();
        item.label = $r('app.string.widget_home_coin');
        item.value = this.game.coinStr + '/' + this.game.coinMaxStr;
        item.color = WidgetColors.STAMINA_MEDIUM;
        return item;
      }
    } else if (this.game.gameId === WIDGET_GAME_ID.STARRAIL) {
      if (parseInt(this.game.trainStr) >= 0) {
        const item = new ExtraDataItem();
        item.label = $r('app.string.widget_train_score');
        item.value = this.game.trainStr + '/' + this.game.trainMaxStr;
        item.color = WidgetColors.STAMINA_MEDIUM;
        return item;
      }
    } else if (this.game.gameId === WIDGET_GAME_ID.ZZZ) {
      if (parseInt(this.game.vitalityStr) >= 0) {
        const item = new ExtraDataItem();
        item.label = $r('app.string.widget_vitality');
        item.value = this.game.vitalityStr + '/' + this.game.vitalityMaxStr;
        item.color = WidgetColors.ZZZ_PRIMARY;
        return item;
      }
    }
    return null;
  }

  @Builder
  renderExtraData(extra: ExtraDataItem) {
    Column({ space: theme.value1 }) {
      Text(extra.label)
        .fontSize(theme.value9)
        .fontColor($r('app.color.gray_500'))

      Text(extra.value)
        .fontSize(theme.value11)
        .fontWeight(FontWeight.Medium)
        .fontColor(extra.color)
    }
    .alignItems(HorizontalAlign.End)
    .flexShrink(0)
  }

  build() {
    Row({ space: theme.value8 }) {
      // ── 左侧：竖线或小环 ──
      if (this.ringSize > 0) {
        // 2×4：小进度环（使用体力颜色）
        Stack() {
          Progress({
            value: this.ratio * 100,
            total: 100,
            type: ProgressType.Ring
          })
            .width(this.ringSize)
            .height(this.ringSize)
            .color(this.staminaColor)
            .backgroundColor($r('app.color.white'))
            .style({ strokeWidth: this.strokeWidth })
        }
        .width(this.ringSize)
        .height(this.ringSize)
        .flexShrink(0)
      } else {
        // 2×2：游戏色竖线（使用游戏主题色）
        Column()
          .width(theme.value3)
          .height(theme.value24)
          .borderRadius(theme.value2)
          .backgroundColor(this.gameThemeColor)
          .flexShrink(0)
      }

      // ── 中间列：游戏名 + 体力数字 + 恢复时间 ──
      Column({ space: theme.value1 }) {
        // 游戏名：11px, rgba(255,255,255,.5)
        Text(gameNameRes(this.game.gameId))
          .fontSize(theme.value11)
          .fontColor($r('app.color.gray_400'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 体力数字行：18px Bold + /max 11px
        Row({ space: theme.value2 }) {
          Text(String(parseCurrent(this.game.currentStr)))
            .fontSize(theme.value18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.staminaColor)
            .lineHeight(theme.value20)

          Text('/' + String(parseMax(this.game.maxStr)))
            .fontSize(theme.value11)
            .fontColor($r('app.color.gray_500'))
            .lineHeight(theme.value20)
        }
        .alignItems(VerticalAlign.Bottom)

        // 恢复时间：9px, rgba(255,255,255,.4)
        // 2×2 时始终显示，2×4 时根据游戏数决定是否显示
        if (this.ringSize === 0 || this.totalGameCount >= 3) {
          Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.game.secondsStr))
            .fontSize(theme.value9)
            .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.gray_500'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)

      // ── 右侧列（仅 2×4） ──
      if (this.ringSize > 0) {
        if (this.totalGameCount <= 2) {
          // 两游戏：显示额外数据
          if (this.getFirstExtra() !== null) {
            this.renderExtraData(this.getFirstExtra()!)
          }
        }
        // 三游戏：恢复时间已在中间列显示，右侧留空
      }
    }
    .width(theme.full)
    .alignItems(VerticalAlign.Center)
  }
}

@Preview
@Component
struct WidgetCompactGameRowPreview {
  build() {
    Column({ space: 8 }) {
      WidgetCompactGameRow({ game: new WidgetGameData(), ringSize: 0 })
      WidgetCompactGameRow({ game: new WidgetGameData(), ringSize: 24, strokeWidth: 3 })
    }
    .padding(16)
    .width(200)
    .backgroundColor($r('app.color.dark_400'))
  }
}
