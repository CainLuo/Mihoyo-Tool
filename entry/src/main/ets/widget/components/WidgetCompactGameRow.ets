/**
 * WidgetCompactGameRow.ets — 多游戏精简行
 *
 * 严格按原型实现：
 * - 2×2：竖线（3vp 宽）+ 中间列（游戏名 + 体力数字） + 右侧列（恢复时间）
 * - 2×4（2 游戏）：小环（36vp）+ 中间列（游戏名 + 体力数字 + 恢复时间） + 右侧列（额外数据）
 * - 2×4（3 游戏）：更小环（24vp）+ 中间列（游戏名 + 体力数字 + 恢复时间） + 右侧列（恢复时间）
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { calcIsFull, calcRatio, gameColorRes, gameNameRes, parseCurrent, parseMax, formatRecoveryDesc, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetGameData } from '../models/WidgetModels';
import { DefaultTheme } from '../../theme/DefaultTheme';

/** 主题常量实例 */
const theme = new DefaultTheme();

class ExtraDataItem {
  label: ResourceStr = '';
  value: string = '';
  color: ResourceColor = Color.White;
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

  private get displayColor(): ResourceColor {
    return gameColorRes(this.game.gameId, this.isFull);
  }

  /** 获取第一条额外数据（2×4 两游戏时右侧显示） */
  private getFirstExtra(): ExtraDataItem | null {
    if (this.game.gameId === WIDGET_GAME_ID.GENSHIN) {
      if (parseInt(this.game.coinStr) >= 0) {
        const item = new ExtraDataItem();
        item.label = $r('app.string.widget_home_coin');
        item.value = this.game.coinStr + '/' + this.game.coinMaxStr;
        item.color = $r('app.color.accent_refine');
        return item;
      }
    } else if (this.game.gameId === WIDGET_GAME_ID.STARRAIL) {
      if (parseInt(this.game.trainStr) >= 0) {
        const item = new ExtraDataItem();
        item.label = $r('app.string.widget_train_score');
        item.value = this.game.trainStr + '/' + this.game.trainMaxStr;
        item.color = $r('app.color.accent_refine');
        return item;
      }
    } else if (this.game.gameId === WIDGET_GAME_ID.ZZZ) {
      if (parseInt(this.game.vitalityStr) >= 0) {
        const item = new ExtraDataItem();
        item.label = $r('app.string.widget_vitality');
        item.value = this.game.vitalityStr + '/' + this.game.vitalityMaxStr;
        item.color = $r('app.color.game_color_zzz');
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
        .fontColor($r('app.color.text_on_dark_muted'))

      Text(extra.value)
        .fontSize(theme.value11)
        .fontWeight(FontWeight.Medium)
        .fontColor(extra.color)
    }
    .alignItems(HorizontalAlign.End)
    .flexShrink(0)
  }

  build() {
    Row({ space: theme.value10 }) {
      // 左侧：竖线或小环
      if (this.ringSize > 0) {
        // 2×4：小进度环
        Stack() {
          Progress({
            value: calcRatio(this.game.currentStr, this.game.maxStr) * 100,
            total: 100,
            type: ProgressType.Ring
          })
            .width(this.ringSize)
            .height(this.ringSize)
            .color(this.displayColor)
            .backgroundColor($r('app.color.surface_inactive_border'))
            .style({ strokeWidth: this.strokeWidth })
        }
        .width(this.ringSize)
        .height(this.ringSize)
        .flexShrink(0)
      } else {
        // 2×2：游戏色竖线（3vp 宽，高度约 60% 父容器）
        Column()
          .width(theme.value3)
          .constraintSize({ minHeight: theme.value20, maxHeight: theme.value32 })
          .borderRadius(theme.value2)
          .backgroundColor(this.displayColor)
          .flexShrink(0)
      }

      // 中间列：游戏名 + 体力数字 + (2×4 时显示恢复时间)
      Column({ space: theme.value1 }) {
        Text(gameNameRes(this.game.gameId))
          .fontSize(theme.value9)
          .fontColor($r('app.color.text_on_dark_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: this.ringSize > 0 ? theme.value1 : theme.value2 }) {
          Text(String(parseCurrent(this.game.currentStr)))
            .fontSize(this.ringSize > 0 ? (this.totalGameCount <= 2 ? theme.value16 : theme.value14) : theme.value18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.displayColor)
            .lineHeight(theme.value18)

          Text('/' + String(parseMax(this.game.maxStr)))
            .fontSize(theme.value9)
            .fontColor($r('app.color.text_on_dark_muted'))
            .alignSelf(ItemAlign.End)
            .margin({ bottom: theme.value1 })
        }
        .alignItems(VerticalAlign.Bottom)

        // 2×4 时在中间列显示恢复时间
        if (this.ringSize > 0) {
          Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.game.secondsStr))
            .fontSize(theme.value9)
            .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_muted'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)

      // 右侧列
      if (this.ringSize > 0) {
        // 2×4：两游戏时显示额外数据，三游戏时显示恢复时间
        if (this.totalGameCount <= 2) {
          if (this.getFirstExtra() !== null) {
            this.renderExtraData(this.getFirstExtra()!)
          }
        } else {
          Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.game.secondsStr))
            .fontSize(theme.value9)
            .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_muted'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .flexShrink(0)
        }
      } else {
        // 2×2：右侧显示恢复时间
        Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.game.secondsStr))
          .fontSize(theme.value9)
          .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_muted'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.End)
          .flexShrink(0)
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
    .backgroundColor('#1a1a2e')
  }
}
