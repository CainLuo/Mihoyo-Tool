# 实现计划：持久化同步队列

## 状态

**已完成**（代码已实现，文档补全中）

## 任务

- [x] 1. SyncMetaDao 新增 pending 状态支持
  - [x] 1.1 新增 `findAllPending()` 方法，查询所有 `pending` 状态的任务
  - [x] 1.2 新增 `markPending()` 方法，写入/更新任务为 `pending` 状态

- [x] 2. 新增 SyncQueueRunner
  - [x] 2.1 定义 `SyncTask` 类（accountId / roleUid / server / cookie / dataType）
  - [x] 2.2 实现 `buildTasksForRoles()` — 根据游戏角色列表生成任务列表
  - [x] 2.3 实现 `enqueue()` — 把任务写入 `sync_meta` 表（`pending`）
  - [x] 2.4 实现 `runTasks()` — 逐个执行任务，防并发
  - [x] 2.5 实现 `resumeOnStartup()` — App 启动时从 DB 读取 pending 任务并继续
  - [x] 2.6 实现 `executeTask()` — 根据 `dataType` 分发到对应 Repository 方法

- [x] 3. GenshinRepository 新增角色详情同步
  - [x] 3.1 新增 `syncAvatarDetail()` — 调用 `getCharacterDetail` API 并存 DB
  - [x] 3.2 新增 `parseCharacterDetail()` — 直接存原始 API 数据（不做 UI 转换）

- [x] 4. GenshinCharacterDetailViewModel 适配原始格式
  - [x] 4.1 更新 `CharacterRawJson` 接口，适配 API 原始格式（`base` / `weapon` / `relics` / `skills` / `constellations`）
  - [x] 4.2 更新 `parseRawJson()` 方法，从原始格式解析 UI 展示数据

- [x] 5. BBSRepository 登录后触发队列同步
  - [x] 5.1 `login()` 方法步骤5：调用 `SyncQueueRunner.enqueue + runTasks`

- [x] 6. CoreInitializer 启动时恢复队列
  - [x] 6.1 `initCore()` 完成后调用 `SyncQueueRunner.resumeOnStartup()`

- [x] 7. CharactersViewModel 手动刷新改用队列
  - [x] 7.1 `syncCharacters()` 改为调用 `SyncQueueRunner.enqueue + runTasks`

- [x] 8. 导出 SyncQueueRunner
  - [x] 8.1 在 `core/Index.ets` 中导出 `SyncQueueRunner`

## 待优化（后续迭代）

- [ ] 绝区零真实环境逐个角色 id 请求（当前 mock 环境已验证，真实环境需要测试）
- [ ] `failed` 状态任务的重试机制（当前失败后不自动重试）
- [ ] 队列执行进度 UI 反馈（当前后台静默执行，无进度提示）
- [ ] 测试：`SyncQueueRunner` 单元测试
