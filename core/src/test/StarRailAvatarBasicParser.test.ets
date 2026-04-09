/**
 * StarRailAvatarBasicParser.test.ets
 *
 * 测试 StarRailRepository.parseAvatarBasic 静态方法。
 * 重点验证 API 响应使用 avatar_list 字段（而非 list），确保解析正确。
 */
import { describe, it, expect } from '@ohos/hypium';
import { StarRailRepository } from '../main/ets/repository/StarRailRepository';

const TEST_ACCOUNT_ID = 30001;
const TEST_ROLE_UID = 'sr_parse_uid';

/** 构造标准 API 响应（使用 avatar_list 字段） */
function makeAvatarListResp(count: number): object {
  const list: object[] = [];
  for (let i = 0; i < count; i++) {
    list[list.length] = {
      id: 1000 + i,
      name: `角色_${i}`,
      rarity: i % 2 === 0 ? 5 : 4,
      level: 80,
      rank: i,
      base_type: 3,
      element: 'fire',
      element_id: 2,
      icon: `icon_${i}`,
      figure_path: `figure_${i}`,
      is_chosen: i === 0,
      equip: i === 0 ? {
        id: 23001,
        name: '光锥名称',
        level: 80,
        rank: 1,
        rarity: 5,
        icon: 'equip_icon_url_0'
      } : null
    };
  }
  const resp: Record<string, object> = {};
  resp['retcode'] = 0;
  resp['message'] = 'OK';
  const data: Record<string, object[]> = {};
  data['avatar_list'] = list;
  resp['data'] = data as unknown as object;
  return resp;
}

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
      expect(rows[0].equipIconUrl).assertEqual('equip_icon_url_0');
    });

    it('parse_avatarListField_equipNull_equipFieldsEmpty', 0, () => {
      const resp = makeAvatarListResp(2);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      // 第二个角色 equip=null
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

    it('parse_invalidJson_returnsEmptyArray', 0, () => {
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, 'not an object' as unknown as object);
      expect(rows.length).assertEqual(0);
    });

    it('parse_emptyObject_returnsEmptyArray', 0, () => {
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, {});
      expect(rows.length).assertEqual(0);
    });

    it('parse_rawJsonStoredCorrectly', 0, () => {
      const resp = makeAvatarListResp(1);
      const rows = StarRailRepository.parseAvatarBasic(TEST_ACCOUNT_ID, TEST_ROLE_UID, resp);
      // rawJson 应该是单个角色对象的 JSON，不是整个响应
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
