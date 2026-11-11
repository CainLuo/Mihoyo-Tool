/**
 * Preview2x4SingleGame.ets — Widget 配置预览 2x4 单游戏水平布局
 *
 * 布局与 Widget2x4SingleGame.ets 一致：
 * - 左侧：游戏名 → 角色名 → UID → 体力数值 → 恢复时间
 * - 中间分隔线
 * - 右侧：额外数据行（最多3条，原神去掉探索派遣）
 * - 底部（原神）：派遣角色头像
 */

import { GameId } from 'core';
import { WidgetColors, DefaultTheme } from 'widgetbase';
import { PreviewStamina, getPreviewStaminaData } from '../../model/WidgetPreviewModels';
import {
  getWidgetGameName,
  getStaminaColorType,
  getStaminaColor,
  formatRecoveryTime
} from '../../utils/WidgetPreviewUtil';
import { PreviewExtraDataRow, PreviewExtraRow } from './PreviewExtraDataRow';
import { PreviewExpeditionAvatar } from './PreviewExpeditionAvatar';

/** 获取额外数据行（2×4 单游戏：原神去掉探索派遣） */
function getExtraRows(gameId: GameId): PreviewExtraRow[] {
  if (gameId === GameId.GENSHIN) {
    return [
      new PreviewExtraRow($r('app.string.widget_home_coin'), '1800/2400'),
      new PreviewExtraRow($r('app.string.widget_daily_task'), '3/4'),
      new PreviewExtraRow($r('app.string.widget_transformer'), $r('app.string.widget_transformer_ready'),
        WidgetColors.SUCCESS),
    ];
  } else if (gameId === GameId.STARRAIL) {
    return [
      new PreviewExtraRow($r('app.string.widget_reserve_stamina'), '2400'),
      new PreviewExtraRow($r('app.string.widget_train_score'), '400/500'),
      new PreviewExtraRow($r('app.string.widget_rogue_weekly'), '800/1000'),
    ];
  } else if (gameId === GameId.ZZZ) {
    return [
      new PreviewExtraRow($r('app.string.widget_vitality'), '300/400'),
      new PreviewExtraRow($r('app.string.widget_video_store'), $r('app.string.widget_store_open'),
        WidgetColors.SUCCESS),
      new PreviewExtraRow($r('app.string.widget_card_sign'), $r('app.string.widget_card_done'),
        WidgetColors.SUCCESS),
    ];
  }
  return [];
}

@ComponentV2
export struct Preview2x4SingleGame {
  @Param gameId: GameId = GameId.GENSHIN;
  @Param roleId: string = '';

  @Local theme: DefaultTheme = new DefaultTheme();

  private get staminaData(): PreviewStamina {
    return getPreviewStaminaData(this.gameId);
  }

  private get staminaRatio(): number {
    return this.staminaData.max > 0 ? this.staminaData.cur / this.staminaData.max : 0;
  }

  private get staminaColorResource(): Resource {
    return getStaminaColor(getStaminaColorType(this.staminaRatio), this.gameId);
  }

  private get extraRows(): PreviewExtraRow[] {
    return getExtraRows(this.gameId);
  }

  build() {
    Column() {
      // 主体内容：左右两列
      Row() {
        // 左侧：游戏名 → 角色名 → UID → 体力 → 恢复时间
        Column() {
          // 游戏名 14fp
          Text(getWidgetGameName(this.gameId))
            .fontSize(14)
            .fontWeight(500)
            .fontColor(WidgetColors.WHITE)
            .opacity(WidgetColors.OPACITY_TEXT_MEDIUM)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // UID 12fp
          Text() {
            Span($r('app.string.widget_uid_prefix'))
            Span(this.roleId)
          }
            .fontSize(12)
            .fontColor(WidgetColors.WHITE)
            .opacity(WidgetColors.OPACITY_TEXT_GHOST)
            .maxLines(1)
            .margin({ top: 2 })

          // 体力数值 22fp
          Row() {
            Text(String(this.staminaData.cur))
              .fontSize(22)
              .fontWeight(700)
              .fontColor(this.staminaColorResource)

            Text('/' + String(this.staminaData.max))
              .fontSize(14)
              .fontColor(WidgetColors.WHITE)
              .opacity(WidgetColors.OPACITY_TEXT_GHOST)
              .margin({ left: 2 })
          }
          .alignItems(VerticalAlign.Bottom)
          .margin({ top: 4 })

          // 恢复时间 12fp
          Text(formatRecoveryTime(this.staminaData))
            .fontSize(12)
            .fontColor(WidgetColors.WHITE)
            .opacity(WidgetColors.OPACITY_TEXT_FAINT)
            .maxLines(1)
            .margin({ top: 2 })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
        .flexShrink(0)

        // 分隔线
        Row()
          .width(1)
          .height('50%')
          .backgroundColor(WidgetColors.WHITE)
          .opacity(0.08)
          .margin({ left: 12, right: 12 })

        // 右侧：额外数据行
        Column({ space: 6 }) {
          ForEach(this.extraRows, (row: PreviewExtraRow) => {
            PreviewExtraDataRow({
              label: row.label,
              value: row.value,
              valueColor: row.valueColor,
              fontSize: 12,
              labelOpacity: WidgetColors.OPACITY_TEXT_FAINT,
              valueFontWeight: 600,
              valueOpacity: 1
            })
          })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .layoutWeight(1)

      // 底部（原神）：派遣角色头像
      if (this.gameId === GameId.GENSHIN) {
        Column() {
          // 分隔线
          Row()
            .width('100%')
            .height(1)
            .backgroundColor(WidgetColors.WHITE)
            .opacity(0.06)

          // 派遣内容
          Row({ space: 4 }) {
            Text($r('app.string.widget_expedition'))
              .fontSize(10)
              .fontColor(WidgetColors.WHITE)
              .opacity(0.35)
              .margin({ right: 2 })

            // 5个派遣头像（2个完成，3个进行中）
            PreviewExpeditionAvatar({ avatarSize: 24, completed: true })
            PreviewExpeditionAvatar({ avatarSize: 24, completed: true })
            PreviewExpeditionAvatar({ avatarSize: 24, completed: false })
            PreviewExpeditionAvatar({ avatarSize: 24, completed: false })
            PreviewExpeditionAvatar({ avatarSize: 24, completed: false })
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
          .margin({ top: 8 })
        }
        .width('100%')
      }
    }
    .width(this.theme.full)
    .height(this.theme.full)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 12, right: 12 })
  }
}
