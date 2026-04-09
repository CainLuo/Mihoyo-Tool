/**
 * MyModels — My 页面 ViewModel 数据类
 */

/** My 页面游戏角色 */
export class MyGameRoleVM {
  gameId: string = ''
  gameName: Resource = $r('app.string.game_name_genshin')
  gameColor: ResourceColor = $r('app.color.color_primary')
  roleUid: string = ''
  nickname: string = ''
  /** 服务器显示名称，优先使用国际化 Resource，未知服务器时降级为原始 region 字符串 */
  server: ResourceStr = ''
  level: number = 0
  /** 游戏背景图 URL */
  bgImageUrl: string = ''
  /** 游戏内统计数据，格式：[{name, value}] */
  stats: GameStatItem[] = []

  constructor(
    gameId: string,
    gameName: Resource,
    gameColor: ResourceColor,
    roleUid: string,
    nickname: string,
    server: ResourceStr,
    level: number = 0,
    bgImageUrl: string = '',
    stats: GameStatItem[] = []
  ) {
    this.gameId = gameId
    this.gameName = gameName
    this.gameColor = gameColor
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
  accountId: number = 0
  username: string = ''
  uid: string = ''
  nickname: string = ''
  avatarUrl: string = ''
  roles: MyGameRoleVM[] = []

  constructor(accountId: number, username: string, roles: MyGameRoleVM[], nickname: string = '', avatarUrl: string = '', uid: string = '') {
    this.accountId = accountId
    this.username = username
    this.roles = roles
    this.nickname = nickname
    this.avatarUrl = avatarUrl
    this.uid = uid
  }
}
