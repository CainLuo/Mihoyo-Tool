# 实现任务列表

## 前置条件

执行本 spec 前，确认以下 spec 已全部完成：

- `home-page-v2-migration` ✅
- `characters-page-v2-migration` ✅
- `login-page-v2-migration`（mock LoginViewModel 迁移完成）

## 任务

- [ ] 1. 从 core/Index.ets 移除旧版 V1 导出行
  - [x] 1.1 移除 `export * from './src/main/ets/database/QueryBuilder'`
  - [x] 1.2 移除 `export * from './src/main/ets/database/GameDataDao'`
  - [x] 1.3 移除 `export * from './src/main/ets/database/GameStatsDao'`
  - [x] 1.4 移除 `export * from './src/main/ets/database/SyncMetaDao'`
  - [x] 1.5 移除 `export * from './src/main/ets/models/GameDataRow'`
  - [x] 1.6 移除 `export * from './src/main/ets/models/GameStatsRow'`
  - [x] 1.7 移除 `export * from './src/main/ets/models/SyncMetaRow'`（旧版）
  - [x] 1.8 移除 `export * from './src/main/ets/repository/CharacterRepository'`
  - [x] 1.9 移除 `export * from './src/main/ets/repository/DailyNoteRepository'`
  - [x] 1.10 移除 `export * from './src/main/ets/repository/ActivityRepository'`
  - [x] 1.11 移除 `export * from './src/main/ets/repository/GachaRepository'`

- [ ] 2. 删除旧版 V1 文件
  - [x] 2.1 删除 `core/src/main/ets/database/GameDataDao.ets`
  - [x] 2.2 删除 `core/src/main/ets/database/GameStatsDao.ets`
  - [x] 2.3 删除 `core/src/main/ets/database/SyncMetaDao.ets`
  - [x] 2.4 删除 `core/src/main/ets/database/QueryBuilder.ets`
  - [x] 2.5 删除 `core/src/main/ets/models/GameDataRow.ets`
  - [x] 2.6 删除 `core/src/main/ets/models/GameStatsRow.ets`
  - [x] 2.7 删除 `core/src/main/ets/models/SyncMetaRow.ets`（旧版）
  - [x] 2.8 删除 `core/src/main/ets/repository/CharacterRepository.ets`
  - [x] 2.9 删除 `core/src/main/ets/repository/DailyNoteRepository.ets`
  - [x] 2.10 删除 `core/src/main/ets/repository/ActivityRepository.ets`
  - [x] 2.11 删除 `core/src/main/ets/repository/GachaRepository.ets`

- [ ] 3. 构建验证
  - [x] 3.1 执行 `hvigorw clean && hvigorw assembleHap -p product=mock`，确认 BUILD SUCCESSFUL，零编译错误
  - [x] 3.2 记录构建产生的新增警告（如有）到 requirements.md 的"清理后新增警告记录区"

- [ ] 4. 移除旧版 CoreInitializer 并行初始化
  - [ ] 4.1 `EntryAbility.ets` 删除 `CoreInitializer.initCore(...)` 调用及相关注释
  - [ ] 4.2 `EntryAbility.ets` 删除对 `CoreInitializer` 的 import
  - [ ] 4.3 `Launch.ets` 将 `CoreInitializer.waitForReady()` 替换为 `CoreInitializerV2.waitForReady()`
  - [ ] 4.4 `Launch.ets` 删除对 `CoreInitializer` 的 import，添加 `CoreInitializerV2` 的 import
  - [ ] 4.5 从 `core/Index.ets` 移除 `export * from './src/main/ets/CoreInitializer'`
  - [ ] 4.6 从 `core/Index.ets` 移除 `export * from './src/main/ets/database/RdbManager'`
  - [ ] 4.7 从 `core/Index.ets` 移除 `export * from './src/main/ets/repository/AccountRepository'`
  - [ ] 4.8 删除 `core/src/main/ets/CoreInitializer.ets`
  - [ ] 4.9 删除 `core/src/main/ets/database/RdbManager.ets`
  - [ ] 4.10 删除 `core/src/main/ets/repository/AccountRepository.ets`

- [ ] 5. 清理 MyViewModel 中的误导性注释
  - [ ] 5.1 删除 `MyViewModel.ets` 文件头注释中"网络调用暂时保留旧版 AuthRepository"的说明
  - [ ] 5.2 删除 `loadAccounts` 方法中两处"暂时保留旧版网络调用"注释

- [ ] 6. 构建验证（第二阶段）
  - [ ] 6.1 执行 `hvigorw clean && hvigorw assembleHap -p product=mock`，确认 BUILD SUCCESSFUL，零编译错误
  - [ ] 6.2 记录构建产生的新增警告（如有）
