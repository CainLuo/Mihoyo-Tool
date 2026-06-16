/**
 * Preview4x4SingleGame.ets — Widget 配置预览 4x4 单游戏内容
 *
 * 布局与 Widget4x4SingleGame 保持一致：
 * - 顶部标题行：游戏名 + UID
 * - 区块1：体力区块（固定高度）
 * - 区块2：数据行分组1（flex:1）
 * - 区块3：数据行分组2（flex:1）
 * - 区块4：原神派遣（flex:1）
 */

import { GameId } from 'core';
import { WidgetColors, StaminaColorType } from '../../../widget/models/WidgetUIStates';
import { PreviewStaminaData, getPreviewStaminaData } from '../../../models/WidgetPreviewModels';
import { DefaultTheme } from '../../../theme/DefaultTheme';
import { gameIdToWidgetName, staminaColorType, staminaColor, recoveryTimeText } from './WidgetPreviewUtils';

/** 额外数据行 */
class ExtraRow {
  label: ResourceStr = '';
  value: string = '';
  valueColor: ResourceColor = WidgetColors.WHITE;

  constructor(label: ResourceStr, value: string, valueColor: ResourceColor = WidgetColors.WHITE) {
    this.label = label;
    this.value = value;
    this.valueColor = valueColor;
  }
}

/** 获取额外数据行 */
function getExtraRows(gameId: GameId): ExtraRow[] {
  if (gameId === GameId.GENSHIN) {
    return [
      new ExtraRow($r('app.string.widget_home_coin'), '1800/2400'),
      new ExtraRow($r('app.string.widget_daily_task'), '3/4'),
      new ExtraRow($r('app.string.widget_transformer'), '已就绪', WidgetColors.SUCCESS),
    ];
  } else if (gameId === GameId.STARRAIL) {
    return [
      new ExtraRow($r('app.string.widget_reserve_stamina'), '2400'),
      new ExtraRow($r('app.string.widget_train_score'), '400/500'),
      new ExtraRow($r('app.string.widget_rogue_weekly'), '800/1000'),
      new ExtraRow($r('app.string.widget_grid_fight'), '1/3'),
    ];
  } else if (gameId === GameId.ZZZ) {
    return [
      new ExtraRow($r('app.string.widget_video_store'), '营业中', WidgetColors.SUCCESS),
      new ExtraRow($r('app.string.widget_card_sign'), '已完成', WidgetColors.SUCCESS),
      new ExtraRow('刮刮卡', '已完成', WidgetColors.SUCCESS),
    ];
  }
  return [];
}

@ComponentV2
export struct Preview4x4SingleGame {
  @Param gameId: GameId = GameId.GENSHIN;
  @Param roleId: string = '';

  @Local theme: DefaultTheme = new DefaultTheme();

  private get staminaData(): PreviewStaminaData {
    return getPreviewStaminaData(this.gameId);
  }

  private get staminaRatio(): number {
    return this.staminaData.max > 0 ? this.staminaData.cur / this.staminaData.max : 0;
  }

  private get extraRows(): ExtraRow[] {
    return getExtraRows(this.gameId);
  }

  private get group1(): ExtraRow[] {
    const half = Math.ceil(this.extraRows.length / 2);
    return this.extraRows.slice(0, half);
  }

  private get group2(): ExtraRow[] {
    const half = Math.ceil(this.extraRows.length / 2);
    return this.extraRows.slice(half);
  }

  private get staminaLabel(): string {
    if (this.gameId === GameId.STARRAIL) {
      return '开拓力';
    } else if (this.gameId === GameId.ZZZ) {
      return '电量';
    }
    return '原粹树脂';
  }

  build() {
    Column() {
      // ── 顶部标题行（固定高度）──
      Row() {
        Row()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor(staminaColor(staminaColorType(this.staminaRatio), this.gameId))

        Text(gameIdToWidgetName(this.gameId))
          .fontSize(14)
          .fontWeight(700)
          .fontColor(WidgetColors.WHITE)
          .opacity(0.95)
          .layoutWeight(1)
          .margin({ left: 6 })

        Text($r('app.string.widget_uid_prefix', this.roleId))
          .fontSize(10)
          .fontColor(WidgetColors.WHITE)
          .opacity(0.35)
      }
      .width('100%')
      .padding({ bottom: 8 })

      // ── 区块1：体力区块（固定高度）──
      Column() {
        Text(this.staminaLabel)
          .fontSize(10)
          .fontColor(WidgetColors.WHITE)
          .opacity(0.3)
          .margin({ bottom: 4 })

        Row() {
          Text(String(this.staminaData.cur))
            .fontSize(40)
            .fontWeight(700)
            .fontColor(staminaColor(staminaColorType(this.staminaRatio), this.gameId))

          Text('/ ' + String(this.staminaData.max))
            .fontSize(14)
            .fontColor(WidgetColors.WHITE)
            .opacity(0.3)
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Bottom)
        .margin({ bottom: 3 })

        Text(recoveryTimeText(this.staminaData))
          .fontSize(12)
          .fontColor(WidgetColors.WHITE)
          .opacity(0.5)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 8, bottom: 8 })
      .border({ width: { bottom: 1 }, color: 'rgba(255,255,255,0.1)' })

      // ── 区块2：数据行分组1（flex:1）──
      if (this.group1.length > 0) {
        Column() {
          ForEach(this.group1, (row: ExtraRow) => {
            Row() {
              Text(row.label)
                .fontSize(12)
                .fontColor(WidgetColors.WHITE)
                .opacity(0.45)
                .layoutWeight(1)

              Text(row.value)
                .fontSize(12)
                .fontWeight(600)
                .fontColor(row.valueColor)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 4, bottom: 4 })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 6, bottom: 6 })
        .border({ width: { bottom: this.group2.length > 0 ? 1 : 0 }, color: 'rgba(255,255,255,0.1)' })
      }

      // ── 区块3：数据行分组2（flex:1）──
      if (this.group2.length > 0) {
        Column() {
          ForEach(this.group2, (row: ExtraRow) => {
            Row() {
              Text(row.label)
                .fontSize(12)
                .fontColor(WidgetColors.WHITE)
                .opacity(0.45)
                .layoutWeight(1)

              Text(row.value)
                .fontSize(12)
                .fontWeight(600)
                .fontColor(row.valueColor)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top: 4, bottom: 4 })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 6, bottom: 6 })
        .border({ width: { bottom: this.gameId === GameId.GENSHIN ? 1 : 0 }, color: 'rgba(255,255,255,0.1)' })
      }

      // ── 区块4：原神派遣（flex:1）──
      if (this.gameId === GameId.GENSHIN) {
        Column() {
          Text('探索派遣')
            .fontSize(10)
            .fontColor(WidgetColors.WHITE)
            .opacity(0.3)
            .margin({ bottom: 6 })

          Row() {
            ForEach([0, 1, 2, 3], (idx: number) => {
              Row()
                .width(32)
                .height(32)
                .borderRadius(16)
                .linearGradient({
                  angle: 135,
                  colors: [['rgba(100,100,120,0.8)', 0], ['rgba(60,60,80,0.8)', 1]]
                })
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceEvenly)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 6, bottom: 6 })
      }
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
