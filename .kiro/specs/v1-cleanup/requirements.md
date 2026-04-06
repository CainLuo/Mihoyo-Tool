# 需求文档

## 简介

所有 entry 页面 ViewModel 已完成 V2 迁移（Home、Characters、Login mock 页均已完成）。
本 spec 完成最后的清理工作：从 `core/Index.ets` 移除旧版 V1 导出行，并删除旧版 V1 文件。

完成后，整个项目不再有任何对旧版 V1 架构的依赖。

---

## 术语表

- **旧版 V1**：`core/src/main/ets/database/`（非 v2 子目录）、`core/src/main/ets/models/`（非 v2 子目录）、`core/src/main/ets/repository/`（非 v2 子目录）下的旧版文件
- **保留文件**：`CoreInitializer.ets`、`AccountRepository.ets`、`AuthRepository.ets`、`RdbManager.ets` 等仍被 `EntryAbility` 和 `Launch` 间接使用的文件，本 spec 不删除

---

## 需求列表

### 需求 1：从 core/Index.ets 移除旧版 V1 导出

**用户故事：** 作为开发者，我希望 `core/Index.ets` 不再导出旧版 V1 符号，使 entry 模块无法意外 import 旧版类。

#### 验收标准

1. `core/Index.ets` 移除以下导出行：
   - `export * from './src/main/ets/database/QueryBuilder'`
   - `export * from './src/main/ets/database/GameDataDao'`
   - `export * from './src/main/ets/database/GameStatsDao'`
   - `export * from './src/main/ets/database/SyncMetaDao'`
   - `export * from './src/main/ets/models/GameDataRow'`
   - `export * from './src/main/ets/models/GameStatsRow'`
   - `export * from './src/main/ets/models/SyncMetaRow'`（旧版，V2 版本在 models/v2/ 目录）
   - `export * from './src/main/ets/repository/CharacterRepository'`
   - `export * from './src/main/ets/repository/DailyNoteRepository'`
   - `export * from './src/main/ets/repository/ActivityRepository'`
   - `export * from './src/main/ets/repository/GachaRepository'`
2. 保留以下导出行（仍被 `CoreInitializer` 或 `EntryAbility` 使用）：
   - `export * from './src/main/ets/database/RdbManager'`
   - `export * from './src/main/ets/repository/AccountRepository'`
   - `export * from './src/main/ets/repository/AuthRepository'`
3. 移除后，编译器不得产生任何与 import 相关的错误

---

### 需求 2：删除旧版 V1 文件

**用户故事：** 作为开发者，我希望旧版 V1 文件从代码库中彻底删除，减少维护负担和混淆风险。

#### 验收标准

1. 删除以下文件（已确认无任何引用）：
   - `core/src/main/ets/database/GameDataDao.ets`
   - `core/src/main/ets/database/GameStatsDao.ets`
   - `core/src/main/ets/database/SyncMetaDao.ets`
   - `core/src/main/ets/database/QueryBuilder.ets`
   - `core/src/main/ets/models/GameDataRow.ets`
   - `core/src/main/ets/models/GameStatsRow.ets`
   - `core/src/main/ets/models/SyncMetaRow.ets`（旧版）
   - `core/src/main/ets/repository/CharacterRepository.ets`
   - `core/src/main/ets/repository/DailyNoteRepository.ets`
   - `core/src/main/ets/repository/ActivityRepository.ets`
   - `core/src/main/ets/repository/GachaRepository.ets`
2. 保留以下文件（仍被 `CoreInitializer` 使用）：
   - `core/src/main/ets/database/RdbManager.ets`
   - `core/src/main/ets/repository/AccountRepository.ets`
   - `core/src/main/ets/repository/AuthRepository.ets`
   - `core/src/main/ets/CoreInitializer.ets`

---

### 需求 4：移除旧版 CoreInitializer 并行初始化

**用户故事：** 作为开发者，我希望 `EntryAbility` 和 `Launch` 不再依赖旧版 `CoreInitializer`，使应用启动时只初始化 V2 架构，彻底完成新旧架构的切换。

#### 验收标准

1. `EntryAbility.ets` 删除 `CoreInitializer.initCore(...)` 调用，只保留 `CoreInitializerV2.initCore(...)`
2. `EntryAbility.ets` 删除对 `CoreInitializer` 的 import
3. `Launch.ets` 将 `CoreInitializer.waitForReady()` 替换为 `CoreInitializerV2.waitForReady()`
4. `Launch.ets` 删除对 `CoreInitializer` 的 import
5. 删除 `core/src/main/ets/CoreInitializer.ets`（旧版初始化器，已无引用）
6. 删除 `core/src/main/ets/database/RdbManager.ets`（旧版 RDB 管理器，已无引用）
7. 删除 `core/src/main/ets/repository/AccountRepository.ets`（旧版账号 Repository，已无引用）
8. 从 `core/Index.ets` 移除以下导出行：
   - `export * from './src/main/ets/database/RdbManager'`
   - `export * from './src/main/ets/repository/AccountRepository'`
   - `export * from './src/main/ets/CoreInitializer'`
9. 移除后，编译器不得产生任何与 import 相关的错误

---

### 需求 5：清理 MyViewModel 中的误导性注释

**用户故事：** 作为开发者，我希望 `MyViewModel` 中的"暂时保留旧版网络调用"注释被移除，因为 `AuthRepository` 是正常的网络层调用，不是旧版 V1 DB 依赖。

#### 验收标准

1. `MyViewModel.ets` 删除"暂时保留旧版网络调用"相关注释
2. 文件头部注释更新，移除"网络调用暂时保留旧版 AuthRepository"的说明

---

### 需求 6：构建验证（第二阶段）

#### 验收标准

1. 执行 `hvigorw clean && hvigorw assembleHap -p product=mock` 输出 `BUILD SUCCESSFUL`，零编译错误
2. 无新增警告

---

## 前置条件

本 spec 必须在以下 spec 全部完成后才能执行：

- `home-page-v2-migration` ✅
- `characters-page-v2-migration` ✅
- `login-page-v2-migration`（mock LoginViewModel 迁移）

---

## 文件改动清单

| 文件                                                   | 改动类型 | 改动内容                                            |
| ------------------------------------------------------ | -------- | --------------------------------------------------- |
| `core/Index.ets`                                       | 修改     | 移除旧版 V1 导出行（11 行）                         |
| `core/src/main/ets/database/GameDataDao.ets`           | 删除     | 旧版，无引用                                        |
| `core/src/main/ets/database/GameStatsDao.ets`          | 删除     | 旧版，无引用                                        |
| `core/src/main/ets/database/SyncMetaDao.ets`           | 删除     | 旧版，无引用                                        |
| `core/src/main/ets/database/QueryBuilder.ets`          | 删除     | 旧版，无引用                                        |
| `core/src/main/ets/models/GameDataRow.ets`             | 删除     | 旧版，无引用                                        |
| `core/src/main/ets/models/GameStatsRow.ets`            | 删除     | 旧版，无引用                                        |
| `core/src/main/ets/models/SyncMetaRow.ets`（旧版）     | 删除     | 旧版，无引用（V2 版本在 models/v2/SyncMetaRow.ets） |
| `core/src/main/ets/repository/CharacterRepository.ets` | 删除     | 旧版，无引用                                        |
| `core/src/main/ets/repository/DailyNoteRepository.ets` | 删除     | 旧版，无引用                                        |
| `core/src/main/ets/repository/ActivityRepository.ets`  | 删除     | 旧版，无引用                                        |
| `core/src/main/ets/repository/GachaRepository.ets`     | 删除     | 旧版，无引用                                        |

---

## 已知警告说明

### 预存在警告

| 警告来源           | 警告内容                   | 说明                 |
| ------------------ | -------------------------- | -------------------- |
| `RdbManagerV2.ets` | `canIUse` 相关警告         | 预存在，不影响功能   |
| 签名配置           | `Will skip sign 'hos_hap'` | 预存在，开发环境正常 |

### 清理后新增警告记录区

| 警告来源   | 警告内容   | 处理方式   |
| ---------- | ---------- | ---------- |
| （待填写） | （待填写） | （待填写） |
