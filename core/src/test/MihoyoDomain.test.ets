/**
 * MihoyoDomain.test.ets
 *
 * 锁定三环境域名契约：
 * - mock 全部指向本机 local-service，BBS_APIHUB 保留 /apihub
 * - uat / release 保持官方域名
 */

import { describe, it, expect } from '@ohos/hypium';
import { AppEnv } from '../main/ets/common/constants/AppEnv';
import { AppEnvManager } from '../main/ets/common/constants/AppEnvManager';
import { MihoyoDomain } from '../main/ets/base/network/MihoyoDomain';

function assertOfficialDomains(): void {
  expect(MihoyoDomain.TAKUMI_RECORD).assertEqual('https://api-takumi-record.mihoyo.com');
  expect(MihoyoDomain.TAKUMI).assertEqual('https://api-takumi.mihoyo.com');
  expect(MihoyoDomain.BBS).assertEqual('https://bbs-api.miyoushe.com');
  expect(MihoyoDomain.BBS_APIHUB).assertEqual('https://bbs-api.miyoushe.com/apihub');
  expect(MihoyoDomain.ACT_TAKUMI).assertEqual('https://act-api-takumi.mihoyo.com');
  expect(MihoyoDomain.PASSPORT).assertEqual('https://passport-api.mihoyo.com');
  expect(MihoyoDomain.PASSPORT_V4).assertEqual('https://passport-api-v4.mihoyo.com');
  expect(MihoyoDomain.HK4E_SDK).assertEqual('https://hk4e-sdk.mihoyo.com');
  expect(MihoyoDomain.PUBLIC_DATA_API).assertEqual('https://public-data-api.mihoyo.com');
}

export default function mihoyoDomainTest() {
  describe('MihoyoDomain', () => {

    it('mock_routesAllDomainsToLocalService', 0, () => {
      AppEnvManager.setup(AppEnv.MOCK);
      expect(MihoyoDomain.TAKUMI_RECORD).assertEqual('http://127.0.0.1:8787');
      expect(MihoyoDomain.TAKUMI).assertEqual('http://127.0.0.1:8787');
      expect(MihoyoDomain.BBS).assertEqual('http://127.0.0.1:8787');
      expect(MihoyoDomain.BBS_APIHUB).assertEqual('http://127.0.0.1:8787/apihub');
      expect(MihoyoDomain.ACT_TAKUMI).assertEqual('http://127.0.0.1:8787');
      expect(MihoyoDomain.PASSPORT).assertEqual('http://127.0.0.1:8787');
      expect(MihoyoDomain.PASSPORT_V4).assertEqual('http://127.0.0.1:8787');
      expect(MihoyoDomain.HK4E_SDK).assertEqual('http://127.0.0.1:8787');
      expect(MihoyoDomain.PUBLIC_DATA_API).assertEqual('http://127.0.0.1:8787');
      AppEnvManager.setup(AppEnv.UAT);
    });

    it('uat_keepsOfficialDomains', 0, () => {
      AppEnvManager.setup(AppEnv.UAT);
      assertOfficialDomains();
    });

    it('release_keepsOfficialDomains', 0, () => {
      AppEnvManager.setup(AppEnv.RELEASE);
      assertOfficialDomains();
      AppEnvManager.setup(AppEnv.UAT);
    });
  });
}
