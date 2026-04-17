/**
 * ColdStartCookieChecker.test.ets
 *
 * 测试 ColdStartCookieChecker.needsColdStartRefresh() 纯函数的边界值，
 * 以及 BBSRepository.extractCookieField / replaceCookieField 的 round-trip 属性。
 */

import { describe, it, expect } from '@ohos/hypium';
import { ColdStartCookieChecker } from '../main/ets/cookie/ColdStartCookieChecker';
import { BBSRepository } from '../main/ets/repository/BBSRepository';

export default function coldStartCookieCheckerTest() {
  describe('ColdStartCookieChecker.needsColdStartRefresh', () => {

    // ── 边界值测试 ────────────────────────────────────────────────

    it('needsColdStartRefresh_over7Days_returnsTrue', 0, () => {
      const now = 1700000000;
      const updateTime = now - 604801; // 超过 7 天
      expect(ColdStartCookieChecker.needsColdStartRefresh(updateTime, now)).assertTrue();
    });

    it('needsColdStartRefresh_exactly7Days_returnsFalse', 0, () => {
      const now = 1700000000;
      const updateTime = now - 604800; // 恰好 7 天
      expect(ColdStartCookieChecker.needsColdStartRefresh(updateTime, now)).assertFalse();
    });

    it('needsColdStartRefresh_under7Days_returnsFalse', 0, () => {
      const now = 1700000000;
      const updateTime = now - 86400; // 1 天
      expect(ColdStartCookieChecker.needsColdStartRefresh(updateTime, now)).assertFalse();
    });

    it('needsColdStartRefresh_updateTimeZero_returnsTrue', 0, () => {
      const now = 1700000000;
      expect(ColdStartCookieChecker.needsColdStartRefresh(0, now)).assertTrue();
    });

    it('needsColdStartRefresh_nowLessThanUpdateTime_returnsFalse', 0, () => {
      // now < updateTime，时间差为负数，不触发刷新
      expect(ColdStartCookieChecker.needsColdStartRefresh(200, 100)).assertFalse();
    });

    // ── 属性测试：阈值判断（Property 1） ─────────────────────────
    // Feature: cookie-refresh-and-expiry, Property 1: 冷启动刷新阈值判断

    it('property1_thresholdJudgment_100iterations', 0, () => {
      const now = 1700000000;
      for (let i = 0; i < 100; i++) {
        const diff = Math.floor(Math.random() * 2000000); // 0 ~ 23 天
        const updateTime = now - diff;
        const result = ColdStartCookieChecker.needsColdStartRefresh(updateTime, now);
        const expected = diff > 604800;
        expect(result).assertEqual(expected);
      }
    });
  });

  describe('BBSRepository.extractCookieField / replaceCookieField', () => {

    it('extractCookieField_existingField_returnsValue', 0, () => {
      const cookie = 'account_id=123; stoken=abc; ltoken=xyz';
      expect(BBSRepository.extractCookieField(cookie, 'stoken')).assertEqual('abc');
    });

    it('extractCookieField_missingField_returnsEmpty', 0, () => {
      const cookie = 'account_id=123; ltoken=xyz';
      expect(BBSRepository.extractCookieField(cookie, 'stoken')).assertEqual('');
    });

    it('extractCookieField_emptyValue_returnsEmpty', 0, () => {
      const cookie = 'stoken=; ltoken=xyz';
      expect(BBSRepository.extractCookieField(cookie, 'stoken')).assertEqual('');
    });

    // ── 属性测试：Cookie 字段 round-trip（Property 2） ────────────
    // Feature: cookie-refresh-and-expiry, Property 2: Cookie 字段提取 round-trip

    it('property2_cookieFieldRoundTrip_100iterations', 0, () => {
      const fields = ['stoken', 'ltoken', 'cookie_token', 'account_id', 'mid'];
      const values = ['abc123', 'xyz456', 'v2_token_value', '182692936', 'mid_value'];
      for (let i = 0; i < 100; i++) {
        const fieldIdx = Math.floor(Math.random() * fields.length);
        const field = fields[fieldIdx];
        const value = values[fieldIdx];
        const cookie = `account_id=123; ${field}=${value}; ltoken=xyz`;
        const original = BBSRepository.extractCookieField(cookie, field);
        const replaced = BBSRepository.replaceCookieField(cookie, field, original);
        const extracted = BBSRepository.extractCookieField(replaced, field);
        expect(extracted).assertEqual(original);
      }
    });
  });
}
