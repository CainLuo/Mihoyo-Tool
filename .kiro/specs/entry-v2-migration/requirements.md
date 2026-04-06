# 需求文档：V1 旧版清理

## 简介

所有 entry 页面 ViewModel 已完成 V2 迁移（Home、Characters 页已完成）。
本 spec 完成最后的清理工作：

1. 迁移 mock source set 的 `LoginViewModel`（仍使用旧版 `AccountRepository`）
2. 从 `core/Index.ets` 移除旧版 V1 导出行
3. 删除旧版 V1 文件（DB 层、Model 层、Repository 层）

完成后，整个项目不再有任何对旧版 V1 架构的依赖。

---

## 术语表

- **旧版 V1**：`core/src/main/ets/database/`（非 v2 子目录）、`core/src/main/ets/models/`（非 v2 子目录）、`core/src/main/ets/repository/`（非 v2 子目录）下的文件
- **mock LoginViewModel**：`entry/src/mock/ets/viewmodel/LoginViewModel.ets`，mock source set 专用，使用旧版 `AccountRepository` 写入账号和角色数据
- **V2 finalizeLogin**：使用 `CoreInitializerV2.bbsRepository` 写入 `AccountRowV2` 和 `GameRoleRowV2`

---

## 需求列表

### 需求 1：迁移 mock LoginViewModel

**用户故事：** 作为开发者，我希望 mock source set 的 LoginViewModel 也使用 V2 Repository，使 mock 环境和 release 环境的数据写入路径一致。

#### 验收标准

1. `entry/src/mock/ets/viewmodel/LoginViewModel.ets` 不得 import `AccountRepository` 或 `GameRoleRow`
2. `finalizeLogin` 使用 `CoreInitializerV2.bbsRepository.saveAccount(AccountRowV2)` 写入账号
3. `finalizeLogin` 使用 `CoreInitializerV2.bbsRepository.saveGameRoles(GameRoleRowV2[])` 写入角色
4. mock 登录成功后，`loginSuccess` 仍设为 `true`，行为与迁移前一致
5. `LoginViewModelKeys` 补充 `loginedAccountId` 和 `loginedAccountVM` 字段，与 main source set 保持一致

---

### 需求 2：从 core/Index.ets 移除旧版 V1 导出

**用户故事：** 作为开发者，我希望 `core/Index.ets` 不再导出旧版 V1 符号，使 entry 模块无法意外 import 旧版类。

#### 验收标准

1. `core/Index.ets` 移除以下导出行：
   - `export * from './src/main/ets/database/RdbManager'`
   - `export * from './src/main/ets/database/QueryBuilder'`
   - `export * from './src/main/ets/database/GameDataDao'`
   - `export * from './src/main/ets/database/GameStatsDao'`
   - `export * from './src/main/ets/database/SyncMetaDao'`
   - `export * from './src/main/ets/models/GameDataRow'`
   - `export * from './src/main/ets/models/GameStatsRow'`
   - `export * from './src/main/ets/models/SyncMetaRow'`
   - `export * from './src/main/ets/repository/CharacterRepository'`
   - `export * from './src/main/ets/repository/DailyNoteRepository'`
   - `export * from './src/main/ets/repository/ActivityRepository'`
   - `export * from './src/main/ets/repository/GachaRepository'`
2. 保留 `export * from './src/main/ets/repository/AccountRepository'`（`EntryAbility` 和 `Launch` 仍通过 `CoreInitializer` 间接依赖旧版初始化）
3. 移除后，编译器不得产生任何与 import 相关的错误

---

### 需求 3：删除旧版 V1 文件

**用户故事：** 作为开发者，我希望旧版 V1 文件从代码库中彻底删除，减少维护负担。

#### 验收标准

1. 删除以下文件（已确认无任何引用）：
   - `core/src/main/ets/database/GameDataDao.ets`
   - `core/src/main/ets/database/GameStatsDao.ets`
   - `core/src/main/ets/database/SyncMetaDao.ets`
   - `core/src/main/ets/database/QueryBuilder.ets`
   - `core/src/main/ets/models/GameDataRow.ets`
   - `core/src/main/ets/models/GameStatsRow.ets`
   - `core/src/main/ets/models/SyncMetaRow.ets`
   - `core/src/main/ets/repository/CharacterRepository.ets`
   - `core/src/main/ets/repository/DailyNoteRepository.ets`
   - `core/src/main/ets/repository/ActivityRepository.ets`
   - `core/src/main/ets/repository/GachaRepository.ets`
2. 保留以下文件（仍被 `CoreInitializer` 使用）：
   - `core/src/main/ets/database/RdbManager.ets`
   - `core/src/main/ets/models/SyncMetaRow.ets`（旧版，被 `SyncMetaDao` 使用）
   - `core/src/main/ets/repository/AccountRepository.ets`
   - `core/src/main/ets/repository/AuthRepository.ets`

---

### 需求 4：构建验证

#### 验收标准

1. 执行 `hvigorw clean && hvigorw assembleHap -p product=mock` 输出 `BUILD SUCCESSFUL`，零编译错误
2. 无新增警告

---

## 文件改动清单

| 文件                                                   | 改动类型 | 改动内容                                              |
| ------------------------------------------------------ | -------- | ----------------------------------------------------- |
| `entry/src/mock/ets/viewmodel/LoginViewModel.ets`      | 修改     | 移除旧版 import，`finalizeLogin` 切换到 V2 Repository |
| `core/Index.ets`                                       | 修改     | 移除旧版 V1 导出行                                    |
| `core/src/main/ets/database/GameDataDao.ets`           | 删除     | 旧版，无引用                                          |
| `core/src/main/ets/database/GameStatsDao.ets`          | 删除     | 旧版，无引用                                          |
| `core/src/main/ets/database/SyncMetaDao.ets`           | 删除     | 旧版，无引用                                          |
| `core/src/main/ets/database/QueryBuilder.ets`          | 删除     | 旧版，无引用                                          |
| `core/src/main/ets/models/GameDataRow.ets`             | 删除     | 旧版，无引用                                          |
| `core/src/main/ets/models/GameStatsRow.ets`            | 删除     | 旧版，无引用                                          |
| `core/src/main/ets/models/SyncMetaRow.ets`（旧版）     | 删除     | 旧版，无引用（V2 版本在 models/v2/ 目录）             |
| `core/src/main/ets/repository/CharacterRepository.ets` | 删除     | 旧版，无引用                                          |
| `core/src/main/ets/repository/DailyNoteRepository.ets` | 删除     | 旧版，无引用                                          |
| `core/src/main/ets/repository/ActivityRepository.ets`  | 删除     | 旧版，无引用                                          |
| `core/src/main/ets/repository/GachaRepository.ets`     | 删除     | 旧版，无引用                                          |

---

## 已知警告说明

### 预存在警告

| 警告来源           | 警告内容                   | 说明                 |
| ------------------ | -------------------------- | -------------------- |
| `RdbManagerV2.ets` | `executeSql` 异常处理警告  | 预存在，不影响功能   |
| 签名配置           | `Will skip sign 'hos_hap'` | 预存在，开发环境正常 |

### 清理后新增警告记录区

| 警告来源   | 警告内容   | 处理方式   |
| ---------- | ---------- | ---------- |
| （待填写） | （待填写） | （待填写） |
