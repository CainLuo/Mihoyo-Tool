# 数据库架构设计文档

## 重要说明

本项目数据库已完成 V1.0 全新重构，**旧版通用表设计（`game_data`、`game_stats`、`QueryBuilder`、`Calculator`）已废弃**，请勿参考旧版内容。

**新版设计文档位置：**

- 数据库设计：`.kiro/specs/game-data-database-redesign/design.md`
- API 网络层设计：`.kiro/specs/mihoyo-api-redesign/design.md`
- Mock 环境设计：`.kiro/specs/mihoyo-mock-redesign/design.md`

## 新版架构概要

新版采用**按游戏类型分离的专用表**设计，共 15 张表：

- 基础表 2 张：`account_table`（含 `stoken`/`stuid`/`mid` 字段）、`game_role_table`
- 原神专用表 4 张：`genshin_character_list`、`genshin_daily_note`、`genshin_character_detail`、`genshin_character_compute`
- 星穹铁道专用表 4 张：`starrail_avatar_basic`、`starrail_daily_note`、`starrail_avatar_info`、`starrail_avatar_compute`
- 绝区零专用表 4 张：`zzz_avatar_basic`、`zzz_daily_note`、`zzz_avatar_info`、`zzz_avatar_compute`
- 辅助表 1 张：`sync_meta`

> 注意：各 compute 表已拆分为多个 JSON 字段（原神：`avatar_consume_json`/`skill_consume_json`/`weapon_consume_json`；星铁：`avatar_consume_json`/`skill_consume_json`/`equipment_consume_json`），不再使用单一的 `consume_items_json`。

## 新版代码目录结构

```
core/src/main/ets/
├── database/v2/
│   ├── RdbManagerV2.ets       ← 数据库管理器（建表 + 事务 + 写入队列）
│   ├── BBSDao.ets             ← 账号/角色表 DAO
│   ├── GenshinDao.ets         ← 原神四张表 DAO
│   ├── StarRailDao.ets        ← 星穹铁道四张表 DAO
│   ├── ZZZDao.ets             ← 绝区零四张表 DAO
│   └── SyncMetaDaoV2.ets      ← 同步状态 DAO（过渡期加 V2 后缀）
├── repository/v2/
│   ├── GameRepository.ets     ← 抽象基类（仅游戏数据）
│   ├── BBSRepository.ets      ← 账号 + 游戏角色（独立，不继承 GameRepository）
│   ├── GenshinRepository.ets
│   ├── StarRailRepository.ets
│   ├── ZZZRepository.ets
│   └── SignRepository.ets     ← 签到
├── network/v2/
│   ├── MihoyoDomain.ets       ← Domain 枚举（7 个 Host）
│   ├── MihoyoHeaderBuilder.ets← 请求头构建器（HeaderProfile 枚举）
│   ├── ApiConfigV2.ets        ← 应用配置常量（APP_VERSION、device_id/fp）
│   ├── DSUtilV2.ets           ← DS 动态签名生成
│   ├── MihoyoEnvironment.ets  ← 运行环境枚举（MOCK / RELEASE）
│   ├── MihoyoApiServiceFactory.ets ← Service 工厂
│   ├── MihoyoAccountApiService.ets
│   ├── GenshinApiService.ets
│   ├── StarRailApiService.ets
│   ├── ZZZApiService.ets
│   ├── SignApiService.ets
│   └── mock/                  ← Mock Service 实现
└── constants/
    └── SyncDataType.ets       ← sync_meta.data_type 枚举（禁止直接写字符串）

core/src/main/ets/errors/
└── ApiErrors.ets              ← 业务错误类型（AuthExpiredError / GeetestRequiredError 等）
```

## 模块边界原则（最高优先级）

**entry 模块严禁直接操作数据库，也不感知运行环境（mock/release）**，所有数据操作和环境适配必须通过 core 层 Repository 完成：

- entry ViewModel 只调用 Repository 的高层方法（如 `login()`、`syncDailyNote()`、`syncAvatarList()`）
- entry 不得 import `RdbManager`、任何 DAO 类、`Row` 模型（用于写入）
- entry 不得直接调用 `ApiService.getDailyNote()` 等网络方法后自己写 DB
- entry 不得判断 `isMock`、`APP_RUNTIME_ENV` 等环境变量做业务分支
- 唯一例外：`EntryAbility.onCreate` 负责从 `BuildProfile` 读取环境并通过 `CoreInitializer.initCore({ isMock })` 传给 core，这是 entry 唯一感知环境的地方
- mock 环境下的 username/cookie 替换逻辑由 `BBSRepository.login()` 内部处理，entry 传入原始值即可

数据流：entry ViewModel → core Repository（内部完成环境适配 + API 调用 + 解析 + DB 写入）→ 返回结果给 ViewModel

### BBSRepository 高层方法

| 方法                      | 说明                                                       |
| ------------------------- | ---------------------------------------------------------- |
| `login(username, cookie)` | 完整登录流程：写账号 + 拉角色 + 补详情，返回 `LoginResult` |
| `getAllAccounts()`        | 读所有账号                                                 |
| `getGameRoles(accountId)` | 读账号下所有游戏角色                                       |
| `deleteAccount(id)`       | 删除账号（级联删除所有子表数据）                           |

### 游戏 Repository 高层方法（三个游戏统一）

| 方法                                                 | 说明                        |
| ---------------------------------------------------- | --------------------------- |
| `syncAvatarList(accountId, roleUid, server, cookie)` | 拉取角色列表 → 解析 → 写 DB |
| `syncDailyNote(accountId, roleUid, server, cookie)`  | 拉取便笺 → 写 DB            |
| `getAvatarList(accountId, roleUid)`                  | 读角色列表                  |
| `getDailyNote(accountId, roleUid)`                   | 读便笺                      |
| `needsAvatarListSync(accountId, roleUid)`            | 检查是否需要同步            |
| `needsDailyNoteSync(accountId, roleUid)`             | 检查是否需要同步            |

1. **全新数据库，无旧表兼容，无迁移逻辑**（V1.0 起点）
2. 所有表使用 `CREATE TABLE IF NOT EXISTS`，保证幂等性
3. 通过 `account_id + role_uid` 实现多账号数据隔离
4. UI 直接显示 API 返回数据，DB 写入走后台异步队列（任务数组 + runner 协程，无 Promise 链增长）
5. `sync_meta.data_type` 必须使用 `SyncDataType` 枚举，禁止字符串字面量
6. Cookie 刷新：`stoken` 长期有效，`cookie_token`/`ltoken`/`ltoken_v2` 过期时用 `stoken` 自动刷新
7. 数据库使用 `SecurityLevel.S2` 加密，每次连接后必须执行 `PRAGMA foreign_keys = ON`
8. compute 接口和大别野签到接口的 mock 文件名不遵循自动映射规则，需要特殊映射表处理
