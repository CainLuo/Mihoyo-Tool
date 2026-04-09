# 需求文档

## 简介

本 spec 覆盖 `CharactersViewModel` 从旧版 `CharacterRepository`（V1）迁移到 V2 Repository + V2 ApiService 的完整重构工作。

**范围**：仅修改 `entry/src/main/ets/viewmodel/CharactersViewModel.ets`，Characters 页 View 层（`Characters.ets`）、组件层均已完成，**不在本 spec 修改范围内**。

**目标**：

1. 移除所有旧版 `CharacterRepository` 调用，切换到 V2 Repository 的 `upsertAvatarList`
2. 移除旧版 `CharacterRepository` import
3. 保持 Characters 页 UI 功能和用户体验完全不变
4. 每次 spec 执行完成后 clean + rebuild 验证，警告需记录

---

## 术语表

- **CharactersViewModel**：角色 Tab ViewModel，持有账号选择器、游戏 Tab、角色列表等 UI 状态
- **CharacterRepository**：旧版（V1）角色同步工具类，本 spec 完成后将从 CharactersViewModel 中完全移除
- **V2 Repository**：`GenshinRepository`、`StarRailRepository`、`ZZZRepository`，通过 `CoreInitializerV2` 单例访问，提供 `upsertAvatarList`、`markAvatarListSyncing`、`markAvatarListFailed`、`needsAvatarListSync` 等方法
- **V2 ApiService**：`GenshinApiService`、`StarRailApiService`、`ZZZApiService`，通过对应 Repository 的 `getService()` 获取，提供 `getCharacterList(roleId, server, cookie)` 网络方法
- **syncCharactersV2**：新增私有辅助方法，封装单个游戏角色列表的完整 V2 同步流程
- **refresh**：手动刷新方法，检查冷却后触发当前游戏角色同步
- **forceRefresh**：强制刷新方法，跳过冷却检查直接触发同步
- **autoSyncCharacters**：后台静默同步方法，角色列表为空时自动触发

---

## 需求列表

### 需求 1：移除旧版 import

**用户故事：** 作为开发者，我希望移除 CharactersViewModel 中所有 V1 旧版 import，使代码库不再依赖已废弃的 CharacterRepository。

#### 验收标准

1. `CharactersViewModel` 不得 import `CharacterRepository`
2. 移除 V1 import 后，编译器不得产生任何与 import 相关的错误

---

### 需求 2：实现 syncCharactersV2 私有辅助方法

**用户故事：** 作为开发者，我希望有一个私有辅助方法封装单个游戏角色列表的 V2 同步逻辑，使 refresh、forceRefresh、autoSyncCharacters 共用同一实现，避免代码重复。

#### 验收标准

1. `CharactersViewModel` 提供私有方法 `syncCharactersV2(account: AccountRowV2, gameId: string, roleUid: string, server: string): Promise<void>`
2. `syncCharactersV2` 根据 `gameId` 分发到对应 V2 Repository（genshin / starrail / zzz），其他 gameId 静默跳过
3. 原神分支：调用 `genshinRepository.markAvatarListSyncing` → `getService().getCharacterList` → 解析响应构建 `GenshinCharacterListRow[]` → `genshinRepository.upsertAvatarList`
4. 星铁分支：调用 `starRailRepository.markAvatarListSyncing` → `getService().getAvatarBasic` → 解析响应构建 `StarRailAvatarBasicRow[]` → `starRailRepository.upsertAvatarList`
5. 绝区零分支：调用 `zzzRepository.markAvatarListSyncing` → `getService().getAvatarBasic` → 解析响应构建 `ZZZAvatarBasicRow[]` → `zzzRepository.upsertAvatarList`
6. 任意分支失败时，调用对应 Repository 的 `markAvatarListFailed` 并将错误信息传出（由调用方处理 `networkErrorMsg`）

---

### 需求 3：改写 refresh

**用户故事：** 作为开发者，我希望 refresh 使用 V2 Repository 和 V2 ApiService 进行角色同步，使角色数据通过新架构拉取和持久化。

#### 验收标准

1. `refresh` 被调用时，`CharactersViewModel` 调用 `syncCharactersV2` 替代旧版 `CharacterRepository.syncCharacters`
2. 同步成功后，`CharactersViewModel` 调用 `reloadCharacters()` 刷新 UI
3. 同步失败时，`CharactersViewModel` 将 `networkErrorMsg` 设为错误信息
4. `refresh` 不得包含任何对 `CharacterRepository` 的调用
5. 删除注释"暂时保留旧版网络同步调用"

---

### 需求 4：改写 forceRefresh

**用户故事：** 作为开发者，我希望 forceRefresh 使用 V2 Repository 和 V2 ApiService，使强制刷新也通过新架构执行。

#### 验收标准

1. `forceRefresh` 被调用时，`CharactersViewModel` 调用 `syncCharactersV2` 替代旧版 `CharacterRepository.syncCharacters`
2. 同步成功后，`CharactersViewModel` 调用 `reloadCharacters()` 刷新 UI
3. 同步失败时，`CharactersViewModel` 将 `networkErrorMsg` 设为错误信息
4. `forceRefresh` 不得包含任何对 `CharacterRepository` 的调用
5. 删除注释"暂时保留旧版网络同步调用"

---

### 需求 5：改写 autoSyncCharacters

**用户故事：** 作为开发者，我希望 autoSyncCharacters 使用 V2 Repository 和 V2 ApiService，使后台静默同步也通过新架构执行。

#### 验收标准

1. `autoSyncCharacters` 被调用时，`CharactersViewModel` 调用 `syncCharactersV2` 替代旧版 `CharacterRepository.syncCharacters`
2. 同步成功后，若仍是当前选中 tab，`CharactersViewModel` 重新从 V2 DB 读取数据并更新 UI
3. 同步失败时，若 `viewState` 仍为 LOADING，切换为 EMPTY
4. `autoSyncCharacters` 不得包含任何对 `CharacterRepository` 的调用
5. 删除注释"暂时保留旧版网络同步调用"

---

### 需求 6：UI 功能和用户体验不变

**用户故事：** 作为用户，我希望 V2 迁移后 Characters 页的外观和行为与迁移前完全一致，使重构对我透明无感。

#### 验收标准

1. `CharactersViewModel` 保留所有现有公开属性：`viewState`、`accountOptions`、`selectedAccountIdx`、`gameTabs`、`selectedGameIdx`、`characters`、`isRefreshing`、`networkErrorMsg`、`refreshCoolingDown`
2. `CharactersViewModel` 保留所有现有公开方法：`loadData()`、`selectAccount()`、`selectGame()`、`refresh()`、`forceRefresh()`
3. 角色列表为空时，后台自动触发同步的行为保持不变
4. 30 分钟冷却检查逻辑保持不变

---

### 需求 7：构建验证要求

**用户故事：** 作为开发者，我希望迁移完成后项目能成功构建，以确认没有引入回归问题。

#### 验收标准

1. 迁移完成后，执行 `hvigorw clean && hvigorw assembleHap -p product=mock` 输出 `BUILD SUCCESSFUL`，零编译错误
2. 构建产物不得产生超出"已知警告说明"中预存在警告的新警告
3. 若出现新警告，开发者须排查并修复，或记录在"已知警告说明"的新增警告区

---

## 数据流文档

### 主流程：角色列表同步（V2 架构）

```mermaid
flowchart TD
    A([用户触发刷新 / 角色列表为空]) --> B{触发方式}

    B -- refresh 手动刷新 --> C{冷却期内？}
    C -- 是 --> D[refreshCoolingDown 信号翻转\n弹冷却 Dialog]
    C -- 否 --> E[isRefreshing = true]

    B -- forceRefresh 强制刷新 --> E
    B -- autoSyncCharacters 后台静默 --> F[syncCharactersV2]

    E --> F

    F --> G{gameId 分发}
    G -- genshin --> H[genshinRepository.markAvatarListSyncing\ngetService.getCharacterList\n构建 GenshinCharacterListRow[]\ngenshinRepository.upsertAvatarList]
    G -- starrail --> I[starRailRepository.markAvatarListSyncing\ngetService.getAvatarBasic\n构建 StarRailAvatarBasicRow[]\nstarRailRepository.upsertAvatarList]
    G -- zzz --> J[zzzRepository.markAvatarListSyncing\ngetService.getAvatarBasic\n构建 ZZZAvatarBasicRow[]\nzzzRepository.upsertAvatarList]
    G -- 其他 --> K[静默跳过]

    H --> L{同步结果}
    I --> L
    J --> L

    L -- 成功 --> M[reloadCharacters\n从 V2 DB 读取\n更新 UI]
    L -- 失败 --> N[markAvatarListFailed\nnetworkErrorMsg = msg\n弹 Alert]

    M --> O[isRefreshing = false]
    N --> O
```

---

## 测试用例设计

### ViewModel 单元测试（entry/src/test/CharactersViewModel.test.ets）

> 遵循 testing-entry-pages.md 规范，只测试纯逻辑，不依赖设备，不 import core Repository 或 DAO。

| 测试用例                                      | 前置条件                              | 操作                                          | 预期结果                            |
| --------------------------------------------- | ------------------------------------- | --------------------------------------------- | ----------------------------------- |
| 初始 viewState 为 LOADING                     | 新建实例                              | `new CharactersViewModel()`                   | `viewState === ViewState.LOADING`   |
| 初始 selectedAccountIdx 为 0                  | 新建实例                              | `new CharactersViewModel()`                   | `selectedAccountIdx === 0`          |
| 初始 selectedGameIdx 为 0                     | 新建实例                              | `new CharactersViewModel()`                   | `selectedGameIdx === 0`             |
| 初始 characters 为空数组                      | 新建实例                              | `new CharactersViewModel()`                   | `characters.length === 0`           |
| 初始 isRefreshing 为 false                    | 新建实例                              | `new CharactersViewModel()`                   | `isRefreshing === false`            |
| 初始 networkErrorMsg 为空                     | 新建实例                              | `new CharactersViewModel()`                   | `networkErrorMsg === ''`            |
| 初始 accountOptions 为空数组                  | 新建实例                              | `new CharactersViewModel()`                   | `accountOptions.length === 0`       |
| 初始 gameTabs 为空数组                        | 新建实例                              | `new CharactersViewModel()`                   | `gameTabs.length === 0`             |
| 初始 refreshCoolingDown 为 false              | 新建实例                              | `new CharactersViewModel()`                   | `refreshCoolingDown === false`      |
| selectAccount 相同 idx 不触发重载             | `selectedAccountIdx=0`                | `selectAccount(0)`                            | 不改变 selectedAccountIdx           |
| selectGame 相同 idx 不触发重载                | `selectedGameIdx=0`                   | `selectGame(0)`                               | 不改变 selectedGameIdx              |
| refresh 时 isRefreshing 已为 true 则跳过      | `isRefreshing=true`                   | `vm.refresh()`                                | 不重复触发，isRefreshing 保持 true  |
| forceRefresh 时 isRefreshing 已为 true 则跳过 | `isRefreshing=true`                   | `vm.forceRefresh()`                           | 不重复触发，isRefreshing 保持 true  |
| refresh 时 gameTabs 为空则跳过                | `gameTabs=[]`                         | `vm.refresh()`                                | 不触发同步，isRefreshing 保持 false |
| forceRefresh 时 gameTabs 为空则跳过           | `gameTabs=[]`                         | `vm.forceRefresh()`                           | 不触发同步，isRefreshing 保持 false |
| toSelectOptions 空数组返回空数组              | —                                     | `CharactersViewModel.toSelectOptions([])`     | 返回 `[]`                           |
| toSelectOptions 转换正确                      | `opts=[{accountId:1, username:'u1'}]` | `CharactersViewModel.toSelectOptions(opts)`   | 返回 `[{value:'u1'}]`               |
| toSelectOptions 多条转换正确                  | 2 个 AccountOption                    | `CharactersViewModel.toSelectOptions(opts)`   | 返回 2 条，顺序一致                 |
| KEYS.networkErrorMsg 路径正确                 | —                                     | `CharactersViewModel.KEYS.networkErrorMsg`    | 值为 `'vm.networkErrorMsg'`         |
| KEYS.refreshCoolingDown 路径正确              | —                                     | `CharactersViewModel.KEYS.refreshCoolingDown` | 值为 `'vm.refreshCoolingDown'`      |

### 边界场景补充

| 测试用例                                       | 操作                                             | 预期结果                                      |
| ---------------------------------------------- | ------------------------------------------------ | --------------------------------------------- |
| refreshCoolingDown 信号翻转触发 View 弹 Dialog | `refreshCoolingDown=false`，refresh 且在冷却期内 | `refreshCoolingDown` 变为 true（信号翻转）    |
| selectAccount 超出范围的 idx 不崩溃            | `selectAccount(999)`                             | 不崩溃（数组越界保护）                        |
| selectGame 超出范围的 idx 不崩溃               | `selectGame(999)`                                | 不崩溃                                        |
| forceRefresh 时 gameTabs 为空直接返回          | `gameTabs=[]`，调用 `forceRefresh()`             | 不崩溃，直接返回，isRefreshing 保持 false     |
| parseGenshinCharacterList 空响应返回空数组     | `resp = {list: []}`                              | 返回 `[]`，不崩溃                             |
| parseStarRailAvatarBasic 空响应返回空数组      | `resp = {list: []}`                              | 返回 `[]`，不崩溃                             |
| parseZZZAvatarBasic 空响应返回空数组           | `resp = {avatar_list: []}`                       | 返回 `[]`，不崩溃                             |
| parseGenshinCharacterList 无 weapon 字段不崩溃 | `item.weapon = null`                             | weaponName/Level/AffixLevel/Rarity 均为默认值 |
| parseStarRailAvatarBasic 无 equip 字段不崩溃   | `item.equip = null`                              | equipId/Name/Level/Rank/Rarity 均为默认值     |

---

## 构建验证要求

### 执行步骤

每次 spec 任务执行完成后，必须按以下顺序验证：

```bash
# 1. 清理
"$HVIGOR" clean

# 2. 构建（mock 模式）
"$HVIGOR" assembleHap -p product=mock

# 3. 安装
"$HDC" -t 127.0.0.1:5555 install entry/build/mock/outputs/mock/entry-mock-unsigned.hap

# 4. 启动
"$HDC" -t 127.0.0.1:5555 shell aa start -b com.cainluo.mihoyo.tools -a EntryAbility
```

### 验收标准

1. `hvigorw assembleHap -p product=mock` 输出 `BUILD SUCCESSFUL`，零编译错误
2. 安装和启动无异常
3. 新增警告必须记录在下方"已知警告说明"中

---

## 文件改动清单

| 文件                                                   | 改动类型 | 改动内容                                                                                      |
| ------------------------------------------------------ | -------- | --------------------------------------------------------------------------------------------- |
| `entry/src/main/ets/viewmodel/CharactersViewModel.ets` | 修改     | 删除 V1 import，新增 `syncCharactersV2`，改写 `refresh`、`forceRefresh`、`autoSyncCharacters` |

**本 spec 不删除的文件**：

- `core/src/main/ets/repository/CharacterRepository.ets` — 仍被 `CharactersViewModel` 迁移前引用，本 spec 完成后在 entry 中无引用，但等所有页面迁移完成后统一清理

---

## 已知警告说明

### 预存在警告（迁移前已存在，不属于本 spec 引入）

| 警告来源                | 警告内容                                                                                      | 说明                                                                                    |
| ----------------------- | --------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `RdbManagerV2.ets`      | `canIUse('SystemCapability.DistributedDataManager.RelationalStore.Core')` 返回 false 相关警告 | HarmonyOS NEXT 模拟器环境下 RDB canIUse 检查的已知问题，不影响功能，运行时 RDB 正常工作 |
| `GenshinApiService.ets` | `x-rpc-tool_verison` 拼写警告（米游社服务端拼写错误 `verison`，非 `version`）                 | 故意保留，与服务端保持一致，修改会导致接口鉴权失败                                      |
| 签名配置                | `Will skip sign 'hos_hap'`                                                                    | 开发环境未配置签名，正常现象                                                            |

### 迁移后新增警告记录区

> 执行 clean + rebuild 后，若出现新警告，在此处记录：

| 警告来源   | 警告内容   | 处理方式   |
| ---------- | ---------- | ---------- |
| （待填写） | （待填写） | （待填写） |
