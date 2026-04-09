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
  /** 最大开拓力，固定 240 */
  maxStamina: number = 240
  /** 恢复剩余秒数 */
  staminaRecoverySeconds: number = 0

  /** 每日实训完成数 */
  currentTrainScore: number = 0
  /** 每日实训总分 */
  maxTrainScore: number = 500

  /** 模拟宇宙本周积分 */
  currentRogueScore: number = 0
  /** 模拟宇宙本周积分上限 */
  maxRogueScore: number = 14000

  /** 派遣列表 */
  expeditions: ExpeditionVM[] = []
  /** 派遣上限 */
  maxExpeditionNum: number = 4
}

// ---- 绝区零 ----

/** 绝区零实时便签 ViewModel */
export class ZZZDailyNoteVM {
  /** 当前电量 */
  currentEnergy: number = 0
  /** 最大电量，固定 240 */
  maxEnergy: number = 240
  /** 恢复剩余秒数 */
  energyRecoverySeconds: number = 0

  /** 每日活跃度 */
  currentVitality: number = 0
  /** 每日活跃度上限，固定 400 */
  maxVitality: number = 400

  /** 邦布派遣完成数 */
  bountyCommissionDone: number = 0
  /** 邦布派遣总数 */
  bountyCommissionTotal: number = 4
}
