/**
 * StarRailAvatarBasicParser.test.ets
 *
 * 测试 StarRailRepository.parseAvatarBasic 静态方法。
 * 重点验证 API 响应使用 avatar_list 字段（而非 list），确保解析正确。
 */
import { describe, it, expect } from '@ohos/hypium';
import { StarRailRepository, StarRailEquipItem, StarRailAvatarItem, StarRailAvatarListData } from 'core';

const TEST_ACCOUNT_ID = '30001';
const TEST_ROLE_UID = 'sr_parse_uid';

/** 构造单个装备对象 */
function makeEquip(id: number): StarRailEquipItem {
  const e = new StarRailEquipItemImpl();
  e.id = id;
  e.name = '光锥名称';
  e.level = 80;
  e.rank = 1;
  e.rarity = 5;
  e.icon = `equip_icon_url_${id}`;
  return e;
}

/** 构造单个角色对象 */
function makeAvatarItem(index: number): StarRailAvatarItem {
  const item = new StarRailAvatarItemImpl();
  item.id = 1000 + index;
  item.name = `角色_${index}`;
  item.rarity = index % 2 === 0 ? 5 : 4;
  item.level = 80;
  item.rank = index;
  item.base_type = 3;
  item.element = 'fire';
  item.element_id = 2;
  item.icon = `icon_${index}`;
  item.figure_path = `figure_${index}`;
  item.is_chosen = index === 0;
  item.equip = index === 0 ? makeEquip(23001) : null;
  return item;
}

/** 构造标准 API 响应（使用 avatar_list 字段） */
function makeAvatarListResp(count: number): object {
  const list: StarRailAvatarItem[] = [];
  for (let i = 0; i < count; i++) {
    list[list.length] = makeAvatarItem(i);
  }
  const data = new StarRailAvatarListDataImpl();
  data.avatar_list = list;
  data.list = [];
  const resp = new AvatarListRespImpl();
  resp.data = data;
  return resp;
}

// ─── 测试用 class 实现（ArkTS 严格模式要求对象字面量对应 class）────

class StarRailEquipItemImpl implements StarRailEquipItem {
  id: number = 0;
  name: string = '';
  level: number = 0;
  rank: number = 0;
  rarity: number = 0;
  icon: string = '';
}

class StarRailAvatarItemImpl implements StarRailAvatarItem {
  id: number = 0;
  name: string = '';
  rarity: number = 0;
  level: number = 0;
  rank: number = 0;
  base_type: number = 0;
  element: string = '';
  element_id: number = 0;
  icon: string = '';
  figure_path: string = '';
  is_chosen: boolean = false;
  equip: StarRailEquipItem | null = null;
}

class StarRailAvatarListDataImpl implements StarRailAvatarListData {
  list: StarRailAvatarItem[] = [];
  avatar_list: StarRailAvatarItem[] = [];
}

class AvatarListRespImpl {
  retcode: number = 0;
  message: string = 'OK';
  data: StarRailAvatarListData = new StarRailAvatarListDataImpl();
}

// ─── 测试套件 ─────────────────────────────────────────────────────

export default function starRailAvatarBasicParserTest() {
  describe('StarRailRepository.parseAvatarBasic', () => {

    it('parse_avatarListField_returnsCorrectCount', 0, () => {
      const resp = makeAvatarListResp(3);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      expect(rows.length).assertEqual(3);
    });

    it('parse_avatarListField_accountIdAndRoleUidCorrect', 0, () => {
      const resp = makeAvatarListResp(1);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      expect(rows.length).assertEqual(1);
      expect(rows[0].accountId).assertEqual(TEST_ACCOUNT_ID);
      expect(rows[0].roleUid).assertEqual(TEST_ROLE_UID);
    });

    it('parse_avatarListField_avatarIdIsString', 0, () => {
      const resp = makeAvatarListResp(1);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      expect(rows[0].avatarId).assertEqual('1000');
    });

    it('parse_avatarListField_nameCorrect', 0, () => {
      const resp = makeAvatarListResp(1);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      expect(rows[0].name).assertEqual('角色_0');
    });

    it('parse_avatarListField_rarityCorrect', 0, () => {
      const resp = makeAvatarListResp(2);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      expect(rows[0].rarity).assertEqual(5);
      expect(rows[1].rarity).assertEqual(4);
    });

    it('parse_avatarListField_equipNotNull_equipFieldsCorrect', 0, () => {
      const resp = makeAvatarListResp(1);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      expect(rows[0].equipId).assertEqual('23001');
      expect(rows[0].equipName).assertEqual('光锥名称');
      expect(rows[0].equipLevel).assertEqual(80);
      expect(rows[0].equipRank).assertEqual(1);
      expect(rows[0].equipRarity).assertEqual(5);
      expect(rows[0].equipIconUrl).assertEqual('equip_icon_url_23001');
    });

    it('parse_avatarListField_equipNull_equipFieldsEmpty', 0, () => {
      const resp = makeAvatarListResp(2);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      expect(rows[1].equipId).assertEqual('');
      expect(rows[1].equipName).assertEqual('');
      expect(rows[1].equipLevel).assertEqual(0);
      expect(rows[1].equipIconUrl).assertEqual('');
    });

    it('parse_avatarListField_elementStringCorrect', 0, () => {
      const resp = makeAvatarListResp(1);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      expect(rows[0].element).assertEqual('fire');
    });

    it('parse_avatarListField_isChosenTrue_isChosen1', 0, () => {
      const resp = makeAvatarListResp(2);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      expect(rows[0].isChosen).assertEqual(1);
      expect(rows[1].isChosen).assertEqual(0);
    });

    it('parse_emptyAvatarList_returnsEmptyArray', 0, () => {
      const resp = makeAvatarListResp(0);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      expect(rows.length).assertEqual(0);
    });

    it('parse_emptyObject_returnsEmptyArray', 0, () => {
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, new AvatarListRespImpl());
      expect(rows.length).assertEqual(0);
    });

    it('parse_rawJsonStoredCorrectly', 0, () => {
      const resp = makeAvatarListResp(1);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      const parsed = JSON.parse(rows[0].rawJson) as Record<string, number>;
      expect(parsed['id']).assertEqual(1000);
    });

    it('parse_updateTimeIsSet', 0, () => {
      const before = Math.floor(Date.now() / 1000);
      const resp = makeAvatarListResp(1);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      const after = Math.floor(Date.now() / 1000);
      expect(rows[0].updateTime >= before).assertTrue();
      expect(rows[0].updateTime <= after).assertTrue();
    });

  });
}
