/**
 * HeaderBuilder.test.ets
 *
 * 锁定公共 header 的 Profile 选择与合并规则：
 * - Profile 决定基础 header
 * - 请求特定 header 覆盖公共 header
 * - removeHeaders 在合并后删除
 * - 合并不修改调用方传入的 options
 */

import { describe, it, expect } from '@ohos/hypium';
import { HeaderContext, HeaderProfile, MihoyoHeaderBuilder } from '../main/ets/base/network/MihoyoHeaderBuilder';
import { RequestParams, RequestOptions } from '../main/ets/base/network/APIs';
import { HKey, HVal } from '../main/ets/base/network/MihoyoHeaderKey';
import { GameFpBiz } from '../main/ets/base/network/GameFpBiz';
import { MihoyoApiService } from '../main/ets/base/network/MihoyoApiService';

class HeaderProbeService extends MihoyoApiService {
  merge(
    context: HeaderContext,
    params?: RequestParams,
    body?: string,
    options?: RequestOptions,
  ): RequestOptions {
    return this.prepareOptions(context, params, body, options);
  }
}

export default function headerBuilderTest() {
  describe('HeaderBuilder', () => {

    it('buildFor_bbs_usesBbsProfile', 0, () => {
      const params = new RequestParams();
      const headers = MihoyoHeaderBuilder.buildFor(
        new HeaderContext(HeaderProfile.BBS, 'ltuid=1; ltoken=abc'),
        params,
      );
      expect(headers.get(HKey.REFERER)).assertEqual(HVal.APP_MIHOYO);
      expect(headers.get(HKey.ORIGIN)).assertEqual(HVal.APP_MIHOYO);
      expect(headers.get(HKey.CLIENT_TYPE)).assertEqual(HVal.CLIENT_IOS);
      expect(headers.get(HKey.COOKIE)).assertEqual('ltuid=1; ltoken=abc');
      expect(headers.has(HKey.DS)).assertTrue();
    });

    it('buildFor_pizzaRecord_appliesGameBizAndWidgetUserAgent', 0, () => {
      const headers = MihoyoHeaderBuilder.buildFor(
        new HeaderContext(
          HeaderProfile.PIZZA_RECORD,
          'stuid=1; stoken=abc',
          GameFpBiz.STARRAIL,
          'WidgetExtension/434',
        ),
      );
      expect(headers.get(HKey.USER_AGENT)).assertEqual('WidgetExtension/434');
      expect(headers.get(HKey.REFERER)).assertEqual(HVal.WEBSTATIC);
      expect(headers.has(HKey.DS)).assertTrue();
    });

    it('merge_specificHeaderOverridesCommonHeader', 0, () => {
      const options = new RequestOptions();
      options.extraHeaders.set(HKey.REFERER, 'https://override.example/');
      options.extraHeaders.set(HKey.SIGN_GAME, 'hk4e_cn');
      options.suppressGeetestReport = true;

      const merged = new HeaderProbeService().merge(
        new HeaderContext(HeaderProfile.SIGN, 'ltuid=1'),
        undefined,
        '{}',
        options,
      );

      expect(merged.extraHeaders.get(HKey.REFERER)).assertEqual('https://override.example/');
      expect(merged.extraHeaders.get(HKey.SIGN_GAME)).assertEqual('hk4e_cn');
      expect(merged.suppressGeetestReport).assertTrue();
      // 调用方 options 不被合并逻辑污染
      expect(options.extraHeaders.size).assertEqual(2);
      expect(options.extraHeaders.has(HKey.COOKIE)).assertFalse();
    });

    it('merge_removeHeadersDeletesCommonHeader', 0, () => {
      const options = new RequestOptions();
      options.removeHeaders = [HKey.DS];

      const merged = new HeaderProbeService().merge(
        new HeaderContext(HeaderProfile.CALCULATE, 'ltuid=1'),
        undefined,
        '{}',
        options,
      );

      expect(merged.extraHeaders.has(HKey.DS)).assertFalse();
      expect(merged.extraHeaders.get(HKey.CAL_TYPE)).assertEqual('0');
    });
  });
}
