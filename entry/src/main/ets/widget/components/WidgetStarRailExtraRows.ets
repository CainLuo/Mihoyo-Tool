/**
 * WidgetStarRailExtraRows.ets — 星穹铁道额外数据行组件
 *
 * 显示实训积分、历战余响（周本）、模拟宇宙积分等星铁专属数据。
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetDataRow } from './WidgetDataRow';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

import { WidgetGameData } from '../models/WidgetModels';

@Component
export struct WidgetStarRailExtraRows {
  private tm: ThemeManager = themeManager;

  @Prop game: WidgetGameData = new WidgetGameData();
  /** 数据行字体大小，默认 body12（13vp），4×4 传 body13（14vp） */
  fontSize: number = themeManager.current.value12;

  build() {
    Column({ space: 0 }) {
      if (parseInt(this.game.trainStr) >= 0) {
        WidgetDataRow({
          label: $r('app.string.widget_train_score'),
          value: this.game.trainStr + '/' + this.game.trainMaxStr,
          valueColor: $r('app.color.accent_refine'),
          fontSize: this.fontSize
        })
      }

      if (parseInt(this.game.cocoonStr) >= 0) {
        WidgetDataRow({
          label: $r('app.string.widget_cocoon'),
          value: this.game.cocoonStr + '/' + this.game.cocoonLimitStr,
          valueColor: $r('app.color.accent_refine'),
          fontSize: this.fontSize
        })
      }

      if (parseInt(this.game.rogueStr) >= 0) {
        WidgetDataRow({
          label: $r('app.string.widget_rogue_weekly'),
          value: this.game.rogueStr + '/' + this.game.rogueMaxStr,
          valueColor: $r('app.color.game_color_zzz'),
          fontSize: this.fontSize
        })
      }
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .justifyContent(FlexAlign.SpaceEvenly)
  }
}

@Preview
@Component
struct WidgetStarRailExtraRowsPreview {
  build() {
    Column() {
      WidgetStarRailExtraRows({ game: new WidgetGameData(), fontSize: 13 })
    }
    .padding(16)
    .width(200)
    .backgroundColor('#1a1a2e')
  }
}
