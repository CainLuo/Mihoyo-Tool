/**
 * Widget4x4MultiGame.ets — 4×4 多游戏布局
 *
 * 顶部账号名行 + 2~3 个游戏区块（WidgetMultiGameBlock），区块间用分割线隔开。
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetMultiGameBlock } from './WidgetMultiGameBlock';

import { WidgetAccountData, WidgetGameData } from '../models/WidgetModels';

@Component
export struct Widget4x4MultiGame {
  private tm: ThemeManager = themeManager;

  @Prop data: WidgetAccountData = new WidgetAccountData();

  private get displayName(): string {
    return this.data.accountName.length > 0 ? this.data.accountName : this.data.accountUid;
  }

  private gameAt(idx: number): WidgetGameData {
    return idx < this.data.games.length ? this.data.games[idx] : new WidgetGameData();
  }

  build() {
    Column({ space: 0 }) {
      Row({ space: themeManager.current.value8 }) {
        Text(this.displayName)
          .fontSize(themeManager.current.value13)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_on_dark_high'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.data.accountUid)
          .fontSize(themeManager.current.value11)
          .fontColor($r('app.color.text_on_dark_muted'))
      }
      .margin({ bottom: this.tm.current.value8 })

      Column({ space: 0 }) {
        WidgetMultiGameBlock({
          game: this.gameAt(0),
          totalGameCount: this.data.gameCount
        })

        if (this.data.gameCount >= 2) {
          Divider()
            .color($r('app.color.surface_inactive_border'))
            .margin({ top: this.tm.current.value4, bottom: this.tm.current.value4 })

          WidgetMultiGameBlock({
            game: this.gameAt(1),
            totalGameCount: this.data.gameCount
          })
        }

        if (this.data.gameCount >= 3) {
          Divider()
            .color($r('app.color.surface_inactive_border'))
            .margin({ top: this.tm.current.value4, bottom: this.tm.current.value4 })

          WidgetMultiGameBlock({
            game: this.gameAt(2),
            totalGameCount: this.data.gameCount
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
struct Widget4x4MultiGamePreview {
  build() {
    Column() {
      Widget4x4MultiGame({ data: new WidgetAccountData() })
    }
    .padding(12)
    .width(352)
    .height(352)
    .backgroundColor('#2E3033')
    .borderRadius(16)
  }
}
