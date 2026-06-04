/**
 * Widget4x4ViewModel.ets — 4x4 Widget ViewModel
 *
 * 职责：
 * - 接收已解析的 ParsedPayload (Model)
 * - 构建 4x4 专用的 UIState (View)
 *
 * 4x4 Widget 特性：
 * - 单游戏：详细布局（体力环 + 额外数据行）
 * - 多游戏（2个）：两个 Widget2x2SingleGame 横向排列
 *
 * 数据流：
 *   EntryFormAbility → parsePayload() → ParsedPayload → ViewModel.buildUIState() → UIState
 */

import {
  Widget4x4UIState,
  WidgetRoleUIState,
  WidgetExtraRow,
  StaminaColorType
} from '../models/WidgetUIStates';
import { ParsedPayload, ParsedRole } from '../utils/WidgetPayloadParser';
import { WidgetDataHelper, ParsedExtraRow } from '../utils/WidgetDataHelper';
import { WIDGET_GAME_ID, getGameName, getGameColor } from '../utils/WidgetUtils';

/**
 * 4x4 Widget ViewModel
 */
export class Widget4x4ViewModel {
  /** 4x4 多游戏模式最多显示的游戏数量 */
  private static readonly MAX_GAMES_4x4: number = 2;

  /**
   * 构建 4x4 Widget UIState
   * @param parsed 已解析的 Payload 对象（Model 层）
   */
  static buildUIState(parsed: ParsedPayload): Widget4x4UIState {
    const result = new Widget4x4UIState();
    const roles = parsed.getAllRoles();

    if (roles.length === 0) {
      result.isEmpty = true;
      return result;
    }

    result.isEmpty = false;

    if (parsed.isSingleGame) {
      // 单游戏模式：详细布局
      result.isSingleGame = true;
      result.singleGameState = Widget4x4ViewModel.buildRoleUIState(roles[0]);
    } else {
      // 多游戏模式：两个 WidgetRoleUIState
      result.isSingleGame = false;
      result.multiGameStates = Widget4x4ViewModel.buildMultiGameStates(
        roles,
        Widget4x4ViewModel.MAX_GAMES_4x4
      );
    }

    return result;
  }

  /**
   * 构建单个角色的详细 UIState（单游戏模式）
   */
  private static buildRoleUIState(role: ParsedRole): WidgetRoleUIState {
    const state = new WidgetRoleUIState();

    state.gameId = role.gameId;
    state.gameName = getGameName(role.gameId);
    state.gameColor = getGameColor(role.gameId);
    state.roleId = role.roleId;
    state.currentStamina = role.currentStamina;
    state.maxStamina = role.maxStamina;
    state.recoverySeconds = role.recoverySeconds;

    // 使用 WidgetDataHelper 工具函数计算展示字段
    state.isFull = WidgetDataHelper.calcIsFull(role.currentStamina, role.maxStamina, role.recoverySeconds);
    state.recoveryTime = WidgetDataHelper.formatRecoveryTime(role.recoverySeconds, state.isFull);
    state.staminaColorType = WidgetDataHelper.calcStaminaColorType(role.currentStamina, role.maxStamina);

    // 星铁专属：后备开拓力
    if (role.isStarRail()) {
      state.reserveStamina = WidgetDataHelper.parseReserveStamina(role.rawJson);
    }

    // 解析额外数据行
    const extraRows = WidgetDataHelper.parseExtraRows(role.rawJson, role.gameId);
    state.extraRows = Widget4x4ViewModel.convertExtraRows(extraRows);

    return state;
  }

  /**
   * 构建多游戏的 UIState 数组（4x4 多游戏模式）
   *
   * 按游戏 ID 去重，每个游戏只显示第一个角色，最多 2 个游戏。
   */
  private static buildMultiGameStates(
    roles: ParsedRole[],
    maxGames: number
  ): WidgetRoleUIState[] {
    const result: WidgetRoleUIState[] = [];
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
        result.push(Widget4x4ViewModel.buildRoleUIState(role));
        addedGameIds.push(role.gameId);
      }
    }

    return result;
  }

  /**
   * 转换额外数据行
   */
  private static convertExtraRows(rows: ParsedExtraRow[]): WidgetExtraRow[] {
    const result: WidgetExtraRow[] = [];
    for (let i = 0; i < rows.length; i++) {
      const row = new WidgetExtraRow();
      row.label = rows[i].label;
      row.value = rows[i].value;
      row.valueColor = rows[i].valueColor;
      result.push(row);
    }
    return result;
  }
}
