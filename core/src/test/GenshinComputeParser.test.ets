/**
 * GenshinComputeParser.test.ets
 *
 * 测试 GenshinComputeParser.parse() 和 parseItem() 的 JSON 解析逻辑。
 * 
 * 测试重点：
 * 1. parse() — 解析批量 API 响应
 * 2. parseItem() — 解析单个角色的 rawJson（优先读取 overall_consume）
 */

import { describe, it, expect } from '@ohos/hypium';
import { GenshinComputeParser, GenshinComputeItem, GenshinMaterialItem } from '../main/ets/parsers/genshin/GenshinComputeParser';

// ─── 批量 API 响应格式测试数据 ────────────────────────────────────────

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

// ─── 单角色 rawJson 格式测试数据（parseItem 测试）──────────────────────

/**
 * 单角色请求存储的格式：包含 overall_consume（真实缺口数据）
 * 这是从 GenshinRepository.parseComputeResult() 存储的格式
 */
const SINGLE_ROLE_WITH_OVERALL_CONSUME = `{
  "avatar_id": 10000122,
  "overall_consume": [
    {
      "id": 202,
      "name": "摩拉",
      "icon": "https://example.com/mora.png",
      "num": 8181475,
      "lack_num": 7876844,
      "level": 3
    },
    {
      "id": 104003,
      "name": "大英雄的经验",
      "icon": "https://example.com/exp.png",
      "num": 419,
      "lack_num": 137,
      "level": 4
    },
    {
      "id": 104013,
      "name": "精锻用魔矿",
      "icon": "https://example.com/ore.png",
      "num": 907,
      "lack_num": 0,
      "level": 4
    }
  ]
}`;

/**
 * 批量请求存储的格式：avatar_consume 已合并 lack_num
 */
const BATCH_ROLE_FORMAT = `{
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
  "skill_consume": [
    {
      "id": 104321,
      "name": "「正义」的教导",
      "icon": "https://example.com/skill.png",
      "num": 9,
      "lack_num": 3,
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
  ]
}`;

const EMPTY_OVERALL_CONSUME = `{
  "avatar_id": 10000122,
  "overall_consume": []
}`;

const NULL_OVERALL_CONSUME = `{
  "avatar_id": 10000122
}`;

const INVALID_ITEM_JSON = 'not valid json';

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

  // ─── parseItem 测试（单角色 rawJson 解析）────────────────────────────

  describe('GenshinComputeParser.parseItem', () => {

    // ── overall_consume 格式（单角色请求存储的格式）────────────────────

    it('parseItem_withOverallConsume_returnsItem', 0, () => {
      const item = GenshinComputeParser.parseItem(SINGLE_ROLE_WITH_OVERALL_CONSUME);
      expect(item).assertNotNull();
    });

    it('parseItem_withOverallConsume_avatarId', 0, () => {
      const item = GenshinComputeParser.parseItem(SINGLE_ROLE_WITH_OVERALL_CONSUME);
      expect(item!.avatarId).assertEqual('10000122');
    });

    it('parseItem_withOverallConsume_avatarConsumeLength', 0, () => {
      const item = GenshinComputeParser.parseItem(SINGLE_ROLE_WITH_OVERALL_CONSUME);
      expect(item!.avatarConsume.length).assertEqual(3);
    });

    it('parseItem_withOverallConsume_firstMaterialId', 0, () => {
      const item = GenshinComputeParser.parseItem(SINGLE_ROLE_WITH_OVERALL_CONSUME);
      expect(item!.avatarConsume[0].id).assertEqual(202);
    });

    it('parseItem_withOverallConsume_firstMaterialName', 0, () => {
      const item = GenshinComputeParser.parseItem(SINGLE_ROLE_WITH_OVERALL_CONSUME);
      expect(item!.avatarConsume[0].name).assertEqual('摩拉');
    });

    it('parseItem_withOverallConsume_firstMaterialNum', 0, () => {
      const item = GenshinComputeParser.parseItem(SINGLE_ROLE_WITH_OVERALL_CONSUME);
      expect(item!.avatarConsume[0].num).assertEqual(8181475);
    });

    it('parseItem_withOverallConsume_firstMaterialLackNum', 0, () => {
      const item = GenshinComputeParser.parseItem(SINGLE_ROLE_WITH_OVERALL_CONSUME);
      expect(item!.avatarConsume[0].lackNum).assertEqual(7876844);
    });

    it('parseItem_withOverallConsume_secondMaterialLackNum', 0, () => {
      const item = GenshinComputeParser.parseItem(SINGLE_ROLE_WITH_OVERALL_CONSUME);
      expect(item!.avatarConsume[1].lackNum).assertEqual(137);
    });

    it('parseItem_withOverallConsume_zeroLackNum', 0, () => {
      const item = GenshinComputeParser.parseItem(SINGLE_ROLE_WITH_OVERALL_CONSUME);
      expect(item!.avatarConsume[2].lackNum).assertEqual(0);
    });

    it('parseItem_withOverallConsume_zeroLackNumMaterial', 0, () => {
      const item = GenshinComputeParser.parseItem(SINGLE_ROLE_WITH_OVERALL_CONSUME);
      expect(item!.avatarConsume[2].name).assertEqual('精锻用魔矿');
      expect(item!.avatarConsume[2].num).assertEqual(907);
    });

    // ── 批量请求格式（avatar_consume 已合并 lack_num）────────────────────

    it('parseItem_batchFormat_returnsItem', 0, () => {
      const item = GenshinComputeParser.parseItem(BATCH_ROLE_FORMAT);
      expect(item).assertNotNull();
    });

    it('parseItem_batchFormat_avatarId', 0, () => {
      const item = GenshinComputeParser.parseItem(BATCH_ROLE_FORMAT);
      expect(item!.avatarId).assertEqual('10000025');
    });

    it('parseItem_batchFormat_avatarConsumeLength', 0, () => {
      const item = GenshinComputeParser.parseItem(BATCH_ROLE_FORMAT);
      expect(item!.avatarConsume.length).assertEqual(1);
    });

    it('parseItem_batchFormat_avatarConsumeLackNum', 0, () => {
      const item = GenshinComputeParser.parseItem(BATCH_ROLE_FORMAT);
      expect(item!.avatarConsume[0].lackNum).assertEqual(10);
    });

    it('parseItem_batchFormat_skillConsumeLength', 0, () => {
      const item = GenshinComputeParser.parseItem(BATCH_ROLE_FORMAT);
      expect(item!.skillConsume.length).assertEqual(1);
    });

    it('parseItem_batchFormat_skillConsumeLackNum', 0, () => {
      const item = GenshinComputeParser.parseItem(BATCH_ROLE_FORMAT);
      expect(item!.skillConsume[0].lackNum).assertEqual(3);
    });

    it('parseItem_batchFormat_weaponConsumeLength', 0, () => {
      const item = GenshinComputeParser.parseItem(BATCH_ROLE_FORMAT);
      expect(item!.weaponConsume.length).assertEqual(1);
    });

    it('parseItem_batchFormat_weaponConsumeLackNum', 0, () => {
      const item = GenshinComputeParser.parseItem(BATCH_ROLE_FORMAT);
      expect(item!.weaponConsume[0].lackNum).assertEqual(2);
    });

    // ── 边界场景 ─────────────────────────────────────────────────

    it('parseItem_emptyOverallConsume_returnsEmptyAvatarConsume', 0, () => {
      const item = GenshinComputeParser.parseItem(EMPTY_OVERALL_CONSUME);
      expect(item).assertNotNull();
      expect(item!.avatarConsume.length).assertEqual(0);
    });

    it('parseItem_nullOverallConsume_returnsEmptyAvatarConsume', 0, () => {
      const item = GenshinComputeParser.parseItem(NULL_OVERALL_CONSUME);
      expect(item).assertNotNull();
      expect(item!.avatarConsume.length).assertEqual(0);
    });

    it('parseItem_invalidJson_returnsNull', 0, () => {
      const item = GenshinComputeParser.parseItem(INVALID_ITEM_JSON);
      expect(item).assertNull();
    });

  });
}
