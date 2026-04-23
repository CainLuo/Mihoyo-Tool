/**
 * MyModels — My 页面 ViewModel 数据类
 */

import { GameId } from 'core';

/** My 页面游戏角色 */
export class MyGameRoleVM {
  /** 游戏 ID */
  gameId: GameId = GameId.GENSHIN
  /** 游戏名称（多语言 Resource） */
  gameName: Resource = $r('app.string.game_name_genshin')
  /** 游戏主题色 */
  gameColor: ResourceColor = $r('app.color.color_primary')
  /** 游戏 logo 资源，由 ViewModel 根据 gameId 填充，Component 直接使用 */
  logoResource: Resource = $r('app.media.logo_genshin')
  /** 游戏角色 UID */
  roleUid: string = ''
  /** 游戏角色昵称 */
  nickname: string = ''
  /** 服务器显示名称，优先使用国际化 Resource，未知服务器时降级为原始 region 字符串 */
  server: ResourceStr = ''
  /** 角色等级 */
  level: number = 0
  /** 游戏背景图 URL */
  bgImageUrl: string = ''
  /** 游戏内统计数据，格式：[{name, value}] */
  stats: GameStatItem[] = []

  constructor(
    gameId: GameId,
    gameName: Resource,
    gameColor: ResourceColor,
    roleUid: string,
    nickname: string,
    server: ResourceStr,
    level: number = 0,
    bgImageUrl: string = '',
    stats: GameStatItem[] = [],
    logoResource: Resource = $r('app.media.logo_genshin')
  ) {
    this.gameId = gameId
    this.gameName = gameName
    this.gameColor = gameColor
    this.logoResource = logoResource
    this.roleUid = roleUid
    this.nickname = nickname
    this.server = server
    this.level = level
    this.bgImageUrl = bgImageUrl
    this.stats = stats
  }
}

/** 游戏内统计数据项 */
export class GameStatItem {
  name: string = ''
  value: string = ''

  constructor(name: string, value: string) {
    this.name = name
    this.value = value
  }
}

/** My 页面账号 ViewModel */
export class MyAccountVM {
  /** 米游社 UID（同时作为列表 key） */
  accountId: string = ''
  /** 米游社用户名 */
  username: string = ''
  /** 米游社 UID */
  uid: string = ''
  /** 米游社昵称 */
  nickname: string = ''
  /** 米游社头像 URL */
  avatarUrl: string = ''
  /** 该账号下的游戏角色列表 */
  roles: MyGameRoleVM[] = []

  constructor(accountId: string, username: string, roles: MyGameRoleVM[], nickname: string = '', avatarUrl: string = '', uid: string = '') {
    this.accountId = accountId
    this.username = username
    this.roles = roles
    this.nickname = nickname
    this.avatarUrl = avatarUrl
    this.uid = uid
  }
}
