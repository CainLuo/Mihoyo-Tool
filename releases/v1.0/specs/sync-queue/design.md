# 设计文档：持久化同步队列

## 架构概述

利用现有的 `sync_meta` 表新增 `pending` 状态，实现持久化任务队列。新增 `SyncQueueRunner` 作为队列执行器，统一管理所有同步任务的生命周期。

## 核心原则

- **core 不做 UI 转换**：Repository 层直接存原始 API 数据，ViewModel 层负责转换为 UI 展示格式
- **持久化优先**：任务在执行前必须先写入 DB，防止 App 被杀后丢失
- **单一职责**：`SyncQueueRunner` 只负责队列管理，具体同步逻辑仍在各 Repository 里

## 数据模型

### sync_meta 表状态扩展

在现有 `syncing`/`success`/`failed` 基础上新增：

| 状态      | 含义                       |
| --------- | -------------------------- |
| `pending` | 待执行（已入队，尚未开始） |
| `syncing` | 执行中                     |
| `success` | 已完成                     |
| `failed`  | 失败（可重试）             |

### 任务类型（data_type 字段）

| data_type                  | 说明                                   |
| -------------------------- | -------------------------------------- |
| `genshin_character_list`   | 原神角色列表                           |
| `genshin_character_detail` | 原神角色详情（批量）                   |
| `starrail_avatar_basic`    | 星铁角色列表                           |
| `starrail_avatar_info`     | 星铁角色详情（批量）                   |
| `zzz_avatar_basic`         | 绝区零角色列表                         |
| `zzz_avatar_info`          | 绝区零角色详情（mock 批量 / 真实逐个） |

## 新增文件

### `core/src/main/ets/repository/SyncQueueRunner.ets`

```
SyncQueueRunner
├── SyncTask（任务描述类）
├── buildTasksForRoles(accountId, roles, cookie) → SyncTask[]
├── enqueue(tasks) → void（写入 pending）
├── runTasks(tasks) → void（执行队列）
├── resumeOnStartup() → void（App 启动时恢复）
└── executeTask(task) → void（执行单个任务）
```

### `SyncMetaDao` 新增方法

- `findAllPending()` — 查询所有 `pending` 状态的任务
- `markPending(accountId, roleUid, dataType)` — 写入/更新为 `pending`

## 触发时机

```
登录成功
  └─ BBSRepository.login()
       └─ SyncQueueRunner.enqueue(tasks)
            └─ SyncQueueRunner.runTasks(tasks)  [后台异步]

手动刷新
  └─ CharactersViewModel.syncCharacters()
       └─ SyncQueueRunner.enqueue(tasks)
            └─ SyncQueueRunner.runTasks(tasks)

App 启动
  └─ CoreInitializer.initCore()
       └─ SyncQueueRunner.resumeOnStartup()
            └─ 从 DB 读取 pending 任务
                 └─ SyncQueueRunner.runTasks(tasks)
```

## 绝区零特殊处理

绝区零没有"一次拿全部角色详情"的 API：

- **mock 环境**：`getAvatarInfo` 传任意 idList 都返回同一个 mock 文件，一次请求即可
- **真实环境**：遍历 `avatar_basic` 里的每个角色 id，逐个调用 `getAvatarInfo`

```
ZZZ_AVATAR_INFO 任务执行逻辑：
  if (isMock):
    syncAvatarInfo(accountId, roleUid, server, cookie)  // 一次拿全部
  else:
    for each avatarId in getAvatarList():
      syncAvatarInfo(accountId, roleUid, server, cookie)  // 逐个请求
```

## 原神角色详情数据流

```
API 响应（原始格式）
  └─ GenshinRepository.parseCharacterDetail()
       └─ 直接存 JSON.stringify(item) 到 rawJson
            └─ GenshinCharacterDetailRow.rawJson

GenshinCharacterDetailViewModel.parseRawJson()
  └─ 读取 rawJson
       └─ 解析 base / weapon / relics / skills / constellations
            └─ 转换为 UI 展示模型（CharDetailWeapon / CharDetailRelic 等）
```

## 修改的文件

| 文件                                                      | 修改内容                                        |
| --------------------------------------------------------- | ----------------------------------------------- |
| `core/.../database/SyncMetaDao.ets`                       | 新增 `findAllPending`、`markPending`            |
| `core/.../repository/SyncQueueRunner.ets`                 | 新增文件，持久化队列执行器                      |
| `core/.../repository/BBSRepository.ets`                   | 登录后触发队列同步                              |
| `core/.../repository/GenshinRepository.ets`               | 新增 `syncAvatarDetail`、`parseCharacterDetail` |
| `core/.../CoreInitializer.ets`                            | 启动时调用 `resumeOnStartup`                    |
| `core/Index.ets`                                          | 导出 `SyncQueueRunner`                          |
| `entry/.../viewmodel/CharactersViewModel.ets`             | 手动刷新改用队列                                |
| `entry/.../viewmodel/GenshinCharacterDetailViewModel.ets` | 适配原始 API 格式解析                           |
