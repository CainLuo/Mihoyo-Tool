/**
 * Widget2x2ViewModel.ets — 2x2 Widget ViewModel
 *
 * 职责：
 * - 接收已解析的 ParsedPayload (Model)
 * - 构建 2x2 专用的 UIState (View)
 *
 * 2x2 Widget 特性：
 * - 单游戏：详细布局（体力环 + 额外数据行）
 * - 多游戏：紧凑布局（最多 2 个游戏）
 *
 * 数据流：
 *   EntryFormAbility → parsePayload() → ParsedPayload → ViewModel.buildUIState() → UIState
 */

import { Widget2x2UIState, Widget1x2RoleUIState, ParsedPayload, ParsedRole, WidgetDataHelper, getGameName } from 'widgetbase';
import { WidgetRoleStateBuilder, WidgetRoleLayout } from './WidgetRoleStateBuilder';

/**
 * 2x2 Widget ViewModel
 */
export class Widget2x2ViewModel {
  /** 2x2 多游戏模式最多显示的游戏数量 */
  private static readonly MAX_GAMES_2X2: number = 2;

  /**
   * 构建 2x2 Widget UIState
   * @param parsed 已解析的 Payload 对象（Model 层）
   */
  static buildUIState(parsed: ParsedPayload): Widget2x2UIState {
    const result = new Widget2x2UIState();
    const roles = parsed.getAllRoles();

    if (roles.length === 0) {
      result.isEmpty = true;
      return result;
    }

    result.isEmpty = false;

    if (parsed.isSingleGame) {
      // 单游戏模式：详细布局
      result.isSingleGame = true;
      result.singleGameState = WidgetRoleStateBuilder.buildRoleUIState(roles[0], WidgetRoleLayout.COMPACT_2X2);
    } else {
      // 多游戏模式：两个 1x2 纵向排列
      result.isSingleGame = false;
      result.multiGameStates = Widget2x2ViewModel.buildMultiGame1x2States(
        roles,
        Widget2x2ViewModel.MAX_GAMES_2X2
      );
    }

    return result;
  }

  /**
   * 构建多游戏的 1x2 UIState 数组（2x2 多游戏模式）
   *
   * 按游戏 ID 去重，每个游戏只显示第一个角色，最多 2 个游戏。
   * 返回 Widget1x2RoleUIState 数组，供 Widget1x2ContentView 组件使用。
   */
  private static buildMultiGame1x2States(
    roles: ParsedRole[],
    maxGames: number
  ): Widget1x2RoleUIState[] {
    const result: Widget1x2RoleUIState[] = [];
    const addedGameIds: string[] = [];

    for (let i = 0; i < roles.length && addedGameIds.length < maxGames; i++) {
      const role = roles[i];

      // 检查该游戏是否已添加
      let alreadyAdded = false;
      for (let j = 0; j < addedGameIds.length; j++) {
        if (addedGameIds[j] === role.gameId) {
          alreadyAdded = true;
          break;
        }
      }

      if (!alreadyAdded) {
        result.push(Widget2x2ViewModel.build1x2RoleUIState(role));
        addedGameIds.push(role.gameId);
      }
    }

    return result;
  }

  /**
   * 构建单个角色的 1x2 UIState（用于多游戏模式）
   */
  private static build1x2RoleUIState(role: ParsedRole): Widget1x2RoleUIState {
    const state = new Widget1x2RoleUIState();

    state.gameId = role.gameId;
    state.gameName = getGameName(role.gameId);
    state.accountUid = role.roleId;
    state.currentStamina = role.currentStamina;
    state.maxStamina = role.maxStamina;
    state.recoverySeconds = role.recoverySeconds;

    // 使用 WidgetDataHelper 工具函数计算展示字段
    state.isFull = WidgetDataHelper.calcIsFull(role.currentStamina, role.maxStamina, role.recoverySeconds);
    state.recoveryTime = WidgetDataHelper.formatRecoveryTime(role.recoverySeconds, state.isFull);
    state.staminaColorType = WidgetDataHelper.calcStaminaColorType(role.currentStamina, role.maxStamina);

    return state;
  }
}
