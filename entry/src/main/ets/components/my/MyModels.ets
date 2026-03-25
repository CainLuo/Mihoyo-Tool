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
  server: string = ''

  constructor(
    gameId: string,
    gameName: Resource,
    gameColor: ResourceColor,
    roleUid: string,
    nickname: string,
    server: string
  ) {
    this.gameId = gameId
    this.gameName = gameName
    this.gameColor = gameColor
    this.roleUid = roleUid
    this.nickname = nickname
    this.server = server
  }
}

/** My 页面账号 ViewModel */
export class MyAccountVM {
  accountId: number = 0
  username: string = ''
  roles: MyGameRoleVM[] = []

  constructor(accountId: number, username: string, roles: MyGameRoleVM[]) {
    this.accountId = accountId
    this.username = username
    this.roles = roles
  }
}
