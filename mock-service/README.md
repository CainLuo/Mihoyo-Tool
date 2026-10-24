# mock-service

Mihoyo-Tool 的本机 Mock HTTP 服务与 fixtures。当前 App 不连接此服务，也不参与 HAP 构建；后续可用 Swift-Vapor 实现 local service 并复用这里的 fixtures 与路由规则。

完整的 Mock 状态与 Swift-Vapor 迁移方案见
[`../Documents/Core-Kits-Refactor/Mock.md`](../Documents/Core-Kits-Refactor/Mock.md)。

零第三方依赖，只需要 Node.js 18+。

## 启动

```bash
cd mock-service
npm start
# 或：node server.mjs
```

默认监听 `http://127.0.0.1:8787`，延迟 300ms。

真机 / 模拟器需要把设备本机端口反向映射到开发机：

```bash
hdc rport tcp:8787 tcp:8787
```

> 默认监听 `http://127.0.0.1:8787`；客户端接入方案待定（计划 Swift-Vapor local service）。

## 常用参数

```bash
node server.mjs --port 8787        # 端口
node server.mjs --host 0.0.0.0     # 允许局域网访问（默认只监听 127.0.0.1）
node server.mjs --delay 0          # 关闭模拟延迟
node server.mjs --fixtures ./fixtures
```

> 走局域网时，客户端需把 base URL 指向开发机 IP；`hdc rport` 方案仅在未来客户端接入后使用。

健康检查：

```bash
curl http://127.0.0.1:8787/__health
```

## fixture 目录

```
fixtures/
└── {accountId}/
    ├── binding_api_getUserGameRolesByCookie.json       # 账号级
    ├── user_wapi_getUserFullInfo.json
    └── {roleId}/
        ├── game_record_app_genshin_api_dailyNote.json  # 角色级
        ├── game_record_app_hkrpg_api_note.json
        ├── 1171.json                                   # 绝区零角色详情
        └── avatar_compute/1001.json                    # 养成计算
```

路由优先级：

1. `{accountId}/{roleId}/{fileName}`
2. `{accountId}/{fileName}`
3. 找不到 → `{ retcode: 0, message: "success", data: {} }`

特殊映射（沿用原 Mock 路由约定，并补齐计算接口）：

| API 路径 | fixture 文件 |
| --- | --- |
| `/game_record/app/genshin/api/character/detail` | `game_record_app_genshin_api_character_detail_all.json` |
| `/game_record/app/hkrpg/api/avatar/basic` | `game_record_app_hkrpg_api_avatar_list.json` |
| `/game_record/app/hkrpg/api/avatar/info` | `game_record_app_hkrpg_api_avatar_detail_all.json` |
| `/event/game_record_zzz/api/zzz/buddy/info` | `event_game_record_zzz_api_zzz_buddy_list.json` |
| `/game_record/app/genshin/aapi/widget/v2` | `game_record_app_genshin_api_dailyNote.json` |
| `/game_record/app/hkrpg/aapi/widget` | `game_record_app_hkrpg_api_note.json` |
| `/event/game_record_zzz/api/zzz/widget` | `event_record_app_zzz_widget.json` |
| `/event/e20200928calculate/v3/batch_compute` | `genshin_character_batch_compute.json` |
| `/event/rpgcalc/compute` | `hkrpg_character_compute.json` |
| `/event/nap_cultivate_tool/avatar_calc` | `zzz_character_compute.json` |
| `/app/api/signIn` | `apihub_app_api_signIn.json` |

有 `avatarId` 的养成计算会优先使用
`{accountId}/{roleId}/avatar_compute/{avatarId}.json`；绝区零角色详情使用
`{accountId}/{roleId}/{avatarId}.json`。

> Widget 接口是账号级请求（不带 roleId）。当前只有 ZZZ 提供账号级
> `event_record_app_zzz_widget.json`；原神/星穹铁道的 fixture 都在角色目录下，
> 因此 Mock 下这两个 Widget 接口会返回空响应（与旧实现一致）。
>
> 绝区零目前没有 `avatar_compute/{avatarId}.json`，按角色计算会返回空响应
> （旧实现同样如此）；需要时从真实响应补充该目录。

## 账号 Mock

| 手机号 | 账号 |
| --- | --- |
| `13800138000` | `182692936` |
| `13800138001` | `348366494` |

- 验证码固定 `111111`，其他返回 `-3001`
- 二维码 `fetch` 返回假 URL，`query` 固定返回 `init`（不自动确认登录）
- Token 换取返回 `mock_ltoken_*` / `mock_cookie_token_*`

## 签到 Mock

当前仓库没有签到 fixture，所有签到接口返回空成功响应（`retcode: 0`）。
如需补充，按旧约定放到：

- `fixtures/{accountId}/apihub_app_api_signIn.json`（大别野）
- `fixtures/account{accountId}/event_luna_{hk4e|hkrpg|zzz}_{sign|info|home}.json`（游戏签到）

## RPC（调试用）

```bash
# 读取 fixture
curl -s -X POST http://127.0.0.1:8787/__mock/rpc \
  -H 'Content-Type: application/json' \
  -d '{"kind":"fixture","path":"/game_record/app/genshin/api/dailyNote","cookie":"account_id=182692936","roleId":"109050292"}'

# 手机号登录
curl -s -X POST http://127.0.0.1:8787/__mock/rpc \
  -H 'Content-Type: application/json' \
  -d '{"kind":"account","method":"loginByMobileCaptcha","mobile":"13800138000","captcha":"111111"}'
```

## 测试

```bash
cd mock-service
npm test
```

测试覆盖路径映射、账号提取、角色/计算路由、fixture 命中、账号登录与签到兜底。
