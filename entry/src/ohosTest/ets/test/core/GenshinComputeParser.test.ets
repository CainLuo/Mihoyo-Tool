/**
 * GenshinComputeParser.test.ets
 *
 * 测试 GenshinComputeParser.parse() 的 JSON 解析逻辑。
 */

import { describe, it, expect } from '@ohos/hypium';
import { GenshinComputeParser, GenshinComputeItem, GenshinMaterialItem } from '../main/ets/parsers/genshin/GenshinComputeParser';

// 标准测试 JSON（基于真实 API 响应结构）
const VALID_JSON = `{
  "items": [
    {
      "avatar_id": "10000025",
      "avatar_consume": [
        {
          "id": 104161,
          "name": "哀叙冰玉",
          "icon": "https://example.com/icon.png",
          "num": 46,
          "lack_num": 10,
          "level": 5
        }
      ],
      "avatar_skill_consume": [
        {
          "id": 104321,
          "name": "「正义」的教导",
          "icon": "https://example.com/skill.png",
          "num": 9,
          "lack_num": 0,
          "level": 2
        }
      ],
      "weapon_consume": [
        {
          "id": 114025,
          "name": "悠古的脉动",
          "icon": "https://example.com/weapon.png",
          "num": 6,
          "lack_num": 2,
          "level": 5
        }
      ],
      "skills_consume": [
        {
          "skill_info": {
            "id": "100251",
            "level_current": "1",
            "level_target": "10"
          },
          "consume_list": [
            {
              "id": 104321,
              "name": "「正义」的教导",
              "icon": "https://example.com/skill.png",
              "num": 9,
              "lack_num": 0,
              "level": 2
            }
          ]
        }
      ]
    }
  ]
}`;

const EMPTY_ITEMS_JSON = '{"items": []}';

const INVALID_JSON = 'not valid json';

const MISSING_FIELDS_JSON = '{"items": [{}]}';

export default function genshinComputeParserTest() {
  describe('GenshinComputeParser', () => {

    // ── 正常解析 ─────────────────────────────────────────────────

    it('parse_validJson_returnsArray', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data.length).assertEqual(1);
    });

    it('parse_avatarId_isCorrect', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].avatarId).assertEqual('10000025');
    });

    it('parse_avatarConsume_length', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].avatarConsume.length).assertEqual(1);
    });

    it('parse_avatarConsume_id', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].avatarConsume[0].id).assertEqual(104161);
    });

    it('parse_avatarConsume_name', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].avatarConsume[0].name).assertEqual('哀叙冰玉');
    });

    it('parse_avatarConsume_num', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].avatarConsume[0].num).assertEqual(46);
    });

    it('parse_avatarConsume_lackNum', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].avatarConsume[0].lackNum).assertEqual(10);
    });

    it('parse_avatarConsume_level', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].avatarConsume[0].level).assertEqual(5);
    });

    it('parse_avatarConsume_rarity_sameAsLevel', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].avatarConsume[0].rarity).assertEqual(5);
    });

    it('parse_skillConsume_length', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].skillConsume.length).assertEqual(1);
    });

    it('parse_weaponConsume_length', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].weaponConsume.length).assertEqual(1);
    });

    it('parse_skillsConsume_length', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].skillsConsume.length).assertEqual(1);
    });

    it('parse_skillsConsume_skillId', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].skillsConsume[0].skillId).assertEqual('100251');
    });

    it('parse_skillsConsume_levelCurrent', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].skillsConsume[0].levelCurrent).assertEqual(1);
    });

    it('parse_skillsConsume_levelTarget', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].skillsConsume[0].levelTarget).assertEqual(10);
    });

    it('parse_skillsConsume_consumeList', 0, () => {
      const data = GenshinComputeParser.parse(VALID_JSON);
      expect(data[0].skillsConsume[0].consumeList.length).assertEqual(1);
    });

    // ── 边界场景 ─────────────────────────────────────────────────

    it('parse_emptyItems_returnsEmptyArray', 0, () => {
      const data = GenshinComputeParser.parse(EMPTY_ITEMS_JSON);
      expect(data.length).assertEqual(0);
    });

    it('parse_invalidJson_returnsEmptyArray', 0, () => {
      const data = GenshinComputeParser.parse(INVALID_JSON);
      expect(data.length).assertEqual(0);
    });

    it('parse_missingFields_doesNotCrash', 0, () => {
      const data = GenshinComputeParser.parse(MISSING_FIELDS_JSON);
      expect(data.length).assertEqual(1);
      expect(data[0].avatarId).assertEqual('');
      expect(data[0].avatarConsume.length).assertEqual(0);
      expect(data[0].skillConsume.length).assertEqual(0);
      expect(data[0].weaponConsume.length).assertEqual(0);
    });

  });
}
