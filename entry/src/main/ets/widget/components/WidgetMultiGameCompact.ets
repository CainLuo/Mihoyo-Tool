/**
 * WidgetMultiGameCompact.ets — 多游戏精简列表（2×2 / 2×4 共用）
 *
 * 严格按原型 wr-2x2.js / wr-2x4.js 多游戏分支实现：
 * - 2×2：竖线模式（ringSize=0），最多显示 2 个游戏
 * - 2×4（2 游戏）：小环模式（ringSize=36），右侧显示额外数据
 * - 2×4（3 游戏）：更小环模式（ringSize=24），恢复时间在中间列
 * - 顶部：账号名（11px Medium, rgba(255,255,255,.7)）
 * - 每行：WidgetCompactGameRow
 * - 行间：1px 极细分割线（rgba 8%）
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetCompactGameRow } from './WidgetCompactGameRow';
import { WidgetGameData } from '../models/WidgetModels';
import { DefaultTheme } from '../../theme/DefaultTheme';

/** 主题常量实例 */
const theme = new DefaultTheme();

@Component
export struct WidgetMultiGameCompact {

  /** 账号名 */
  @Prop accountName: string = '';
  /** 账号 UID */
  @Prop accountUid: string = '';
  /** 游戏数量 */
  @Prop gameCount: number = 0;
  /** 游戏数据数组（必须用 @Prop） */
  @Prop games: WidgetGameData[] = [];
  /** 0 = 2×2 竖线模式，>0 = 2×4 小环模式 */
  ringSize: number = 0;

  private get displayName(): string {
    return this.accountName.length > 0 ? this.accountName : this.accountUid;
  }

  private gameAt(idx: number): WidgetGameData {
    return idx < this.games.length ? this.games[idx] : new WidgetGameData();
  }

  /** 2×4 模式下根据游戏数量动态计算环大小 */
  private get dynamicRingSize(): number {
    if (this.ringSize === 0) {
      return 0;
    }
    return this.gameCount <= 2 ? theme.value36 : theme.value24;
  }

  /** 2×4 模式下根据游戏数量动态计算环线宽 */
  private get dynamicStrokeWidth(): number {
    if (this.ringSize === 0) {
      return 0;
    }
    return this.gameCount <= 2 ? theme.value4 : theme.value2;
  }

  /** 2x2 最多显示 2 个游戏 */
  private get displayGameCount(): number {
    if (this.ringSize === 0) {
      return Math.min(this.gameCount, 2);
    }
    return this.gameCount;
  }

  build() {
    Column() {
      // ── 顶部账号名：11px Medium, rgba(255,255,255,.7) ──
      Text(this.displayName)
        .fontSize(theme.value11)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.gray_400'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: theme.value4 })

      // ── 游戏行列表 ──
      Column() {
        // 第一个游戏
        WidgetCompactGameRow({
          game: this.gameAt(0),
          ringSize: this.dynamicRingSize,
          strokeWidth: this.dynamicStrokeWidth,
          totalGameCount: this.displayGameCount
        })

        // 第二个游戏
        if (this.displayGameCount >= 2) {
          // 1px 分割线
          Column()
            .width(theme.full)
            .height(theme.value1)
            .backgroundColor($r('app.color.white'))
            .opacity(0.5)
            .margin({ top: theme.value4, bottom: theme.value4 })

          WidgetCompactGameRow({
            game: this.gameAt(1),
            ringSize: this.dynamicRingSize,
            strokeWidth: this.dynamicStrokeWidth,
            totalGameCount: this.displayGameCount
          })
        }

        // 第三个游戏（仅 2x4）
        if (this.displayGameCount >= 3) {
          Column()
            .width(theme.full)
            .height(theme.value1)
            .backgroundColor($r('app.color.white'))
            .opacity(0.5)
            .margin({ top: theme.value4, bottom: theme.value4 })

          WidgetCompactGameRow({
            game: this.gameAt(2),
            ringSize: this.dynamicRingSize,
            strokeWidth: this.dynamicStrokeWidth,
            totalGameCount: this.displayGameCount
          })
        }
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .width(theme.full)
    .height(theme.full)
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview
@Component
struct WidgetMultiGameCompactPreview {
  build() {
    Column() {
      WidgetMultiGameCompact({ 
        accountName: '旅行者',
        accountUid: '123456789',
        gameCount: 2,
        games: [],
        ringSize: 0 
      })
    }
    .padding(12)
    .width(168)
    .height(168)
    .linearGradient({ angle: 135, colors: [[$r('app.color.widget_bg_default_1'), 0], [$r('app.color.widget_bg_default_2'), 1]] })
    .borderRadius(16)
  }
}
