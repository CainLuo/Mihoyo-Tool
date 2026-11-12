/**
 * Widget2x4ViewModel.ets — 2x4 Widget ViewModel
 *
 * 职责：
 * - 接收已解析的 ParsedPayload (Model)
 * - 构建 2x4 专用的 UIState (View)
 *
 * 2x4 Widget 特性：
 * - 单游戏：详细布局（体力环 + 数据行）— Widget2x4SingleGame
 * - 多游戏（2个）：两个 Widget2x2SingleGame 横向排列 + Divider
 *
 * 角色 UIState 的公共构建逻辑（角色字段 / 体力 / 额外数据行 / 派遣头像）
 * 见 WidgetRoleStateBuilder，本文件只保留 2x4 的尺寸差异。
 *
 * 数据流：
 *   EntryFormAbility → parsePayload() → ParsedPayload → ViewModel.buildUIState() → UIState
 */

import { Widget2x4UIState, ParsedPayload } from 'widgetbase';
import { WidgetRoleStateBuilder, WidgetRoleLayout } from './WidgetRoleStateBuilder';

/**
 * 2x4 Widget ViewModel
 */
export class Widget2x4ViewModel {
  /** 2x4 多游戏模式最多显示的游戏数量 */
  private static readonly MAX_GAMES_2X4: number = 2;

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
      result.singleGameState = WidgetRoleStateBuilder.buildRoleUIState(roles[0], WidgetRoleLayout.GRID_2X4);
    } else {
      // 多游戏模式：两个 WidgetRoleUIState 横向排列
      result.isSingleGame = false;
      result.multiGameStates = WidgetRoleStateBuilder.buildMultiGameStates(
        roles,
        Widget2x4ViewModel.MAX_GAMES_2X4,
        WidgetRoleLayout.GRID_2X4
      );
    }

    return result;
  }
}
