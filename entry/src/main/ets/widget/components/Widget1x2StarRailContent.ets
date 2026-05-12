/**
 * Widget1x2StarRailContent.ets — 星铁 1×2 迷你卡片专用组件
 *
 * 星铁布局（游戏名较长）：
 * - 左侧：游戏色竖线装饰条（3vp 宽，上下 8px padding）
 * - 中间：游戏名 + UID + 恢复时间（纵向三行）
 * - 右侧：当前值（上）+ Divider + 最大值（下）
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 * 不能使用 @ObservedV2/@Trace 装饰的类。
 */

import { calcIsFull, calcRatio, formatRecoveryDesc, parseCurrent, parseMax } from '../utils/WidgetUtils';
import { WidgetSingleGameData } from '../models/WidgetModels';

@Component
export struct Widget1x2StarRailContent {
  @Prop data: WidgetSingleGameData = new WidgetSingleGameData();
  gameColor: ResourceColor = $r('app.color.game_color_starrail');

  /** 体力是否已满 */
  private get isFull(): boolean {
    return calcIsFull(this.data.game.currentStr, this.data.game.maxStr, this.data.game.secondsStr);
  }

  /** 体力进度比例 0~1 */
  private get ratio(): number {
    return calcRatio(this.data.game.currentStr, this.data.game.maxStr);
  }

  /**
   * 当前体力颜色：根据比例从红色到游戏主题色
   * 0-30%：红色
   * 30-70%：橙色
   * 70-100%：游戏主题色
   */
  private get staminaColor(): ResourceColor {
    if (this.ratio <= 0.3) {
      return $r('app.color.color_danger');
    }
    if (this.ratio <= 0.7) {
      return $r('app.color.color_warning');
    }
    return this.gameColor;
  }

  build() {
    Row({ space: 8 }) {
      // 左侧：游戏色竖线装饰条（3vp 宽，上下 8px padding）
      Stack() {
        Column()
          .width(3)
          .borderRadius(2)
          .backgroundColor(this.gameColor)
          .height('100%')
      }
      .width(3)
      .height('100%')
      .padding({ top: 8, bottom: 8 })
      .alignContent(Alignment.Center)
      .flexShrink(0)

      // 中间：游戏名 + UID + 恢复时间
      Column({ space: 2 }) {
        Text($r('app.string.game_name_starrail'))
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_on_dark_secondary'))

        Text('UID ' + this.data.accountUid)
          .fontSize(9)
          .fontColor($r('app.color.text_on_dark_muted'))

        Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.data.game.secondsStr))
          .fontSize(10)
          .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)

      // 右侧：当前值 + Divider + 最大值
      Column() {
        Text(String(parseCurrent(this.data.game.currentStr)))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.staminaColor)

        Divider()
          .width(20)
          .height(1)
          .color($r('app.color.text_on_dark_muted'))

        Text(String(parseMax(this.data.game.maxStr)))
          .fontSize(12)
          .fontColor($r('app.color.text_on_dark_muted'))
      }
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.Center)
      .flexShrink(0)
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Center)
  }
}

@Preview
@Component
struct Widget1x2StarRailContentPreview {
  build() {
    Column({ space: 8 }) {
      Widget1x2StarRailContent({
        data: new WidgetSingleGameData(),
        gameColor: $r('app.color.game_color_starrail')
      })
        .width(168)
        .height(56)
        .padding(12)
        .linearGradient({ angle: 135, colors: [[$r('app.color.widget_bg_starrail_dark'), 0], [$r('app.color.widget_bg_starrail_light'), 1]] })
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor($r('app.color.widget_preview_bg'))
  }
}
