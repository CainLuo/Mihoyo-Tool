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
import { parsePayload, ParsedRole, ParsedPayload, Widget2x2UIState, WidgetColors, createWidgetGradient, getGameColor, DefaultTheme, formatUpdatedAtCompactText, isWidgetDataStale } from 'widgetbase';
import { Widget2x2ViewModel } from '../viewmodel/Widget2x2ViewModel';

const theme = new DefaultTheme();

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget2x2 {
  @LocalStorageProp('payload') payloadJson: string = '';

  /**
   * 性能优化：同一 payload 字符串只解析/构建一次。
   * build() 中会多次读取 ParsedPayload / UIState，缓存后避免重复 JSON.parse + ViewModel 计算。
   */
  private cachedPayloadJson: string = '';
  private cachedParsed: ParsedPayload = parsePayload('');
  private cachedUIState: Widget2x2UIState = Widget2x2ViewModel.buildUIState(parsePayload(''));

  /** payload 变化时重建缓存，未变化时直接复用 */
  private ensureCache(): void {
    if (this.cachedPayloadJson === this.payloadJson) {
      return;
    }
    this.cachedPayloadJson = this.payloadJson;
    this.cachedParsed = parsePayload(this.payloadJson);
    this.cachedUIState = Widget2x2ViewModel.buildUIState(this.cachedParsed);
  }

  private getParsed(): ParsedPayload {
    this.ensureCache();
    return this.cachedParsed;
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
    this.ensureCache();
    return this.cachedUIState;
  }

  /** 数据拉取时间（秒），0 表示从未成功拉取 */
  private getUpdatedAt(): number {
    return this.getParsed().updatedAt;
  }

  /** 数据是否已陈旧（超过 1 小时未刷新） */
  private isDataStale(): boolean {
    return isWidgetDataStale(this.getUpdatedAt(), Math.floor(Date.now() / 1000));
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
          Widget2x2SingleGame({
            role: this.getUIState().singleGameState,
            dataUpdatedAt: this.getUpdatedAt()
          })
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

      // 数据新鲜度角标：单游戏由 Widget2x2Header 显示（UID 行右侧）；
      // 多游戏顶部行被游戏名 + UID 占满，只能放右下角，用紧凑文案。
      if (this.getUpdatedAt() > 0 && !this.getIsEmpty() && !this.getIsSingleGame()) {
        Column() {
          Text(formatUpdatedAtCompactText(this.getUpdatedAt(), Math.floor(Date.now() / 1000)))
            .fontSize(theme.font9)
            .fontColor(this.isDataStale() ? WidgetColors.STAMINA_MEDIUM : WidgetColors.WHITE)
            .opacity(this.isDataStale() ? WidgetColors.OPACITY_TEXT_HIGH : WidgetColors.OPACITY_TEXT_GHOST)
            .maxLines(1)
        }
        .width(theme.full)
        .height(theme.full)
        .padding({ top: theme.value6, right: theme.value10, bottom: theme.value6 })
        .alignItems(HorizontalAlign.End)
        .justifyContent(FlexAlign.End)
      }
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
