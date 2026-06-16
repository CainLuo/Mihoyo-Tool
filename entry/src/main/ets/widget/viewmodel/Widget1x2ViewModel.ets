/**
 * Widget1x2ViewModel.ets — 1x2 Widget ViewModel
 *
 * 职责：
 * - 接收已解析的 ParsedPayload (Model)
 * - 构建 1x2 专用的 UIState (View)
 *
 * 1x2 Widget 特性：
 * - 单游戏专用模板（原神/星铁/绝区零各有独立模板）
 * - 只显示单个角色
 * - 根据 gameIdFilter 过滤角色
 *
 * 数据流：
 *   EntryFormAbility → parsePayload() → ParsedPayload → ViewModel.buildUIState() → UIState
 */

import { Widget1x2UIState, Widget1x2RoleUIState, StaminaColorType } from '../models/WidgetUIStates';
import { ParsedPayload, ParsedRole } from '../utils/WidgetPayloadParser';
import { WidgetDataHelper } from '../utils/WidgetDataHelper';
import { getGameName } from '../utils/WidgetUtils';

/**
 * 1x2 Widget ViewModel
 */
export class Widget1x2ViewModel {
  /**
   * 构建 1x2 Widget UIState
   * @param parsed 已解析的 Payload 对象（Model 层）
   * @param gameIdFilter 游戏类型过滤（genshin/starrail/zzz）
   */
  static buildUIState(parsed: ParsedPayload, gameIdFilter: string): Widget1x2UIState {
    const result = new Widget1x2UIState();
    const roles = Widget1x2ViewModel.filterRolesByGameId(parsed.getAllRoles(), gameIdFilter);

    if (roles.length === 0) {
      result.isEmpty = true;
      return result;
    }

    result.isEmpty = false;
    result.role = Widget1x2ViewModel.buildRoleUIState(roles[0]);
    return result;
  }

  /**
   * 按游戏类型过滤角色
   */
  private static filterRolesByGameId(roles: ParsedRole[], gameId: string): ParsedRole[] {
    if (gameId.length === 0) {
      return roles;
    }

    const filtered: ParsedRole[] = [];
    for (let i = 0; i < roles.length; i++) {
      if (roles[i].gameId === gameId) {
        filtered.push(roles[i]);
      }
    }
    return filtered;
  }

  /**
   * 构建单个角色的 1x2 UIState
   */
  private static buildRoleUIState(role: ParsedRole): Widget1x2RoleUIState {
    const state = new Widget1x2RoleUIState();

    state.gameId = role.gameId;
    state.gameName = getGameName(role.gameId);
    state.accountUid = role.roleId;
    state.currentStamina = role.currentStamina;
    state.maxStamina = role.maxStamina;
    state.recoverySeconds = role.recoverySeconds;

    // 使用 WidgetDataHelper 工具函数计算展示字段
    state.isFull = WidgetDataHelper.calcIsFull(role.currentStamina, role.maxStamina, role.recoverySeconds);
    state.ratio = WidgetDataHelper.calcStaminaRatio(role.currentStamina, role.maxStamina);
    state.staminaColorType = WidgetDataHelper.calcStaminaColorType(role.currentStamina, role.maxStamina);
    state.recoveryTime = WidgetDataHelper.formatRecoveryTime(role.recoverySeconds, state.isFull);

    return state;
  }
}
