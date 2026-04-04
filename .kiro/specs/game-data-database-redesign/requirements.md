# 需求文档

## 简介

本功能将现有的单张通用 `game_data` 表重构为按游戏类型和数据类型拆分的多张专用表。当前架构使用 `game_id + data_type` 区分所有游戏的所有数据，随着支持的游戏和数据类型增多，通用字段（`extra_int1`、`extra_text1` 等）的语义越来越模糊，查询时无法利用类型专属索引，维护成本持续上升。

重构目标：为原神（genshin）、崩坏：星穹铁道（starrail）、绝区零（zzz）三款游戏各自建立专用表，每张表的字段直接对应 API 返回的数据结构，消除通用字段的语义歧义，提升查询性能和代码可读性。共建立 15 张表：基础表 2 张（account_table、game_role_table）、原神 4 张（character_list、daily_note、character_detail、character_compute）、星穹铁道 4 张（avatar_basic、daily_note、avatar_info、avatar_compute）、绝区零 4 张（avatar_basic、daily_note、avatar_info、avatar_compute）、辅助表 1 张（sync_meta）。

---

## 词汇表

- **Database**：HarmonyOS ArkData 关系型数据库（RDB），由 `RdbManager` 管理
- **game_data 表**：现有通用表，存储所有游戏所有数据类型，待废弃
- **专用表**：按游戏 + 数据类型命名的新表，如 `genshin_character_list`
- **account_id**：`account_table` 的主键，标识米游社账号
- **role_uid**：游戏内角色 UID，与 `game_role_table.role_id` 对应
- **RdbManager**：`core/src/main/ets/database/RdbManager.ets`，负责数据库初始化和建表
- **GameDataDao**：`core/src/main/ets/database/GameDataDao.ets`，现有通用 DAO
- **Repository**：`core/src/main/ets/repository/` 下各游戏的数据访问层
- **SyncMeta**：`sync_meta` 表，记录每种数据类型的最后同步时间和状态
- **raw_json**：API 返回的完整 JSON 字符串，存储于数据库供详情页解析
- **Parser**：`core/src/main/ets/parsers/` 下各游戏的 JSON 解析器
- **Genshin_DB**：原神专用表集合的统称
- **StarRail_DB**：星穹铁道专用表集合的统称
- **ZZZ_DB**：绝区零专用表集合的统称

---

## 需求

### 需求 1：原神专用表 — 角色列表

**用户故事：** 作为开发者，我希望将原神角色列表数据存入专用表，以便按元素、星级、等级等字段直接过滤，无需解析 raw_json。

#### 验收标准

1. THE **RdbManager** SHALL 创建 `genshin_character_list` 表，包含以下字段：`id`（主键）、`account_id`（INTEGER）、`role_uid`（TEXT）、`avatar_id`（TEXT）、`name`（TEXT）、`element`（TEXT）、`rarity`（INTEGER）、`level`（INTEGER）、`fetter`（INTEGER）、`actived_constellation_num`（INTEGER）、`weapon_type`（INTEGER）、`weapon_id`（TEXT）、`weapon_name`（TEXT）、`weapon_rarity`（INTEGER）、`weapon_level`（INTEGER）、`weapon_affix_level`（INTEGER）、`icon`（TEXT）、`side_icon`（TEXT）、`raw_json`（TEXT）、`update_time`（INTEGER）
2. THE **RdbManager** SHALL 在 `(account_id, role_uid, avatar_id)` 上建立唯一索引
3. THE **RdbManager** SHALL 在 `(account_id, role_uid, element)` 和 `(account_id, role_uid, rarity)` 上建立查询索引
4. WHEN 同一 `(account_id, role_uid, avatar_id)` 的记录已存在，THE **Genshin_DB** SHALL 执行 UPDATE 而非 INSERT（upsert 语义）
5. IF `avatar_id` 为空或 `role_uid` 为空，THEN THE **Genshin_DB** SHALL 拒绝写入并返回错误

### 需求 2：原神专用表 — 实时便笺

**用户故事：** 作为开发者，我希望将原神实时便笺数据存入专用表，以便直接读取树脂、委托、探索派遣等字段，无需每次解析 raw_json。

#### 验收标准

1. THE **RdbManager** SHALL 创建 `genshin_daily_note` 表，包含以下字段：`id`（主键）、`account_id`（INTEGER）、`role_uid`（TEXT）、`current_resin`（INTEGER）、`max_resin`（INTEGER）、`resin_recovery_time`（INTEGER）、`finished_task_num`（INTEGER）、`total_task_num`（INTEGER）、`remain_resin_discount_num`（INTEGER）、`current_expedition_num`（INTEGER）、`max_expedition_num`（INTEGER）、`current_home_coin`（INTEGER）、`max_home_coin`（INTEGER）、`transformer_recovery_day`（INTEGER）、`raw_json`（TEXT）、`update_time`（INTEGER）
2. THE **RdbManager** SHALL 在 `(account_id, role_uid)` 上建立唯一索引（每个角色只保留一条最新便笺）
3. WHEN 同一 `(account_id, role_uid)` 的记录已存在，THE **Genshin_DB** SHALL 执行 UPDATE 覆盖旧数据
4. IF `role_uid` 为空，THEN THE **Genshin_DB** SHALL 拒绝写入并返回错误

### 需求 3：原神专用表 — 角色详情

**用户故事：** 作为开发者，我希望将原神角色详情（含武器、圣遗物、技能）存入专用表，以便详情页直接读取，无需重复网络请求。

#### 验收标准

1. THE **RdbManager** SHALL 创建 `genshin_character_detail` 表，包含以下字段：`id`（主键）、`account_id`（INTEGER）、`role_uid`（TEXT）、`avatar_id`（TEXT）、`weapon_id`（TEXT）、`weapon_level`（INTEGER）、`weapon_affix_level`（INTEGER）、`relic_ids`（TEXT，逗号分隔的圣遗物 ID 列表）、`skill_levels`（TEXT，JSON 数组）、`raw_json`（TEXT）、`update_time`（INTEGER）
2. THE **RdbManager** SHALL 在 `(account_id, role_uid, avatar_id)` 上建立唯一索引
3. WHEN 同一 `(account_id, role_uid, avatar_id)` 的记录已存在，THE **Genshin_DB** SHALL 执行 UPDATE
4. FOR ALL 有效的 `genshin_character_detail` 记录，THE **Genshin_DB** SHALL 保证 `avatar_id` 与 `genshin_character_list` 中对应记录的 `avatar_id` 一致（引用完整性）

### 需求 4：原神专用表 — 养成材料计算

**用户故事：** 作为开发者，我希望将原神角色养成材料计算结果存入专用表，以便离线展示所需材料，无需每次重新调用计算接口。

#### 验收标准

1. THE **RdbManager** SHALL 创建 `genshin_character_compute` 表，包含以下字段：`id`（主键）、`account_id`（INTEGER）、`role_uid`（TEXT）、`avatar_id`（TEXT）、`avatar_consume_json`（TEXT，`items[0].avatar_consume` 数组）、`skill_consume_json`（TEXT，`items[0].avatar_skill_consume` 数组）、`weapon_consume_json`（TEXT，`items[0].weapon_consume` 数组）、`update_time`（INTEGER）
2. THE **RdbManager** SHALL 在 `(account_id, role_uid, avatar_id)` 上建立唯一索引
3. WHEN 同一 `(account_id, role_uid, avatar_id)` 的记录已存在，THE **Genshin_DB** SHALL 执行 UPDATE
4. THE **Genshin_DB** SHALL 在各 consume JSON 中保留每个材料的 `id`、`name`、`icon`、`num`、`lack_num` 字段

### 需求 5：星穹铁道专用表 — 角色列表

**用户故事：** 作为开发者，我希望将星穹铁道角色列表数据存入专用表，以便按命途、元素、星级过滤，无需解析 raw_json。

#### 验收标准

1. THE **RdbManager** SHALL 创建 `starrail_avatar_basic` 表，包含以下字段：`id`（主键）、`account_id`（INTEGER）、`role_uid`（TEXT）、`avatar_id`（TEXT）、`name`（TEXT）、`element`（TEXT）、`element_id`（INTEGER，属性数字 ID）、`rarity`（INTEGER）、`level`（INTEGER）、`rank`（INTEGER，星魂数）、`base_type`（INTEGER，命途）、`equip_id`（TEXT）、`equip_name`（TEXT）、`equip_rarity`（INTEGER）、`equip_level`（INTEGER）、`equip_rank`（INTEGER，叠影）、`icon`（TEXT）、`figure_path`（TEXT）、`raw_json`（TEXT）、`update_time`（INTEGER）
2. THE **RdbManager** SHALL 在 `(account_id, role_uid, avatar_id)` 上建立唯一索引
3. THE **RdbManager** SHALL 在 `(account_id, role_uid, base_type)` 和 `(account_id, role_uid, element)` 上建立查询索引
4. WHEN 同一 `(account_id, role_uid, avatar_id)` 的记录已存在，THE **StarRail_DB** SHALL 执行 UPDATE
5. IF `avatar_id` 为空或 `role_uid` 为空，THEN THE **StarRail_DB** SHALL 拒绝写入并返回错误

### 需求 6：星穹铁道专用表 — 实时便笺

**用户故事：** 作为开发者，我希望将星穹铁道实时便笺数据存入专用表，以便直接读取开拓力、每日实训、模拟宇宙等字段。

#### 验收标准

1. THE **RdbManager** SHALL 创建 `starrail_daily_note` 表，包含以下字段：`id`（主键）、`account_id`（INTEGER）、`role_uid`（TEXT）、`current_stamina`（INTEGER）、`max_stamina`（INTEGER）、`stamina_recover_time`（INTEGER）、`stamina_full_ts`（INTEGER，满体力时间戳）、`current_reserve_stamina`（INTEGER）、`accepted_expedition_num`（INTEGER）、`total_expedition_num`（INTEGER）、`current_train_score`（INTEGER）、`max_train_score`（INTEGER）、`current_rogue_score`（INTEGER）、`max_rogue_score`（INTEGER）、`weekly_cocoon_cnt`（INTEGER）、`weekly_cocoon_limit`（INTEGER）、`rogue_tourn_weekly_cur`（INTEGER）、`rogue_tourn_weekly_max`（INTEGER）、`grid_fight_weekly_cur`（INTEGER，本周已用侵蚀隧洞次数）、`grid_fight_weekly_max`（INTEGER，侵蚀隧洞每周上限）、`raw_json`（TEXT）、`update_time`（INTEGER）
2. THE **RdbManager** SHALL 在 `(account_id, role_uid)` 上建立唯一索引
3. WHEN 同一 `(account_id, role_uid)` 的记录已存在，THE **StarRail_DB** SHALL 执行 UPDATE 覆盖旧数据
4. IF `role_uid` 为空，THEN THE **StarRail_DB** SHALL 拒绝写入并返回错误

### 需求 7：星穹铁道专用表 — 角色详情

**用户故事：** 作为开发者，我希望将星穹铁道角色详情（含光锥、遗器、技能树）存入专用表，以便详情页直接读取。

#### 验收标准

1. THE **RdbManager** SHALL 创建 `starrail_avatar_info` 表，包含以下字段：`id`（主键）、`account_id`（INTEGER）、`role_uid`（TEXT）、`avatar_id`（TEXT）、`equip_id`（TEXT）、`equip_level`（INTEGER）、`equip_rank`（INTEGER）、`relic_ids`（TEXT，逗号分隔）、`skill_tree_json`（TEXT，技能树等级 JSON）、`raw_json`（TEXT）、`update_time`（INTEGER）
2. THE **RdbManager** SHALL 在 `(account_id, role_uid, avatar_id)` 上建立唯一索引
3. WHEN 同一 `(account_id, role_uid, avatar_id)` 的记录已存在，THE **StarRail_DB** SHALL 执行 UPDATE

### 需求 8：绝区零专用表 — 代理人列表

**用户故事：** 作为开发者，我希望将绝区零代理人列表数据存入专用表，以便按属性、职业、星级过滤，无需解析 raw_json。

#### 验收标准

1. THE **RdbManager** SHALL 创建 `zzz_avatar_basic` 表，包含以下字段：`id`（主键）、`account_id`（INTEGER）、`role_uid`（TEXT）、`avatar_id`（TEXT）、`name_mi18n`（TEXT）、`full_name_mi18n`（TEXT）、`element_type`（INTEGER）、`sub_element_type`（INTEGER，副属性）、`avatar_profession`（INTEGER，职业）、`rarity`（TEXT，"S"/"A"）、`level`（INTEGER）、`rank`（INTEGER，影画数）、`camp_name_mi18n`（TEXT，阵营）、`group_icon_path`（TEXT）、`hollow_icon_path`（TEXT）、`role_square_url`（TEXT）、`awaken_state`（TEXT，觉醒状态）、`raw_json`（TEXT）、`update_time`（INTEGER）
2. THE **RdbManager** SHALL 在 `(account_id, role_uid, avatar_id)` 上建立唯一索引
3. THE **RdbManager** SHALL 在 `(account_id, role_uid, element_type)` 和 `(account_id, role_uid, avatar_profession)` 上建立查询索引
4. WHEN 同一 `(account_id, role_uid, avatar_id)` 的记录已存在，THE **ZZZ_DB** SHALL 执行 UPDATE
5. IF `avatar_id` 为空或 `role_uid` 为空，THEN THE **ZZZ_DB** SHALL 拒绝写入并返回错误

### 需求 9：账号维度关联

**用户故事：** 作为开发者，我希望所有专用表都通过 `account_id + role_uid` 关联到账号，以便支持多账号、多角色的数据隔离。

#### 验收标准

1. THE **Database** SHALL 在所有专用表中包含 `account_id`（INTEGER）和 `role_uid`（TEXT）字段
2. THE **Database** SHALL 保证 `account_id` 与 `account_table.id` 的外键约束
3. WHEN 查询某账号某角色的数据，THE **Repository** SHALL 以 `(account_id, role_uid)` 作为必填过滤条件
4. WHEN 删除 `account_table` 中的账号记录，THE **Database** SHALL 级联删除该账号在所有专用表中的数据
5. IF `account_id` 不存在于 `account_table`，THEN THE **Database** SHALL 拒绝向专用表写入数据

### 需求 10：数据同步策略

**用户故事：** 作为开发者，我希望有明确的同步触发时机和更新规则，以便数据保持最新且不产生冗余请求。

#### 验收标准

1. WHEN 用户进入对应游戏的数据页面，THE **Repository** SHALL 检查 `sync_meta` 表中该 `(account_id, role_uid, data_type)` 的 `last_sync_time`
2. WHEN `last_sync_time` 距当前时间超过 300 秒，THE **Repository** SHALL 触发后台网络请求并更新专用表数据
3. WHILE 网络请求进行中，THE **Repository** SHALL 将 `sync_meta.sync_status` 设置为 `"syncing"`
4. WHEN 网络请求成功，THE **Repository** SHALL 以事务方式批量 upsert 专用表数据，并将 `sync_meta.sync_status` 更新为 `"success"`、`last_sync_time` 更新为当前时间戳
5. IF 网络请求失败，THEN THE **Repository** SHALL 将 `sync_meta.sync_status` 设置为 `"failed"`，`error_msg` 记录错误信息，并保留专用表中的旧数据供离线展示
6. THE **SyncMeta** SHALL 使用 `sync_meta` 表追踪同步状态，`data_type` 字段值与专用表名保持一致（如 `"genshin_character_list"`），必须使用 `SyncDataType` 枚举，禁止直接写字符串字面量

### 需求 11：数据库幂等性

**用户故事：** 作为开发者，我希望新表的创建是幂等的，以便重复启动不会报错。

#### 验收标准

1. THE **RdbManager** SHALL 使用 `CREATE TABLE IF NOT EXISTS` 语句创建所有专用表，保证幂等性
2. THE **Database** SHALL 维护一个 `db_version` 整数版本号（初始值为 1），WHEN 版本号低于当前版本，THE **RdbManager** SHALL 执行对应的迁移脚本
3. WHEN 应用首次安装，THE **RdbManager** SHALL 直接建立全部 15 张专用表，`user_version` 设为 1
4. WHEN 应用升级（`user_version < DB_VERSION`），THE **RdbManager** SHALL 按版本顺序执行迁移函数，每个函数在事务中执行，失败时回滚

### 需求 12：Repository 层设计

**用户故事：** 作为开发者，我希望各游戏的 Repository 方法签名清晰稳定，以便 ViewModel 层无需感知底层表结构变化。

#### 验收标准

1. THE **Repository** SHALL 为每款游戏提供独立的 DAO 文件，命名规则为 `<Game>Dao`（如 `GenshinDao`、`StarRailDao`、`ZZZDao`），每个文件内包含该游戏所有专用表的 DAO 类（如 `GenshinCharacterListDao`、`GenshinDailyNoteDao` 等）；账号/角色表使用 `BBSDao`，同步状态表使用 `SyncMetaDaoV2`
2. THE **GenshinRepository** / **StarRailRepository** / **ZZZRepository** SHALL 各自提供 `findAll`、`findById`、`upsertAll`、`deleteAll` 方法，继承自 `GameRepository` 抽象基类
3. THE **BBSRepository** SHALL 独立实现，不继承 `GameRepository`，提供账号和游戏角色的专属查询方法
4. FOR ALL 专用表的写入操作，THE **Repository** SHALL 在同一事务中同步更新 `sync_meta` 表的 `last_sync_time` 和 `sync_status`

### 需求 13：星穹铁道专用表 — 养成材料计算

**用户故事：** 作为开发者，我希望将星穹铁道角色养成材料计算结果存入专用表，以便离线展示所需材料。

#### 验收标准

1. THE **RdbManager** SHALL 创建 `starrail_avatar_compute` 表，包含以下字段：`id`（主键）、`account_id`（INTEGER）、`role_uid`（TEXT）、`avatar_id`（TEXT）、`avatar_consume_json`（TEXT，`data.avatar_consume` 数组）、`skill_consume_json`（TEXT，`data.skill_consume` 数组）、`equipment_consume_json`（TEXT，`data.equipment_consume` 数组）、`update_time`（INTEGER）
2. THE **RdbManager** SHALL 在 `(account_id, role_uid, avatar_id)` 上建立唯一索引
3. WHEN 同一 `(account_id, role_uid, avatar_id)` 的记录已存在，THE **StarRail_DB** SHALL 执行 UPDATE
4. THE **StarRail_DB** SHALL 在各 consume JSON 中保留每个材料的 `item_id`、`item_name`、`item_url`、`num`、`rarity`、`item_purpose` 字段（注意：星穹铁道用 `item_id`/`item_url` 而非 `id`/`icon`，且无 `lack_num` 字段）

### 需求 14：绝区零专用表 — 实时便笺

**用户故事：** 作为开发者，我希望将绝区零实时便笺数据存入专用表，以便直接读取电量、活跃度、录像店状态等字段，无需每次解析 raw_json。

#### 验收标准

1. THE **RdbManager** SHALL 创建 `zzz_daily_note` 表，包含以下字段：`id`（主键）、`account_id`（INTEGER）、`role_uid`（TEXT）、`energy_current`（INTEGER，当前电量）、`energy_max`（INTEGER，电量上限）、`energy_restore`（INTEGER，恢复时间秒数）、`vitality_current`（INTEGER，当前活跃度）、`vitality_max`（INTEGER，活跃度上限）、`vhs_sale_state`（TEXT，录像店状态：SaleStateDone/SaleStateDoing/SaleStateNo）、`card_sign`（TEXT，刮刮卡状态：CardSignDone/CardSignNo）、`raw_json`（TEXT）、`update_time`（INTEGER）
2. THE **RdbManager** SHALL 在 `(account_id, role_uid)` 上建立唯一索引（每个角色只保留一条最新便笺）
3. WHEN 同一 `(account_id, role_uid)` 的记录已存在，THE **ZZZ_DB** SHALL 执行 UPDATE 覆盖旧数据
4. IF `role_uid` 为空，THEN THE **ZZZ_DB** SHALL 拒绝写入并返回错误

### 需求 15：绝区零专用表 — 代理人详情

**用户故事：** 作为开发者，我希望将绝区零代理人详情（含驱动盘、音擎、技能）存入专用表，以便详情页直接读取，无需重复网络请求。

#### 验收标准

1. THE **RdbManager** SHALL 创建 `zzz_avatar_info` 表，包含以下字段：`id`（主键）、`account_id`（INTEGER）、`role_uid`（TEXT）、`avatar_id`（TEXT）、`weapon_id`（TEXT）、`weapon_level`（INTEGER）、`weapon_star`（INTEGER，精炼等级）、`equip_ids`（TEXT，驱动盘 ID 列表，逗号分隔，按 equipment_type 1-6 排序）、`skill_levels_json`（TEXT，技能等级 JSON 数组，含 skill_type 和 level）、`vertical_painting_url`（TEXT，立绘 URL）、`raw_json`（TEXT）、`update_time`（INTEGER）
2. THE **RdbManager** SHALL 在 `(account_id, role_uid, avatar_id)` 上建立唯一索引
3. WHEN 同一 `(account_id, role_uid, avatar_id)` 的记录已存在，THE **ZZZ_DB** SHALL 执行 UPDATE
4. FOR ALL 有效的 `zzz_avatar_info` 记录，THE **ZZZ_DB** SHALL 保证 `avatar_id` 与 `zzz_avatar_basic` 中对应记录的 `avatar_id` 一致

### 需求 16：绝区零专用表 — 养成材料计算

**用户故事：** 作为开发者，我希望将绝区零代理人养成材料计算结果存入专用表，以便离线展示所需材料。

#### 验收标准

1. THE **RdbManager** SHALL 创建 `zzz_avatar_compute` 表，包含以下字段：`id`（主键）、`account_id`（INTEGER）、`role_uid`（TEXT）、`avatar_id`（TEXT）、`avatar_consume_json`（TEXT，代理人养成材料 JSON）、`weapon_consume_json`（TEXT，音擎养成材料 JSON）、`skill_consume_json`（TEXT，技能养成材料 JSON）、`update_time`（INTEGER）
2. THE **RdbManager** SHALL 在 `(account_id, role_uid, avatar_id)` 上建立唯一索引
3. WHEN 同一 `(account_id, role_uid, avatar_id)` 的记录已存在，THE **ZZZ_DB** SHALL 执行 UPDATE
4. THE **ZZZ_DB** SHALL 在各 consume JSON 中保留每个材料的 `id`、`name`、`icon`、`cnt`、`rarity`、`not_opened` 字段（注意：绝区零用 `cnt` 而非 `num` 表示数量）
