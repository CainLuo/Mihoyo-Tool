/**
 * ZZZDailyNoteParser.ets
 *
 * 将 game_data.raw_json 解析为绝区零便签纯数据模型。
 * 属于 core 模块，不得引用任何 ArkUI 组件或 entry 模块类型。
 */

export class ZZZDailyNoteData {
  currentEnergy: number = 0;
  maxEnergy: number = 240;
  energyRecoverTime: number = 0;   // 剩余恢复秒数

  currentVitality: number = 0;
  maxVitality: number = 500;

  /** 刮刮卡/占卜：'CardSignDone' = 已完成，'CardSignNo' = 未完成 */
  cardSign: string = '';

  /** 录像店状态：'SaleStateDone'=已结算 / 'SaleStateDoing'=营业中 / 'SaleStateNo'=未营业 */
  videoStoreState: string = '';
}

interface RawZZZEnergyProgress {
  current: number;
  max: number;
}

interface RawZZZEnergy {
  progress: RawZZZEnergyProgress;
  restore: number;
}

interface RawZZZVitality {
  current: number;
  max: number;
}

interface RawZZZVhsSale {
  sale_state: string;
}

interface RawZZZNoteData {
  energy: RawZZZEnergy;
  vitality: RawZZZVitality;
  card_sign: string;
  vhs_sale: RawZZZVhsSale;
}

export class ZZZDailyNoteParser {

  static parse(rawJson: string): ZZZDailyNoteData {
    try {
      const raw = JSON.parse(rawJson) as RawZZZNoteData;
      return ZZZDailyNoteParser.fromRaw(raw);
    } catch (_e) {
      return new ZZZDailyNoteData();
    }
  }

  private static fromRaw(raw: RawZZZNoteData): ZZZDailyNoteData {
    const data = new ZZZDailyNoteData();
    data.currentEnergy = raw.energy.progress.current;
    data.maxEnergy = raw.energy.progress.max;
    data.energyRecoverTime = raw.energy.restore;
    data.currentVitality = raw.vitality.current;
    data.maxVitality = raw.vitality.max;
    data.cardSign = raw.card_sign;
    data.videoStoreState = raw.vhs_sale.sale_state;
    return data;
  }
}
