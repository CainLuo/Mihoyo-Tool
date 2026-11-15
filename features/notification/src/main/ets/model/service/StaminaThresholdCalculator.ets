/**
 * StaminaThresholdCalculator.ets — 纯函数：阈值计算逻辑
 *
 * 不依赖任何设备 API，可在本地单元测试中直接测试。
 */

export class StaminaThresholdCalculator {
  /**
   * 计算体力达到阈值所需的剩余秒数。
   *
   * API 返回的 recoveryTime 是「距离满值还需多少秒」，因此：
   *   当前体力 = maxStamina - ceil(recoveryTime / secondsPerUnit)
   *   达到阈值还需秒数 = recoveryTime - (maxStamina - threshold) * secondsPerUnit
   *
   * 返回值 ≤ 0 表示当前体力已达到或超过阈值，应立即发送通知。
   *
   * @param recoveryTime API 返回的恢复至满值所需秒数（≥ 0）
   * @param threshold 用户设定的阈值（体力值）
   * @param maxStamina 该游戏体力上限
   * @param secondsPerUnit 每点体力恢复秒数
   */
  static calcDelaySeconds(
    recoveryTime: number,
    threshold: number,
    maxStamina: number,
    secondsPerUnit: number,
  ): number {
    if (maxStamina <= 0 || secondsPerUnit <= 0) {
      return -1;
    }
    // 达到阈值还需秒数 = recoveryTime - (maxStamina - threshold) * secondsPerUnit
    return recoveryTime - (maxStamina - threshold) * secondsPerUnit;
  }

  /**
   * 扣除快照生成至今已流逝的秒数。
   *
   * `recoveryTime` 是拉取那一刻的「距满值剩余秒数」。若直接用 DB 里的旧快照
   * （冷启动、30 分钟内跳过同步），延迟会多出「上次拉取距今」的时长，
   * 提醒因此推迟弹出。
   *
   * @param delaySeconds calcDelaySeconds 的结果
   * @param updateTime 快照数据更新时间（Unix 秒，0 表示未知）
   * @param nowSeconds 当前时间（Unix 秒）
   */
  static adjustDelayForElapsed(delaySeconds: number, updateTime: number, nowSeconds: number): number {
    if (delaySeconds <= 0 || updateTime <= 0) {
      return delaySeconds;
    }
    const elapsed = nowSeconds - updateTime;
    if (elapsed <= 0) {
      return delaySeconds;
    }
    return Math.max(0, delaySeconds - elapsed);
  }

  /**
   * 判断是否应发送「已达阈值」的即时通知（阈值跨越去重）。
   *
   * 即时通知代表「刚刚跨过阈值」这一事件，而不是「当前仍在阈值上」这一状态。
   * 标记里记录上次通知时的阈值：
   *   - 体力仍在阈值上且阈值未变 → 已通知过，跳过（避免每次同步都重复响铃）；
   *   - 用户改了阈值 → 视为新的通知条件，重新通知；
   *   - 体力回落到阈值以下 → 调用方清除标记，下次跨越时再通知。
   *
   * @param delaySeconds 距达到阈值的剩余秒数（≤ 0 表示已达标）
   * @param notifiedThreshold 上次发送即时通知时的阈值（-1 表示从未通知）
   * @param threshold 当前生效的阈值
   */
  static shouldNotifyImmediate(
    delaySeconds: number,
    notifiedThreshold: number,
    threshold: number,
  ): boolean {
    if (delaySeconds > 0) {
      return false;
    }
    return notifiedThreshold !== threshold;
  }

  /**
   * 解析原神 resin_recovery_time 字符串为整数秒数。
   * API 返回的是字符串（如 "22825"），需要 parseInt。
   */
  static parseGenshinRecoveryTime(raw: string | number): number {
    if (typeof raw === 'number') {
      return isNaN(raw) ? 0 : raw;
    }
    const parsed = parseInt(raw);
    return isNaN(parsed) ? 0 : parsed;
  }

  /**
   * 判断是否需要重新调度（Recovery_Time 快照发生变化）。
   * 相等时返回 false（不重新调度），不等时返回 true。
   */
  static shouldReschedule(oldSnapshot: number, newRecoveryTime: number): boolean {
    return oldSnapshot !== newRecoveryTime;
  }

  /**
   * 将阈值 clamp 到合法范围 [1, maxStamina]。
   */
  static clampThreshold(value: number, maxStamina: number): number {
    if (maxStamina <= 0) {
      return 1;
    }
    if (value < 1) {
      return 1;
    }
    if (value > maxStamina) {
      return maxStamina;
    }
    return value;
  }
}
