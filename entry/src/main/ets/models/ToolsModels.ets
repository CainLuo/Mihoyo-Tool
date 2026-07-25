/**
 * ToolsModels.ets — 工具页 UI State 模型
 *
 * 定义工具页所需的数据结构，由 ViewModel 组装后传给 View 层。
 */

import { GameId } from 'core';

/**
 * 养成目标配置页路由参数
 */
export class MaterialTargetConfigParam {
  gameId: GameId = GameId.GENSHIN;
}

/**
 * 游戏入口 UI State
 */
export class GameEntryVM {
  /** 账号 UID（米游社 UID） */
  accountId: string = '';
  /** 游戏标识 */
  gameId: GameId = GameId.GENSHIN;
  /** 游戏名称 */
  gameName: ResourceStr = '';
  /** 游戏图标 */
  gameIcon: Resource = $r('app.media.logo_genshin');
  /** 游戏主题色 */
  gameColor: ResourceColor = $r('app.color.blue_400');
  /** 角色数量 */
  characterCount: number = 0;
  /** 已计算角色数量 */
  computedCount: number = 0;
  /** 是否有数据 */
  hasData: boolean = false;
}
