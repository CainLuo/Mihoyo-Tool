/**
 * RetcodeRegistry.test.ets
 *
 * 锁定 retcode 的语义分类，重点防止两个历史回归：
 * - `-10001`（请求无效）被误判成登录失效
 * - `-100` 通过字符串匹配误命中 `-10001`
 */

import { describe, it, expect } from '@ohos/hypium';
import { MihoyoRetcode, RetcodeKind, RetcodeRegistry } from 'core';

export default function retcodeRegistryTest() {
  describe('RetcodeRegistry', () => {

    it('classifies_success', 0, () => {
      expect(RetcodeRegistry.isSuccess(MihoyoRetcode.SUCCESS)).assertTrue();
      expect(RetcodeRegistry.isSuccess(MihoyoRetcode.LOGIN_EXPIRED)).assertFalse();
      expect(RetcodeRegistry.kindOf(MihoyoRetcode.SUCCESS)).assertEqual(RetcodeKind.SUCCESS);
    });

    it('classifies_auth_expired_but_not_invalid_request', 0, () => {
      expect(RetcodeRegistry.isAuthExpired(MihoyoRetcode.LOGIN_EXPIRED)).assertTrue();
      expect(RetcodeRegistry.isAuthExpired(MihoyoRetcode.LOGIN_EXPIRED_PLEASE_LOGIN)).assertTrue();
      expect(RetcodeRegistry.isAuthExpired(MihoyoRetcode.LOGIN_EXPIRED_LEGACY)).assertTrue();
      // -10001 是 DS / Header / 参数错误，不是 Cookie 失效
      expect(RetcodeRegistry.isAuthExpired(MihoyoRetcode.INVALID_REQUEST)).assertFalse();
      expect(RetcodeRegistry.isInvalidRequest(MihoyoRetcode.INVALID_REQUEST)).assertTrue();
    });

    it('classifies_verification_and_fingerprint', 0, () => {
      expect(RetcodeRegistry.isVerificationRequired(MihoyoRetcode.CAPTCHA_REQUIRED)).assertTrue();
      expect(RetcodeRegistry.isVerificationRequired(MihoyoRetcode.CAPTCHA_REQUIRED_GAME_RECORD)).assertTrue();
      expect(RetcodeRegistry.isFingerprintInvalid(MihoyoRetcode.FINGERPRINT_INVALID)).assertTrue();
      expect(RetcodeRegistry.isFingerprintInvalid(MihoyoRetcode.FINGERPRINT_INVALID_ALT)).assertTrue();
      // 5003 / 10041 不是 Geetest
      expect(RetcodeRegistry.isVerificationRequired(MihoyoRetcode.FINGERPRINT_INVALID)).assertFalse();
      expect(RetcodeRegistry.isFingerprintInvalid(MihoyoRetcode.CAPTCHA_REQUIRED)).assertFalse();
    });

    it('classifies_role_and_login_flow_codes', 0, () => {
      expect(RetcodeRegistry.isRoleNotPublic(MihoyoRetcode.ROLE_NOT_PUBLIC)).assertTrue();
      expect(RetcodeRegistry.isRoleNotFound(MihoyoRetcode.ROLE_NOT_FOUND)).assertTrue();
      expect(RetcodeRegistry.isQrExpired(MihoyoRetcode.QR_EXPIRED)).assertTrue();
      expect(RetcodeRegistry.isMaintenance(MihoyoRetcode.MAINTENANCE)).assertTrue();
      expect(RetcodeRegistry.kindOf(MihoyoRetcode.CAPTCHA_INVALID)).assertEqual(RetcodeKind.CAPTCHA_INVALID);
    });

    it('unknown_code_preserves_original_code', 0, () => {
      const info = RetcodeRegistry.infoOf(-123456);
      expect(info.code).assertEqual(-123456);
      expect(info.kind).assertEqual(RetcodeKind.UNKNOWN);
      expect(RetcodeRegistry.isSuccess(-123456)).assertFalse();
    });

    it('message_matching_is_exact_for_negative_codes', 0, () => {
      // 不能因为 -100 是 -10001 的子串就把 -10001 判成登录失效
      expect(RetcodeRegistry.messageHasKind('retcode=-10001: invalid request', RetcodeKind.AUTH_EXPIRED)).assertFalse();
      expect(RetcodeRegistry.messageHasKind('retcode=-100: login expired', RetcodeKind.AUTH_EXPIRED)).assertTrue();
      expect(RetcodeRegistry.messageHasKind('retcode=1034: captcha', RetcodeKind.VERIFICATION_REQUIRED)).assertTrue();
      expect(RetcodeRegistry.messageHasKind('retcode=10035: captcha', RetcodeKind.VERIFICATION_REQUIRED)).assertTrue();
      expect(RetcodeRegistry.messageHasKind('retcode=5003: fp', RetcodeKind.FINGERPRINT_INVALID)).assertTrue();
    });

    it('retcode_from_message_parses_number', 0, () => {
      expect(RetcodeRegistry.retcodeFromMessage('foo retcode=-100 bar')).assertEqual(-100);
      expect(RetcodeRegistry.retcodeFromMessage('no retcode here')).assertNull();
    });

    it('region_restriction_requires_403_and_message', 0, () => {
      expect(RetcodeRegistry.isRegionRestricted(
        403,
        'Our services are not available in your country or region',
      )).assertTrue();
      expect(RetcodeRegistry.isRegionRestricted(403, 'Forbidden')).assertFalse();
      expect(RetcodeRegistry.isRegionRestricted(
        401,
        'Our services are not available in your country or region',
      )).assertFalse();
    });
  });
}
