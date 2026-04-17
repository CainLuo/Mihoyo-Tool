# 设计文档：game-data-database-redesign

## 命名说明（V2 后缀的由来）

本次重构目标是全新的 V1.0 架构，最终代码里不应有 `V2` 后缀。但由于旧代码（`CoreInitializer.ets`、`RdbManager.ets`、`database/`、`repository/`、`network/` 等）在重构完成前仍需保留，为避免新旧代码命名冲突，**过渡期临时使用 `V2` 后缀**：

| 过渡期命名（临时）  | 最终命名（旧代码删除后） |
| ------------------- | ------------------------ |
| `CoreInitializerV2` | `CoreInitializer`        |
| `RdbManagerV2`      | `RdbManager`             |
| `DSUtilV2`          | `DSUtil`                 |
| `ApiConfigV2`       | `ApiConfig`              |
| `SyncMetaDaoV2`     | `SyncMetaDao`            |
| `AccountRowV2`      | `AccountRow`             |
| `GameRoleRowV2`     | `GameRoleRow`            |
| `database/v2/`      | `database/`              |
| `repository/v2/`    | `repository/`            |
| `network/v2/`       | `network/`               |

> `AccountRowV2` 字段对应 `account_table` 所有列（含 `uid`/`nickname`/`avatar_url`/`introduce`/`raw_json`；`stoken`/`stuid`/`mid` 已移除，stoken 直接拼入 `cookie` 字段存储）。`GameRoleRowV2` 字段对应 `game_role_table` 所有列（含新增的 `game_biz`/`game_type`/`region_name`/`is_chosen`/`is_public`/`bg_image_url`/`stats_json`）。实现时直接按表定义映射即可。

**实施顺序：**

1. 按本设计文档实现所有新代码（带 `V2` 后缀）
2. 将所有调用方（entry 模块）切换到新代码
3. 删除旧代码目录和文件
4. 全局重命名去掉 `V2` 后缀（使用 IDE 的 Rename Symbol 功能）

---

## 概述

全新数据库设计，按游戏类型和数据类型建立专用表，每张表字段直接对应 API 返回结构。共 **15 张表**：

- 基础表 2 张：`account_table`、`game_role_table`
- 原神专用表 4 张：`genshin_character_list`、`genshin_daily_note`、`genshin_character_detail`、`genshin_character_compute`
- 星穹铁道专用表 4 张：`starrail_avatar_basic`、`starrail_daily_note`、`starrail_avatar_info`、`starrail_avatar_compute`
- 绝区零专用表 4 张：`zzz_avatar_basic`、`zzz_daily_note`、`zzz_avatar_info`、`zzz_avatar_compute`
- 辅助表 1 张：`sync_meta`

> 注意：mock 文件共 16 个，其中 `genshin_character_detail` 表对应两个接口（单角色查询 `character_detail.json` 和批量查询 `character_detail_all.json`），两个接口写入同一张表，因此表数量仍为 15 张。

对应 16 个 mock 文件（`genshin_character_detail` 表对应两个接口：单角色查询和批量查询，写入同一张表）：

| mock 文件                                               | 对应表                                   |
| ------------------------------------------------------- | ---------------------------------------- |
| `user_wapi_getUserFullInfo.json`                        | `account_table`                          |
| `binding_api_getUserGameRolesByCookie.json`             | `game_role_table`                        |
| `game_record_app_card_wapi_getGameRecordCard.json`      | `game_role_table`（补充 bg_image/stats） |
| `game_record_app_genshin_api_character_list.json`       | `genshin_character_list`                 |
| `game_record_app_genshin_api_dailyNote.json`            | `genshin_daily_note`                     |
| `game_record_app_genshin_api_character_detail.json`     | `genshin_character_detail`（单角色）     |
| `game_record_app_genshin_api_character_detail_all.json` | `genshin_character_detail`（批量）       |
| `genshin_character_batch_compute.json`                  | `genshin_character_compute`              |
| `game_record_app_hkrpg_api_avatar_basic.json`           | `starrail_avatar_basic`                  |
| `game_record_app_hkrpg_api_note.json`                   | `starrail_daily_note`                    |
| `game_record_app_hkrpg_api_avatar_info.json`            | `starrail_avatar_info`                   |
| `hkrpg_character_compute.json`                          | `starrail_avatar_compute`                |
| `event_game_record_zzz_api_zzz_avatar_basic.json`       | `zzz_avatar_basic`                       |
| `event_game_record_zzz_api_zzz_note.json`               | `zzz_daily_note`                         |
| `event_game_record_zzz_api_zzz_avatar_info.json`        | `zzz_avatar_info`                        |
| `zzz_character_compute.json`                            | `zzz_avatar_compute`                     |

**设计原则：**

- 全新数据库，无旧表兼容，无迁移逻辑
- 所有表使用 `CREATE TABLE IF NOT EXISTS`，保证幂等性
- 通过 `account_id + role_uid` 实现多账号数据隔离
- `sync_meta` 追踪每张专用表的同步状态

---

## 架构

```
RdbManagerV2.createTables()
    │
    ├── 基础表
    │   ├── account_table
    │   └── game_role_table
    │
    ├── 原神专用表
    │   ├── genshin_character_list
    │   ├── genshin_daily_note
    │   ├── genshin_character_detail
    │   └── genshin_character_compute
    │
    ├── 星穹铁道专用表
    │   ├── starrail_avatar_basic
    │   ├── starrail_daily_note
    │   ├── starrail_avatar_info
    │   └── starrail_avatar_compute
    │
    ├── 绝区零专用表
    │   ├── zzz_avatar_basic
    │   ├── zzz_daily_note
    │   ├── zzz_avatar_info
    │   └── zzz_avatar_compute
    │
    └── 辅助表
        └── sync_meta
```

数据流：

```
API 响应 JSON
    │
    ▼
Repository.upsert()  ←── 事务写入专用表 + 更新 sync_meta
    │
    ▼
专用表（结构化字段 + raw_json）
    │
    ├── 列表页：直接读结构化字段（无需解析 raw_json）
    └── 详情页：读 raw_json → Parser 解析 → 业务模型
```

---

## 组件与接口

### DAO 层

| DAO 类名                     | 对应表                      |
| ---------------------------- | --------------------------- |
| `AccountDao`                 | `account_table`             |
| `GameRoleDao`                | `game_role_table`           |
| `GenshinCharacterListDao`    | `genshin_character_list`    |
| `GenshinDailyNoteDao`        | `genshin_daily_note`        |
| `GenshinCharacterDetailDao`  | `genshin_character_detail`  |
| `GenshinCharacterComputeDao` | `genshin_character_compute` |
| `StarRailAvatarBasicDao`     | `starrail_avatar_basic`     |
| `StarRailDailyNoteDao`       | `starrail_daily_note`       |
| `StarRailAvatarInfoDao`      | `starrail_avatar_info`      |
| `StarRailAvatarComputeDao`   | `starrail_avatar_compute`   |
| `ZZZAvatarBasicDao`          | `zzz_avatar_basic`          |
| `ZZZDailyNoteDao`            | `zzz_daily_note`            |
| `ZZZAvatarInfoDao`           | `zzz_avatar_info`           |
| `ZZZAvatarComputeDao`        | `zzz_avatar_compute`        |
| `SyncMetaDaoV2`              | `sync_meta`                 |

### Repository 层

- `BBSRepository`：账号和游戏角色的读写（独立，不继承 `GameRepository`）
- `GenshinRepository`：原神四张表的读写
- `StarRailRepository`：星穹铁道四张表的读写
- `ZZZRepository`：绝区零四张表的读写
- `SignRepository`：签到状态管理（不写入 DB，仅封装签到 API 调用和 Geetest 重试逻辑）
- 所有写入操作在同一事务中同步更新 `sync_meta`

---

## 数据模型

### 表 1：account_table

**数据流：** `user_wapi_getUserFullInfo` 写入，登录/刷新账号信息时更新。

> **设计说明：** `stoken`/`stuid`/`mid` 已从独立字段移除。手机号/二维码登录获取的 stoken 直接拼入 `cookie` 字符串存储（格式：`account_id=xxx; cookie_token=xxx; ltoken=xxx; ltuid=xxx; stoken=xxx; stuid=xxx; mid=xxx`），Cookie 登录则存用户粘贴的原始字符串。所有 API 请求直接使用 `cookie` 字段，无需单独提取 stoken。

```sql
CREATE TABLE IF NOT EXISTS account_table (
  id          INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  username    TEXT UNIQUE NOT NULL,              -- 米游社 account_id，唯一
  cookie      TEXT        NOT NULL,              -- 完整 Cookie 字符串（含 stoken/ltoken/cookie_token 等）
  is_active   INTEGER     DEFAULT 0,             -- 是否为当前激活账号（0/1）
  create_time INTEGER,                           -- 创建时间戳（Unix 秒）
  update_time INTEGER,                           -- 最后更新时间戳（Unix 秒）
  uid         TEXT        DEFAULT '',            -- 米游社 UID（user_info.uid）
  nickname    TEXT        DEFAULT '',            -- 米游社昵称（user_info.nickname）
  avatar_url  TEXT        DEFAULT '',            -- 头像完整 URL（user_info.avatar_url，非 user_info.avatar）
  introduce   TEXT        DEFAULT '',            -- 个人简介（user_info.introduce）
  raw_json    TEXT        DEFAULT ''             -- getUserFullInfo 完整响应 JSON
);
```

| 字段名      | 类型    | 来源 API 字段          | 说明                                                                                     |
| ----------- | ------- | ---------------------- | ---------------------------------------------------------------------------------------- |
| id          | INTEGER | —                      | 主键，自增                                                                               |
| username    | TEXT    | —                      | 米游社 account_id，唯一                                                                  |
| cookie      | TEXT    | —                      | 完整 Cookie 字符串（手机号/二维码登录含 stoken；Cookie 登录存原始字符串）                |
| is_active   | INTEGER | —                      | 是否为当前激活账号（0/1）                                                                |
| create_time | INTEGER | —                      | 创建时间戳（Unix 秒）                                                                    |
| update_time | INTEGER | —                      | 最后更新时间戳                                                                           |
| uid         | TEXT    | `user_info.uid`        | 米游社 UID                                                                               |
| nickname    | TEXT    | `user_info.nickname`   | 米游社昵称                                                                               |
| avatar_url  | TEXT    | `user_info.avatar_url` | 头像完整 URL（注意：`user_info.avatar` 是头像 ID 数字字符串，`avatar_url` 才是完整 URL） |
| introduce   | TEXT    | `user_info.introduce`  | 个人简介                                                                                 |
| raw_json    | TEXT    | —                      | getUserFullInfo 完整响应 JSON                                                            |

---

### 表 2：game_role_table

**数据流：** `binding_api_getUserGameRolesByCookie` + `game_record_app_card_wapi_getGameRecordCard` 写入，登录/刷新时更新。

```sql
CREATE TABLE IF NOT EXISTS game_role_table (
  id           INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id   INTEGER NOT NULL,                  -- 关联 account_table.id
  game_id      TEXT    NOT NULL,                  -- 游戏标识（内部枚举：genshin/starrail/zzz）
  game_biz     TEXT    DEFAULT '',                -- 原始业务标识（如 hk4e_cn）
  game_type    INTEGER DEFAULT 0,                 -- 游戏类型数字（game_id 字段：1=崩坏3 2=原神 6=星铁 8=绝区零）
  role_id      TEXT    NOT NULL,                  -- 游戏内 UID
  nickname     TEXT    DEFAULT '',                -- 游戏内昵称
  level        INTEGER DEFAULT 0,                 -- 游戏内等级
  server       TEXT    DEFAULT '',                -- 服务器代码（如 cn_gf01）
  region_name  TEXT    DEFAULT '',                -- 服务器显示名（如 天空岛）
  is_chosen    INTEGER DEFAULT 0,                 -- 是否被选中（0/1）
  is_public    INTEGER DEFAULT 0,                 -- 战绩是否公开（0/1）
  bg_image_url TEXT    DEFAULT '',                -- 游戏背景图 URL（优先用 background_image_v2，为空时 fallback 到 background_image）
  stats_json   TEXT    DEFAULT '',                -- 统计数据 JSON 数组（data 字段）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE INDEX IF NOT EXISTS idx_game_role_account
  ON game_role_table(account_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_game_role_unique
  ON game_role_table(account_id, game_id, role_id);
```

| 字段名       | 类型    | 来源 API 字段                                                 | 说明                                                                  |
| ------------ | ------- | ------------------------------------------------------------- | --------------------------------------------------------------------- |
| id           | INTEGER | —                                                             | 主键，自增                                                            |
| account_id   | INTEGER | —                                                             | 关联 account_table.id                                                 |
| game_id      | TEXT    | —                                                             | 游戏标识（内部枚举）                                                  |
| game_biz     | TEXT    | `game_biz`（getUserGameRolesByCookie）                        | 原始业务标识                                                          |
| game_type    | INTEGER | `game_id`（getGameRecordCard）                                | 游戏类型数字（1=崩坏3 2=原神 6=星铁 8=绝区零）                        |
| role_id      | TEXT    | `game_uid`                                                    | 游戏内 UID                                                            |
| nickname     | TEXT    | `nickname`                                                    | 游戏内昵称                                                            |
| level        | INTEGER | `level`                                                       | 游戏内等级                                                            |
| server       | TEXT    | `region`                                                      | 服务器代码                                                            |
| region_name  | TEXT    | `region_name`                                                 | 服务器显示名                                                          |
| is_chosen    | INTEGER | `is_chosen`                                                   | 是否被选中                                                            |
| is_public    | INTEGER | `is_public`（getGameRecordCard）                              | 战绩是否公开                                                          |
| bg_image_url | TEXT    | `background_image_v2`（优先）/ `background_image`（fallback） | 游戏背景图 URL（v2 为新版，绝区零等新游戏 background_image 可能为空） |
| stats_json   | TEXT    | `data`（getGameRecordCard）                                   | 统计数据 JSON 数组                                                    |

---

### 表 3：genshin_character_list

**数据流：** `game_record_app_genshin_api_character_list` 写入，进入原神角色页时触发同步。

```sql
CREATE TABLE IF NOT EXISTS genshin_character_list (
  id                        INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id                INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid                  TEXT    NOT NULL,                  -- 游戏内角色 UID
  avatar_id                 TEXT    NOT NULL,                  -- 角色 ID（如 10000125）
  name                      TEXT,                              -- 角色名称
  element                   TEXT,                              -- 元素属性（如 Hydro）
  rarity                    INTEGER,                           -- 星级（4 或 5）
  level                     INTEGER,                           -- 角色等级
  fetter                    INTEGER,                           -- 好感度（0-10）
  actived_constellation_num INTEGER,                           -- 已激活命座数（0-6）
  weapon_type               INTEGER,                           -- 武器类型数字
  weapon_id                 TEXT,                              -- 武器 ID
  weapon_name               TEXT,                              -- 武器名称
  weapon_rarity             INTEGER,                           -- 武器星级
  weapon_level              INTEGER,                           -- 武器等级
  weapon_affix_level        INTEGER,                           -- 武器精炼等级（1-5）
  icon                      TEXT,                              -- 角色图标 URL
  side_icon                 TEXT,                              -- 角色侧面图标 URL
  raw_json                  TEXT    NOT NULL,                  -- 单条角色完整 JSON
  update_time               INTEGER,                           -- 最后更新时间戳（Unix 秒）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_genshin_char_list_unique
  ON genshin_character_list(account_id, role_uid, avatar_id);

CREATE INDEX IF NOT EXISTS idx_genshin_char_list_element
  ON genshin_character_list(account_id, role_uid, element);

CREATE INDEX IF NOT EXISTS idx_genshin_char_list_rarity
  ON genshin_character_list(account_id, role_uid, rarity);
```

| 字段名                    | 类型    | 来源 API 字段               | 说明                      |
| ------------------------- | ------- | --------------------------- | ------------------------- |
| id                        | INTEGER | —                           | 主键，自增                |
| account_id                | INTEGER | —                           | 关联 account_table.id     |
| role_uid                  | TEXT    | —                           | 游戏内角色 UID            |
| avatar_id                 | TEXT    | `id`                        | 角色 ID，如 10000125      |
| name                      | TEXT    | `name`                      | 角色名称                  |
| element                   | TEXT    | `element`                   | 元素属性，如 "Hydro"      |
| rarity                    | INTEGER | `rarity`                    | 星级，4 或 5              |
| level                     | INTEGER | `level`                     | 角色等级                  |
| fetter                    | INTEGER | `fetter`                    | 好感度 0-10               |
| actived_constellation_num | INTEGER | `actived_constellation_num` | 已激活命座数 0-6          |
| weapon_type               | INTEGER | `weapon_type`               | 武器类型数字              |
| weapon_id                 | TEXT    | `weapon.id`                 | 武器 ID                   |
| weapon_name               | TEXT    | `weapon.name`               | 武器名称                  |
| weapon_rarity             | INTEGER | `weapon.rarity`             | 武器星级                  |
| weapon_level              | INTEGER | `weapon.level`              | 武器等级                  |
| weapon_affix_level        | INTEGER | `weapon.affix_level`        | 武器精炼等级 1-5          |
| icon                      | TEXT    | `icon`                      | 角色图标 URL              |
| side_icon                 | TEXT    | `side_icon`                 | 角色侧面图标 URL          |
| raw_json                  | TEXT    | —                           | 单条角色完整 JSON         |
| update_time               | INTEGER | —                           | 最后更新时间戳（Unix 秒） |

---

### 表 4：genshin_daily_note

**数据流：** `game_record_app_genshin_api_dailyNote` 写入，每个角色只保留一条最新记录。

```sql
CREATE TABLE IF NOT EXISTS genshin_daily_note (
  id                        INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id                INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid                  TEXT    NOT NULL,                  -- 游戏内角色 UID（每角色唯一一条）
  current_resin             INTEGER,                           -- 当前树脂值
  max_resin                 INTEGER,                           -- 树脂上限（通常 200）
  resin_recovery_time       INTEGER,                           -- 树脂恢复剩余秒数
  finished_task_num         INTEGER,                           -- 已完成每日委托数
  total_task_num            INTEGER,                           -- 每日委托总数
  remain_resin_discount_num INTEGER,                           -- 剩余周本减半次数
  current_expedition_num    INTEGER,                           -- 当前派遣中的角色数
  max_expedition_num        INTEGER,                           -- 最大派遣槽位数
  current_home_coin         INTEGER,                           -- 当前洞天宝钱数量
  max_home_coin             INTEGER,                           -- 洞天宝钱上限
  transformer_recovery_day  INTEGER,                           -- 参量质变仪剩余恢复天数
  raw_json                  TEXT    NOT NULL,                  -- 完整便笺 JSON
  update_time               INTEGER,                           -- 最后更新时间戳（Unix 秒）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_genshin_daily_note_unique
  ON genshin_daily_note(account_id, role_uid);
```

| 字段名                    | 类型    | 来源 API 字段                         | 说明                      |
| ------------------------- | ------- | ------------------------------------- | ------------------------- |
| id                        | INTEGER | —                                     | 主键，自增                |
| account_id                | INTEGER | —                                     | 关联 account_table.id     |
| role_uid                  | TEXT    | —                                     | 游戏内角色 UID            |
| current_resin             | INTEGER | `current_resin`                       | 当前树脂值                |
| max_resin                 | INTEGER | `max_resin`                           | 树脂上限（通常为 200）    |
| resin_recovery_time       | INTEGER | `resin_recovery_time`（字符串转整数） | 树脂恢复剩余秒数          |
| finished_task_num         | INTEGER | `finished_task_num`                   | 已完成每日委托数          |
| total_task_num            | INTEGER | `total_task_num`                      | 每日委托总数              |
| remain_resin_discount_num | INTEGER | `remain_resin_discount_num`           | 剩余周本减半次数          |
| current_expedition_num    | INTEGER | `current_expedition_num`              | 当前派遣中的角色数        |
| max_expedition_num        | INTEGER | `max_expedition_num`                  | 最大派遣槽位数            |
| current_home_coin         | INTEGER | `current_home_coin`                   | 当前洞天宝钱数量          |
| max_home_coin             | INTEGER | `max_home_coin`                       | 洞天宝钱上限              |
| transformer_recovery_day  | INTEGER | `transformer.recovery_time.Day`       | 参量质变仪剩余恢复天数    |
| raw_json                  | TEXT    | —                                     | 完整便笺 JSON             |
| update_time               | INTEGER | —                                     | 最后更新时间戳（Unix 秒） |

---

### 表 5：genshin_character_detail

**数据流：** `game_record_app_genshin_api_character_detail` 写入，进入角色详情页时触发同步。

```sql
CREATE TABLE IF NOT EXISTS genshin_character_detail (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id         INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid           TEXT    NOT NULL,                  -- 游戏内角色 UID
  avatar_id          TEXT    NOT NULL,                  -- 角色 ID（对应 list[].base.id）
  weapon_id          TEXT,                              -- 武器 ID（list[].weapon.id）
  weapon_level       INTEGER,                           -- 武器等级
  weapon_affix_level INTEGER,                           -- 武器精炼等级（1-5）
  relic_ids          TEXT,                              -- 圣遗物 ID 列表，逗号分隔（pos 1-5）
  skill_levels       TEXT,                              -- 技能等级 JSON 数组（含 skill_id 和 level）
  raw_json           TEXT    NOT NULL,                  -- 单条角色完整详情 JSON（含 relics/constellations/skills）
  update_time        INTEGER,                           -- 最后更新时间戳（Unix 秒）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_genshin_char_detail_unique
  ON genshin_character_detail(account_id, role_uid, avatar_id);
```

| 字段名             | 类型    | 来源 API 字段               | 说明                                                     |
| ------------------ | ------- | --------------------------- | -------------------------------------------------------- |
| id                 | INTEGER | —                           | 主键，自增                                               |
| account_id         | INTEGER | —                           | 关联 account_table.id                                    |
| role_uid           | TEXT    | —                           | 游戏内角色 UID                                           |
| avatar_id          | TEXT    | `list[].base.id`            | 角色 ID                                                  |
| weapon_id          | TEXT    | `list[].weapon.id`          | 武器 ID                                                  |
| weapon_level       | INTEGER | `list[].weapon.level`       | 武器等级                                                 |
| weapon_affix_level | INTEGER | `list[].weapon.affix_level` | 武器精炼等级 1-5                                         |
| relic_ids          | TEXT    | `list[].relics[].id`        | 圣遗物 ID 列表，逗号分隔，共 5 件（pos 1-5）             |
| skill_levels       | TEXT    | `list[].skills[].level`     | 技能等级 JSON 数组，每项含 skill_id 和 level             |
| raw_json           | TEXT    | —                           | 单条角色完整详情 JSON（含 relics/constellations/skills） |
| update_time        | INTEGER | —                           | 最后更新时间戳（Unix 秒）                                |

---

### 表 6：genshin_character_compute

**数据流：** 养成计算接口写入，用户触发计算时更新。

```sql
CREATE TABLE IF NOT EXISTS genshin_character_compute (
  id                       INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id               INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid                 TEXT    NOT NULL,                  -- 游戏内角色 UID
  avatar_id                TEXT    NOT NULL,                  -- 角色 ID
  avatar_consume_json      TEXT,                              -- 角色养成材料 JSON（items[0].avatar_consume，含 id/name/icon/num/lack_num）
  skill_consume_json       TEXT,                              -- 技能养成材料 JSON（items[0].avatar_skill_consume，字段同上）
  weapon_consume_json      TEXT,                              -- 武器养成材料 JSON（items[0].weapon_consume，字段同上）
  update_time              INTEGER,                           -- 最后更新时间戳（Unix 秒）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_genshin_char_compute_unique
  ON genshin_character_compute(account_id, role_uid, avatar_id);
```

| 字段名              | 类型    | 来源 API 字段                        | 说明                                                                   |
| ------------------- | ------- | ------------------------------------ | ---------------------------------------------------------------------- |
| id                  | INTEGER | —                                    | 主键，自增                                                             |
| account_id          | INTEGER | —                                    | 关联 account_table.id                                                  |
| role_uid            | TEXT    | —                                    | 游戏内角色 UID                                                         |
| avatar_id           | TEXT    | —                                    | 角色 ID                                                                |
| avatar_consume_json | TEXT    | `data.items[0].avatar_consume`       | 角色养成材料 JSON 数组，每项含 `id`、`name`、`icon`、`num`、`lack_num` |
| skill_consume_json  | TEXT    | `data.items[0].avatar_skill_consume` | 技能养成材料 JSON 数组，字段同上                                       |
| weapon_consume_json | TEXT    | `data.items[0].weapon_consume`       | 武器养成材料 JSON 数组，字段同上                                       |
| update_time         | INTEGER | —                                    | 最后更新时间戳（Unix 秒）                                              |

> 注意：原神 `batch_compute` 接口返回 `data.items[]` 数组（批量计算多个角色），每个 item 对应一个角色。单角色计算时取 `items[0]`，批量时按 `avatar_id` 匹配对应 item 后分别存储。

---

### 表 7：starrail_avatar_basic

**数据流：** `game_record_app_hkrpg_api_avatar_basic` 写入，进入星穹铁道角色页时触发同步。

```sql
CREATE TABLE IF NOT EXISTS starrail_avatar_basic (
  id           INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id   INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid     TEXT    NOT NULL,                  -- 游戏内角色 UID
  avatar_id    TEXT    NOT NULL,                  -- 角色 ID（如 8006）
  name         TEXT,                              -- 角色名称
  element      TEXT,                              -- 属性（imaginary/lightning/ice/fire/wind/quantum/physical）
  rarity       INTEGER,                           -- 星级（4 或 5）
  level        INTEGER,                           -- 角色等级
  rank         INTEGER,                           -- 星魂数（0-6）
  base_type    INTEGER,                           -- 命途数字（1=毁灭 2=巡猎 3=智识 4=同谐 5=虚无 6=存护 7=丰饶）
  equip_id     TEXT,                              -- 光锥 ID（equip 为 null 时留空）
  equip_name   TEXT,                              -- 光锥名称
  equip_rarity INTEGER,                           -- 光锥星级
  equip_level  INTEGER,                           -- 光锥等级
  equip_rank   INTEGER,                           -- 光锥叠影（1-5）
  icon         TEXT,                              -- 角色图标 URL
  figure_path  TEXT,                              -- 角色立绘 URL
  element_id   INTEGER,                           -- 属性数字 ID（1=物理 2=火 4=冰 8=雷 16=风 32=量子 64=虚数）
  raw_json     TEXT    NOT NULL,                  -- 单条角色完整 JSON
  update_time  INTEGER,                           -- 最后更新时间戳（Unix 秒）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_starrail_avatar_basic_unique
  ON starrail_avatar_basic(account_id, role_uid, avatar_id);

CREATE INDEX IF NOT EXISTS idx_starrail_avatar_basic_type
  ON starrail_avatar_basic(account_id, role_uid, base_type);

CREATE INDEX IF NOT EXISTS idx_starrail_avatar_basic_element
  ON starrail_avatar_basic(account_id, role_uid, element);
```

| 字段名       | 类型    | 来源 API 字段  | 说明                                                                                |
| ------------ | ------- | -------------- | ----------------------------------------------------------------------------------- |
| id           | INTEGER | —              | 主键，自增                                                                          |
| account_id   | INTEGER | —              | 关联 account_table.id                                                               |
| role_uid     | TEXT    | —              | 游戏内角色 UID                                                                      |
| avatar_id    | TEXT    | `id`           | 角色 ID，如 8006                                                                    |
| name         | TEXT    | `name`         | 角色名称                                                                            |
| element      | TEXT    | `element`      | 属性，如 "imaginary"、"lightning"、"ice"、"fire"、"wind"、"quantum"、"physical"     |
| rarity       | INTEGER | `rarity`       | 星级，4 或 5                                                                        |
| level        | INTEGER | `level`        | 角色等级                                                                            |
| rank         | INTEGER | `rank`         | 星魂数 0-6                                                                          |
| base_type    | INTEGER | `base_type`    | 命途数字（1=毁灭 2=巡猎 3=智识 4=同谐 5=虚无 6=存护 7=丰饶）                        |
| equip_id     | TEXT    | `equip.id`     | 光锥 ID（equip 为 null 时留空）                                                     |
| equip_name   | TEXT    | `equip.name`   | 光锥名称                                                                            |
| equip_rarity | INTEGER | `equip.rarity` | 光锥星级                                                                            |
| equip_level  | INTEGER | `equip.level`  | 光锥等级                                                                            |
| equip_rank   | INTEGER | `equip.rank`   | 光锥叠影 1-5                                                                        |
| icon         | TEXT    | `icon`         | 角色图标 URL                                                                        |
| figure_path  | TEXT    | `figure_path`  | 角色立绘 URL                                                                        |
| element_id   | INTEGER | `element_id`   | 属性数字 ID（1=物理 2=火 4=冰 8=雷 16=风 32=量子 64=虚数，与 `element` 字符串对应） |
| raw_json     | TEXT    | —              | 单条角色完整 JSON                                                                   |
| update_time  | INTEGER | —              | 最后更新时间戳（Unix 秒）                                                           |

---

### 表 8：starrail_daily_note

**数据流：** `game_record_app_hkrpg_api_note` 写入，每个角色只保留一条最新记录。

```sql
CREATE TABLE IF NOT EXISTS starrail_daily_note (
  id                          INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id                  INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid                    TEXT    NOT NULL,                  -- 游戏内角色 UID（每角色唯一一条）
  current_stamina             INTEGER,                           -- 当前开拓力
  max_stamina                 INTEGER,                           -- 开拓力上限（通常 300）
  stamina_recover_time        INTEGER,                           -- 开拓力恢复剩余秒数
  stamina_full_ts             INTEGER,                           -- 开拓力满时的 Unix 时间戳
  current_reserve_stamina     INTEGER,                           -- 当前后备开拓力（上限 2400）
  accepted_expedition_num     INTEGER,                           -- 当前派遣中的角色数（API 原字段拼写为 epedition）
  total_expedition_num        INTEGER,                           -- 最大派遣槽位数
  current_train_score         INTEGER,                           -- 当前每日实训积分
  max_train_score             INTEGER,                           -- 每日实训积分上限（通常 500）
  current_rogue_score         INTEGER,                           -- 当前模拟宇宙积分
  max_rogue_score             INTEGER,                           -- 模拟宇宙积分上限（通常 14000）
  weekly_cocoon_cnt           INTEGER,                           -- 本周已用拟造花萼次数
  weekly_cocoon_limit         INTEGER,                           -- 拟造花萼每周上限（通常 3）
  rogue_tourn_weekly_cur      INTEGER,                           -- 差分宇宙本周积分
  rogue_tourn_weekly_max      INTEGER,                           -- 差分宇宙本周积分上限（通常 1000）
  grid_fight_weekly_cur       INTEGER,                           -- 本周已用侵蚀隧洞次数
  grid_fight_weekly_max       INTEGER,                           -- 侵蚀隧洞每周上限
  raw_json                    TEXT    NOT NULL,                  -- 完整便笺 JSON
  update_time                 INTEGER,                           -- 最后更新时间戳（Unix 秒）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_starrail_daily_note_unique
  ON starrail_daily_note(account_id, role_uid);
```

| 字段名                  | 类型    | 来源 API 字段             | 说明                                                      |
| ----------------------- | ------- | ------------------------- | --------------------------------------------------------- |
| id                      | INTEGER | —                         | 主键，自增                                                |
| account_id              | INTEGER | —                         | 关联 account_table.id                                     |
| role_uid                | TEXT    | —                         | 游戏内角色 UID                                            |
| current_stamina         | INTEGER | `current_stamina`         | 当前开拓力                                                |
| max_stamina             | INTEGER | `max_stamina`             | 开拓力上限（通常为 300）                                  |
| stamina_recover_time    | INTEGER | `stamina_recover_time`    | 开拓力恢复剩余秒数                                        |
| stamina_full_ts         | INTEGER | `stamina_full_ts`         | 开拓力满时的 Unix 时间戳                                  |
| current_reserve_stamina | INTEGER | `current_reserve_stamina` | 当前后备开拓力（上限 2400）                               |
| accepted_expedition_num | INTEGER | `accepted_epedition_num`  | 当前派遣中的角色数（注意 API 原字段有拼写错误 epedition） |
| total_expedition_num    | INTEGER | `total_expedition_num`    | 最大派遣槽位数                                            |
| current_train_score     | INTEGER | `current_train_score`     | 当前每日实训积分                                          |
| max_train_score         | INTEGER | `max_train_score`         | 每日实训积分上限（通常为 500）                            |
| current_rogue_score     | INTEGER | `current_rogue_score`     | 当前模拟宇宙积分                                          |
| max_rogue_score         | INTEGER | `max_rogue_score`         | 模拟宇宙积分上限（通常为 14000）                          |
| weekly_cocoon_cnt       | INTEGER | `weekly_cocoon_cnt`       | 本周已用拟造花萼次数                                      |
| weekly_cocoon_limit     | INTEGER | `weekly_cocoon_limit`     | 拟造花萼每周上限（通常为 3）                              |
| rogue_tourn_weekly_cur  | INTEGER | `rogue_tourn_weekly_cur`  | 差分宇宙本周积分                                          |
| rogue_tourn_weekly_max  | INTEGER | `rogue_tourn_weekly_max`  | 差分宇宙本周积分上限（通常为 1000）                       |
| grid_fight_weekly_cur   | INTEGER | `grid_fight_weekly_cur`   | 本周已用侵蚀隧洞次数                                      |
| grid_fight_weekly_max   | INTEGER | `grid_fight_weekly_max`   | 侵蚀隧洞每周上限                                          |
| raw_json                | TEXT    | —                         | 完整便笺 JSON                                             |
| update_time             | INTEGER | —                         | 最后更新时间戳（Unix 秒）                                 |

---

### 表 9：starrail_avatar_info

**数据流：** `game_record_app_hkrpg_api_avatar_info` 写入，进入角色详情页时触发同步。

```sql
CREATE TABLE IF NOT EXISTS starrail_avatar_info (
  id              INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id      INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid        TEXT    NOT NULL,                  -- 游戏内角色 UID
  avatar_id       TEXT    NOT NULL,                  -- 角色 ID（avatar_list[].id）
  equip_id        TEXT,                              -- 光锥 ID（equip 为 null 时留空）
  equip_level     INTEGER,                           -- 光锥等级
  equip_rank      INTEGER,                           -- 光锥叠影（1-5）
  relic_ids       TEXT,                              -- 遗器 ID 列表，逗号分隔（relics pos 1-4 + ornaments pos 5-6）
  skill_tree_json TEXT,                              -- 技能树 JSON 数组（含 point_id/level/is_activated）
  raw_json        TEXT    NOT NULL,                  -- 单条角色完整详情 JSON（含 relics/ornaments/ranks/properties/skills）
  update_time     INTEGER,                           -- 最后更新时间戳（Unix 秒）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_starrail_avatar_info_unique
  ON starrail_avatar_info(account_id, role_uid, avatar_id);
```

| 字段名          | 类型    | 来源 API 字段                                                | 说明                                                                 |
| --------------- | ------- | ------------------------------------------------------------ | -------------------------------------------------------------------- |
| id              | INTEGER | —                                                            | 主键，自增                                                           |
| account_id      | INTEGER | —                                                            | 关联 account_table.id                                                |
| role_uid        | TEXT    | —                                                            | 游戏内角色 UID                                                       |
| avatar_id       | TEXT    | `avatar_list[].id`                                           | 角色 ID                                                              |
| equip_id        | TEXT    | `avatar_list[].equip.id`                                     | 光锥 ID（equip 为 null 时留空）                                      |
| equip_level     | INTEGER | `avatar_list[].equip.level`                                  | 光锥等级                                                             |
| equip_rank      | INTEGER | `avatar_list[].equip.rank`                                   | 光锥叠影 1-5                                                         |
| relic_ids       | TEXT    | `avatar_list[].relics[].id` + `avatar_list[].ornaments[].id` | 遗器 ID 列表，逗号分隔（relics pos 1-4 + ornaments pos 5-6）         |
| skill_tree_json | TEXT    | `avatar_list[].skills[]`                                     | 技能树 JSON 数组，每项含 `point_id`、`level`、`is_activated`         |
| raw_json        | TEXT    | —                                                            | 单条角色完整详情 JSON（含 relics/ornaments/ranks/properties/skills） |
| update_time     | INTEGER | —                                                            | 最后更新时间戳（Unix 秒）                                            |

---

### 表 10：starrail_avatar_compute

**数据流：** 养成计算接口写入，用户触发计算时更新。

```sql
CREATE TABLE IF NOT EXISTS starrail_avatar_compute (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id         INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid           TEXT    NOT NULL,                  -- 游戏内角色 UID
  avatar_id          TEXT    NOT NULL,                  -- 角色 ID
  avatar_consume_json TEXT,                             -- 角色养成材料 JSON（data.avatar_consume，含 item_id/item_name/item_url/num/rarity/item_purpose）
  skill_consume_json  TEXT,                             -- 行迹养成材料 JSON（data.skill_consume，字段同上）
  equipment_consume_json TEXT,                          -- 光锥养成材料 JSON（data.equipment_consume，字段同上）
  update_time        INTEGER,                           -- 最后更新时间戳（Unix 秒）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_starrail_avatar_compute_unique
  ON starrail_avatar_compute(account_id, role_uid, avatar_id);
```

| 字段名                 | 类型    | 来源 API 字段            | 说明                                                                                               |
| ---------------------- | ------- | ------------------------ | -------------------------------------------------------------------------------------------------- |
| id                     | INTEGER | —                        | 主键，自增                                                                                         |
| account_id             | INTEGER | —                        | 关联 account_table.id                                                                              |
| role_uid               | TEXT    | —                        | 游戏内角色 UID                                                                                     |
| avatar_id              | TEXT    | —                        | 角色 ID                                                                                            |
| avatar_consume_json    | TEXT    | `data.avatar_consume`    | 角色养成材料 JSON 数组，每项含 `item_id`、`item_name`、`item_url`、`num`、`rarity`、`item_purpose` |
| skill_consume_json     | TEXT    | `data.skill_consume`     | 行迹养成材料 JSON 数组，字段同上                                                                   |
| equipment_consume_json | TEXT    | `data.equipment_consume` | 光锥养成材料 JSON 数组，字段同上（通常为空数组）                                                   |
| update_time            | INTEGER | —                        | 最后更新时间戳（Unix 秒）                                                                          |

---

### 表 11：zzz_avatar_basic

**数据流：** `event_game_record_zzz_api_zzz_avatar_basic` 写入，进入绝区零代理人页时触发同步。

```sql
CREATE TABLE IF NOT EXISTS zzz_avatar_basic (
  id                INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id        INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid          TEXT    NOT NULL,                  -- 游戏内角色 UID
  avatar_id         TEXT    NOT NULL,                  -- 代理人 ID（如 1171）
  name_mi18n        TEXT,                              -- 代理人简称（如 柏妮思）
  full_name_mi18n   TEXT,                              -- 代理人全名（如 柏妮思·怀特）
  element_type      INTEGER,                           -- 属性数字（200=物理 201=火 202=冰 203=电 205=以太）
  sub_element_type  INTEGER,                           -- 副属性数字（通常为 0，部分代理人有双属性）
  avatar_profession INTEGER,                           -- 职业数字（1=强攻 2=击破 3=支援 4=异常 5=防御 6=辅助）
  rarity            TEXT,                              -- 稀有度（"S" 或 "A"）
  level             INTEGER,                           -- 代理人等级
  rank              INTEGER,                           -- 影画数（0-6）
  camp_name_mi18n   TEXT,                              -- 阵营名称（如 卡吕冬之子）
  group_icon_path   TEXT,                              -- 阵营图标 URL
  hollow_icon_path  TEXT,                              -- 空洞图标 URL
  role_square_url   TEXT,                              -- 方形头像 URL
  awaken_state      TEXT,                              -- 觉醒状态（AwakenStateNotVisible/AwakenStateVisible）
  raw_json          TEXT    NOT NULL,                  -- 单条代理人完整 JSON
  update_time       INTEGER,                           -- 最后更新时间戳（Unix 秒）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_zzz_avatar_basic_unique
  ON zzz_avatar_basic(account_id, role_uid, avatar_id);

CREATE INDEX IF NOT EXISTS idx_zzz_avatar_basic_element
  ON zzz_avatar_basic(account_id, role_uid, element_type);

CREATE INDEX IF NOT EXISTS idx_zzz_avatar_basic_profession
  ON zzz_avatar_basic(account_id, role_uid, avatar_profession);
```

| 字段名            | 类型    | 来源 API 字段       | 说明                                                   |
| ----------------- | ------- | ------------------- | ------------------------------------------------------ |
| id                | INTEGER | —                   | 主键，自增                                             |
| account_id        | INTEGER | —                   | 关联 account_table.id                                  |
| role_uid          | TEXT    | —                   | 游戏内角色 UID                                         |
| avatar_id         | TEXT    | `id`                | 代理人 ID，如 1171                                     |
| name_mi18n        | TEXT    | `name_mi18n`        | 代理人简称，如 "柏妮思"                                |
| full_name_mi18n   | TEXT    | `full_name_mi18n`   | 代理人全名，如 "柏妮思·怀特"                           |
| element_type      | INTEGER | `element_type`      | 属性数字（200=物理 201=火 202=冰 203=电 205=以太）     |
| sub_element_type  | INTEGER | `sub_element_type`  | 副属性数字（通常为 0，部分代理人有双属性）             |
| avatar_profession | INTEGER | `avatar_profession` | 职业数字（1=强攻 2=击破 3=支援 4=异常 5=防御 6=辅助）  |
| rarity            | TEXT    | `rarity`            | 稀有度，"S" 或 "A"                                     |
| level             | INTEGER | `level`             | 代理人等级                                             |
| rank              | INTEGER | `rank`              | 影画数 0-6                                             |
| camp_name_mi18n   | TEXT    | `camp_name_mi18n`   | 阵营名称，如 "卡吕冬之子"                              |
| group_icon_path   | TEXT    | `group_icon_path`   | 阵营图标 URL                                           |
| hollow_icon_path  | TEXT    | `hollow_icon_path`  | 空洞图标 URL                                           |
| role_square_url   | TEXT    | `role_square_url`   | 方形头像 URL                                           |
| awaken_state      | TEXT    | `awaken_state`      | 觉醒状态（AwakenStateNotVisible / AwakenStateVisible） |
| raw_json          | TEXT    | —                   | 单条代理人完整 JSON                                    |
| update_time       | INTEGER | —                   | 最后更新时间戳（Unix 秒）                              |

---

### 表 12：zzz_daily_note

**数据流：** `event_game_record_zzz_api_zzz_note` 写入，每个角色只保留一条最新记录。

```sql
CREATE TABLE IF NOT EXISTS zzz_daily_note (
  id               INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id       INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid         TEXT    NOT NULL,                  -- 游戏内角色 UID（每角色唯一一条）
  energy_current   INTEGER,                           -- 当前电量（energy.progress.current）
  energy_max       INTEGER,                           -- 电量上限（通常 240）
  energy_restore   INTEGER,                           -- 电量恢复剩余秒数（0 表示已满）
  vitality_current INTEGER,                           -- 当前活跃度
  vitality_max     INTEGER,                           -- 活跃度上限（通常 400）
  vhs_sale_state   TEXT,                              -- 录像店状态（SaleStateDone/SaleStateDoing/SaleStateNo）
  card_sign        TEXT,                              -- 刮刮卡状态（CardSignDone/CardSignNo）
  raw_json         TEXT    NOT NULL,                  -- 完整便笺 JSON（含 member_card/bounty_commission 等扩展字段）
  update_time      INTEGER,                           -- 最后更新时间戳（Unix 秒）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_zzz_daily_note_unique
  ON zzz_daily_note(account_id, role_uid);
```

| 字段名           | 类型    | 来源 API 字段             | 说明                                                     |
| ---------------- | ------- | ------------------------- | -------------------------------------------------------- |
| id               | INTEGER | —                         | 主键，自增                                               |
| account_id       | INTEGER | —                         | 关联 account_table.id                                    |
| role_uid         | TEXT    | —                         | 游戏内角色 UID                                           |
| energy_current   | INTEGER | `energy.progress.current` | 当前电量                                                 |
| energy_max       | INTEGER | `energy.progress.max`     | 电量上限（通常为 240）                                   |
| energy_restore   | INTEGER | `energy.restore`          | 电量恢复剩余秒数（0 表示已满）                           |
| vitality_current | INTEGER | `vitality.current`        | 当前活跃度                                               |
| vitality_max     | INTEGER | `vitality.max`            | 活跃度上限（通常为 400）                                 |
| vhs_sale_state   | TEXT    | `vhs_sale.sale_state`     | 录像店状态：SaleStateDone / SaleStateDoing / SaleStateNo |
| card_sign        | TEXT    | `card_sign`               | 刮刮卡状态：CardSignDone / CardSignNo                    |
| raw_json         | TEXT    | —                         | 完整便笺 JSON                                            |
| update_time      | INTEGER | —                         | 最后更新时间戳（Unix 秒）                                |

---

### 表 13：zzz_avatar_info

**数据流：** `event_game_record_zzz_api_zzz_avatar_info` 写入，进入代理人详情页时触发同步。

```sql
CREATE TABLE IF NOT EXISTS zzz_avatar_info (
  id                INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id        INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid          TEXT    NOT NULL,                  -- 游戏内角色 UID
  avatar_id         TEXT    NOT NULL,                  -- 代理人 ID
  weapon_id         TEXT,                              -- 音擎 ID（weapon.id）
  weapon_level      INTEGER,                           -- 音擎等级
  weapon_star       INTEGER,                           -- 音擎精炼等级（weapon.star）
  equip_ids         TEXT,                              -- 驱动盘 ID 列表，逗号分隔（共 6 件，按 equipment_type 1-6 排序）
  skill_levels_json TEXT,                              -- 技能等级 JSON 数组（含 skill_type 和 level，skill_type: 0=普攻 1=特殊技 2=闪避 3=连携技 5=核心被动 6=支援技）
  vertical_painting_url TEXT,                          -- 角色立绘 URL（role_vertical_painting_url，详情页展示用）
  raw_json          TEXT    NOT NULL,                  -- 单条代理人完整详情 JSON（含 weapon/equip/skills/properties/ranks）
  update_time       INTEGER,                           -- 最后更新时间戳（Unix 秒）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_zzz_avatar_info_unique
  ON zzz_avatar_info(account_id, role_uid, avatar_id);
```

| 字段名                | 类型    | 来源 API 字段                | 说明                                                                                                     |
| --------------------- | ------- | ---------------------------- | -------------------------------------------------------------------------------------------------------- |
| id                    | INTEGER | —                            | 主键，自增                                                                                               |
| account_id            | INTEGER | —                            | 关联 account_table.id                                                                                    |
| role_uid              | TEXT    | —                            | 游戏内角色 UID                                                                                           |
| avatar_id             | TEXT    | —                            | 代理人 ID                                                                                                |
| weapon_id             | TEXT    | `weapon.id`                  | 音擎 ID                                                                                                  |
| weapon_level          | INTEGER | `weapon.level`               | 音擎等级                                                                                                 |
| weapon_star           | INTEGER | `weapon.star`                | 音擎精炼等级                                                                                             |
| equip_ids             | TEXT    | `equip[].id`                 | 驱动盘 ID 列表，逗号分隔（共 6 件，按 equipment_type 1-6 排序）                                          |
| skill_levels_json     | TEXT    | `skills[]`                   | 技能等级 JSON 数组，每项含 `skill_type`（0=普攻 1=特殊技 2=闪避 3=连携技 5=核心被动 6=支援技）和 `level` |
| vertical_painting_url | TEXT    | `role_vertical_painting_url` | 角色立绘 URL，详情页展示用（比 basic 表的方形头像更适合详情页）                                          |
| raw_json              | TEXT    | —                            | 单条代理人完整详情 JSON（含 weapon/equip/skills/properties/ranks）                                       |
| update_time           | INTEGER | —                            | 最后更新时间戳（Unix 秒）                                                                                |

---

### 表 14：zzz_avatar_compute

**数据流：** 养成计算接口写入，用户触发计算时更新。

```sql
CREATE TABLE IF NOT EXISTS zzz_avatar_compute (
  id                   INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id           INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid             TEXT    NOT NULL,                  -- 游戏内角色 UID
  avatar_id            TEXT    NOT NULL,                  -- 代理人 ID
  avatar_consume_json  TEXT,                              -- 代理人养成材料 JSON（含 id/name/icon/cnt/rarity/not_opened）
  weapon_consume_json  TEXT,                              -- 音擎养成材料 JSON（字段同上）
  skill_consume_json   TEXT,                              -- 技能养成材料 JSON（字段同上，注意用 cnt 而非 num）
  update_time          INTEGER,                           -- 最后更新时间戳（Unix 秒）
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_zzz_avatar_compute_unique
  ON zzz_avatar_compute(account_id, role_uid, avatar_id);
```

| 字段名              | 类型    | 来源 API 字段         | 说明                                                                                 |
| ------------------- | ------- | --------------------- | ------------------------------------------------------------------------------------ |
| id                  | INTEGER | —                     | 主键，自增                                                                           |
| account_id          | INTEGER | —                     | 关联 account_table.id                                                                |
| role_uid            | TEXT    | —                     | 游戏内角色 UID                                                                       |
| avatar_id           | TEXT    | —                     | 代理人 ID                                                                            |
| avatar_consume_json | TEXT    | `data.avatar_consume` | 代理人养成材料 JSON 数组，每项含 `id`、`name`、`icon`、`cnt`、`rarity`、`not_opened` |
| weapon_consume_json | TEXT    | `data.weapon_consume` | 音擎养成材料 JSON 数组，字段同上                                                     |
| skill_consume_json  | TEXT    | `data.skill_consume`  | 技能养成材料 JSON 数组，字段同上                                                     |
| update_time         | INTEGER | —                     | 最后更新时间戳（Unix 秒）                                                            |

> 注意：绝区零养成材料用 `cnt` 表示数量（非 `num`），且分三类分别存储。

---

### 表 15：sync_meta

**数据流：** 所有 Repository 写入操作时同步更新。

```sql
CREATE TABLE IF NOT EXISTS sync_meta (
  id             INTEGER PRIMARY KEY AUTOINCREMENT, -- 主键，自增
  account_id     INTEGER NOT NULL,                  -- 关联 account_table.id
  role_uid       TEXT    NOT NULL,                  -- 游戏内角色 UID
  data_type      TEXT    NOT NULL,                  -- 数据类型，与专用表名一致（如 genshin_character_list）
  last_sync_time INTEGER,                           -- 最后成功同步时间戳（Unix 秒）
  sync_status    TEXT,                              -- 同步状态（success/failed/syncing）
  error_msg      TEXT,                              -- 失败时的错误信息
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_meta_unique
  ON sync_meta(account_id, role_uid, data_type);
```

| 字段名         | 类型    | 来源 API 字段 | 说明                                       |
| -------------- | ------- | ------------- | ------------------------------------------ |
| id             | INTEGER | —             | 主键，自增                                 |
| account_id     | INTEGER | —             | 关联 account_table.id                      |
| role_uid       | TEXT    | —             | 游戏内角色 UID                             |
| data_type      | TEXT    | —             | 数据类型，与专用表名一致                   |
| last_sync_time | INTEGER | —             | 最后成功同步时间戳（Unix 秒）              |
| sync_status    | TEXT    | —             | 同步状态："success" / "failed" / "syncing" |
| error_msg      | TEXT    | —             | 失败时的错误信息                           |

`data_type` 枚举值：

| data_type                 | 对应专用表                |
| ------------------------- | ------------------------- |
| genshin_character_list    | genshin_character_list    |
| genshin_daily_note        | genshin_daily_note        |
| genshin_character_detail  | genshin_character_detail  |
| genshin_character_compute | genshin_character_compute |
| starrail_avatar_basic     | starrail_avatar_basic     |
| starrail_daily_note       | starrail_daily_note       |
| starrail_avatar_info      | starrail_avatar_info      |
| starrail_avatar_compute   | starrail_avatar_compute   |
| zzz_avatar_basic          | zzz_avatar_basic          |
| zzz_daily_note            | zzz_daily_note            |
| zzz_avatar_info           | zzz_avatar_info           |
| zzz_avatar_compute        | zzz_avatar_compute        |

> 注意：`account_table` 和 `game_role_table` **不使用** `sync_meta` 追踪同步状态，因为账号和角色绑定数据在登录/刷新时直接覆盖写入，无需独立的同步状态机。

### SyncDataType 枚举

`data_type` 字段必须使用以下枚举，禁止在代码中直接写字符串字面量：

```typescript
// core/src/main/ets/constants/SyncDataType.ets
export enum SyncDataType {
  GENSHIN_CHARACTER_LIST = "genshin_character_list",
  GENSHIN_DAILY_NOTE = "genshin_daily_note",
  GENSHIN_CHARACTER_DETAIL = "genshin_character_detail",
  GENSHIN_CHARACTER_COMPUTE = "genshin_character_compute",
  STARRAIL_AVATAR_BASIC = "starrail_avatar_basic",
  STARRAIL_DAILY_NOTE = "starrail_daily_note",
  STARRAIL_AVATAR_INFO = "starrail_avatar_info",
  STARRAIL_AVATAR_COMPUTE = "starrail_avatar_compute",
  ZZZ_AVATAR_BASIC = "zzz_avatar_basic",
  ZZZ_DAILY_NOTE = "zzz_daily_note",
  ZZZ_AVATAR_INFO = "zzz_avatar_info",
  ZZZ_AVATAR_COMPUTE = "zzz_avatar_compute",
}
```

新增游戏时在此枚举追加对应值，不得在 Repository 或 DAO 中直接写字符串。

---

## 正确性属性

### Property 1：唯一索引约束

对任意 `(account_id, role_uid, avatar_id)` 组合，向角色/代理人列表表中插入两条相同主键的记录，第二次插入应失败（违反唯一约束）。

### Property 2：Upsert 幂等性

对任意专用表和任意一条有效记录，执行 upsert 操作后：表中该主键的记录数恰好为 1，字段值为最后一次写入的值。即 `upsert(upsert(x)) = upsert(x)`。

### Property 3：空值写入拒绝

对任意专用表，当 `avatar_id` 为空或 `role_uid` 为空时，写入操作应被拒绝并返回错误。

### Property 4：账号级联删除

删除 `account_table` 中某账号后，所有专用表中该 `account_id` 的记录应全部不存在。

### Property 5：外键约束

对任意不存在于 `account_table` 的 `account_id`，向任意专用表写入数据应被拒绝。

### Property 6：建表幂等性

调用 `RdbManagerV2.createTables()` 任意次数，结果与调用 1 次相同：所有表和索引存在，无重复，无报错。

### Property 7：同步时间阈值触发

对任意 `(account_id, role_uid, data_type)`：

- 若 `now - last_sync_time > 300`，Repository 应触发网络请求
- 若 `now - last_sync_time ≤ 300`，Repository 不应触发网络请求

---

## 错误处理

### 数据库层错误

| 错误场景                    | 触发条件                                | 处理方式                                                                                  |
| --------------------------- | --------------------------------------- | ----------------------------------------------------------------------------------------- |
| `avatar_id` 为空            | DAO 写入前校验                          | 抛出 `Error('avatar_id is empty')`，不执行 SQL                                            |
| `role_uid` 为空             | DAO 写入前校验                          | 抛出 `Error('role_uid is empty')`，不执行 SQL                                             |
| `account_id` 不存在         | SQLite 外键约束                         | 捕获 SQLite 错误，转换为 `Error('account_id not found: ${id}')`                           |
| 唯一索引冲突（INSERT 路径） | 重复写入同一主键                        | 捕获 SQLITE_CONSTRAINT_UNIQUE，自动切换为 UPDATE（upsert 语义）                           |
| 事务中途失败                | 任意 SQL 执行异常                       | `RdbManagerV2.runInTransaction` 自动 rollback，抛出原始错误                               |
| 数据库未初始化              | `RdbManagerV2.getRdbStore()` 被提前调用 | 抛出 `Error('RdbStore not initialized')`，调用方需等待 `CoreInitializerV2.waitForReady()` |
| 建表失败                    | `createTables()` 中 SQL 语法错误        | 抛出 `Error('Create tables failed: ${msg}')`，应用无法启动                                |
| 列不存在（查询时）          | 读取不存在的列名                        | 捕获 `getColumnIndex` 返回 -1，对应字段使用默认值（空字符串/0）                           |
| 磁盘空间不足                | SQLite SQLITE_FULL                      | 捕获后抛出 `Error('Database full: ${msg}')`，UI 提示用户清理空间                          |
| 数据库文件损坏              | SQLite SQLITE_CORRUPT                   | 捕获后抛出 `Error('Database corrupt')`，建议用户重新安装                                  |

### 网络层错误

| 错误场景                    | 触发条件              | 处理方式                                                                        |
| --------------------------- | --------------------- | ------------------------------------------------------------------------------- |
| 网络请求超时                | HTTP 请求超过超时阈值 | `sync_meta.sync_status = "failed"`，`error_msg` 记录超时信息，保留旧数据        |
| API 返回非 0 retcode        | `retcode !== 0`       | 抛出 `Error('retcode=${retcode}: ${message}')`，Repository 捕获后更新 sync_meta |
| Cookie 失效（retcode=-100） | 登录态过期            | 通知 UI 层弹出重新登录提示，不更新专用表数据                                    |
| 网络不可用                  | 无网络连接            | `sync_meta.sync_status = "failed"`，UI 展示离线缓存数据                         |
| 响应 JSON 解析失败          | API 返回格式异常      | 捕获 JSON.parse 异常，`sync_meta.sync_status = "failed"`，保留旧数据            |
| 请求被限流（retcode=-110）  | 短时间内请求过多      | 记录失败，UI 提示"请求过于频繁，请稍后再试"                                     |

### 同步状态机

```
初始状态
    │
    ▼
[syncing] ←── Repository 发起网络请求时设置
    │
    ├── 成功 ──► [success]  last_sync_time = now
    │
    └── 失败 ──► [failed]   error_msg = 错误信息
                             旧数据保留，UI 展示缓存
```

---

## 测试策略

### 单元测试（具体示例）

使用 Hypium 框架，测试文件放置于 `core/src/ohosTest/` 目录。

**建表测试：**

- 验证 `createTables()` 执行后所有 15 张表存在（查询 `sqlite_master`）
- 验证 `createTables()` 执行两次不报错（幂等性）
- 验证所有唯一索引存在

**账号表测试：**

- 插入账号后可按 `id` 查询到
- 插入重复 `username` 应失败（UNIQUE 约束）
- 删除账号后 `game_role_table` 中对应记录级联删除

**游戏角色表测试：**

- 插入角色后可按 `(account_id, game_id, role_id)` 查询到
- 插入重复 `(account_id, game_id, role_id)` 应失败
- `account_id` 不存在时插入应失败（外键约束）

**原神角色列表表测试：**

- 插入角色后可按 `avatar_id` 查询到
- upsert 同一 `(account_id, role_uid, avatar_id)` 两次，表中只有一条记录
- `avatar_id` 为空时插入应失败
- 按 `element` 过滤查询返回正确结果
- 按 `rarity` 过滤查询返回正确结果

**便笺表测试（原神/星铁/绝区零）：**

- 插入便笺后可按 `(account_id, role_uid)` 查询到
- 同一 `(account_id, role_uid)` 第二次 upsert 覆盖旧数据，记录数仍为 1
- `role_uid` 为空时插入应失败

**sync_meta 测试：**

- 网络成功后 `sync_status = "success"`，`last_sync_time` 已更新
- 网络失败后 `sync_status = "failed"`，`error_msg` 非空，旧数据仍存在
- `now - last_sync_time ≤ 300` 时不触发网络请求
- `now - last_sync_time > 300` 时触发网络请求

**养成材料计算表测试：**

- 插入计算结果后可按 `(account_id, role_uid, avatar_id)` 查询到
- upsert 同一角色两次，`avatar_consume_json` 为最新值
- 绝区零 `avatar_consume_json`、`weapon_consume_json`、`skill_consume_json` 三字段独立存储
- 星铁 `avatar_consume_json`、`skill_consume_json`、`equipment_consume_json` 三字段独立存储

### 属性测试（Property-Based Testing）

使用 Hypium 框架，每个属性最少运行 100 次，通过随机生成输入数据验证通用规则。

测试文件注释格式：

```typescript
// Feature: game-data-database-redesign, Property N: 属性名称
```

| 属性编号 | 属性名称        | 测试描述                                              | 生成器                                        |
| -------- | --------------- | ----------------------------------------------------- | --------------------------------------------- |
| P1       | 唯一索引约束    | 向角色列表表插入两条相同主键记录，第二次应失败        | 随机 account_id/role_uid/avatar_id            |
| P2       | Upsert 幂等性   | 对任意表执行 1-5 次 upsert，最终记录数为 1 且值为最新 | 随机有效记录，随机写入次数 1-5                |
| P3       | 空值写入拒绝    | avatar_id 或 role_uid 为空时写入应失败                | 随机表名，空字符串/null 的关键字段            |
| P4       | 账号级联删除    | 删除账号后所有专用表中该 account_id 的记录不存在      | 随机账号，随机数量的专用表记录                |
| P5       | 外键约束        | 不存在的 account_id 写入任意专用表应失败              | 随机不存在的 account_id（负数或超大值）       |
| P6       | 建表幂等性      | 调用 createTables() 1-10 次，结果与调用 1 次相同      | 随机调用次数 1-10                             |
| P7       | 同步阈值触发    | last_sync_time 超过 300 秒时触发请求，否则不触发      | 随机 last_sync_time（覆盖超时和未超时两侧）   |
| P8       | raw_json 完整性 | 写入的 raw_json 与读取的 raw_json 字节完全一致        | 随机长度的 JSON 字符串（含特殊字符）          |
| P9       | 多账号数据隔离  | 账号 A 的数据查询不返回账号 B 的记录                  | 随机两个不同 account_id，各自写入随机数量记录 |
| P10      | 事务原子性      | 事务中途失败后，所有已执行的写入均被回滚              | 随机在第 1-N 条记录处注入失败                 |

**属性测试与单元测试的关系：**

- 单元测试覆盖具体示例和边界条件
- 属性测试通过随机化验证通用正确性，发现单元测试遗漏的边界情况
- 两者共同保证数据库层的完整性

---

---

## 数据库层抽象协议与模块隔离

### 抽象 Repository 协议

类似 API 层的 `MihoyoApiService`，数据库层也有一个抽象基类约束游戏数据 Repository。注意：`BBSRepository`（账号/角色）**不继承此基类**，因为账号表的查询语义与游戏数据表不同（无 `roleUid` 维度）。

```typescript
// core/src/main/ets/repository/v2/GameRepository.ets
// 注意：ArkTS 支持 abstract class 和 abstract method，可正常使用
// object 类型在此作为泛型占位，实际实现时各 Repository 子类应使用具体的行模型类型
export abstract class GameRepository {
  /** 查询列表（不含 raw_json） */
  abstract findAll(accountId: number, roleUid: string): Promise<object[]>;
  /** 查询单条（含 raw_json） */
  abstract findById(
    accountId: number,
    roleUid: string,
    entityId: string,
  ): Promise<object | null>;
  /** 批量 upsert（事务） */
  abstract upsertAll(
    accountId: number,
    roleUid: string,
    rows: object[],
  ): Promise<void>;
  /** 删除指定账号角色的所有数据 */
  abstract deleteAll(accountId: number, roleUid: string): Promise<void>;
  /**
   * 带 Geetest challenge 重试便笺请求（Geetest 验证后调用）
   * 默认抛出 not implemented，需要便笺功能的子类覆盖此方法
   */
  async fetchDailyNoteWithChallenge(
    roleId: string,
    server: string,
    cookie: string,
    challenge: string,
    validate: string,
    seccode: string,
  ): Promise<void> {
    throw new Error("fetchDailyNoteWithChallenge not implemented");
  }

  /**
   * 统一错误处理：将 Service 抛出的 retcode 错误转换为业务错误类型
   * 所有子类共用，无需重复实现
   * 注意：参数类型为 Error，调用方需先 instanceof 判断后传入
   */
  protected handleApiError(e: Error): void {
    const msg = e.message;
    if (msg.includes(`retcode=${ApiErrorCodes.AUTH_INVALID}`)) {
      throw new AuthExpiredError();
    }
    if (msg.includes(`retcode=${ApiErrorCodes.GEETEST_REQUIRED}`)) {
      throw new GeetestRequiredError(GeetestTriggerType.NEED_CREATE);
    }
    if (msg.includes(`retcode=${ApiErrorCodes.GEETEST_SIGN}`)) {
      throw new GeetestRequiredError(GeetestTriggerType.NEED_CREATE);
    }
    if (msg.includes(`retcode=${ApiErrorCodes.ROLE_NOT_PUBLIC}`)) {
      throw new RoleNotPublicError();
    }
    if (msg.includes(`retcode=${ApiErrorCodes.RATE_LIMITED}`)) {
      throw new RateLimitedError();
    }
    throw e;
  }

  /**
   * 带 Cookie 自动刷新的错误处理（AUTH_INVALID 时先刷新再重试）
   * 定义在 GameRepository 基类，各游戏 Repository 子类继承后可直接调用
   * 注意：调用方 catch 到的 e 是 Object 类型，需先 instanceof Error 判断后传入
   */
  protected async handleApiErrorWithRefresh(
    e: Error,
    accountId: number,
    retryFn: (newCookie: string) => Promise<object>,
  ): Promise<object> {
    const msg = e.message;
    if (msg.includes(`retcode=${ApiErrorCodes.AUTH_INVALID}`)) {
      try {
        const newCookie =
          await BBSRepository.getInstance().refreshCookie(accountId);
        return await retryFn(newCookie);
      } catch (_) {
        throw new AuthExpiredError();
      }
    }
    this.handleApiError(e);
    throw e;
  }
}
```

`BBSRepository` 独立实现，不继承 `GameRepository`，提供账号和角色专属的查询方法：

```typescript
// core/src/main/ets/repository/v2/BBSRepository.ets
// 注意：过渡期使用 AccountRowV2 和 GameRoleRowV2（包含 stoken/stuid/mid 等新增字段），
// 避免与现有 AccountRow / GameRoleRow（AccountRepository.ets）冲突。
// 旧代码删除后统一重命名为 AccountRow / GameRoleRow。
// 还需要 import：GeetestCreateResult, GeetestVerifyInput from '../errors/ApiErrors'
// 以下为方法签名说明，实际实现时每个方法需要有完整的函数体
export class BBSRepository {
  private static instance: BBSRepository = new BBSRepository();
  // BBSRepository 的 service 是 MihoyoAccountApiService（不是抽象基类），
  // 因为需要调用 refreshCookieToken 等 BBS 专属方法
  private accountService: MihoyoAccountApiService | null = null;

  static getInstance(): BBSRepository {
    return BBSRepository.instance;
  }

  setService(service: MihoyoApiService): void {
    // ArkTS 严格模式：需要类型断言，因为 setService 接收抽象基类类型
    this.accountService = service as MihoyoAccountApiService;
  }

  private getAccountService(): MihoyoAccountApiService {
    if (this.accountService === null) {
      throw new Error("BBSRepository: service not initialized");
    }
    return this.accountService;
  }

  /** 查询账号 */
  findAccount(accountId: number): Promise<AccountRowV2 | null>;
  /** 查询所有账号 */
  findAllAccounts(): Promise<AccountRowV2[]>;
  /** upsert 账号 */
  upsertAccount(row: AccountRowV2): Promise<void>;
  /** 查询某账号下所有游戏角色 */
  findRoles(accountId: number): Promise<GameRoleRowV2[]>;
  /** upsert 游戏角色列表（事务） */
  upsertRoles(accountId: number, rows: GameRoleRowV2[]): Promise<void>;
  /** 删除账号及其所有关联数据（级联） */
  deleteAccount(accountId: number): Promise<void>;
  /** 用 stoken 刷新 cookie_token 和 ltoken，返回新 Cookie 字符串 */
  refreshCookie(accountId: number): Promise<string>;
  /** 更新账号的 Cookie 字段 */
  updateAccountCookie(accountId: number, cookie: string): Promise<void>;
  /** 申请 Geetest 验证（委托给 MihoyoAccountApiService.createVerification） */
  createVerification(cookie: string): Promise<GeetestCreateResult>;
  // 实现：调用 getAccountService().createVerification(cookie)，从响应 data 字段提取 gt/challenge 构建 GeetestCreateResult
  /** 提交 Geetest 验证结果，返回新 challenge（委托给 MihoyoAccountApiService.verifyVerification） */
  verifyVerification(
    input: GeetestVerifyInput,
    cookie: string,
  ): Promise<string>;
  // 实现：调用 getAccountService().verifyVerification(input, cookie)，从响应 data 字段提取 challenge 字符串
}
```

`SignRepository` 不继承 `GameRepository`，不写 DB，只封装签到 API 调用：

```typescript
// core/src/main/ets/repository/v2/SignRepository.ets
// 以下为方法签名说明，实际实现时每个方法需要有完整的函数体
export class SignRepository {
  private static instance: SignRepository = new SignRepository();
  // SignRepository 的 service 是 SignApiService（不是抽象基类），
  // 因为需要调用 signBBS()/signGame() 等签到专属方法（类似 BBSRepository 持有 MihoyoAccountApiService）
  private signService: SignApiService | null = null;

  static getInstance(): SignRepository {
    return SignRepository.instance;
  }

  setService(service: MihoyoApiService): void {
    // ArkTS 严格模式：需要类型断言，因为 setService 接收抽象基类类型
    this.signService = service as SignApiService;
  }

  private getSignService(): SignApiService {
    if (this.signService === null) {
      throw new Error("SignRepository: service not initialized");
    }
    return this.signService;
  }

  /** 大别野签到 */
  async signBBS(cookie: string, challenge?: string): Promise<void>;
  /** 游戏每日签到 */
  async signGame(
    gameBiz: string,
    roleId: string,
    server: string,
    cookie: string,
    challenge?: string,
  ): Promise<void>;
  /** 获取签到状态 */
  async getSignInfo(
    gameBiz: string,
    roleId: string,
    server: string,
    cookie: string,
  ): Promise<object>;
  /** 获取今日签到奖励 */
  async getSignReward(gameBiz: string, cookie: string): Promise<object>;
  /** 带 challenge 重试大别野签到（Geetest 验证后调用） */
  async signBBSWithChallenge(cookie: string, challenge: string): Promise<void>;
  /** 带 challenge 重试游戏签到（Geetest 验证后调用） */
  async signGameWithChallenge(
    gameBiz: string,
    roleId: string,
    server: string,
    cookie: string,
    challenge: string,
  ): Promise<void>;
}
```

### 模块隔离结构

```
GameRepository（抽象基类，仅游戏数据）
    │
    ├── GenshinRepository      → genshin_* 四张表
    ├── StarRailRepository     → starrail_* 四张表
    └── ZZZRepository          → zzz_* 四张表

BBSRepository（独立，不继承 GameRepository）
    └── account_table + game_role_table

SignRepository（独立，不继承 GameRepository，不写 DB）
    └── 封装签到 API 调用和 Geetest 重试逻辑
```

### 文件结构

```
core/src/main/ets/repository/v2/
├── GameRepository.ets          ← 抽象基类（多态协议，仅游戏数据）
├── BBSRepository.ets           ← 米游社账号 + 游戏角色（独立，不继承 GameRepository）
├── GenshinRepository.ets       ← 原神四张表
├── StarRailRepository.ets      ← 星穹铁道四张表
├── ZZZRepository.ets           ← 绝区零四张表
├── SignRepository.ets          ← 签到（不写 DB，封装签到 API 调用和 Geetest 重试）
└── index.ets                   ← 统一导出

core/src/main/ets/database/v2/
├── RdbManagerV2.ets            ← 新版数据库管理器（建表 + 事务 + 写入队列）
├── BBSDao.ets                  ← 账号/角色表 DAO
├── GenshinDao.ets              ← 原神四张表 DAO
├── StarRailDao.ets             ← 星穹铁道四张表 DAO
├── ZZZDao.ets                  ← 绝区零四张表 DAO
└── SyncMetaDaoV2.ets           ← 同步状态 DAO（过渡期加 V2 后缀，避免与旧 SyncMetaDao 冲突）

core/src/main/ets/constants/
└── SyncDataType.ets            ← sync_meta.data_type 枚举（禁止直接写字符串字面量）
```

---

## 并发安全与数据一致性

### 数据流设计

UI 层直接展示 API 返回的最新数据，DB 写入作为后台异步队列处理：

```
用户点击刷新按钮
    │
    ▼
Button 置灰（block，防止重复点击）
    │
    ▼
API 请求
    │
    ├── 失败 → Button 恢复，显示错误提示
    │
    └── 成功 → API 数据直接传递给 UI 显示（最新数据立即可见）
                │
                ▼
               Button 恢复可点击
                │
                ▼
               数据加入 DB 写入队列（后台异步，不阻塞 UI）
                │
                ▼
               队列串行写入 DB（INSERT OR REPLACE）
```

**关键原则：**

- UI 显示的数据来自 API 返回，不经过 DB 中转，响应最快
- DB 是持久化缓存，用于冷启动时读取，不是 UI 的数据源
- Button 在整个 API 请求期间置灰，API 成功/失败后恢复，用户无法在请求期间重复触发

### 冷启动数据流

```
进入页面
    │
    ▼
读取 DB（显示缓存数据）
    │
    ▼
UI 显示旧数据（如有）
    │
    ▼
用户手动点击刷新 → 走上方的刷新流程
```

### DB 写入队列

`RdbManagerV2` 维护一个全局写入队列，保证写操作串行不冲突。

**设计要点：避免 Promise 链无限增长**

朴素的 `this.writeQueue = this.writeQueue.then(...)` 方案会导致 Promise 链随写入次数线性增长，App 长时间运行后存在内存泄漏风险。正确方案是用显式任务数组 + 单一 runner 协程：

```typescript
// 写入队列（任务数组方案，无 Promise 链增长问题）
// RdbManagerV2 全部使用静态方法，保持与 RdbManagerV2.init() 调用方式一致
// 完整文件需要：import { relationalStore } from '@kit.ArkData'; import { common } from '@kit.AbilityKit';
class RdbManagerV2 {
  // ArkTS 严格模式：函数类型数组，元素类型明确
  private static pendingWrites: Array<() => Promise<void>> = [];
  private static isWriting: boolean = false;
  // rdbStore 在 init() 时赋值，使用前必须确保已初始化
  private static rdbStore: relationalStore.RdbStore | null = null;

  /**
   * 初始化数据库：打开/创建 DB 文件，激活外键约束，建表，执行迁移
   * 由 CoreInitializerV2.initCore() 调用，必须在任何 DAO 操作前完成
   */
  static async init(context: common.UIAbilityContext): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: "mihoyo_tools.db",
      securityLevel: relationalStore.SecurityLevel.S2,
    };
    const store = await relationalStore.getRdbStore(context, config);
    // 激活外键约束（连接级别，每次打开必须设置）
    await store.executeSql("PRAGMA foreign_keys = ON", []);
    RdbManagerV2.rdbStore = store;
    // 建表（幂等，IF NOT EXISTS）
    await RdbManagerV2.createTables(store);
    // 版本迁移
    await RdbManagerV2.runMigrations(store);
  }

  /** 建立所有 15 张表 + 索引（幂等，使用 CREATE TABLE IF NOT EXISTS） */
  private static async createTables(
    store: relationalStore.RdbStore,
  ): Promise<void> {
    // 执行所有建表 SQL（见"数据模型"章节）
    // 此处省略具体 SQL，实现时从设计文档各表定义中复制
  }

  static enqueueWrite(action: () => Promise<void>): void {
    RdbManagerV2.pendingWrites.push(action);
    if (!RdbManagerV2.isWriting) {
      // 启动 runner（不 await，让它在后台跑）
      RdbManagerV2.runWriteQueue();
    }
  }

  private static async runWriteQueue(): Promise<void> {
    RdbManagerV2.isWriting = true;
    // ArkTS 严格模式：禁止 Array.shift()，改用索引遍历后清空
    while (RdbManagerV2.pendingWrites.length > 0) {
      // 取出第一个任务（ArkTS 允许 splice）
      const tasks = RdbManagerV2.pendingWrites.splice(0, 1);
      const action = tasks[0];
      if (action === undefined) {
        break;
      }
      try {
        await RdbManagerV2.runInTransaction(action);
      } catch (_) {
        // 写入失败静默处理，不影响 UI
        // 下次冷启动会重新从 API 拉取最新数据
      }
    }
    RdbManagerV2.isWriting = false;
  }

  /**
   * 在事务中执行写操作，失败时自动 rollback
   * 注意：beginTransaction / commit / rollBack 均为同步 API，不可 await
   * 参考现有 RdbManager 的事务用法
   */
  static async runInTransaction(action: () => Promise<void>): Promise<void> {
    const store = RdbManagerV2.getRdbStore();
    store.beginTransaction();
    try {
      await action();
      store.commit();
    } catch (e) {
      store.rollBack();
      throw e;
    }
  }

  static getRdbStore(): relationalStore.RdbStore {
    if (RdbManagerV2.rdbStore === null) {
      throw new Error("RdbStore not initialized");
    }
    return RdbManagerV2.rdbStore;
  }
}
```

**与朴素 Promise 链方案的对比：**

| 方案                                | 内存行为                        | 风险                   |
| ----------------------------------- | ------------------------------- | ---------------------- |
| `writeQueue = writeQueue.then(...)` | Promise 链随写入次数线性增长    | 长时间运行内存泄漏     |
| 任务数组 + runner 协程              | 任务执行完即可 GC，数组长度有界 | 无内存泄漏风险（推荐） |

- 写入使用 `INSERT OR REPLACE`（upsert），直接覆盖，不需要先对比
- 写入失败静默处理，下次冷启动会重新从 API 拉取
- 用户杀掉 App 时队列中未完成的写入会丢失，这是可接受的

### 数据一致性保证矩阵

| 场景                    | 解决方案                      | 保证级别  |
| ----------------------- | ----------------------------- | --------- |
| 用户快速多次点击刷新    | Button 置灰，API 期间不可点击 | UI 层防护 |
| 批量写入中途失败        | 事务回滚，下次刷新重新写入    | 原子性    |
| 冷启动读到旧数据        | 正常，用户手动刷新获取最新    | 最终一致  |
| 写入队列未完成 App 被杀 | 数据丢失，下次刷新重新写入    | 可接受    |
| 账号删除时数据残留      | 外键级联删除                  | 强一致    |

### 外键约束激活

HarmonyOS SQLite 默认**不开启**外键约束（`PRAGMA foreign_keys = OFF`），必须在每次打开数据库连接后显式开启，否则 `FOREIGN KEY` 声明形同虚设：

```typescript
// RdbManagerV2.init() 中，getRdbStore 成功后立即执行
await store.executeSql("PRAGMA foreign_keys = ON", []);
```

> 注意：`PRAGMA foreign_keys` 是连接级别设置，每次打开连接都需要重新设置，不会持久化到数据库文件。`RdbManagerV2.init()` 必须在建表之前执行此语句。

### Cookie 安全存储

`account_table.cookie` 字段目前以明文存储完整 Cookie 字符串，包含 `stoken`、`ltoken`、`cookie_token` 等敏感凭证。

**风险：** 若设备被 root 或数据库文件被提取，Cookie 将直接泄露，攻击者可完全控制米游社账号。

**缓解方案（分级）：**

| 方案                        | 实现复杂度 | 安全级别 | 说明                                                                |
| --------------------------- | ---------- | -------- | ------------------------------------------------------------------- |
| 使用 RDB SecurityLevel.S2   | 低         | 中       | 数据库文件加密，需要设备解锁才能访问，HarmonyOS 原生支持            |
| 应用层 AES 加密 Cookie 字段 | 中         | 高       | 写入前加密，读取后解密，密钥存储在 `HUKS`（HarmonyOS 密钥管理服务） |
| 将 stoken 单独存入 HUKS     | 中         | 高       | 最敏感的 stoken 不落 DB，直接存 HUKS，其他字段存 DB                 |

**V1.0 采用方案：使用 RDB SecurityLevel.S2**

```typescript
// RdbManagerV2.init() 中配置数据库安全级别
const config: relationalStore.StoreConfig = {
  name: "mihoyo_tools.db",
  securityLevel: relationalStore.SecurityLevel.S2, // 设备解锁后才可访问
};
```

`SecurityLevel.S2` 表示数据库文件在设备锁屏状态下不可访问，是 HarmonyOS 推荐的用户敏感数据存储级别，无需额外代码即可获得文件级加密保护。

**后续版本可升级为 HUKS 方案**，将 `stoken` 单独存入 HUKS，彻底隔离最高权限凭证。

---

## 扩展性设计

### 新增游戏类型（以崩坏 3 为例）

只需以下步骤，不修改任何现有文件：

**步骤 1：新增 API Path 枚举**

```typescript
// core/src/main/ets/network/v2/Honkai3ApiPath.ets
export enum Honkai3ApiPath {
  DAILY_NOTE = "/game_record/app/honkai3rd/api/note",
  AVATAR_BASIC = "/game_record/app/honkai3rd/api/avatar/basic",
  // ...
}
```

**步骤 2：新增 API Service**

```typescript
// core/src/main/ets/network/v2/Honkai3ApiService.ets
export class Honkai3ApiService extends MihoyoApiService {
  // 实现各接口方法
}
```

**步骤 3：新增数据库表（追加到 RdbManagerV2.createTables）**

```sql
CREATE TABLE IF NOT EXISTS honkai3_avatar_basic (...);
CREATE TABLE IF NOT EXISTS honkai3_daily_note (...);
-- ...
```

**步骤 4：新增 Repository**

```typescript
// core/src/main/ets/repository/v2/Honkai3Repository.ets
export class Honkai3Repository extends GameRepository {
  // 实现 findAll / findById / upsertAll / deleteAll
}
```

**步骤 5：注册到 sync_meta 的 data_type 枚举**

```typescript
// 新增 data_type 值
'honkai3_avatar_basic' | 'honkai3_daily_note' | ...
```

### 扩展性约束

| 约束                                 | 说明                                                 |
| ------------------------------------ | ---------------------------------------------------- |
| 新游戏不修改现有表                   | 每款游戏有独立的表集合，互不影响                     |
| 新游戏不修改现有 Repository          | 继承 `GameRepository`，独立实现                      |
| 新游戏不修改现有 API Service         | 继承 `MihoyoApiService`，独立实现                    |
| sync_meta 通用                       | 所有游戏共用同一张 sync_meta 表，通过 data_type 区分 |
| account_table / game_role_table 通用 | 所有游戏共用账号和角色绑定表                         |

---

## CoreInitializerV2 初始化流程

### 职责

`CoreInitializerV2` 是新版核心库的统一初始化入口，负责：

1. 初始化 `RdbManagerV2`（建表、版本迁移）
2. 根据运行环境（Mock / Release）创建对应的 Service 实例
3. 将 Service 注入到各 Repository
4. 暴露 `waitForReady()` 供调用方等待初始化完成

### 初始化时序

```
EntryAbility.onCreate()
    │
    ▼
CoreInitializerV2.initCore({ isMock, context })
    │
    ├── 1. RdbManagerV2.init(context)
    │       ├── getRdbStore（打开/创建数据库文件，SecurityLevel.S2）
    │       ├── PRAGMA foreign_keys = ON（激活外键约束，每次连接必须设置）
    │       ├── createTables()（建 15 张表 + 索引）
    │       └── runMigrations()（版本迁移，见下节）
    │
    ├── 1.5 ApiConfigV2.preloadDeviceId(context)
    │       └── 从 Preferences 读取或生成 device_id，缓存到内存
    │
    ├── 1.6 ApiConfigV2.preloadDeviceFp(context)
    │       └── 从 Preferences 读取或生成 device_fp，缓存到内存
    │
    ├── 1.7 DSUtilV2.setSalts(v1, v2, x6)
    │       └── 从 rawfile/release/salt_config.json 读取 salt 值并注入
    │           （salt_config.json 不提交 git，加入 .gitignore）
    │           Mock 环境：注入占位字符串（如 "mock_salt"），
    │           因为 MockService 不调用 MihoyoHeaderBuilder，不会实际使用 salt
    │
    ├── 2. MihoyoApiServiceFactory.create(env)
    │       ├── Mock 环境 → 创建各 MockService 实例（含 SignMockService）
    │       └── Release 环境 → 创建各 ApiService 实例（含 SignApiService）
    │
    ├── 3. 注入 Service 到 Repository
    │       ├── BBSRepository.setService(accountService)
    │       ├── GenshinRepository.setService(genshinService)
    │       ├── StarRailRepository.setService(starRailService)
    │       ├── ZZZRepository.setService(zzzService)
    │       └── SignRepository.setService(signService)
    │
    └── 4. readyResolve()（通知所有等待方初始化完成）
```

### 代码结构

```typescript
// core/src/main/ets/CoreInitializerV2.ets
import { common } from "@kit.AbilityKit";
import { util } from "@kit.ArkTS";
// 还需要 import：RdbManagerV2, ApiConfigV2, DSUtilV2, MihoyoEnvironment,
// MihoyoApiServiceFactory, BBSRepository, GenshinRepository,
// StarRailRepository, ZZZRepository, SignRepository

/** 核心库配置接口 */
interface CoreConfig {
  isMock: boolean;
  context: common.UIAbilityContext;
}

export class CoreInitializerV2 {
  private static initialized: boolean = false;
  // initializing 标志防止并发重复初始化（如 App 快速重启时 initCore 被调用两次）
  private static initializing: boolean = false;
  // ArkTS 严格模式：函数类型字段必须有初始值，使用联合类型允许 null
  private static readyResolve: (() => void) | null = null;
  private static readyReject: ((e: Error) => void) | null = null;
  private static readyPromise: Promise<void> = new Promise<void>(
    (resolve, reject) => {
      CoreInitializerV2.readyResolve = resolve;
      CoreInitializerV2.readyReject = reject;
    },
  );

  public static async initCore(config: CoreConfig): Promise<void> {
    if (CoreInitializerV2.initialized || CoreInitializerV2.initializing) {
      return;
    }
    CoreInitializerV2.initializing = true;

    try {
      // 1. 初始化数据库
      await RdbManagerV2.init(config.context);

      // 1.5 预加载设备 ID 和 device_fp（buildHeaders 是同步方法，需提前加载）
      await ApiConfigV2.preloadDeviceId(config.context);
      await ApiConfigV2.preloadDeviceFp(config.context);

      // 1.7 注入 DS salt（从 rawfile 读取，不硬编码在源码中）
      // Mock 环境注入占位字符串，因为 MockService 不调用 MihoyoHeaderBuilder
      if (config.isMock) {
        DSUtilV2.setSalts("mock_salt", "mock_salt", "mock_salt");
      } else {
        // 使用 resourceManager 读取 rawfile（项目里没有 RawFileUtil，直接用系统 API）
        const rm = config.context.resourceManager;
        const fileContent = await rm.getRawFileContent(
          "release/salt_config.json",
        );
        const decoder = new util.TextDecoder("utf-8");
        const jsonStr = decoder.decodeToString(
          new Uint8Array(fileContent.buffer),
        );
        const saltConfig = JSON.parse(jsonStr) as Record<string, Object>;
        DSUtilV2.setSalts(
          saltConfig["salt_v1"] as string,
          saltConfig["salt_v2"] as string,
          saltConfig["salt_x6"] as string,
        );
      }

      // 2. 创建 Service（根据 isMock 决定实现）
      // Mock 环境需要传入 context 用于读取 rawfile
      const env = config.isMock
        ? MihoyoEnvironment.MOCK
        : MihoyoEnvironment.RELEASE;
      // ArkTS 严格模式：明确类型，Mock 时传入 context，Release 时传 undefined
      const ctx: common.UIAbilityContext | undefined = config.isMock
        ? config.context
        : undefined;
      const accountService = MihoyoApiServiceFactory.createAccountService(
        env,
        ctx,
      );
      const genshinService = MihoyoApiServiceFactory.createGenshinService(
        env,
        ctx,
      );
      const starRailService = MihoyoApiServiceFactory.createStarRailService(
        env,
        ctx,
      );
      const zzzService = MihoyoApiServiceFactory.createZZZService(env, ctx);
      const signService = MihoyoApiServiceFactory.createSignService(env, ctx);

      // 3. 注入 Service 到 Repository（单例注入）
      BBSRepository.getInstance().setService(accountService);
      GenshinRepository.getInstance().setService(genshinService);
      StarRailRepository.getInstance().setService(starRailService);
      ZZZRepository.getInstance().setService(zzzService);
      SignRepository.getInstance().setService(signService);

      CoreInitializerV2.initialized = true;
      if (CoreInitializerV2.readyResolve !== null) {
        CoreInitializerV2.readyResolve();
        CoreInitializerV2.readyResolve = null;
      }
    } catch (e) {
      // 初始化失败：reject readyPromise，防止所有 waitForReady() 调用方永久挂起
      CoreInitializerV2.initializing = false;
      if (CoreInitializerV2.readyReject !== null) {
        const err = e instanceof Error ? (e as Error) : new Error(String(e));
        CoreInitializerV2.readyReject(err);
        CoreInitializerV2.readyReject = null;
      }
      throw e; // 继续向上抛，让 EntryAbility 感知到初始化失败
    }
  }

  public static waitForReady(): Promise<void> {
    return CoreInitializerV2.readyPromise;
  }
}
```

### Repository 单例模式

每个 Repository 以单例形式存在，Service 通过 `setService()` 注入，避免构造函数参数传递：

```typescript
export class GenshinRepository extends GameRepository {
  private static instance: GenshinRepository = new GenshinRepository();
  // ArkTS 严格模式：null 初始值需要联合类型声明
  private service: MihoyoApiService | null = null;

  static getInstance(): GenshinRepository {
    return GenshinRepository.instance;
  }

  setService(service: MihoyoApiService): void {
    this.service = service;
  }

  // 所有需要 service 的方法必须先检查 null，防止 initCore 未完成时被调用
  private getService(): MihoyoApiService {
    if (this.service === null) {
      throw new Error(
        "GenshinRepository: service not initialized, call CoreInitializerV2.initCore() first",
      );
    }
    return this.service;
  }
}
```

**防护原则：** ViewModel 在 `aboutToAppear()` 中调用 Repository 时，`CoreInitializerV2.initCore()` 可能尚未完成（异步初始化）。Repository 的每个公开方法必须通过 `getService()` 获取 service，而非直接访问 `this.service`，确保 null 检查统一在一处处理。

**推荐模式：** ViewModel 在调用 Repository 前先 `await CoreInitializerV2.waitForReady()`，确保初始化完成：

```typescript
// ViewModel.aboutToAppear() 推荐写法
async aboutToAppear(): Promise<void> {
  await CoreInitializerV2.waitForReady();
  await this.vm.loadData();
}
```

---

## DB 版本管理

### 版本号机制

`RdbManagerV2` 使用 `user_version` pragma 追踪数据库 schema 版本，App 升级时自动执行对应迁移脚本。

**HarmonyOS 兼容性确认：** HarmonyOS ArkData RDB 底层是 SQLite，`PRAGMA user_version` 是 SQLite 内置的用户自定义版本号机制（整数，默认 0），通过 `store.querySql()` 和 `store.executeSql()` 均可正常读写，无需额外 API。

```typescript
// 当前数据库版本（V1.0 全新建表，起始版本号为 1）
private static readonly DB_VERSION: number = 1;

private static async runMigrations(store: relationalStore.RdbStore): Promise<void> {
  let currentVersion = 0;
  const rs = await store.querySql('PRAGMA user_version', []);
  try {
    if (rs.goToFirstRow()) {
      currentVersion = rs.getLong(0);
    }
  } finally {
    rs.close();
  }

  // V1.0 全新安装：currentVersion = 0，直接建表，无需迁移
  // 未来版本示例：
  // if (currentVersion < 2) { await RdbManagerV2.migrateV1ToV2(store); }

  await store.executeSql(`PRAGMA user_version = ${RdbManagerV2.DB_VERSION}`, []);
}
```

### 版本迁移策略

**全新安装（version = 0）：**

- `createTables()` 使用 `CREATE TABLE IF NOT EXISTS`，幂等建表
- 无需额外迁移，直接将 `user_version` 设为 1

**App 升级（version < 当前版本）：**

- 按版本号顺序依次执行迁移函数
- 每个迁移函数只负责从上一版本升级到下一版本
- 迁移函数在事务中执行，失败时回滚

### 新增字段迁移工具（ALTER TABLE）

当新版本需要为已有表新增字段时，使用 `migrateAddColumn` 安全添加（列已存在时幂等忽略）：

```typescript
private static async migrateAddColumn(
  store: relationalStore.RdbStore,
  tableName: string,
  columnName: string,
  columnType: string,
  defaultValue?: string
): Promise<void> {
  try {
    // 注意：字符串类型的 defaultValue 需要加单引号，数字类型不需要
    // 调用方负责传入正确格式，如数字传 '0'，字符串传 "''（空字符串）"
    const defaultClause = defaultValue !== undefined ? ` DEFAULT ${defaultValue}` : '';
    await store.executeSql(
      `ALTER TABLE ${tableName} ADD COLUMN ${columnName} ${columnType}${defaultClause}`,
      []
    );
  } catch (_) {
    // 列已存在时 SQLite 报错，直接忽略（幂等）
  }
}
```

> 注意：`defaultValue` 参数的格式由调用方负责：
>
> - 数字类型：传 `'0'`，生成 `DEFAULT 0`
> - 文本类型：传 `"''"` （含单引号），生成 `DEFAULT ''`
> - 不传：无 DEFAULT 子句

### 版本迁移记录表

| 版本 | 变更内容                          | 迁移方式    |
| ---- | --------------------------------- | ----------- |
| v1   | V1.0 全新建表：15 张专用表 + 索引 | CREATE 建表 |
| v2   | （预留）如需新增字段，在此追加    | ALTER TABLE |

---

## 扩展性约束

| 约束                                 | 说明                                                 |
| ------------------------------------ | ---------------------------------------------------- |
| 新游戏不修改现有表                   | 每款游戏有独立的表集合，互不影响                     |
| 新游戏不修改现有 Repository          | 继承 `GameRepository`，独立实现                      |
| 新游戏不修改现有 API Service         | 继承 `MihoyoApiService`，独立实现                    |
| sync_meta 通用                       | 所有游戏共用同一张 sync_meta 表，通过 data_type 区分 |
| account_table / game_role_table 通用 | 所有游戏共用账号和角色绑定表                         |
