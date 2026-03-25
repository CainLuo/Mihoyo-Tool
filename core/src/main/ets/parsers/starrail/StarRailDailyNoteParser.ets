/**
 * StarRailDailyNoteParser.ets
 *
 * 将 game_data.raw_json 解析为崩坏：星穹铁道便签纯数据模型。
 * 属于 core 模块，不得引用任何 ArkUI 组件或 entry 模块类型。
 */

export class StarRailDailyNoteData {
  currentStamina: number = 0;
  maxStamina: number = 240;
  staminaRecoverTime: number = 0;   // 剩余恢复秒数

  currentReserveStamina: number = 0;
  isReserveStaminaFull: boolean = false;

  currentTrainScore: number = 0;
  maxTrainScore: number = 500;

  currentRogueScore: number = 0;
  maxRogueScore: number = 14000;

  weeklyCocoonCnt: number = 0;
  weeklyCocoonLimit: number = 3;

  rogueTournWeeklyCur: number = 0;
  rogueTournWeeklyMax: number = 0;
}

interface RawStarRailNoteData {
  current_stamina: number;
  max_stamina: number;
  stamina_recover_time: number;
  current_reserve_stamina: number;
  is_reserve_stamina_full: boolean;
  current_train_score: number;
  max_train_score: number;
  current_rogue_score: number;
  max_rogue_score: number;
  weekly_cocoon_cnt: number;
  weekly_cocoon_limit: number;
  rogue_tourn_weekly_cur: number;
  rogue_tourn_weekly_max: number;
}

export class StarRailDailyNoteParser {

  static parse(rawJson: string): StarRailDailyNoteData {
    try {
      const raw = JSON.parse(rawJson) as RawStarRailNoteData;
      return StarRailDailyNoteParser.fromRaw(raw);
    } catch (_e) {
      return new StarRailDailyNoteData();
    }
  }

  private static fromRaw(raw: RawStarRailNoteData): StarRailDailyNoteData {
    const data = new StarRailDailyNoteData();
    data.currentStamina = raw.current_stamina;
    data.maxStamina = raw.max_stamina;
    data.staminaRecoverTime = raw.stamina_recover_time;
    data.currentReserveStamina = raw.current_reserve_stamina;
    data.isReserveStaminaFull = raw.is_reserve_stamina_full;
    data.currentTrainScore = raw.current_train_score;
    data.maxTrainScore = raw.max_train_score;
    data.currentRogueScore = raw.current_rogue_score;
    data.maxRogueScore = raw.max_rogue_score;
    data.weeklyCocoonCnt = raw.weekly_cocoon_cnt;
    data.weeklyCocoonLimit = raw.weekly_cocoon_limit;
    data.rogueTournWeeklyCur = raw.rogue_tourn_weekly_cur;
    data.rogueTournWeeklyMax = raw.rogue_tourn_weekly_max;
    return data;
  }
}
