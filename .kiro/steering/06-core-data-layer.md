# core 数据层规范

## 一、数据库表结构

共 **16 张表**，按游戏类型分离，真相来源：`core/src/main/ets/database/TableSchema.ets`

- 基础表 2 张：`account_table`、`game_role_table`
- 原神专用表 4 张：`genshin_character_list`、`genshin_daily_note`、`genshin_character_detail`、`genshin_character_compute`
- 星穹铁道专用表 4 张：`starrail_avatar_basic`、`starrail_daily_note`、`starrail_avatar_info`、`starrail_avatar_compute`
- 绝区零专用表 5 张：`zzz_avatar_basic`、`zzz_daily_note`、`zzz_avatar_info`、`zzz_avatar_compute`、`zzz_buddy`
- 辅助表 1 张：`sync_meta`

**设计原则：**

- 所有表名通过 `TableName` enum 引用，**禁止**直接写表名字符串
- 所有列名通过对应的 `XxxCol` enum 引用，**禁止**在 DAO 中直接写列名字符串
- 所有表使用 `CREATE TABLE IF NOT EXISTS`，保证幂等性
- 通过 `account_id + role_uid` 实现多账号数据隔离
- `account_id` 是 `account_table.uid`（TEXT 类型，米游社 UID），所有子表通过 `ON DELETE CASCADE` 级联删除
- `sync_meta.data_type` 必须使用 `SyncDataType` 枚举，**禁止**字符串字面量
- 数据库使用 `SecurityLevel.S2` 加密，每次连接后必须执行 `PRAGMA foreign_keys = ON`

---

## 二、Repository 层规范

entry 层只能调用 Repository 的高层方法，**禁止**直接调用 DAO 或 ApiService。

### BBSRepository（`core/src/main/ets/repository/BBSRepository.ets`）

| 方法                                      | 说明                                                           |
| ----------------------------------------- | -------------------------------------------------------------- |
| `login(username, cookie)`                 | 完整登录流程：写账号 → 拉游戏角色 → 补 BBS 详情 → 触发同步队列 |
| `getAllAccounts()`                        | 读所有账号                                                     |
| `getAccountById(id)`                      | 按自增 id 查账号                                               |
| `getAccountByUsername(username)`          | 按 username 查账号                                             |
| `getAccountByUid(uid)`                    | 按米游社 UID 查账号                                            |
| `deleteAccount(uid)`                      | 删除账号（参数为米游社 UID，级联删除所有子表数据）             |
| `getGameRoles(accountId)`                 | 读账号下所有游戏角色（只返回 `SUPPORTED_GAMES` 中的游戏）      |
| `getGameRolesByGame(accountId, gameId)`   | 读账号下指定游戏的角色                                         |
| `refreshCookieIfNeeded(username, cookie)` | 用 stoken 刷新 ltoken/cookie_token，更新 DB                    |
| `getBbsAccountDetail(cookie)`             | 拉取米游社账号详情（nickname/avatarUrl/uid）                   |

> 注意：`deleteAccount` 接收的是 `uid: string`（米游社 UID），不是数据库自增 `id: number`。

### 游戏 Repository（原神/星铁/绝区零，继承自 `GameRepository`）

三个游戏 Repository 方法命名一致，以原神为例：

| 方法                                                   | 说明                                    |
| ------------------------------------------------------ | --------------------------------------- |
| `syncAvatarList(accountId, roleUid, server, cookie)`   | 拉取角色列表 → 解析 → 写 DB             |
| `syncDailyNote(accountId, roleUid, server, cookie)`    | 拉取便笺 → 写 DB（含 Geetest 降级逻辑） |
| `syncAvatarDetail(accountId, roleUid, server, cookie)` | 拉取角色详情 → 写 DB（原神/星铁）       |
| `syncAvatarInfo(accountId, roleUid, server, cookie)`   | 拉取角色详情 → 写 DB（绝区零）          |
| `syncBuddyList(accountId, roleUid, server, cookie)`    | 拉取邦布列表 → 写 DB（绝区零专有）      |
| `getAvatarList(accountId, roleUid)`                    | 读角色列表                              |
| `getDailyNote(accountId, roleUid)`                     | 读便笺                                  |
| `needsAvatarListSync(accountId, roleUid)`              | 检查角色列表是否需要同步                |
| `needsDailyNoteSync(accountId, roleUid)`               | 检查便笺是否需要同步                    |
| `upsertAvatarList(accountId, roleUid, rows)`           | 写角色列表（同时更新 sync_meta）        |
| `upsertDailyNote(accountId, roleUid, row)`             | 写便笺（同时更新 sync_meta）            |

---

## 三、SyncQueueRunner（持久化同步队列）

所有同步任务必须通过 `SyncQueueRunner` 执行，**禁止**直接调用 Repository 的 `sync*` 方法：

```typescript
// 正确
const tasks = SyncQueueRunner.buildTasksForRoles(accountId, roles, cookie);
await SyncQueueRunner.enqueue(tasks);
await SyncQueueRunner.runTasks(tasks);

// 错误 — 不持久化，App 被杀后丢失
await CoreInitializer.genshinRepository.syncAvatarList(...);
```

**sync_meta 状态流转：** `pending → syncing → success / failed`

**任务类型（`SyncDataType` 枚举值）：**

| 游戏   | 任务类型                                             |
| ------ | ---------------------------------------------------- |
| 原神   | `GENSHIN_CHARACTER_LIST`、`GENSHIN_CHARACTER_DETAIL` |
| 星铁   | `STARRAIL_AVATAR_BASIC`、`STARRAIL_AVATAR_INFO`      |
| 绝区零 | `ZZZ_AVATAR_BASIC`、`ZZZ_AVATAR_INFO`、`ZZZ_BUDDY`   |

App 启动时，`CoreInitializer.initCore()` 完成后自动调用 `SyncQueueRunner.resumeOnStartup()` 恢复 `pending`/`syncing` 状态的未完成任务。

---

## 四、数据流规范

```
API 响应 → Repository.parse*() → rawJson（原始格式）→ DB
DB → ViewModel / Parser → UI 展示模型
```

**禁止**在 Repository 层做任何 UI 相关的数据转换，`rawJson` 原样存储，由 ViewModel 或 Parser 负责解析为 UI 模型。

---

## 五、Cookie 存储规范

`cookie` 字段存完整字符串（手机号/二维码登录含 `stoken`；Cookie 登录存原始字符串）。`stoken`/`stuid`/`mid` 不作为独立字段存储。

Widget API 所需的 `stuid=xxx;stoken=xxx;mid=xxx` 格式通过 `BBSRepository.buildWidgetCookie(cookie)` 动态构造，不单独存储。
