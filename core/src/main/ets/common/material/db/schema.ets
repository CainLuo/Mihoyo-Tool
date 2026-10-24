/**
 * 材料背包通用列名（适用于三个游戏的材料背包表）。
 * 存储玩家背包中的材料数据，用于材料计算功能。
 *
 * 注意：三个游戏有独立的材料背包表，不再需要 game_id 字段：
 * - genshin_material_bag（原神）
 * - starrail_material_bag（星穹铁道）
 * - zzz_material_bag（绝区零）
 *
 * 唯一键：(account_id, role_uid, material_id)
 * 同一个米游社账号下，不同游戏角色的背包是独立的。
 *
 * 公共字段使用 CommonCol：
 * - account_id（米游社账号 UID）
 * - role_uid（游戏角色 UID，与 game_role_table.role_id 对应）
 * - update_time（更新时间戳）
 */
export enum MaterialBagCol {
  /** 材料 ID（统一 TEXT 类型，兼容星铁 item_id/绝区零 id/原神 id） */
  MATERIAL_ID    = 'material_id',
  /** 材料名称 */
  MATERIAL_NAME  = 'material_name',
  /** 材料图标 URL */
  MATERIAL_ICON  = 'material_icon',
  /** 稀有度（星铁/绝区零返回 string 的 S/A/B/C，原神返回 number 的 1-5，统一存 string） */
  RARITY         = 'rarity',
  /** 拥有数量（星铁/绝区零来自 API，原神为用户手动输入或从 lack_num 反推） */
  COUNT          = 'count',
  /** 数据来源：api（API 返回）或 manual（手动输入）或 computed（从 lack_num 反推） */
  SOURCE         = 'source',
}

/**
 * 养成目标配置通用列名（适用于三个游戏的养成目标配置表）。
 * 存储用户设置的角色/技能/武器目标等级配置。
 *
 * 注意：三个游戏有独立的配置表，不再需要 game_id 字段：
 * - genshin_material_target_config（原神）
 * - starrail_material_target_config（星穹铁道）
 * - zzz_material_target_config（绝区零）
 *
 * 唯一键：(account_id, role_uid)
 * 同一个米游社账号下，不同游戏角色的配置是独立的。
 *
 * 配置数据以 JSON 形式存储在 config_json 字段中，不同游戏的 JSON 结构不同：
 * - 原神：avatar (current/target), skill (current/target), weapon (current/target)
 * - 星铁：avatar (current/target), skill (current/target), light_cone (current/target)
 * - 绝区零：avatar (current/target), weapon (current/target), skills (数组，每个含 skill_type/current/target)
 */
export enum MaterialTargetConfigCol {
  /** 配置 JSON（包含角色/技能/武器的当前等级和目标等级） */
  CONFIG_JSON    = 'config_json',
}
