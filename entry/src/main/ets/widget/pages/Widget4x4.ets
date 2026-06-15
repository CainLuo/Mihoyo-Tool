/**
 * Widget4x4.ets — 4×4 大卡片入口
 *
 * v1.2 design:
 * - Use ViewModel pattern for data transformation
 * - Single game: Widget4x4SingleGame (详细布局，体力区块 + 数据行分组 + 派遣头像)
 * - Multi game (2): two Widget2x4SingleGame vertically + Divider
 *
 * 数据流：
 *   payload JSON → parsePayload() → ParsedPayload (Model) → ViewModel.buildUIState() → UIState (View)
 */

import { Widget4x4SingleGame } from '../components/Widget4x4SingleGame';
import { Widget2x4SingleGame } from '../components/Widget2x4SingleGame';
import { parsePayload, ParsedPayload } from '../utils/WidgetPayloadParser';
import { Widget4x4UIState, WidgetColors } from '../models/WidgetUIStates';
import { widgetGradient } from '../utils/WidgetUtils';
import { Widget4x4ViewModel } from '../viewmodel/Widget4x4ViewModel';
import { DefaultTheme } from '../../theme/DefaultTheme';

/** 主题常量实例 */
const theme = new DefaultTheme();

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget4x4 {
  @LocalStorageProp('payload') payloadJson: string = '';

  private getParsed(): ParsedPayload {
    return parsePayload(this.payloadJson);
  }

  private getGameIds(): string[] {
    return this.getParsed().getUniqueGameIds();
  }

  private getUIState(): Widget4x4UIState {
    return Widget4x4ViewModel.buildUIState(this.getParsed());
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
          // 单游戏模式：详细布局（使用 4x4 专用组件）
          Widget4x4SingleGame({ role: this.getUIState().singleGameState })
        } else {
          // 多游戏模式：两个 Widget2x4SingleGame + 分隔线 纵向排列
          Column() {
            // 第一个游戏
            Widget2x4SingleGame({ 
              role: this.getUIState().multiGameStates[0],
              inNestedContainer: true 
            })
              .layoutWeight(1)

            // 分隔线（用 Row 替代 Divider，Widget 可能不支持 Divider）
            if (this.getUIState().multiGameStates.length >= 2) {
              Row()
                .width('100%')
                .height(1)
                .backgroundColor(WidgetColors.WHITE)
                .opacity(0.1)
                .margin({ top: theme.value4, bottom: theme.value4 })

              // 第二个游戏
              Widget2x4SingleGame({ 
                role: this.getUIState().multiGameStates[1],
                inNestedContainer: true 
              })
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
