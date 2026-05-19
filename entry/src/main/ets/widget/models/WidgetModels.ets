/**
 * WidgetModels.ets — Widget 数据模型
 *
 * 数据流：
 *   WidgetDataBuilder（主进程）→ JSON 字符串 → LocalStorage → @Entry 组件 → fromJson() → 子组件
 *
 * 每个游戏的数据序列化为一个 JSON 字符串，用单个 LocalStorage key 传递，
 * 避免在 @Entry 组件里平铺几十个 @LocalStorageProp 字段。
 */

/** WidgetGameData JSON 结构 */
interface WidgetGameDataJson {
  gameId?: string;
  currentStr?: string;
  maxStr?: string;
  secondsStr?: string;
  coinStr?: string;
  coinMaxStr?: string;
  taskStr?: string;
  taskTotalStr?: string;
  taskAllReceived?: string;
  transformerStr?: string;
  expeditionMaxStr?: string;
  expeditionFinishedStr?: string;
  reserveStr?: string;
  trainStr?: string;
  trainMaxStr?: string;
  cocoonStr?: string;
  cocoonLimitStr?: string;
  rogueStr?: string;
  rogueMaxStr?: string;
  vitalityStr?: string;
  vitalityMaxStr?: string;
  cardSign?: string;
  videoStore?: string;
}

/**
 * 单款游戏的体力和额外数据
 * 所有数值字段以字符串存储（来自 LocalStorage），-1 表示该字段不可用/不显示
 */
export class WidgetGameData {
  /** 游戏 ID（GameId 枚举值） */
  gameId: string = '';
  /** 体力当前值 */
  currentStr: string = '0';
  /** 体力上限 */
  maxStr: string = '200';
  /** 恢复剩余秒数 */
  secondsStr: string = '0';

  // ---- 原神专属 ----
  coinStr: string = '-1';
  coinMaxStr: string = '0';
  taskStr: string = '-1';
  taskTotalStr: string = '0';
  taskAllReceived: string = 'false';
  transformerStr: string = 'false';
  expeditionMaxStr: string = '5';
  /** 已完成的派遣数量 */
  expeditionFinishedStr: string = '0';

  // ---- 星铁专属 ----
  reserveStr: string = '-1';
  trainStr: string = '-1';
  trainMaxStr: string = '0';
  cocoonStr: string = '-1';
  cocoonLimitStr: string = '0';
  rogueStr: string = '-1';
  rogueMaxStr: string = '0';

  // ---- 绝区零专属 ----
  vitalityStr: string = '-1';
  vitalityMaxStr: string = '0';
  cardSign: string = '';
  videoStore: string = '';

  /**
   * 序列化为 JSON 字符串，用于写入 LocalStorage payload
   */
  toJson(): string {
    return JSON.stringify(this);
  }

  /**
   * 从 JSON 字符串反序列化，用于 @Entry 组件读取 @LocalStorageProp 后还原 model
   * 解析失败时返回默认空对象，不崩溃
   */
  static fromJson(json: string): WidgetGameData {
    const d = new WidgetGameData();
    if (json.length === 0) {
      return d;
    }
    try {
      const obj = JSON.parse(json) as WidgetGameDataJson;
      d.gameId = obj.gameId ?? '';
      d.currentStr = obj.currentStr ?? '0';
      d.maxStr = obj.maxStr ?? '200';
      d.secondsStr = obj.secondsStr ?? '0';
      d.coinStr = obj.coinStr ?? '-1';
      d.coinMaxStr = obj.coinMaxStr ?? '0';
      d.taskStr = obj.taskStr ?? '-1';
      d.taskTotalStr = obj.taskTotalStr ?? '0';
      d.taskAllReceived = obj.taskAllReceived ?? 'false';
      d.transformerStr = obj.transformerStr ?? 'false';
      d.expeditionMaxStr = obj.expeditionMaxStr ?? '5';
      d.expeditionFinishedStr = obj.expeditionFinishedStr ?? '0';
      d.reserveStr = obj.reserveStr ?? '-1';
      d.trainStr = obj.trainStr ?? '-1';
      d.trainMaxStr = obj.trainMaxStr ?? '0';
      d.cocoonStr = obj.cocoonStr ?? '-1';
      d.cocoonLimitStr = obj.cocoonLimitStr ?? '0';
      d.rogueStr = obj.rogueStr ?? '-1';
      d.rogueMaxStr = obj.rogueMaxStr ?? '0';
      d.vitalityStr = obj.vitalityStr ?? '-1';
      d.vitalityMaxStr = obj.vitalityMaxStr ?? '0';
      d.cardSign = obj.cardSign ?? '';
      d.videoStore = obj.videoStore ?? '';
    } catch (_e) {
      // 解析失败返回默认值，不崩溃
    }
    return d;
  }

  /**
   * 将本游戏数据写入 LocalStorage payload 对象（JSON 序列化方式）
   * @param obj  payload 目标对象
   * @param key  键名，如 'game0Json'
   */
  writeToPayload(obj: Record<string, string | number | boolean>, key: string): void {
    obj[key] = this.toJson();
  }
}

/**
 * 账号信息 + 最多 3 款游戏数据
 * 用于多游戏卡片（2×2/2×4/4×4 多游戏模式）
 */
export class WidgetAccountData {
  accountName: string = '';
  accountUid: string = '';
  gameCount: number = 0;
  games: WidgetGameData[] = [];
}

/**
 * 账号信息 + 单款游戏数据
 * 用于单游戏卡片（1×2 / 2×2 / 2×4 / 4×4 单游戏模式）
 */
export class WidgetSingleGameData {
  accountName: string = '';
  accountUid: string = '';
  game: WidgetGameData = new WidgetGameData();
}
