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

/** 游戏便签摘要 — 展示核心指标 */
export class GameNoteSnapshotVM {
  /** 主要资源名称，如 "原粹树脂" / "开拓力" */
  primaryLabel: string = ''
  /** 主要资源当前值 */
  primaryCurrent: number = 0
  /** 主要资源上限 */
  primaryMax: number = 0
  /** 主要资源恢复描述（可选） */
  primaryRecoveryDesc: string = ''

  /** 次要指标名称（可选） */
  secondaryLabel: string = ''
  /** 次要指标值描述 */
  secondaryDesc: string = ''

  /** 是否已全部恢复/满 */
  isFull: boolean = false

  // ── 原神专属字段 ──────────────────────────────────────────────
  /** 探索派遣当前人数（-1 表示无此数据） */
  expeditionCurrent: number = -1
  /** 探索派遣上限 */
  expeditionMax: number = 0

  /** 洞天财瓮当前值（-1 表示无此数据） */
  homeCoinCurrent: number = -1
  /** 洞天财瓮上限 */
  homeCoinMax: number = 0

  /** 每日委托已完成数（-1 表示无此数据） */
  dailyTaskFinished: number = -1
  /** 每日委托总数 */
  dailyTaskTotal: number = 0
  /** 每日委托奖励是否已全部领取 */
  dailyTaskAllReceived: boolean = false

  // ── 崩铁专属字段 ──────────────────────────────────────────────
  /** 后备开拓力（-1 表示无此数据，无封顶值） */
  reserveStamina: number = -1
  /** 每日实训当前积分（-1 表示无此数据） */
  trainScoreCurrent: number = -1
  /** 每日实训积分上限 */
  trainScoreMax: number = 0
  /** 历战余响剩余次数（-1 表示无此数据） */
  weeklyCocoonCnt: number = -1
  /** 历战余响总次数 */
  weeklyCocoonLimit: number = 0
  /** 模拟宇宙本周积分（-1 表示无此数据） */
  rogueScoreCurrent: number = -1
  /** 模拟宇宙本周积分上限 */
  rogueScoreMax: number = 0
  /** 货币战争本周积分（-1 表示无此数据） */
  tournScoreCurrent: number = -1
  /** 货币战争本周积分上限 */
  tournScoreMax: number = 0

  // ── 绝区零专属字段 ──────────────────────────────────────────────
  /** 今日活跃度当前值（-1 表示无此数据） */
  vitalityCurrent: number = -1
  /** 今日活跃度上限 */
  vitalityMax: number = 0
  /** 刮刮卡/占卜是否已完成 */
  scratchCardDone: boolean = false
  /** 录像店经营状态：'done'=已结算 / 'open'=营业中 / 'closed'=未营业 */
  videoStoreState: string = ''

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
  gameColor: ResourceColor = $r('app.color.color_primary')
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
  /** 米游社用户名（UID） */
  username: string = ''
  /** 米游社昵称 */
  nickname: string = ''
  /** 米游社头像 URL */
  avatarUrl: string = ''
  /** 该账号下的游戏角色列表（二维数组的"行"） */
  roles: GameRoleCardVM[] = []

  constructor(accountId: number, username: string, roles: GameRoleCardVM[], nickname: string = '', avatarUrl: string = '') {
    this.accountId = accountId
    this.username = username
    this.roles = roles
    this.nickname = nickname
    this.avatarUrl = avatarUrl
  }
}
