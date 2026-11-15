/**
 * AccountRoleModels — 账号 / 游戏角色 / 便签摘要的展示模型
 *
 * 以用户为单位，每个用户下有多个游戏角色，
 * 每个游戏角色携带该游戏的实时便签摘要。
 * 供首页（HomePage）与小组件设置（WidgetSettingsSlotStep）共用；
 * 角色详情专用的模型（CharDetailRouterParam 等）不在这里，见 features/chardetail 的 CharDetailModels.
 */
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
  valueColor: ResourceColor = $r('app.color.gray_900');

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
export class MihoyoAccountVM {
  /** 米游社 UID */
  accountId: string = ''
  /** 米游社用户名（UID） */
  username: string = ''
  /** 米游社昵称 */
  nickname: string = ''
  /** 米游社头像 URL */
  avatarUrl: string = ''
  /** 该账号下的游戏角色列表 */
  roles: GameRoleCardVM[] = []

  constructor(accountId: string, username: string, roles: GameRoleCardVM[], nickname: string = '', avatarUrl: string = '') {
    this.accountId = accountId
    this.username = username
    this.roles = roles
    this.nickname = nickname
    this.avatarUrl = avatarUrl
  }
}
