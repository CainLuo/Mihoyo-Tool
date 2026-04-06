/**
 * TableSchema — 数据库表结构定义
 *
 * 本文件是整个数据库层的"单一真相来源"：
 * - 所有表名通过 TableName enum 引用，禁止在其他文件直接写表名字符串
 * - 所有列名通过对应的 XxxCol enum 引用，禁止在 DAO 中直接写列名字符串
 * - 每张表的 DDL 由 TableDef.buildCreateSql() 动态生成，RdbManager 循环调用
 * - 每个索引的 DDL 由 IndexDef.buildCreateSql() 动态生成
 *
 * 新增表时：
 * 1. 在 TableName 添加枚举值
 * 2. 新建对应的 XxxCol enum（如有专属列）
 * 3. 用 new TableDef(...) 声明表结构常量
 * 4. 将常量加入 ALL_TABLES 列表
 * 5. 在 ALL_INDEXES 中添加必要索引
 */

/**
 * 表名枚举 — 所有 15 张表名的唯一来源，禁止在其他地方直接写表名字符串。
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
  /** 原神角色养成计算，存储角色/技能/武器的养成材料消耗 JSON */
  GENSHIN_CHARACTER_COMPUTE = 'genshin_character_compute',
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
  /** 同步状态元数据，记录每个角色每种数据类型的最后同步时间和状态 */
  SYNC_META                 = 'sync_meta',
}

/**
 * 公共列名枚举 — 跨多张表复用的列名。
 * 所有 DAO 的 equalTo/getColumnIndex 调用必须使用此 enum，禁止直接写字符串。
 */
export enum CommonCol {
  /** 自增主键 */
  ID          = 'id',
  /** 关联的米游社账号 ID（外键 → account_table.id，ON DELETE CASCADE） */
  ACCOUNT_ID  = 'account_id',
  /** 游戏角色 UID（与 game_role_table.role_id 对应） */
  ROLE_UID    = 'role_uid',
  /** 角色/代理人 ID（米游社 API 返回的 avatar_id 字段） */
  AVATAR_ID   = 'avatar_id',
  /** 原始 API 响应 JSON，完整保存以便 Parser 重新解析 */
  RAW_JSON    = 'raw_json',
  /** 数据写入时间戳（Unix 秒） */
  UPDATE_TIME = 'update_time',
  /** sync_meta 表专用：标识数据类型，值与 TableName enum 对齐 */
  DATA_TYPE   = 'data_type',
}

/**
 * account_table 专属列名。
 * 对应 AccountRow 模型字段，存储米游社账号的登录凭证和基础信息。
 */
export enum AccountCol {
  /** 米游社用户名（唯一键，用于 upsert 冲突检测） */
  USERNAME    = 'username',
  /** 登录 Cookie（含 cookie_token/ltoken 等短期凭证） */
  COOKIE      = 'cookie',
  /** stoken（长期凭证，用于刷新 cookie_token） */
  STOKEN      = 'stoken',
  /** stoken 对应的 stuid（米游社 UID） */
  STUID       = 'stuid',
  /** stoken 对应的 mid（设备标识） */
  MID         = 'mid',
  /** 是否为当前激活账号（1=激活，0=未激活） */
  IS_ACTIVE   = 'is_active',
  /** 账号创建时间戳（Unix 秒） */
  CREATE_TIME = 'create_time',
  /** 米游社 UID（通行证 UID） */
  UID         = 'uid',
  /** 米游社昵称 */
  NICKNAME    = 'nickname',
  /** 米游社头像 URL */
  AVATAR_URL  = 'avatar_url',
  /** 米游社个人简介 */
  INTRODUCE   = 'introduce',
}

/**
 * game_role_table 专属列名。
 * 对应 GameRoleRow 模型字段，存储各游戏绑定角色的基础信息。
 */
export enum GameRoleCol {
  /** 游戏标识符（如 'hk4e_cn'=原神国服，'hkrpg_cn'=星铁国服，'nap_cn'=绝区零国服） */
  GAME_ID      = 'game_id',
  /** 游戏业务标识（如 'hk4e_cn'，与 game_id 通常相同） */
  GAME_BIZ     = 'game_biz',
  /** 游戏类型枚举值（米游社内部分类） */
  GAME_TYPE    = 'game_type',
  /** 游戏角色 UID（游戏内唯一标识） */
  ROLE_ID      = 'role_id',
  /** 游戏内昵称 */
  NICKNAME     = 'nickname',
  /** 角色等级 */
  LEVEL        = 'level',
  /** 服务器标识（如 'cn_gf01'=官服，'cn_qd01'=渠道服） */
  SERVER       = 'server',
  /** 服务器显示名称（如 '天空岛'） */
  REGION_NAME  = 'region_name',
  /** 是否为当前选中角色（1=选中，0=未选中） */
  IS_CHOSEN    = 'is_chosen',
  /** 战绩是否公开（1=公开，0=不公开） */
  IS_PUBLIC    = 'is_public',
  /** 角色卡片背景图 URL */
  BG_IMAGE_URL = 'bg_image_url',
  /** 角色统计数据 JSON（用于 My 页面展示格子数据） */
  STATS_JSON   = 'stats_json',
}

/**
 * sync_meta 表专属列名。
 * 记录每个角色每种数据类型的同步状态，供 Repository 层判断是否需要重新同步。
 */
export enum SyncMetaCol {
  /** 最后一次成功同步的 Unix 秒时间戳（0 表示从未同步） */
  LAST_SYNC_TIME = 'last_sync_time',
  /** 同步状态：'syncing'=同步中，'success'=成功，'failed'=失败 */
  SYNC_STATUS    = 'sync_status',
  /** 同步失败时的错误信息（成功时为空字符串） */
  ERROR_MSG      = 'error_msg',
}

// ── 游戏表专属列名 ────────────────────────────────────────────

/**
 * genshin_character_list 专属列名。
 * 存储原神角色列表的基础属性和当前装备武器的摘要信息。
 */
export enum GenshinCharListCol {
  /** 角色名称（中文，如 '纳西妲'） */
  NAME                      = 'name',
  /** 元素属性（如 'Dendro'=草，'Hydro'=水） */
  ELEMENT                   = 'element',
  /** 角色稀有度（4=四星，5=五星） */
  RARITY                    = 'rarity',
  /** 角色当前等级（1-90） */
  LEVEL                     = 'level',
  /** 好感度等级（0-10） */
  FETTER                    = 'fetter',
  /** 已激活命座数量（0-6） */
  ACTIVED_CONSTELLATION_NUM = 'actived_constellation_num',
  /** 武器类型枚举值（1=单手剑，2=双手剑，3=长柄，4=弓，5=法器） */
  WEAPON_TYPE               = 'weapon_type',
  /** 武器 ID（米游社内部 ID） */
  WEAPON_ID                 = 'weapon_id',
  /** 武器名称 */
  WEAPON_NAME               = 'weapon_name',
  /** 武器稀有度（3-5） */
  WEAPON_RARITY             = 'weapon_rarity',
  /** 武器等级（1-90） */
  WEAPON_LEVEL              = 'weapon_level',
  /** 武器精炼等级（1-5） */
  WEAPON_AFFIX_LEVEL        = 'weapon_affix_level',
  /** 角色头像图片 URL */
  ICON                      = 'icon',
  /** 角色侧面小图 URL（用于列表展示） */
  SIDE_ICON                 = 'side_icon',
}

/**
 * genshin_daily_note 专属列名。
 * 存储原神实时便笺的各项数值，每个角色（roleUid）只保留一条最新记录。
 */
export enum GenshinDailyNoteCol {
  /** 当前原粹树脂数量 */
  CURRENT_RESIN              = 'current_resin',
  /** 原粹树脂上限（通常为 200） */
  MAX_RESIN                  = 'max_resin',
  /** 树脂完全恢复所需秒数（0 表示已满） */
  RESIN_RECOVERY_TIME        = 'resin_recovery_time',
  /** 已完成的每日委托数量 */
  FINISHED_TASK_NUM          = 'finished_task_num',
  /** 每日委托总数（通常为 4） */
  TOTAL_TASK_NUM             = 'total_task_num',
  /** 剩余周本折扣次数 */
  REMAIN_RESIN_DISCOUNT_NUM  = 'remain_resin_discount_num',
  /** 当前派遣中的角色数量 */
  CURRENT_EXPEDITION_NUM     = 'current_expedition_num',
  /** 派遣槽位上限 */
  MAX_EXPEDITION_NUM         = 'max_expedition_num',
  /** 当前洞天宝钱数量 */
  CURRENT_HOME_COIN          = 'current_home_coin',
  /** 洞天宝钱上限 */
  MAX_HOME_COIN              = 'max_home_coin',
  /** 参量质变仪恢复剩余天数（0 表示可使用） */
  TRANSFORMER_RECOVERY_DAY   = 'transformer_recovery_day',
}

/**
 * genshin_character_detail 专属列名。
 * 存储原神角色的完整配装数据，每个角色（avatarId）只保留一条最新记录。
 */
export enum GenshinCharDetailCol {
  /** 武器 ID */
  WEAPON_ID          = 'weapon_id',
  /** 武器等级 */
  WEAPON_LEVEL       = 'weapon_level',
  /** 武器精炼等级 */
  WEAPON_AFFIX_LEVEL = 'weapon_affix_level',
  /** 圣遗物 ID 列表（JSON 数组字符串） */
  RELIC_IDS          = 'relic_ids',
  /** 技能等级 JSON（键为技能 ID，值为等级） */
  SKILL_LEVELS       = 'skill_levels',
}

/**
 * genshin_character_compute 专属列名。
 * 存储原神角色养成计算的材料消耗数据，每个角色（avatarId）只保留一条最新记录。
 */
export enum GenshinCharComputeCol {
  /** 角色本体升级所需材料 JSON */
  AVATAR_CONSUME_JSON = 'avatar_consume_json',
  /** 技能升级所需材料 JSON */
  SKILL_CONSUME_JSON  = 'skill_consume_json',
  /** 武器升级所需材料 JSON */
  WEAPON_CONSUME_JSON = 'weapon_consume_json',
}

/**
 * starrail_avatar_basic 专属列名。
 * 存储星穹铁道角色的基础属性和当前装备光锥的摘要信息。
 */
export enum StarRailAvatarBasicCol {
  /** 角色名称 */
  NAME         = 'name',
  /** 属性（如 'Fire'=火，'Ice'=冰） */
  ELEMENT      = 'element',
  /** 稀有度（4=四星，5=五星） */
  RARITY       = 'rarity',
  /** 角色等级（1-80） */
  LEVEL        = 'level',
  /** 星魂数量（0-6，对应原神命座） */
  RANK         = 'rank',
  /** 命途类型枚举值（米游社内部分类） */
  BASE_TYPE    = 'base_type',
  /** 光锥 ID */
  EQUIP_ID     = 'equip_id',
  /** 光锥名称 */
  EQUIP_NAME   = 'equip_name',
  /** 光锥稀有度（3-5） */
  EQUIP_RARITY = 'equip_rarity',
  /** 光锥等级（1-80） */
  EQUIP_LEVEL  = 'equip_level',
  /** 光锥叠影等级（1-5，对应原神精炼） */
  EQUIP_RANK   = 'equip_rank',
  /** 角色头像图片 URL */
  ICON         = 'icon',
  /** 角色立绘图片路径 */
  FIGURE_PATH  = 'figure_path',
  /** 属性 ID（米游社内部枚举值） */
  ELEMENT_ID   = 'element_id',
}

/**
 * starrail_daily_note 专属列名。
 * 存储星穹铁道实时便笺的各项数值，每个角色（roleUid）只保留一条最新记录。
 */
export enum StarRailDailyNoteCol {
  /** 当前开拓力数量 */
  CURRENT_STAMINA          = 'current_stamina',
  /** 开拓力上限（通常为 240） */
  MAX_STAMINA              = 'max_stamina',
  /** 开拓力完全恢复所需秒数 */
  STAMINA_RECOVER_TIME     = 'stamina_recover_time',
  /** 开拓力满时的 Unix 时间戳 */
  STAMINA_FULL_TS          = 'stamina_full_ts',
  /** 当前后备开拓力数量（溢出时存入，上限 2400） */
  CURRENT_RESERVE_STAMINA  = 'current_reserve_stamina',
  /** 当前派遣中的角色数量 */
  ACCEPTED_EXPEDITION_NUM  = 'accepted_expedition_num',
  /** 派遣槽位上限 */
  TOTAL_EXPEDITION_NUM     = 'total_expedition_num',
  /** 当前实训积分 */
  CURRENT_TRAIN_SCORE      = 'current_train_score',
  /** 实训积分上限（通常为 500） */
  MAX_TRAIN_SCORE          = 'max_train_score',
  /** 当前模拟宇宙积分 */
  CURRENT_ROGUE_SCORE      = 'current_rogue_score',
  /** 模拟宇宙积分上限 */
  MAX_ROGUE_SCORE          = 'max_rogue_score',
  /** 本周已完成的历战余响次数 */
  WEEKLY_COCOON_CNT        = 'weekly_cocoon_cnt',
  /** 历战余响每周上限 */
  WEEKLY_COCOON_LIMIT      = 'weekly_cocoon_limit',
  /** 本周差分宇宙已获积分 */
  ROGUE_TOURN_WEEKLY_CUR   = 'rogue_tourn_weekly_cur',
  /** 差分宇宙每周积分上限 */
  ROGUE_TOURN_WEEKLY_MAX   = 'rogue_tourn_weekly_max',
  /** 本周黄金与机械已完成次数 */
  GRID_FIGHT_WEEKLY_CUR    = 'grid_fight_weekly_cur',
  /** 黄金与机械每周上限 */
  GRID_FIGHT_WEEKLY_MAX    = 'grid_fight_weekly_max',
}

/**
 * starrail_avatar_info 专属列名。
 * 存储星穹铁道角色的完整配装数据，每个角色（avatarId）只保留一条最新记录。
 */
export enum StarRailAvatarInfoCol {
  /** 光锥 ID */
  EQUIP_ID        = 'equip_id',
  /** 光锥等级 */
  EQUIP_LEVEL     = 'equip_level',
  /** 光锥叠影等级 */
  EQUIP_RANK      = 'equip_rank',
  /** 遗器 ID 列表（JSON 数组字符串） */
  RELIC_IDS       = 'relic_ids',
  /** 行迹树节点激活状态 JSON */
  SKILL_TREE_JSON = 'skill_tree_json',
}

/**
 * starrail_avatar_compute 专属列名。
 * 存储星穹铁道角色养成计算的材料消耗数据。
 */
export enum StarRailAvatarComputeCol {
  /** 角色本体升级所需材料 JSON */
  AVATAR_CONSUME_JSON    = 'avatar_consume_json',
  /** 技能升级所需材料 JSON */
  SKILL_CONSUME_JSON     = 'skill_consume_json',
  /** 光锥升级所需材料 JSON */
  EQUIPMENT_CONSUME_JSON = 'equipment_consume_json',
}

/**
 * zzz_avatar_basic 专属列名。
 * 存储绝区零代理人的基础属性信息。
 * 注意：rarity 字段为 TEXT 类型（存储 'S' 或 'A'），与原神/星铁的 INTEGER 不同。
 * awakenState 字段在数据库中以 TEXT 存储，读取时需转换为 number。
 */
export enum ZZZAvatarBasicCol {
  /** 代理人名称（米游社 i18n 格式） */
  NAME_MI18N        = 'name_mi18n',
  /** 代理人全名（米游社 i18n 格式） */
  FULL_NAME_MI18N   = 'full_name_mi18n',
  /** 属性类型枚举值（如 200=电，201=以太） */
  ELEMENT_TYPE      = 'element_type',
  /** 副属性类型枚举值 */
  SUB_ELEMENT_TYPE  = 'sub_element_type',
  /** 职业类型枚举值（如 1=强攻，2=击破） */
  AVATAR_PROFESSION = 'avatar_profession',
  /** 稀有度字符串（'S' 或 'A'） */
  RARITY            = 'rarity',
  /** 代理人等级（1-60） */
  LEVEL             = 'level',
  /** 影画数量（0-6，对应原神命座） */
  RANK              = 'rank',
  /** 阵营名称（米游社 i18n 格式） */
  CAMP_NAME_MI18N   = 'camp_name_mi18n',
  /** 阵营图标路径 */
  GROUP_ICON_PATH   = 'group_icon_path',
  /** 空洞图标路径 */
  HOLLOW_ICON_PATH  = 'hollow_icon_path',
  /** 代理人方形头像 URL */
  ROLE_SQUARE_URL   = 'role_square_url',
  /** 觉醒状态（存储为 TEXT，读取时 parseInt 转 number） */
  AWAKEN_STATE      = 'awaken_state',
}

/**
 * zzz_daily_note 专属列名。
 * 存储绝区零实时便笺的各项数值，每个角色（roleUid）只保留一条最新记录。
 */
export enum ZZZDailyNoteCol {
  /** 当前电量数值 */
  ENERGY_CURRENT   = 'energy_current',
  /** 电量上限（通常为 240） */
  ENERGY_MAX       = 'energy_max',
  /** 电量完全恢复所需秒数 */
  ENERGY_RESTORE   = 'energy_restore',
  /** 当前活跃度数值 */
  VITALITY_CURRENT = 'vitality_current',
  /** 活跃度上限 */
  VITALITY_MAX     = 'vitality_max',
  /** 录像店营业状态（'SaleStateDoing'=营业中，'SaleStateDone'=已结算，'SaleStateNo'=未开启） */
  VHS_SALE_STATE   = 'vhs_sale_state',
  /** 刮刮卡状态（'CardSignDone'=已完成，'CardSignNo'=未完成） */
  CARD_SIGN        = 'card_sign',
}

/**
 * zzz_avatar_info 专属列名。
 * 存储绝区零代理人的完整配装数据，每个代理人（avatarId）只保留一条最新记录。
 */
export enum ZZZAvatarInfoCol {
  /** 音擎（武器）ID */
  WEAPON_ID             = 'weapon_id',
  /** 音擎等级 */
  WEAPON_LEVEL          = 'weapon_level',
  /** 音擎精炼等级（1-5） */
  WEAPON_STAR           = 'weapon_star',
  /** 驱动盘 ID 列表（JSON 数组字符串） */
  EQUIP_IDS             = 'equip_ids',
  /** 技能等级 JSON（键为技能 ID，值为等级） */
  SKILL_LEVELS_JSON     = 'skill_levels_json',
  /** 代理人竖版立绘 URL */
  VERTICAL_PAINTING_URL = 'vertical_painting_url',
}

/**
 * zzz_avatar_compute 专属列名。
 * 存储绝区零代理人养成计算的材料消耗数据。
 */
export enum ZZZAvatarComputeCol {
  /** 代理人本体升级所需材料 JSON */
  AVATAR_CONSUME_JSON = 'avatar_consume_json',
  /** 音擎升级所需材料 JSON */
  WEAPON_CONSUME_JSON = 'weapon_consume_json',
  /** 技能升级所需材料 JSON */
  SKILL_CONSUME_JSON  = 'skill_consume_json',
}

/**
 * 单列定义，描述一张表中某一列的名称、SQLite 类型和约束。
 * 由 TableDef 持有，通过 buildCreateSql() 拼入 DDL。
 */
export class ColumnDef {
  /** 列名（与对应 XxxCol enum 的值保持一致） */
  name: string;
  /** SQLite 数据类型（'INTEGER' / 'TEXT' / 'REAL' / 'BLOB'） */
  type: string;
  /** 列级约束，如 'PRIMARY KEY AUTOINCREMENT'、'NOT NULL'、"DEFAULT ''"（可为空字符串） */
  constraints: string;

  /**
   * @param name        列名
   * @param type        SQLite 数据类型
   * @param constraints 列级约束（可选，默认为空字符串）
   */
  constructor(name: string, type: string, constraints: string = '') {
    this.name = name;
    this.type = type;
    this.constraints = constraints;
  }
}

/**
 * 表定义，描述一张表的名称、所有列和可选的外键约束。
 * 通过 buildCreateSql() 生成 CREATE TABLE IF NOT EXISTS DDL，
 * 通过 columnNames() 返回列名数组供 DAO 的 upsertRow/queryFirst/queryAll 使用。
 */
export class TableDef {
  /** 表名（来自 TableName enum） */
  tableName: TableName;
  /** 所有列定义，顺序与 DAO upsertRow 传入的 values 数组严格对应 */
  columns: ColumnDef[];
  /**
   * 表级外键约束字符串（可选）。
   * 示例：'FOREIGN KEY (account_id) REFERENCES account_table(id) ON DELETE CASCADE'
   * 为空字符串时不追加外键约束。
   */
  foreignKey: string;

  /**
   * @param tableName  表名
   * @param columns    列定义数组（顺序决定 upsertRow 的 values 顺序）
   * @param foreignKey 表级外键约束（可选，默认为空字符串）
   */
  constructor(tableName: TableName, columns: ColumnDef[], foreignKey: string = '') {
    this.tableName = tableName;
    this.columns = columns;
    this.foreignKey = foreignKey;
  }

  /**
   * 生成 CREATE TABLE IF NOT EXISTS DDL 字符串。
   * 由 RdbManager.createTables() 调用，幂等（IF NOT EXISTS 保证）。
   */
  buildCreateSql(): string {
    const colDefs: string[] = [];
    for (let i = 0; i < this.columns.length; i++) {
      const col = this.columns[i];
      const def = col.constraints.length > 0
        ? `${col.name} ${col.type} ${col.constraints}`
        : `${col.name} ${col.type}`;
      colDefs.push(def);
    }
    if (this.foreignKey.length > 0) {
      colDefs.push(this.foreignKey);
    }
    return `CREATE TABLE IF NOT EXISTS ${this.tableName} (\n  ${colDefs.join(',\n  ')}\n)`;
  }

  /**
   * 返回所有列名的字符串数组。
   * DAO 的 upsertRow/queryFirst/queryAll 调用此方法获取列名列表，
   * 确保列名顺序与 upsertRow 传入的 values 数组严格一致。
   */
  columnNames(): string[] {
    const names: string[] = [];
    for (let i = 0; i < this.columns.length; i++) {
      names.push(this.columns[i].name);
    }
    return names;
  }
}

// ── 公共外键约束模板 ──────────────────────────────────────────
const FK_ACCOUNT = 'FOREIGN KEY (account_id) REFERENCES account_table(id) ON DELETE CASCADE';

// ── 表 1：account_table ──────────────────────────────────────
export const ACCOUNT_TABLE = new TableDef(TableName.ACCOUNT, [
  new ColumnDef(CommonCol.ID,          'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef('username',    'TEXT',    'UNIQUE NOT NULL'),
  new ColumnDef('cookie',      'TEXT',    'NOT NULL'),
  new ColumnDef('stoken',      'TEXT',    "DEFAULT ''"),
  new ColumnDef('stuid',       'TEXT',    "DEFAULT ''"),
  new ColumnDef('mid',         'TEXT',    "DEFAULT ''"),
  new ColumnDef('is_active',   'INTEGER', 'DEFAULT 0'),
  new ColumnDef('create_time', 'INTEGER'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
  new ColumnDef('uid',         'TEXT',    "DEFAULT ''"),
  new ColumnDef('nickname',    'TEXT',    "DEFAULT ''"),
  new ColumnDef('avatar_url',  'TEXT',    "DEFAULT ''"),
  new ColumnDef('introduce',   'TEXT',    "DEFAULT ''"),
]);

// ── 表 2：game_role_table ────────────────────────────────────
export const GAME_ROLE_TABLE = new TableDef(TableName.GAME_ROLE, [
  new ColumnDef(CommonCol.ID,           'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID,   'INTEGER', 'NOT NULL'),
  new ColumnDef('game_id',      'TEXT',    'NOT NULL'),
  new ColumnDef('game_biz',     'TEXT',    "DEFAULT ''"),
  new ColumnDef('game_type',    'INTEGER', 'DEFAULT 0'),
  new ColumnDef('role_id',      'TEXT',    'NOT NULL'),
  new ColumnDef('nickname',     'TEXT',    "DEFAULT ''"),
  new ColumnDef('level',        'INTEGER', 'DEFAULT 0'),
  new ColumnDef('server',       'TEXT',    "DEFAULT ''"),
  new ColumnDef('region_name',  'TEXT',    "DEFAULT ''"),
  new ColumnDef('is_chosen',    'INTEGER', 'DEFAULT 0'),
  new ColumnDef('is_public',    'INTEGER', 'DEFAULT 0'),
  new ColumnDef('bg_image_url', 'TEXT',    "DEFAULT ''"),
  new ColumnDef('stats_json',   'TEXT',    "DEFAULT ''"),
], FK_ACCOUNT);

// ── 表 3：genshin_character_list ─────────────────────────────
export const GENSHIN_CHARACTER_LIST_TABLE = new TableDef(TableName.GENSHIN_CHARACTER_LIST, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('name',                      'TEXT'),
  new ColumnDef('element',                   'TEXT'),
  new ColumnDef('rarity',                    'INTEGER'),
  new ColumnDef('level',                     'INTEGER'),
  new ColumnDef('fetter',                    'INTEGER'),
  new ColumnDef('actived_constellation_num', 'INTEGER'),
  new ColumnDef('weapon_type',               'INTEGER'),
  new ColumnDef('weapon_id',                 'TEXT'),
  new ColumnDef('weapon_name',               'TEXT'),
  new ColumnDef('weapon_rarity',             'INTEGER'),
  new ColumnDef('weapon_level',              'INTEGER'),
  new ColumnDef('weapon_affix_level',        'INTEGER'),
  new ColumnDef('icon',                      'TEXT'),
  new ColumnDef('side_icon',                 'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 4：genshin_daily_note ─────────────────────────────────
export const GENSHIN_DAILY_NOTE_TABLE = new TableDef(TableName.GENSHIN_DAILY_NOTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef('current_resin',             'INTEGER'),
  new ColumnDef('max_resin',                 'INTEGER'),
  new ColumnDef('resin_recovery_time',       'INTEGER'),
  new ColumnDef('finished_task_num',         'INTEGER'),
  new ColumnDef('total_task_num',            'INTEGER'),
  new ColumnDef('remain_resin_discount_num', 'INTEGER'),
  new ColumnDef('current_expedition_num',    'INTEGER'),
  new ColumnDef('max_expedition_num',        'INTEGER'),
  new ColumnDef('current_home_coin',         'INTEGER'),
  new ColumnDef('max_home_coin',             'INTEGER'),
  new ColumnDef('transformer_recovery_day',  'INTEGER'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 5：genshin_character_detail ───────────────────────────
export const GENSHIN_CHARACTER_DETAIL_TABLE = new TableDef(TableName.GENSHIN_CHARACTER_DETAIL, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('weapon_id',          'TEXT'),
  new ColumnDef('weapon_level',       'INTEGER'),
  new ColumnDef('weapon_affix_level', 'INTEGER'),
  new ColumnDef('relic_ids',          'TEXT'),
  new ColumnDef('skill_levels',       'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 6：genshin_character_compute ──────────────────────────
export const GENSHIN_CHARACTER_COMPUTE_TABLE = new TableDef(TableName.GENSHIN_CHARACTER_COMPUTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('avatar_consume_json', 'TEXT'),
  new ColumnDef('skill_consume_json',  'TEXT'),
  new ColumnDef('weapon_consume_json', 'TEXT'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 7：starrail_avatar_basic ──────────────────────────────
export const STARRAIL_AVATAR_BASIC_TABLE = new TableDef(TableName.STARRAIL_AVATAR_BASIC, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('name',         'TEXT'),
  new ColumnDef('element',      'TEXT'),
  new ColumnDef('rarity',       'INTEGER'),
  new ColumnDef('level',        'INTEGER'),
  new ColumnDef('rank',         'INTEGER'),
  new ColumnDef('base_type',    'INTEGER'),
  new ColumnDef('equip_id',     'TEXT'),
  new ColumnDef('equip_name',   'TEXT'),
  new ColumnDef('equip_rarity', 'INTEGER'),
  new ColumnDef('equip_level',  'INTEGER'),
  new ColumnDef('equip_rank',   'INTEGER'),
  new ColumnDef('icon',         'TEXT'),
  new ColumnDef('figure_path',  'TEXT'),
  new ColumnDef('element_id',   'INTEGER'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 8：starrail_daily_note ────────────────────────────────
export const STARRAIL_DAILY_NOTE_TABLE = new TableDef(TableName.STARRAIL_DAILY_NOTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef('current_stamina',         'INTEGER'),
  new ColumnDef('max_stamina',             'INTEGER'),
  new ColumnDef('stamina_recover_time',    'INTEGER'),
  new ColumnDef('stamina_full_ts',         'INTEGER'),
  new ColumnDef('current_reserve_stamina', 'INTEGER'),
  new ColumnDef('accepted_expedition_num', 'INTEGER'),
  new ColumnDef('total_expedition_num',    'INTEGER'),
  new ColumnDef('current_train_score',     'INTEGER'),
  new ColumnDef('max_train_score',         'INTEGER'),
  new ColumnDef('current_rogue_score',     'INTEGER'),
  new ColumnDef('max_rogue_score',         'INTEGER'),
  new ColumnDef('weekly_cocoon_cnt',       'INTEGER'),
  new ColumnDef('weekly_cocoon_limit',     'INTEGER'),
  new ColumnDef('rogue_tourn_weekly_cur',  'INTEGER'),
  new ColumnDef('rogue_tourn_weekly_max',  'INTEGER'),
  new ColumnDef('grid_fight_weekly_cur',   'INTEGER'),
  new ColumnDef('grid_fight_weekly_max',   'INTEGER'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 9：starrail_avatar_info ───────────────────────────────
export const STARRAIL_AVATAR_INFO_TABLE = new TableDef(TableName.STARRAIL_AVATAR_INFO, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('equip_id',        'TEXT'),
  new ColumnDef('equip_level',     'INTEGER'),
  new ColumnDef('equip_rank',      'INTEGER'),
  new ColumnDef('relic_ids',       'TEXT'),
  new ColumnDef('skill_tree_json', 'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 10：starrail_avatar_compute ───────────────────────────
export const STARRAIL_AVATAR_COMPUTE_TABLE = new TableDef(TableName.STARRAIL_AVATAR_COMPUTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('avatar_consume_json',    'TEXT'),
  new ColumnDef('skill_consume_json',     'TEXT'),
  new ColumnDef('equipment_consume_json', 'TEXT'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 11：zzz_avatar_basic ──────────────────────────────────
export const ZZZ_AVATAR_BASIC_TABLE = new TableDef(TableName.ZZZ_AVATAR_BASIC, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('name_mi18n',        'TEXT'),
  new ColumnDef('full_name_mi18n',   'TEXT'),
  new ColumnDef('element_type',      'INTEGER'),
  new ColumnDef('sub_element_type',  'INTEGER'),
  new ColumnDef('avatar_profession', 'INTEGER'),
  new ColumnDef('rarity',            'TEXT'),
  new ColumnDef('level',             'INTEGER'),
  new ColumnDef('rank',              'INTEGER'),
  new ColumnDef('camp_name_mi18n',   'TEXT'),
  new ColumnDef('group_icon_path',   'TEXT'),
  new ColumnDef('hollow_icon_path',  'TEXT'),
  new ColumnDef('role_square_url',   'TEXT'),
  new ColumnDef('awaken_state',      'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 12：zzz_daily_note ────────────────────────────────────
export const ZZZ_DAILY_NOTE_TABLE = new TableDef(TableName.ZZZ_DAILY_NOTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef('energy_current',   'INTEGER'),
  new ColumnDef('energy_max',       'INTEGER'),
  new ColumnDef('energy_restore',   'INTEGER'),
  new ColumnDef('vitality_current', 'INTEGER'),
  new ColumnDef('vitality_max',     'INTEGER'),
  new ColumnDef('vhs_sale_state',   'TEXT'),
  new ColumnDef('card_sign',        'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 13：zzz_avatar_info ───────────────────────────────────
export const ZZZ_AVATAR_INFO_TABLE = new TableDef(TableName.ZZZ_AVATAR_INFO, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('weapon_id',             'TEXT'),
  new ColumnDef('weapon_level',          'INTEGER'),
  new ColumnDef('weapon_star',           'INTEGER'),
  new ColumnDef('equip_ids',             'TEXT'),
  new ColumnDef('skill_levels_json',     'TEXT'),
  new ColumnDef('vertical_painting_url', 'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 14：zzz_avatar_compute ────────────────────────────────
export const ZZZ_AVATAR_COMPUTE_TABLE = new TableDef(TableName.ZZZ_AVATAR_COMPUTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('avatar_consume_json', 'TEXT'),
  new ColumnDef('weapon_consume_json', 'TEXT'),
  new ColumnDef('skill_consume_json',  'TEXT'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 15：sync_meta ─────────────────────────────────────────
export const SYNC_META_TABLE = new TableDef(TableName.SYNC_META, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.DATA_TYPE,  'TEXT',    'NOT NULL'),
  new ColumnDef('last_sync_time', 'INTEGER'),
  new ColumnDef('sync_status',    'TEXT'),
  new ColumnDef('error_msg',      'TEXT'),
], FK_ACCOUNT);

/**
 * 所有 15 张表的有序列表，供 RdbManager.createTables() 循环建表使用。
 * 顺序很重要：account_table 必须在所有有外键的子表之前创建。
 */
export const ALL_TABLES: TableDef[] = [
  ACCOUNT_TABLE,
  GAME_ROLE_TABLE,
  GENSHIN_CHARACTER_LIST_TABLE,
  GENSHIN_DAILY_NOTE_TABLE,
  GENSHIN_CHARACTER_DETAIL_TABLE,
  GENSHIN_CHARACTER_COMPUTE_TABLE,
  STARRAIL_AVATAR_BASIC_TABLE,
  STARRAIL_DAILY_NOTE_TABLE,
  STARRAIL_AVATAR_INFO_TABLE,
  STARRAIL_AVATAR_COMPUTE_TABLE,
  ZZZ_AVATAR_BASIC_TABLE,
  ZZZ_DAILY_NOTE_TABLE,
  ZZZ_AVATAR_INFO_TABLE,
  ZZZ_AVATAR_COMPUTE_TABLE,
  SYNC_META_TABLE,
];

// ── 索引定义 ─────────────────────────────────────────────────

/**
 * 单个索引定义，描述一个数据库索引的名称、所在表、列和是否唯一。
 * 通过 buildCreateSql() 生成 CREATE [UNIQUE] INDEX IF NOT EXISTS DDL。
 */
export class IndexDef {
  /** 索引名称（全局唯一，命名规范：idx_{表名缩写}_{用途}） */
  indexName: string;
  /** 索引所在的表（来自 TableName enum） */
  tableName: TableName;
  /** 参与索引的列名数组（复合索引时顺序影响查询效率） */
  columns: string[];
  /**
   * 是否为唯一索引。
   * true = UNIQUE INDEX，用于实现业务唯一键约束（如 account_id+role_uid+avatar_id）；
   * false = 普通索引，用于加速查询（如按 element/rarity 过滤）。
   */
  unique: boolean;

  /**
   * @param indexName 索引名称
   * @param tableName 所在表
   * @param columns   参与索引的列名数组
   * @param unique    是否唯一索引（默认 false）
   */
  constructor(indexName: string, tableName: TableName, columns: string[], unique: boolean = false) {
    this.indexName = indexName;
    this.tableName = tableName;
    this.columns = columns;
    this.unique = unique;
  }

  /**
   * 生成 CREATE [UNIQUE] INDEX IF NOT EXISTS DDL 字符串。
   * 由 RdbManager.createTables() 调用，幂等（IF NOT EXISTS 保证）。
   */
  buildCreateSql(): string {
    const uniqueStr = this.unique ? 'UNIQUE ' : '';
    return `CREATE ${uniqueStr}INDEX IF NOT EXISTS ${this.indexName} ON ${this.tableName}(${this.columns.join(', ')})`;
  }
}

/**
 * 所有索引的有序列表，供 RdbManager.createTables() 循环建索引使用。
 * UNIQUE 索引同时承担业务唯一键约束（INSERT OR REPLACE 依赖此约束实现 upsert 语义）。
 */
export const ALL_INDEXES: IndexDef[] = [
  // game_role_table
  new IndexDef('idx_game_role_account', TableName.GAME_ROLE, [CommonCol.ACCOUNT_ID]),
  new IndexDef('idx_game_role_unique',  TableName.GAME_ROLE, [CommonCol.ACCOUNT_ID, 'game_id', 'role_id'], true),
  // genshin_character_list
  new IndexDef('idx_genshin_char_list_unique',  TableName.GENSHIN_CHARACTER_LIST, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  new IndexDef('idx_genshin_char_list_element', TableName.GENSHIN_CHARACTER_LIST, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'element']),
  new IndexDef('idx_genshin_char_list_rarity',  TableName.GENSHIN_CHARACTER_LIST, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'rarity']),
  // genshin_daily_note
  new IndexDef('idx_genshin_daily_note_unique', TableName.GENSHIN_DAILY_NOTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true),
  // genshin_character_detail
  new IndexDef('idx_genshin_char_detail_unique', TableName.GENSHIN_CHARACTER_DETAIL, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  // genshin_character_compute
  new IndexDef('idx_genshin_char_compute_unique', TableName.GENSHIN_CHARACTER_COMPUTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  // starrail_avatar_basic
  new IndexDef('idx_starrail_avatar_basic_unique',  TableName.STARRAIL_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  new IndexDef('idx_starrail_avatar_basic_type',    TableName.STARRAIL_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'base_type']),
  new IndexDef('idx_starrail_avatar_basic_element', TableName.STARRAIL_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'element']),
  // starrail_daily_note
  new IndexDef('idx_starrail_daily_note_unique', TableName.STARRAIL_DAILY_NOTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true),
  // starrail_avatar_info
  new IndexDef('idx_starrail_avatar_info_unique', TableName.STARRAIL_AVATAR_INFO, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  // starrail_avatar_compute
  new IndexDef('idx_starrail_avatar_compute_unique', TableName.STARRAIL_AVATAR_COMPUTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  // zzz_avatar_basic
  new IndexDef('idx_zzz_avatar_basic_unique',     TableName.ZZZ_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  new IndexDef('idx_zzz_avatar_basic_element',    TableName.ZZZ_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'element_type']),
  new IndexDef('idx_zzz_avatar_basic_profession', TableName.ZZZ_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'avatar_profession']),
  // zzz_daily_note
  new IndexDef('idx_zzz_daily_note_unique', TableName.ZZZ_DAILY_NOTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true),
  // zzz_avatar_info
  new IndexDef('idx_zzz_avatar_info_unique', TableName.ZZZ_AVATAR_INFO, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  // zzz_avatar_compute
  new IndexDef('idx_zzz_avatar_compute_unique', TableName.ZZZ_AVATAR_COMPUTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  // sync_meta
  new IndexDef('idx_sync_meta_unique', TableName.SYNC_META, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.DATA_TYPE], true),
];
