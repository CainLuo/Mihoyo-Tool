/**
 * Widget1x2Content.ets — 1×2 迷你卡片通用内容组件（原神/绝区零）
 *
 * 严格按原型 wr-1x2.js 实现：
 * - 左侧：游戏色竖线（3vp 宽，充满内容高度，圆角，上下 8px padding）
 * - 第一行：游戏名（10px）+ UID（9px）同一行
 * - 第二行：当前体力（18px Bold）+ "/" + 最大体力（18px）
 * - 第三行：恢复时间（10px）
 * - 体力颜色：0-30% 红色，30-70% 橙色，70-100% 游戏主题色
 *
 * 注意：星铁使用独立组件 Widget1x2StarRailContent.ets
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 * 不能使用 @ObservedV2/@Trace 装饰的类。
 */

import { calcIsFull, calcRatio, formatRecoveryDesc, gameNameRes, parseCurrent, parseMax } from '../utils/WidgetUtils';
import { WidgetSingleGameData } from '../models/WidgetModels';

@Component
export struct Widget1x2Content {
  @Prop data: WidgetSingleGameData = new WidgetSingleGameData();
  gameColor: ResourceColor = $r('app.color.game_color_genshin');

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

      // 右侧：游戏名+UID + 体力 + 恢复时间
      Column() {
        // 第一行：游戏名 + UID
        Row({ space: 4 }) {
          Text(gameNameRes(this.data.game.gameId))
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_on_dark_secondary'))

          Text('UID ' + this.data.accountUid)
            .fontSize(9)
            .fontColor($r('app.color.text_on_dark_muted'))
        }

        // 第二行：当前体力 / 最大体力
        Row({ space: 2 }) {
          Text(String(parseCurrent(this.data.game.currentStr)))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.staminaColor)

          Text('/' + String(parseMax(this.data.game.maxStr)))
            .fontSize(18)
            .fontColor($r('app.color.text_on_dark_muted'))
        }
        .alignItems(VerticalAlign.Bottom)

        // 第三行：恢复时间
        Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.data.game.secondsStr))
          .fontSize(10)
          .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .alignItems(VerticalAlign.Center)
  }
}

@Preview
@Component
struct Widget1x2ContentPreview {
  build() {
    Column({ space: 8 }) {
      Widget1x2Content({
        data: new WidgetSingleGameData(),
        gameColor: $r('app.color.game_color_genshin')
      })
        .width(168)
        .height(56)
        .padding(12)
        .linearGradient({ angle: 135, colors: [[$r('app.color.widget_bg_genshin_dark'), 0], [$r('app.color.widget_bg_genshin_light'), 1]] })
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor($r('app.color.widget_preview_bg'))
  }
}
