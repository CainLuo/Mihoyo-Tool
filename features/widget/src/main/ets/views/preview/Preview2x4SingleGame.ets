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

  /** 右侧额外数据行（12fp / 弱化标签） */
  @Builder
  private extraRow(label: ResourceStr, value: ResourceStr, valueColor: ResourceColor = WidgetColors.WHITE) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor(WidgetColors.WHITE)
        .opacity(WidgetColors.OPACITY_TEXT_FAINT)
        .layoutWeight(1)

      Text(value)
        .fontSize(12)
        .fontWeight(600)
        .fontColor(valueColor)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  /** 派遣头像（completed 时带绿色对勾角标） */
  @Builder
  private expeditionAvatar(completed: boolean) {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Row()
        .width(24)
        .height(24)
        .borderRadius(12)
        .linearGradient({
          angle: 135,
          colors: [['rgba(100,100,120,0.8)', 0], ['rgba(60,60,80,0.8)', 1]]
        })

      if (completed) {
        Row() {
          Text('✓')
            .fontSize(7)
            .fontColor('#000000')
            .fontWeight(700)
        }
        .width(10)
        .height(10)
        .borderRadius(5)
        .backgroundColor('#34d399')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: -2, right: -2 })
      }
    }
    .width(24)
    .height(24)
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
          if (this.gameId === GameId.GENSHIN) {
            // 原神：洞天宝钱 + 每日委托 + 参量质变仪（去掉探索派遣）
            this.extraRow($r('app.string.widget_home_coin'), '1800/2400')
            this.extraRow($r('app.string.widget_daily_task'), '3/4')
            this.extraRow($r('app.string.widget_transformer'), $r('app.string.widget_transformer_ready'),
              WidgetColors.SUCCESS)
          } else if (this.gameId === GameId.STARRAIL) {
            // 星铁：后备开拓力 + 实训积分 + 模拟宇宙
            this.extraRow($r('app.string.widget_reserve_stamina'), '2400')
            this.extraRow($r('app.string.widget_train_score'), '400/500')
            this.extraRow($r('app.string.widget_rogue_weekly'), '800/1000')
          } else if (this.gameId === GameId.ZZZ) {
            // 绝区零：活跃度 + 录像店 + 刮刮卡
            this.extraRow($r('app.string.widget_vitality'), '300/400')
            this.extraRow($r('app.string.widget_video_store'), $r('app.string.widget_store_open'),
              WidgetColors.SUCCESS)
            this.extraRow($r('app.string.widget_card_sign'), $r('app.string.widget_card_done'),
              WidgetColors.SUCCESS)
          }
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
            this.expeditionAvatar(true)
            this.expeditionAvatar(true)
            this.expeditionAvatar(false)
            this.expeditionAvatar(false)
            this.expeditionAvatar(false)
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
