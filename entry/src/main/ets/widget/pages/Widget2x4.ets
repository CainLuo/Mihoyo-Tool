/**
 * Widget2x4.ets — 2×4 宽幅卡片入口
 *
 * v1.3 design:
 * - Use ViewModel pattern for data transformation
 * - Single game: horizontal layout (ring + data rows) — Widget2x4SingleGame
 * - Multi game (2): two Widget2x2SingleGame horizontally + Divider
 *
 * 数据流：
 *   payload JSON → parsePayload() → ParsedPayload (Model) → ViewModel.buildUIState() → UIState (View)
 */

import { Widget2x4SingleGame } from '../components/Widget2x4SingleGame';
import { Widget2x2SingleGame } from '../components/Widget2x2SingleGame';
import { parsePayload, ParsedPayload } from '../utils/WidgetPayloadParser';
import { Widget2x4UIState, WidgetColors } from '../models/WidgetUIStates';
import { widgetGradient } from '../utils/WidgetUtils';
import { Widget2x4ViewModel } from '../viewmodel/Widget2x4ViewModel';
import { DefaultTheme } from '../../theme/DefaultTheme';

/** 主题常量实例 */
const theme = new DefaultTheme();

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget2x4 {
  @LocalStorageProp('payload') payloadJson: string = '';

  private getParsed(): ParsedPayload {
    return parsePayload(this.payloadJson);
  }

  private getGameIds(): string[] {
    return this.getParsed().getUniqueGameIds();
  }

  private getUIState(): Widget2x4UIState {
    return Widget2x4ViewModel.buildUIState(this.getParsed());
  }

  build() {
    Stack() {
      // Background layer with gradient
      Column()
        .width(theme.full)
        .height(theme.full)
        .linearGradient(widgetGradient(this.getGameIds()))
        .borderRadius(theme.radius16)

      // Content layer
      Column() {
        if (this.getUIState().isEmpty) {
          // 空态
          Column() {
            Text($r('app.string.widget_no_account'))
              .fontSize(theme.font13)
              .fontColor(WidgetColors.WHITE)
              .opacity(0.6)
              .textAlign(TextAlign.Center)
          }
          .width(theme.full)
          .height(theme.full)
          .justifyContent(FlexAlign.Center)
        } else if (this.getUIState().isSingleGame) {
          // 单游戏模式：水平布局（体力环 + 数据行）
          Widget2x4SingleGame({ role: this.getUIState().singleGameState })
        } else {
          // 多游戏模式：两个 Widget2x2SingleGame + Divider 横向排列
          Row() {
            // 第一个游戏
            Widget2x2SingleGame({ role: this.getUIState().multiGameStates[0] })
              .layoutWeight(1)

            // 分隔线
            if (this.getUIState().multiGameStates.length >= 2) {
              Divider()
                .vertical(true)
                .color(WidgetColors.WHITE)
                .opacity(0.2)
                .strokeWidth(1)
                .height(theme.pct80)
                .margin({ left: theme.value8, right: theme.value8 })

              // 第二个游戏
              Widget2x2SingleGame({ role: this.getUIState().multiGameStates[1] })
                .layoutWeight(1)
            }
          }
          .width(theme.full)
          .height(theme.full)
        }
      }
      .width(theme.full)
      .height(theme.full)
      .padding(theme.value12)
    }
    .width(theme.full)
    .height(theme.full)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { page: 'Main' }
      });
    })
  }
}
