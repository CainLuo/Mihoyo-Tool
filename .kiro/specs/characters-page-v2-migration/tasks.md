# 任务列表

## 任务 1：清理旧版 import，添加 V2 依赖

- [x] 1.1 从 `CharactersViewModel.ets` 的 import 列表中移除 `CharacterRepository`
- [x] 1.2 在 import 列表中添加 `GenshinApiService`、`StarRailApiService`、`ZZZApiService`
- [x] 1.3 在文件顶部声明解析用本地 interface：`GenshinWeaponItem`、`GenshinCharacterItem`、`GenshinCharacterListData`、`StarRailEquipItem`、`StarRailAvatarItem`、`StarRailAvatarListData`、`ZZZAvatarItem`、`ZZZAvatarListData`

## 任务 2：实现 syncCharactersV2 私有辅助方法

- [x] 2.1 新增私有方法 `syncCharactersV2(account: AccountRowV2, gameId: string, roleUid: string, server: string): Promise<void>`
- [x] 2.2 在方法内根据 `gameId` 分发到对应 V2 Repository（genshin / starrail / zzz），其他 gameId 静默跳过
- [x] 2.3 实现原神分支：调用 `genshinRepository.markAvatarListSyncing` → `(repo.getService() as GenshinApiService).getCharacterList` → `parseGenshinCharacterList` 构建 `GenshinCharacterListRow[]` → `genshinRepository.upsertAvatarList`
- [x] 2.4 实现星铁分支：调用 `starRailRepository.markAvatarListSyncing` → `(repo.getService() as StarRailApiService).getAvatarBasic` → `parseStarRailAvatarBasic` 构建 `StarRailAvatarBasicRow[]` → `starRailRepository.upsertAvatarList`
- [x] 2.5 实现绝区零分支：调用 `zzzRepository.markAvatarListSyncing` → `(repo.getService() as ZZZApiService).getAvatarBasic` → `parseZZZAvatarBasic` 构建 `ZZZAvatarBasicRow[]` → `zzzRepository.upsertAvatarList`
- [x] 2.6 在各分支的 catch 块中：调用对应 Repository 的 `markAvatarListFailed`，并 `throw new Error(msg)` 将错误传出给调用方处理

## 任务 3：实现三个静态解析方法

- [x] 3.1 实现 `parseGenshinCharacterList(accountId, roleUid, resp): GenshinCharacterListRow[]`：将 `resp as GenshinCharacterListData`，遍历 `list`，逐字段构建 `GenshinCharacterListRow`，weapon 为 null 时各字段取默认值，解析失败时返回空数组
- [x] 3.2 实现 `parseStarRailAvatarBasic(accountId, roleUid, resp): StarRailAvatarBasicRow[]`：将 `resp as StarRailAvatarListData`，遍历 `list`，逐字段构建 `StarRailAvatarBasicRow`，equip 为 null 时各字段取默认值，解析失败时返回空数组
- [x] 3.3 实现 `parseZZZAvatarBasic(accountId, roleUid, resp): ZZZAvatarBasicRow[]`：将 `resp as ZZZAvatarListData`，遍历 `avatar_list`，逐字段构建 `ZZZAvatarBasicRow`，解析失败时返回空数组

## 任务 4：改写 refresh

- [x] 4.1 将 `refresh` 中调用 `CharacterRepository.syncCharacters` 的代码替换为 `await this.syncCharactersV2(account, tab.gameId, tab.roleUid, server)`
- [x] 4.2 删除注释"暂时保留旧版网络同步调用"
- [x] 4.3 确认同步成功后仍调用 `reloadCharacters()` 刷新 UI，失败时设置 `networkErrorMsg`

## 任务 5：改写 forceRefresh

- [x] 5.1 将 `forceRefresh` 中调用 `CharacterRepository.syncCharacters` 的代码替换为 `await this.syncCharactersV2(account, tab.gameId, tab.roleUid, this.findServer(tab.roleUid))`
- [x] 5.2 删除注释"暂时保留旧版网络同步调用"
- [x] 5.3 确认同步成功后仍调用 `reloadCharacters()` 刷新 UI，失败时设置 `networkErrorMsg`

## 任务 6：改写 autoSyncCharacters

- [x] 6.1 将 `autoSyncCharacters` 中调用 `CharacterRepository.syncCharacters` 的代码替换为 `this.syncCharactersV2(account, gameId, roleUid, server)`
- [x] 6.2 删除注释"暂时保留旧版网络同步调用"
- [x] 6.3 确认 `.then()` 中仍从 V2 DB 重新读取数据并更新 UI，`.catch()` 中若 viewState 仍为 LOADING 则切换为 EMPTY

## 任务 7：编写 ViewModel 单元测试

- [x] 7.1 在 `entry/src/test/` 下新建 `CharactersViewModel.test.ets`
- [x] 7.2 实现初始状态测试：`viewState === LOADING`、`selectedAccountIdx === 0`、`selectedGameIdx === 0`、`characters.length === 0`、`isRefreshing === false`、`networkErrorMsg === ''`、`accountOptions.length === 0`、`gameTabs.length === 0`、`refreshCoolingDown === false`
- [x] 7.3 实现防重入测试：`isRefreshing=true` 时调用 `refresh()` 和 `forceRefresh()` 均不重复触发
- [x] 7.4 实现 gameTabs 为空时的防护测试：`gameTabs=[]` 时调用 `refresh()` 和 `forceRefresh()` 直接返回，isRefreshing 保持 false
- [x] 7.5 实现 `selectAccount` 相同 idx 不触发重载测试
- [x] 7.6 实现 `selectGame` 相同 idx 不触发重载测试
- [x] 7.7 实现 `toSelectOptions` 静态方法测试：空数组、单条、多条转换正确
- [x] 7.8 实现 `CharactersViewModel.KEYS` 常量路径正确性测试（`networkErrorMsg`、`refreshCoolingDown` 两个字段）
- [x] 7.9 在 `entry/src/test/List.test.ets` 中注册 `charactersViewModelTest`

## 任务 8：构建验证

- [x] 8.1 执行 `hvigorw clean`
- [x] 8.2 执行 `hvigorw assembleHap -p product=mock`，确认 `BUILD SUCCESSFUL`，零编译错误
- [ ] 8.3 安装到模拟器：`hdc -t 127.0.0.1:5555 install entry/build/mock/outputs/mock/entry-mock-unsigned.hap`
- [ ] 8.4 启动应用，进入 Characters Tab，验证角色列表正常展示
- [ ] 8.5 若出现新警告，记录到 `requirements.md` 的"迁移后新增警告记录区"

---

> **说明：UI 测试和 Snapshot 测试不在本 spec 范围内。**
> Characters 页的 UI 测试（Hypium + uitest）和截图回归测试已在独立 spec
> `.kiro/specs/entry-ui-and-snapshot-tests/` 中定义，需单独执行。
