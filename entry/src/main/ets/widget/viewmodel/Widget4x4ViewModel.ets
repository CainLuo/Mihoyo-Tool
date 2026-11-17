/**
 * Widget4x4ViewModel.ets — 4x4 Widget ViewModel
 *
 * 职责：
 * - 接收已解析的 ParsedPayload (Model)
 * - 构建 4x4 专用的 UIState (View)
 *
 * 4x4 Widget 特性：
 * - 单游戏：详细布局（体力区块 + 数据行分组 + 派遣头像）— Widget4x4SingleGame
 * - 多游戏（2个）：两个 WidgetRoleUIState，2x2 网格排列
 *
 * 角色 UIState 的公共构建逻辑（角色字段 / 体力 / 额外数据行 / 派遣头像）
 * 见 WidgetRoleStateBuilder，本文件只保留 4x4 的尺寸差异。
 *
 * 数据流：
 *   EntryFormAbility → parsePayload() → ParsedPayload → ViewModel.buildUIState() → UIState
 */

import { Widget4x4UIState, ParsedPayload } from 'widgetbase';
import { WidgetRoleStateBuilder, WidgetRoleLayout } from './WidgetRoleStateBuilder';

/**
 * 4x4 Widget ViewModel
 */
export class Widget4x4ViewModel {
  /** 4x4 多游戏模式最多显示的游戏数量 */
  private static readonly MAX_GAMES_4X4: number = 2;

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
      // 单游戏模式：详细布局（使用 4x4 专用组件）
      result.isSingleGame = true;
      result.singleGameState = WidgetRoleStateBuilder.buildRoleUIState(roles[0], WidgetRoleLayout.GRID_4X4);
    } else {
      // 多游戏模式：两个 WidgetRoleUIState
      result.isSingleGame = false;
      result.multiGameStates = WidgetRoleStateBuilder.buildMultiGameStates(
        roles,
        Widget4x4ViewModel.MAX_GAMES_4X4,
        WidgetRoleLayout.GRID_4X4
      );
    }

    return result;
  }
}
