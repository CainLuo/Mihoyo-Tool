/**
 * WidgetMultiGameCompact.ets — 多游戏精简列表（2×2 / 2×4 共用）
 *
 * 严格按原型 wr-2x2.js / wr-2x4.js 多游戏分支实现：
 * - 2×2：竖线模式（ringSize=0）
 * - 2×4（2 游戏）：小环模式（ringSize=36），右侧显示额外数据
 * - 2×4（3 游戏）：更小环模式（ringSize=24），右侧只显示恢复时间
 * - 顶部：账号名（10px Medium）
 * - 每行：WidgetCompactGameRow
 * - 行间：1px 极细分割线（rgba 8%）
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { widgetTheme } from '../utils/WidgetTheme';
import { WidgetCompactGameRow } from './WidgetCompactGameRow';
import { WidgetAccountData, WidgetGameData } from '../models/WidgetModels';

@Component
export struct WidgetMultiGameCompact {

  @Prop data: WidgetAccountData = new WidgetAccountData();
  /** 0 = 2×2 竖线模式，>0 = 2×4 小环模式 */
  ringSize: number = 0;

  private get displayName(): string {
    return this.data.accountName.length > 0 ? this.data.accountName : this.data.accountUid;
  }

  private gameAt(idx: number): WidgetGameData {
    return idx < this.data.games.length ? this.data.games[idx] : new WidgetGameData();
  }

  /** 2×4 模式下根据游戏数量动态计算环大小 */
  private get dynamicRingSize(): number {
    if (this.ringSize === 0) {
      return 0;
    }
    return this.data.gameCount <= 2 ? widgetTheme.value36 : widgetTheme.value24;
  }

  /** 2×4 模式下根据游戏数量动态计算环线宽 */
  private get dynamicStrokeWidth(): number {
    if (this.ringSize === 0) {
      return 0;
    }
    return this.data.gameCount <= 2 ? widgetTheme.value4 : widgetTheme.value2;
  }

  build() {
    Column() {
      // 顶部账号名
      Text(this.displayName)
        .fontSize(widgetTheme.value10)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_on_dark_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: widgetTheme.value4 })

      // 游戏行列表（SpaceEvenly 均分剩余高度）
      Column() {
        WidgetCompactGameRow({
          game: this.gameAt(0),
          ringSize: this.dynamicRingSize,
          strokeWidth: this.dynamicStrokeWidth,
          totalGameCount: this.data.gameCount
        })

        if (this.data.gameCount >= 2) {
          Column()
            .width(widgetTheme.full)
            .height(widgetTheme.value1)
            .backgroundColor($r('app.color.surface_inactive_border'))
            .opacity(0.5)
            .margin({ top: widgetTheme.value4, bottom: widgetTheme.value4 })

          WidgetCompactGameRow({
            game: this.gameAt(1),
            ringSize: this.dynamicRingSize,
            strokeWidth: this.dynamicStrokeWidth,
            totalGameCount: this.data.gameCount
          })
        }

        if (this.data.gameCount >= 3) {
          Column()
            .width(widgetTheme.full)
            .height(widgetTheme.value1)
            .backgroundColor($r('app.color.surface_inactive_border'))
            .opacity(0.5)
            .margin({ top: widgetTheme.value4, bottom: widgetTheme.value4 })

          WidgetCompactGameRow({
            game: this.gameAt(2),
            ringSize: this.dynamicRingSize,
            strokeWidth: this.dynamicStrokeWidth,
            totalGameCount: this.data.gameCount
          })
        }
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .width(widgetTheme.full)
    .height(widgetTheme.full)
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview
@Component
struct WidgetMultiGameCompactPreview {
  build() {
    Column() {
      WidgetMultiGameCompact({ data: new WidgetAccountData(), ringSize: 0 })
    }
    .padding(12)
    .width(168)
    .height(168)
    .linearGradient({ angle: 135, colors: [['#181820', 0], ['#1c1c2c', 1]] })
    .borderRadius(16)
  }
}
