/**
 * Widget2x2.ets - 2x2 standard card entry
 *
 * v1.5 design:
 * - Use ViewModel pattern for data transformation
 * - Single game: detailed layout with extra rows
 * - Multi game: two Widget1x2ContentView stacked vertically with Divider
 */

import { Widget2x2SingleGame } from '../views/Widget2x2SingleGame';
import { Widget1x2ContentView } from '../views/Widget1x2ContentView';
import { WidgetEmptyContent } from '../views/WidgetEmptyContent';
import { parsePayload, ParsedRole, ParsedPayload, Widget2x2UIState, WidgetColors, createWidgetGradient, getGameColor, DefaultTheme } from 'widgetbase';
import { Widget2x2ViewModel } from '../viewmodel/Widget2x2ViewModel';

const theme = new DefaultTheme();

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget2x2 {
  @LocalStorageProp('payload') payloadJson: string = '';

  private getParsed(): ParsedPayload {
    return parsePayload(this.payloadJson);
  }

  private getAllRoles(): ParsedRole[] {
    return this.getParsed().getAllRoles();
  }

  private getIsSingleGame(): boolean {
    return this.getParsed().isSingleGame;
  }

  private getGameIds(): string[] {
    return this.getParsed().getUniqueGameIds();
  }

  private getIsEmpty(): boolean {
    return this.getAllRoles().length === 0;
  }

  private getUIState(): Widget2x2UIState {
    return Widget2x2ViewModel.buildUIState(this.getParsed());
  }

  build() {
    Stack() {
      Column()
        .width(theme.full)
        .height(theme.full)
        .linearGradient(createWidgetGradient(this.getGameIds()))
        .borderRadius(theme.radius16)

      Column() {
        if (this.getIsEmpty()) {
          WidgetEmptyContent()
        } else if (this.getIsSingleGame()) {
          Widget2x2SingleGame({ role: this.getUIState().singleGameState })
        } else {
          // 多游戏模式：两个 Widget1x2ContentView + Divider
          Column() {
            // 第一个游戏
            Widget1x2ContentView({
              state: this.getUIState().multiGameStates[0],
              gameColor: getGameColor(this.getUIState().multiGameStates[0].gameId)
            })
              .layoutWeight(1)

            if (this.getUIState().multiGameStates.length >= 2) {
              // 分隔线
              Divider()
                .color(WidgetColors.WHITE)
                .opacity(0.3)
                .strokeWidth(1)
                .margin({ top: theme.value4, bottom: theme.value4 })

              // 第二个游戏
              Widget1x2ContentView({
                state: this.getUIState().multiGameStates[1],
                gameColor: getGameColor(this.getUIState().multiGameStates[1].gameId)
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
    .accessibilityText($r('app.string.a11y_widget_card'))
    .onClick(() => {
      postCardAction(this, {
        action: 'call',
        abilityName: 'WidgetSyncAbility',
        params: {
          method: 'sync'
        }
      });
    })
  }
}
