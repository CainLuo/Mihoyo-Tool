/**
 * WidgetZZZExtraRows.ets — 绝区零额外数据行组件
 *
 * 显示活跃度、刮刮卡、录像店经营等绝区零专属数据。
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetDataRow } from './WidgetDataRow';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

import { WidgetGameData } from '../models/WidgetModels';

@Component
export struct WidgetZZZExtraRows {
  private tm: ThemeManager = themeManager;

  @Prop game: WidgetGameData = new WidgetGameData();
  /** 数据行字体大小，默认 body12（13vp），4×4 传 body13（14vp） */
  fontSize: number = themeManager.current.value12;

  build() {
    Column({ space: 0 }) {
      if (parseInt(this.game.vitalityStr) >= 0) {
        WidgetDataRow({
          label: $r('app.string.widget_vitality'),
          value: this.game.vitalityStr + '/' + this.game.vitalityMaxStr,
          valueColor: $r('app.color.game_color_zzz'),
          fontSize: this.fontSize
        })
      }

      if (this.game.cardSign.length > 0) {
        WidgetDataRow({
          label: $r('app.string.widget_card_sign'),
          value: this.game.cardSign !== 'CardSignNo'
            ? $r('app.string.widget_card_done')
            : $r('app.string.widget_card_not_done'),
          valueColor: this.game.cardSign !== 'CardSignNo'
            ? $r('app.color.text_on_dark_high')
            : $r('app.color.text_on_dark_muted'),
          fontSize: this.fontSize
        })
      }

      if (this.game.videoStore.length > 0) {
        WidgetDataRow({
          label: $r('app.string.widget_video_store'),
          value: this.game.videoStore === 'SaleStateDoing'
            ? $r('app.string.widget_store_open')
            : $r('app.string.widget_store_closed'),
          valueColor: this.game.videoStore === 'SaleStateDoing'
            ? $r('app.color.accent_refine')
            : $r('app.color.text_on_dark_muted'),
          fontSize: this.fontSize
        })
      }
    }
    .width(this.tm.current.full)
    .justifyContent(FlexAlign.SpaceEvenly)
  }
}

@Preview
@Component
struct WidgetZZZExtraRowsPreview {
  build() {
    Column() {
      WidgetZZZExtraRows({ game: new WidgetGameData(), fontSize: 13 })
    }
    .padding(16)
    .width(200)
    .backgroundColor('#1a1a2e')
  }
}
