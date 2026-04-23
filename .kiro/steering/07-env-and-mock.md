# 环境与 Mock 规范

## 一、三个运行环境

| 环境      | `AppEnv` 枚举值  | 网络实现                      | 用途                           |
| --------- | ---------------- | ----------------------------- | ------------------------------ |
| `mock`    | `AppEnv.MOCK`    | MockService（读本地 rawfile） | 开发调试，不依赖真实服务器     |
| `debug`   | `AppEnv.DEBUG`   | ApiService（真实网络请求）    | 联调测试，可配合 Proxyman 抓包 |
| `release` | `AppEnv.RELEASE` | ApiService（真实网络请求）    | 生产环境，关闭调试日志         |

未知环境字符串 fallback 到 `DEBUG`（安全默认值：不误用 mock 数据，不关闭日志）。

新增环境时，只需修改两处：

1. `core/src/main/ets/constants/AppEnv.ets` — 添加枚举值和 `appEnvFromString()` 分支
2. `build-profile.json5` — 添加对应 `buildModeSet` 条目

---

## 二、环境注入规范

环境由 `entry` 在启动时注入，`core` 内部通过 `AppEnvManager` 读取，**禁止**在 ViewModel / Repository / 页面中直接判断环境：

```typescript
// EntryAbility.onCreate — 唯一允许读取 BuildProfile 的地方
await CoreInitializer.initCore(context, appEnvFromString(BuildProfile.APP_ENV));

// core 内部判断环境（仅限 core 层）
if (AppEnvManager.isMock()) { ... }

// 禁止在 entry 层判断
if (AppEnvManager.isMock()) { ... }  // ❌ entry 层禁止
```

---

## 三、Service 选择机制

`MihoyoApiServiceFactory` 根据 `AppEnv` 决定创建哪个 Service，对 Repository 层完全透明：

```
AppEnv.MOCK    → XxxMockService（继承 MockServiceBase）
AppEnv.DEBUG   → XxxApiService（真实 HTTP 请求）
AppEnv.RELEASE → XxxApiService（真实 HTTP 请求）
```

每种游戏/功能对应一对 Service：

| 功能      | Mock Service               | API Service               |
| --------- | -------------------------- | ------------------------- |
| 账号/登录 | `MihoyoAccountMockService` | `MihoyoAccountApiService` |
| 原神      | `GenshinMockService`       | `GenshinApiService`       |
| 星穹铁道  | `StarRailMockService`      | `StarRailApiService`      |
| 绝区零    | `ZZZMockService`           | `ZZZApiService`           |
| 签到      | `SignMockService`          | `SignApiService`          |

**修改 Mock Service 不得影响 API Service**，两者只共享 `MihoyoApiService` 抽象接口，实现完全独立。

---

## 四、Mock 文件规范

### 文件位置

```
core/src/mock/resources/rawfile/mock/
└── {account_id}/                    ← 米游社账号 UID（从 Cookie 的 account_id 字段提取）
    ├── {role_uid}/                  ← 游戏角色 UID（角色级接口）
    │   └── {file_name}.json
    └── {file_name}.json             ← 账号级接口（无 role_uid）
```

### 文件名规则

URL 路径去掉 query 参数后，将 `/` 替换为 `_`，去掉开头的 `_`，加 `.json` 后缀：

```
/game_record/app/genshin/api/dailyNote  →  game_record_app_genshin_api_dailyNote.json
/user/wapi/getUserFullInfo              →  user_wapi_getUserFullInfo.json
```

### 特殊映射表（优先于通用规则）

| URL 路径                                        | 映射文件名                                                          |
| ----------------------------------------------- | ------------------------------------------------------------------- |
| `/event/e20200928calculate/v3/batch_compute`    | `genshin_character_batch_compute.json`                              |
| `/event/rpgcalc/compute`                        | `hkrpg_character_compute.json`                                      |
| `/event/nap_cultivate_tool/avatar_calc`         | `zzz_character_compute.json`                                        |
| `/app/api/signIn`                               | `apihub_app_api_signIn.json`                                        |
| `/game_record/app/genshin/api/character/detail` | `game_record_app_genshin_api_character_detail_all.json`             |
| `/game_record/app/hkrpg/api/avatar/basic`       | `game_record_app_hkrpg_api_avatar_list.json`                        |
| `/game_record/app/hkrpg/api/avatar/info`        | `game_record_app_hkrpg_api_avatar_detail_all.json`                  |
| `/event/game_record_zzz/api/zzz/buddy/info`     | `event_game_record_zzz_api_zzz_buddy_list.json`                     |
| `/game_record/app/genshin/aapi/widget/v2`       | `game_record_app_genshin_api_dailyNote.json`（Widget 复用便笺文件） |
| `/game_record/app/hkrpg/aapi/widget`            | `game_record_app_hkrpg_api_note.json`                               |
| `/event/game_record_zzz/api/zzz/widget`         | `event_game_record_zzz_api_zzz_note.json`                           |

### 绝区零单角色详情的特殊规则

绝区零角色详情按 `avatarId` 单独请求，文件名直接用 `{avatarId}.json`，放在 `{account_id}/{role_uid}/` 目录下。

### 文件查找优先级

1. `mock/{account_id}/{role_uid}/{file_name}.json`（角色级，有 roleId 时优先）
2. `mock/{account_id}/{file_name}.json`（账号级）
3. 文件不存在时返回空响应 `{ retcode: 0, message: 'success', data: {} }`，并记录 warning 日志

### 新增 Mock 数据文件

1. 确认接口 URL，用 `MockServiceBase.pathToFileName()` 推算文件名（或查特殊映射表）
2. 将 JSON 文件放到对应账号/角色目录下
3. 如果是新接口且通用规则映射的文件名不直观，在 `MockServiceBase.pathToFileName()` 的 `specialMap` 中添加映射

---

## 五、Mock Service 开发规范

- **禁止**在 Mock Service 中发起真实 HTTP 请求
- Mock Service 统一继承 `MockServiceBase`，通过 `readMockFile(path, cookie, roleId?)` 读取本地文件
- Mock Service 会模拟 300ms 网络延迟（`MOCK_DELAY_MS = 300`），保持与真实网络行为一致
- 修改 Mock Service 逻辑时，**不得修改** `MihoyoApiService` 抽象接口或 API Service 实现
- Mock Service 需要 `UIAbilityContext` 来访问 rawfile，通过构造函数注入，不得全局存储
