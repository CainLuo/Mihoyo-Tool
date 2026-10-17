/**
 * ZZZComputeParser.test.ets
 *
 * 测试 ZZZComputeParser.parse() 的 JSON 解析逻辑。
 */

import { describe, it, expect } from '@ohos/hypium';
import { ZZZComputeParser, ZZZComputeData, ZZZMaterialItem } from '../main/ets/parsers/zzz/ZZZComputeParser';

// 标准测试 JSON（基于真实 API 响应结构）
const VALID_JSON = `{
  "avatar_consume": [
    {
      "id": "item_001",
      "name": "代理人经验材料",
      "icon": "https://example.com/avatar.png",
      "num": 100,
      "rarity": "A",
      "type": 1
    }
  ],
  "skill_consume": [
    {
      "id": 2001,
      "name": "技能芯片",
      "icon": "https://example.com/skill.png",
      "num": 50,
      "rarity": "S",
      "type": 2
    }
  ],
  "weapon_consume": [
    {
      "id": "item_003",
      "name": "音擎材料",
      "icon": "https://example.com/weapon.png",
      "num": 30,
      "rarity": "B",
      "type": 3
    }
  ],
  "skills_consume": [
    {
      "skill_info": {
        "id": 101,
        "level_current": 1,
        "level_target": 12
      },
      "consume_list": [
        {
          "id": "skill_item_001",
          "name": "技能材料",
          "icon": "https://example.com/skill_item.png",
          "num": 10,
          "rarity": "A",
          "type": 2
        }
      ]
    }
  ],
  "user_owns_materials": {
    "item_001": 50,
    "item_002": 100,
    "item_003": 20
  },
  "coin_id": 10
}`;

const EMPTY_JSON = '{}';

const INVALID_JSON = 'not valid json';

const NULL_ARRAYS_JSON = `{
  "avatar_consume": null,
  "skill_consume": null,
  "weapon_consume": null,
  "skills_consume": null,
  "user_owns_materials": null
}`;

export default function zzzComputeParserTest() {
  describe('ZZZComputeParser', () => {

    // ── 正常解析 ─────────────────────────────────────────────────

    it('parse_validJson_returnsData', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data).not.assertNull();
    });

    it('parse_avatarConsume_length', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume.length).assertEqual(1);
    });

    it('parse_avatarConsume_id', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].id).assertEqual('item_001');
    });

    it('parse_avatarConsume_name', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].name).assertEqual('代理人经验材料');
    });

    it('parse_avatarConsume_num', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].num).assertEqual(100);
    });

    it('parse_avatarConsume_rarity', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].rarity).assertEqual('A');
    });

    it('parse_avatarConsume_type', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].type).assertEqual(1);
    });

    it('parse_avatarConsume_iconUrl', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.avatarConsume[0].iconUrl).assertEqual('https://example.com/avatar.png');
    });

    it('parse_skillConsume_idFromString', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.skillConsume.length).assertEqual(1);
      expect(data.skillConsume[0].id).assertEqual('2001');
    });

    it('parse_weaponConsume_length', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.weaponConsume.length).assertEqual(1);
    });

    it('parse_skillsConsume_length', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.skillsConsume.length).assertEqual(1);
    });

    it('parse_skillsConsume_skillId', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.skillsConsume[0].skillId).assertEqual(101);
    });

    it('parse_skillsConsume_levelCurrent', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.skillsConsume[0].levelCurrent).assertEqual(1);
    });

    it('parse_skillsConsume_levelTarget', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.skillsConsume[0].levelTarget).assertEqual(12);
    });

    it('parse_skillsConsume_consumeList', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.skillsConsume[0].consumeList.length).assertEqual(1);
    });

    it('parse_userOwnsMaterials_size', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.userOwnsMaterials.size).assertEqual(3);
    });

    it('parse_userOwnsMaterials_item001', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      const count = data.userOwnsMaterials.get('item_001');
      expect(count).assertEqual(50);
    });

    it('parse_coinId', 0, () => {
      const data = ZZZComputeParser.parse(VALID_JSON);
      expect(data.coinId).assertEqual(10);
    });

    // ── 边界场景 ─────────────────────────────────────────────────

    it('parse_emptyJson_returnsDefault', 0, () => {
      const data = ZZZComputeParser.parse(EMPTY_JSON);
      expect(data.avatarConsume.length).assertEqual(0);
      expect(data.skillConsume.length).assertEqual(0);
      expect(data.weaponConsume.length).assertEqual(0);
      expect(data.skillsConsume.length).assertEqual(0);
      expect(data.userOwnsMaterials.size).assertEqual(0);
    });

    it('parse_invalidJson_returnsDefault', 0, () => {
      const data = ZZZComputeParser.parse(INVALID_JSON);
      expect(data.avatarConsume.length).assertEqual(0);
      expect(data.skillConsume.length).assertEqual(0);
      expect(data.weaponConsume.length).assertEqual(0);
    });

    it('parse_nullArrays_returnsEmpty', 0, () => {
      const data = ZZZComputeParser.parse(NULL_ARRAYS_JSON);
      expect(data.avatarConsume.length).assertEqual(0);
      expect(data.skillConsume.length).assertEqual(0);
      expect(data.weaponConsume.length).assertEqual(0);
      expect(data.skillsConsume.length).assertEqual(0);
    });

  });
}
