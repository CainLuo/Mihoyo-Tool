/**
 * Widget2x4ViewModel.ets — 2x4 Widget ViewModel
 *
 * 职责：
 * - 接收已解析的 ParsedPayload (Model)
 * - 构建 2x4 专用的 UIState (View)
 *
 * 2x4 Widget 特性：
 * - 单游戏：详细布局（体力环 + 额外数据行）
 * - 多游戏（2个）：两个 Widget2x2SingleGame 横向排列 + Divider
 *
 * 数据流：
 *   EntryFormAbility → parsePayload() → ParsedPayload → ViewModel.buildUIState() → UIState
 */

import {
  Widget2x4UIState,
  WidgetRoleUIState,
  WidgetExtraRow
} from '../models/WidgetUIStates';
import { ParsedPayload, ParsedRole } from '../utils/WidgetPayloadParser';
import { WidgetDataHelper, ParsedExtraRow } from '../utils/WidgetDataHelper';
import { WIDGET_GAME_ID, getGameName, getGameColor, gameNameRes } from '../utils/WidgetUtils';

/**
 * 2x4 Widget ViewModel
 */
export class Widget2x4ViewModel {
  /** 2x4 多游戏模式最多显示的游戏数量 */
  private static readonly MAX_GAMES_2x4: number = 2;

  /**
   * 构建 2x4 Widget UIState
   * @param parsed 已解析的 Payload 对象（Model 层）
   */
  static buildUIState(parsed: ParsedPayload): Widget2x4UIState {
    const result = new Widget2x4UIState();
    const roles = parsed.getAllRoles();

    if (roles.length === 0) {
      result.isEmpty = true;
      return result;
    }

    result.isEmpty = false;

    if (parsed.isSingleGame) {
      // 单游戏模式：详细布局
      result.isSingleGame = true;
      result.singleGameState = Widget2x4ViewModel.buildRoleUIState(roles[0]);
    } else {
      // 多游戏模式：两个 WidgetRoleUIState 横向排列
      result.isSingleGame = false;
      result.multiGameStates = Widget2x4ViewModel.buildMultiGameStates(
        roles,
        Widget2x4ViewModel.MAX_GAMES_2x4
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
    state.gameNameResource = gameNameRes(role.gameId);
    state.gameColor = getGameColor(role.gameId);
    state.roleId = role.roleId;
    state.roleIdWithPrefix = 'UID ' + role.roleId;
    // 角色名：使用角色昵称 + 等级（如果有）
    state.roleName = Widget2x4ViewModel.buildRoleName(role);
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
    // 原神：去掉第一条（探索派遣），因为改在底部显示
    // 星铁/绝区零：保留全部
    // 2x4 右侧最多显示 3 条额外数据
    const maxRows = role.gameId === WIDGET_GAME_ID.GENSHIN ? 4 : 3; // 原神多解析一条用于去掉
    const extraRows = WidgetDataHelper.parseExtraRows(role.rawJson, role.widgetRawJson, role.gameId, maxRows);
    const filteredRows = role.gameId === WIDGET_GAME_ID.GENSHIN ? extraRows.slice(1) : extraRows;
    state.extraRows = Widget2x4ViewModel.convertExtraRows(filteredRows.slice(0, 3));

    // 原神专属：解析派遣角色头像
    // formImagesKey 使用 'exp_avatar' 前缀，与 FormExtensionAbility 中的 key 对应
    if (role.gameId === WIDGET_GAME_ID.GENSHIN) {
      state.expeditions = WidgetDataHelper.parseExpeditions(role.rawJson, 'exp_avatar');
    }

    return state;
  }

  /**
   * 构建角色名显示文字
   * 格式：昵称 或空
   */
  private static buildRoleName(role: ParsedRole): string {
    return role.nickname;
  }

  /**
   * 构建多游戏的 UIState 数组（2x4 多游戏模式）
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
        result.push(Widget2x4ViewModel.buildRoleUIState(role));
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
      row.labelResource = WidgetDataHelper.getExtraRowLabelResource(rows[i].label);
      row.value = rows[i].value;
      row.displayValue = WidgetDataHelper.getExtraRowValueDisplay(rows[i].value);
      row.valueColor = rows[i].valueColor;
      result.push(row);
    }
    return result;
  }
}
