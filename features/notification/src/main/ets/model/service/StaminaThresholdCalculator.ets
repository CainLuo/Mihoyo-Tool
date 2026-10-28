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
