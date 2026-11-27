# 设计说明

## 背景

仓库里原本有一份 Node 版 Mock 服务（`mock-service/`：`server.mjs` + `router.mjs`），
App 侧通过它读取本地 fixture 调试。Swift + Vapor 版本的目标不是重写 App 逻辑，
而是提供一个**协议等价**的本地服务：App 把 base URL 指向 `http://127.0.0.1:8787`
即可，不需要恢复任何 Mock 适配器（Mock.md 方案 A：直连代理）。

原提交 `b7c7922` 的实现已确认不在对象库、reflog、stash、worktree、Trash、
LocalHistory 与 Time Machine 快照中，因此本目录是按 Node 契约重新实现的版本。

## 分层

```
MockServerCLI          ← 只做参数解析与启动
MockServerCore
├── Configuration      ServerConfiguration
├── Domain             JSONValue / MockRequest / MockResponse / AccountModels
├── Fixtures           FixturePathMapper → FixtureResolver → FixtureStore
├── Routing            QueryParameters / CookieParser / RequestRouter / FixtureRouter / SignMock
├── Validation         DynamicSecret / RequestValidator
└── App                MockRPCService / MockServerApplication（唯一 import Vapor 的地方）
```

约束：除 `App/MockServerApplication.swift` 外，核心层不依赖 Vapor。
好处是 204 个用例可以只喂 `MockRequest` 快照，不需要起端口。

## 请求流转

1. `MockServerApplication.makeSnapshot` 把 Vapor `Request` 转成 `MockRequest`
   （path + query、headers、body、remoteAddress）。
2. `RequestValidator.bodyLimitFailure` 在路由前拦下超大请求（默认 8 MiB → 400）。
3. `RequestRouter.route` 分类：`/` → serverInfo，`/__health` → health，
   `/__mock/rpc` → rpc，`OPTIONS` → preflight，其余 GET/POST → proxy，
   其他方法 → 404。
4. proxy 分支：`FixtureRouter` → `FixtureStore.lookup` → 命中返回原始字节，
   未命中返回空成功信封。
5. Vapor 层负责延迟（`--delay`）与响应头转换；核心分发不 sleep，单测才快。

## fixture 映射规则（parity 契约）

通用规则：去掉协议/域名/query → 去前导 `/` → `/` 换 `_` → 追加 `.json`。
因此根路径 `/` 的文件名是 `.json`（与 Node 版一致，属于历史行为，保留）。

`FixturePathMapper.specialFiles` 固定 11 条精确映射：

| API 路径 | fixture |
| --- | --- |
| `/app/api/signIn` | `apihub_app_api_signIn.json` |
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

候选路径固定两级：`{accountId}/{roleId}/{fileName}` → `{accountId}/{fileName}`。
养成计算（`compute` / `avatar_calc`）在有 avatarId 时把文件名换成
`avatar_compute/{avatarId}.json`；绝区零角色详情从 `id_list[]` 取第一个，
文件名直接用 `{avatarId}.json`。

## 关键行为对齐

| 行为 | 取值 |
| --- | --- |
| 账号提取 | `account_id` → `stuid` → `1`，数字取连续前缀（`1.5` → `1`） |
| 角色提取 | query `role_id` → query `uid` → body `role_id` → body `uid` |
| 未命中 fixture | `{"retcode":0,"message":"success","data":{}}` |
| 列表兜底 | `fallbackEmptyList=true` 时 `{"retcode":0,"message":"OK","data":{"list":[]}}` |
| 账号错误码 | 手机号未注册 `-3101`，验证码错误 `-3001`，未知方法 `-1` |
| 签到 | 已知方法无 fixture 时返回空成功信封；未知方法 400 |
| 响应头 | `application/json; charset=utf-8`、`Access-Control-Allow-Origin: *`、`Cache-Control: no-store` |
| 请求体上限 | 8 MiB（`--delay` 不影响该值） |

fixture 命中时返回文件**原始字节**，不经过 JSON 重新编码——
否则字段顺序与整数/浮点类型可能变化，App 的快照测试会失败。

## `DS` 动态签名：已知差异

需求里给出的固定向量：

```
query = role_id=1&server=cn_gf01
t     = 1700000000
r     = 123456
salt  = xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs
DS    = 1700000000,123456,ea56f3c12b77bcd23947635b9b4634f3
```

按公开的标准公式

```
md5("salt={salt}&{query}&t={timestamp}&r={nonce}")
```

计算得到 `e73e9e44da8e2c0a832a481d085aba5b`，与给定摘要不一致。
已穷举 864+ 种组合（query 顺序、空 query、`ts=` 变体、大小写 salt、
毫秒时间戳、MD5/SHA1/SHA256），没有一种能复现 `ea56f3c…`，
因此该摘要无法从公开规则反推——本实现**不伪造**它。

处理方式：

- `DynamicSecret.parse` / `isWellFormed` 把该向量当作**结构合法的样本请求头**
  来解析（3 段、纯数字时间戳与随机数、32 位小写十六进制摘要）。
- `DynamicSecretGenerator` 按标准公式生成与校验，金标为
  `e73e9e44da8e2c0a832a481d085aba5b`。
- mock 服务本身**不校验** `DS`。App 发来的仍是真实签名，
  服务只记录 / 回显；因此这一差异不影响联调，只影响「用 mock 生成签名」的场景。

如果后续确认了真实客户端额外的混淆步骤，应只修改
`Validation/DynamicSecret.swift` 的 `canonicalInput`，其余层无需改动。

## 安全与边界

- `FixtureStore.load` 先标准化路径再校验前缀，拒绝 `..`、绝对路径与反斜杠。
- 只监听 `127.0.0.1`；要暴露到局域网必须显式 `--host 0.0.0.0`。
- fixture 只读，服务不写任何文件。
