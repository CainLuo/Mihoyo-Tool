# 环境与 Mock 规范

## 一、构建环境

`AppEnv` 保留三个枚举值，但 **MOCK 当前没有任何逻辑分支使用**：

| 构建方式 | `BuildProfile.APP_ENV` | Core `AppEnv` | 说明 |
| -------- | ---------------------- | ------------- | ---- |
| `mock` product | `mock` | `AppEnv.MOCK` | mock env；独立 `.mock` 包 |
| `debug` product | `debug` | `AppEnv.DEBUG` | 真实 API |
| `internal` product | `debug` | `AppEnv.DEBUG` | 真实 API |
| `release` / `default` product | `release` | `AppEnv.RELEASE` | 真实 API |

`mock` product 保留，生成独立 `.mock` 包；原独立 `mock/` ArkTS 源码目录已删除。

- `AppEnv.MOCK` 与 `AppEnvManager.isMock()` **保留**（兼容历史调用与未来恢复），
  但 Core / entry 中没有任何分支依赖它们。
- `appEnvFromString('mock')` 仍然返回 `AppEnv.MOCK`。
- 构建配置中保留 `mock` product；使用 `-p product=mock`（或 `bash run.sh mock`）。
  `buildMode=mock` 仅用于 `test-core.sh` / `test-entry.sh` 的 ohosTest 构建，不是 App 包。
- `entry/src/main/ets/config/RuntimeConfig.ets` 是唯一读取 `BuildProfile.APP_ENV` 的地方。

---

## 二、Service 创建规范

`CoreInitializer.initCore({ env, context })` 只接收环境与上下文，
**不接受任何 Service 注入**：

```typescript
// entry
CoreInitializer.initCore({ env: APP_ENV, context: this.context });

// core
const accountService = MihoyoApiServiceFactory.createAccountService();
// genshin / starRail / zzz / sign 同理
```

- `MihoyoApiServiceFactory` 只创建真实 API Service，没有 Mock 分支。
- `NetworkFactory` 当前仍默认创建 `HttpService`，没有注入入口；Phase 1.1 BaseApiService 迁移完成后，`NetworkFactory` / `HttpService` 会删除，非 Service 调用方改走 `BaseApiService.shared`。
- Core 不 import 任何 Mock 类；entry 不 import 任何 Mock 类。

---

## 三、Mock 代码现状

- Core 与 entry 中没有任何 Mock 适配器、工厂分支或注入入口。
- 跑 mock env：`bash run.sh mock`；构建独立 `.mock` 包（`APP_ENV=mock`）。
- 原独立 `mock/` ArkTS 适配器目录已删除，不要重新创建。
- `AppEnv.MOCK` / `AppEnvManager.isMock()` 保留，但当前没有逻辑分支使用。
- 仅保留 `mock-service/`（零依赖 Node HTTP 服务 + fixtures），作为独立数据服务；它不参与 HAP 构建，App 当前也未接入。
- 后续计划用 Swift-Vapor 实现 local service，复用 `mock-service/fixtures/` 与 `router.mjs` 的路由规则；客户端接入层需要重新设计，不要直接把 Mock 代码放回 core/entry。
- 完整的 Mock 状态、fixture 契约与 Swift-Vapor 迁移阶段见
  [`Documents/Core-Kits-Refactor/Mock.md`](../../Documents/Core-Kits-Refactor/Mock.md)。
- `MihoyoAccountApiService` 自己负责手机号/区号的 RSA 加密，`AuthRepository` 不判断环境。

---

## 四、Mock 服务与数据

`mock-service/` 当前是独立 Node 服务，仅用于 fixtures 路由测试和未来 local service 的参考，不是 HAP 的一部分。

### 启动服务

```bash
cd mock-service
npm start          # 默认 http://127.0.0.1:8787，延迟 300ms

# 健康检查
curl http://127.0.0.1:8787/__health
```

App 当前未接入该服务；`hdc rport tcp:8787 tcp:8787` 只有在客户端实现后才需要。

### 数据目录

```
mock-service/fixtures/
└── {accountId}/                    ← 米游社账号 UID（从 Cookie 的 account_id / stuid 提取）
    ├── {roleId}/                   ← 游戏角色 UID（角色级接口）
    │   ├── {file_name}.json
    │   └── avatar_compute/{avatarId}.json
    └── {file_name}.json            ← 账号级接口
```

### 文件名规则

URL 路径去掉协议/域名和 query 参数后，去掉开头的 `/`，将 `/` 替换为 `_`，加 `.json` 后缀：

```
/game_record/app/genshin/api/dailyNote  →  game_record_app_genshin_api_dailyNote.json
/user/wapi/getUserFullInfo              →  user_wapi_getUserFullInfo.json
```

特殊映射表在 `mock-service/router.mjs` 的 `SPECIAL_FILES` 中，优先于通用规则。当前包括：

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
| `/event/game_record_zzz/api/zzz/widget`         | `event_record_app_zzz_widget.json`                                  |

### 路由规则

- 账号：Cookie 中优先 `account_id`，其次 `stuid`，缺失时兜底 `1`。
- 角色：优先使用调用方传入的 `roleId`，否则从 query/body 取 `role_id` / `uid`。
- 绝区零角色详情：从 query 的 `id_list[]` 取第一个作为 `avatarId`，文件名为 `{avatarId}.json`。
- 养成计算：有 `avatarId` 时优先 `avatar_compute/{avatarId}.json`。
- 查找顺序：`{accountId}/{roleId}/{fileName}` → `{accountId}/{fileName}`。
- 文件不存在时返回空响应 `{ retcode: 0, message: 'success', data: {} }`。
- 服务端只负责返回 fixture；非 0 retcode 的异常处理由未来客户端接入层决定。

### 新增 Mock 数据文件

1. 确认接口 URL，用 `pathToFileName` 规则或 `SPECIAL_FILES` 推算文件名。
2. 将 JSON 文件放到对应 `{accountId}/{roleId}/` 或 `{accountId}/` 目录。
3. 如果是新接口且通用规则映射的文件名不直观，在 `router.mjs` 的 `SPECIAL_FILES` 中添加映射。
4. 补充 `mock-service/tests/router.test.mjs` 的覆盖（如果路由/映射有变化）。

---

## 五、开发规范

- **禁止**把 Mock 代码放回 `core` 或 `entry`；独立 `mock/` 目录也已删除，不要恢复。
- 客户端接入方案确定前，`mock-service/` 只作为独立数据服务维护。
- **禁止**在 Mock Service 中发起真实 HTTP 请求。
- 服务端默认模拟 300ms 延迟（`--delay 0` 可关闭），保持与真实网络行为一致。
- Mock 代码不得修改 `MihoyoApiService` 抽象接口或真实 API Service 实现。
- 服务端路由测试用 Node 自带 test runner：

```bash
cd mock-service
npm test
```

### 明文 HTTP

当前项目未配置 `network_config.json`。HarmonyOS 文档中 `2300997` 只说明「应用显式禁止明文」时会触发；真机首次运行时仍需确认。如果 127.0.0.1 请求被拦截，再补
`network_config.json` 并在 `module.json5` 中注册 metadata，不要提前猜测字段。

---

## 六、当前 Mock 行为摘要

- 手机号：`13800138000 → 182692936`，`13800138001 → 348366494`。
- 验证码固定 `111111`，其他返回 `-3001`。
- 二维码：`fetch` 返回假 URL，`query` 固定返回 `init`（不自动确认）。
- 签到：仓库中没有签到 fixture，所有签到接口返回空成功响应。
- 缺失 fixture：返回 `retcode: 0` 空 data，不抛错；客户端接入后需自行处理非 0 retcode。
