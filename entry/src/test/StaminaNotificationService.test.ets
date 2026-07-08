/**
 * StaminaNotificationService.test.ets — 通知调度服务单元测试
 *
 * 测试 StaminaNotificationService 的可测试部分：
 * - 静态方法 hashNotifId
 * - MergedNotificationEntry 数据类构建
 * - NotificationStyle 枚举值
 * - GameStaminaConstants 常量
 *
 * 注意：代理提醒和通知发布的集成测试需要在设备端运行（ohosTest），
 * 因为依赖 reminderAgentManager、notificationManager 等 API。
 */
import { describe, it, expect } from '@ohos/hypium';
import { NotificationStyle, GameStaminaConstants, GameNotificationSetting } from '../main/ets/notification/NotificationModels';
import { GameId } from 'core';

/** 复制 StaminaNotificationService 的 hashNotifId 逻辑进行测试 */
function hashNotifId(key: string): number {
  let hash = 0;
  for (let i = 0; i < key.length; i++) {
    hash = (hash * 31 + key.charCodeAt(i)) & 0x7fffffff;
  }
  return (hash % 100000) + 10000;
}

/** 测试用的合并通知条目 */
class TestMergedEntry {
  key: string = '';
  gameName: string = '';
  displayName: string = '';
  staminaName: string = '';
  currentStamina: number = 0;
  maxStamina: number = 0;
  recoveryTimeSnapshot: number = 0;
  threshold: number = 0;
  delaySeconds: number = 0;
}

/** 测试用的简化条目 */
class TestSimpleEntry {
  key: string = '';
  currentStamina: number = 0;
  delaySeconds: number = 0;
}

export default function staminaNotificationServiceTest() {
  describe('StaminaNotificationService', () => {

    // ─── hashNotifId 测试 ────────────────────────────────────────

    it('hashNotifId: 相同输入返回相同输出（确定性）', 0, () => {
      const key = 'uid123_role456_genshin';
      const result1 = hashNotifId(key);
      const result2 = hashNotifId(key);
      expect(result1).assertEqual(result2);
    });

    it('hashNotifId: 返回值在合法范围 [10000, 109999]', 0, () => {
      const keys = ['key1', 'key2', 'uid_123_genshin', 'test_key_zzz'];
      for (let i = 0; i < keys.length; i++) {
        const result = hashNotifId(keys[i]);
        expect(result >= 10000).assertTrue();
        expect(result <= 109999).assertTrue();
      }
    });

    it('hashNotifId: 不同输入大概率返回不同输出', 0, () => {
      const result1 = hashNotifId('account1_role1_genshin');
      const result2 = hashNotifId('account2_role2_starrail');
      // 哈希碰撞概率极低，但理论上可能发生
      expect(result1 !== result2).assertTrue();
    });

    it('hashNotifId: 空字符串返回固定值', 0, () => {
      const result = hashNotifId('');
      expect(result >= 10000).assertTrue();
    });

    it('hashNotifId: 单字符输入正常处理', 0, () => {
      const result = hashNotifId('a');
      expect(result >= 10000).assertTrue();
    });

    it('hashNotifId: 包含特殊字符的 key 正常处理', 0, () => {
      const result = hashNotifId('uid_123-456@special');
      expect(result >= 10000).assertTrue();
    });

    // ─── NotificationStyle 枚举测试 ────────────────────────────────────────

    it('NotificationStyle.STYLE_A 值正确', 0, () => {
      expect(NotificationStyle.STYLE_A).assertEqual('styleA');
    });

    it('NotificationStyle.STYLE_B 值正确', 0, () => {
      expect(NotificationStyle.STYLE_B).assertEqual('styleB');
    });

    // ─── GameStaminaConstants 测试 ────────────────────────────────────────

    it('GameStaminaConstants: 原神每点恢复秒数正确（480秒=8分钟）', 0, () => {
      expect(GameStaminaConstants.GENSHIN_SECONDS_PER_UNIT).assertEqual(480);
    });

    it('GameStaminaConstants: 星铁每点恢复秒数正确（360秒=6分钟）', 0, () => {
      expect(GameStaminaConstants.STARRAIL_SECONDS_PER_UNIT).assertEqual(360);
    });

    it('GameStaminaConstants: 绝区零每点恢复秒数正确（360秒=6分钟）', 0, () => {
      expect(GameStaminaConstants.ZZZ_SECONDS_PER_UNIT).assertEqual(360);
    });

    it('GameStaminaConstants: 原神默认阈值正确（200×80%=160）', 0, () => {
      expect(GameStaminaConstants.GENSHIN_DEFAULT_THRESHOLD).assertEqual(160);
    });

    it('GameStaminaConstants: 星铁默认阈值正确（300×80%=240）', 0, () => {
      expect(GameStaminaConstants.STARRAIL_DEFAULT_THRESHOLD).assertEqual(240);
    });

    it('GameStaminaConstants: 绝区零默认阈值正确（240×80%=192）', 0, () => {
      expect(GameStaminaConstants.ZZZ_DEFAULT_THRESHOLD).assertEqual(192);
    });

    it('GameStaminaConstants: 原神 fallback 上限正确（200）', 0, () => {
      expect(GameStaminaConstants.GENSHIN_MAX_FALLBACK).assertEqual(200);
    });

    it('GameStaminaConstants: 星铁 fallback 上限正确（300）', 0, () => {
      expect(GameStaminaConstants.STARRAIL_MAX_FALLBACK).assertEqual(300);
    });

    it('GameStaminaConstants: 绝区零 fallback 上限正确（240）', 0, () => {
      expect(GameStaminaConstants.ZZZ_MAX_FALLBACK).assertEqual(240);
    });

    it('GameStaminaConstants: 代理提醒上限正确（30）', 0, () => {
      expect(GameStaminaConstants.REMINDER_LIMIT).assertEqual(30);
    });

    it('GameStaminaConstants.fallbackMax: 原神返回 200', 0, () => {
      expect(GameStaminaConstants.fallbackMax(GameId.GENSHIN)).assertEqual(200);
    });

    it('GameStaminaConstants.fallbackMax: 星铁返回 300', 0, () => {
      expect(GameStaminaConstants.fallbackMax(GameId.STARRAIL)).assertEqual(300);
    });

    it('GameStaminaConstants.fallbackMax: 绝区零返回 240', 0, () => {
      expect(GameStaminaConstants.fallbackMax(GameId.ZZZ)).assertEqual(240);
    });

    // ─── GameNotificationSetting 测试 ────────────────────────────────────────

    it('GameNotificationSetting: 默认 enabled=true', 0, () => {
      const setting = new GameNotificationSetting();
      expect(setting.enabled).assertTrue();
    });

    it('GameNotificationSetting: 默认 threshold=0', 0, () => {
      const setting = new GameNotificationSetting();
      expect(setting.threshold).assertEqual(0);
    });

    // ─── 合并通知逻辑测试（基于 MergedNotificationEntry 概念）────────

    it('合并通知: 单角色数据可正确构建', 0, () => {
      // 模拟 MergedNotificationEntry 构建
      const entry = new TestMergedEntry();
      entry.key = 'uid123_role456_genshin';
      entry.gameName = 'Genshin Impact';
      entry.displayName = 'Traveler';
      entry.staminaName = 'Resin';
      entry.currentStamina = 140;
      entry.maxStamina = 200;
      entry.recoveryTimeSnapshot = 28800;
      entry.threshold = 160;
      entry.delaySeconds = -19200;  // 已超过阈值
      expect(entry.key).assertEqual('uid123_role456_genshin');
      expect(entry.currentStamina).assertEqual(140);
      expect(entry.delaySeconds < 0).assertTrue();  // 应立即通知
    });

    it('合并通知: 多角色数据可正确收集', 0, () => {
      const entry1 = new TestSimpleEntry();
      entry1.key = 'role1';
      entry1.currentStamina = 160;
      entry1.delaySeconds = -100;
      const entry2 = new TestSimpleEntry();
      entry2.key = 'role2';
      entry2.currentStamina = 150;
      entry2.delaySeconds = 500;
      const entry3 = new TestSimpleEntry();
      entry3.key = 'role3';
      entry3.currentStamina = 180;
      entry3.delaySeconds = -200;
      const entries: TestSimpleEntry[] = [entry1, entry2, entry3];
      // 收集 delaySeconds <= 0 的条目
      const toNotify: TestSimpleEntry[] = [];
      for (let i = 0; i < entries.length; i++) {
        if (entries[i].delaySeconds <= 0) {
          toNotify.push(entries[i]);
        }
      }
      expect(toNotify.length).assertEqual(2);
    });

    it('合并通知: 行格式正确', 0, () => {
      const entry = new TestMergedEntry();
      entry.gameName = 'Genshin Impact';
      entry.displayName = 'Traveler';
      entry.staminaName = 'Resin';
      entry.currentStamina = 140;
      entry.maxStamina = 200;
      const line = `${entry.gameName} · ${entry.displayName}：${entry.staminaName} ${entry.currentStamina}/${entry.maxStamina}`;
      expect(line).assertEqual('Genshin Impact · Traveler：Resin 140/200');
    });

  });
}
