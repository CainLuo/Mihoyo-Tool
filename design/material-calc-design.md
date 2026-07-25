# 材料计算功能优化方案 v2.0.0

## 一、背景与需求

### 1.1 现状分析

当前项目已有三张材料计算缓存表：
- `genshin_character_compute` — 原神角色养成计算
- `starrail_avatar_compute` — 星铁角色养成计算
- `zzz_avatar_compute` — 绝区零角色养成计算

三张表结构相似，但使用方式存在差异：
- **原神**：API 支持批量请求（最多 8 个角色 + 武器）
- **星铁/绝区零**：API 仅支持单角色请求

### 1.2 核心需求

1. **数据库设计**：新增 `material_bag` 表存储玩家背包材料
2. **API 请求策略**：根据游戏特性实现不同的请求策略
3. **材料汇总**：统一列出所有缺失材料
4. **缓存管理**：逐次缓存每次请求的数据，避免重复请求

---

## 二、API 差异分析

> API 文档来源：`core/src/main/resources/rawfile/release/mihoyo_apis.md`

### 2.1 原神（批量请求）

| 属性 | 值 |
|-----|-----|
| API | `/event/e20200928calculate/v3/batch_compute` |
| 方法 | POST |
| 最大批量 | 8 个角色（含武器） |
| Header Profile | `CALCULATE` |
| 特殊 Header | `x-rpc-cal_type: 1` |

**请求体结构**：
```json
{
  "items": [
    {
      "avatar_id": 10000122,
      "avatar_level_current": 1,
      "avatar_level_target": 90,
      "element_attr_id": 4,
      "skill_list": [
        { "id": 12231, "level_current": 1, "level_target": 10 }
      ],
      "from_user_sync": false
    }
  ],
  "lang": "zh-cn",
  "region": "cn_gf01",
  "uid": "109050292"
}
```

**`from_user_sync` 参数说明**：
- `false`（默认）：仅计算所需材料，不返回玩家背包数据
- `true`：尝试从服务器同步玩家背包材料数据，并在响应中返回 `items` 字段包含玩家已拥有材料

> ⚠️ **注意**：原神 `from_user_sync: true` 参数的实际行为需要实测验证。根据 API 文档和社区反馈，该参数可能无法稳定返回背包数据，或者需要特定的认证条件。
>
> **当前设计策略**：
> - 如果 `from_user_sync: true` 能返回背包数据 → 直接使用，与星铁/绝区零处理方式相同
> - 如果 `from_user_sync: true` 不可靠 → 使用 `lack_num` 反推算法（已在 3.2 节论证无偏差）
> - 用户手动输入 → 作为兜底方案，但**不强制要求**

### 2.2 星穹铁道（单角色请求）

| 属性 | 值 |
|-----|-----|
| API | `/event/rpgcalc/compute?game=hkrpg` |
| 方法 | POST |
| 批量 | 不支持，单角色请求 |
| Header Profile | `CALCULATE` |

**请求体结构**：
```json
{
  "game": "hkrpg",
  "avatar": {
    "item_id": "1504",
    "cur_level": 1,
    "target_level": 80
  },
  "skill_list": [
    { "item_id": "1504001", "cur_level": 1, "target_level": 6 },
    { "item_id": "1504002", "cur_level": 1, "target_level": 10 }
  ],
  "lang": "zh-cn",
  "uid": "102731382",
  "region": "prod_gf_cn"
}
```

### 2.3 绝区零（单角色请求）

| 属性 | 值 |
|-----|-----|
| API | `/event/nap_cultivate_tool/avatar_calc?uid=xxx&region=prod_gf_cn` |
| 方法 | POST |
| 批量 | 不支持，单角色请求 |

**请求体结构**：
```json
{
  "avatar_id": 1051,
  "avatar_level": 60,
  "avatar_current_level": 1,
  "avatar_current_promotes": 1,
  "skills": [
    { "skill_type": 0, "level": 6 }
  ]
}
```

---

## 三、背包数据获取方案

### 3.1 三游戏 API 返回数据差异

| 游戏 | 批量请求 | 返回背包数据 | 背包数据字段 |
|-----|---------|------------|-------------|
| 原神 | ✅ 支持（8 个角色） | ❌ 不返回 | `lack_num` 永远为 0 |
| 星铁 | ❌ 单角色 | ✅ 返回 | `user_owns_materials: {"item_id": count}` |
| 绝区零 | ❌ 单角色 | ✅ 返回 | `user_owns_materials: {"id": count}` |

### 3.2 原神背包数据处理

#### 3.2.1 API 返回数据结构

原神批量请求（最多 8 个角色）返回的数据包含：

```json
{
  "data": {
    "items": [...],  // 每个角色的详细材料需求
    "overall_consume": [  // 汇总材料列表
      {
        "id": 104364,
        "name": "「浪迹」的哲学",
        "num": 228,        // 本批次总需求
        "lack_num": 125    // 本批次缺口
      }
    ]
  }
}
```

**关键字段**：
- `num`：本批次（最多 8 个角色）的总需求
- `lack_num`：本批次的缺口 = num - 背包拥有量

#### 3.2.2 核心问题：跨批次汇总

**问题 1**：不能直接累加 `lack_num`

假设背包有 103 个「浪迹」的哲学：
- 批次 1：需求 228 → `lack_num = 125`
- 批次 2：需求 114 → `lack_num = 11`

错误做法：
```
总缺口 = 125 + 11 = 136 ❌（背包被减了两次）
```

正确做法：
```
背包 = 228 - 125 = 103（从批次 1 反推）
总需求 = 228 + 114 = 342
总缺口 = 342 - 103 = 239 ✅
```

**问题 2**：跨批次可能有角色重叠

通过实测数据分析，发现：
- 不同批次可能请求了**部分相同的角色**
- 如果直接累加 `num`，会导致重复计算

**解决方案**：按角色维度存储和汇总

```
存储结构：
  genshin_character_compute 表
    ├── avatar_id: 角色ID（唯一键）
    ├── avatar_consume_json: 角色升级材料
    ├── skill_consume_json: 技能升级材料
    └── weapon_consume_json: 武器升级材料

汇总逻辑：
  1. 从数据库读取所有角色的材料需求
  2. 按材料 ID 去重并累加需求
  3. 从最后一次请求的 overall_consume 反推背包数量
  4. 总缺口 = 总需求 - 背包数量
```

#### 3.2.3 算法实现

```typescript
interface MaterialSummary {
  materialId: number;
  totalNeed: number;    // 总需求（所有角色累加）
  bagCount: number;     // 背包拥有量
  totalLack: number;    // 总缺口 = totalNeed - bagCount
}

function computeMaterialSummary(
  allCharacters: GenshinCharacterComputeRow[],  // 所有角色的计算结果
  lastBatchOverall: OverallConsume[]            // 最后一次请求的汇总
): MaterialSummary[] {
  // 1. 按材料ID累加所有角色的需求
  const needMap = new Map<number, number>();
  for (const char of allCharacters) {
    const materials = parseMaterialsFromCharacter(char);
    for (const mat of materials) {
      const current = needMap.get(mat.id) || 0;
      needMap.set(mat.id, current + mat.num);
    }
  }
  
  // 2. 从最后一次请求反推背包数量
  const bagMap = new Map<number, number>();
  for (const mat of lastBatchOverall) {
    if (mat.lack_num > 0) {
      bagMap.set(mat.id, mat.num - mat.lack_num);
    } else {
      bagMap.set(mat.id, mat.num);  // 背包充足
    }
  }
  
  // 3. 计算总缺口
  const result: MaterialSummary[] = [];
  for (const [materialId, totalNeed] of needMap) {
    const bagCount = bagMap.get(materialId) || 0;
    const totalLack = Math.max(0, totalNeed - bagCount);
    result.push({ materialId, totalNeed, bagCount, totalLack });
  }
  
  return result;
}
```

#### 3.2.4 数学证明

**设**：
- 背包数量为 B
- 角色 1 ~ M 各自需要材料 X 的数量为 N₁, N₂, ..., N_M
- 总需求 Σ(N_i)

**API 行为**：
- 批量请求返回的 `lack_num = num - B`（当 num > B 时）
- 反推：`B = num - lack_num`

**总缺口计算**：
```
总缺口 = Σ(N_i) - B = Σ(N_i) - (num_k - lack_num_k)
```

**无偏差证明**：
- 如果请求的是不同角色，Σ(N_i) 是真实总需求
- 背包 B 是唯一值，从任一批次反推的结果相同
- 因此总缺口 = 真实总需求 - 背包 = 正确结果 ✅

### 3.3 星铁/绝区零背包数据处理

**现状**：每次请求角色计算时，API 返回 `user_owns_materials`，包含玩家真实背包数据。

#### 3.3.1 API 返回数据格式

**星铁**：
```json
{
  "data": {
    "avatar_consume": [...],
    "skill_consume": [...],
    "equipment_consume": [...],
    "user_owns_materials": {
      "112012": 15,  // "古代转轴": 15 个
      "241": 19,     // "命运的足迹": 19 个
      ...
    }
  }
}
```

**绝区零**：
```json
{
  "data": {
    "avatar_consume": [...],
    "skill_consume": [...],
    "user_owns_materials": {
      "10": 127559,    // "丁尼": 127559 个
      "300003": 48,    // "资深调查员记录": 48 个
      ...
    }
  }
}
```

#### 3.3.2 数学论证

**设**：
- 背包数量为 B（玩家真实拥有）
- 角色 1 ~ M 各自需要材料 X 的数量为 N₁, N₂, ..., N_M

**星铁/绝区零 API 特性**：
- 每次请求返回的 `user_owns_materials` 是**同一时刻的真实背包数据**
- 无论请求多少次，同一个材料的背包值 B 是相同的（除非玩家在请求期间消费了材料）

**正确算法**：
```
总需求 = Σ(N_i) = N₁ + N₂ + ... + N_M
背包拥有量 = B（从任意一次请求的 user_owns_materials 获取）
总缺口 = Σ(N_i) - B

如果 总缺口 < 0，则缺口 = 0（背包充足）
```

**数学证明**：

假设请求顺序为角色 1 → 角色 2 → ... → 角色 M：

1. 请求角色 1 时，API 返回 `user_owns_materials[X] = B`
2. 请求角色 2 时，API 返回 `user_owns_materials[X] = B`（相同值）
3. ... 所有请求返回的 B 都相同

**错误做法**（背包被减多次）：
```
角色 1 缺口 = N₁ - B = 12
角色 2 缺口 = N₂ - B = 17
总缺口 = 12 + 17 = 29 ❌ 错误！
```

**正确做法**：
```
总缺口 = (N₁ + N₂) - B = (15 + 20) - 3 = 32 ✅ 正确！
```

#### 3.3.3 与原神算法对比

| 方面 | 原神 | 星铁/绝区零 |
|-----|------|-----------|
| 请求方式 | 批量（8 个角色/次） | 单角色 |
| API 返回背包数据 | ❌ 只返回 `lack_num` | ✅ 返回 `user_owns_materials` |
| 背包数据来源 | 从 `lack_num` 反推（`B = num - lack_num`） | 直接从 `user_owns_materials` 获取 |
| 总缺口计算 | `Σ(num) - B` | `Σ(num) - B` |
| **数学本质** | **完全相同** | **完全相同** |

#### 3.3.4 数据处理流程

```
请求角色 1 计算
  ├── 获得 avatar_consume（角色升级材料）
  ├── 获得 skill_consume（技能升级材料）
  ├── 获得 equipment_consume（光锥升级材料，星铁专有）
  └── 获得 user_owns_materials → 写入 material_bag 表

请求角色 2 计算
  ├── 获得 consume 数据
  └── 获得 user_owns_materials → 覆盖 material_bag 表（取最新值）

... 继续 M 个角色

汇总时：
  ├── 从各角色的 consume 数据累加总需求 Σ(N_i)
  ├── 从 material_bag 表读取背包拥有量 B
  └── 计算总缺口 = Σ(N_i) - B
```

#### 3.3.5 数据一致性保证

**问题**：假设有 80 个角色，请求期间背包变化怎么办？

**答案**：星铁/绝区零每次请求都返回**实时背包数据**，取最后一次请求的值即可。如果担心请求期间玩家消费了材料，可以在 UI 上提供「刷新背包数据」按钮，重新请求一次任意角色即可获得最新背包数据。

**不需要用户手动输入**：星铁/绝区零的 `user_owns_materials` 已经包含真实背包数据，直接存储使用即可。

### 3.4 背包数据同步时机

| 触发场景 | 星铁/绝区零 | 原神 |
|---------|-----------|-----|
| 请求角色计算 | 自动写入 `material_bag`（取最后值） | 无背包数据 |
| 跨角色相同材料 | 缺口累加（需求 - 同一背包值） | 缺口累加（需求直接相加） |
| 用户手动输入 | 支持手动覆盖背包数据 | 必须手动输入 |

### 3.5 数据一致性保证

**问题**：假设有 80 个角色，如何保证数据不出现差错？

#### 3.5.1 三游戏统一数学模型

无论是原神的批量请求，还是星铁/绝区零的单角色请求，**数学本质完全相同**：

```
总缺口 = Σ(各角色的需求) - 背包拥有量
```

**差异只在于背包数据的获取方式**：
- 原神：从 `lack_num` 反推（`B = num - lack_num`）
- 星铁/绝区零：直接从 `user_owns_materials` 获取

#### 3.5.2 原神方案（批量请求）

**场景**：80 个角色，按每批 8 个计算，需要 10 批请求。

**算法**：
1. 累加所有批次的 `num` 得到总需求 Σ(N_i)
2. 从最后一个 `lack_num > 0` 的批次计算背包数量：`B = num - lack_num`
3. 总缺口 = Σ(N_i) - B
4. 如果所有批次 `lack_num = 0`，则总缺口 = 0（背包充足）

**数据一致性**：
- 同一批次内，API 已自动计算重复材料
- 跨批次的相同材料，按上述算法累加后减去背包值，无偏差

#### 3.5.3 星铁/绝区零方案（单角色请求）

**场景**：80 个角色，需要 80 次请求。

**算法**：
1. 累加所有角色的 `num` 得到总需求 Σ(N_i)
2. 从任意一次请求的 `user_owns_materials` 获取背包数量 B
3. 总缺口 = Σ(N_i) - B
4. 如果总缺口 < 0，则缺口 = 0

**数据一致性**：
- 每次请求都返回实时背包数据
- 取最后一次请求的 `user_owns_materials` 存入 `material_bag` 表
- 请求期间背包变化 → 取最后一次请求的值（最新数据）

**不需要用户手动输入**：星铁/绝区零的 API 已返回真实背包数据。

### 3.6 背包数据更新策略

#### 3.6.1 星铁/绝区零

```
请求角色 A 计算 → 获得 user_owns_materials → 写入 material_bag 表（覆盖）
请求角色 B 计算 → 获得 user_owns_materials → 写入 material_bag 表（覆盖）
...
最后汇总时：
  1. 累加所有角色的需求 Σ(N_i)
  2. 从 material_bag 表读取背包拥有量 B
  3. 计算总缺口 = Σ(N_i) - B
```

**覆盖策略**：`user_owns_materials` 是实时数据，直接覆盖旧值，保证数据最新。

#### 3.6.2 原神

```
请求批次 1（8 个角色） → 获得 items 列表 + lack_num → 写入 compute 表
请求批次 2（8 个角色） → 获得 items 列表 + lack_num → 写入 compute 表
...
最后汇总时：
  1. 累加所有批次的 num 得到 Σ(N_i)
  2. 从最后一批 lack_num > 0 的数据反推背包 B = num - lack_num
  3. 计算总缺口 = Σ(N_i) - B
```

**无背包表**：原神不需要 `material_bag` 表，因为背包数据可以从 `lack_num` 反推。

#### 3.6.3 跨游戏数据隔离

`material_bag` 表通过 `game_id` 字段区分不同游戏的材料数据，三游戏数据互不干扰：

```
material_bag 表：
  ├── game_id = 'genshin' → 原神材料（用户手动输入）
  ├── game_id = 'starrail' → 星铁材料（API 自动获取）
  └── game_id = 'zzz' → 绝区零材料（API 自动获取）
```

---

## 四、数据库设计

### 4.1 新增表：`material_bag`

存储玩家背包中的材料数据，支持多账号数据隔离。

```sql
CREATE TABLE IF NOT EXISTS material_bag (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id TEXT NOT NULL,           -- 米游社账号 UID（外键 → account_table.uid）
  material_id TEXT NOT NULL,          -- 材料 ID（统一 string 类型，兼容三游戏）
  material_name TEXT NOT NULL,        -- 材料名称
  material_icon TEXT,                 -- 材料图标 URL
  rarity TEXT DEFAULT '',             -- 稀有度（S/A/B/C 或 1-5，统一存 string）
  count INTEGER DEFAULT 0,            -- 拥有数量（星铁/绝区零来自 API，原神手动输入）
  source TEXT DEFAULT 'api',          -- 数据来源：api 或 manual
  game_id TEXT NOT NULL,              -- 游戏标识（genshin/starrail/zzz）
  update_time INTEGER DEFAULT 0,      -- 更新时间戳
  UNIQUE(account_id, material_id, game_id),
  FOREIGN KEY (account_id) REFERENCES account_table(uid) ON DELETE CASCADE
)
```

**字段说明**：

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | INTEGER | 自增主键 |
| account_id | TEXT | 米游社账号 UID，关联 `account_table.uid`，删除账号时级联删除 |
| material_id | TEXT | 材料 ID，统一使用 string 类型（星铁 `item_id`、绝区零 `id`、原神 `id` 都转为 string） |
| material_name | TEXT | 材料名称 |
| material_icon | TEXT | 材料图标 URL |
| rarity | TEXT | 稀有度，星铁/绝区零返回 string（S/A/B/C），原神返回 number（1-5），存储时统一转 string |
| count | INTEGER | 玩家拥有数量，**星铁/绝区零从 API 自动获取，原神需要用户手动输入或从 lack_num 反推** |
| source | TEXT | 数据来源：`api`（API 自动获取）或 `manual`（用户手动输入）或 `computed`（从 lack_num 反推），用于区分数据可信度 |
| game_id | TEXT | 游戏标识，使用 `GameId` 枚举值（'genshin'/'starrail'/'zzz'） |
| update_time | INTEGER | 最后更新时间戳（Unix 秒） |

**唯一键约束**：`(account_id, material_id, game_id)` 确保同一账号下同一游戏同一材料只有一条记录。

**外键约束**：`account_id` 关联 `account_table.uid`，删除账号时级联删除所有材料数据。

### 4.2 修改现有 Compute 表

为三张 Compute 表添加 `raw_json` 字段，存储完整 API 响应：

```sql
ALTER TABLE genshin_character_compute ADD COLUMN raw_json TEXT DEFAULT '';
ALTER TABLE starrail_avatar_compute ADD COLUMN raw_json TEXT DEFAULT '';
ALTER TABLE zzz_avatar_compute ADD COLUMN raw_json TEXT DEFAULT '';
```

---

## 五、多用户数据隔离方案

### 5.1 数据隔离设计

本 App 支持多米游社账号登录，材料背包数据必须按账号隔离：

```
account_table (米游社账号)
  ├── uid: '348366494' (账号 1)
  │     ├── material_bag (原神材料)
  │     ├── material_bag (星铁材料)
  │     └── material_bag (绝区零材料)
  │
  └── uid: '182692936' (账号 2)
        ├── material_bag (原神材料)
        └── ...
```

### 5.2 数据访问逻辑

1. **读取背包数据**：`MaterialBagDao.findByAccountAndGame(accountId, gameId)`
2. **写入背包数据**：`MaterialBagDao.upsert(accountId, materialId, gameId, count, ...)`
3. **删除账号时**：外键级联删除自动清理，无需手动处理

### 5.3 ViewModel 层处理

ViewModel 在初始化时：
1. 从 `BBSRepository.getActiveAccount()` 获取当前激活账号
2. 调用 `MaterialBagRepository.getMaterials(accountId, gameId)` 读取背包数据
3. 材料计算结果与背包数据合并，计算缺口

---

## 六、数据库迁移策略

### 6.1 版本规划

| 数据库版本 | App 版本 | 迁移内容 |
|-----------|---------|---------|
| v1 | ≤ 1.1.0 | 原始版本，16 张表（无 `material_bag`） |
| v2 | 2.0.0 | 新增 `material_bag` 表，Compute 表添加 `raw_json` 字段 |

### 6.2 迁移实现

**RdbManager.runMigrations()** 中实现：

```typescript
// v1 → v2 迁移
if (currentVersion < 2) {
  // 1. 创建 material_bag 表
  await rdbStore.executeSql(MATERIAL_BAG_TABLE.buildCreateSql());
  
  // 2. 为 Compute 表添加 raw_json 字段
  await rdbStore.executeSql('ALTER TABLE genshin_character_compute ADD COLUMN raw_json TEXT DEFAULT \'\'');
  await rdbStore.executeSql('ALTER TABLE starrail_avatar_compute ADD COLUMN raw_json TEXT DEFAULT \'\'');
  await rdbStore.executeSql('ALTER TABLE zzz_avatar_compute ADD COLUMN raw_json TEXT DEFAULT \'\'');
  
  // 3. 更新 user_version
  await rdbStore.executeSql('PRAGMA user_version = 2');
}
```

### 6.3 旧用户升级处理

| 场景 | 处理方式 |
|-----|---------|
| v1 用户升级到 v2.0.0 | 数据库迁移自动执行，新增 `material_bag` 表，现有数据不受影响 |
| Compute 表已有数据 | `raw_json` 字段默认为空字符串，下次同步时会填充 |
| 用户未使用过材料计算 | 无数据，功能首次使用时初始化 |

### 6.4 新用户安装处理

| 场景 | 处理方式 |
|-----|---------|
| 全新安装 v2.0.0 | 数据库初始化时直接创建 v2 版本，包含 `material_bag` 表 |
| 首次进入材料计算页面 | `material_bag` 表为空，用户手动输入材料数量 |
| 首次同步养成计算数据 | Compute 表写入，`raw_json` 字段填充完整响应 |

---

## 七、表结构详情

### 7.1 GenshinCharacterComputeRow

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | number | 自增主键 |
| account_id | string | 账号 UID |
| role_uid | string | 角色 UID |
| avatar_id | string | 角色ID |
| avatar_consume_json | string | 角色升级材料 JSON |
| skill_consume_json | string | 技能升级材料 JSON |
| weapon_consume_json | string | 武器升级材料 JSON |
| raw_json | string | 完整 API 响应 JSON |

### 7.2 StarRailAvatarComputeRow

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | number | 自增主键 |
| account_id | string | 账号 UID |
| role_uid | string | 角色 UID |
| avatar_id | string | 角色 ID |
| avatar_consume_json | string | 角色升级材料 JSON |
| skill_consume_json | string | 技能升级材料 JSON |
| equipment_consume_json | string | 光锥升级材料 JSON |
| raw_json | string | 完整 API 响应 JSON |

### 7.3 ZZZAvatarComputeRow

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | number | 自增主键 |
| account_id | string | 账号 UID |
| role_uid | string | 角色 UID |
| avatar_id | string | 角色 ID |
| avatar_consume_json | string | 角色升级材料 JSON |
| weapon_consume_json | string | 武器升级材料 JSON |
| skill_consume_json | string | 技能升级材料 JSON |
| raw_json | string | 完整 API 响应 JSON |

### 7.4 MaterialBagRow

| 字段 | 类型 | 说明 |
|-----|-----|-----|
| id | number | 自增主键 |
| account_id | string | 米游社账号 UID |
| material_id | string | 材料 ID（统一使用 string 类型，兼容星铁/绝区零） |
| material_name | string | 材料名称 |
| material_icon | string | 图标 URL |
| rarity | string | 稀有度（星铁/绝区零为 string：S/A/B/C；原神为 number：1-5，存储时统一转 string） |
| count | number | 拥有数量（**星铁/绝区零来自 API，原神为用户手动输入**） |
| source | string | 数据来源：`api`（API 返回）或 `manual`（手动输入） |
| game_id | string | 游戏标识（genshin/starrail/zzz） |
| update_time | number | 更新时间戳 |

---

## 八、API 请求策略

### 8.1 原神批量请求

```typescript
async function batchComputeGenshin(
  items: GenshinComputeItem[],
  region: string,
  uid: string,
  cookie: string
): Promise<GenshinComputeResult[]>
```

**批量策略**：
1. 按 8 个角色一组分批
2. 每批请求后立即写入缓存
3. 失败重试机制

### 8.2 星铁/绝区零单角色请求

```typescript
async function computeStarRail(
  avatarId: string,
  region: string,
  uid: string,
  cookie: string
): Promise<StarRailComputeResult>
```

---

## 九、入口设计

### 9.1 入口位置

材料计算功能有两个入口：

| 入口 | 位置 | 跳转页面 |
|------|------|---------|
| 工具 Tab | 底部导航新增 Tab | 工具页（包含 3 个游戏入口） |
| 角色详情页 | 内容区末尾「操作」区块 | 材料计算页（单个角色） |

### 9.2 工具 Tab 入口

> **设计决策**：在底部导航新增「工具」Tab，作为各种工具功能的统一入口。
>
> 当前工具：材料计算
> 未来可能扩展：签到、兑换码、其他便捷功能

在底部导航新增「工具」Tab，点击后显示工具页，包含 3 个游戏的材料总汇入口卡片：

```
┌─────────────────────────────────────────────────────┐
│ 工具                                                │  ← 标题栏
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ 🎮 原神材料总汇                            › │   │
│  │    12 个角色 · 已计算 8 个                  │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ 🚂 崩坏：星穹铁道材料总汇                  › │   │
│  │    15 个角色 · 已计算 12 个                 │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ 🌆 绝区零材料总汇                          › │   │
│  │    8 个代理人 · 已计算 5 个                 │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
├─────────────────────────────────────────────────────┤
│ 🏠 首页   👥 角色   🔧 工具   👤 我的              │  ← 底部导航
└─────────────────────────────────────────────────────┘
```

**关键设计点**：
1. **底部 Tab**：新增「工具」Tab，图标使用 `sys.symbol.wrench_and_screwdriver` 或类似图标
2. **工具页结构**：垂直排列 3 个游戏入口卡片
3. **卡片信息**：游戏名称 + 角色数量 + 计算进度
4. **点击跳转**：点击卡片跳转到对应游戏的材料汇总页

### 9.3 空态和无数据处理

**场景 1：无账号**
```
┌─────────────────────────────────────────────────────┐
│ 工具                                                │
├─────────────────────────────────────────────────────┤
│                                                     │
│              ┌───────────────────┐                  │
│              │       👤          │                  │
│              │                   │                  │
│              │   请先添加账号    │                  │
│              │                   │                  │
│              │  [去登录]         │                  │
│              └───────────────────┘                  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**场景 2：有账号但无某游戏角色**
```
┌─────────────────────────────────────────────────────┐
│ 🎮 原神材料总汇                                    │
│    暂无原神角色数据                                 │
│    请在角色页面同步数据后重试                        │
└─────────────────────────────────────────────────────┘
```
- 卡片置灰，显示「暂无角色数据」提示
- 点击不跳转，或弹出 Toast 提示

**场景 3：有角色但未计算**
```
┌─────────────────────────────────────────────────────┐
│ 🎮 原神材料总汇                                    │
│    12 个角色 · 未计算                               │
│    点击开始计算养成材料                              │
└─────────────────────────────────────────────────────┘
```
- 显示「未计算」状态
- 点击跳转到材料汇总页，自动触发计算

### 9.3 角色详情页入口

**复用现有角色详情页结构**（v1.0 已实现），在内容区域末尾新增「操作」区块，包含「材料计算」入口卡片：

```
┌──────────────────────────────────────┐
│ [立绘英雄区 + 命座列]                 │
│                                      │
│  甘雨  Lv.90  好感 10                │
├──────────────────────────────────────┤
│  技能                                │
│  ├─ 普攻：流天射术      Lv.10        │
│  ├─ 战技：山泽麟迹      Lv.10        │
│  └─ 爆发：降众天华      Lv.10        │
├──────────────────────────────────────┤
│  武器                                │
│  🏹 阿莫斯之弓  Lv.90 R1 五星         │
│     基础攻击力 542 · 攻击力 49.6%    │
├──────────────────────────────────────┤
│  属性                                │
│  ├─ 生命值      36086                │
│  ├─ 攻击力      1454                 │
│  ├─ 暴击率      18.6%                │
│  └─ 暴击伤害    176.0%               │
├──────────────────────────────────────┤
│  操作（新增区块）                     │
│  ┌──────────────────────────────────┐│
│  │ 📊 材料计算                    › ││
│  │    计算养成所需材料数量          ││
│  └──────────────────────────────────┘│
└──────────────────────────────────────┘
```

**关键设计点**：
1. **不修改现有角色详情页结构**：技能、武器、属性、圣遗物等区块保持不变
2. **新增「操作」区块**：放在属性区后面，包含材料计算入口卡片
3. **卡片样式统一**：使用现有的卡片样式（背景色、圆角、边框）
4. **点击跳转**：点击后跳转到材料计算页，自动选中当前角色

### 9.4 交互流程

```
用户操作流程：

1. 从工具 Tab 进入：
   底部导航「工具」Tab → 工具页 → 点击游戏卡片 → 材料汇总页（该游戏所有角色）→ 点击角色卡片 → 材料计算页（单个角色）

2. 从角色详情页进入：
   角色详情页 → 点击「材料计算」卡片 → 材料计算页（当前角色）
```

### 9.5 代码实现要点

**Main.ets 修改**：

```typescript
// 新增工具 Tab
const TAB_TOOLS = 3

// toolbarConfiguration 中新增
{
  value: $r('app.string.tools_tab_title'),
  symbolIcon: new SymbolGlyphModifier($r('sys.symbol.wrench_and_screwdriver'))
    .fontColor([this.tm.current.colorTextSecondary]),
  activeSymbolIcon: new SymbolGlyphModifier($r('sys.symbol.wrench_and_screwdriver'))
    .fontColor([this.tm.current.colorPrimary]),
  status: (this.selectedTab === TAB_TOOLS && this.tabVersion >= 0)
    ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
  action: () => { this.selectedTab = TAB_TOOLS; this.tabVersion++; if (this.isSplit) { this.stack.clear() } }
}
```

**Tools.ets 页面结构**：

```typescript
@ComponentV2
export struct Tools {
  @Local private vm: ToolsViewModel = new ToolsViewModel()
  
  build() {
    Column() {
      // 空态：无账号
      if (this.vm.accountCount === 0) {
        ToolsEmptyState()
      } else {
        // 有账号：显示游戏入口卡片
        ForEach(this.vm.gameEntries, (entry: GameEntryVM) => {
          GameEntryCard({ entry: entry, onTap: () => { this.onGameTap(entry.gameId) } })
        })
      }
    }
  }
}
```

**ToolsViewModel 数据结构**：

```typescript
export class GameEntryVM {
  gameId: GameId = GameId.GENSHIN
  gameName: ResourceStr = ''
  gameIcon: Resource = $r('app.media.logo_genshin')
  characterCount: number = 0    // 角色数量
  computedCount: number = 0     // 已计算数量
  hasData: boolean = false      // 是否有角色数据
}

@ObservedV2
export class ToolsViewModel {
  @Trace accountCount: number = 0
  @Trace gameEntries: GameEntryVM[] = []
  
  async loadData(): Promise<void> {
    // 读取账号数量
    // 读取各游戏角色数量和计算状态
  }
}
```

---

## 十、UI 设计

### 9.1 材料计算页（单个角色）

> **设计决策记录**：
> - 去掉角色切换按钮（单个角色不需要切换）
> - 去掉刷新按钮，改为下拉刷新
> - 等级目标移到角色信息区，显示为 `Lv.当前 → 目标`，可点击修改
> - 武器等级目标在武器材料 section 标题旁，可点击修改
> - 目标设置只保留技能（普攻、战技、爆发）
> - 材料分两个 section：角色材料 + 武器材料

**功能**：
1. 角色材料和武器材料分两个 Section 显示
2. 角色等级目标显示在角色信息卡，可点击修改
3. 武器等级目标显示在武器材料 section 标题旁，可点击修改
4. 技能目标（普攻/战技/爆发）单独设置
5. 下拉刷新（不用刷新按钮）
6. 显示材料收集进度
7. 显示缺失材料清单

**页面结构**：
```
┌──────────────────────────────────────┐
│ ← 返回    材料计算                   │  ← 只有返回按钮和标题
├──────────────────────────────────────┤
│  ┌──────────────────────────────────┐│
│  │ 👤 甘雨         ★★★★★            ││  ← 角色信息卡
│  │                 [Lv.80 → 90 ▼]   ││  ← 可点击的等级目标
│  └──────────────────────────────────┘│
├──────────────────────────────────────┤
│  技能目标                            │
│  ┌─────────┐┌─────────┐┌─────────┐   │
│  │ 普攻    ││ 战技    ││ 爆发    │   │
│  │ 10/10 ✓ ││ 10/10 ✓ ││ 10/10 ✓ │   │
│  └─────────┘└─────────┘└─────────┘   │
├──────────────────────────────────────┤
│  👤 角色材料            72%  缺少 34 │
│  ┌──────────────────────────────────┐│
│  │💎 哀叙冰玉      12/46   -34     ││
│  │❄️ 极寒之核       8/46   -38     ││
│  │🌸 清心          68/168  -100     ││
│  └──────────────────────────────────┘│
├──────────────────────────────────────┤
│  ⚔️ 武器材料 · 阿莫斯之弓            │
│                [Lv.80→90 ▼]  缺少 15 │
│  ┌──────────────────────────────────┐│
│  │⭐ 孤云寒冰的神瞳  3/6    -3     ││
│  │🔨 北陆弓原胚      1/1    ✓      ││
│  │💎 水晶块       156/50   ✓       ││
│  └──────────────────────────────────┘│
├──────────────────────────────────────┤
│         ↓ 下拉刷新材料数据           │
└──────────────────────────────────────┘
```

**关键设计点**：
1. **角色信息卡**：显示角色头像、名称、稀有度，右侧是可点击的等级目标按钮
2. **技能目标**：三个技能卡片（普攻/战技/爆发），显示当前/目标等级，满级显示 ✓
3. **角色材料 Section**：标题包含进度百分比和缺口数量，材料列表显示拥有/需求和缺口
4. **武器材料 Section**：标题包含武器名称和可点击的等级目标按钮，材料列表格式同角色材料
5. **下拉刷新**：页面底部提示下拉刷新，不使用刷新按钮

### 9.2 材料汇总列表页

**功能**：
1. 显示所有角色+武器的材料汇总
2. 支持按游戏筛选（原神/星铁/绝区零）
3. 两种视图模式：
   - **按角色分组**：显示每个角色+武器的缺失材料，可展开/收起
   - **按材料汇总**：紧凑网格布局，只显示材料图标+右下角缺口数量角标

**视图切换**：
```
┌──────────────────────────────────────┐
│ ← 返回    材料汇总                   │
├──────────────────────────────────────┤
│  [原神] [星铁] [绝区零]               │  ← 游戏 Tab
├──────────────────────────────────────┤
│  [按角色] [按材料]                    │  ← 视图切换
├──────────────────────────────────────┤
│  视图内容区                           │
│  （按角色：角色卡片列表）              │
│  （按材料：紧凑网格）                  │
└──────────────────────────────────────┘
```

**按角色视图**：
```
┌──────────────────────────────────────┐
│ ▼ 纳西妲 (Lv.90) + 千叶浮屠 (Lv.90)  │
│   💎 哀叙冰玉 ×46 (-34)              │
│   💎 生长碧翡 ×12 (-8)               │
│   ...                                │
├──────────────────────────────────────┤
│ ▶ 钟离 (Lv.90) + 护摩之杖 (Lv.90)    │
├──────────────────────────────────────┤
│ ▶ 夜兰 (Lv.90) + 若水 (Lv.90)        │
└──────────────────────────────────────┘
```

**按材料视图**：
```
┌──────────────────────────────────────┐
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐  │
│ │ 💎 │ │ 💎 │ │ 💎 │ │ 💎 │ │ 💎 │  │
│ │    │ │    │ │    │ │    │ │    │  │
│ │   ││ │   ││ │   ││ │   ││ │   ││  │
│ │  34│ │   8│ │  12│ │   5│ │   3│  │
│ └────┘ └────┘ └────┘ └────┘ └────┘  │
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐  │
│ │ 💎 │ │ 💎 │ │ 💎 │ │ 💎 │ │ 💎 │  │
│ │    │ │    │ │    │ │    │ │    │  │
│ │   ││ │   ││ │   ││ │   ││ │   ││  │
│ │  28│ │  15│ │   9│ │   6│ │   2│  │
│ └────┘ └────┘ └────┘ └────┘ └────┘  │
└──────────────────────────────────────┘
  每个材料 64x64px，右下角红色角标显示缺口数量
```

---

## 十、实现计划

### Phase 1：数据库层
- [x] 新增 `material_bag` 表
- [x] 为 Compute 表添加 `raw_json` 字段
- [x] 实现 `MaterialBagDao`
- [x] 实现 `MaterialBagRow` 模型
- [x] 实现数据库迁移 v1→v2

### Phase 2：API 层
- [x] `GenshinApiService.batchCompute()` 已存在
- [ ] 实现 `StarRailComputeService`
- [ ] 实现 `ZZZComputeService`
- [ ] 实现 Mock Service

### Phase 3：Repository 层
- [x] 扩展 `GenshinRepository`（添加 `syncAvatarCompute` 方法）
- [ ] 实现 `MaterialBagRepository`
- [ ] 扩展 `StarRailRepository`
- [ ] 扩展 `ZZZRepository`

### Phase 4：UI 层
- [ ] 实现 `MaterialCalcViewModel`
- [ ] 实现 `MaterialListViewModel`
- [ ] 实现材料计算页面
- [ ] 实现材料汇总页面
- [ ] 实现技能等级 Picker

### Phase 5：原型设计
- [x] 创建原型框架（参考 v1.0）
- [x] 实现材料计算原型 `material-calc.js`
- [x] 实现材料汇总原型 `material-list.js`（含两种视图模式）

### Phase 6：测试
- [ ] 数据库层测试
- [ ] API 层测试
- [ ] UI 测试

---

## 十一、文件索引

### 核心模块（core）

| 文件路径 | 说明 |
|---------|-----|
| `core/src/main/ets/database/TableSchema.ets` | 表结构定义 |
| `core/src/main/ets/database/RdbManager.ets` | 数据库管理（含迁移逻辑） |
| `core/src/main/ets/database/MaterialBagDao.ets` | 材料背包 DAO |
| `core/src/main/ets/models/MaterialBagRow.ets` | 材料背包 Row 模型 |
| `core/src/main/ets/repository/MaterialBagRepository.ets` | 材料背包 Repository |

### 入口模块（entry）

| 文件路径 | 说明 |
|---------|-----|
| `entry/src/main/ets/pages/Tools.ets` | 工具页（材料总汇入口） |
| `entry/src/main/ets/pages/MaterialCalc.ets` | 材料计算页 |
| `entry/src/main/ets/pages/MaterialList.ets` | 材料汇总页 |
| `entry/src/main/ets/viewmodel/ToolsViewModel.ets` | 工具页 ViewModel |
| `entry/src/main/ets/viewmodel/MaterialCalcViewModel.ets` | 材料计算 ViewModel |
| `entry/src/main/ets/viewmodel/MaterialListViewModel.ets` | 材料汇总 ViewModel |

### 原型文件

| 文件路径 | 说明 |
|---------|-----|
| `design/prototypes/v2.0/viewer/index.html` | 原型入口 |
| `design/prototypes/v2.0/viewer/pages/tools.js` | 工具页原型 |
| `design/prototypes/v2.0/viewer/pages/material-calc.js` | 材料计算原型 |
| `design/prototypes/v2.0/viewer/pages/material-list-data.js` | 材料汇总数据 |
| `design/prototypes/v2.0/viewer/pages/material-list-utils.js` | 材料汇总工具函数 |
| `design/prototypes/v2.0/viewer/pages/material-list-render.js` | 材料汇总渲染逻辑 |
| `design/prototypes/v2.0/viewer/pages/material-list-card.js` | 材料汇总卡片组件 |
| `design/prototypes/v2.0/viewer/pages/material-list-controls.js` | 材料汇总控制项 |
