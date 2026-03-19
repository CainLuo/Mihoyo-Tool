/**
 * HomeModels — 首页 ViewModel 数据类
 *
 * 以用户为单位，每个用户下有多个游戏角色，
 * 每个游戏角色携带该游戏的实时便签摘要。
 */

// ---- 游戏 ID 枚举 ----
export const GAME_GENSHIN = 'genshin'
export const GAME_STARRAIL = 'starrail'
export const GAME_ZZZ = 'zzz'
export const GAME_HONKAI3 = 'honkai3'

/** 游戏便签摘要 — 只展示最核心的 1-2 个指标 */
export class GameNoteSnapshotVM {
  /** 主要资源名称，如 "原粹树脂" / "开拓力" / "电量" */
  primaryLabel: string = ''
  /** 主要资源当前值 */
  primaryCurrent: number = 0
  /** 主要资源上限 */
  primaryMax: number = 0
  /** 主要资源恢复描述（可选） */
  primaryRecoveryDesc: string = ''

  /** 次要指标名称（可选），如 "每日委托" / "实训" / "活跃度" */
  secondaryLabel: string = ''
  /** 次要指标值描述，如 "4/4 已领取" / "0/500" */
  secondaryDesc: string = ''

  /** 是否已全部恢复/满 */
  isFull: boolean = false

  constructor(
    primaryLabel: string,
    primaryCurrent: number,
    primaryMax: number,
    primaryRecoveryDesc: string,
    secondaryLabel: string,
    secondaryDesc: string,
    isFull: boolean
  ) {
    this.primaryLabel = primaryLabel
    this.primaryCurrent = primaryCurrent
    this.primaryMax = primaryMax
    this.primaryRecoveryDesc = primaryRecoveryDesc
    this.secondaryLabel = secondaryLabel
    this.secondaryDesc = secondaryDesc
    this.isFull = isFull
  }
}

/** 单个游戏角色卡片 ViewModel */
export class GameRoleCardVM {
  /** 游戏 ID，对应 GAME_* 常量 */
  gameId: string = ''
  /** 游戏显示名称 */
  gameName: string = ''
  /** 游戏主题色（用于卡片顶部色条） */
  gameColor: ResourceColor = '#007DFF'
  /** 角色 UID */
  roleUid: string = ''
  /** 角色昵称 */
  nickname: string = ''
  /** 服务器名称，如 "天空岛" / "世界树" */
  server: string = ''
  /** 便签摘要（null 表示未同步） */
  snapshot: GameNoteSnapshotVM | null = null
  /** 最后同步时间描述，如 "5分钟前" */
  lastSyncDesc: string = ''

  constructor(
    gameId: string,
    gameName: string,
    gameColor: ResourceColor,
    roleUid: string,
    nickname: string,
    server: string,
    snapshot: GameNoteSnapshotVM | null,
    lastSyncDesc: string
  ) {
    this.gameId = gameId
    this.gameName = gameName
    this.gameColor = gameColor
    this.roleUid = roleUid
    this.nickname = nickname
    this.server = server
    this.snapshot = snapshot
    this.lastSyncDesc = lastSyncDesc
  }
}

/** 单个米游社账号 ViewModel */
export class MihoyoAccountVM {
  /** 账号 ID */
  accountId: number = 0
  /** 米游社用户名 */
  username: string = ''
  /** 该账号下的游戏角色列表（二维数组的"行"） */
  roles: GameRoleCardVM[] = []

  constructor(accountId: number, username: string, roles: GameRoleCardVM[]) {
    this.accountId = accountId
    this.username = username
    this.roles = roles
  }
}
