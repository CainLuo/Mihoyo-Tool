import { describe, it, expect } from '@ohos/hypium';
import { WidgetPayloadBuilder } from '../main/ets/model/service/WidgetPayloadBuilder';
import {
  WidgetAccountDataV2,
  WidgetDataStore,
  WidgetSlotRef,
  WidgetSlotSnapshot,
} from '../main/ets/model/WidgetDataStoreModels';
import { WidgetConfig, WidgetSize } from '../main/ets/model/WidgetConfigModels';

function addSlot(store: WidgetDataStore, accountId: string, roleId: string, gameId: string, nickname: string): void {
  let account = store.data[accountId];
  if (account === undefined) {
    account = new WidgetAccountDataV2();
    account.accountName = `name_${accountId}`;
    store.data[accountId] = account;
  }
  const slot = new WidgetSlotSnapshot();
  slot.gameId = gameId;
  slot.nickname = nickname;
  slot.server = 'cn_gf01';
  slot.rawJson = `{"role":"${roleId}"}`;
  slot.widgetRawJson = '';
  account.slots[roleId] = slot;
}

function makeStore(): WidgetDataStore {
  const store = new WidgetDataStore();
  addSlot(store, 'a1', 'r1', 'genshin', '原神角色');
  addSlot(store, 'a1', 'r2', 'starrail', '星铁角色');
  addSlot(store, 'a2', 'r3', 'zzz', '绝区零角色');
  return store;
}

function makeSlotRef(accountId: string, gameId: string, roleId: string): WidgetSlotRef {
  const ref = new WidgetSlotRef();
  ref.accountId = accountId;
  ref.gameId = gameId;
  ref.roleId = roleId;
  return ref;
}

export default function widgetPayloadBuilderTest() {
  describe('WidgetPayloadBuilder', () => {

    it('空 dataStore 返回空 accounts 与默认尺寸', 0, () => {
      const payload = WidgetPayloadBuilder.buildPayload(null, new WidgetDataStore());
      expect(payload.widgetSize).assertEqual(WidgetSize.SIZE_2X2);
      expect(payload.accounts.length).assertEqual(0);
    });

    it('用户配置的 slots 优先生效', 0, () => {
      const store = makeStore();
      const config = new WidgetConfig();
      config.size = WidgetSize.SIZE_2X2;
      config.slots = [
        makeSlotRef('a2', 'zzz', 'r3'),
        makeSlotRef('a1', 'genshin', 'r1'),
      ];

      const payload = WidgetPayloadBuilder.buildPayload(config, store);
      expect(payload.accounts.length).assertEqual(2);
      expect(payload.accounts[0].accountId).assertEqual('a2');
      expect(payload.accounts[0].games[0].gameId).assertEqual('zzz');
      expect(payload.accounts[0].games[0].roles[0].roleId).assertEqual('r3');
      expect(payload.accounts[1].accountId).assertEqual('a1');
    });

    it('同一账号的多个游戏合并到一个 AccountPayload', 0, () => {
      const store = makeStore();
      const config = new WidgetConfig();
      config.size = WidgetSize.SIZE_2X2;
      config.slots = [
        makeSlotRef('a1', 'genshin', 'r1'),
        makeSlotRef('a1', 'starrail', 'r2'),
      ];

      const payload = WidgetPayloadBuilder.buildPayload(config, store);
      expect(payload.accounts.length).assertEqual(1);
      expect(payload.accounts[0].games.length).assertEqual(2);
      expect(payload.accounts[0].games[0].roles.length).assertEqual(1);
      expect(payload.accounts[0].games[1].roles.length).assertEqual(1);
    });

    it('超出尺寸上限的 slots 被截断', 0, () => {
      const store = makeStore();
      const config = new WidgetConfig();
      config.size = WidgetSize.SIZE_1X2;
      config.slots = [
        makeSlotRef('a1', 'genshin', 'r1'),
        makeSlotRef('a1', 'starrail', 'r2'),
      ];

      const payload = WidgetPayloadBuilder.buildPayload(config, store);
      let roleCount = 0;
      for (let i = 0; i < payload.accounts.length; i++) {
        for (let j = 0; j < payload.accounts[i].games.length; j++) {
          roleCount += payload.accounts[i].games[j].roles.length;
        }
      }
      expect(roleCount).assertEqual(1);
    });

    it('没有用户配置时使用 formName 对应的预设', 0, () => {
      const store = makeStore();
      store.setPresetSlots('widget12', ['a1/r2']);
      const config = new WidgetConfig();
      config.size = WidgetSize.SIZE_1X2;
      config.formName = 'widget_1x2_genshin';

      const payload = WidgetPayloadBuilder.buildPayload(config, store);
      expect(payload.accounts.length).assertEqual(1);
      expect(payload.accounts[0].games[0].gameId).assertEqual('starrail');
      expect(payload.accounts[0].games[0].roles[0].roleId).assertEqual('r2');
    });

    it('无预设时按 1x2 formName 过滤游戏并取第一个账号', 0, () => {
      const store = new WidgetDataStore();
      addSlot(store, 'a1', 'r_sr', 'starrail', '星铁');
      addSlot(store, 'a1', 'r_gi', 'genshin', '原神');
      const config = new WidgetConfig();
      config.size = WidgetSize.SIZE_1X2;
      config.formName = 'widget_1x2_genshin';

      const payload = WidgetPayloadBuilder.buildPayload(config, store);
      expect(payload.accounts.length).assertEqual(1);
      expect(payload.accounts[0].games.length).assertEqual(1);
      expect(payload.accounts[0].games[0].gameId).assertEqual('genshin');
      expect(payload.accounts[0].games[0].roles[0].roleId).assertEqual('r_gi');
    });

    it('toLocalStorageRecord 返回 payload JSON 字符串', 0, () => {
      const store = makeStore();
      const config = new WidgetConfig();
      config.size = WidgetSize.SIZE_2X2;
      config.slots = [makeSlotRef('a1', 'genshin', 'r1')];

      const record = WidgetPayloadBuilder.buildPayload(config, store).toLocalStorageRecord();
      const json = record['payload'];
      expect(json.length > 0).assertTrue();
      expect(json.includes('"accounts"')).assertTrue();
      expect(json.includes('"r1"')).assertTrue();
    });

    it('buildForFormExtension 支持 1x2 / 2x4 / 4x4 / 未知尺寸', 0, async (done: Function) => {
      const store = makeStore();
      const one = await WidgetPayloadBuilder.buildForFormExtension('f1', '1x2', store);
      const two = await WidgetPayloadBuilder.buildForFormExtension('f2', '2x4', store);
      const four = await WidgetPayloadBuilder.buildForFormExtension('f3', '4x4', store);
      const unknown = await WidgetPayloadBuilder.buildForFormExtension('f4', 'unknown', store);
      expect(one['payload'].length > 0).assertTrue();
      expect(two['payload'].length > 0).assertTrue();
      expect(four['payload'].length > 0).assertTrue();
      expect(unknown['payload'].length > 0).assertTrue();
      done();
    });

  });
}
