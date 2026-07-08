/**
 * WidgetDataHelper.ets — Widget 数据解析公共方法
 *
 * 职责：
 * - 解析 rawJson 数据为基础字段
 * - 计算体力状态
 * - 提供纯工具函数
 *
 * 设计原则：
 * - 只包含纯函数，无状态
 * - 只负责从 JSON 解析基础数据，不组装 UIState
 * - UIState 组装逻辑在各个 ViewModel 中完成
 * - 颜色判断由组件负责，这里只返回枚举类型
 */

import { Logger } from 'core';
import { WIDGET_GAME_ID } from './WidgetUtils';
import { WidgetExtraRowConfig } from './WidgetExtraRowConfig';
import {
  StaminaColorType,
  RecoveryTimeData,
  WidgetColors,
  ExpeditionAvatar
} from '../models/WidgetUIStates';

/**
 * 额外数据行（解析后的结果）
 */
export class ParsedExtraRow {
  label: string = '';
  value: string = '';
  valueColor: Resource = $r('app.color.gray_600');
  /** value 是否已经是最终显示格式，不需要再通过 getExtraRowValueDisplay() 转换 */
  isRawValue: boolean = false;
}

/**
 * Widget 数据解析辅助类
 * 所有方法都是静态方法，无状态
 */
export class WidgetDataHelper {
  /**
   * 格式化恢复时间
   * 返回解析后的小时和分钟数据，由组件决定如何显示
   */
  static formatRecoveryTime(seconds: number, isFull: boolean): RecoveryTimeData {
    const result = new RecoveryTimeData();

    if (isFull || seconds <= 0) {
      result.isFull = true;
      return result;
    }

    result.isFull = false;
    result.hours = Math.floor(seconds / 3600);
    result.minutes = Math.floor((seconds % 3600) / 60);

    return result;
  }

  /**
   * 计算体力进度比例
   */
  static calcStaminaRatio(current: number, max: number): number {
    return max > 0 ? current / max : 0;
  }

  /**
   * 判断体力是否已满
   */
  static calcIsFull(current: number, max: number, recoverySeconds: number): boolean {
    return recoverySeconds <= 0 && current >= max;
  }

  /**
   * 计算体力颜色类型
   * 组件根据返回的枚举值决定显示什么颜色
   */
  static calcStaminaColorType(current: number, max: number): StaminaColorType {
    const ratio = max > 0 ? current / max : 0;

    if (ratio <= 0.3) {
      return StaminaColorType.LOW;
    }
    if (ratio <= 0.7) {
      return StaminaColorType.MEDIUM;
    }
    return StaminaColorType.HIGH;
  }

  /**
   * 解析后备开拓力（星铁专用）
   */
  static parseReserveStamina(rawJson: string): string {
    if (rawJson.length === 0) {
      return '0';
    }

    try {
      const data = JSON.parse(rawJson) as Record<string, Object>;
      const val = data['current_reserve_stamina'];
      if (val !== undefined && val !== null) {
        return String(val);
      }
    } catch (_e) {
      // 解析失败返回默认值
    }

    return '0';
  }

  /**
   * 解析派遣角色头像列表（原神专用）
   * 返回最多 5 个派遣角色的完成状态
   * 
   * @param rawJson 原始 JSON 字符串
   * @param formImagesKeyPrefix formImages 中的 key 前缀（如 'exp_avatar'），用于生成 memory:// 路径
   */
  static parseExpeditions(rawJson: string, formImagesKeyPrefix: string = 'exp_avatar'): ExpeditionAvatar[] {
    const result: ExpeditionAvatar[] = [];

    if (rawJson.length === 0) {
      return result;
    }

    try {
      const data = JSON.parse(rawJson) as Record<string, Object>;
      const expeditions = data['expeditions'];

      if (!Array.isArray(expeditions)) {
        return result;
      }

      for (let i = 0; i < Math.min(expeditions.length, 5); i++) {
        const exp = expeditions[i] as Record<string, Object>;
        const avatar = new ExpeditionAvatar();
        avatar.avatarUrl = String(exp['avatar_side_icon'] ?? '');
        avatar.finished = exp['status'] === 'Finished';
        // 生成 memory:// 路径，与 formImages 中的 key 对应
        avatar.memoryUrl = `memory://${formImagesKeyPrefix}_${i}`;
        result.push(avatar);
      }
    } catch (_e) {
      // 解析失败返回空数组
    }

    return result;
  }

  /**
   * 解析额外数据行
   *
   * @param rawJson Note API 原始 JSON 字符串
   * @param widgetRawJson Widget API 原始 JSON 字符串（绝区零含 note_list 字段）
   * @param gameId 游戏 ID
   * @param maxRows 最多返回几行（0 = 不限制，默认 0）
   * @returns 额外数据行数组，已按优先级排序并截断
   *
   * 解析规则：
   * - 原神：解析原始字段，按优先级排序后截断
   * - 星铁：解析原始字段，按优先级排序后截断
   * - 绝区零：优先从 widgetRawJson 解析 note_list，降级从原始字段构建
   */
  static parseExtraRows(
    rawJson: string,
    widgetRawJson: string,
    gameId: string,
    maxRows: number = 0
  ): ParsedExtraRow[] {
    const rows: ParsedExtraRow[] = [];

    // DEBUG: 打印参数
    Logger.info('WIDGET', `[parseExtraRows] gameId=${gameId} rawJson.len=${rawJson.length} widgetRawJson.len=${widgetRawJson.length}`);

    if (rawJson.length === 0 && widgetRawJson.length === 0) {
      Logger.warn('WIDGET', `[parseExtraRows] both empty, returning empty array`);
      return rows;
    }

    try {
      if (gameId === WIDGET_GAME_ID.GENSHIN) {
        Logger.info('WIDGET', `[parseExtraRows] parsing genshin`);
        const emptyObj: Record<string, Object> = {};
        const data = rawJson.length > 0 ? JSON.parse(rawJson) as Record<string, Object> : emptyObj;
        WidgetDataHelper.parseGenshinExtraRows(data, rows);
      } else if (gameId === WIDGET_GAME_ID.STARRAIL) {
        Logger.info('WIDGET', `[parseExtraRows] parsing starrail`);
        const emptyObj: Record<string, Object> = {};
        const data = rawJson.length > 0 ? JSON.parse(rawJson) as Record<string, Object> : emptyObj;
        WidgetDataHelper.parseStarRailExtraRows(data, rows);
      } else if (gameId === WIDGET_GAME_ID.ZZZ) {
        Logger.info('WIDGET', `[parseExtraRows] parsing zzz`);
        WidgetDataHelper.parseZZZNoteList(rawJson, widgetRawJson, rows);
      }
      Logger.info('WIDGET', `[parseExtraRows] parsed ${rows.length} rows`);
    } catch (e) {
      Logger.error('WIDGET', `[parseExtraRows] failed: ${JSON.stringify(e)}`);
    }

    // 绝区零使用 note_list，已按米游社顺序排列，不需要排序
    if (gameId !== WIDGET_GAME_ID.ZZZ && rows.length > 0) {
      // 按优先级排序（原神/星铁）
      const priority = WidgetExtraRowConfig.getPriority(gameId);
      rows.sort((a, b) => {
        const pa = priority[a.label] ?? 99;
        const pb = priority[b.label] ?? 99;
        return pa - pb;
      });
    }

    // 截断到指定数量
    if (maxRows > 0 && rows.length > maxRows) {
      return rows.slice(0, maxRows);
    }

    return rows;
  }

  // ── 游戏特定的额外信息解析方法 ────────────────────────────────────────

  /**
   * 解析原神额外信息
   */
  private static parseGenshinExtraRows(data: Record<string, Object>, rows: ParsedExtraRow[]): void {
    // 探索派遣
    const expeditionMax = WidgetDataHelper.parseIntSafe(data['max_expedition_num'], 5);
    if (expeditionMax > 0) {
      const finished = WidgetDataHelper.calcFinishedExpeditions(data['expeditions']);
      rows.push(WidgetDataHelper.createExtraRow('expedition', `${finished}/${expeditionMax}`, WidgetColors.STARRAIL_PRIMARY));
    }

    // 洞天宝钱
    const coinMax = WidgetDataHelper.parseIntSafe(data['max_home_coin'], 2400);
    if (coinMax > 0) {
      const coin = WidgetDataHelper.parseIntSafe(data['current_home_coin'], 0);
      rows.push(WidgetDataHelper.createExtraRow('home_coin', `${coin}/${coinMax}`, WidgetColors.STAMINA_MEDIUM));
    }

    // 每日委托
    const totalTaskNum = WidgetDataHelper.parseIntSafe(data['total_task_num'], 4);
    if (totalTaskNum > 0) {
      const finishedTaskNum = WidgetDataHelper.parseIntSafe(data['finished_task_num'], 0);
      const isExtraRewardReceived = data['is_extra_task_reward_received'] === true;
      const taskStatus = isExtraRewardReceived ? 'received' : `${finishedTaskNum}/${totalTaskNum}`;
      rows.push(WidgetDataHelper.createExtraRow('daily_task', taskStatus, WidgetColors.SUCCESS));
    }

    // 参量质变仪
    const transformer = data['transformer'];
    if (transformer !== undefined && transformer !== null) {
      const transformerObj = transformer as Record<string, Object>;
      const obtained = transformerObj['obtained'] === true;
      const reached = transformerObj['reached'] === true;
      if (obtained) {
        const transformerStatus = reached ? 'ready' : 'not_ready';
        rows.push(WidgetDataHelper.createExtraRow('transformer', transformerStatus, reached ? WidgetColors.ZZZ_PRIMARY : WidgetColors.INCOMPLETE));
      }
    }

    // 周活跃进度
    const weekActiveProgress = data['week_active_progress'];
    if (weekActiveProgress !== undefined && weekActiveProgress !== null) {
      const progressObj = weekActiveProgress as Record<string, Object>;
      const progressCurrent = WidgetDataHelper.parseIntSafe(progressObj['progress_current'], 0);
      const progressTotal = WidgetDataHelper.parseIntSafe(progressObj['progress_total'], 5);
      if (progressTotal > 0) {
        rows.push(WidgetDataHelper.createExtraRow('week_active', `${progressCurrent}/${progressTotal}`, WidgetColors.STAMINA_MEDIUM));
      }
    }
  }

  /**
   * 解析星铁额外信息
   */
  private static parseStarRailExtraRows(data: Record<string, Object>, rows: ParsedExtraRow[]): void {
    // 委托派遣
    const expeditionNum = WidgetDataHelper.parseIntSafe(data['accepted_epedition_num'], 0);
    const expeditionTotal = WidgetDataHelper.parseIntSafe(data['total_expedition_num'], 4);
    if (expeditionTotal > 0) {
      rows.push(WidgetDataHelper.createExtraRow('starrail_expedition', `${expeditionNum}/${expeditionTotal}`, WidgetColors.STAMINA_MEDIUM));
    }

    // 每日实训（周期积分）
    const trainMax = WidgetDataHelper.parseIntSafe(data['max_train_score'], 500);
    if (trainMax > 0) {
      const train = WidgetDataHelper.parseIntSafe(data['current_train_score'], 0);
      rows.push(WidgetDataHelper.createExtraRow('train_score', `${train}/${trainMax}`, WidgetColors.STAMINA_MEDIUM));
    }

    // 模拟宇宙积分
    const rogueTournMax = WidgetDataHelper.parseIntSafe(data['rogue_tourn_weekly_max'], 0);
    const rogueTourn = WidgetDataHelper.parseIntSafe(data['rogue_tourn_weekly_cur'], 0);
    rows.push(WidgetDataHelper.createExtraRow('rogue_tourn', `${rogueTourn}/${rogueTournMax}`, WidgetColors.SUCCESS));
  }

  /**
   * 解析绝区零额外信息
   * 
   * 数据来源优先级：
   * 1. widgetRawJson 的 note_list 字段（Widget API 返回）
   * 2. 从 widgetRawJson 或 rawJson 的原始字段手动构建
   */
  private static parseZZZNoteList(rawJson: string, widgetRawJson: string, rows: ParsedExtraRow[]): void {
    Logger.info('WIDGET', `[parseZZZNoteList] rawJson.len=${rawJson.length} widgetRawJson.len=${widgetRawJson.length}`);
    
    // 优先使用 widgetRawJson 的 note_list（Widget API）
    if (widgetRawJson.length > 0) {
      try {
        const data = JSON.parse(widgetRawJson) as Record<string, Object>;
        const noteList = data['note_list'];
        
        Logger.info('WIDGET', `[parseZZZNoteList] noteList exists=${noteList !== undefined && noteList !== null}`);
        
        if (noteList !== undefined && noteList !== null && Array.isArray(noteList)) {
          Logger.info('WIDGET', `[parseZZZNoteList] noteList.length=${(noteList as Object[]).length}`);
          for (let i = 0; i < noteList.length; i++) {
            const item = noteList[i] as Record<string, Object>;
            const name = String(item['name'] ?? '');
            const value = String(item['value'] ?? '');
            const valueHighlight = item['value_highlight'] === true;

            if (name.length === 0 || value.length === 0) {
              continue;
            }

            const color = valueHighlight ? WidgetColors.ZZZ_PRIMARY : WidgetColors.STAMINA_MEDIUM;
            // 绝区零 note_list 的 value 已经是最终显示格式，标记为 "raw" 避免后续转换
            rows.push(WidgetDataHelper.createExtraRow(name, value, color, true));
          }
          Logger.info('WIDGET', `[parseZZZNoteList] parsed ${rows.length} rows from note_list`);
          return; // note_list 解析成功，直接返回
        }
      } catch (e) {
        Logger.error('WIDGET', `[parseZZZNoteList] widgetRawJson parse failed: ${JSON.stringify(e)}`);
      }
    }

    // 降级：从原始字段构建（优先用 widgetRawJson，其次用 rawJson）
    Logger.info('WIDGET', `[parseZZZNoteList] falling back to raw fields`);
    let data: Record<string, Object> = {};
    try {
      if (widgetRawJson.length > 0) {
        data = JSON.parse(widgetRawJson) as Record<string, Object>;
        Logger.info('WIDGET', `[parseZZZNoteList] using widgetRawJson for fallback`);
      } else if (rawJson.length > 0) {
        data = JSON.parse(rawJson) as Record<string, Object>;
        Logger.info('WIDGET', `[parseZZZNoteList] using rawJson for fallback`);
      }
    } catch (e) {
      Logger.error('WIDGET', `[parseZZZNoteList] fallback parse failed: ${JSON.stringify(e)}`);
      return;
    }

    // 录像店经营
    const vhsSale = data['vhs_sale'] as Record<string, Object> | null;
    if (vhsSale !== null && vhsSale !== undefined) {
      const saleState = String(vhsSale['sale_state'] ?? '');
      if (saleState.length > 0) {
        const displayValue = saleState === 'SaleStateDoing' ? '正在营业' : 
                             saleState === 'SaleStateDone' ? '已结算' : '未营业';
        rows.push(WidgetDataHelper.createExtraRow('录像店经营', displayValue, WidgetColors.STAMINA_MEDIUM, true));
      }
    }

    // 刮刮卡/签到
    const cardSign = String(data['card_sign'] ?? '');
    if (cardSign.length > 0) {
      const displayValue = cardSign === 'CardSignDone' ? '已完成' : '未完成';
      rows.push(WidgetDataHelper.createExtraRow('饼铺盲盒/刮刮卡', displayValue, WidgetColors.STAMINA_MEDIUM, true));
    }

    // 周常积分
    const weeklyTask = data['weekly_task'] as Record<string, Object> | null;
    if (weeklyTask !== null && weeklyTask !== undefined) {
      const curPoint = WidgetDataHelper.parseIntSafe(weeklyTask['cur_point'], 0);
      const maxPoint = WidgetDataHelper.parseIntSafe(weeklyTask['max_point'], 0);
      if (maxPoint > 0) {
        rows.push(WidgetDataHelper.createExtraRow('丽都周纪积分', `${curPoint}/${maxPoint}`, WidgetColors.ZZZ_PRIMARY, true));
      }
    }

    // 悬赏委托
    const bountyCommission = data['bounty_commission'] as Record<string, Object> | null;
    if (bountyCommission !== null && bountyCommission !== undefined) {
      const num = WidgetDataHelper.parseIntSafe(bountyCommission['num'], 0);
      const total = WidgetDataHelper.parseIntSafe(bountyCommission['total'], 0);
      if (total > 0) {
        rows.push(WidgetDataHelper.createExtraRow('悬赏委托', `${num}/${total}`, WidgetColors.ZZZ_PRIMARY, true));
      }
    }
  }

  /**
   * 将标签 key 转换为资源文字
   * 在 ViewModel 中调用，组件直接使用返回值
   *
   * 绝区零使用 note_list 中的中文名称，直接返回原值
   */
  static getExtraRowLabelResource(label: string): ResourceStr {
    // ── 原神 ──
    if (label === 'expedition') {
      return $r('app.string.widget_expedition');
    }
    if (label === 'home_coin') {
      return $r('app.string.widget_home_coin');
    }
    if (label === 'daily_task') {
      return $r('app.string.widget_daily_task');
    }
    if (label === 'transformer') {
      return $r('app.string.widget_transformer');
    }
    if (label === 'week_active') {
      return $r('app.string.widget_week_active');
    }

    // ── 星铁 ──
    if (label === 'starrail_expedition') {
      return $r('app.string.widget_expedition');
    }
    if (label === 'train_score') {
      return $r('app.string.widget_train_score');
    }
    if (label === 'rogue_tourn') {
      return $r('app.string.widget_rogue_tourn');
    }

    // ── 绝区零 ──
    // 绝区零使用 note_list 中的中文名称，直接返回
    // 如：'饼铺盲盒/刮刮卡/占卜'、'录像店经营'、'悬赏委托'、'丽都周纪积分'
    return label;
  }

  /**
   * 将值 key 转换为显示文字资源
   * 在 ViewModel 中调用，组件直接使用返回值
   */
  static getExtraRowValueDisplay(value: string): ResourceStr {
    if (value === 'done') {
      return $r('app.string.widget_card_done');
    }
    if (value === 'not_done') {
      return $r('app.string.widget_card_not_done');
    }
    if (value === 'received') {
      return $r('app.string.widget_task_received');
    }
    if (value === 'ready') {
      return $r('app.string.widget_transformer_ready');
    }
    if (value === 'not_ready') {
      return $r('app.string.widget_transformer_cooling');
    }
    if (value === 'open') {
      return $r('app.string.widget_store_open');
    }
    return value;
  }

  // ── 私有辅助方法 ─────────────────────────────────────────────────────

  private static createExtraRow(label: string, value: string, color: Resource, isRawValue: boolean = false): ParsedExtraRow {
    const row = new ParsedExtraRow();
    row.label = label;
    row.value = value;
    row.valueColor = color;
    row.isRawValue = isRawValue;
    return row;
  }

  private static parseIntSafe(val: Object | undefined, defaultVal: number): number {
    if (val === undefined || val === null) {
      return defaultVal;
    }
    const parsed = parseInt(String(val), 10);
    return isNaN(parsed) ? defaultVal : parsed;
  }

  private static calcFinishedExpeditions(expeditions: Object | undefined): number {
    if (expeditions === undefined || expeditions === null) {
      return 0;
    }

    if (!Array.isArray(expeditions)) {
      return 0;
    }

    let finished = 0;
    for (let i = 0; i < expeditions.length; i++) {
      const exp = expeditions[i] as Record<string, Object>;
      if (exp['status'] === 'Finished') {
        finished++;
      }
    }
    return finished;
  }
}
