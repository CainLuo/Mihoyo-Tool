/**
 * WidgetMultiGameCompact.ets — 多游戏精简列表布局（2×2 / 2×4 共用）
 *
 * 顶部账号名行 + 2~3 个 WidgetCompactGameRow，区块间用分割线隔开。
 * 2×2 和 2×4 的多游戏模式结构完全相同，通过 ringSize 区分环的大小。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetCompactGameRow } from './WidgetCompactGameRow';

import { WidgetAccountData, WidgetGameData } from '../models/WidgetModels';

@Component
export struct WidgetMultiGameCompact {
  private tm: ThemeManager = themeManager;

  @Prop data: WidgetAccountData = new WidgetAccountData();
  /** 进度环直径（vp）：2×2 用 28，2×4 用 24 */
  ringSize: number = 28;

  private get displayName(): string {
    return this.data.accountName.length > 0 ? this.data.accountName : this.data.accountUid;
  }

  private gameAt(idx: number): WidgetGameData {
    return idx < this.data.games.length ? this.data.games[idx] : new WidgetGameData();
  }

  build() {
    Column({ space: 0 }) {
      Text(this.displayName)
        .fontSize(themeManager.current.value11)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_on_dark_high'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: this.tm.current.value8 })

      Column({ space: 0 }) {
        WidgetCompactGameRow({
          game: this.gameAt(0),
          ringSize: this.ringSize,
          strokeWidth: themeManager.current.value2
        })

        if (this.data.gameCount >= 2) {
          Divider()
            .color($r('app.color.surface_inactive_border'))
            .margin({ top: this.tm.current.value4, bottom: this.tm.current.value4 })

          WidgetCompactGameRow({
            game: this.gameAt(1),
            ringSize: this.ringSize,
            strokeWidth: themeManager.current.value2
          })
        }

        if (this.data.gameCount >= 3) {
          Divider()
            .color($r('app.color.surface_inactive_border'))
            .margin({ top: this.tm.current.value4, bottom: this.tm.current.value4 })

          WidgetCompactGameRow({
            game: this.gameAt(2),
            ringSize: this.ringSize,
            strokeWidth: themeManager.current.value2
          })
        }
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview
@Component
struct WidgetMultiGameCompactPreview {
  build() {
    Column() {
      WidgetMultiGameCompact({ data: new WidgetAccountData(), ringSize: 28 })
    }
    .padding(16)
    .width(168)
    .height(168)
    .backgroundColor('#1a1a2e')
  }
}
