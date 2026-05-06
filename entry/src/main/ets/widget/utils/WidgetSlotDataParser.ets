/**
 * WidgetSlotDataParser.ets — Widget Slot 数据解析器
 *
 * 从 WidgetSlotData 的 rawJson 解析为 Widget 可用的数据结构。
 * 这是 Widget 模块专用的解析器，不依赖 core 的 Parser（因为 Widget 使用 @Component V1 体系）。
 *
 * 解析结果直接用于 Widget 组件渲染，字段命名与 UI 显示需求对齐。
 */

import { WIDGET_GAME_ID } from './WidgetUtils';

/**
 * 原神便签解析数据
 */
export class WidgetGenshinData {
  currentResin: number = 0;
  maxResin: number = 160;
  resinRecoveryTime: number = 0;
  currentHomeCoin: number = 0;
  maxHomeCoin: number = 2400;
  finishedTaskNum: number = 0;
  totalTaskNum: number = 4;
  remainResinDiscountNum: number = 0;
  currentExpeditionNum: number = 0;
  maxExpeditionNum: number = 5;
  transformerObtained: boolean = false;
  transformerReached: boolean = false;
}

/**
 * 星铁便签解析数据
 */
export class WidgetStarRailData {
  currentStamina: number = 0;
  maxStamina: number = 240;
  staminaRecoverTime: number = 0;
  currentReserveStamina: number = 0;
  currentTrainScore: number = 0;
  maxTrainScore: number = 500;
  weeklyCocoonCnt: number = 0;
  weeklyCocoonLimit: number = 3;
}

/**
 * 绝区零便签解析数据
 */
export class WidgetZZZData {
  currentEnergy: number = 0;
  maxEnergy: number = 240;
  energyRecoverTime: number = 0;
  currentVitality: number = 0;
  maxVitality: number = 400;
  cardSign: string = '';
  videoStoreState: string = '';
}

/**
 * 解析后的 Slot 数据（统一接口）
 */
export class ParsedSlotData {
  gameId: string = '';
  accountId: string = '';
  accountName: string = '';
  roleId: string = '';
  nickname: string = '';
  server: string = '';

  // 当前体力（三游戏通用）
  currentStamina: number = 0;
  maxStamina: number = 160;
  recoverySeconds: number = 0;

  // 原神专属
  genshin: WidgetGenshinData | null = null;

  // 星铁专属
  starrail: WidgetStarRailData | null = null;

  // 绝区零专属
  zzz: WidgetZZZData | null = null;
}

/**
 * 从 WidgetSlotData JSON 解析为 ParsedSlotData
 */
export function parseSlotJson(slotJson: string): ParsedSlotData {
  const result = new ParsedSlotData();

  if (slotJson.length === 0) {
    return result;
  }

  try {
    const obj = JSON.parse(slotJson) as Record<string, Object>;
    result.gameId = (obj['gameId'] as string) ?? '';
    result.accountId = (obj['accountId'] as string) ?? '';
    result.accountName = (obj['accountName'] as string) ?? '';
    result.roleId = (obj['roleId'] as string) ?? '';
    result.nickname = (obj['nickname'] as string) ?? '';
    result.server = (obj['server'] as string) ?? '';

    const rawJson = obj['rawJson'] as string;
    if (rawJson && rawJson.length > 0) {
      parseRawJson(result, rawJson);
    }
  } catch (_e) {
    // 解析失败返回默认值
  }

  return result;
}

/**
 * 解析 rawJson（API 原始响应）
 */
function parseRawJson(result: ParsedSlotData, rawJson: string): void {
  try {
    const resp = JSON.parse(rawJson) as Record<string, Object>;
    // API 响应格式：{ retcode: 0, message: 'OK', data: {...} }
    const data = (resp['data'] ?? resp) as Record<string, Object>;

    if (result.gameId === WIDGET_GAME_ID.GENSHIN) {
      result.genshin = parseGenshinData(data);
      result.currentStamina = result.genshin.currentResin;
      result.maxStamina = result.genshin.maxResin;
      result.recoverySeconds = result.genshin.resinRecoveryTime;
    } else if (result.gameId === WIDGET_GAME_ID.STARRAIL) {
      result.starrail = parseStarRailData(data);
      result.currentStamina = result.starrail.currentStamina;
      result.maxStamina = result.starrail.maxStamina;
      result.recoverySeconds = result.starrail.staminaRecoverTime;
    } else if (result.gameId === WIDGET_GAME_ID.ZZZ) {
      result.zzz = parseZZZData(data);
      result.currentStamina = result.zzz.currentEnergy;
      result.maxStamina = result.zzz.maxEnergy;
      result.recoverySeconds = result.zzz.energyRecoverTime;
    }
  } catch (_e) {
    // 解析失败保持默认值
  }
}

/**
 * 解析原神便签数据
 */
function parseGenshinData(data: Record<string, Object>): WidgetGenshinData {
  const result = new WidgetGenshinData();
  result.currentResin = Number(data['current_resin'] ?? 0);
  result.maxResin = Number(data['max_resin'] ?? 160);
  result.resinRecoveryTime = parseInt(String(data['resin_recovery_time'] ?? '0'), 10) || 0;
  result.currentHomeCoin = Number(data['current_home_coin'] ?? 0);
  result.maxHomeCoin = Number(data['max_home_coin'] ?? 2400);
  result.finishedTaskNum = Number(data['finished_task_num'] ?? 0);
  result.totalTaskNum = Number(data['total_task_num'] ?? 4);
  result.remainResinDiscountNum = Number(data['remain_resin_discount_num'] ?? 0);
  result.currentExpeditionNum = Number(data['current_expedition_num'] ?? 0);
  result.maxExpeditionNum = Number(data['max_expedition_num'] ?? 5);

  const transformer = data['transformer'] as Record<string, Object> | null;
  if (transformer) {
    result.transformerObtained = Boolean(transformer['obtained']);
    const recoveryTime = transformer['recovery_time'] as Record<string, Object> | null;
    if (recoveryTime) {
      result.transformerReached = Boolean(recoveryTime['reached']);
    }
  }

  return result;
}

/**
 * 解析星铁便签数据
 */
function parseStarRailData(data: Record<string, Object>): WidgetStarRailData {
  const result = new WidgetStarRailData();
  result.currentStamina = Number(data['current_stamina'] ?? 0);
  result.maxStamina = Number(data['max_stamina'] ?? 240);
  result.staminaRecoverTime = Number(data['stamina_recover_time'] ?? 0);
  result.currentReserveStamina = Number(data['current_reserve_stamina'] ?? 0);
  result.currentTrainScore = Number(data['current_train_score'] ?? 0);
  result.maxTrainScore = Number(data['max_train_score'] ?? 500);
  result.weeklyCocoonCnt = Number(data['weekly_cocoon_cnt'] ?? 0);
  result.weeklyCocoonLimit = Number(data['weekly_cocoon_limit'] ?? 3);
  return result;
}

/**
 * 解析绝区零便签数据
 */
function parseZZZData(data: Record<string, Object>): WidgetZZZData {
  const result = new WidgetZZZData();

  const energy = data['energy'] as Record<string, Object> | null;
  if (energy) {
    const progress = energy['progress'] as Record<string, Object> | null;
    if (progress) {
      result.currentEnergy = Number(progress['current'] ?? 0);
      result.maxEnergy = Number(progress['max'] ?? 240);
    }
    result.energyRecoverTime = Number(energy['restore'] ?? 0);
  }

  const vitality = data['vitality'] as Record<string, Object> | null;
  if (vitality) {
    result.currentVitality = Number(vitality['current'] ?? 0);
    result.maxVitality = Number(vitality['max'] ?? 400);
  }

  result.cardSign = String(data['card_sign'] ?? '');
  const vhsSale = data['vhs_sale'] as Record<string, Object> | null;
  if (vhsSale) {
    result.videoStoreState = String(vhsSale['sale_state'] ?? '');
  }

  return result;
}
