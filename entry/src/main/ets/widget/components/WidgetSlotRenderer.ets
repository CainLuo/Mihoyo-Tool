/**
 * WidgetSlotRenderer.ets — Widget 单 Slot 渲染组件
 *
 * 根据 ParsedSlotData 渲染单个游戏角色的体力数据。
 * 支持 1x2、2x2、2x4、4x4 四种尺寸，通过 slotSize 参数区分。
 *
 * 布局：
 * - 头部：游戏名 + UID
 * - 体力区块：当前/最大 + 恢复时间
 *   - 星铁特殊：后备开拓力在右侧
 * - 额外数据行（根据游戏类型）
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WIDGET_GAME_ID, gameNameRes, formatRecoveryDesc, gameColorRes } from '../utils/WidgetUtils';
import { ParsedSlotData, WidgetGenshinData, WidgetStarRailData, WidgetZZZData } from '../utils/WidgetSlotDataParser';
import { DefaultTheme } from '../../theme/DefaultTheme';

/** 主题常量实例 */
const theme = new DefaultTheme();

/** Slot 尺寸枚举 */
export enum WidgetSlotSize {
  SIZE_1x2,
  SIZE_2x2,
  SIZE_2x4,
  SIZE_4x4,
}

/** 额外数据行 */
class ExtraRow {
  label: string = '';
  value: string = '';
  color: ResourceColor = $r('app.color.gray_300');
}

@Component
export struct WidgetSlotRenderer {

  @Prop data: ParsedSlotData = new ParsedSlotData();
  slotSize: WidgetSlotSize = WidgetSlotSize.SIZE_2x2;

  /** 体力是否已满 */
  private get isFull(): boolean {
    return this.data.recoverySeconds <= 0 && this.data.currentStamina >= this.data.maxStamina;
  }

  /** 体力进度比例 0~1 */
  private get ratio(): number {
    const m = this.data.maxStamina;
    return m > 0 ? Math.min(this.data.currentStamina / m, 1) : 0;
  }

  /** 游戏主题色 */
  private get gameColor(): ResourceColor {
    return gameColorRes(this.data.gameId, this.isFull);
  }

  /** 当前体力颜色 */
  private get staminaColor(): ResourceColor {
    if (this.ratio <= 0.3) {
      return $r('app.color.color_danger');
    }
    if (this.ratio <= 0.7) {
      return $r('app.color.color_warning');
    }
    return this.gameColor;
  }

  /** 是否为迷你尺寸（1x2） */
  private get isMini(): boolean {
    return this.slotSize === WidgetSlotSize.SIZE_1x2;
  }

  /** 额外数据行 */
  private get extraRows(): ExtraRow[] {
    const rows: ExtraRow[] = [];

    if (this.data.gameId === WIDGET_GAME_ID.GENSHIN && this.data.genshin) {
      const g = this.data.genshin;
      if (g.maxExpeditionNum > 0) {
        rows.push({
          label: '探索派遣',
          value: `${g.currentExpeditionNum}/${g.maxExpeditionNum}`,
          color: $r('app.color.game_color_starrail'),
        });
      }
      if (g.maxHomeCoin > 0) {
        rows.push({
          label: '洞天财瓮',
          value: `${g.currentHomeCoin}/${g.maxHomeCoin}`,
          color: $r('app.color.color_warning'),
        });
      }
    } else if (this.data.gameId === WIDGET_GAME_ID.STARRAIL && this.data.starrail) {
      const s = this.data.starrail;
      if (s.maxTrainScore > 0) {
        rows.push({
          label: '每日实训',
          value: `${s.currentTrainScore}/${s.maxTrainScore}`,
          color: $r('app.color.color_warning'),
        });
      }
      if (s.weeklyCocoonLimit > 0) {
        rows.push({
          label: '历战余响',
          value: `${s.weeklyCocoonCnt}/${s.weeklyCocoonLimit}`,
          color: $r('app.color.color_warning'),
        });
      }
    } else if (this.data.gameId === WIDGET_GAME_ID.ZZZ && this.data.zzz) {
      const z = this.data.zzz;
      if (z.maxVitality > 0) {
        rows.push({
          label: '今日活跃度',
          value: `${z.currentVitality}/${z.maxVitality}`,
          color: $r('app.color.game_color_zzz'),
        });
      }
      if (z.cardSign.length > 0) {
        rows.push({
          label: '刮刮卡',
          value: z.cardSign === 'CardSignDone' ? '已完成' : '未完成',
          color: z.cardSign === 'CardSignDone' ? $r('app.color.color_success') : $r('app.color.gray_500'),
        });
      }
    }

    return this.isMini ? rows.slice(0, 1) : rows.slice(0, 2);
  }

  /** 后备开拓力（星铁专用） */
  private get reserveStamina(): string {
    if (this.data.starrail) {
      return String(this.data.starrail.currentReserveStamina);
    }
    return '0';
  }

  build() {
    if (this.isMini) {
      this.buildMiniLayout()
    } else {
      this.buildStandardLayout()
    }
  }

  /** 迷你布局（1x2） */
  @Builder
  private buildMiniLayout(): void {
    Row({ space: theme.value8 }) {
      // 左侧：游戏色竖线装饰条
      Stack() {
        Column()
          .width(theme.value3)
          .borderRadius(theme.value2)
          .backgroundColor(this.gameColor)
          .height(theme.full)
      }
      .width(theme.value3)
      .height(theme.full)
      .padding({ top: theme.value8, bottom: theme.value8 })
      .alignContent(Alignment.Center)
      .flexShrink(0)

      // 右侧：游戏名+UID + 体力
      Column() {
        Row({ space: theme.value4 }) {
          Text(gameNameRes(this.data.gameId))
            .fontSize(theme.value10)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.gray_400'))

          Text('UID ' + this.data.roleId)
            .fontSize(theme.value9)
            .fontColor($r('app.color.gray_500'))
        }

        Row({ space: theme.value2 }) {
          Text(String(this.data.currentStamina))
            .fontSize(theme.value18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.staminaColor)

          Text('/' + String(this.data.maxStamina))
            .fontSize(theme.value18)
            .fontColor($r('app.color.gray_500'))
        }
        .alignItems(VerticalAlign.Bottom)

        Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(String(this.data.recoverySeconds)))
          .fontSize(theme.value10)
          .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.gray_600'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
    }
    .width(theme.full)
    .height(theme.full)
    .alignItems(VerticalAlign.Center)
  }

  /** 标准布局（2x2/2x4/4x4） */
  @Builder
  private buildStandardLayout(): void {
    Column() {
      // 头部：游戏名 + UID
      Column({ space: theme.value1 }) {
        Text(gameNameRes(this.data.gameId))
          .fontSize(theme.value12)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.white'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text('UID ' + this.data.roleId)
          .fontSize(theme.value10)
          .fontColor($r('app.color.gray_500'))
      }
      .width(theme.full)
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: theme.value8 })

      // 体力区块
      if (this.data.gameId === WIDGET_GAME_ID.STARRAIL) {
        // 星铁特殊布局：左侧体力 + 右侧后备开拓力
        Row() {
          Column({ space: theme.value2 }) {
            Row({ space: theme.value3 }) {
              Text(String(this.data.currentStamina))
                .fontSize(theme.value24)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.staminaColor)

              Text('/' + String(this.data.maxStamina))
                .fontSize(theme.value14)
                .fontColor($r('app.color.gray_500'))
            }
            .alignItems(VerticalAlign.Bottom)

            Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(String(this.data.recoverySeconds)))
              .fontSize(theme.value11)
              .fontColor($r('app.color.gray_400'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 右侧：后备开拓力
          Column({ space: theme.value1 }) {
            Text($r('app.string.widget_reserve_prefix'))
              .fontSize(theme.value9)
              .fontColor($r('app.color.gray_500'))

            Text(this.reserveStamina)
              .fontSize(theme.value12)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.gameColor)
          }
          .alignItems(HorizontalAlign.End)
        }
        .width(theme.full)
        .alignItems(VerticalAlign.Top)
        .margin({ bottom: theme.value8 })
      } else {
        // 原神/绝区零：标准布局
        Column({ space: theme.value2 }) {
          Row({ space: theme.value3 }) {
            Text(String(this.data.currentStamina))
              .fontSize(theme.value24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.staminaColor)

            Text('/' + String(this.data.maxStamina))
              .fontSize(theme.value14)
              .fontColor($r('app.color.gray_500'))
          }
          .alignItems(VerticalAlign.Bottom)

          Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(String(this.data.recoverySeconds)))
            .fontSize(theme.value11)
            .fontColor($r('app.color.gray_400'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width(theme.full)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: theme.value8 })
      }

      // 底部：额外数据行
      Column({ space: theme.value5 }) {
        ForEach(this.extraRows, (row: ExtraRow, idx: number) => {
          Row() {
            Text(row.label)
              .fontSize(theme.value11)
              .fontColor($r('app.color.gray_600'))
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(row.value)
              .fontSize(theme.value11)
              .fontWeight(FontWeight.Bold)
              .fontColor(row.color)
          }
          .width(theme.full)
        })
      }
      .width(theme.full)
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width(theme.full)
    .height(theme.full)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }
}

@Preview
@Component
struct WidgetSlotRendererPreview {
  build() {
    Column({ space: 12 }) {
      // 2x2 预览
      WidgetSlotRenderer({
        data: new ParsedSlotData(),
        slotSize: WidgetSlotSize.SIZE_2x2,
      })
        .width(168)
        .height(168)
        .padding(12)
        .linearGradient({ angle: 135, colors: [[$r('app.color.widget_bg_genshin_1'), 0], [$r('app.color.widget_bg_genshin_3'), 1]] })
        .borderRadius(16)

      // 1x2 预览
      WidgetSlotRenderer({
        data: new ParsedSlotData(),
        slotSize: WidgetSlotSize.SIZE_1x2,
      })
        .width(168)
        .height(80)
        .padding(12)
        .linearGradient({ angle: 135, colors: [[$r('app.color.widget_bg_genshin_1'), 0], [$r('app.color.widget_bg_genshin_3'), 1]] })
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
