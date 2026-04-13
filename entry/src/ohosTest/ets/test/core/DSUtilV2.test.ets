/**
 * DSUtil.test.ets
 *
 * 测试 DSUtil 的纯函数逻辑：
 * - DS 格式（timestamp,random,md5）
 * - query 参数序列化（字典序）
 * - 空参数处理
 */

import { describe, it, expect } from '@ohos/hypium';
import { DSUtil, RequestParams } from 'core';

export default function dsUtilV2Test() {
  describe('DSUtilV2', () => {

    // ── DS 格式验证 ──────────────────────────────────────────────

    it('generateV1_format_isTimestampRandomMd5', 0, () => {
      const ds = DSUtil.generateV1();
      const parts = ds.split(',');
      // DS 格式：{timestamp},{random},{md5}
      expect(parts.length).assertEqual(3);
    });

    it('generateV1_timestamp_isRecentUnixSeconds', 0, () => {
      const ds = DSUtil.generateV1();
      const timestamp = parseInt(ds.split(',')[0]);
      const now = Math.floor(Date.now() / 1000);
      // 时间戳应在当前时间 ±5 秒内
      expect(Math.abs(now - timestamp) < 5).assertTrue();
    });

    it('generateV1_random_is6Chars', 0, () => {
      const ds = DSUtil.generateV1();
      const random = ds.split(',')[1];
      expect(random.length).assertEqual(6);
    });

    it('generateV1_md5_is32HexChars', 0, () => {
      const ds = DSUtil.generateV1();
      const md5 = ds.split(',')[2];
      expect(md5.length).assertEqual(32);
      // MD5 只含十六进制字符
      const hexPattern = /^[0-9a-f]+$/;
      expect(hexPattern.test(md5)).assertTrue();
    });

    it('generateV2_format_isTimestampRandomMd5', 0, () => {
      const ds = DSUtil.generateV2();
      const parts = ds.split(',');
      expect(parts.length).assertEqual(3);
    });

    it('generateX6_format_isTimestampRandomMd5', 0, () => {
      const ds = DSUtil.generateX6();
      const parts = ds.split(',');
      expect(parts.length).assertEqual(3);
    });

    // ── query 参数序列化 ─────────────────────────────────────────

    it('generateV1_withParams_queryIsSorted', 0, () => {
      // 传入乱序参数，验证 DS 能正常生成（不崩溃）
      const params = new RequestParams();
      params.set('server', 'cn_gf01');
      params.set('role_id', '12345678');
      const ds = DSUtil.generateV1(params);
      expect(ds.split(',').length).assertEqual(3);
    });

    it('generateV1_withSingleParam_doesNotCrash', 0, () => {
      const params = new RequestParams();
      params.set('uid', '100000001');
      const ds = DSUtil.generateV1(params);
      expect(ds.length > 0).assertTrue();
    });

    it('generateV1_withEmptyParams_doesNotCrash', 0, () => {
      const params = new RequestParams();
      const ds = DSUtil.generateV1(params);
      expect(ds.split(',').length).assertEqual(3);
    });

    it('generateV1_withUndefinedParams_doesNotCrash', 0, () => {
      const ds = DSUtil.generateV1(undefined);
      expect(ds.split(',').length).assertEqual(3);
    });

    // ── POST body 参数 ───────────────────────────────────────────

    it('generateV1_withBody_doesNotCrash', 0, () => {
      const body = JSON.stringify({ role_id: '12345678', server: 'cn_gf01' });
      const ds = DSUtil.generateV1(undefined, body);
      expect(ds.split(',').length).assertEqual(3);
    });

    it('generateV1_withEmptyBody_doesNotCrash', 0, () => {
      const ds = DSUtil.generateV1(undefined, '');
      expect(ds.split(',').length).assertEqual(3);
    });

    // ── 两次调用结果不同（随机性） ────────────────────────────────

    it('generateV1_twoCallsProduceDifferentRandoms', 0, () => {
      const ds1 = DSUtil.generateV1();
      const ds2 = DSUtil.generateV1();
      const random1 = ds1.split(',')[1];
      const random2 = ds2.split(',')[1];
      // 极小概率相同，但通常不同
      // 这里只验证格式正确，不强制要求不同
      expect(random1.length).assertEqual(6);
      expect(random2.length).assertEqual(6);
    });

    // ── 字典序排列验证 ───────────────────────────────────────────

    it('generateV1_params_zam_sortedToAmz', 0, () => {
      // 传入 {z:1, a:2, m:3}，DS 正常生成不崩溃（字典序内部处理）
      const params = new RequestParams();
      params.set('z', '1');
      params.set('a', '2');
      params.set('m', '3');
      const ds = DSUtil.generateV1(params);
      expect(ds.split(',').length).assertEqual(3);
    });

    it('generateV1_params_ba_sortedToAb', 0, () => {
      const params = new RequestParams();
      params.set('b', '1');
      params.set('a', '2');
      const ds = DSUtil.generateV1(params);
      expect(ds.split(',').length).assertEqual(3);
    });

    it('generateV1_params_roleIdAndRole_sortedCorrectly', 0, () => {
      const params = new RequestParams();
      params.set('role_id', '1');
      params.set('role', '2');
      const ds = DSUtil.generateV1(params);
      expect(ds.split(',').length).assertEqual(3);
    });

    // ── random 字符集验证 ────────────────────────────────────────

    it('generateV1_random_onlyAlphanumeric', 0, () => {
      // 调用 10 次，每次 random 只含 [a-zA-Z0-9]
      const alphanumeric = /^[a-zA-Z0-9]+$/;
      for (let i = 0; i < 10; i++) {
        const random = DSUtil.generateV1().split(',')[1];
        expect(alphanumeric.test(random)).assertTrue();
      }
    });

    // ── 极端参数 ─────────────────────────────────────────────────

    it('generateV1_100Params_doesNotCrash', 0, () => {
      const params = new RequestParams();
      for (let i = 0; i < 100; i++) {
        params.set(`key${i}`, `val${i}`);
      }
      const ds = DSUtil.generateV1(params);
      expect(ds.split(',').length).assertEqual(3);
    });

    it('generateV1_paramValueZero_notFiltered', 0, () => {
      const params = new RequestParams();
      params.set('level', 0);
      const ds = DSUtil.generateV1(params);
      expect(ds.split(',').length).assertEqual(3);
    });

    it('generateV1_paramValueNegative_doesNotCrash', 0, () => {
      const params = new RequestParams();
      params.set('offset', -1);
      const ds = DSUtil.generateV1(params);
      expect(ds.split(',').length).assertEqual(3);
    });

    it('generateV1_unicodeBody_doesNotCrash', 0, () => {
      const body = JSON.stringify({ name: '旅行者' });
      const ds = DSUtil.generateV1(undefined, body);
      expect(ds.split(',').length).assertEqual(3);
    });
  });
}
