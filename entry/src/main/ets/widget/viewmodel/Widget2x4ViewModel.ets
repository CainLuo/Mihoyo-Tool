/**
 * Widget2x4ViewModel.ets — 2x4 Widget ViewModel
 *
 * 职责：
 * - 接收已解析的 ParsedPayload (Model)
 * - 构建 2x4 专用的 UIState (View)
 *
 * 2x4 Widget 特性：
 * - 单游戏：详细布局（体力环 + 额外数据行）
 * - 多游戏：紧凑布局（最多 3 个游戏）
 * - 比 2x2 更宽，可显示更多信息
 *
 * 数据流：
 *   EntryFormAbility → parsePayload() → ParsedPayload → ViewModel.buildUIState() → UIState
 */

import {
  Widget2x4UIState,
  WidgetRoleUIState,
  WidgetMultiGameUIState,
  WidgetExtraRow,
  StaminaColorType,
  RecoveryTimeData
} from '../models/WidgetUIStates';
import { WidgetGameData } from '../models/WidgetModels';
import { ParsedPayload, ParsedRole, ParsedAccount } from '../utils/WidgetPayloadParser';
import { WidgetDataHelper, ParsedExtraRow } from '../utils/WidgetDataHelper';
import { WIDGET_GAME_ID, getGameName, getGameColor } from '../utils/WidgetUtils';

/**
 * 2x4 Widget ViewModel
 */
export class Widget2x4ViewModel {
  /** 2x4 多游戏模式最多显示的游戏数量 */
  private static readonly MAX_GAMES_2x4: number = 3;

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
      // 多游戏模式：紧凑布局，最多 3 个游戏
      result.isSingleGame = false;
      result.multiGameState = Widget2x4ViewModel.buildMultiGameUIState(
        parsed.firstAccount,
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
    state.extraRows = Widget2x4ViewModel.convertExtraRows(extraRows);

    return state;
  }

  /**
   * 构建多游戏 UIState（多游戏模式）
   */
  private static buildMultiGameUIState(
    account: ParsedAccount,
    roles: ParsedRole[],
    maxGames: number
  ): WidgetMultiGameUIState {
    const state = new WidgetMultiGameUIState();

    state.accountName = account.accountName;
    state.accountUid = roles.length > 0 ? roles[0].roleId : '';

    // 按游戏 ID 去重，每个游戏只显示第一个角色
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
        state.games.push(Widget2x4ViewModel.buildGameData(role));
        addedGameIds.push(role.gameId);
      }
    }

    state.gameCount = addedGameIds.length;
    return state;
  }

  /**
   * 构建 WidgetGameData（从 ParsedRole 转换）
   */
  private static buildGameData(role: ParsedRole): WidgetGameData {
    const gameData = new WidgetGameData();

    gameData.gameId = role.gameId;
    gameData.currentStr = String(role.currentStamina);
    gameData.maxStr = String(role.maxStamina);
    gameData.secondsStr = String(role.recoverySeconds);

    // 解析额外数据行
    const extraRows = WidgetDataHelper.parseExtraRows(role.rawJson, role.gameId);

    for (let i = 0; i < extraRows.length; i++) {
      const row = extraRows[i];

      // 原神专属数据
      if (role.gameId === WIDGET_GAME_ID.GENSHIN) {
        if (row.label === 'expedition') {
          const parts = row.value.split('/');
          if (parts.length === 2) {
            gameData.expeditionFinishedStr = parts[0];
            gameData.expeditionMaxStr = parts[1];
          }
        } else if (row.label === 'home_coin') {
          const parts = row.value.split('/');
          if (parts.length === 2) {
            gameData.coinStr = parts[0];
            gameData.coinMaxStr = parts[1];
          }
        }
      }

      // 星铁专属数据
      if (role.gameId === WIDGET_GAME_ID.STARRAIL) {
        if (row.label === 'train_score') {
          const parts = row.value.split('/');
          if (parts.length === 2) {
            gameData.trainStr = parts[0];
            gameData.trainMaxStr = parts[1];
          }
        } else if (row.label === 'cocoon') {
          const parts = row.value.split('/');
          if (parts.length === 2) {
            gameData.cocoonStr = parts[0];
            gameData.cocoonLimitStr = parts[1];
          }
        }
        gameData.reserveStr = WidgetDataHelper.parseReserveStamina(role.rawJson);
      }

      // 绝区零专属数据
      if (role.gameId === WIDGET_GAME_ID.ZZZ) {
        if (row.label === 'vitality') {
          const parts = row.value.split('/');
          if (parts.length === 2) {
            gameData.vitalityStr = parts[0];
            gameData.vitalityMaxStr = parts[1];
          }
        } else if (row.label === 'card_sign') {
          gameData.cardSign = row.value === 'done' ? 'done' : 'not_done';
        }
      }
    }

    return gameData;
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
