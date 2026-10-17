# 材料计算功能 v2.0.0 - 设计文档

## 一、架构设计

### 1.1 模块依赖关系

```
entry (UI 层)
  ├── pages/
  │   ├── Tools.ets              ← 工具页
  │   ├── MaterialList.ets       ← 材料汇总页
  │   └── MaterialCalc.ets       ← 材料计算页
  ├── viewmodel/
  │   ├── ToolsViewModel.ets
  │   ├── MaterialListViewModel.ets
  │   └── MaterialCalcViewModel.ets
  ├── models/
  │   ├── ToolsModels.ets        ← GameEntryVM 等
  │   ├── MaterialListModels.ets ← MaterialSummaryVM 等
  │   └── MaterialCalcModels.ets ← MaterialItemVM 等
  └── components/
      ├── tools/
      ├── material-list/
      └── material-calc/

core (数据层)
  ├── database/
  │   ├── MaterialBagDao.ets     ← 新增
  │   └── TableSchema.ets        ← 修改：新增 material_bag 表
  ├── models/
  │   └── MaterialBagRow.ets     ← 新增
  ├── repository/
  │   ├── MaterialBagRepository.ets  ← 新增
  │   ├── GenshinRepository.ets      ← 扩展：添加 syncAvatarCompute
  │   ├── StarRailRepository.ets     ← 扩展
  │   └── ZZZRepository.ets          ← 扩展
  └── network/
      ├── GenshinComputeService.ets  ← 新增
      ├── StarRailComputeService.ets ← 新增
      └── ZZZComputeService.ets      ← 新增
```

### 1.2 数据流设计

```
用户操作
    ↓
ViewModel
    ↓
Repository.syncXxxCompute()  ← 调用 API 并写入 DB
    ↓
ApiService.batchCompute() / compute()
    ↓
Parser.parse()  ← 解析 API 响应
    ↓
Dao.upsert()    ← 写入 Compute 表
    ↓
MaterialBagDao.upsert()  ← 写入背包数据（星铁/绝区零）
    ↓
ViewModel.loadMaterials()  ← 读取汇总数据
    ↓
UI 渲染
```

---

## 二、数据库设计

### 2.1 表结构定义

#### material_bag 表

```sql
CREATE TABLE IF NOT EXISTS material_bag (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id TEXT NOT NULL,
  material_id TEXT NOT NULL,
  material_name TEXT NOT NULL,
  material_icon TEXT,
  rarity TEXT DEFAULT '',
  count INTEGER DEFAULT 0,
  source TEXT DEFAULT 'api',
  game_id TEXT NOT NULL,
  update_time INTEGER DEFAULT 0,
  UNIQUE(account_id, material_id, game_id),
  FOREIGN KEY (account_id) REFERENCES account_table(uid) ON DELETE CASCADE
)
```

#### 修改现有 Compute 表

```sql
ALTER TABLE genshin_character_compute ADD COLUMN raw_json TEXT DEFAULT '';
ALTER TABLE starrail_avatar_compute ADD COLUMN raw_json TEXT DEFAULT '';
ALTER TABLE zzz_avatar_compute ADD COLUMN raw_json TEXT DEFAULT '';
```

### 2.2 数据库迁移

**版本规划**：
- v1：现有 16 张表（≤ 1.1.0）
- v2：新增 `material_bag` 表，Compute 表添加 `raw_json` 字段（2.0.0）

**迁移实现**（RdbManager.runMigrations）：

```typescript
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

---

## 三、API 设计

### 3.1 GenshinComputeService

```typescript
export interface GenshinComputeItem {
  avatar_id: number;
  avatar_level_current: number;
  avatar_level_target: number;
  element_attr_id: number;
  skill_list: GenshinSkillItem[];
  weapon?: GenshinWeaponItem;
  from_user_sync: boolean;
}

export interface GenshinComputeResult {
  avatar_consume: GenshinMaterialConsume[];
  skill_consume: GenshinMaterialConsume[];
  weapon_consume?: GenshinMaterialConsume[];
  overall_consume?: GenshinMaterialConsume[];
}

export class GenshinComputeService extends MihoyoApiService {
  async batchCompute(
    items: GenshinComputeItem[],
    region: string,
    uid: string
  ): Promise<GenshinComputeResult[]>;
}
```

### 3.2 StarRailComputeService

```typescript
export interface StarRailComputeResult {
  avatar_consume: StarRailMaterialConsume[];
  skill_consume: StarRailMaterialConsume[];
  equipment_consume: StarRailMaterialConsume[];
  user_owns_materials: Record<string, number>;
}

export class StarRailComputeService extends MihoyoApiService {
  async compute(
    avatarId: string,
    avatarLevel: { cur_level: number; target_level: number },
    skillList: StarRailSkillItem[],
    region: string,
    uid: string
  ): Promise<StarRailComputeResult>;
}
```

### 3.3 ZZZComputeService

```typescript
export interface ZZZComputeResult {
  avatar_consume: ZZZMaterialConsume[];
  skill_consume: ZZZMaterialConsume[];
  weapon_consume?: ZZZMaterialConsume[];
  user_owns_materials: Record<string, number>;
}

export class ZZZComputeService extends MihoyoApiService {
  async compute(
    avatarId: number,
    avatarLevel: { current: number; target: number },
    skills: ZZZSkillItem[],
    region: string,
    uid: string
  ): Promise<ZZZComputeResult>;
}
```

---

## 四、Repository 层设计

### 4.1 MaterialBagRepository

```typescript
export class MaterialBagRepository {
  /**
   * 批量写入材料背包数据
   * 星铁/绝区零：从 API 的 user_owns_materials 写入
   * 原神：从 lack_num 反推后写入（source='computed'）
   */
  async upsertMaterials(
    accountId: string,
    gameId: GameId,
    materials: MaterialBagRow[]
  ): Promise<void>;

  /**
   * 读取某账号某游戏的背包数据
   */
  async getMaterials(
    accountId: string,
    gameId: GameId
  ): Promise<MaterialBagRow[]>;

  /**
   * 获取单个材料的拥有数量
   */
  async getMaterialCount(
    accountId: string,
    gameId: GameId,
    materialId: string
  ): Promise<number>;
}
```

### 4.2 扩展现有 Repository

```typescript
// GenshinRepository 新增方法
export class GenshinRepository {
  /**
   * 同步角色养成计算数据
   * @param items 最多 8 个角色的计算参数
   */
  async syncAvatarCompute(
    accountId: string,
    roleUid: string,
    items: GenshinComputeItem[],
    server: string,
    cookie: string
  ): Promise<GenshinCharacterComputeRow[]>;

  /**
   * 读取所有角色的计算数据
   */
  async getAllComputeData(
    accountId: string,
    roleUid: string
  ): Promise<GenshinCharacterComputeRow[]>;
}
```

---

## 五、ViewModel 设计

### 5.1 ToolsViewModel

```typescript
export class GameEntryVM {
  gameId: GameId = GameId.GENSHIN;
  gameName: ResourceStr = '';
  gameIcon: Resource = $r('app.media.logo_genshin');
  characterCount: number = 0;
  computedCount: number = 0;
  hasData: boolean = false;
}

@ObservedV2
export class ToolsViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace accountCount: number = 0;
  @Trace gameEntries: GameEntryVM[] = [];

  async loadData(): Promise<void>;
}
```

### 5.2 MaterialListViewModel

```typescript
export class CharacterMaterialVM {
  characterId: string = '';
  characterName: string = '';
  characterIcon: string = '';
  weaponName: string = '';
  weaponIcon: string = '';
  materials: MaterialItemVM[] = [];
  totalProgress: number = 0;
  totalDeficit: number = 0;
}

export class MaterialSummaryVM {
  materialId: string = '';
  materialName: string = '';
  materialIcon: string = '';
  rarity: string = '';
  totalCount: number = 0;
  haveCount: number = 0;
  deficitCount: number = 0;
}

@ObservedV2
export class MaterialListViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace viewMode: 'character' | 'material' = 'character';
  @Trace characters: CharacterMaterialVM[] = [];
  @Trace materials: MaterialSummaryVM[] = [];
  @Trace overallProgress: number = 0;
  @Trace overallDeficit: number = 0;

  async loadData(accountId: string, gameId: GameId): Promise<void>;
  toggleViewMode(): void;
  async refresh(): Promise<void>;
}
```

### 5.3 MaterialCalcViewModel

```typescript
export class SkillTargetVM {
  id: string = '';
  label: ResourceStr = '';
  current: number = 1;
  target: number = 10;
  max: number = 10;
}

export class MaterialCalcViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
  
  // 角色信息
  @Trace characterName: string = '';
  @Trace characterIcon: string = '';
  @Trace characterRarity: number = 5;
  @Trace charCurrentLevel: number = 1;
  @Trace charTargetLevel: number = 90;
  
  // 武器信息
  @Trace weaponName: string = '';
  @Trace weaponIcon: string = '';
  @Trace weaponRarity: number = 5;
  @Trace weaponCurrentLevel: number = 1;
  @Trace weaponTargetLevel: number = 90;
  
  // 技能目标
  @Trace skills: SkillTargetVM[] = [];
  
  // 材料列表
  @Trace avatarMaterials: MaterialItemVM[] = [];
  @Trace weaponMaterials: MaterialItemVM[] = [];
  @Trace avatarProgress: number = 0;
  @Trace avatarDeficit: number = 0;
  @Trace weaponProgress: number = 0;
  @Trace weaponDeficit: number = 0;
  
  // 等级选择器状态
  @Trace showLevelPicker: boolean = false;
  @Trace levelPickerTarget: 'character' | 'weapon' = 'character';

  async init(accountId: string, roleUid: string, avatarId: string): Promise<void>;
  async setCharTargetLevel(level: number): Promise<void>;
  async setWeaponTargetLevel(level: number): Promise<void>;
  async setSkillTarget(skillId: string, level: number): Promise<void>;
  async refresh(): Promise<void>;
}
```

---

## 六、UI 组件设计

### 6.1 工具页组件

```
Tools.ets
├── ToolsEmptyState.ets      ← 无账号空态
└── GameEntryCard.ets        ← 游戏入口卡片
```

### 6.2 材料汇总页组件

```
MaterialList.ets
├── MaterialListHeader.ets       ← 标题栏 + 视图切换
├── MaterialListProgress.ets     ← 总进度条
├── CharacterMaterialCard.ets    ← 按角色视图：角色卡片
│   ├── CharacterMaterialHeader.ets
│   └── CharacterMaterialContent.ets
└── MaterialGridCard.ets         ← 按材料视图：材料网格卡片
```

### 6.3 材料计算页组件

```
MaterialCalc.ets
├── MaterialCalcHeader.ets       ← 标题栏（返回按钮 + 标题）
├── MaterialCalcCharacter.ets    ← 角色信息卡（含等级目标按钮）
├── MaterialCalcSkills.ets       ← 技能目标设置
├── MaterialCalcSection.ets      ← 材料 Section（角色/武器）
│   └── MaterialCalcItem.ets     ← 材料列表项
└── LevelPicker.ets              ← 等级选择器弹窗
```

---

## 七、测试策略

### 7.1 单元测试（core/src/test/）

| 测试文件 | 测试内容 |
|---------|---------|
| `MaterialBagDao.test.ets` | CRUD 操作、唯一键约束 |
| `GenshinComputeParser.test.ets` | API 响应解析 |
| `StarRailComputeParser.test.ets` | API 响应解析、user_owns_materials |
| `ZZZComputeParser.test.ets` | API 响应解析、user_owns_materials |
| `MaterialBagRepository.test.ets` | 数据读写逻辑 |

### 7.2 ViewModel 单元测试（entry/src/test/）

| 测试文件 | 测试内容 |
|---------|---------|
| `ToolsViewModel.test.ets` | 初始状态、账号数量、游戏入口数据 |
| `MaterialListViewModel.test.ets` | 视图切换、数据加载 |
| `MaterialCalcViewModel.test.ets` | 等级目标修改、技能目标修改 |

### 7.3 设备端测试（entry/src/ohosTest/）

| 测试文件 | 测试内容 |
|---------|---------|
| `ToolsPageTest.test.ets` | 空态显示、卡片点击跳转 |
| `MaterialListPageTest.test.ets` | 视图切换、下拉刷新 |
| `MaterialCalcPageTest.test.ets` | 等级选择器、材料列表显示 |
| `MaterialBagDao.test.ets` | 真实 RDB 操作 |

### 7.4 组件 @Preview

每个 `@ComponentV2` 组件文件末尾必须有 `@Preview`：

- `GameEntryCard.ets` → `GameEntryCardPreview`
- `MaterialCalcCharacter.ets` → `MaterialCalcCharacterPreview`
- `MaterialCalcSkills.ets` → `MaterialCalcSkillsPreview`
- `MaterialCalcSection.ets` → `MaterialCalcSectionPreview`
- `MaterialCalcItem.ets` → `MaterialCalcItemPreview`
- `LevelPicker.ets` → `LevelPickerPreview`

---

## 八、路由设计

### 8.1 新增路由

| 路由 path | 页面 | Builder |
|----------|------|---------|
| `/tools` | Tools.ets | ToolsBuilder |
| `/material-list` | MaterialList.ets | MaterialListBuilder |
| `/material-calc` | MaterialCalc.ets | MaterialCalcBuilder |

### 8.2 路由参数

```typescript
// MaterialList 跳转参数
interface MaterialListParam {
  accountId: string;
  gameId: GameId;
}

// MaterialCalc 跳转参数
interface MaterialCalcParam {
  accountId: string;
  roleUid: string;
  avatarId: string;
  gameId: GameId;
}
```

---

## 九、多语言支持

### 9.1 新增字符串资源

| key | 简体中文 | 繁体中文 | 英文 |
|-----|---------|---------|------|
| `tools_tab_title` | 工具 | 工具 | Tools |
| `tools_empty_title` | 请先添加账号 | 請先添加賬號 | Add Account First |
| `tools_empty_button` | 去登录 | 去登錄 | Login |
| `tools_game_no_data` | 暂无角色数据 | 暫無角色數據 | No Character Data |
| `material_list_view_character` | 按角色 | 按角色 | By Character |
| `material_list_view_material` | 按材料 | 按材料 | By Material |
| `material_list_progress` | 收集进度 | 收集進度 | Progress |
| `material_list_deficit` | 缺少 %d 个 | 缺少 %d 個 | Missing %d |
| `material_calc_skill_target` | 技能目标 | 技能目標 | Skill Target |
| `material_calc_avatar_materials` | 角色材料 | 角色材料 | Character Materials |
| `material_calc_weapon_materials` | 武器材料 | 武器材料 | Weapon Materials |
| `material_calc_pull_refresh` | 下拉刷新材料数据 | 下拉刷新材料數據 | Pull to Refresh |
| `level_picker_title` | 选择目标等级 | 選擇目標等級 | Select Target Level |

---

## 十、文件索引

### 10.1 core 模块新增文件

| 文件路径 | 说明 |
|---------|-----|
| `core/src/main/ets/database/MaterialBagDao.ets` | 材料背包 DAO |
| `core/src/main/ets/models/MaterialBagRow.ets` | 材料背包 Row 模型 |
| `core/src/main/ets/repository/MaterialBagRepository.ets` | 材料背包 Repository |
| `core/src/main/ets/network/GenshinComputeService.ets` | 原神计算 Service |
| `core/src/main/ets/network/StarRailComputeService.ets` | 星铁计算 Service |
| `core/src/main/ets/network/ZZZComputeService.ets` | 绝区零计算 Service |
| `core/src/main/ets/parsers/GenshinComputeParser.ets` | 原神计算 Parser |
| `core/src/main/ets/parsers/StarRailComputeParser.ets` | 星铁计算 Parser |
| `core/src/main/ets/parsers/ZZZComputeParser.ets` | 绝区零计算 Parser |

### 10.2 entry 模块新增文件

| 文件路径 | 说明 |
|---------|-----|
| `entry/src/main/ets/pages/Tools.ets` | 工具页 |
| `entry/src/main/ets/pages/MaterialList.ets` | 材料汇总页 |
| `entry/src/main/ets/pages/MaterialCalc.ets` | 材料计算页 |
| `entry/src/main/ets/viewmodel/ToolsViewModel.ets` | 工具页 ViewModel |
| `entry/src/main/ets/viewmodel/MaterialListViewModel.ets` | 材料汇总 ViewModel |
| `entry/src/main/ets/viewmodel/MaterialCalcViewModel.ets` | 材料计算 ViewModel |
| `entry/src/main/ets/models/ToolsModels.ets` | 工具页 Model |
| `entry/src/main/ets/models/MaterialListModels.ets` | 材料汇总 Model |
| `entry/src/main/ets/models/MaterialCalcModels.ets` | 材料计算 Model |
| `entry/src/main/ets/components/tools/GameEntryCard.ets` | 游戏入口卡片 |
| `entry/src/main/ets/components/tools/ToolsEmptyState.ets` | 空态组件 |
| `entry/src/main/ets/components/material-list/MaterialListHeader.ets` | 材料汇总标题 |
| `entry/src/main/ets/components/material-list/CharacterMaterialCard.ets` | 角色材料卡片 |
| `entry/src/main/ets/components/material-list/MaterialGridCard.ets` | 材料网格卡片 |
| `entry/src/main/ets/components/material-calc/MaterialCalcCharacter.ets` | 角色信息卡 |
| `entry/src/main/ets/components/material-calc/MaterialCalcSkills.ets` | 技能目标 |
| `entry/src/main/ets/components/material-calc/MaterialCalcSection.ets` | 材料 Section |
| `entry/src/main/ets/components/material-calc/MaterialCalcItem.ets` | 材料列表项 |
| `entry/src/main/ets/components/material-calc/LevelPicker.ets` | 等级选择器 |
