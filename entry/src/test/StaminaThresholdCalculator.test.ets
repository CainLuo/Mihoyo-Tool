/**
 * StaminaThresholdCalculator.test.ets — 阈值计算逻辑单元测试
 *
 * 测试 StaminaThresholdCalculator 的纯函数方法，不依赖设备 API。
 */
import { describe, it, expect } from '@ohos/hypium';
import { StaminaThresholdCalculator } from '../main/ets/notification/StaminaThresholdCalculator';

export default function staminaThresholdCalculatorTest() {
  describe('StaminaThresholdCalculator', () => {

    // ─── calcDelaySeconds 测试 ────────────────────────────────────────

    it('calcDelaySeconds: recoveryTime=0, threshold<max 时返回负数（已达标）', 0, () => {
      const result = StaminaThresholdCalculator.calcDelaySeconds(
        0,    // recoveryTime: 已满值
        160,  // threshold
        200,  // maxStamina
        480   // secondsPerUnit
      );
      // delaySeconds = 0 - (200 - 160) * 480 = -19200
      expect(result).assertEqual(-19200);
    });

    it('calcDelaySeconds: recoveryTime 使体力恰好等于阈值时返回 0', 0, () => {
      // 阈值 160，max 200，达到 160 还需 (200-160)*480 = 19200 秒
      const result = StaminaThresholdCalculator.calcDelaySeconds(
        19200, // recoveryTime: 恰好达到阈值
        160,   // threshold
        200,   // maxStamina
        480    // secondsPerUnit
      );
      expect(result).assertEqual(0);
    });

    it('calcDelaySeconds: recoveryTime 使体力低于阈值时返回正数', 0, () => {
      // 阈值 160，max 200，当前体力 100（还需 48000 秒满值）
      // 达到阈值还需: 48000 - (200-160)*480 = 48000 - 19200 = 28800
      const result = StaminaThresholdCalculator.calcDelaySeconds(
        48000, // recoveryTime: 体力约 100
        160,   // threshold
        200,   // maxStamina
        480    // secondsPerUnit
      );
      expect(result).assertEqual(28800);
    });

    it('calcDelaySeconds: maxStamina=0 时返回 -1（无效值）', 0, () => {
      const result = StaminaThresholdCalculator.calcDelaySeconds(
        1000, // recoveryTime
        160,  // threshold
        0,    // maxStamina: 无效
        480   // secondsPerUnit
      );
      expect(result).assertEqual(-1);
    });

    it('calcDelaySeconds: secondsPerUnit=0 时返回 -1（无效值）', 0, () => {
      const result = StaminaThresholdCalculator.calcDelaySeconds(
        1000, // recoveryTime
        160,  // threshold
        200,  // maxStamina
        0     // secondsPerUnit: 无效
      );
      expect(result).assertEqual(-1);
    });

    it('calcDelaySeconds: 阈值等于上限时返回 recoveryTime', 0, () => {
      // threshold = maxStamina = 200，达到阈值还需 recoveryTime 秒
      const result = StaminaThresholdCalculator.calcDelaySeconds(
        3600, // recoveryTime
        200,  // threshold = maxStamina
        200,  // maxStamina
        480   // secondsPerUnit
      );
      // delaySeconds = 3600 - (200-200)*480 = 3600
      expect(result).assertEqual(3600);
    });

    it('calcDelaySeconds: 阈值大于上限时仍正常计算', 0, () => {
      // threshold=250 > maxStamina=200，公式仍成立
      const result = StaminaThresholdCalculator.calcDelaySeconds(
        3600, // recoveryTime
        250,  // threshold > maxStamina
        200,  // maxStamina
        480   // secondsPerUnit
      );
      // delaySeconds = 3600 - (200-250)*480 = 3600 + 24000 = 27600
      expect(result).assertEqual(27600);
    });

    // ─── parseGenshinRecoveryTime 测试 ────────────────────────────────

    it('parseGenshinRecoveryTime: 有效字符串 "22825" 返回整数', 0, () => {
      const result = StaminaThresholdCalculator.parseGenshinRecoveryTime('22825');
      expect(result).assertEqual(22825);
    });

    it('parseGenshinRecoveryTime: 数字类型直接返回', 0, () => {
      const result = StaminaThresholdCalculator.parseGenshinRecoveryTime(3600);
      expect(result).assertEqual(3600);
    });

    it('parseGenshinRecoveryTime: 空字符串返回 0', 0, () => {
      const result = StaminaThresholdCalculator.parseGenshinRecoveryTime('');
      expect(result).assertEqual(0);
    });

    it('parseGenshinRecoveryTime: 非数字字符串返回 0', 0, () => {
      const result = StaminaThresholdCalculator.parseGenshinRecoveryTime('invalid');
      expect(result).assertEqual(0);
    });

    it('parseGenshinRecoveryTime: NaN 数字返回 0', 0, () => {
      const result = StaminaThresholdCalculator.parseGenshinRecoveryTime(NaN);
      expect(result).assertEqual(0);
    });

    it('parseGenshinRecoveryTime: 负数字符串返回负数', 0, () => {
      const result = StaminaThresholdCalculator.parseGenshinRecoveryTime('-100');
      expect(result).assertEqual(-100);
    });

    // ─── shouldReschedule 测试 ────────────────────────────────────────

    it('shouldReschedule: 快照相等返回 false', 0, () => {
      const result = StaminaThresholdCalculator.shouldReschedule(1000, 1000);
      expect(result).assertFalse();
    });

    it('shouldReschedule: 快照不等返回 true', 0, () => {
      const result = StaminaThresholdCalculator.shouldReschedule(1000, 2000);
      expect(result).assertTrue();
    });

    it('shouldReschedule: 0 和 0 相等返回 false', 0, () => {
      const result = StaminaThresholdCalculator.shouldReschedule(0, 0);
      expect(result).assertFalse();
    });

    // ─── clampThreshold 测试 ────────────────────────────────────────

    it('clampThreshold: 值在范围内返回原值', 0, () => {
      const result = StaminaThresholdCalculator.clampThreshold(160, 200);
      expect(result).assertEqual(160);
    });

    it('clampThreshold: 值小于 1 返回 1', 0, () => {
      const result = StaminaThresholdCalculator.clampThreshold(0, 200);
      expect(result).assertEqual(1);
    });

    it('clampThreshold: 值为负数返回 1', 0, () => {
      const result = StaminaThresholdCalculator.clampThreshold(-10, 200);
      expect(result).assertEqual(1);
    });

    it('clampThreshold: 值大于 maxStamina 返回 maxStamina', 0, () => {
      const result = StaminaThresholdCalculator.clampThreshold(300, 200);
      expect(result).assertEqual(200);
    });

    it('clampThreshold: maxStamina=0 返回 1', 0, () => {
      const result = StaminaThresholdCalculator.clampThreshold(100, 0);
      expect(result).assertEqual(1);
    });

    it('clampThreshold: 值等于 1 返回 1（边界值）', 0, () => {
      const result = StaminaThresholdCalculator.clampThreshold(1, 200);
      expect(result).assertEqual(1);
    });

    it('clampThreshold: 值等于 maxStamina 返回 maxStamina（边界值）', 0, () => {
      const result = StaminaThresholdCalculator.clampThreshold(200, 200);
      expect(result).assertEqual(200);
    });

  });
}
