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
 *
 * 注意：Widget 卡片渲染引擎对类型有限制，避免使用 union 类型。
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

  // 原神专属（无数据时为默认值，不使用 null）
  genshin: WidgetGenshinData = new WidgetGenshinData();

  // 星铁专属
  starrail: WidgetStarRailData = new WidgetStarRailData();

  // 绝区零专属
  zzz: WidgetZZZData = new WidgetZZZData();
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
    result.gameId = obj['gameId'] !== undefined ? (obj['gameId'] as string) : '';
    result.accountId = obj['accountId'] !== undefined ? (obj['accountId'] as string) : '';
    result.accountName = obj['accountName'] !== undefined ? (obj['accountName'] as string) : '';
    result.roleId = obj['roleId'] !== undefined ? (obj['roleId'] as string) : '';
    result.nickname = obj['nickname'] !== undefined ? (obj['nickname'] as string) : '';
    result.server = obj['server'] !== undefined ? (obj['server'] as string) : '';

    const rawJson = obj['rawJson'] !== undefined ? (obj['rawJson'] as string) : '';
    if (rawJson.length > 0) {
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
    // rawJson 存储的是 data 对象本身（不带 retcode/message 结构）
    // 降级逻辑：如果 resp['data'] 存在则使用，否则直接使用 resp
    let data: Record<string, Object> = resp;
    if (resp['data'] !== undefined && resp['data'] !== null) {
      data = resp['data'] as Record<string, Object>;
    }

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
  result.currentResin = data['current_resin'] !== undefined ? Number(data['current_resin']) : 0;
  result.maxResin = data['max_resin'] !== undefined ? Number(data['max_resin']) : 160;
  result.resinRecoveryTime = data['resin_recovery_time'] !== undefined ? parseInt(String(data['resin_recovery_time']), 10) : 0;
  result.currentHomeCoin = data['current_home_coin'] !== undefined ? Number(data['current_home_coin']) : 0;
  result.maxHomeCoin = data['max_home_coin'] !== undefined ? Number(data['max_home_coin']) : 2400;
  result.finishedTaskNum = data['finished_task_num'] !== undefined ? Number(data['finished_task_num']) : 0;
  result.totalTaskNum = data['total_task_num'] !== undefined ? Number(data['total_task_num']) : 4;
  result.remainResinDiscountNum = data['remain_resin_discount_num'] !== undefined ? Number(data['remain_resin_discount_num']) : 0;
  result.currentExpeditionNum = data['current_expedition_num'] !== undefined ? Number(data['current_expedition_num']) : 0;
  result.maxExpeditionNum = data['max_expedition_num'] !== undefined ? Number(data['max_expedition_num']) : 5;

  const transformer = data['transformer'];
  if (transformer !== undefined && transformer !== null) {
    const transformerObj = transformer as Record<string, Object>;
    result.transformerObtained = transformerObj['obtained'] !== undefined ? Boolean(transformerObj['obtained']) : false;
    const recoveryTime = transformerObj['recovery_time'];
    if (recoveryTime !== undefined && recoveryTime !== null) {
      const recoveryTimeObj = recoveryTime as Record<string, Object>;
      result.transformerReached = recoveryTimeObj['reached'] !== undefined ? Boolean(recoveryTimeObj['reached']) : false;
    }
  }

  return result;
}

/**
 * 解析星铁便签数据
 */
function parseStarRailData(data: Record<string, Object>): WidgetStarRailData {
  const result = new WidgetStarRailData();
  result.currentStamina = data['current_stamina'] !== undefined ? Number(data['current_stamina']) : 0;
  result.maxStamina = data['max_stamina'] !== undefined ? Number(data['max_stamina']) : 240;
  result.staminaRecoverTime = data['stamina_recover_time'] !== undefined ? Number(data['stamina_recover_time']) : 0;
  result.currentReserveStamina = data['current_reserve_stamina'] !== undefined ? Number(data['current_reserve_stamina']) : 0;
  result.currentTrainScore = data['current_train_score'] !== undefined ? Number(data['current_train_score']) : 0;
  result.maxTrainScore = data['max_train_score'] !== undefined ? Number(data['max_train_score']) : 500;
  result.weeklyCocoonCnt = data['weekly_cocoon_cnt'] !== undefined ? Number(data['weekly_cocoon_cnt']) : 0;
  result.weeklyCocoonLimit = data['weekly_cocoon_limit'] !== undefined ? Number(data['weekly_cocoon_limit']) : 3;
  return result;
}

/**
 * 解析绝区零便签数据
 */
function parseZZZData(data: Record<string, Object>): WidgetZZZData {
  const result = new WidgetZZZData();

  const energy = data['energy'];
  if (energy !== undefined && energy !== null) {
    const energyObj = energy as Record<string, Object>;
    const progress = energyObj['progress'];
    if (progress !== undefined && progress !== null) {
      const progressObj = progress as Record<string, Object>;
      result.currentEnergy = progressObj['current'] !== undefined ? Number(progressObj['current']) : 0;
      result.maxEnergy = progressObj['max'] !== undefined ? Number(progressObj['max']) : 240;
    }
    result.energyRecoverTime = energyObj['restore'] !== undefined ? Number(energyObj['restore']) : 0;
  }

  const vitality = data['vitality'];
  if (vitality !== undefined && vitality !== null) {
    const vitalityObj = vitality as Record<string, Object>;
    result.currentVitality = vitalityObj['current'] !== undefined ? Number(vitalityObj['current']) : 0;
    result.maxVitality = vitalityObj['max'] !== undefined ? Number(vitalityObj['max']) : 400;
  }

  result.cardSign = data['card_sign'] !== undefined ? String(data['card_sign']) : '';
  const vhsSale = data['vhs_sale'];
  if (vhsSale !== undefined && vhsSale !== null) {
    const vhsSaleObj = vhsSale as Record<string, Object>;
    result.videoStoreState = vhsSaleObj['sale_state'] !== undefined ? String(vhsSaleObj['sale_state']) : '';
  }

  return result;
}
