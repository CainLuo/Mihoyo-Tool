/**
 * Preview1x2Content.ets — Widget 配置预览 1x2 内容组件
 *
 * 显示单个游戏的 1x2 预览内容：
 * - 游戏名 + UID
 * - 当前体力 / 最大体力
 * - 恢复时间
 */

import { GameId } from 'core';
import { WidgetColors, DefaultTheme } from 'widgetbase';
import { PreviewStamina, getPreviewStaminaData } from '../../model/WidgetPreviewModels';
import { getWidgetGameName, getStaminaColorType, getStaminaColor, formatRecoveryTime } from '../../utils/WidgetPreviewUtil';

@ComponentV2
export struct Preview1x2Content {
  @Param gameId: GameId = GameId.GENSHIN;
  @Param roleId: string = '';

  @Local theme: DefaultTheme = new DefaultTheme();

  private get staminaData(): PreviewStamina {
    return getPreviewStaminaData(this.gameId);
  }

  private get staminaRatio(): number {
    return this.staminaData.max > 0 ? this.staminaData.cur / this.staminaData.max : 0;
  }

  build() {
    Column() {
      // 第一行：游戏名 + UID
      Row({ space: this.theme.value4 }) {
        Text(getWidgetGameName(this.gameId))
          .fontSize(this.theme.font10)
          .fontWeight(FontWeight.Medium)
          .fontColor(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_TEXT_MUTED)

        Text($r('app.string.widget_uid_prefix', this.roleId))
          .fontSize(this.theme.font9)
          .fontColor(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_TEXT_GHOST)
      }

      // 第二行：当前体力 / 最大体力
      Row({ space: this.theme.value2 }) {
        Text(String(this.staminaData.cur))
          .fontSize(this.theme.fontBold18)
          .fontWeight(FontWeight.Bold)
          .fontColor(getStaminaColor(getStaminaColorType(this.staminaRatio), this.gameId))

        Text('/' + String(this.staminaData.max))
          .fontSize(this.theme.fontBold18)
          .fontColor(WidgetColors.WHITE)
          .opacity(WidgetColors.OPACITY_TEXT_FAINT)
      }
      .alignItems(VerticalAlign.Bottom)

      // 第三行：恢复时间
      Text(formatRecoveryTime(this.staminaData))
        .fontSize(this.theme.font10)
        .fontColor(WidgetColors.WHITE)
        .opacity(WidgetColors.OPACITY_TEXT_FAINT)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}
