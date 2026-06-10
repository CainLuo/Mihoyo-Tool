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

import { WIDGET_GAME_ID } from './WidgetUtils';
import { StaminaColorType, RecoveryTimeData, WidgetColors } from '../models/WidgetUIStates';

/**
 * 额外数据行（解析后的结果）
 */
export class ParsedExtraRow {
  label: string = '';
  value: string = '';
  valueColor: Resource = $r('app.color.gray_600');
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
   * 解析额外数据行
   */
  static parseExtraRows(rawJson: string, gameId: string): ParsedExtraRow[] {
    const rows: ParsedExtraRow[] = [];

    if (rawJson.length === 0) {
      return rows;
    }

    try {
      const data = JSON.parse(rawJson) as Record<string, Object>;

      if (gameId === WIDGET_GAME_ID.GENSHIN) {
        const expeditionMax = WidgetDataHelper.parseIntSafe(data['max_expedition_num'], 5);
        if (expeditionMax > 0) {
          const finished = WidgetDataHelper.calcFinishedExpeditions(data['expeditions']);
          rows.push(WidgetDataHelper.createExtraRow('expedition', `${finished}/${expeditionMax}`, WidgetColors.STARRAIL_PRIMARY));
        }

        const coinMax = WidgetDataHelper.parseIntSafe(data['max_home_coin'], 2400);
        if (coinMax > 0) {
          const coin = WidgetDataHelper.parseIntSafe(data['current_home_coin'], 0);
          rows.push(WidgetDataHelper.createExtraRow('home_coin', `${coin}/${coinMax}`, WidgetColors.STAMINA_MEDIUM));
        }

        const totalTaskNum = WidgetDataHelper.parseIntSafe(data['total_task_num'], 4);
        if (totalTaskNum > 0) {
          const finishedTaskNum = WidgetDataHelper.parseIntSafe(data['finished_task_num'], 0);
          const isExtraRewardReceived = data['is_extra_task_reward_received'] === true;
          const taskStatus = isExtraRewardReceived ? 'received' : `${finishedTaskNum}/${totalTaskNum}`;
          rows.push(WidgetDataHelper.createExtraRow('daily_task', taskStatus, WidgetColors.SUCCESS));
        }

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
      } else if (gameId === WIDGET_GAME_ID.STARRAIL) {
        const trainMax = WidgetDataHelper.parseIntSafe(data['max_train_score'], 500);
        if (trainMax > 0) {
          const train = WidgetDataHelper.parseIntSafe(data['current_train_score'], 0);
          rows.push(WidgetDataHelper.createExtraRow('train_score', `${train}/${trainMax}`, WidgetColors.STAMINA_MEDIUM));
        }

        const cocoonLimit = WidgetDataHelper.parseIntSafe(data['weekly_cocoon_limit'], 3);
        if (cocoonLimit > 0) {
          const cocoon = WidgetDataHelper.parseIntSafe(data['weekly_cocoon_cnt'], 0);
          rows.push(WidgetDataHelper.createExtraRow('cocoon', `${cocoon}/${cocoonLimit}`, WidgetColors.STARRAIL_PRIMARY));
        }

      } else if (gameId === WIDGET_GAME_ID.ZZZ) {
        const vitalityData = data['vitality'];
        if (vitalityData !== undefined && vitalityData !== null) {
          const vitalityObj = vitalityData as Record<string, Object>;
          const vitalityMax = WidgetDataHelper.parseIntSafe(vitalityObj['max'], 400);
          if (vitalityMax > 0) {
            const vitality = WidgetDataHelper.parseIntSafe(vitalityObj['current'], 0);
            rows.push(WidgetDataHelper.createExtraRow('vitality', `${vitality}/${vitalityMax}`, WidgetColors.ZZZ_PRIMARY));
          }
        }

        const cardSign = data['card_sign'];
        if (cardSign !== undefined && cardSign !== null) {
          const cardSignStr = String(cardSign);
          const isDone = cardSignStr === 'CardSignDone';
          rows.push(WidgetDataHelper.createExtraRow('card_sign', isDone ? 'done' : 'not_done', isDone ? WidgetColors.SUCCESS : WidgetColors.INCOMPLETE));
        }
      }
    } catch (_e) {
      // 解析失败返回空数组
    }

    return rows.slice(0, 4);
  }

  /**
   * 将标签 key 转换为资源文字
   * 在 ViewModel 中调用，组件直接使用返回值
   */
  static getExtraRowLabelResource(label: string): ResourceStr {
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
    if (label === 'train_score') {
      return $r('app.string.widget_train_score');
    }
    if (label === 'cocoon') {
      return $r('app.string.widget_cocoon');
    }
    if (label === 'vitality') {
      return $r('app.string.widget_vitality');
    }
    if (label === 'card_sign') {
      return $r('app.string.widget_card_sign');
    }
    // 未知 key 直接返回
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
    return value;
  }

  // ── 私有辅助方法 ─────────────────────────────────────────────────────

  private static createExtraRow(label: string, value: string, color: Resource): ParsedExtraRow {
    const row = new ParsedExtraRow();
    row.label = label;
    row.value = value;
    row.valueColor = color;
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
