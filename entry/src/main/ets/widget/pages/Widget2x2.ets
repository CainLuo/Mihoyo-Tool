/**
 * Widget2x2.ets - 2x2 standard card entry
 *
 * v1.5 design:
 * - Use ViewModel pattern for data transformation
 * - Single game (by game type count): detailed layout with extra rows (expedition, home coin, etc.)
 * - Multi game (multiple game types): compact layout showing stamina only
 * - @Builder methods extracted to independent components
 *
 * 数据流：
 *   payload JSON → parsePayload() → ParsedPayload (Model) → ViewModel.buildUIState() → UIState (View)
 */

import { Widget2x2SingleGame } from '../components/Widget2x2SingleGame';
import { WidgetMultiGameCompact } from '../components/WidgetMultiGameCompact';
import { WidgetEmptyContent, WidgetDebugContent } from '../components/WidgetEmptyContent';
import { parsePayload, ParsedRole, ParsedPayload } from '../utils/WidgetPayloadParser';
import { Widget2x2UIState } from '../models/WidgetUIStates';
import { widgetGradient } from '../utils/WidgetUtils';
import { Widget2x2ViewModel } from '../viewmodel/Widget2x2ViewModel';
import { DefaultTheme } from '../../theme/DefaultTheme';

/** 默认主题实例 */
const theme = new DefaultTheme();

/** 调试开关：true = 显示调试信息 */
const DEBUG_MODE: boolean = false;

let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct Widget2x2 {
  @LocalStorageProp('payload') payloadJson: string = '';

  /** 获取解析后的 Payload 对象 (Model 层) */
  private getParsed(): ParsedPayload {
    return parsePayload(this.payloadJson);
  }

  /** 获取所有角色 */
  private getAllRoles(): ParsedRole[] {
    return this.getParsed().getAllRoles();
  }

  /** 是否为单一游戏 */
  private getIsSingleGame(): boolean {
    return this.getParsed().isSingleGame;
  }

  /** 获取游戏 ID 列表 */
  private getGameIds(): string[] {
    return this.getParsed().getUniqueGameIds();
  }

  /** 是否为空数据 */
  private getIsEmpty(): boolean {
    return this.getAllRoles().length === 0;
  }

  /** 构建 UIState（在组件方法中调用 ViewModel） */
  private getUIState(): Widget2x2UIState {
    return Widget2x2ViewModel.buildUIState(this.getParsed());
  }

  /** 构建调试信息字符串 */
  private buildDebugInfo(): string {
    const uiState = this.getUIState();
    
    let info = `roles=${this.getAllRoles().length}\n`;
    info += `isSingle=${this.getIsSingleGame()}\n`;
    info += `gameCount=${uiState.multiGameState.gameCount}\n`;
    info += `games.length=${uiState.multiGameState.games.length}\n`;
    
    // 显示 WidgetGameData 的 gameId
    for (let i = 0; i < uiState.multiGameState.games.length && i < 2; i++) {
      info += `game[${i}].gameId=${uiState.multiGameState.games[i].gameId}\n`;
      info += `game[${i}].current=${uiState.multiGameState.games[i].currentStr}\n`;
    }
    
    return info;
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
        // 调试模式：显示调试信息
        if (DEBUG_MODE) {
          WidgetDebugContent({ 
            debugInfo: this.buildDebugInfo() 
          })
        } else if (this.getIsEmpty()) {
          WidgetEmptyContent()
        } else if (this.getIsSingleGame()) {
          // 单游戏模式：使用 ViewModel 提供的 UIState
          Widget2x2SingleGame({ 
            role: this.getUIState().singleGameState
          })
        } else {
          // 多游戏模式：使用 ViewModel 提供的 UIState
          WidgetMultiGameCompact({ 
            accountName: this.getUIState().multiGameState.accountName,
            accountUid: this.getUIState().multiGameState.accountUid,
            gameCount: this.getUIState().multiGameState.gameCount,
            games: this.getUIState().multiGameState.games,
            ringSize: 0 
          })
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
