# 材料计算功能 v2.0.0 - 任务清单

## Phase 1：数据库层（core）✅

### 1.1 表结构扩展

- [x] **TASK-001**：修改 `TableSchema.ets`，新增 `material_bag` 表定义
- [x] **TASK-002**：新增 `MaterialBagCol` 枚举，定义列名
- [x] **TASK-003**：修改 `RdbManager.runMigrations()`，实现 v2→v3 迁移
  - 创建 `material_bag` 表（使用正确的字段类型：material_id TEXT, rarity TEXT, source TEXT）
  - 为三张 Compute 表添加 `raw_json` 字段
  - 更新 `user_version` 为 3

### 1.2 Model 层

- [x] **TASK-004**：修改 `MaterialBagRow.ets`，更新字段类型
  - `materialId: string`
  - `rarity: string`
  - 新增 `source: string`
- [x] **TASK-005**：三张 Compute Row 模型已有 `rawJson` 字段

### 1.3 DAO 层

- [x] **TASK-006**：修改 `MaterialBagDao.ets`，更新所有方法
  - `upsertAll()` — 批量写入（含 source 字段）
  - `findOne()` — 查询单个材料（materialId: string）
  - `findByAccountAndGame()` — 按账号和游戏查询
  - `deleteByAccountAndGame()` — 删除指定账号游戏数据
  - `updateCount()` — 更新材料数量（materialId: string）

### 1.4 数据库层测试

- [ ] **TASK-007**：新增 `MaterialBagDao.test.ets`（core/src/ohosTest/）
  - 测试 upsert 写入和更新
  - 测试唯一键约束
  - 测试外键级联删除
  - 测试批量写入

---

## Phase 2：API 层（core）

### 2.1 Service 层

- [x] **TASK-008**：`GenshinApiService.batchCompute()` 已存在
- [x] **TASK-009**：`StarRailApiService.compute()` 已存在
- [x] **TASK-010**：`ZZZApiService.compute()` 已存在

### 2.2 Parser 层

- [x] **TASK-011**：新增 `GenshinComputeParser.ets`
  - 解析 `avatar_consume`、`skill_consume`、`weapon_consume`
  - 解析 `skills_consume`（含技能 ID 和等级信息）
  - 容错处理（字段缺失、类型错误）
- [x] **TASK-012**：新增 `StarRailComputeParser.ets`
  - 解析 `avatar_consume`、`skill_consume`、`equipment_consume`
  - 解析 `user_owns_materials`
- [x] **TASK-013**：新增 `ZZZComputeParser.ets`
  - 解析 `avatar_consume`、`skill_consume`、`weapon_consume`
  - 解析 `user_owns_materials`

### 2.3 Mock Service

- [x] **TASK-014**：`GenshinMockService.batchCompute()` 已存在
- [x] **TASK-015**：`StarRailMockService.compute()` 已存在
- [x] **TASK-016**：`ZZZMockService.compute()` 已存在

### 2.4 API 层测试

- [ ] **TASK-017**：新增 `GenshinComputeParser.test.ets`（core/src/test/）
- [ ] **TASK-018**：新增 `StarRailComputeParser.test.ets`（core/src/test/）
- [ ] **TASK-019**：新增 `ZZZComputeParser.test.ets`（core/src/test/）

---

## Phase 3：Repository 层（core）

### 3.1 MaterialBagRepository

- [x] **TASK-020**：新增 `MaterialBagRepository.ets`
  - `upsertMaterials()` — 批量写入背包数据
  - `getMaterials()` — 读取背包数据
  - `getMaterialCount()` — 获取单个材料数量

### 3.2 扩展现有 Repository

- [x] **TASK-021**：扩展 `GenshinRepository.ets`
  - 新增 `syncAvatarCompute()` 方法
  - 新增 `getAllComputeData()` 方法
- [x] **TASK-022**：扩展 `StarRailRepository.ets`
  - 新增 `syncAvatarCompute()` 方法
- [x] **TASK-023**：扩展 `ZZZRepository.ets`
  - 新增 `syncAvatarCompute()` 方法

### 3.3 Repository 层测试

- [ ] **TASK-024**：新增 `MaterialBagRepository.test.ets`（core/src/ohosTest/）

---

## Phase 4：Entry 层 Model 和 ViewModel ✅

### 4.1 Models

- [x] **TASK-025**：新增 `ToolsModels.ets`
  - `GameEntryVM` — 游戏入口 UI State
- [x] **TASK-026**：新增 `MaterialListModels.ets`
  - `CharacterMaterialVM` — 角色材料 UI State
  - `MaterialSummaryVM` — 材料汇总 UI State
  - `MaterialItemVM` — 单个材料 UI State
- [x] **TASK-027**：新增 `MaterialCalcModels.ets`
  - `SkillTargetVM` — 技能目标 UI State

### 4.2 ViewModel

- [x] **TASK-028**：新增 `ToolsViewModel.ets`
  - `loadData()` — 加载账号和游戏入口数据
  - `viewState`、`accountCount`、`gameEntries` 状态
- [x] **TASK-029**：新增 `MaterialListViewModel.ets`
  - `loadData()` — 加载材料汇总数据
  - `toggleViewMode()` — 切换视图模式
  - `refresh()` — 下拉刷新
- [x] **TASK-030**：新增 `MaterialCalcViewModel.ets`
  - `init()` — 初始化角色数据
  - `setCharTargetLevel()` — 设置角色目标等级
  - `setWeaponTargetLevel()` — 设置武器目标等级
  - `setSkillTarget()` — 设置技能目标等级
  - `refresh()` — 刷新数据

### 4.3 ViewModel 单元测试

- [ ] **TASK-031**：新增 `ToolsViewModel.test.ets`（entry/src/test/）
  - 初始状态验证
  - 账号数量验证
- [ ] **TASK-032**：新增 `MaterialListViewModel.test.ets`（entry/src/test/）
  - 初始状态验证
  - 视图切换逻辑
- [ ] **TASK-033**：新增 `MaterialCalcViewModel.test.ets`（entry/src/test/）
  - 初始状态验证
  - 等级目标修改逻辑

---

## Phase 5：UI 组件和页面 ✅

### 5.1 工具页

- [x] **TASK-034**：新增 `components/tools/ToolsEmptyState.ets`
  - 无账号空态组件
  - 添加 @Preview
- [x] **TASK-035**：新增 `components/tools/GameEntryCard.ets`
  - 游戏入口卡片
  - 添加 @Preview
- [x] **TASK-036**：新增 `pages/Tools.ets`
  - 工具页主页面
  - 添加 @Preview

### 5.2 材料汇总页

- [x] **TASK-037**：新增 `components/material-list/MaterialListHeader.ets`
  - 标题栏 + 视图切换按钮
  - 添加 @Preview
- [x] **TASK-038**：新增 `components/material-list/CharacterMaterialCard.ets`
  - 角色材料卡片（按角色视图）
  - 添加 @Preview
- [x] **TASK-039**：新增 `components/material-list/MaterialGridCard.ets`
  - 材料网格卡片（按材料视图）
  - 添加 @Preview
- [x] **TASK-040**：新增 `pages/MaterialList.ets`
  - 材料汇总页主页面
  - 添加 @Preview

### 5.3 材料计算页

- [x] **TASK-041**：新增 `components/material-calc/MaterialCalcCharacter.ets`
  - 角色信息卡（含等级目标按钮）
  - 添加 @Preview
- [x] **TASK-042**：新增 `components/material-calc/MaterialCalcSkills.ets`
  - 技能目标设置区
  - 添加 @Preview
- [x] **TASK-043**：新增 `components/material-calc/MaterialCalcSection.ets`
  - 材料 Section（角色/武器）
  - 添加 @Preview
- [x] **TASK-044**：新增 `components/material-calc/MaterialCalcItem.ets`
  - 材料列表项
  - 添加 @Preview
- [x] **TASK-045**：新增 `components/material-calc/LevelPicker.ets`
  - 等级选择器弹窗
  - 添加 @Preview
- [x] **TASK-046**：新增 `pages/MaterialCalc.ets`
  - 材料计算页主页面
  - 添加 @Preview

### 5.4 角色详情页入口

- [x] **TASK-047**：修改 `GenshinCharacterDetail.ets`
  - 在内容区末尾新增「操作」区块
  - 添加「材料计算」入口卡片
  - 实现跳转逻辑（携带 accountId、roleUid、avatarId）

---

## Phase 6：路由和导航 ✅

### 6.1 路由配置

- [x] **TASK-048**：修改 `AppRoutes.ets`，新增路由常量
  - `TOOLS = 'Tools'`（Tab 内嵌页）
  - `MATERIAL_LIST = 'MaterialList'`
  - `MATERIAL_CALC = 'MaterialCalc'`

### 6.2 Builder 注册

- [x] **TASK-049**：`ToolsBuilder.ets` 不需要（Tab 内嵌页）
- [x] **TASK-050**：新增 `MaterialListBuilder.ets`
- [x] **TASK-051**：新增 `MaterialCalcBuilder.ets`
- [x] **TASK-052**：修改 `custom_router_map.json`，注册新路由

### 6.3 Main 页面修改

- [x] **TASK-053**：修改 `Main.ets`
  - 底部导航新增「工具」Tab
  - `toolbarConfiguration` 新增 Tab 配置

---

## Phase 7：多语言支持 ✅

### 7.1 字符串资源

- [x] **TASK-054**：修改 `entry/src/main/resources/base/element/string.json`
  - 新增工具页相关字符串
  - 新增材料汇总页相关字符串
  - 新增材料计算页相关字符串
- [x] **TASK-055**：修改 `entry/src/main/resources/zh_HK/element/string.json`
  - 同步繁体中文翻译
- [x] **TASK-056**：修改 `entry/src/main/resources/en/element/string.json`
  - 同步英文翻译

---

## Phase 8：测试补充 ✅

### 8.1 设备端 UI 测试

- [x] **TASK-057**：新增 `ToolsPageTest.test.ets`（entry/src/ohosTest/）
  - 空态显示测试
  - 游戏卡片点击跳转测试
- [x] **TASK-058**：新增 `MaterialListPageTest.test.ets`（entry/src/ohosTest/）
  - 视图切换测试
  - 下拉刷新测试
- [x] **TASK-059**：新增 `MaterialCalcPageTest.test.ets`（entry/src/ohosTest/）
  - 等级选择器测试
  - 材料列表显示测试

### 8.2 测试入口文件

- [x] **TASK-060**：修改 `core/src/test/List.test.ets`，注册新测试
- [x] **TASK-061**：修改 `core/src/ohosTest/ets/test/List.test.ets`，注册新测试
- [x] **TASK-062**：修改 `entry/src/test/List.test.ets`，注册新测试
- [x] **TASK-063**：修改 `entry/src/ohosTest/ets/test/List.test.ets`，注册新测试

---

## Phase 9：Mock 数据 ✅

### 9.1 Mock 文件准备

- [x] **TASK-064**：准备原神计算 Mock 数据
  - `mock/{account_id}/{role_uid}/genshin_character_batch_compute.json`
  - 以及 `genshin_character_batch_compute1.json`、`2.json`、`3.json`
- [x] **TASK-065**：准备星铁计算 Mock 数据
  - `mock/{account_id}/{role_uid}/hkrpg_character_compute.json`
- [x] **TASK-066**：准备绝区零计算 Mock 数据
  - `mock/{account_id}/{role_uid}/zzz_character_compute.json`

---

## 任务依赖关系

```
Phase 1 (数据库) ──→ Phase 2 (API) ──→ Phase 3 (Repository)
                                              ↓
                                      Phase 4 (ViewModel)
                                              ↓
                                      Phase 5 (UI 页面)
                                              ↓
                                      Phase 6 (路由导航)
                                              ↓
                                      Phase 7 (多语言)
                                              ↓
                                      Phase 8 (测试)
                                              ↓
                                      Phase 9 (Mock 数据)
```

---

## 任务统计

| Phase | 任务数 |
|-------|--------|
| Phase 1: 数据库层 | 7 |
| Phase 2: API 层 | 12 |
| Phase 3: Repository 层 | 5 |
| Phase 4: Model/ViewModel | 9 |
| Phase 5: UI 组件和页面 | 14 |
| Phase 6: 路由和导航 | 6 |
| Phase 7: 多语言支持 | 3 |
| Phase 8: 测试补充 | 7 |
| Phase 9: Mock 数据 | 3 |
| **总计** | **66** |
