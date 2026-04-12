/**
 * ZZZDailyNoteParser.ets
 *
 * 将 game_data.raw_json 解析为绝区零便签纯数据模型。
 * 属于 core 模块，不得引用任何 ArkUI 组件或 entry 模块类型。
 */

export class ZZZDailyNoteData {
  currentEnergy: number = 0;
  maxEnergy: number = 240;
  /** 剩余恢复秒数（restore 字段） */
  energyRecoverTime: number = 0;

  currentVitality: number = 0;
  maxVitality: number = 400;

  /** 刮刮卡/占卜：'CardSignDone'=已完成 / 'CardSignNo'=未完成 */
  cardSign: string = '';

  /** 录像店状态：'SaleStateDone'=已结算 / 'SaleStateDoing'=营业中 / 'SaleStateNo'=未营业 */
  videoStoreState: string = '';

  /** 侵蚀隧道（深渊）刷新倒计时（秒） */
  abyssRefresh: number = 0;

  /** 是否已订阅月卡 */
  memberCardIsOpen: boolean = false;

  /** 会员卡状态字符串：'MemberCardStateNo'/'MemberCardStateActive'/'MemberCardStateExpired' */
  memberCardState: string = '';

  /** 咖啡厅状态：'CafeStateNo'/'CafeStateOpen'/'CafeStateDone' */
  cafeState: string = '';

  /** 式舆防卫战派遣状态：'ExpeditionStateUnknown'/'ExpeditionStateRunning'/'ExpeditionStateDone'/'ExpeditionStateIdle' */
  templeExpeditionState: string = '';

  /** 式舆防卫战当前货币数量 */
  templeCurrentCurrency: number = 0;
}

// ─── JSON 接口声明 ────────────────────────────────────────────────

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

interface RawZZZMemberCard {
  is_open: boolean;
  member_card_state: string;
}

interface RawZZZTempleRunning {
  expedition_state: string;
  current_currency: string;
}

interface RawZZZNoteData {
  energy: RawZZZEnergy;
  vitality: RawZZZVitality;
  card_sign: string;
  vhs_sale: RawZZZVhsSale;
  abyss_refresh: number;
  member_card: RawZZZMemberCard;
  cafe_state: string;
  temple_running: RawZZZTempleRunning;
}

// ─── Parser ──────────────────────────────────────────────────────

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
    data.energyRecoverTime = raw.energy.restore ?? 0;
    data.currentVitality = raw.vitality.current;
    data.maxVitality = raw.vitality.max;
    data.cardSign = raw.card_sign ?? '';
    data.videoStoreState = raw.vhs_sale ? raw.vhs_sale.sale_state : '';
    data.abyssRefresh = raw.abyss_refresh ?? 0;
    data.memberCardIsOpen = raw.member_card ? raw.member_card.is_open : false;
    data.memberCardState = raw.member_card ? (raw.member_card.member_card_state ?? '') : '';
    data.cafeState = raw.cafe_state ?? '';
    if (raw.temple_running) {
      data.templeExpeditionState = raw.temple_running.expedition_state ?? '';
      data.templeCurrentCurrency = parseInt(raw.temple_running.current_currency ?? '0', 10) || 0;
    }
    return data;
  }
}
