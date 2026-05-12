/**
 * WidgetStaminaRing.ets — Widget 体力环组件
 *
 * 环形进度条 + 中心数值，支持不同尺寸。
 * 业务数据通过 WidgetGameData 传入，渲染参数（尺寸/字体）单独配置。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { calcIsFull, calcRatio, gameColorRes, parseCurrent, parseMax } from '../utils/WidgetUtils';
import { WidgetGameData } from '../models/WidgetModels';
import { widgetTheme } from '../utils/WidgetTheme';

@Component
export struct WidgetStaminaRing {
  @Prop game: WidgetGameData = new WidgetGameData();
  /** 游戏主题色（Resource 类型无法放进 model，由调用方传入） */
  gameColor: ResourceColor = $r('app.color.game_color_genshin');
  /** 环的直径（vp） */
  ringSize: number = 80;
  /** 环的线宽（vp） */
  strokeWidth: number = 8;
  /** 中心数值字体大小 */
  valueFontSize: number = 24;
  /** 分母字体大小 */
  maxFontSize: number = 13;
  /** 是否在环中心显示数值，默认 true */
  showValue: boolean = true;

  private get isFull(): boolean {
    return calcIsFull(this.game.currentStr, this.game.maxStr, this.game.secondsStr);
  }

  private get ratio(): number {
    return calcRatio(this.game.currentStr, this.game.maxStr);
  }

  private get displayColor(): ResourceColor {
    return this.isFull ? $r('app.color.color_danger') : this.gameColor;
  }

  build() {
    Stack() {
      Progress({ value: this.ratio * 100, total: 100, type: ProgressType.Ring })
        .width(this.ringSize)
        .height(this.ringSize)
        .color(this.displayColor)
        .backgroundColor($r('app.color.surface_inactive_border'))
        .style({ strokeWidth: this.strokeWidth })

      if (this.showValue) {
        Column() {
          Text(String(parseCurrent(this.game.currentStr)))
            .fontSize(this.valueFontSize)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.displayColor)
            .lineHeight(this.valueFontSize + widgetTheme.value4)

          Text('/' + String(parseMax(this.game.maxStr)))
            .fontSize(this.maxFontSize)
            .fontColor($r('app.color.text_on_dark_muted'))
        }
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width(this.ringSize)
    .height(this.ringSize)
  }
}

@Preview
@Component
struct WidgetStaminaRingPreview {
  build() {
    Row({ space: 16 }) {
      WidgetStaminaRing({
        game: new WidgetGameData(),
        gameColor: $r('app.color.game_color_genshin'),
        ringSize: 80,
        strokeWidth: 8,
        valueFontSize: 24,
        maxFontSize: 13
      })

      WidgetStaminaRing({
        game: new WidgetGameData(),
        gameColor: $r('app.color.game_color_starrail'),
        ringSize: 56,
        strokeWidth: 5,
        valueFontSize: 18,
        maxFontSize: 11
      })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
