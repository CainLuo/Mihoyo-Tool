/**
 * WidgetExpeditions.ets — 原神探索派遣头像行组件
 *
 * 显示最多 5 个派遣格子，已完成的显示 ✓ 标记。
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { DefaultTheme } from '../../theme/DefaultTheme';

/** 主题常量实例 */
const theme = new DefaultTheme();

/** 派遣格子颜色（按索引区分） */
const EXPEDITION_COLORS: ResourceColor[] = [
  $r('app.color.game_color_genshin'),  // 蓝色
  $r('app.color.game_color_starrail'), // 紫色
  $r('app.color.color_danger'),        // 红色
  $r('app.color.color_warning'),       // 黄色
  $r('app.color.game_color_zzz'),      // 绿色
];

@Component
export struct WidgetExpeditions {
  /** 派遣总数 */
  expeditionMax: string = '5';
  /** 已完成的派遣数量 */
  expeditionFinishedCount: string = '0';

  private buildIndices(): number[] {
    const count = parseInt(this.expeditionMax) || 5;
    const result: number[] = [];
    for (let i = 0; i < count; i++) {
      result.push(i);
    }
    return result;
  }

  private isFinished(idx: number): boolean {
    const finishedCount = parseInt(this.expeditionFinishedCount) || 0;
    return idx < finishedCount;
  }

  private getExpeditionColor(idx: number): ResourceColor {
    if (idx < EXPEDITION_COLORS.length) {
      return EXPEDITION_COLORS[idx];
    }
    return $r('app.color.game_color_genshin');
  }

  build() {
    Column({ space: theme.value8 }) {
      Text($r('app.string.widget_expedition'))
        .fontSize(theme.value10)
        .fontColor($r('app.color.gray_500'))
        .letterSpacing(theme.value0)
        .textCase(TextCase.UpperCase)

      Row() {
        ForEach(this.buildIndices(), (_: number, idx: number) => {
          Stack() {
            // 圆形背景（半透明底色 + 彩色边框）
            Circle()
              .width(theme.value36)
              .height(theme.value36)
              .fill($r('app.color.white'))
              .stroke(this.getExpeditionColor(idx))
              .strokeWidth(theme.value2)

            // 头像占位
            Text('👤')
              .fontSize(theme.value14)

            // 完成标记（右下角小圆圈）
            if (this.isFinished(idx)) {
              Text('✓')
                .fontSize(theme.value9)
                .fontColor($r('app.color.white'))
                .fontWeight(FontWeight.Bold)
                .backgroundColor($r('app.color.game_color_zzz'))
                .borderRadius(theme.value8)
                .width(theme.value14)
                .height(theme.value14)
                .textAlign(TextAlign.Center)
                .position({ x: theme.value22, y: theme.value22 })
            }
          }
          .width(theme.value36)
          .height(theme.value36)
          .layoutWeight(1)
        }, (idx: number) => String(idx))
      }
      .width(theme.full)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width(theme.full)
    .layoutWeight(1)
    .padding({ top: theme.value8, bottom: theme.value8 })
    .justifyContent(FlexAlign.Center)
  }
}

@Preview
@Component
struct WidgetExpeditionsPreview {
  build() {
    Column() {
      WidgetExpeditions({
        expeditionMax: '5',
        expeditionFinishedCount: '3'
      })
    }
    .padding(16)
    .width(200)
    .backgroundColor($r('app.color.dark_400'))
  }
}
