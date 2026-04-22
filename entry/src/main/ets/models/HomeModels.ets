/**
 * HomeModels — 首页 ViewModel 数据类
 *
 * 以用户为单位，每个用户下有多个游戏角色，
 * 每个游戏角色携带该游戏的实时便签摘要。
 */
import { ZZZVideoStoreState, ZZZCardSign } from 'core';
import { GameId } from 'core';

/**
 * 游戏便签数据行 ViewModel
 *
 * 由 HomeViewModel 在解析 daily_note 时填充，View 层直接渲染，不做任何业务判断。
 */
export class GameDataRowVM {
  /** 标签（多语言 Resource） */
  label: Resource;
  /** 值文字（ResourceStr 支持 Resource 或 string） */
  value: ResourceStr = '';
  /** 值颜色（由 VM 根据业务规则算好） */
  valueColor: ResourceColor = $r('app.color.color_text_primary');

  constructor(label: Resource, value: ResourceStr, valueColor: ResourceColor) {
    this.label = label;
    this.value = value;
    this.valueColor = valueColor;
  }
}

/** 游戏便签摘要 — 展示核心指标 */
export class GameNoteSnapshotVM {
  /** 主要资源标签（如 $r('app.string.daily_note_resin_title')），由 VM 填充 */
  primaryLabel: ResourceStr = ''
  /** 主要资源当前值 */
  primaryCurrent: number = 0
  /** 主要资源上限 */
  primaryMax: number = 0
  /** 主要资源恢复剩余秒数（0 表示已满或无数据） */
  primaryRecoverySeconds: number = 0

  /** 次要指标名称（可选） */
  secondaryLabel: string = ''
  /** 次要指标值描述 */
  secondaryDesc: string = ''

  /** 是否已全部恢复/满 */
  isFull: boolean = false

  /**
   * 数据行列表（由 HomeViewModel 填充，View 层直接 ForEach 渲染）
   * 包含分割线以下的所有数据行，顺序由 VM 决定。
   */
  dataRows: GameDataRowVM[] = [];

  /**
   * 主体力颜色（由 VM 根据 isFull + gameId 算好，View 层直接用）
   * 原神满了 = danger，其他游戏满了 = primary，未满按比例。
   */
  primaryColor: ResourceColor = $r('app.color.color_primary');

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
  /** 刮刮卡/占卜状态 */
  scratchCardSign: ZZZCardSign = ZZZCardSign.UNKNOWN
  /** 录像店经营状态 */
  videoStoreState: ZZZVideoStoreState = ZZZVideoStoreState.UNKNOWN

  constructor(
    primaryLabel: ResourceStr,
    primaryCurrent: number,
    primaryMax: number,
    primaryRecoverySeconds: number,
    secondaryLabel: string,
    secondaryDesc: string,
    isFull: boolean
  ) {
    this.primaryLabel = primaryLabel
    this.primaryCurrent = primaryCurrent
    this.primaryMax = primaryMax
    this.primaryRecoverySeconds = primaryRecoverySeconds
    this.secondaryLabel = secondaryLabel
    this.secondaryDesc = secondaryDesc
    this.isFull = isFull
  }
}

/** 单个游戏角色卡片 ViewModel */
export class GameRoleCardVM {
  /** 游戏 ID */
  gameId: GameId = GameId.GENSHIN
  /** 游戏显示名称 */
  gameName: string = ''
  /** 游戏主题色（用于卡片顶部色条） */
  gameColor: ResourceColor = $r('app.color.color_primary')
  /** 游戏 Logo 图标资源（由 ViewModel 填充，Component 直接用） */
  logoResource: Resource = $r('app.media.logo_genshin')
  /** 角色 UID */
  roleUid: string = ''
  /** 角色昵称 */
  nickname: string = ''
  /** 服务器显示名称，优先使用国际化 Resource，未知服务器时降级为原始 region 字符串 */
  server: ResourceStr = ''
  /** 便签摘要（null 表示未同步） */
  snapshot: GameNoteSnapshotVM | null = null
  /** 最后同步时间描述，如 "5分钟前" */
  lastSyncDesc: string = ''

  constructor(
    gameId: GameId,
    gameName: string,
    gameColor: ResourceColor,
    roleUid: string,
    nickname: string,
    server: ResourceStr,
    snapshot: GameNoteSnapshotVM | null,
    lastSyncDesc: string,
    logoResource: Resource = $r('app.media.logo_genshin')
  ) {
    this.gameId = gameId
    this.gameName = gameName
    this.gameColor = gameColor
    this.logoResource = logoResource
    this.roleUid = roleUid
    this.nickname = nickname
    this.server = server
    this.snapshot = snapshot
    this.lastSyncDesc = lastSyncDesc
  }
}

/** 单个米游社账号 ViewModel */
@ObservedV2
export class MihoyoAccountVM {
  /** 米游社 UID */
  @Trace accountId: string = ''
  /** 米游社用户名（UID） */
  @Trace username: string = ''
  /** 米游社昵称 */
  @Trace nickname: string = ''
  /** 米游社头像 URL */
  @Trace avatarUrl: string = ''
  /** 该账号下的游戏角色列表（二维数组的"行"） */
  @Trace roles: GameRoleCardVM[] = []

  constructor(accountId: string, username: string, roles: GameRoleCardVM[], nickname: string = '', avatarUrl: string = '') {
    this.accountId = accountId
    this.username = username
    this.roles = roles
    this.nickname = nickname
    this.avatarUrl = avatarUrl
  }
}
