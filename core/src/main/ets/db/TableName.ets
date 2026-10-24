/**
 * 表名枚举 — 所有 24 张表名的唯一来源，禁止在其他地方直接写表名字符串。
 * 值与 sync_meta.data_type 字段的存储值完全对齐。
 */
export enum TableName {
  /** 米游社账号表，存储 Cookie/stoken 等登录凭证 */
  ACCOUNT                   = 'account_table',
  /** 游戏角色绑定表，存储各游戏的 UID/服务器/等级等基础信息 */
  GAME_ROLE                 = 'game_role_table',
  /** 原神角色列表，存储角色基础属性和当前装备武器的摘要 */
  GENSHIN_CHARACTER_LIST    = 'genshin_character_list',
  /** 原神实时便笺，存储树脂/委托/派遣/洞天宝钱/参量质变仪等数据 */
  GENSHIN_DAILY_NOTE        = 'genshin_daily_note',
  /** 原神角色详情，存储武器/圣遗物/技能等级等完整配装数据 */
  GENSHIN_CHARACTER_DETAIL  = 'genshin_character_detail',
  /** 原神角色养成计算，存储 batch_compute 返回的单角色计算结果（字段与 API 一致） */
  GENSHIN_CHARACTER_COMPUTE = 'genshin_character_compute',
  /** 原神养成计算器角色（v4 新增），存储计算器 sync/avatar/list 返回的角色养成数据（字段与 API 一致） */
  GENSHIN_CALC_AVATAR       = 'genshin_calc_avatar',
  /** 原神养成计算整批合计（v5 新增），存储 batch_compute 顶层的合计数据（字段与 API 一致） */
  GENSHIN_COMPUTE_SUMMARY   = 'genshin_compute_summary',
  /** 星穹铁道角色基础信息，存储角色属性/命途/光锥摘要 */
  STARRAIL_AVATAR_BASIC     = 'starrail_avatar_basic',
  /** 星穹铁道实时便笺，存储开拓力/派遣/实训/模拟宇宙/混沌回忆等数据 */
  STARRAIL_DAILY_NOTE       = 'starrail_daily_note',
  /** 星穹铁道角色详情，存储光锥/遗器/行迹树等完整配装数据 */
  STARRAIL_AVATAR_INFO      = 'starrail_avatar_info',
  /** 星穹铁道角色养成计算，存储角色/技能/光锥的养成材料消耗 JSON */
  STARRAIL_AVATAR_COMPUTE   = 'starrail_avatar_compute',
  /** 绝区零代理人基础信息，存储代理人属性/阵营/邦布摘要 */
  ZZZ_AVATAR_BASIC          = 'zzz_avatar_basic',
  /** 绝区零实时便笺，存储电量/活跃度/录像店/刮刮卡等数据 */
  ZZZ_DAILY_NOTE            = 'zzz_daily_note',
  /** 绝区零代理人详情，存储武器/驱动盘/技能等级等完整配装数据 */
  ZZZ_AVATAR_INFO           = 'zzz_avatar_info',
  /** 绝区零代理人养成计算，存储代理人/武器/技能的养成材料消耗 JSON */
  ZZZ_AVATAR_COMPUTE        = 'zzz_avatar_compute',
  /** 绝区零邦布列表，存储邦布基础信息 */
  ZZZ_BUDDY                 = 'zzz_buddy',
  /** 同步状态元数据，记录每个角色每种数据类型的最后同步时间和状态 */
  SYNC_META                 = 'sync_meta',
  /** 原神材料背包，存储原神玩家拥有的材料数据 */
  GENSHIN_MATERIAL_BAG      = 'genshin_material_bag',
  /** 星穹铁道材料背包，存储星铁玩家拥有的材料数据 */
  STARRAIL_MATERIAL_BAG     = 'starrail_material_bag',
  /** 绝区零材料背包，存储绝区零玩家拥有的材料数据 */
  ZZZ_MATERIAL_BAG          = 'zzz_material_bag',
  /** 原神养成目标配置，存储角色/技能/武器的目标等级配置 */
  GENSHIN_MATERIAL_TARGET_CONFIG = 'genshin_material_target_config',
  /** 星穹铁道养成目标配置，存储角色/命途/光锥的目标等级配置 */
  STARRAIL_MATERIAL_TARGET_CONFIG = 'starrail_material_target_config',
  /** 绝区零养成目标配置，存储代理人/武器/技能的目标等级配置 */
  ZZZ_MATERIAL_TARGET_CONFIG = 'zzz_material_target_config',
}
