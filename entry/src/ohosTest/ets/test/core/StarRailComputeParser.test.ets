/**
 * StarRailComputeParser.test.ets
 *
 * 测试 StarRailComputeParser.parse() 的 JSON 解析逻辑。
 */

import { describe, it, expect } from '@ohos/hypium';
import { StarRailComputeParser, StarRailComputeData, StarRailMaterialItem } from '../main/ets/parsers/starrail/StarRailComputeParser';

// 标准测试 JSON（基于真实 API 响应结构）
const VALID_JSON = `{
  "avatar_consume": [
    {
      "item_id": "item_001",
      "item_name": "角色经验材料",
      "item_url": "https://example.com/avatar.png",
      "num": 100,
      "rarity": "4",
      "item_purpose": "角色升级"
    }
  ],
  "skill_consume": [
    {
      "item_id": "item_002",
      "item_name": "技能书",
      "item_url": "https://example.com/skill.png",
      "num": 50,
      "rarity": "3",
      "item_purpose": "技能升级"
    }
  ],
  "equipment_consume": [
    {
      "item_id": "item_003",
      "item_name": "光锥材料",
      "item_url": "https://example.com/equipment.png",
      "num": 30,
      "rarity": "4",
      "item_purpose": "光锥升级"
    }
  ],
  "user_owns_materials": {
    "item_001": 50,
    "item_002": 100,
    "item_003": 20
  }
}`;

const EMPTY_JSON = '{}';

const INVALID_JSON = 'not valid json';

const NULL_ARRAYS_JSON = `{
  "avatar_consume": null,
  "skill_consume": null,
  "equipment_consume": null,
  "user_owns_materials": null
}`;

export default function starRailComputeParserTest() {
  describe('StarRailComputeParser', () => {

    // ── 正常解析 ─────────────────────────────────────────────────

    it('parse_validJson_returnsData', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      expect(data).not.assertNull();
    });

    it('parse_avatarConsume_length', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume.length).assertEqual(1);
    });

    it('parse_avatarConsume_itemId', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].itemId).assertEqual('item_001');
    });

    it('parse_avatarConsume_itemName', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].itemName).assertEqual('角色经验材料');
    });

    it('parse_avatarConsume_num', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].num).assertEqual(100);
    });

    it('parse_avatarConsume_rarity', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].rarity).assertEqual('4');
    });

    it('parse_avatarConsume_itemPurpose', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].itemPurpose).assertEqual('角色升级');
    });

    it('parse_avatarConsume_idGetter', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].id).assertEqual('item_001');
    });

    it('parse_avatarConsume_nameGetter', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].name).assertEqual('角色经验材料');
    });

    it('parse_skillConsume_length', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      expect(data.skillConsume.length).assertEqual(1);
    });

    it('parse_equipmentConsume_length', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      expect(data.equipmentConsume.length).assertEqual(1);
    });

    it('parse_userOwnsMaterials_size', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      expect(data.userOwnsMaterials.size).assertEqual(3);
    });

    it('parse_userOwnsMaterials_item001', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      const count = data.userOwnsMaterials.get('item_001');
      expect(count).assertEqual(50);
    });

    it('parse_userOwnsMaterials_item002', 0, () => {
      const data = StarRailComputeParser.parse(VALID_JSON);
      const count = data.userOwnsMaterials.get('item_002');
      expect(count).assertEqual(100);
    });

    // ── 边界场景 ─────────────────────────────────────────────────

    it('parse_emptyJson_returnsDefault', 0, () => {
      const data = StarRailComputeParser.parse(EMPTY_JSON);
      expect(data.avatarConsume.length).assertEqual(0);
      expect(data.skillConsume.length).assertEqual(0);
      expect(data.equipmentConsume.length).assertEqual(0);
      expect(data.userOwnsMaterials.size).assertEqual(0);
    });

    it('parse_invalidJson_returnsDefault', 0, () => {
      const data = StarRailComputeParser.parse(INVALID_JSON);
      expect(data.avatarConsume.length).assertEqual(0);
      expect(data.skillConsume.length).assertEqual(0);
      expect(data.equipmentConsume.length).assertEqual(0);
    });

    it('parse_nullArrays_returnsEmpty', 0, () => {
      const data = StarRailComputeParser.parse(NULL_ARRAYS_JSON);
      expect(data.avatarConsume.length).assertEqual(0);
      expect(data.skillConsume.length).assertEqual(0);
      expect(data.equipmentConsume.length).assertEqual(0);
    });

  });
}
