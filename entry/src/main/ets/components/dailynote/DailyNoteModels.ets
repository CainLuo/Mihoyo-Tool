/**
 * DailyNoteModels — 实时便签 ViewModel 数据类
 *
 * 职责：定义各游戏便签的纯数据结构（ViewModel），
 * 由对应游戏的 Parser 从 raw_json 解析后传入 UI 组件。
 *
 * 扩展方式：新增游戏只需新增对应 class，UI 组件不受影响。
 */

// ---- 通用 ----

/** 派遣角色条目（原神、星铁共用） */
export class ExpeditionVM {
  /** 角色头像 URL（可为空，显示占位图） */
  avatarUrl: string = ''
  /** 剩余秒数（0 表示已完成） */
  remainSeconds: number = 0
  /** 是否已完成 */
  finished: boolean = false

  constructor(avatarUrl: string, remainSeconds: number, finished: boolean) {
    this.avatarUrl = avatarUrl
    this.remainSeconds = remainSeconds
    this.finished = finished
  }
}

// ---- 原神 ----

/** 每日委托状态 */
export class GenshinDailyTaskVM {
  /** 委托完成数（0-4） */
  finishedNum: number = 0
  /** 总委托数，固定 4 */
  totalNum: number = 4
  /** 历练点是否全部领取 */
  isExtraTaskRewardReceived: boolean = false
  /** 长效历练点数量（-1 表示不显示） */
  storedAdventure: number = -1

  constructor(
    finishedNum: number,
    totalNum: number,
    isExtraTaskRewardReceived: boolean,
    storedAdventure: number
  ) {
    this.finishedNum = finishedNum
    this.totalNum = totalNum
    this.isExtraTaskRewardReceived = isExtraTaskRewardReceived
    this.storedAdventure = storedAdventure
  }
}

/** 原神实时便签完整 ViewModel */
export class GenshinDailyNoteVM {
  /** 当前树脂 */
  currentResin: number = 0
  /** 最大树脂，固定 200 */
  maxResin: number = 200
  /** 树脂恢复剩余秒数（0 表示已满） */
  resinRecoverySeconds: number = 0

  /** 当前洞天宝钱 */
  currentHomeCoin: number = 0
  /** 最大洞天宝钱 */
  maxHomeCoin: number = 2400
  /** 宝钱恢复剩余秒数（0 表示已满） */
  homeCoinRecoverySeconds: number = 0

  /** 每日委托 */
  dailyTask: GenshinDailyTaskVM = new GenshinDailyTaskVM(0, 4, false, -1)

  /** 本周强敌剩余挑战次数 */
  remainResinDiscountNum: number = 0
  /** 本周强敌总次数，固定 3 */
  resinDiscountNumLimit: number = 3

  /** 参量质变仪是否可用 */
  transformerReady: boolean = false
  /** 参量质变仪剩余天/时/分（可用时均为 0） */
  transformerDay: number = 0
  transformerHour: number = 0
  transformerMinute: number = 0

  /** 派遣列表 */
  expeditions: ExpeditionVM[] = []
  /** 派遣上限 */
  maxExpeditionNum: number = 5

  /** 魔神任务是否全部完成 */
  archonQuestDone: boolean = false
  /** 魔神任务描述（未完成时显示） */
  archonQuestDesc: string = ''
}

// ---- 星穹铁道 ----

/** 星穹铁道实时便签 ViewModel */
export class StarRailDailyNoteVM {
  /** 当前开拓力 */
  currentStamina: number = 0
  /** 最大开拓力 */
  maxStamina: number = 240
  /** 恢复剩余秒数 */
  staminaRecoverySeconds: number = 0

  /** 后备开拓力 */
  currentReserveStamina: number = 0
  /** 后备开拓力是否已满 */
  isReserveStaminaFull: boolean = false

  /** 已派遣数 */
  acceptedExpeditionNum: number = 0
  /** 派遣上限 */
  totalExpeditionNum: number = 4
  /** 派遣列表 */
  expeditions: ExpeditionVM[] = []

  /** 每日实训完成数 */
  currentTrainScore: number = 0
  /** 每日实训总分 */
  maxTrainScore: number = 500

  /** 模拟宇宙本周积分 */
  currentRogueScore: number = 0
  /** 模拟宇宙本周积分上限 */
  maxRogueScore: number = 14000

  /** 历战余响已用次数 */
  weeklyCocoonCnt: number = 0
  /** 历战余响每周上限 */
  weeklyCocoonLimit: number = 3

  /** 差分宇宙是否已解锁 */
  rogueTournWeeklyUnlocked: boolean = false
  /** 差分宇宙本周积分 */
  rogueTournWeeklyCur: number = 0
  /** 差分宇宙本周积分上限 */
  rogueTournWeeklyMax: number = 1000
  /** 差分宇宙经验是否已满 */
  rogueTournExpIsFull: boolean = false

  /** 黄金与机械本周进度 */
  gridFightWeeklyCur: number = 0
  /** 黄金与机械本周上限（0 表示未解锁） */
  gridFightWeeklyMax: number = 0
}

// ---- 绝区零 ----

/** 绝区零实时便签 ViewModel */
export class ZZZDailyNoteVM {
  /** 当前电量 */
  currentEnergy: number = 0
  /** 最大电量 */
  maxEnergy: number = 240
  /** 恢复剩余秒数 */
  energyRecoverySeconds: number = 0

  /** 每日活跃度 */
  currentVitality: number = 0
  /** 每日活跃度上限 */
  maxVitality: number = 400

  /** 录像店状态（'SaleStateDone'/'SaleStateDoing'/'SaleStateNo'） */
  vhsSaleState: string = ''
  /** 刮刮卡状态（'CardSignDone'/'CardSignNo'） */
  cardSign: string = ''

  /** 式舆防卫战刷新倒计时（秒） */
  abyssRefresh: number = 0
  /** 会员卡是否开通 */
  memberCardIsOpen: boolean = false
  /** 会员卡状态字符串 */
  memberCardState: string = ''
  /** 咖啡厅状态 */
  cafeState: string = ''
  /** 式舆防卫战派遣状态 */
  templeExpeditionState: string = ''
  /** 式舆防卫战当前货币 */
  templeCurrentCurrency: number = 0
}
