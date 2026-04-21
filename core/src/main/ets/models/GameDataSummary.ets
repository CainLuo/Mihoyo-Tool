import { GameId } from '../constants/GameId';

/**
 * GameDataSummary.ets
 *
 * 角色摘要展示模型，供 CharactersViewModel 和 CharacterCard 组件使用。
 * 统一表示原神、星穹铁道、绝区零三款游戏的角色摘要数据。
 *
 * 字段映射：
 *   entityId   = 角色 ID（字符串）
 *   name       = 角色名称
 *   fullName   = 角色全名（绝区零专用）
 *   rarity     = 星级（原神/星铁为数字；绝区零 S=5, A=4）
 *   level      = 等级
 *   extraInt1  = 命座/星魂/影画数（actived_constellation_num / rank）
 *   extraInt2  = 好感度（原神 fetter；星铁/绝区零填 0）
 *   extraText1 = 元素属性（原神 element；星铁 element；绝区零 element_type 数字字符串）
 *   extraText2 = 扩展信息（原神 weapon_type；星铁 base_type 命途；绝区零 avatar_profession 职业）
 *   iconUrl    = 角色图标 URL
 *   squareIconUrl = 角色方形图标 URL（原神 side_icon；星铁 figure_path；绝区零 role_square_url）
 *   weaponName = 武器/光锥/音擎名称
 *   weaponLevel = 武器等级
 *   weaponAffix = 武器精炼/星级
 *   weaponRarity = 武器稀有度
 */
export class GameDataSummary {
  /** 游戏 ID */
  gameId: GameId = GameId.GENSHIN;
  /** 角色所属账号的游戏 UID */
  roleUid: string = '';
  /** 角色 ID（字符串） */
  entityId: string = '';
  /** 角色名称 */
  name: string = '';
  /** 角色全名（绝区零专用，其他游戏为空） */
  fullName: string = '';
  /** 星级（原神/星铁为数字；绝区零 S=5, A=4） */
  rarity: number = 0;
  /** 等级 */
  level: number = 0;
  /** 命座/星魂/影画数 */
  extraInt1: number = 0;
  /** 好感度（原神）；其他游戏填 0 */
  extraInt2: number = 0;
  /** 元素属性字符串 */
  extraText1: string = '';
  /** 扩展信息（weapon_type / base_type / avatar_profession） */
  extraText2: string = '';
  /** 角色图标 URL */
  iconUrl: string = '';
  /** 角色方形图标 URL */
  squareIconUrl: string = '';
  /** 武器/光锥/音擎名称 */
  weaponName: string = '';
  /** 武器等级 */
  weaponLevel: number = 0;
  /** 武器精炼/星级 */
  weaponAffix: number = 0;
  /** 武器稀有度 */
  weaponRarity: number = 0;
  /** 武器图标 URL */
  weaponIconUrl: string = '';
  /** 该游戏/角色是否有武器槽位（原神/星铁=true，绝区零暂时=false） */
  hasWeaponSlot: boolean = false;
  /** 阵营图标 URL（绝区零专用，对应 group_icon_path） */
  groupIconUrl: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}
