/**
 * WidgetRoleStateBuilder.ets — Widget 角色 UIState 共享构建逻辑
 *
 * 背景：
 * 2×2 / 2×4 / 4×4 三个 ViewModel 的「ParsedRole → WidgetRoleUIState」逻辑逐行重复，
 * 差异只有三处：
 *   1. 2×2 不显示角色名、不解析派遣头像；
 *   2. 额外数据行的解析上限与展示上限随尺寸不同（2×2 固定 3；2×4 按游戏 3/4；4×4 不限制解析、展示 6 条）；
 *   3. 2×2 多游戏使用紧凑的 Widget1x2RoleUIState，因此不走本文件的 buildMultiGameStates。
 *
 * 本文件只收敛 2×4 / 4×4 完全一致的逻辑，以及 2×2 单游戏的角色构建，
 * 纯函数、无 UI 依赖，行为与原三份实现逐行一致。
 */

import { WidgetRoleUIState, WidgetExtraRow, ParsedRole, ParsedExtraRow, WidgetDataHelper, WidgetGameId, getGameName, getGameColor, getGameNameRes } from 'widgetbase';

/**
 * 卡片布局形态（决定额外数据行的截断规则）
 */
export enum WidgetRoleLayout {
  /** 2×2 单游戏：不显示角色名 / 派遣头像，额外数据行固定 3 行 */
  COMPACT_2X2 = 0,
  /** 2×4 单游戏：额外数据行按游戏 3/4 行 */
  GRID_2X4 = 1,
  /** 4×4 单游戏：额外数据行不限制解析，展示 6 行 */
  GRID_4X4 = 2
}

/**
 * Widget 角色 UIState 构建器
 */
export class WidgetRoleStateBuilder {
  /**
   * 构建单个角色的详细 UIState（单游戏模式）
   */
  static buildRoleUIState(role: ParsedRole, layout: WidgetRoleLayout): WidgetRoleUIState {
    const state = new WidgetRoleUIState();

    state.gameId = role.gameId;
    state.gameName = getGameName(role.gameId);
    state.gameNameResource = getGameNameRes(role.gameId);
    state.gameColor = getGameColor(role.gameId);
    state.roleId = role.roleId;
    state.roleIdWithPrefix = 'UID ' + role.roleId;
    if (layout !== WidgetRoleLayout.COMPACT_2X2) {
      // 角色名：使用角色昵称
      state.roleName = role.nickname;
    }
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

    state.extraRows = WidgetRoleStateBuilder.buildExtraRows(role, layout);

    // 原神专属：解析派遣角色头像（2×2 不展示派遣区）
    // formImagesKey 使用 'exp_avatar' 前缀，与 FormExtensionAbility 中的 key 对应
    if (layout !== WidgetRoleLayout.COMPACT_2X2 && role.gameId === WidgetGameId.GENSHIN) {
      state.expeditions = WidgetDataHelper.parseExpeditions(role.rawJson, 'exp_avatar');
    }

    return state;
  }

  /**
   * 构建多游戏的 UIState 数组（2×4 / 4×4 多游戏模式）
   *
   * 按游戏 ID 去重，每个游戏只显示第一个角色，最多 2 个游戏。
   */
  static buildMultiGameStates(
    roles: ParsedRole[],
    maxGames: number,
    layout: WidgetRoleLayout
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
        result.push(WidgetRoleStateBuilder.buildRoleUIState(role, layout));
        addedGameIds.push(role.gameId);
      }
    }

    return result;
  }

  /**
   * 按布局解析额外数据行
   *
   * 原神：去掉第一条（探索派遣），因为改在底部显示
   */
  private static buildExtraRows(role: ParsedRole, layout: WidgetRoleLayout): WidgetExtraRow[] {
    if (layout === WidgetRoleLayout.COMPACT_2X2) {
      const rows = WidgetDataHelper.parseExtraRows(role.rawJson, role.widgetRawJson, role.gameId, 3);
      return WidgetRoleStateBuilder.convertExtraRows(rows);
    }

    if (layout === WidgetRoleLayout.GRID_4X4) {
      // 4×4 有更多空间：不限制解析数量，最多展示 6 条
      const rows = WidgetDataHelper.parseExtraRows(role.rawJson, role.widgetRawJson, role.gameId, 0);
      const filteredRows = role.gameId === WidgetGameId.GENSHIN ? rows.slice(1) : rows;
      return WidgetRoleStateBuilder.convertExtraRows(filteredRows.slice(0, 6));
    }

    // 2×4：原神 / 绝区零解析 4 条，星铁 3 条；展示上限为绝区零 4 条、其余 3 条
    const parseLimit = role.gameId === WidgetGameId.GENSHIN || role.gameId === WidgetGameId.ZZZ ? 4 : 3;
    const displayLimit = role.gameId === WidgetGameId.ZZZ ? 4 : 3;
    const rows = WidgetDataHelper.parseExtraRows(role.rawJson, role.widgetRawJson, role.gameId, parseLimit);
    const filteredRows = role.gameId === WidgetGameId.GENSHIN ? rows.slice(1) : rows;
    return WidgetRoleStateBuilder.convertExtraRows(filteredRows.slice(0, displayLimit));
  }

  /**
   * 转换额外数据行（ParsedExtraRow → WidgetExtraRow）
   */
  private static convertExtraRows(rows: ParsedExtraRow[]): WidgetExtraRow[] {
    const result: WidgetExtraRow[] = [];
    for (let i = 0; i < rows.length; i++) {
      const row = new WidgetExtraRow();
      row.label = rows[i].label;
      row.labelResource = WidgetDataHelper.getExtraRowLabelResource(rows[i].label);
      row.value = rows[i].value;
      // 如果 value 已经是最终格式（如绝区零 note_list），直接使用，不再转换
      row.displayValue = rows[i].isRawValue ? rows[i].value : WidgetDataHelper.getExtraRowValueDisplay(rows[i].value);
      row.valueColor = rows[i].valueColor;
      result.push(row);
    }
    return result;
  }
}
