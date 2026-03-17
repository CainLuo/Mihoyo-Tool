# 数据库架构设计文档

## 概述

本项目采用**混合分层存储 + Query Builder + Repository 模式**，支持米游社旗下所有游戏（原神、星穹铁道、绝区零、崩坏3等）的本地持久化数据管理。

设计目标：

- 业务代码零 SQL 字符串
- 新增游戏只加 Parser/Calculator，数据库表不动
- 新增统计指标只加 stat_key，表不动
- 支持大批量查询、统计计算、跨游戏数据聚合

---

## 表结构

### 1. `account_table` — 米游社账号

```sql
CREATE TABLE IF NOT EXISTS account_table (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  username    TEXT UNIQUE,
  cookie      TEXT,
  is_active   INTEGER DEFAULT 0,
  create_time INTEGER,
  update_time INTEGER
);
```

### 2. `game_role_table` — 各游戏角色（UID）

```sql
CREATE TABLE IF NOT EXISTS game_role_table (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id INTEGER,
  game_id    TEXT,   -- "genshin" / "starrail" / "zzz" / "honkai3"
  role_id    TEXT,   -- 游戏内 UID
  nickname   TEXT,
  level      INTEGER,
  server     TEXT,
  FOREIGN KEY (account_id) REFERENCES account_table(id)
);
```

### 3. `game_data` — 所有游戏所有数据类型（核心表）

```sql
CREATE TABLE IF NOT EXISTS game_data (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  game_id     TEXT    NOT NULL,  -- 游戏标识
  role_uid    TEXT    NOT NULL,  -- 游戏内 UID，公共数据填 "global"
  data_type   TEXT    NOT NULL,  -- 数据类型，见下方枚举
  entity_id   TEXT    NOT NULL,  -- 数据唯一标识
  name        TEXT,              -- 名称（可搜索）
  rarity      INTEGER,           -- 星级（可过滤）
  level       INTEGER,           -- 等级（可过滤）
  extra_int1  INTEGER,           -- 扩展整数字段1，语义由 data_type 决定
  extra_int2  INTEGER,           -- 扩展整数字段2
  extra_text1 TEXT,              -- 扩展文本字段1
  raw_json    TEXT    NOT NULL,  -- 完整原始 JSON
  update_time INTEGER            -- 最后更新时间戳（Unix 秒）
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_game_data_unique
  ON game_data(game_id, role_uid, data_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_game_data_query
  ON game_data(game_id, role_uid, data_type);
CREATE INDEX IF NOT EXISTS idx_game_data_activity
  ON game_data(game_id, data_type, extra_int2);
```

#### `data_type` 枚举说明

| data_type     | 含义           | extra_int1      | extra_int2  | extra_text1 |
| ------------- | -------------- | --------------- | ----------- | ----------- |
| character     | 角色/代理人    | 命座数          | 好感度      | 元素属性    |
| weapon        | 武器/光锥/音擎 | 精炼/叠影等级   | -           | 武器类型    |
| relic         | 圣遗物/遗器    | 部位(1-6)       | 套装 ID     | -           |
| activity      | 活动           | 开始时间        | 结束时间    | 活动类型    |
| gacha_record  | 抽卡记录(单条) | 卡池类型        | 是否UP(0/1) | 物品类型    |
| gacha_summary | 抽卡统计摘要   | 卡池类型        | 总抽数      | -           |
| daily_note    | 实时便笺       | 当前树脂/开拓力 | 最大值      | -           |
| abyss         | 深渊/混沌回忆  | 层数            | 星数        | 赛季标识    |

### 4. `game_stats` — 预计算统计结果

```sql
CREATE TABLE IF NOT EXISTS game_stats (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  game_id     TEXT NOT NULL,
  role_uid    TEXT NOT NULL,
  entity_id   TEXT NOT NULL,  -- 关联 game_data.entity_id
  stat_key    TEXT NOT NULL,  -- 统计指标名，见下方说明
  stat_value  REAL,           -- 数值结果
  update_time INTEGER
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_game_stats_unique
  ON game_stats(game_id, role_uid, entity_id, stat_key);
```

#### `stat_key` 约定

| stat_key      | 含义                 | 适用游戏     |
| ------------- | -------------------- | ------------ |
| relic_score   | 圣遗物/遗器装备分    | 原神、星铁   |
| is_graduated  | 是否毕业(1=是, 0=否) | 原神、星铁   |
| crit_rate     | 暴击率(%)            | 原神         |
| crit_dmg      | 暴击伤害(%)          | 原神         |
| pity_count    | 当前保底计数         | 所有抽卡游戏 |
| up_pity_count | 大保底计数(0或1)     | 所有抽卡游戏 |

### 5. `sync_meta` — 同步状态追踪

```sql
CREATE TABLE IF NOT EXISTS sync_meta (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  game_id        TEXT NOT NULL,
  role_uid       TEXT NOT NULL,
  data_type      TEXT NOT NULL,
  last_sync_time INTEGER,
  sync_status    TEXT,  -- "success" / "failed" / "syncing"
  error_msg      TEXT
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_meta_unique
  ON sync_meta(game_id, role_uid, data_type);
```

---

## 代码层架构

```
core/src/main/ets/
├── database/
│   ├── RdbManager.ets          # 底层 RDB 封装（CRUD + 事务）
│   ├── QueryBuilder.ets        # 链式 Query Builder，翻译为 RdbPredicates
│   ├── GameDataDao.ets         # 基于 game_data 表的通用 DAO
│   ├── GameStatsDao.ets        # 基于 game_stats 表的统计 DAO
│   └── index.ets               # 数据库模块导出
├── models/
│   ├── GameDataRow.ets         # game_data 行模型
│   ├── GameStatsRow.ets        # game_stats 行模型
│   └── index.ts                # 模型导出
├── repository/
│   ├── CharacterRepository.ets # 角色数据 Repository
│   ├── ActivityRepository.ets  # 活动数据 Repository
│   ├── GachaRepository.ets     # 抽卡记录 Repository
│   └── index.ts                # Repository 导出
├── parsers/                    # 各游戏 raw_json → 业务模型（待实现）
│   └── genshin/
│       └── GenshinCharacterParser.ets
└── calculators/                # 各游戏统计计算（待实现）
    └── genshin/
        └── GenshinScoreCalculator.ets
```

---

## 数据流

```
网络拉取 → 写入 game_data（raw_json）
                ↓
         触发后台计算（TaskPool）
                ↓
         Calculator.calculate(rawJson)
                ↓
         写入 game_stats（预计算结果）

查询时：
  列表页 → Repository.findAll() → GameDataDao（只查通用列，不读 raw_json）
  详情页 → Repository.findById() → GameDataDao（读 raw_json）→ Parser.parse()
  统计页 → Repository.findTopByScore() → GameStatsDao（纯 SQL，极快）
```

---

## 扩展指南

### 新增游戏（如绝区零）

1. 在 `parsers/zzz/` 下新建 `ZZZAgentParser.ets`
2. 在 `calculators/zzz/` 下新建 `ZZZScoreCalculator.ets`
3. 约定新的 `data_type` 和 `extra_*` 字段语义（更新本文档）
4. 数据库表结构**不需要任何改动**

### 新增统计指标

1. 在对应 Calculator 中新增计算逻辑
2. 约定新的 `stat_key`（更新本文档）
3. 数据库表结构**不需要任何改动**

### 新增数据类型（如排行榜）

1. 约定新的 `data_type` 值和 `extra_*` 字段语义
2. 在对应 Repository 中新增方法
3. 数据库表结构**不需要任何改动**
