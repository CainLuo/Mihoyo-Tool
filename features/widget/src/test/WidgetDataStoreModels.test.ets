import { describe, it, expect } from '@ohos/hypium';
import {
  WidgetAccountDataV2,
  WidgetDataStore,
  WidgetSlotRef,
  WidgetSlotSnapshot,
} from '../main/ets/model/WidgetDataStoreModels';

function addSlot(store: WidgetDataStore, accountId: string, roleId: string, gameId: string, nickname: string): void {
  let account = store.data[accountId];
  if (account === undefined) {
    account = new WidgetAccountDataV2();
    account.accountName = accountId;
    store.data[accountId] = account;
  }
  const slot = new WidgetSlotSnapshot();
  slot.gameId = gameId;
  slot.nickname = nickname;
  slot.server = 'cn_gf01';
  slot.serverName = '天空岛';
  slot.level = 60;
  slot.rawJson = '{"current":1}';
  slot.widgetRawJson = '{"note_list":[]}';
  account.slots[roleId] = slot;
}

function makeStore(): WidgetDataStore {
  const store = new WidgetDataStore();
  addSlot(store, 'a1', 'r1', 'starrail', '星铁角色');
  addSlot(store, 'a1', 'r2', 'genshin', '原神角色');
  addSlot(store, 'a2', 'r3', 'zzz', '绝区零角色');
  return store;
}

export default function widgetDataStoreModelsTest() {
  describe('WidgetDataStoreModels', () => {

    it('WidgetSlotRef key 为 accountId/roleId', 0, () => {
      const ref = new WidgetSlotRef();
      ref.accountId = 'acc';
      ref.roleId = 'role';
      expect(ref.key).assertEqual('acc/role');
    });

    it('WidgetSlotRef JSON 往返', 0, () => {
      const ref = new WidgetSlotRef();
      ref.accountId = 'acc';
      ref.accountName = '账号';
      ref.gameId = 'genshin';
      ref.roleId = 'role';
      ref.nickname = '旅行者';
      ref.server = 'cn_gf01';

      const parsed = WidgetSlotRef.fromJson(ref.toJson());
      expect(parsed.accountId).assertEqual('acc');
      expect(parsed.accountName).assertEqual('账号');
      expect(parsed.gameId).assertEqual('genshin');
      expect(parsed.roleId).assertEqual('role');
      expect(parsed.nickname).assertEqual('旅行者');
      expect(parsed.server).assertEqual('cn_gf01');
      expect(parsed.key).assertEqual('acc/role');
    });

    it('getRole / getRoleByKey 命中与未命中', 0, () => {
      const store = makeStore();
      const role = store.getRole('a1', 'r2');
      expect(role === null).assertFalse();
      expect(role?.nickname).assertEqual('原神角色');

      expect(store.getRole('a1', 'missing') === null).assertTrue();
      expect(store.getRoleByKey('a1/r2')?.nickname).assertEqual('原神角色');
      expect(store.getRoleByKey('bad-key') === null).assertTrue();
      expect(store.getRoleByKey('a1/missing') === null).assertTrue();
    });

    it('firstAccountId / firstSlot 行为', 0, () => {
      const empty = new WidgetDataStore();
      expect(empty.firstAccountId === null).assertTrue();
      expect(empty.firstSlot === null).assertTrue();

      const store = makeStore();
      expect(store.firstAccountId).assertEqual('a1');
      expect(store.firstSlot === null).assertFalse();
      expect(store.hasData).assertTrue();
    });

    it('getSlotsByAccount 返回 accountId/roleId 列表', 0, () => {
      const store = makeStore();
      const keys = store.getSlotsByAccount('a1');
      expect(keys.length).assertEqual(2);
      expect(keys[0]).assertEqual('a1/r1');
      expect(keys[1]).assertEqual('a1/r2');
      expect(store.getSlotsByAccount('missing').length).assertEqual(0);
    });

    it('getAllSlotRefs 按 原神 → 星铁 → 绝区零 排序', 0, () => {
      const store = makeStore();
      const refs = store.getAllSlotRefs();
      expect(refs.length).assertEqual(3);
      expect(refs[0].gameId).assertEqual('genshin');
      expect(refs[1].gameId).assertEqual('starrail');
      expect(refs[2].gameId).assertEqual('zzz');
    });

    it('预设与已添加卡片配置互不干扰', 0, () => {
      const store = makeStore();
      store.setPresetSlots('widget22', ['a1/r1', 'a1/r2']);
      store.setFormConfig('123', ['a2/r3']);

      expect(store.getPresetSlots('widget22').length).assertEqual(2);
      expect(store.getFormConfig('123').length).assertEqual(1);
      expect(store.getPresetSlots('missing').length).assertEqual(0);
    });

    it('updateRoleRawJson 只更新已存在的角色', 0, () => {
      const store = makeStore();
      store.updateRoleRawJson('a1', 'r2', '{"updated":true}');
      expect(store.getRole('a1', 'r2')?.rawJson).assertEqual('{"updated":true}');
      store.updateRoleRawJson('a1', 'missing', '{"updated":true}');
      expect(store.getRole('a1', 'missing') === null).assertTrue();
    });

    it('toJson / fromJson 往返保留账号、角色与配置', 0, () => {
      const store = makeStore();
      store.setPresetSlots('widget22', ['a1/r1']);
      store.setFormConfig('123', ['a1/r2']);

      const parsed = WidgetDataStore.fromJson(store.toJson());
      expect(parsed.version).assertEqual(store.version);
      expect(parsed.hasData).assertTrue();
      expect(parsed.getAccountName('a1')).assertEqual('a1');
      expect(parsed.getRole('a1', 'r2')?.nickname).assertEqual('原神角色');
      expect(parsed.getRole('a1', 'r1')?.widgetRawJson).assertEqual('{"note_list":[]}');
      expect(parsed.getPresetSlots('widget22').length).assertEqual(1);
      expect(parsed.getFormConfig('123').length).assertEqual(1);
    });

    it('fromJson 空串 / 非法 JSON 返回空 store', 0, () => {
      const empty = WidgetDataStore.fromJson('');
      expect(empty.hasData).assertFalse();
      expect(empty.version).assertEqual(2);

      const invalid = WidgetDataStore.fromJson('{bad json');
      expect(invalid.hasData).assertFalse();
    });

  });
}
