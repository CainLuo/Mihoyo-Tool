import { describe, it, expect } from '@ohos/hypium';
import { ApiErrorHandler } from '../main/ets/base/utils/ApiErrorHandler';
import { AuthExpiredError, GeetestRequiredError } from '../main/ets/base/errors/ApiErrors';
import { RetcodeKind, RetcodeRegistry } from '../main/ets/base/errors/RetcodeRegistry';

function resp(retcode: number, message: string, data: object | null): Record<string, Object> {
  const result: Record<string, Object> = {};
  result['retcode'] = retcode;
  result['message'] = message;
  result['data'] = data as Object;
  return result;
}

function captureError(fn: () => void): Error | null {
  try {
    fn();
    return null;
  } catch (e) {
    return e as Error;
  }
}

export default function apiErrorHandlerTest() {
  describe('ApiErrorHandler', () => {

    it('retcode=0 且 data 为 null 时不抛错', 0, () => {
      const error = captureError(() => ApiErrorHandler.checkResponse(resp(0, 'ok', null)));
      expect(error === null).assertTrue();
    });

    it('retcode=0 且 data 非空时不抛错', 0, () => {
      const data: Record<string, Object> = { 'value': 1 };
      const error = captureError(() => ApiErrorHandler.checkResponse(resp(0, 'ok', data)));
      expect(error === null).assertTrue();
    });

    it('-100 抛 AuthExpiredError', 0, () => {
      const error = captureError(() => ApiErrorHandler.checkResponse(resp(-100, 'login expired', null)));
      expect(error instanceof AuthExpiredError).assertTrue();
    });

    it('10001 抛 AuthExpiredError', 0, () => {
      const error = captureError(() => ApiErrorHandler.checkResponse(resp(10001, 'please login', null)));
      expect(error instanceof AuthExpiredError).assertTrue();
    });

    it('-10001 是请求无效，不当作登录失效', 0, () => {
      const error = captureError(() => ApiErrorHandler.checkResponse(resp(-10001, 'invalid request', null)));
      expect(error instanceof AuthExpiredError).assertFalse();
      expect(error !== null).assertTrue();
    });

    it('1034 抛 GeetestRequiredError 并解析验证参数', 0, () => {
      const data: Record<string, Object> = {
        'gt': 'gt-token',
        'challenge': 'challenge-token',
        'new_captcha': 1,
        'risk_type': 'risk'
      };
      let geetest: GeetestRequiredError | null = null;
      try {
        ApiErrorHandler.checkResponse(resp(1034, 'need captcha', data));
      } catch (e) {
        geetest = e as GeetestRequiredError;
      }
      expect(geetest !== null).assertTrue();
      if (geetest !== null) {
        expect(geetest instanceof GeetestRequiredError).assertTrue();
        expect(geetest.geetestParams.gt).assertEqual('gt-token');
        expect(geetest.geetestParams.challenge).assertEqual('challenge-token');
        expect(geetest.geetestParams.new_captcha).assertEqual(1);
        expect(geetest.geetestParams.risk_type).assertEqual('risk');
      }
    });

    it('10035 无 data 时抛 GeetestRequiredError，参数为空', 0, () => {
      let geetest: GeetestRequiredError | null = null;
      try {
        ApiErrorHandler.checkResponse(resp(10035, 'need captcha', null));
      } catch (e) {
        geetest = e as GeetestRequiredError;
      }
      expect(geetest !== null).assertTrue();
      if (geetest !== null) {
        expect(geetest.geetestParams.gt).assertEqual('');
        expect(geetest.geetestParams.new_captcha).assertEqual(0);
      }
    });

    it('普通错误码且 data 为 null 时抛 Error', 0, () => {
      const error = captureError(() => ApiErrorHandler.checkResponse(resp(999999, 'boom', null)));
      expect(error !== null).assertTrue();
      if (error !== null) {
        expect(error instanceof AuthExpiredError).assertFalse();
        expect(error instanceof GeetestRequiredError).assertFalse();
        expect(error.message.indexOf('999999') >= 0).assertTrue();
      }
    });

    it('普通错误码但 data 非空时不抛错', 0, () => {
      const data: Record<string, Object> = { 'value': 1 };
      const error = captureError(() => ApiErrorHandler.checkResponse(resp(999999, 'boom', data)));
      expect(error === null).assertTrue();
    });

    it('isGeetestRequired 只认验证码错误码', 0, () => {
      expect(ApiErrorHandler.isGeetestRequired(1034)).assertTrue();
      expect(ApiErrorHandler.isGeetestRequired(10035)).assertTrue();
      expect(ApiErrorHandler.isGeetestRequired(0)).assertFalse();
      expect(ApiErrorHandler.isGeetestRequired(-100)).assertFalse();
    });

    it('isAuthExpired 只认登录失效错误码', 0, () => {
      expect(ApiErrorHandler.isAuthExpired(-100)).assertTrue();
      expect(ApiErrorHandler.isAuthExpired(10001)).assertTrue();
      expect(ApiErrorHandler.isAuthExpired(-111)).assertTrue();
      expect(ApiErrorHandler.isAuthExpired(-10001)).assertFalse();
      expect(ApiErrorHandler.isAuthExpired(0)).assertFalse();
    });

    it('RetcodeRegistry 对未知码返回 UNKNOWN', 0, () => {
      expect(RetcodeRegistry.kindOf(123456789)).assertEqual(RetcodeKind.UNKNOWN);
    });

  });
}
