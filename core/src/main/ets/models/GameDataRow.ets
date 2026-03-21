/**
 * GameDataRow.ets
 *
 * game_data 表的行数据模型。
 *
 * ArkTS 注意事项：
 *   arkts-no-untyped-obj-literals 规则要求对象字面量只能对应 class，不能对应 interface。
 *   GameDataRow / GameDataSummary 均定义为 class，DAO 层用 new 实例化后逐字段赋值。
 */

/**
 * game_data 表行模型（完整版，含 rawJson）
 * 用于详情页查询
 */
export class GameDataRow {
  id: number = 0;
  gameId: string = '';
  roleUid: string = '';
  dataType: string = '';
  entityId: string = '';
  name: string = '';
  rarity: number = 0;
  level: number = 0;
  extraInt1: number = 0;
  extraInt2: number = 0;
  extraText1: string = '';
  rawJson: string = '';
  updateTime: number = 0;
}

/**
 * game_data 表行模型（轻量版，不含 rawJson）
 * 用于列表页查询，避免加载大量 JSON 数据
 */
export class GameDataSummary {
  id: number = 0;
  gameId: string = '';
  roleUid: string = '';
  dataType: string = '';
  entityId: string = '';
  name: string = '';
  rarity: number = 0;
  level: number = 0;
  extraInt1: number = 0;
  extraInt2: number = 0;
  extraText1: string = '';
  /** 角色/武器头像 URL，从 raw_json 中解析填充，不对应数据库列 */
  iconUrl: string = '';
  /** 武器名称，从 raw_json 中解析填充 */
  weaponName: string = '';
  /** 武器等级，从 raw_json 中解析填充 */
  weaponLevel: number = 0;
  /** 武器图标 URL，从 raw_json 中解析填充 */
  weaponIconUrl: string = '';
  /** 武器精炼等级，从 raw_json 中解析填充 */
  weaponAffix: number = 1;
  /** 武器稀有度，从 raw_json 中解析填充 */
  weaponRarity: number = 3;
  /** 圣遗物图标 URL 数组（最多5个），从 detail 接口解析填充 */
  relicIcons: string[] = [];
  /** 技能等级数组 [普攻, 战技, 爆发]，从 detail 接口解析填充 */
  skillLevels: number[] = [];
  /** 技能图标 URL 数组 [普攻, 战技, 爆发]，从 detail 接口解析填充 */
  skillIcons: string[] = [];
  updateTime: number = 0;
}

/**
 * data_type 枚举常量
 */
export class DataType {
  static readonly CHARACTER: string = 'character';
  static readonly WEAPON: string = 'weapon';
  static readonly RELIC: string = 'relic';
  static readonly ACTIVITY: string = 'activity';
  static readonly GACHA_RECORD: string = 'gacha_record';
  static readonly GACHA_SUMMARY: string = 'gacha_summary';
  static readonly DAILY_NOTE: string = 'daily_note';
  static readonly ABYSS: string = 'abyss';
}

/**
 * game_id 枚举常量
 */
export class GameId {
  static readonly GENSHIN: string = 'genshin';
  static readonly STARRAIL: string = 'starrail';
  static readonly ZZZ: string = 'zzz';
  static readonly HONKAI3: string = 'honkai3';
  static readonly GLOBAL: string = 'global';
}
