/**
 * MaterialBagRow — 材料背包数据模型
 *
 * 对应三个游戏的材料背包表：
 * - genshin_material_bag（原神）
 * - starrail_material_bag（星穹铁道）
 * - zzz_material_bag（绝区零）
 *
 * 用于材料计算功能，对比所需材料和已有材料。
 *
 * 唯一键：(account_id, role_uid, material_id)
 * 同一个米游社账号下，不同游戏角色的背包是独立的。
 *
 * 字段说明：
 * - accountId：米游社账号 UID（外键 → account_table.uid）
 * - roleUid：游戏角色 UID（与 game_role_table.role_id 对应）
 * - materialId：材料 ID（统一存储为字符串）
 * - rarity：稀有度（S/A/B/C 或 1-5，统一存储为字符串）
 * - source：数据来源（api/manual/computed）
 */

export class MaterialBagRow {
  /** 自增主键 */
  id: number = 0;

  /** 米游社账号 UID（外键 → account_table.uid） */
  accountId: string = '';

  /** 游戏角色 UID（与 game_role_table.role_id 对应） */
  roleUid: string = '';

  /** 材料 ID（统一存储为字符串） */
  materialId: string = '';

  /** 材料名称 */
  materialName: string = '';

  /** 材料图标 URL */
  materialIcon: string = '';

  /** 稀有度（S/A/B/C 或 1-5，统一存储为字符串） */
  rarity: string = '';

  /** 拥有数量 */
  count: number = 0;

  /** 数据来源：api（API 返回）、manual（手动输入）、computed（从 lack_num 反推） */
  source: string = 'api';

  /** 数据写入时间戳（Unix 秒） */
  updateTime: number = 0;
}
