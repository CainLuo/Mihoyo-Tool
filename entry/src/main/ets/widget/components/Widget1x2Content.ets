/**
 * Widget1x2Content.ets — 1×2 迷你卡片通用内容组件
 *
 * 三款游戏的 1×2 卡片共用此组件，差异仅在游戏颜色（Resource 类型无法放进 model）。
 * 布局：左侧体力环（44vp）+ 右侧账号名/恢复描述/后备体力
 *
 * 数据通过 data 字段传入（与 Widget2x2SingleGame 保持一致），
 * 不在子组件里声明 @LocalStorageProp，避免潜在的渲染问题。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetStaminaRing } from './WidgetStaminaRing';
import { calcIsFull, formatRecoveryDesc } from '../utils/WidgetUtils';
import { WidgetSingleGameData } from '../models/WidgetModels';

@Component
export struct Widget1x2Content {
  private tm: ThemeManager = themeManager;

  /** 账号 + 游戏数据，由 @Entry 组件构建后传入 */
  @Prop data: WidgetSingleGameData = new WidgetSingleGameData();

  /** 游戏主题色（Resource 类型无法放进 model，由 @Entry 传入） */
  gameColor: ResourceColor = $r('app.color.game_color_genshin');

  private get displayName(): string {
    return this.data.accountName.length > 0 ? this.data.accountName : this.data.accountUid;
  }

  private get isFull(): boolean {
    return calcIsFull(this.data.game.currentStr, this.data.game.maxStr, this.data.game.secondsStr);
  }

  private get reserveStamina(): number {
    const v = parseInt(this.data.game.reserveStr);
    return isNaN(v) ? -1 : v;
  }

  build() {
    Row({ space: themeManager.current.value10 }) {
      WidgetStaminaRing({
        game: this.data.game,
        gameColor: this.gameColor,
        ringSize: themeManager.current.value44,
        strokeWidth: themeManager.current.value4,
        valueFontSize: themeManager.current.value14,
        maxFontSize: themeManager.current.value11
      })

      Column({ space: themeManager.current.value2 }) {
        Text(this.displayName)
          .fontSize(themeManager.current.value11)
          .fontColor($r('app.color.text_on_dark_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.isFull ? $r('app.string.widget_stamina_full') : formatRecoveryDesc(this.data.game.secondsStr))
          .fontSize(themeManager.current.value11)
          .fontColor(this.isFull ? $r('app.color.color_danger') : $r('app.color.text_on_dark_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.reserveStamina >= 0) {
          Row({ space: themeManager.current.value2 }) {
            Text($r('app.string.widget_reserve_prefix'))
              .fontSize(themeManager.current.value11)
              .fontColor($r('app.color.game_color_starrail'))

            Text(String(this.reserveStamina))
              .fontSize(themeManager.current.value11)
              .fontColor($r('app.color.game_color_starrail'))
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
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
        .height(80)
        .padding(12)
        .backgroundColor('#2E3033')
        .borderRadius(16)

      Widget1x2Content({
        data: new WidgetSingleGameData(),
        gameColor: $r('app.color.game_color_starrail')
      })
        .width(168)
        .height(80)
        .padding(12)
        .backgroundColor('#2E3033')
        .borderRadius(16)
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
