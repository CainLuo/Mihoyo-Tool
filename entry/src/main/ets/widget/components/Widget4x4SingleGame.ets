/**
 * Widget4x4SingleGame.ets — 4×4 单游戏完整布局
 *
 * 严格按原型 wr-4x4.js 多区块分组版实现：
 *
 * 布局（每个区块 flex:1 均分高度）：
 * ┌─────────────────────────────┐
 * │ 游戏名              账号名  │  顶部标题行（带底部分割线）
 * ├─────────────────────────────┤
 * │ 体力标签(10px uppercase)    │  区块1：体力（flex:1）
 * │ 36px数字  /上限             │
 * │ 恢复时间                    │
 * │ [星铁] 后备开拓力  2400     │
 * ├─────────────────────────────┤
 * │ 数据行1    值1              │  区块2：数据前半（flex:1）
 * │ 数据行2    值2              │
 * ├─────────────────────────────┤
 * │ 数据行3    值3              │  区块3：数据后半（flex:1，原神）
 * │ 数据行4    值4              │  或：数据后半（星铁/绝区零）
 * ├─────────────────────────────┤
 * │ 探索派遣格子                │  区块4：派遣（flex:1，仅原神）
 * └─────────────────────────────┘
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { DefaultTheme } from '../../theme/DefaultTheme';

/** 主题常量实例 */
const theme = new DefaultTheme();
import { WidgetExpeditions } from './WidgetExpeditions';
import { gameColorRes, gameNameRes, staminaLabelRes, calcIsFull, formatRecoveryDesc, parseCurrent, parseMax, WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetSingleGameData, WidgetGameData } from '../models/WidgetModels';

/** 单条数据行：标签左，数值右，flex:1 撑满区块高度 */
@Component
struct DataRow {
  label: ResourceStr = '';
  value: ResourceStr = '';
  valueColor: ResourceColor = $r('app.color.text_on_dark_high');

  build() {
    Row() {
      Text(this.label)
        .fontSize(theme.value13)
        .fontColor($r('app.color.text_on_dark_secondary'))
        .layoutWeight(1)

      Text(this.value)
        .fontSize(theme.value13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.valueColor)
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(VerticalAlign.Center)
  }
}

@Component
export struct Widget4x4SingleGame {

  @Prop data: WidgetSingleGameData = new WidgetSingleGameData();

  aboutToAppear() {
    // 静默处理
  }

  private get displayName(): string {
    return this.data.accountName.length > 0 ? this.data.accountName : this.data.accountUid;
  }

  private get isFull(): boolean {
    return calcIsFull(this.data.game.currentStr, this.data.game.maxStr, this.data.game.secondsStr);
  }

  private get gameColor(): ResourceColor {
    return gameColorRes(this.data.game.gameId, false);
  }

  /** 已完成的派遣数量 */
  private get expeditionFinished(): number {
    return parseInt(this.data.game.expeditionFinishedStr) || 0;
  }

  build() {
    Column() {
      // ── 顶部标题行（带底部分割线）──
      Row({ space: theme.value5 }) {
        Column()
          .width(theme.value8)
          .height(theme.value8)
          .borderRadius(theme.value8)
          .backgroundColor(this.gameColor)
          .flexShrink(0)

        Text(gameNameRes(this.data.game.gameId))
          .fontSize(theme.value16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_on_dark_high'))
          .layoutWeight(1)

        Text(this.displayName)
          .fontSize(theme.value10)
          .fontColor($r('app.color.text_on_dark_muted'))
      }
      .width(theme.full)
      .alignItems(VerticalAlign.Center)
      .padding({ bottom: theme.value10 })
      .border({ width: { bottom: 1 }, color: $r('app.color.surface_inactive_border') })
      .flexShrink(0)

      // ── 区块1：体力（flex:1）──
      Column() {
        // 体力标签（uppercase 小字）
        Text(staminaLabelRes(this.data.game.gameId))
          .fontSize(theme.value10)
          .fontColor($r('app.color.text_on_dark_muted'))
          .margin({ bottom: theme.value5 })

        // 体力数字 + /上限
        Row({ space: theme.value4 }) {
          Text(String(parseCurrent(this.data.game.currentStr)))
            .fontSize(theme.value36)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isFull ? $r('app.color.color_danger') : this.gameColor)
            .lineHeight(theme.value36)

          Text('/ ' + String(parseMax(this.data.game.maxStr)))
            .fontSize(theme.value16)
            .fontColor($r('app.color.text_on_dark_muted'))
            .alignSelf(ItemAlign.End)
            .margin({ bottom: theme.value4 })
        }
        .alignItems(VerticalAlign.Bottom)
        .margin({ bottom: theme.value4 })

        // 恢复时间
        Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.data.game.secondsStr))
          .fontSize(theme.value13)
          .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_secondary'))

        // 星铁：后备开拓力
        if (this.data.game.gameId === WIDGET_GAME_ID.STARRAIL && parseInt(this.data.game.reserveStr) >= 0) {
          Row({ space: theme.value5 }) {
            Text($r('app.string.widget_reserve_stamina'))
              .fontSize(theme.value12)
              .fontColor($r('app.color.text_on_dark_muted'))

            Text(this.data.game.reserveStr)
              .fontSize(theme.value14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.game_color_starrail'))
          }
          .margin({ top: theme.value4 })
        }
      }
      .width(theme.full)
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .padding({ top: theme.value8, bottom: theme.value8 })
      .border({ width: { bottom: 1 }, color: $r('app.color.surface_inactive_border') })

      // ── 区块2：探索派遣 + 洞天财瓮（flex:1，原神）──
      if (this.data.game.gameId === WIDGET_GAME_ID.GENSHIN) {
        Column() {
          // 探索派遣
          if (parseInt(this.data.game.expeditionMaxStr) >= 0) {
            DataRow({
              label: $r('app.string.widget_expedition'),
              value: this.data.game.expeditionFinishedStr + '/' + this.data.game.expeditionMaxStr,
              valueColor: $r('app.color.game_color_starrail')
            })
          }
          // 洞天财瓮
          if (parseInt(this.data.game.coinStr) >= 0) {
            DataRow({
              label: $r('app.string.widget_home_coin'),
              value: this.data.game.coinStr + '/' + this.data.game.coinMaxStr,
              valueColor: $r('app.color.accent_refine')
            })
          }
        }
        .width(theme.full)
        .layoutWeight(1)
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding({ top: theme.value8, bottom: theme.value8 })
        .border({ width: { bottom: 1 }, color: $r('app.color.surface_inactive_border') })

        // ── 区块3：每日委托 + 参量质变仪（flex:1，原神）──
        Column() {
          // 每日委托
          if (parseInt(this.data.game.taskStr) >= 0) {
            DataRow({
              label: $r('app.string.widget_daily_task'),
              value: this.data.game.taskStr + '/' + this.data.game.taskTotalStr +
                (this.data.game.taskAllReceived === 'true' ? $r('app.string.widget_task_received_suffix') : ''),
              valueColor: this.data.game.taskAllReceived === 'true'
                ? $r('app.color.color_success')
                : $r('app.color.game_color_zzz')
            })
          }
          // 参量质变仪
          if (this.data.game.transformerStr.length > 0) {
            DataRow({
              label: $r('app.string.widget_transformer'),
              value: this.data.game.transformerStr === 'true' ? $r('app.string.widget_transformer_ready') : $r('app.string.widget_transformer_cooling'),
              valueColor: this.data.game.transformerStr === 'true' ? $r('app.color.game_color_genshin') : $r('app.color.text_on_dark_muted')
            })
          }
        }
        .width(theme.full)
        .layoutWeight(1)
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding({ top: theme.value8, bottom: theme.value8 })
        .border({ width: { bottom: 1 }, color: $r('app.color.surface_inactive_border') })

        // ── 区块4：探索派遣格子（flex:1，原神）──
        WidgetExpeditions({
          expeditionMax: this.data.game.expeditionMaxStr,
          expeditionFinishedCount: this.data.game.expeditionFinishedStr
        })
          .layoutWeight(1)
          .padding({ top: theme.value8, bottom: theme.value8 })

      } else if (this.data.game.gameId === WIDGET_GAME_ID.STARRAIL) {
        // ── 星铁：数据行前半（flex:1）：每日实训 + 历战余响 ──
        Column() {
          if (parseInt(this.data.game.trainStr) >= 0) {
            DataRow({ label: $r('app.string.widget_train_score'), value: this.data.game.trainStr + '/' + this.data.game.trainMaxStr, valueColor: $r('app.color.accent_refine') })
          }
          if (parseInt(this.data.game.cocoonStr) >= 0) {
            DataRow({ label: $r('app.string.widget_cocoon'), value: this.data.game.cocoonStr + '/' + this.data.game.cocoonLimitStr, valueColor: $r('app.color.accent_refine') })
          }
        }
        .width(theme.full)
        .layoutWeight(1)
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding({ top: theme.value8, bottom: theme.value8 })
        .border({ width: { bottom: 1 }, color: $r('app.color.surface_inactive_border') })

        // ── 星铁：数据行后半（flex:1）：货币战争 ──
        Column() {
          if (parseInt(this.data.game.rogueStr) >= 0) {
            DataRow({ label: $r('app.string.widget_rogue_weekly'), value: this.data.game.rogueStr + '/' + this.data.game.rogueMaxStr, valueColor: $r('app.color.game_color_zzz') })
          }
        }
        .width(theme.full)
        .layoutWeight(1)
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding({ top: theme.value8, bottom: theme.value8 })

      } else if (this.data.game.gameId === WIDGET_GAME_ID.ZZZ) {
        // ── 绝区零：数据行前半（flex:1）──
        Column() {
          if (parseInt(this.data.game.vitalityStr) >= 0) {
            DataRow({ label: $r('app.string.widget_vitality'), value: this.data.game.vitalityStr + '/' + this.data.game.vitalityMaxStr, valueColor: $r('app.color.game_color_zzz') })
          }
          if (this.data.game.cardSign.length > 0) {
            DataRow({
              label: $r('app.string.widget_card_sign'),
              value: this.data.game.cardSign !== 'CardSignNo' ? $r('app.string.widget_card_done') : $r('app.string.widget_card_not_done'),
              valueColor: this.data.game.cardSign !== 'CardSignNo' ? $r('app.color.text_on_dark_high') : $r('app.color.text_on_dark_muted')
            })
          }
        }
        .width(theme.full)
        .layoutWeight(1)
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding({ top: theme.value8, bottom: theme.value8 })
        .border({ width: { bottom: 1 }, color: $r('app.color.surface_inactive_border') })

        // ── 绝区零：数据行后半（flex:1）──
        Column() {
          if (this.data.game.videoStore.length > 0) {
            DataRow({
              label: $r('app.string.widget_video_store'),
              value: this.data.game.videoStore === 'SaleStateDoing' ? $r('app.string.widget_store_open') : $r('app.string.widget_store_closed'),
              valueColor: this.data.game.videoStore === 'SaleStateDoing' ? $r('app.color.accent_refine') : $r('app.color.text_on_dark_muted')
            })
          }
        }
        .width(theme.full)
        .layoutWeight(1)
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding({ top: theme.value8, bottom: theme.value8 })
      }
    }
    .width(theme.full)
    .height(theme.full)
    .alignItems(HorizontalAlign.Start)
  }
}

@Preview
@Component
struct Widget4x4SingleGamePreview {
  build() {
    Column() {
      Widget4x4SingleGame({ data: new WidgetSingleGameData() })
    }
    .padding(12)
    .width(352)
    .height(352)
    .linearGradient({ angle: 135, colors: [['#152030', 0], ['#1c3350', 1]] })
    .borderRadius(16)
  }
}
