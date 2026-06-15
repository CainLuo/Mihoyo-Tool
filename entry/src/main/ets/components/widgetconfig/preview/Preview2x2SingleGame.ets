/**
 * Preview2x2SingleGame.ets — Widget 配置预览 2x2 单游戏内容
 *
 * 显示单个游戏的 2x2 详细布局：
 * - 头部：游戏名 + UID
 * - 体力区块：当前/最大 + 恢复时间
 * - 额外数据行（根据游戏不同显示不同内容）
 */

import { GameId } from 'core';
import { WidgetColors } from '../../../widget/models/WidgetUIStates';
import { PreviewStaminaData, getPreviewStaminaData } from '../../../models/WidgetPreviewModels';
import { PreviewExtraDataRow } from './PreviewExtraDataRow';
import { DefaultTheme } from '../../../theme/DefaultTheme';
import { gameIdToWidgetName, staminaColorType, staminaColor, recoveryTimeText } from './WidgetPreviewUtils';

@ComponentV2
export struct Preview2x2SingleGame {
  @Param gameId: GameId = GameId.GENSHIN;
  @Param roleId: string = '';

  @Local theme: DefaultTheme = new DefaultTheme();

  private get staminaData(): PreviewStaminaData {
    return getPreviewStaminaData(this.gameId);
  }

  private get staminaRatio(): number {
    return this.staminaData.max > 0 ? this.staminaData.cur / this.staminaData.max : 0;
  }

  build() {
    Column() {
      // 头部：游戏名 + UID
      Column({ space: 1 }) {
        Text(gameIdToWidgetName(this.gameId))
          .fontSize(this.theme.font11)
          .fontWeight(FontWeight.Bold)
          .fontColor(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_TEXT_MEDIUM)
          .maxLines(1)

        Text($r('app.string.widget_uid_prefix', this.roleId))
          .fontSize(this.theme.font10)
          .fontColor(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_TEXT_GHOST)
      }
      .width(this.theme.full)
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: this.theme.value8 })

      // 体力区块
      Column({ space: 2 }) {
        Row({ space: 3 }) {
          Text(String(this.staminaData.cur))
            .fontSize(this.theme.fontBold24)
            .fontWeight(FontWeight.Bold)
            .fontColor(staminaColor(staminaColorType(this.staminaRatio), this.gameId))

          Text('/' + String(this.staminaData.max))
            .fontSize(this.theme.font14)
            .fontColor(WidgetColors.WHITE)
            .opacity(WidgetColors.OPACITY_TEXT_FAINT)
        }

        Text(recoveryTimeText(this.staminaData))
          .fontSize(this.theme.font11)
          .fontColor(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_TEXT_SECONDARY)
      }
      .width(this.theme.full)
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: this.theme.value8 })

      // 底部：额外数据行
      if (this.gameId === GameId.GENSHIN) {
        PreviewExtraDataRow({
          label: $r('app.string.widget_expedition'),
          value: '3/4',
          valueColor: WidgetColors.WHITE
        })

        PreviewExtraDataRow({
          label: $r('app.string.widget_home_coin'),
          value: '1800/2400',
          valueColor: WidgetColors.WHITE
        })

        PreviewExtraDataRow({
          label: $r('app.string.widget_daily_task'),
          value: '3/4',
          valueColor: WidgetColors.WHITE
        })
      } else if (this.gameId === GameId.STARRAIL) {
        PreviewExtraDataRow({
          label: $r('app.string.widget_train_score'),
          value: '400/500',
          valueColor: WidgetColors.WHITE
        })

        PreviewExtraDataRow({
          label: $r('app.string.widget_rogue_weekly'),
          value: '800/1000',
          valueColor: WidgetColors.WHITE
        })
      } else if (this.gameId === GameId.ZZZ) {
        PreviewExtraDataRow({
          label: $r('app.string.widget_video_store'),
          value: $r('app.string.widget_store_open'),
          valueColor: WidgetColors.SUCCESS
        })

        PreviewExtraDataRow({
          label: $r('app.string.widget_card_sign'),
          value: $r('app.string.widget_card_done'),
          valueColor: WidgetColors.SUCCESS
        })
      }
    }
    .width(this.theme.full)
    .height(this.theme.full)
    .alignItems(HorizontalAlign.Start)
  }
}
