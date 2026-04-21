/**
 * GameTabItem — Characters 页游戏 Tab 栏的单个 Tab 数据
 *
 * 由 CharactersViewModel.reloadGameTabs() 从 GameRoleRow[] 转换而来，
 * 每个 Tab 对应当前选中账号下的一个游戏角色（原神 / 星铁 / 绝区零）。
 *
 * gameName 使用 Resource 引用，支持多语言。
 */
import { GameId } from 'core';

export class GameTabItem {
  /** 游戏 ID */
  gameId: GameId = GameId.GENSHIN;
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 游戏名称（多语言 Resource） */
  gameName: Resource;

  constructor(gameId: GameId, roleUid: string, gameName: Resource) {
    this.gameId = gameId;
    this.roleUid = roleUid;
    this.gameName = gameName;
  }
}
