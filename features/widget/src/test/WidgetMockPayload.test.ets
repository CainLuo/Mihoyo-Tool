import { describe, it, expect } from '@ohos/hypium';
import { WidgetMockPayload } from '../main/ets/model/service/WidgetMockPayload';

interface MockRole {
  roleId: string;
  nickname: string;
  server: string;
  rawJson: string;
}

interface MockGame {
  gameId: string;
  roles: MockRole[];
}

interface MockAccount {
  accountId: string;
  accountName: string;
  games: MockGame[];
}

interface MockPayload {
  version: number;
  updatedAt: number;
  accounts: MockAccount[];
}

export default function widgetMockPayloadTest() {
  describe('WidgetMockPayload', () => {

    it('buildPayload 返回合法 JSON', 0, () => {
      const payload = JSON.parse(WidgetMockPayload.buildPayload()) as MockPayload;
      expect(payload.version).assertEqual(1);
      expect(payload.accounts.length).assertEqual(1);
      expect(payload.accounts[0].accountId).assertEqual('mock_account_1');
      expect(payload.accounts[0].games.length).assertEqual(1);
      expect(payload.accounts[0].games[0].gameId).assertEqual('genshin');
    });

    it('包含一个原神角色与完整便笺数据', 0, () => {
      const payload = JSON.parse(WidgetMockPayload.buildPayload()) as MockPayload;
      const role = payload.accounts[0].games[0].roles[0];
      expect(role.roleId).assertEqual('123456789');
      expect(role.nickname).assertEqual('旅行者');
      const note = JSON.parse(role.rawJson) as Record<string, Object>;
      expect(note['current_resin']).assertEqual(152);
      expect(note['max_resin']).assertEqual(200);
      expect(note['current_expedition_num']).assertEqual(5);
    });

    it('updatedAt 为秒级时间戳', 0, () => {
      const payload = JSON.parse(WidgetMockPayload.buildPayload()) as MockPayload;
      const now = Math.floor(Date.now() / 1000);
      expect(Math.abs(now - payload.updatedAt) < 60).assertTrue();
    });

  });
}
