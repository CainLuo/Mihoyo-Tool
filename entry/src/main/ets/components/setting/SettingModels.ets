/**
 * SettingModels — 设置页 ViewModel 数据类
 */

/** 设置页游戏角色 */
export class SettingGameRoleVM {
  gameId: string = ''
  gameName: string = ''
  gameColor: ResourceColor = '#007DFF'
  roleUid: string = ''
  nickname: string = ''
  server: string = ''

  constructor(
    gameId: string,
    gameName: string,
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

/** 设置页账号 ViewModel（带展开状态） */
@ObservedV2
export class SettingAccountVM {
  accountId: number = 0
  username: string = ''
  roles: SettingGameRoleVM[] = []
  @Trace expanded: boolean = false

  constructor(accountId: number, username: string, roles: SettingGameRoleVM[]) {
    this.accountId = accountId
    this.username = username
    this.roles = roles
  }
}
