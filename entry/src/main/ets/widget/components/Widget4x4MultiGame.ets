/**
 * Widget4x4MultiGame.ets — 4×4 多游戏布局
 *
 * 严格按原型 wr-4x4.js 多游戏分支实现：
 * - 顶部：账号名 + UID（固定高度）
 * - 每个游戏区块（flex:1 均分）：游戏名+体力数字+恢复时间 + 数据行
 * - 区块间：1px 细分割线
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetMultiGameBlock } from './WidgetMultiGameBlock';
import { WidgetAccountData, WidgetGameData } from '../models/WidgetModels';
import { DefaultTheme } from '../../theme/DefaultTheme';

/** 主题常量实例 */
const theme = new DefaultTheme();

@Component
export struct Widget4x4MultiGame {

  @Prop data: WidgetAccountData = new WidgetAccountData();

  private get displayName(): string {
    return this.data.accountName.length > 0 ? this.data.accountName : this.data.accountUid;
  }

  private gameAt(idx: number): WidgetGameData {
    return idx < this.data.games.length ? this.data.games[idx] : new WidgetGameData();
  }

  build() {
    Column() {
      // 顶部：账号名 + UID（固定高度，带底部分割线）
      Row({ space: theme.value8 }) {
        Text(this.displayName)
          .fontSize(theme.value12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.white'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(this.data.accountUid)
          .fontSize(theme.value10)
          .fontColor($r('app.color.gray_500'))
      }
      .width(theme.full)
      .padding({ bottom: theme.value8 })
      .border({ width: { bottom: 1 }, color: $r('app.color.white') })
      .flexShrink(0)

      // 游戏区块列表（均分剩余高度）
      Column() {
        WidgetMultiGameBlock({
          game: this.gameAt(0),
          totalGameCount: this.data.gameCount
        })

        if (this.data.gameCount >= 2) {
          Column()
            .width(theme.full)
            .height(theme.value1)
            .backgroundColor($r('app.color.white'))
            .opacity(0.5)
            .flexShrink(0)

          WidgetMultiGameBlock({
            game: this.gameAt(1),
            totalGameCount: this.data.gameCount
          })
        }

        if (this.data.gameCount >= 3) {
          Column()
            .width(theme.full)
            .height(theme.value1)
            .backgroundColor($r('app.color.white'))
            .opacity(0.5)
            .flexShrink(0)

          WidgetMultiGameBlock({
            game: this.gameAt(2),
            totalGameCount: this.data.gameCount
          })
        }
      }
      .layoutWeight(1)
      .width(theme.full)
    }
    .width(theme.full)
    .height(theme.full)
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview
@Component
struct Widget4x4MultiGamePreview {
  build() {
    Column() {
      Widget4x4MultiGame({ data: new WidgetAccountData() })
    }
    .padding(12)
    .width(352)
    .height(352)
    .backgroundColor($r('app.color.widget_bg_default_1'))
    .borderRadius(16)
  }
}
