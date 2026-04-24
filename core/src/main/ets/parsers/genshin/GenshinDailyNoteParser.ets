/**
 * GenshinDailyNoteParser.ets
 *
 * 将 game_data.raw_json 解析为原神便签纯数据模型 GenshinDailyNoteData。
 * 此文件属于 core 模块，不得引用任何 ArkUI 组件或 entry 模块的类型。
 *
 * 调用方（entry ViewModel）：
 *   const data = GenshinDailyNoteParser.parse(row.rawJson)
 *   // 再将 data 转换为带本地化描述的 GenshinDailyNoteVM
 */

// ─── 纯数据模型（core 对外暴露，entry ViewModel 消费）────────────

export class GenshinExpeditionData {
  avatarSideIcon: string = '';
  status: string = '';        // "Ongoing" | "Finished"
  remainedTime: string = '';  // 剩余秒数字符串，"0" 表示已完成
}

export class GenshinTransformerData {
  obtained: boolean = false;
  reached: boolean = false;   // true = 可用
  day: number = 0;
  hour: number = 0;
  minute: number = 0;
  second: number = 0;
}

export class GenshinDailyNoteData {
  currentResin: number = 0;
  maxResin: number = 160;
  resinRecoveryTime: number = 0;    // 剩余恢复秒数

  currentHomeCoin: number = 0;
  maxHomeCoin: number = 2400;
  homeCoinRecoveryTime: number = 0; // 剩余恢复秒数

  finishedTaskNum: number = 0;
  totalTaskNum: number = 4;
  isExtraTaskRewardReceived: boolean = false;

  remainResinDiscountNum: number = 0;
  resinDiscountNumLimit: number = 3;

  transformer: GenshinTransformerData = new GenshinTransformerData();

  expeditions: GenshinExpeditionData[] = [];
  maxExpeditionNum: number = 5;
}

// ─── JSON 接口声明（仅用于 parse，不对外暴露）────────────────────

interface RawExpedition {
  avatar_side_icon: string;
  status: string;
  remained_time: string;
}

interface RawTransformerTime {
  Day: number;
  Hour: number;
  Minute: number;
  Second: number;
  reached: boolean;
}

interface RawTransformer {
  obtained: boolean;
  recovery_time: RawTransformerTime;
}

interface RawDailyNoteData {
  current_resin: number;
  max_resin: number;
  resin_recovery_time: string;
  current_home_coin: number;
  max_home_coin: number;
  home_coin_recovery_time: string;
  finished_task_num: number;
  total_task_num: number;
  is_extra_task_reward_received: boolean;
  remain_resin_discount_num: number;
  resin_discount_num_limit: number;
  transformer: RawTransformer;
  expeditions: RawExpedition[];
  max_expedition_num: number;
}

// ─── Parser ──────────────────────────────────────────────────────

export class GenshinDailyNoteParser {

  /**
   * 解析 raw_json 字符串为 GenshinDailyNoteData。
   * 解析失败时返回默认空对象，不抛异常（调用方无需 try-catch）。
   */
  static parse(rawJson: string): GenshinDailyNoteData {
    try {
      const raw = JSON.parse(rawJson) as RawDailyNoteData;
      return GenshinDailyNoteParser.fromRaw(raw);
    } catch (_e) {
      return new GenshinDailyNoteData();
    }
  }

  private static fromRaw(raw: RawDailyNoteData): GenshinDailyNoteData {
    const data = new GenshinDailyNoteData();

    data.currentResin = raw.current_resin;
    data.maxResin = raw.max_resin;
    data.resinRecoveryTime = parseInt(raw.resin_recovery_time, 10) || 0;

    data.currentHomeCoin = raw.current_home_coin ?? 0;
    data.maxHomeCoin = raw.max_home_coin ?? 2400;
    data.homeCoinRecoveryTime = parseInt(raw.home_coin_recovery_time ?? '0', 10) || 0;

    data.finishedTaskNum = raw.finished_task_num;
    data.totalTaskNum = raw.total_task_num;
    data.isExtraTaskRewardReceived = raw.is_extra_task_reward_received;

    data.remainResinDiscountNum = raw.remain_resin_discount_num ?? 0;
    data.resinDiscountNumLimit = raw.resin_discount_num_limit ?? 3;

    data.maxExpeditionNum = raw.max_expedition_num;
    data.expeditions = GenshinDailyNoteParser.parseExpeditions(raw.expeditions);

    data.transformer = GenshinDailyNoteParser.parseTransformer(raw.transformer);

    return data;
  }

  private static parseExpeditions(raws: RawExpedition[]): GenshinExpeditionData[] {
    const result: GenshinExpeditionData[] = [];
    for (let i = 0; i < raws.length; i++) {
      const r = raws[i];
      const e = new GenshinExpeditionData();
      e.avatarSideIcon = r.avatar_side_icon;
      e.status = r.status;
      e.remainedTime = r.remained_time;
      result[result.length] = e;
    }
    return result;
  }

  private static parseTransformer(raw: RawTransformer): GenshinTransformerData {
    const t = new GenshinTransformerData();
    if (!raw || !raw.recovery_time) {
      return t;
    }
    t.obtained = raw.obtained;
    t.reached = raw.recovery_time.reached;
    t.day = raw.recovery_time.Day;
    t.hour = raw.recovery_time.Hour;
    t.minute = raw.recovery_time.Minute;
    t.second = raw.recovery_time.Second;
    return t;
  }
}
