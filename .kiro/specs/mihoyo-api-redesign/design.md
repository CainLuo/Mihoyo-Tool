# 设计文档：mihoyo-api-redesign

## 命名说明（V2 后缀的由来）

同 `game-data-database-redesign/design.md` 中的说明，`network/v2/` 目录和 `DSUtilV2`、`ApiConfigV2` 等命名均为过渡期临时命名，旧代码删除后统一去掉 `V2` 后缀。

---

## 概述

重新设计 core module 的网络层，将 API 请求按游戏类型分离为独立的 Service 类，通过共同的抽象基类实现多态。同时将 Domain 和 API Path 提取为独立的枚举文件。

**设计原则：**

- 新代码统一放在 `core/src/main/ets/network/v2/` 目录下
- 通过抽象基类 `MihoyoApiService` 约束所有 Service，实现多态
- Domain 和 API Path 各自独立枚举，按游戏分离

---

## 架构

```
MihoyoApiService（抽象基类）
    │
    ├── MihoyoAccountApiService   → 米游社账号相关（游戏角色绑定、战绩卡片、BBS 账号详情）
    ├── GenshinApiService         → 原神（便笺、角色列表、角色详情、养成计算）
    ├── StarRailApiService        → 星穹铁道（便笺、角色列表、角色详情、养成计算）
    ├── ZZZApiService             → 绝区零（便笺、代理人列表、代理人详情、养成计算）
    └── SignApiService            → 签到（大别野 + 各游戏每日签到）
```

每个 Service 内部持有对应的 Domain，通过底层 `HttpService` 发起实际请求。

---

## 文件结构

```
core/src/main/ets/network/v2/
├── MihoyoDomain.ets              ← Domain 枚举（7 个 Host，含 BBS_APIHUB/PASSPORT/PASSPORT_V4）
├── MihoyoAccountApiPath.ets      ← 米游社账号 API Path 枚举
├── PassportApiPath.ets           ← Passport API Path 枚举（Cookie 刷新）
├── GenshinApiPath.ets            ← 原神 API Path 枚举
├── StarRailApiPath.ets           ← 星穹铁道 API Path 枚举
├── ZZZApiPath.ets                ← 绝区零 API Path 枚举
├── SignApiPath.ets               ← 签到 API Path 枚举（大别野 + 各游戏）
├── MihoyoApiService.ets          ← 抽象基类（多态协议）
├── MihoyoHeaderBuilder.ets       ← 请求头构建器（HeaderProfile 枚举 + build()）
├── ApiConfigV2.ets               ← 应用配置常量（APP_VERSION、USER_AGENT、device_id/fp 管理）
├── DSUtilV2.ets                  ← DS 动态签名生成（salt 注入 + V1/V2/X6 三种签名）
├── MihoyoEnvironment.ets         ← 运行环境枚举（MOCK / RELEASE）
├── MihoyoApiServiceFactory.ets   ← Service 工厂（根据环境创建对应 Service 实例）
├── MihoyoAccountApiService.ets   ← 米游社账号 API Service（含 Geetest + Cookie 刷新）
├── GenshinApiService.ets         ← 原神 API Service
├── StarRailApiService.ets        ← 星穹铁道 API Service
├── ZZZApiService.ets             ← 绝区零 API Service
└── SignApiService.ets            ← 签到 API Service（大别野 + 各游戏统一入口）

core/src/main/ets/errors/
└── ApiErrors.ets                 ← 业务错误类型（AuthExpiredError / GeetestRequiredError 等）
```

---

## ArkTS 严格模式已知限制与规避方案

本设计在实现时必须遵守以下 ArkTS 严格模式限制，违反会导致 hvigor 编译失败：

| 限制                                       | 规避方案                                                                                          |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| `catch (e)` 的 `e` 类型为 `Object`         | 先 `instanceof` 判断，再 `as` 类型断言访问字段；禁止直接 `e.message`                              |
| 禁止 `throw 'string'`                      | 只允许 `throw new Error('message')`                                                               |
| 禁止 `unknown` 类型                        | 改用 `Object` 或具体类型                                                                          |
| 禁止 `Array.map()` / `Array.filter()`      | 用 `for` 循环替代（DSUtilV2 的 query 参数排序已使用此方案）                                       |
| 禁止 `spread` 展开运算符（`...obj`）       | 逐字段赋值                                                                                        |
| 禁止无类型对象字面量作为 `static readonly` | 先声明 class，再 `new` 实例化（如 `ViewModelKeys` 模式）                                          |
| 禁止 `!` 非空断言（`value!`）              | 改为显式 `if (value === null) { return; }` 检查，或用 `if (value !== null)` 分支                  |
| `null` 字段必须联合类型声明                | `private field: Type \| null = null`（如 `readyResolve`、`service`、`geetestResolve`）            |
| `abstract class` 支持                      | ArkTS 支持 `abstract class` 和 `abstract method`，`GameRepository` 和 `MihoyoApiService` 均可使用 |
| `Promise.race` 泛型                        | 必须明确泛型参数 `Promise.race<T>([...])`，数组元素类型必须一致                                   |
| `Array.shift()` 返回 `T \| undefined`      | 必须判断 `undefined`，或改用 `splice(0, 1)[0]` 后判断                                             |
| 对象字面量赋值（如 `GeetestCreateResult`） | 禁止 `const x: T = { ... }` 字面量，改为 `const x = new T(); x.field = value`                     |

---

## 数据模型

### Domain 枚举

从 `mihoyo_apis.md` 提取出 7 个不同的 Host：

```typescript
// core/src/main/ets/network/v2/MihoyoDomain.ets
export enum MihoyoDomain {
  /** 米游社游戏记录 API（原神/星铁/绝区零 游戏数据） */
  TAKUMI_RECORD = "https://api-takumi-record.mihoyo.com",
  /** 米游社主 API（养成计算、账号绑定、游戏签到等） */
  TAKUMI = "https://api-takumi.mihoyo.com",
  /** 米游社 BBS API（账号详情、Geetest 验证） */
  BBS = "https://bbs-api.miyoushe.com",
  /**
   * 米游社 BBS ApiHub（大别野签到、米游币任务）
   * 注意：这是独立的 URL 前缀，不是 BBS 的子路径。
   * 大别野签到完整 URL = BBS_APIHUB + SignApiPath.SIGN_BBS
   *   = "https://bbs-api.miyoushe.com/apihub/app/api/signIn"
   */
  BBS_APIHUB = "https://bbs-api.miyoushe.com/apihub",
  /** 绝区零养成计算专用 */
  ACT_TAKUMI = "https://act-api-takumi.mihoyo.com",
  /** Passport API（Cookie 刷新：cookie_token / ltoken） */
  PASSPORT = "https://passport-api.mihoyo.com",
  /** Passport V4 API（ltoken 验证） */
  PASSPORT_V4 = "https://passport-api-v4.mihoyo.com",
}
```

### API Path 枚举

```typescript
// core/src/main/ets/network/v2/MihoyoAccountApiPath.ets
export enum MihoyoAccountApiPath {
  /** 游戏战绩卡片（含背景图、统计数据）— Domain: TAKUMI_RECORD */
  GET_GAME_RECORD_CARD = "/game_record/app/card/wapi/getGameRecordCard",
  /** BBS 账号详情（昵称、头像、简介）— Domain: BBS */
  GET_USER_FULL_INFO = "/user/api/getUserFullInfo",
  /** 游戏角色绑定列表 — Domain: TAKUMI（注意：不是 TAKUMI_RECORD） */
  GET_GAME_ROLES = "/binding/api/getUserGameRolesByCookie",
  /** 申请 Geetest 验证任务 — Domain: BBS */
  CREATE_VERIFICATION = "/misc/api/createVerification",
  /** 提交 Geetest 验证结果，换取新 challenge — Domain: BBS */
  VERIFY_VERIFICATION = "/misc/api/verifyVerification",
}

// core/src/main/ets/network/v2/GenshinApiPath.ets
export enum GenshinApiPath {
  /** 实时便笺 */
  DAILY_NOTE = "/game_record/app/genshin/api/dailyNote",
  /** 角色列表 */
  CHARACTER_LIST = "/game_record/app/genshin/api/character/list",
  /** 角色详情 */
  CHARACTER_DETAIL = "/game_record/app/genshin/api/character/detail",
  /** 养成材料批量计算 */
  BATCH_COMPUTE = "/event/e20200928calculate/v3/batch_compute",
}

// core/src/main/ets/network/v2/StarRailApiPath.ets
export enum StarRailApiPath {
  /** 实时便笺 */
  DAILY_NOTE = "/game_record/app/hkrpg/api/note",
  /** 角色列表 */
  AVATAR_BASIC = "/game_record/app/hkrpg/api/avatar/basic",
  /** 角色详情 */
  AVATAR_INFO = "/game_record/app/hkrpg/api/avatar/info",
  /** 养成材料计算 */
  COMPUTE = "/event/rpgcalc/compute",
}

// core/src/main/ets/network/v2/ZZZApiPath.ets
export enum ZZZApiPath {
  /** 实时便笺 */
  DAILY_NOTE = "/event/game_record_zzz/api/zzz/note",
  /** 代理人列表 */
  AVATAR_BASIC = "/event/game_record_zzz/api/zzz/avatar/basic",
  /** 代理人详情 */
  AVATAR_INFO = "/event/game_record_zzz/api/zzz/avatar/info",
  /** 养成材料计算 */
  COMPUTE = "/event/nap_cultivate_tool/avatar_calc",
}
```

### 抽象基类

```typescript
// core/src/main/ets/network/v2/MihoyoApiService.ets
import { RequestParams, RequestOptions } from "../APIs";

export abstract class MihoyoApiService {
  /** GET 请求 */
  abstract get(
    path: string,
    params?: RequestParams,
    options?: RequestOptions,
  ): Promise<object>;
  /**
   * POST 请求
   * @param data POST body：JSON 字符串（推荐）或 RequestParams（Map 形式，由 HttpService 序列化）
   *             各 Service 子类统一使用 JSON.stringify() 序列化后传入字符串
   */
  abstract post(
    path: string,
    data?: string | RequestParams,
    options?: RequestOptions,
  ): Promise<object>;
}
```

### 各 Service 方法签名

**MihoyoAccountApiService：**

| 方法                                | HTTP | Domain        | Path                                         |
| ----------------------------------- | ---- | ------------- | -------------------------------------------- |
| `getGameRoles(cookie)`              | GET  | TAKUMI        | `MihoyoAccountApiPath.GET_GAME_ROLES`        |
| `getGameRecordCard(uid, cookie)`    | GET  | TAKUMI_RECORD | `MihoyoAccountApiPath.GET_GAME_RECORD_CARD`  |
| `getUserFullInfo(uid, cookie)`      | GET  | BBS           | `MihoyoAccountApiPath.GET_USER_FULL_INFO`    |
| `createVerification(cookie)`        | GET  | BBS           | `MihoyoAccountApiPath.CREATE_VERIFICATION`   |
| `verifyVerification(input, cookie)` | POST | BBS           | `MihoyoAccountApiPath.VERIFY_VERIFICATION`   |
| `refreshCookieToken(stoken, stuid)` | GET  | PASSPORT      | `PassportApiPath.GET_COOKIE_TOKEN_BY_STOKEN` |
| `refreshLToken(stoken, stuid)`      | GET  | PASSPORT      | `PassportApiPath.GET_LTOKEN_BY_STOKEN`       |
| `verifyLToken(ltoken, ltuid)`       | POST | PASSPORT_V4   | `PassportApiPath.VERIFY_LTOKEN`              |

**GenshinApiService：**

| 方法                                                       | HTTP | Domain        | Path               |
| ---------------------------------------------------------- | ---- | ------------- | ------------------ |
| `getDailyNote(roleId, server, cookie)`                     | GET  | TAKUMI_RECORD | `DAILY_NOTE`       |
| `getCharacterList(roleId, server, cookie)`                 | POST | TAKUMI_RECORD | `CHARACTER_LIST`   |
| `getCharacterDetail(roleId, server, characterIds, cookie)` | POST | TAKUMI_RECORD | `CHARACTER_DETAIL` |
| `batchCompute(items, uid, region, cookie)`                 | POST | TAKUMI        | `BATCH_COMPUTE`    |

**StarRailApiService：**

| 方法                                              | HTTP | Domain        | Path           |
| ------------------------------------------------- | ---- | ------------- | -------------- |
| `getDailyNote(roleId, server, cookie)`            | GET  | TAKUMI_RECORD | `DAILY_NOTE`   |
| `getAvatarBasic(roleId, server, cookie)`          | GET  | TAKUMI_RECORD | `AVATAR_BASIC` |
| `getAvatarInfo(roleId, server, id, cookie)`       | GET  | TAKUMI_RECORD | `AVATAR_INFO`  |
| `compute(avatar, skillList, uid, region, cookie)` | POST | TAKUMI        | `COMPUTE`      |

**ZZZApiService：**

| 方法                                                                                                     | HTTP | Domain        | Path           |
| -------------------------------------------------------------------------------------------------------- | ---- | ------------- | -------------- |
| `getDailyNote(roleId, server, cookie)`                                                                   | GET  | TAKUMI_RECORD | `DAILY_NOTE`   |
| `getAvatarBasic(roleId, server, cookie)`                                                                 | GET  | TAKUMI_RECORD | `AVATAR_BASIC` |
| `getAvatarInfo(roleId, server, idList, cookie)`                                                          | GET  | TAKUMI_RECORD | `AVATAR_INFO`  |
| `compute(avatarId, avatarLevel, avatarCurrentLevel, avatarCurrentPromotes, skills, uid, region, cookie)` | POST | ACT_TAKUMI    | `COMPUTE`      |

> 注意：`idList` 参数序列化为 URL 时使用 PHP 风格数组格式：`id_list[]=1171&id_list[]=1141`（每个 ID 单独一个 `id_list[]` 参数），不是逗号分隔。绝区零养成计算需要传入代理人等级相关参数（`avatarLevel`、`avatarCurrentLevel`、`avatarCurrentPromotes`），对应请求体字段 `avatar_level`、`avatar_current_level`、`avatar_current_promotes`。

---

## API 与 Domain 完整对应关系

| API 功能           | Domain        | Path                                                                  |
| ------------------ | ------------- | --------------------------------------------------------------------- |
| 游戏角色绑定列表   | TAKUMI        | `MihoyoAccountApiPath.GET_GAME_ROLES`                                 |
| 游戏战绩卡片       | TAKUMI_RECORD | `MihoyoAccountApiPath.GET_GAME_RECORD_CARD`                           |
| BBS 账号详情       | BBS           | `MihoyoAccountApiPath.GET_USER_FULL_INFO`                             |
| 申请 Geetest 验证  | BBS           | `MihoyoAccountApiPath.CREATE_VERIFICATION`                            |
| 提交 Geetest 验证  | BBS           | `MihoyoAccountApiPath.VERIFY_VERIFICATION`                            |
| 刷新 cookie_token  | PASSPORT      | `PassportApiPath.GET_COOKIE_TOKEN_BY_STOKEN`                          |
| 刷新 ltoken        | PASSPORT      | `PassportApiPath.GET_LTOKEN_BY_STOKEN`                                |
| 验证 ltoken 有效性 | PASSPORT_V4   | `PassportApiPath.VERIFY_LTOKEN`                                       |
| 原神实时便笺       | TAKUMI_RECORD | `GenshinApiPath.DAILY_NOTE`                                           |
| 原神角色列表       | TAKUMI_RECORD | `GenshinApiPath.CHARACTER_LIST`                                       |
| 原神角色详情       | TAKUMI_RECORD | `GenshinApiPath.CHARACTER_DETAIL`                                     |
| 原神养成计算       | TAKUMI        | `GenshinApiPath.BATCH_COMPUTE`                                        |
| 星铁实时便笺       | TAKUMI_RECORD | `StarRailApiPath.DAILY_NOTE`                                          |
| 星铁角色列表       | TAKUMI_RECORD | `StarRailApiPath.AVATAR_BASIC`                                        |
| 星铁角色详情       | TAKUMI_RECORD | `StarRailApiPath.AVATAR_INFO`                                         |
| 星铁养成计算       | TAKUMI        | `StarRailApiPath.COMPUTE`                                             |
| 绝区零实时便笺     | TAKUMI_RECORD | `ZZZApiPath.DAILY_NOTE`                                               |
| 绝区零代理人列表   | TAKUMI_RECORD | `ZZZApiPath.AVATAR_BASIC`                                             |
| 绝区零代理人详情   | TAKUMI_RECORD | `ZZZApiPath.AVATAR_INFO`                                              |
| 绝区零养成计算     | ACT_TAKUMI    | `ZZZApiPath.COMPUTE`                                                  |
| 大别野每日签到     | BBS_APIHUB    | `SignApiPath.SIGN_BBS`                                                |
| 原神每日签到       | TAKUMI        | `SignApiPath.SIGN_GAME_BASE + "/hk4e/sign"`                           |
| 星铁每日签到       | TAKUMI        | `SignApiPath.SIGN_GAME_BASE + "/hkrpg/sign"`                          |
| 绝区零每日签到     | TAKUMI        | `SignApiPath.SIGN_GAME_BASE + "/zzz/sign"`                            |
| 获取签到状态       | TAKUMI        | `SignApiPath.SIGN_GAME_BASE + "/{host}/info"`（host 由 gameBiz 决定） |
| 获取今日签到奖励   | TAKUMI        | `SignApiPath.SIGN_GAME_BASE + "/{host}/home"`（host 由 gameBiz 决定） |

---

## 正确性属性

### Property 1：多态调用一致性

对任意 `MihoyoApiService` 的子类实例，调用 `get()` 和 `post()` 方法应返回 `Promise<object>`，不抛出类型错误。

### Property 2：Domain 与 Path 组合唯一性

对任意 API 功能，`(Domain, Path)` 组合在整个系统中唯一，不存在两个不同功能使用相同组合的情况。

### Property 3：Cookie 注入隔离

对任意两个不同账号的 cookie，同时发起相同 API 请求，两次请求的 Cookie 头互不干扰。

---

## 错误处理

| 错误场景                    | 处理方式                                                       |
| --------------------------- | -------------------------------------------------------------- |
| 网络请求超时                | 抛出 `Error('Request timeout: ${path}')`，调用方更新 sync_meta |
| API 返回非 0 retcode        | 抛出 `Error('retcode=${retcode}: ${message}')`，调用方处理     |
| Cookie 失效（retcode=-100） | 抛出特定错误，调用方通知 UI 重新登录                           |
| Domain 枚举值无效           | 编译期类型检查，不会运行时出现                                 |
| Path 枚举值无效             | 编译期类型检查，不会运行时出现                                 |
| JSON 解析失败               | 抛出 `Error('Response parse failed: ${path}')`，调用方处理     |

---

## 测试策略

### 单元测试

- 验证每个 Service 的方法调用正确的 Domain + Path 组合
- 验证 Cookie 正确注入到请求头
- 验证 GET 参数正确拼接到 URL
- 验证 POST body 正确序列化

### 属性测试

| 属性编号 | 描述            | 生成器                                     |
| -------- | --------------- | ------------------------------------------ |
| P1       | 多态调用一致性  | 随机选择 Service 子类，随机 path 和 params |
| P2       | Cookie 注入隔离 | 随机两个不同 cookie，并发发起相同请求      |
| P3       | 请求参数完整性  | 随机 params，验证序列化后可完整还原        |

---

## DS 动态签名生成

### 背景

米游社 API 使用 DS（Dynamic Secret）作为防爬虫机制，每次请求必须在请求头中携带 `DS` 字段。DS 由时间戳、随机字符串和 MD5 签名组成，签名内容包含 salt、时间戳、随机串、请求 body 和 query 参数。

### DS 格式

```
DS: {timestamp},{random},{md5}
md5 = MD5("salt={salt}&t={timestamp}&r={random}&b={body}&q={query}")
```

- `timestamp`：Unix 秒级时间戳
- `random`：6 位随机字母数字字符串
- `body`：POST 请求的 JSON body 字符串（GET 请求为空字符串）
- `query`：GET 请求的查询参数字符串，格式为 `key1=val1&key2=val2`（按字典序排列，POST 请求为空字符串）

### Salt 版本

不同接口使用不同的 salt，目前已知三个版本：

| Salt 版本 | 适用接口                                    | 说明                |
| --------- | ------------------------------------------- | ------------------- |
| `salt_v1` | 游戏记录接口（便笺、角色列表、角色详情等）  | GAME_RECORD Profile |
| `salt_v2` | BBS 接口（账号详情、游戏角色绑定、Geetest） | BBS Profile         |
| `salt_x6` | 签到接口（大别野签到、游戏每日签到）        | SIGN Profile        |

> 注意：从真实抓包数据观察到 GAME_RECORD Profile 的 DS `random` 字段为纯数字，BBS Profile 为字母数字混合。这可能反映了不同 salt 版本的规律，但 DS 签名验证只校验 MD5 是否匹配，不校验 `random` 的格式，因此统一使用字母数字混合在技术上是安全的。实现后如发现 GAME_RECORD 接口拒绝请求，可尝试改为纯数字 `random`。

### Service 层集成

DS 生成由 `MihoyoHeaderBuilder` 在 `GAME_RECORD` 和 `BBS` Profile 下自动注入，`CALCULATE` Profile 不携带 DS。各 Service 子类通过调用 `MihoyoHeaderBuilder.build()` 时传入正确的 Profile 来控制是否生成 DS，无需手动调用 `DSUtil`：

```typescript
// GAME_RECORD Profile → 自动注入 DS
const headers = MihoyoHeaderBuilder.build(
  HeaderProfile.GAME_RECORD,
  cookie,
  params,
);

// CALCULATE Profile → 不注入 DS
const headers = MihoyoHeaderBuilder.build(HeaderProfile.CALCULATE, cookie);

// BBS Profile → 自动注入 DS
const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
```

`MihoyoApiService` 基类不再包含 `buildHeaders()` 方法，只保留 `get()` 和 `post()` 抽象方法：

```typescript
// core/src/main/ets/network/v2/MihoyoApiService.ets
export abstract class MihoyoApiService {
  abstract get(
    path: string,
    params?: RequestParams,
    options?: RequestOptions,
  ): Promise<object>;
  abstract post(
    path: string,
    data?: string | RequestParams,
    options?: RequestOptions,
  ): Promise<object>;
}
```

---

## 请求头构建器（MihoyoHeaderBuilder）

### 背景

不同接口的请求头差异显著，主要体现在以下维度：

- 是否需要 DS 动态签名
- `Referer` / `Origin` 来源域名不同
- `x-rpc-client_type` 值不同（`"5"` vs `"1"` vs 无）
- 是否携带 `x-rpc-tool_verison`（游戏记录接口特有，注意：米游社服务端拼写错误）
- 是否携带 `x-rpc-language` / `x-rpc-platform`（绝区零接口特有）

### 请求头 Profile 分类

从 `mihoyo_apis.md` 的真实抓包数据中归纳出三种 Profile：

| Profile           | 适用接口                                  | DS            | Referer/Origin         | client_type | tool_version | language | platform             |
| ----------------- | ----------------------------------------- | ------------- | ---------------------- | ----------- | ------------ | -------- | -------------------- |
| `GAME_RECORD`     | 原神/星铁 便笺、角色列表、角色详情        | ✅            | `webstatic.mihoyo.com` | `"5"`       | ✅           | ❌       | 星铁为 `"5"`，原神无 |
| `ZZZ_GAME_RECORD` | 绝区零 便笺、代理人列表、详情             | ❌            | `act.mihoyo.com`       | ❌          | ❌           | ✅       | ✅ `"1"`             |
| `CALCULATE`       | 原神养成计算（`batch_compute`）           | ❌            | `act.mihoyo.com`       | ❌          | ❌           | ❌       | ❌                   |
| `BBS`             | 账号详情、游戏角色绑定、战绩卡片、Geetest | ✅            | `app.mihoyo.com`       | `"1"`       | ❌           | ❌       | ❌                   |
| `SIGN`            | 大别野签到 + 各游戏每日签到               | ✅（X6 salt） | `act.mihoyo.com`       | `"2"`       | ❌           | ❌       | ❌                   |

> 注意 1：`SIGN` Profile 使用 X6 salt（不是 V1），`client_type=2`。游戏签到还需要额外的 `x-rpc-signgame: {host}` 头，由 `SignApiService` 在调用 `build()` 后手动 `headers.set('x-rpc-signgame', host)` 注入。
>
> 注意 2：`x-rpc-tool_version` 的请求头名称在抓包数据中实际拼写为 `x-rpc-tool_verison`（米游社服务端的拼写错误），实现时**必须使用错误拼写** `x-rpc-tool_verison`，否则服务端不识别。
>
> 注意 3：星穹铁道的 `GAME_RECORD` 接口（note/avatar_basic/avatar_info）需要额外携带 `x-rpc-platform: 5`，原神不需要。`StarRailApiService` 在调用 `build()` 后手动注入此字段。
>
> 注意 4：星穹铁道养成计算（`rpgcalc/compute`）的 `Referer`/`Origin` 是 `webstatic.mihoyo.com`，与原神养成计算（`act.mihoyo.com`）不同。`StarRailApiService` 在调用 `build(CALCULATE)` 后需要覆盖这两个字段：
>
> ```typescript
> const headers = MihoyoHeaderBuilder.build(HeaderProfile.CALCULATE, cookie);
> headers.set("Referer", "https://webstatic.mihoyo.com/");
> headers.set("Origin", "https://webstatic.mihoyo.com");
> ```
>
> 注意 5：绝区零养成计算（`nap_cultivate_tool/avatar_calc`）使用 `ZZZ_GAME_RECORD` Profile（带 `x-rpc-language`/`x-rpc-platform: 1`），但 Domain 是 `ACT_TAKUMI`。还需要额外注入 `x-rpc-cultivate_source: bbs`：
>
> ```typescript
> const headers = MihoyoHeaderBuilder.build(
>   HeaderProfile.ZZZ_GAME_RECORD,
>   cookie,
> );
> headers.set("x-rpc-cultivate_source", "bbs");
> return this.http.post(MihoyoDomain.ACT_TAKUMI + ZZZApiPath.COMPUTE, body, {
>   extraHeaders: headers,
> });
> ```

### 文件结构

```
core/src/main/ets/network/v2/
└── MihoyoHeaderBuilder.ets   ← 请求头构建器（新增）
```

### 设计

```typescript
// core/src/main/ets/network/v2/MihoyoHeaderBuilder.ets
import { RequestParams } from "../APIs";
import { ApiConfigV2 } from "./ApiConfigV2";
import { DSUtilV2 } from "./DSUtilV2";

/** 请求头 Profile 枚举 */
export enum HeaderProfile {
  /** 原神/星铁 游戏记录接口（有 DS，Referer=webstatic，client_type=5） */
  GAME_RECORD = "GAME_RECORD",
  /** 绝区零 游戏记录接口（无 DS，Referer=act，带 language/platform） */
  ZZZ_GAME_RECORD = "ZZZ_GAME_RECORD",
  /** 养成计算接口（原神/星铁，无 DS，Referer=act） */
  CALCULATE = "CALCULATE",
  /** BBS 账号 + 游戏角色绑定 + 战绩卡片 + Geetest（有 DS，Referer=app，client_type=1） */
  BBS = "BBS",
  /**
   * 签到接口（大别野 + 各游戏）
   * 使用 X6 salt，client_type=2，Referer=act
   * 游戏签到额外需要 x-rpc-signgame 头（由调用方在 build() 后手动 set）
   */
  SIGN = "SIGN",
}

export class MihoyoHeaderBuilder {
  /**
   * 构建请求头 Map
   * @param profile  请求头 Profile
   * @param cookie   登录 Cookie
   * @param params   GET 请求参数（用于 DS 签名的 query 部分，POST 请求传 undefined）
   * @param body     POST 请求 body 字符串（用于 DS 签名的 body 部分，GET 请求传 undefined）
   *
   * 注意：DS 签名规则：GET 请求 query=params 序列化，body=""；POST 请求 query=""，body=JSON.stringify(data)
   * 调用方必须正确区分：GET 请求传 params，POST 请求传 body 字符串，不能混用。
   */
  static build(
    profile: HeaderProfile,
    cookie: string,
    params?: RequestParams,
    body?: string,
  ): Map<string, string> {
    const h = new Map<string, string>();

    // ── 所有接口共有 ──────────────────────────────────────────────
    h.set("x-rpc-app_version", ApiConfigV2.APP_VERSION);
    h.set("x-rpc-device_id", ApiConfigV2.getDeviceIdSync());
    h.set("x-rpc-device_fp", ApiConfigV2.getDeviceFp());
    h.set("x-rpc-sys_version", "15.7.1");
    h.set("Cookie", cookie);
    h.set("User-Agent", ApiConfigV2.USER_AGENT);
    h.set("Accept", "application/json, text/plain, */*");

    // ── 按 Profile 差异化注入 ─────────────────────────────────────
    if (profile === HeaderProfile.GAME_RECORD) {
      h.set("x-rpc-client_type", "5");
      // 注意：米游社服务端的拼写错误，必须用 "x-rpc-tool_verison" 而非 "version"
      // 默认使用原神版本号；StarRailApiService 调用后会覆盖为星铁版本号
      h.set("x-rpc-tool_verison", ApiConfigV2.TOOL_VERSION_GENSHIN);
      h.set("Referer", "https://webstatic.mihoyo.com/");
      h.set("Origin", "https://webstatic.mihoyo.com");
      h.set("DS", DSUtilV2.generateV1(params, body));
    } else if (profile === HeaderProfile.ZZZ_GAME_RECORD) {
      h.set("x-rpc-language", "zh-cn");
      h.set("x-rpc-platform", "1");
      h.set("Referer", "https://act.mihoyo.com/");
      h.set("Origin", "https://act.mihoyo.com");
      // 绝区零游戏记录接口不携带 DS
    } else if (profile === HeaderProfile.CALCULATE) {
      h.set("Referer", "https://act.mihoyo.com/");
      h.set("Origin", "https://act.mihoyo.com");
      // 养成计算不携带 DS
    } else if (profile === HeaderProfile.BBS) {
      h.set("x-rpc-client_type", "1");
      h.set("Referer", "https://app.mihoyo.com");
      h.set("Origin", "https://app.mihoyo.com");
      // BBS Profile 使用 salt_v2（random 为字母数字混合，从真实抓包数据确认）
      h.set("DS", DSUtilV2.generateV2(params, body));
    } else if (profile === HeaderProfile.SIGN) {
      h.set("x-rpc-client_type", "2");
      h.set("Referer", "https://act.mihoyo.com/");
      h.set("Origin", "https://act.mihoyo.com");
      // SIGN 使用 X6 salt（不是 V1）
      h.set("DS", DSUtilV2.generateX6(params, body));
      // 游戏签到需要额外的 x-rpc-signgame 头，由 SignApiService 在调用后手动注入
    }

    return h;
  }
}
```

> 注意：`x-rpc-tool_verison` 在原神和星铁中值不同（原神 `v6.4.2-gr-cn`，星铁 `v4.1.1`），各 Service 在调用 `build()` 后可通过 `headers.set('x-rpc-tool_verison', ...)` 覆盖默认值。注意请求头名称是 `verison`（米游社服务端拼写错误）。

### 各 Service 使用方式

```typescript
// GenshinApiService — 游戏记录接口使用 GAME_RECORD Profile
async getDailyNote(roleId: string, server: string, cookie: string): Promise<object> {
  const params = new RequestParams();
  params.set('role_id', roleId);
  params.set('server', server);
  const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, params);
  // 注意：拼写是 "verison" 不是 "version"（米游社服务端的拼写错误）
  headers.set('x-rpc-tool_verison', ApiConfigV2.TOOL_VERSION_GENSHIN);
  // 原神不需要 x-rpc-platform
  return this.http.get(MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.DAILY_NOTE, params, { extraHeaders: headers });
}

// StarRailApiService — 游戏记录接口，覆盖 tool_version 为星铁版本号，并注入 x-rpc-platform: 5
async getDailyNote(roleId: string, server: string, cookie: string): Promise<object> {
  const params = new RequestParams();
  params.set('role_id', roleId);
  params.set('server', server);
  const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, params);
  headers.set('x-rpc-tool_verison', ApiConfigV2.TOOL_VERSION_STARRAIL); // 星铁专属版本号
  headers.set('x-rpc-platform', '5'); // 星铁游戏记录接口需要此字段，原神不需要
  return this.http.get(MihoyoDomain.TAKUMI_RECORD + StarRailApiPath.DAILY_NOTE, params, { extraHeaders: headers });
}

// GenshinApiService — 养成计算使用 CALCULATE Profile
async batchCompute(items: object[], uid: string, region: string, cookie: string): Promise<object> {
  // POST 请求：body 是 JSON 字符串，params 传 undefined（DS 签名的 query 为空）
  // ArkTS 严格模式：禁止对象字面量 shorthand，需要显式写出 key: value
  const bodyStr = JSON.stringify({ items: items, lang: 'zh-cn', region: region, uid: uid });
  const headers = MihoyoHeaderBuilder.build(HeaderProfile.CALCULATE, cookie, undefined, bodyStr);
  headers.set('x-rpc-cal_type', '1'); // 原神养成计算专用
  // 原神养成计算 Referer 是 act.mihoyo.com（CALCULATE Profile 默认值，无需覆盖）
  return this.http.post(MihoyoDomain.TAKUMI + GenshinApiPath.BATCH_COMPUTE, bodyStr, { extraHeaders: headers });
}

// ZZZApiService — 所有接口使用 ZZZ_GAME_RECORD Profile（无需 isZZZ 参数）
async getDailyNote(roleId: string, server: string, cookie: string): Promise<object> {
  const params = new RequestParams();
  params.set('role_id', roleId);
  params.set('server', server);
  const headers = MihoyoHeaderBuilder.build(HeaderProfile.ZZZ_GAME_RECORD, cookie, params);
  return this.http.get(MihoyoDomain.TAKUMI_RECORD + ZZZApiPath.DAILY_NOTE, params, { extraHeaders: headers });
}

// MihoyoAccountApiService — BBS 接口使用 BBS Profile
async getUserFullInfo(uid: string, cookie: string): Promise<object> {
  const params = new RequestParams();
  params.set('uid', uid);
  const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
  return this.http.get(MihoyoDomain.BBS + MihoyoAccountApiPath.GET_USER_FULL_INFO, params, { extraHeaders: headers });
}

// StarRailApiService — 养成计算使用 CALCULATE Profile，但需覆盖 Referer/Origin
async compute(avatar: object, skillList: object[], uid: string, region: string, cookie: string): Promise<object> {
  const bodyStr = JSON.stringify({ game: 'hkrpg', avatar: avatar, skill_list: skillList, lang: 'zh-cn', uid: uid, region: region });
  const headers = MihoyoHeaderBuilder.build(HeaderProfile.CALCULATE, cookie, undefined, bodyStr);
  // 星铁养成计算 Referer 是 webstatic.mihoyo.com，与原神不同（见 Profile 分类表注意 4）
  headers.set('Referer', 'https://webstatic.mihoyo.com/');
  headers.set('Origin', 'https://webstatic.mihoyo.com');
  // 真实抓包：URL 带 ?game=hkrpg query 参数
  return this.http.post(MihoyoDomain.TAKUMI + StarRailApiPath.COMPUTE + '?game=hkrpg', bodyStr, { extraHeaders: headers });
}

// ZZZApiService — 养成计算使用 ZZZ_GAME_RECORD Profile，Domain 是 ACT_TAKUMI
// 注意：uid 和 region 是 query 参数（URL 里），不是 body 参数（真实抓包确认）
async compute(avatarId: string, avatarLevel: number, avatarCurrentLevel: number, avatarCurrentPromotes: number, skills: object[], uid: string, region: string, cookie: string): Promise<object> {
  const bodyStr = JSON.stringify({
    avatar_id: parseInt(avatarId),
    avatar_level: avatarLevel,
    avatar_current_level: avatarCurrentLevel,
    avatar_current_promotes: avatarCurrentPromotes,
    skills: skills
  });
  const headers = MihoyoHeaderBuilder.build(HeaderProfile.ZZZ_GAME_RECORD, cookie, undefined, bodyStr);
  headers.set('x-rpc-cultivate_source', 'bbs'); // 绝区零养成计算专用（见 Profile 分类表注意 5）
  // uid 和 region 作为 query 参数拼接到 URL（真实抓包：?uid=37716744&region=prod_gf_cn）
  const url = `${MihoyoDomain.ACT_TAKUMI}${ZZZApiPath.COMPUTE}?uid=${uid}&region=${region}`;
  return this.http.post(url, bodyStr, { extraHeaders: headers });
}
```

### 与旧版 buildHeaders() 的关系

旧版 `MihoyoApiService.buildHeaders()` 将所有接口的请求头统一处理，无法区分 Profile 差异。新版用 `MihoyoHeaderBuilder` 替代，`MihoyoApiService` 基类不再包含 `buildHeaders()` 方法，改由各 Service 子类在每个方法内按需调用 `MihoyoHeaderBuilder.build()`。

### ApiConfigV2 新增常量

```typescript
import { common } from '@kit.AbilityKit';

export class ApiConfigV2 {
  static readonly APP_VERSION: string           = '2.102.0';
  static readonly USER_AGENT: string            = 'Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0 WebCacheKit2';
  /**
   * x-rpc-tool_verison：原神游戏记录接口专用
   * 注意：请求头名称是 "verison"（米游社服务端拼写错误），常量名用正确拼写便于阅读
   */
  static readonly TOOL_VERSION_GENSHIN: string  = 'v6.4.2-gr-cn';
  /** x-rpc-tool_verison：星穹铁道游戏记录接口专用 */
  static readonly TOOL_VERSION_STARRAIL: string = 'v4.1.1';

  private static cachedDeviceId: string = '';
  private static cachedDeviceFp: string = '';

  static async preloadDeviceId(context: common.UIAbilityContext): Promise<void> { ... }
  static getDeviceIdSync(): string { return ApiConfigV2.cachedDeviceId; }

  /** device_fp 从 Preferences 读取或随机生成（格式：38d8xxxxxxxx） */
  static async preloadDeviceFp(context: common.UIAbilityContext): Promise<void> { ... }
  static getDeviceFp(): string { return ApiConfigV2.cachedDeviceFp; }
}
```

### DSUtil 新版接口设计

现有 `DSUtil.generateDS(config: AxiosRequestConfig)` 依赖 Axios 配置对象，与新版 `MihoyoHeaderBuilder` 的参数类型不兼容。新版需要重新设计接口，接收 `RequestParams` 和 body 字符串：

```typescript
// core/src/main/ets/network/v2/DSUtilV2.ets
import { RequestParams, RequestValue } from "../APIs";
import crypto from "@ohos/crypto-js";

export class DSUtilV2 {
  /**
   * salt 值管理说明：
   * salt 属于敏感配置，禁止硬编码在源码中。
   * 管理方案：
   *   1. 存放在 core/src/main/resources/rawfile/release/salt_config.json（不提交 git，加入 .gitignore）
   *   2. CoreInitializerV2.initCore() 时通过 resourceManager.getRawFileContent() 读取并缓存到内存
   *   3. DSUtilV2 通过 setSalts() 接收注入，不自行读取文件
   * 这样 salt 值不出现在任何 .ets 源码文件中，也不会被编译进 HAP 包的代码段。
   */
  private static saltV1: string = "";
  private static saltV2: string = "";
  private static saltX6: string = "";

  /** 由 CoreInitializerV2 在初始化时调用，注入 salt 值 */
  static setSalts(v1: string, v2: string, x6: string): void {
    DSUtilV2.saltV1 = v1;
    DSUtilV2.saltV2 = v2;
    DSUtilV2.saltX6 = x6;
  }

  /**
   * 生成 DS 签名（v1 salt，适用于 GAME_RECORD Profile）
   * @param params GET 请求参数（RequestParams，值序列化为字符串后按字典序拼接）
   * @param body   POST 请求 body 字符串（GET 请求传空字符串）
   */
  static generateV1(params?: RequestParams, body?: string): string {
    if (DSUtilV2.saltV1 === "") {
      throw new Error("DSUtilV2: salt not initialized, call setSalts() first");
    }
    return DSUtilV2.generate(DSUtilV2.saltV1, params, body);
  }

  /**
   * 生成 DS 签名（v2 salt，适用于 BBS Profile）
   */
  static generateV2(params?: RequestParams, body?: string): string {
    if (DSUtilV2.saltV2 === "") {
      throw new Error("DSUtilV2: salt not initialized, call setSalts() first");
    }
    return DSUtilV2.generate(DSUtilV2.saltV2, params, body);
  }

  /**
   * 生成 DS 签名（X6 salt，适用于签到接口）
   */
  static generateX6(params?: RequestParams, body?: string): string {
    if (DSUtilV2.saltX6 === "") {
      throw new Error("DSUtilV2: salt not initialized, call setSalts() first");
    }
    return DSUtilV2.generate(DSUtilV2.saltX6, params, body);
  }

  private static generate(
    salt: string,
    params?: RequestParams,
    body?: string,
  ): string {
    const timestamp = Math.floor(Date.now() / 1000);
    // random：6 位字母数字混合随机字符串
    // 注意：从真实抓包数据观察到 GAME_RECORD Profile 的 random 为纯数字，
    // BBS Profile 的 random 为字母数字混合。但 DS 签名的验证逻辑只校验
    // MD5 是否匹配，不校验 random 的格式，因此统一使用字母数字混合是安全的。
    // 如果实际测试发现 GAME_RECORD 接口拒绝字母数字 random，再改为纯数字。
    const random = DSUtilV2.randomStr(6);

    // query：GET 参数按字典序排列，值统一转字符串
    // 注意：ArkTS 严格模式禁止 Array.map/filter，使用 for 循环替代
    let query = "";
    if (params && params.size > 0) {
      const entries: string[] = [];
      params.forEach((v: RequestValue, k: string) => {
        entries.push(`${k}=${String(v)}`);
      });
      entries.sort(); // sort() 是原地排序，ArkTS 允许
      query = entries.join("&");
    }

    const b = body ?? "";
    // 米游社 DS 签名格式：salt=${salt}&t=${timestamp}&r=${random}&b=${body}&q=${query}
    // 注意：这是标准格式，不是简单拼接，必须带 key= 前缀和 & 分隔符
    const sign = `salt=${salt}&t=${timestamp}&r=${random}&b=${b}&q=${query}`;
    const md5 = crypto.MD5(sign).toString();
    return `${timestamp},${random},${md5}`;
  }

  /** 生成 6 位字母数字混合随机字符串 */
  private static randomStr(len: number): string {
    const chars =
      "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    let r = "";
    for (let i = 0; i < len; i++) {
      r += chars[Math.floor(Math.random() * chars.length)];
    }
    return r;
  }
}
```

> 注意：salt 值属于敏感配置，禁止硬编码在源码中，应通过安全配置文件或构建时注入。

### 正确性属性

| 属性               | 描述                                                                                            |
| ------------------ | ----------------------------------------------------------------------------------------------- |
| P1：Profile 完整性 | 对任意 Profile，`build()` 返回的 Map 包含该 Profile 所有必填字段，不包含其他 Profile 的专属字段 |
| P2：DS 隔离性      | `CALCULATE` 和 `ZZZ_GAME_RECORD` Profile 的返回 Map 中不包含 `DS` 字段                          |
| P3：ZZZ 字段隔离   | 非 `ZZZ_GAME_RECORD` Profile 不包含 `x-rpc-language` 和 `x-rpc-platform`                        |
| P4：Cookie 注入    | 对任意 cookie 字符串，`build()` 返回的 Map 中 `Cookie` 字段值与传入值完全一致                   |

---

## 公共请求头管理

> 公共请求头的构建逻辑已统一迁移到 `MihoyoHeaderBuilder`（见上节），本节仅保留各 Profile 的请求头字段清单供参考。

### GAME_RECORD Profile（原神/星铁 游戏记录）

| 请求头名称           | 值                                  | 备注                                     |
| -------------------- | ----------------------------------- | ---------------------------------------- |
| `x-rpc-app_version`  | `ApiConfigV2.APP_VERSION`           |                                          |
| `x-rpc-client_type`  | `"5"`                               |                                          |
| `x-rpc-device_id`    | `ApiConfigV2.getDeviceIdSync()`     |                                          |
| `x-rpc-device_fp`    | `ApiConfigV2.getDeviceFp()`         |                                          |
| `x-rpc-tool_verison` | `ApiConfigV2.TOOL_VERSION_GENSHIN`  | 注意：拼写是 verison（米游社服务端错误） |
| `x-rpc-sys_version`  | `"15.7.1"`                          |                                          |
| `Cookie`             | 调用方传入                          |                                          |
| `DS`                 | `DSUtilV2.generateV1(params, body)` |                                          |
| `Referer`            | `https://webstatic.mihoyo.com/`     |                                          |
| `Origin`             | `https://webstatic.mihoyo.com`      |                                          |
| `User-Agent`         | `ApiConfigV2.USER_AGENT`            |                                          |
| `x-rpc-platform`     | `"5"`（仅星铁，原神不需要）         | 由 StarRailApiService 在 build() 后注入  |

### CALCULATE Profile（原神养成计算；星铁养成计算需覆盖 Referer/Origin）

| 请求头名称          | 值                              |
| ------------------- | ------------------------------- |
| `x-rpc-app_version` | `ApiConfigV2.APP_VERSION`       |
| `x-rpc-device_id`   | `ApiConfigV2.getDeviceIdSync()` |
| `x-rpc-device_fp`   | `ApiConfigV2.getDeviceFp()`     |
| `x-rpc-sys_version` | `"15.7.1"`                      |
| `x-rpc-cal_type`    | `"1"`（原神养成计算专用）       |
| `Cookie`            | 调用方传入                      |
| `Referer`           | `https://act.mihoyo.com/`       |
| `Origin`            | `https://act.mihoyo.com`        |
| `User-Agent`        | `ApiConfigV2.USER_AGENT`        |

> 注意：`x-rpc-cal_type: 1` 是原神养成计算接口专用字段，由 `GenshinApiService` 在调用 `build(CALCULATE)` 后手动注入：
>
> ```typescript
> const headers = MihoyoHeaderBuilder.build(HeaderProfile.CALCULATE, cookie);
> headers.set("x-rpc-cal_type", "1"); // 原神养成计算专用
> ```
>
> 星铁养成计算不需要此字段，但需要覆盖 Referer/Origin 为 `webstatic.mihoyo.com`（见 Profile 分类表注意 4）。

### ZZZ_GAME_RECORD Profile（绝区零 游戏记录）

| 请求头名称          | 值                              |
| ------------------- | ------------------------------- |
| `x-rpc-app_version` | `ApiConfigV2.APP_VERSION`       |
| `x-rpc-device_id`   | `ApiConfigV2.getDeviceIdSync()` |
| `x-rpc-device_fp`   | `ApiConfigV2.getDeviceFp()`     |
| `x-rpc-sys_version` | `"15.7.1"`                      |
| `x-rpc-language`    | `"zh-cn"`                       |
| `x-rpc-platform`    | `"1"`                           |
| `Cookie`            | 调用方传入                      |
| `Referer`           | `https://act.mihoyo.com/`       |
| `Origin`            | `https://act.mihoyo.com`        |
| `User-Agent`        | `ApiConfigV2.USER_AGENT`        |

### BBS Profile（账号详情 + 游戏角色绑定 + 战绩卡片 + Geetest）

| 请求头名称          | 值                                                                       |
| ------------------- | ------------------------------------------------------------------------ |
| `x-rpc-app_version` | `ApiConfigV2.APP_VERSION`                                                |
| `x-rpc-client_type` | `"1"`                                                                    |
| `x-rpc-device_id`   | `ApiConfigV2.getDeviceIdSync()`                                          |
| `x-rpc-device_fp`   | `ApiConfigV2.getDeviceFp()`                                              |
| `x-rpc-sys_version` | `"15.7.1"`                                                               |
| `Cookie`            | 调用方传入                                                               |
| `DS`                | `DSUtilV2.generateV2(params, body)`（BBS 用 salt_v2，random 为字母数字） |
| `Referer`           | `https://app.mihoyo.com`                                                 |
| `Origin`            | `https://app.mihoyo.com`                                                 |
| `User-Agent`        | `ApiConfigV2.USER_AGENT`                                                 |

### SIGN Profile（大别野签到 + 各游戏每日签到）

| 请求头名称          | 值                                                 |
| ------------------- | -------------------------------------------------- |
| `x-rpc-app_version` | `ApiConfigV2.APP_VERSION`                          |
| `x-rpc-client_type` | `"2"`                                              |
| `x-rpc-device_id`   | `ApiConfigV2.getDeviceIdSync()`                    |
| `x-rpc-device_fp`   | `ApiConfigV2.getDeviceFp()`                        |
| `x-rpc-sys_version` | `"15.7.1"`                                         |
| `Cookie`            | 调用方传入                                         |
| `DS`                | `DSUtilV2.generateX6(params, body)`                |
| `Referer`           | `https://act.mihoyo.com/`                          |
| `Origin`            | `https://act.mihoyo.com`                           |
| `User-Agent`        | `ApiConfigV2.USER_AGENT`                           |
| `x-rpc-signgame`    | `{host}`（游戏签到专用，由 `SignApiService` 注入） |

---

## Cookie 管理

### Cookie 字段说明

米游社 Cookie 由多个字段组成，各字段有效期不同：

| 字段名         | 说明                                              | 有效期            |
| -------------- | ------------------------------------------------- | ----------------- |
| `stoken`       | 主 Token，长期有效                                | 长期（数月）      |
| `stuid`        | 与 `stoken` 配套的 uid，Passport API 刷新接口必填 | 同 `stoken`       |
| `mid`          | 账号 mid，与 `stoken` 配套，部分接口需要          | 同 `stoken`       |
| `ltoken_v2`    | 用于游戏记录 API（新版，替代旧版 `ltoken`）       | 较短（数天~数周） |
| `ltuid_v2`     | 与 `ltoken_v2` 配套的 uid                         | 同 `ltoken_v2`    |
| `ltmid_v2`     | 与 `ltoken_v2` 配套的 mid                         | 同 `ltoken_v2`    |
| `cookie_token` | 用于部分 BBS API                                  | 较短              |
| `account_id`   | 账号 ID                                           | 长期              |

> 注意：从真实抓包数据（`mihoyo_apis.md`）可以看到，当前米游社 App 使用的是 `ltoken_v2` 而非旧版 `ltoken`。`rebuildCookie` 在刷新时需要同时处理 `ltoken` 和 `ltoken_v2` 两种字段名，以兼容不同登录方式获取的 Cookie。

**关键原则：`stoken` 是刷新其他 Token 的根凭证，必须妥善保存。刷新接口（`getCookieAccountInfoBySToken`、`getLTokenBySToken`）需要同时传入 `stoken` 和 `stuid`。**

### Cookie 来源

Cookie 由登录流程写入，通过 `BBSRepository` 持久化到 `account_table`：

```
用户登录成功
    │
    ▼
登录 ViewModel 解析登录响应，提取 Cookie 字符串
    │
    ▼
BBSRepository.upsertAccount(accountRow)
    └── 写入 account_table.cookie（持久化，多账号隔离）
```

> 注意：旧版通过 `CookieManager` 存储全局 Cookie，新版改为按账号存储在 `account_table`，支持多账号切换。`CookieManager` 在新版中仅用于登录流程的临时 Cookie 传递，不作为主要存储。

### Cookie 自动刷新

当 API 返回 `retcode=-100`（Cookie 失效）时，不应立即要求用户重新登录，而是先尝试用 `stoken` 自动刷新过期的 Token 字段。

**刷新接口（来自 TeyvatGuide passportReq.ts）：**

| 接口                           | Domain                       | Path                                             | 说明                               |
| ------------------------------ | ---------------------------- | ------------------------------------------------ | ---------------------------------- |
| `getCookieAccountInfoBySToken` | `passport-api.mihoyo.com`    | `/account/auth/api/getCookieAccountInfoBySToken` | 用 `stoken` 换取新 `cookie_token`  |
| `getLTokenBySToken`            | `passport-api.mihoyo.com`    | `/account/auth/api/getLTokenBySToken`            | 用 `stoken` 换取新 `ltoken`        |
| `verifyLToken`                 | `passport-api-v4.mihoyo.com` | `/account/ma-cn-session/web/verifyLtoken`        | 验证 `ltoken` 是否有效，返回 `mid` |

**自动刷新流程：**

```
API 返回 retcode=-100（Cookie 失效）
    │
    ▼
BBSRepository.refreshCookie(accountId)
    │
    ├── 1. 从 DB 读取该账号的 stoken
    │
    ├── 2. 调 getCookieAccountInfoBySToken(stoken) → 新 cookie_token
    │
    ├── 3. 调 getLTokenBySToken(stoken) → 新 ltoken
    │
    ├── 4. 更新 account_table 中该账号的 Cookie 字段
    │
    └── 5. 返回新 Cookie，调用方用新 Cookie 重试原请求
```

**刷新失败的处理：**

- 如果 `stoken` 也已失效（`getCookieAccountInfoBySToken` 返回 `-100`），说明需要重新登录
- 此时抛出 `AuthExpiredError`，通知 UI 弹出重新登录提示

**新增 PassportApiPath 枚举：**

```typescript
// core/src/main/ets/network/v2/PassportApiPath.ets
export enum PassportApiPath {
  /** 用 stoken 换取新 cookie_token — Domain: PASSPORT */
  GET_COOKIE_TOKEN_BY_STOKEN = "/account/auth/api/getCookieAccountInfoBySToken",
  /** 用 stoken 换取新 ltoken — Domain: PASSPORT */
  GET_LTOKEN_BY_STOKEN = "/account/auth/api/getLTokenBySToken",
  /** 验证 ltoken 有效性 — Domain: PASSPORT_V4 */
  VERIFY_LTOKEN = "/account/ma-cn-session/web/verifyLtoken",
}
```

**新增 MihoyoAccountApiService 方法：**

| 方法                                | HTTP | Domain      | Path                                         |
| ----------------------------------- | ---- | ----------- | -------------------------------------------- |
| `refreshCookieToken(stoken, stuid)` | GET  | PASSPORT    | `PassportApiPath.GET_COOKIE_TOKEN_BY_STOKEN` |
| `refreshLToken(stoken, stuid)`      | GET  | PASSPORT    | `PassportApiPath.GET_LTOKEN_BY_STOKEN`       |
| `verifyLToken(ltoken, ltuid)`       | POST | PASSPORT_V4 | `PassportApiPath.VERIFY_LTOKEN`              |

**Repository 层集成：**

```typescript
// BBSRepository 里的 Cookie 刷新逻辑
async refreshCookie(accountId: number): Promise<string> {
  const account = await this.findAccount(accountId);
  if (account === null) {
    throw new Error('account not found');
  }

  // 用 stoken + stuid 刷新 cookie_token 和 ltoken
  // 注意：Passport API 需要 stuid（不是 mid），mid 是另一个独立字段
  // refreshCookieToken/refreshLToken 返回 Promise<object>，实现时需从响应 data 字段提取 token 字符串
  const cookieTokenResp = await this.getAccountService().refreshCookieToken(
    account.stoken, account.stuid
  ) as Record<string, Object>;
  const lTokenResp = await this.getAccountService().refreshLToken(
    account.stoken, account.stuid
  ) as Record<string, Object>;
  const newCookieToken = (cookieTokenResp['data'] as Record<string, Object>)['cookie_token'] as string;
  const newLToken = (lTokenResp['data'] as Record<string, Object>)['ltoken'] as string;

  // 更新 DB 中的 Cookie（rebuildCookie 替换 Cookie 字符串中的指定字段）
  const updatedCookie = BBSRepository.rebuildCookie(account.cookie, newCookieToken, newLToken);
  await this.updateAccountCookie(accountId, updatedCookie);
  return updatedCookie;
}

/**
 * 替换 Cookie 字符串中的 cookie_token 和 ltoken 相关字段
 * ArkTS 严格模式：禁止对象展开，用正则替换字符串字段
 * 注意：同时处理旧版 ltoken 和新版 ltoken_v2，兼容不同登录方式
 */
private static rebuildCookie(
  original: string,
  newCookieToken: string,
  newLToken: string
): string {
  let result = original;
  // 替换 cookie_token 字段（精确匹配，不会误匹配其他字段）
  result = result.replace(/cookie_token=[^;]*/g, `cookie_token=${newCookieToken}`);
  // 替换 ltoken 字段：使用精确前缀匹配，防止误匹配 ltoken_v2
  // 匹配 "; ltoken=" 或开头的 "ltoken="（不匹配 ltoken_v2）
  result = result.replace(/(^|;\s*)ltoken=([^;]*)/g, `$1ltoken=${newLToken}`);
  // 同时替换 ltoken_v2 字段（新版 Cookie 格式）
  result = result.replace(/(^|;\s*)ltoken_v2=([^;]*)/g, `$1ltoken_v2=${newLToken}`);
  return result;
}
```

**handleApiError 集成自动刷新：**

```typescript
// ArkTS 严格模式：方法参数 e 类型已声明为 Error，直接访问 .message 即可
// 注意：此方法定义在 GameRepository 抽象基类中（protected），各游戏 Repository 子类继承后可直接调用
// GameRepository 调用 BBSRepository.getInstance() 不构成循环依赖，因为 BBSRepository 是独立类
protected async handleApiErrorWithRefresh(
  e: Error,
  accountId: number,
  retryFn: (newCookie: string) => Promise<object>
): Promise<object> {
  const msg = e.message;
  if (msg.includes(`retcode=${ApiErrorCodes.AUTH_INVALID}`)) {
    // 先尝试自动刷新 Cookie
    try {
      const newCookie = await BBSRepository.getInstance().refreshCookie(accountId);
      return await retryFn(newCookie); // 用新 Cookie 重试
    } catch (_) {
      // 刷新也失败，才要求重新登录
      throw new AuthExpiredError();
    }
  }
  // 其他错误走原有处理逻辑
  this.handleApiError(e);
  throw e;
}
```

> **调用方写法：** catch 到的 `e` 是 `Object` 类型，需要先 `instanceof Error` 判断后再传入 `handleApiErrorWithRefresh`：
>
> ```typescript
> } catch (e) {
>   if (e instanceof Error) {
>     return await this.handleApiErrorWithRefresh(e as Error, accountId, retryFn);
>   }
>   throw e;
> }
> ```

### Cookie 传递路径

Cookie 从 `account_table` 读取后，沿调用链向下传递，不在 Service 内部自行读取：

```
ViewModel.loadData()
    │
    ▼
Repository.fetchXxx()
    ├── cookie = account.cookie（从 DB 读取该账号的 Cookie）
    └── service.getDailyNote(roleId, server, cookie)
            │
            ▼
        MihoyoHeaderBuilder.build(profile, cookie, params)
            │
            ▼
        HTTP 请求头 Cookie: {cookie}
```

**设计原则：**

- Service 层不直接调用 `CookieManager`，Cookie 由 Repository 层从 `account_table` 读取后作为参数传入
- 这样 Service 层保持无状态，便于测试（Mock 时可传入任意 Cookie）
- `CookieManager` 只在登录流程中使用（写入 Cookie），多账号场景下 Cookie 从 `account_table` 读取

### 多账号 Cookie 切换

多账号场景下，Repository 根据当前激活账号从 `account_table` 读取对应 Cookie，而非从 `CookieManager` 读取全局 Cookie：

```typescript
// Repository 多账号 Cookie 读取示意
async fetchDailyNote(accountId: number, roleId: string, server: string): Promise<object> {
  const account = await BBSRepository.getInstance().findAccount(accountId);
  // ArkTS 严格模式：findAccount 返回 AccountRowV2 | null，必须 null 检查
  if (account === null) {
    throw new Error(`account not found: ${accountId}`);
  }
  const cookie = account.cookie; // 从 DB 读取该账号的 Cookie
  return this.getService().getDailyNote(roleId, server, cookie);
}
```

---

## 扩展性设计

### 新增游戏类型（以崩坏 3 为例）

只需以下步骤，不修改任何现有文件：

**步骤 1：新增 API Path 枚举**

```typescript
// core/src/main/ets/network/v2/Honkai3ApiPath.ets
export enum Honkai3ApiPath {
  DAILY_NOTE = "/game_record/app/honkai3rd/api/note",
  AVATAR_BASIC = "/game_record/app/honkai3rd/api/avatar/basic",
}
```

**步骤 2：新增 API Service**

```typescript
// core/src/main/ets/network/v2/Honkai3ApiService.ets
export class Honkai3ApiService extends MihoyoApiService {
  async getDailyNote(roleId: string, server: string, cookie: string): Promise<object> { ... }
  async getAvatarBasic(roleId: string, server: string, cookie: string): Promise<object> { ... }
}
```

**步骤 3：如有新 Domain，追加到 MihoyoDomain 枚举**

```typescript
// 如崩坏 3 使用不同 Host，追加一行即可
HONKAI3_RECORD = 'https://api-takumi-record.mihoyo.com', // 通常复用 TAKUMI_RECORD
```

### 扩展性约束

| 约束                       | 说明                                                              |
| -------------------------- | ----------------------------------------------------------------- |
| 新游戏不修改现有 Service   | 继承 `MihoyoApiService`，独立实现                                 |
| 新游戏不修改现有 Path 枚举 | 新建独立的 `XxxApiPath.ets` 文件                                  |
| Domain 枚举可追加          | 新增枚举值不影响现有代码                                          |
| 多态调用统一               | 所有 Service 通过 `MihoyoApiService` 引用，调用方无需感知具体类型 |

---

## 错误码统一处理

### ApiErrorCodes 枚举

所有 retcode 判断必须引用 `core` 模块的 `ApiErrorCodes` 类，禁止在业务代码中直接写数字字面量：

```typescript
// core/src/main/ets/constants/ApiErrorCodes.ets（已存在，按需扩充）
// 注意：GEETEST_SIGN = 1034 是新增常量，实现时需要添加到现有文件里
export class ApiErrorCodes {
  static readonly SUCCESS: number = 0;
  static readonly AUTH_INVALID: number = -100; // Cookie 失效 / 登录已过期
  static readonly RATE_LIMITED: number = -110; // 请求频率过高
  static readonly INVALID_PARAM: number = -1; // 参数错误
  static readonly GEETEST_REQUIRED: number = 10035; // 游戏记录接口触发 Geetest 人机验证
  static readonly GEETEST_SIGN: number = 1034; // 大别野签到/米游币任务触发 Geetest（retcode 不同）
  static readonly ROLE_NOT_PUBLIC: number = 10102; // 角色战绩未公开
  static readonly ROLE_NOT_FOUND: number = 10103; // 角色不存在
  static readonly ACCOUNT_NOT_FOUND: number = -1002; // 账号不存在
  static readonly CAPTCHA_INVALID: number = -3208; // 验证码错误或已过期
  static readonly QRCODE_EXPIRED: number = -106; // 二维码已过期
}
```

### Service 层错误抛出规范

所有 Service（Release 和 Mock）在收到非 0 retcode 时，统一抛出以下格式的错误：

```typescript
throw new Error(`retcode=${retcode}: ${message}`);
```

### Repository 层统一错误处理

Repository 层捕获 Service 抛出的错误，根据 retcode 分类处理：

```typescript
protected handleApiError(e: Error): void {
  // 参数类型已声明为 Error，直接访问 .message
  const msg = e.message;

  if (msg.includes(`retcode=${ApiErrorCodes.AUTH_INVALID}`)) {
    throw new AuthExpiredError();
  }
  // 游戏记录接口触发 Geetest（retcode=10035）
  if (msg.includes(`retcode=${ApiErrorCodes.GEETEST_REQUIRED}`)) {
    throw new GeetestRequiredError(GeetestTriggerType.NEED_CREATE);
  }
  // 大别野签到/米游币任务触发 Geetest（retcode=1034）
  if (msg.includes(`retcode=${ApiErrorCodes.GEETEST_SIGN}`)) {
    throw new GeetestRequiredError(GeetestTriggerType.NEED_CREATE);
  }
  if (msg.includes(`retcode=${ApiErrorCodes.ROLE_NOT_PUBLIC}`)) {
    throw new RoleNotPublicError();
  }
  if (msg.includes(`retcode=${ApiErrorCodes.RATE_LIMITED}`)) {
    throw new RateLimitedError();
  }
  // 其他错误：保留旧数据，更新 sync_meta 为 failed
  throw e;
}
```

### 错误类型定义

```typescript
// core/src/main/ets/errors/ApiErrors.ets
// 注意：此文件需要在 core/Index.ets 里 export * from './src/main/ets/errors/ApiErrors'
// 以便 entry 模块通过 import { GeetestCreateResult, GeetestVerifyInput, ... } from 'core' 使用
export class AuthExpiredError extends Error {
  constructor() {
    super("Cookie 已失效，请重新登录");
  }
}

/**
 * Geetest 验证初始化参数（createVerification 接口返回，或签到 is_risk=true 时直接提取）
 * 替代旧版 GeetestService.ets 里的 interface GeetestCreateResult，改为 class（ArkTS 严格模式要求）
 * 定义在 core 模块，entry 模块通过 import { GeetestCreateResult } from 'core' 使用
 */
export class GeetestCreateResult {
  gt: string = "";
  challenge: string = "";
  new_captcha: boolean = true;
}

/**
 * Geetest 验证完成后的结果（SDK 回调返回）
 * 替代旧版 GeetestService.ets 里的 interface GeetestVerifyInput，改为 class（ArkTS 严格模式要求）
 * 定义在 core 模块，entry 模块通过 import { GeetestVerifyInput } from 'core' 使用
 */
export class GeetestVerifyInput {
  geetest_challenge: string = "";
  geetest_validate: string = "";
  geetest_seccode: string = "";
}

/** Geetest 触发类型 */
export enum GeetestTriggerType {
  /** 需要先调 createVerification 获取 gt/challenge（retcode=10035 或 1034） */
  NEED_CREATE = "NEED_CREATE",
  /** 签到响应里直接带了 gt/challenge（is_risk=true），无需调 createVerification */
  HAS_PARAMS = "HAS_PARAMS",
}

/**
 * Geetest 参数（HAS_PARAMS 情况下直接从签到响应中提取）
 * ArkTS 严格模式：不能用内联对象字面量类型作为字段类型，需要独立 class
 */
export class GeetestParams {
  gt: string = "";
  challenge: string = "";
}

export class GeetestRequiredError extends Error {
  readonly triggerType: GeetestTriggerType;
  /** HAS_PARAMS 时有值，直接传给 GeetestDialog；NEED_CREATE 时为 null */
  readonly geetestParams: GeetestParams | null;

  constructor(triggerType: GeetestTriggerType, geetestParams?: GeetestParams) {
    super("需要 Geetest 人机验证");
    this.triggerType = triggerType;
    this.geetestParams = geetestParams ?? null;
  }
}

export class RoleNotPublicError extends Error {
  constructor() {
    super("该角色的战绩未公开");
  }
}
export class RateLimitedError extends Error {
  constructor() {
    super("请求过于频繁，请稍后再试");
  }
}
```

```typescript
try {
  await GenshinRepository.getInstance().fetchDailyNote(
    accountId,
    roleId,
    server,
  );
} catch (e) {
  // ArkTS 严格模式：catch 的 e 是 unknown 类型，需要先转为 Error 再访问 .message
  // 注意：ArkTS 严格模式禁止 unknown 类型，catch 参数实际类型是 Object
  // 使用 instanceof 判断时，需要确保错误类是从 Error 继承的
  if (e instanceof AuthExpiredError) {
    this.showReLoginDialog = true;
  } else if (e instanceof GeetestRequiredError) {
    // 构建 GeetestTrigger 并加入队列（具体字段根据当前请求上下文填充）
    // ArkTS 严格模式：禁止对象字面量，改为 new GeetestTrigger() 并逐字段赋值
    // this.enqueueGeetest(trigger); // 见 enqueueGeetest() 方法
  } else if (e instanceof RateLimitedError) {
    // instanceof 后可直接访问子类字段
    this.networkErrorMsg = (e as RateLimitedError).message;
  } else if (e instanceof Error) {
    this.networkErrorMsg = (e as Error).message;
  } else {
    // 兜底：非 Error 类型（如字符串 throw）
    this.networkErrorMsg = String(e);
  }
}
```

> **ArkTS 严格模式注意事项：**
>
> - `catch (e)` 中的 `e` 在 ArkTS 严格模式下类型为 `Object`，不能直接访问 `.message`
> - 必须先用 `instanceof` 判断，再用 `as` 类型断言访问具体字段
> - 禁止 `throw 'string'`，只允许 `throw new Error('message')`，这样 `instanceof Error` 判断才可靠
> - 自定义错误类必须继承 `Error`（如 `class AuthExpiredError extends Error`），否则 `instanceof` 判断失效

---

## CoreInitializerV2 完整设计

详见 `game-data-database-redesign/design.md` 中的"CoreInitializerV2 初始化流程"章节。

API 层视角的关键点：

- `CoreInitializerV2.initCore()` 负责创建所有 Service 实例并注入到 Repository
- Service 实例由 `MihoyoApiServiceFactory` 根据 `MihoyoEnvironment` 创建
- ViewModel 通过 `Repository.getInstance()` 获取单例，无需感知 Service 的具体实现
- **salt 注入**：`initCore()` 在步骤 1.7 从 `rawfile/release/salt_config.json` 读取 salt 值并调用 `DSUtilV2.setSalts()`，确保 DS 签名在任何 API 调用前已就绪。Mock 环境注入占位字符串（如 `"mock_salt"`），因为 MockService 不调用 `MihoyoHeaderBuilder`，不会实际使用 salt
- **初始化顺序保证**：ViewModel 必须在 `await CoreInitializerV2.waitForReady()` 之后才能调用 Repository，否则 `service` 为 null 会抛出明确错误

---

## Geetest 人机验证设计

### 触发场景

| 场景                                       | retcode    | 触发类型      |
| ------------------------------------------ | ---------- | ------------- |
| 游戏记录接口（便笺、角色列表等）频繁请求   | `10035`    | `NEED_CREATE` |
| 大别野签到 / 米游币任务                    | `1034`     | `NEED_CREATE` |
| 游戏签到（is_risk=true，响应里直接带参数） | 无 retcode | `HAS_PARAMS`  |

### 完整流程

```
任意 API 请求
    │
    ▼ retcode=10035 或 1034
Repository.handleApiError()
    │ → 抛出 GeetestRequiredError(NEED_CREATE)
    ▼
ViewModel 捕获
    │ → 调 BBSRepository.getInstance().createVerification(cookie)
    │   （BBSRepository 暴露此方法，内部委托给 MihoyoAccountApiService）
    │ → 把 createResult + cookie + 请求上下文 打包成 GeetestTrigger
    │ → 写入 @Trace geetestTrigger（触发 UI 响应）
    ▼
View 层 @Monitor(geetestTrigger)
    │ → 调 showGeetestDialog(uiContext, trigger.createResult)
    │ → 用户完成验证，SDK 返回 GeetestVerifyInput
    │ → 调 vm.onGeetestResult(verifyInput)
    ▼
ViewModel.onGeetestResult()
    │ → 调 BBSRepository.getInstance().verifyVerification(verifyInput, cookie)
    │   （BBSRepository 暴露此方法，内部委托给 MihoyoAccountApiService）
    │ → 拿到新 challenge
    │ → 调 retryAfterGeetest(trigger, challenge, validate, seccode)
    ▼
Repository 带 x-rpc-challenge/validate/seccode 重新发请求
```

**is_risk=true 的特殊路径（游戏签到）：**

```
游戏签到响应 is_risk=true（响应里直接带 gt/challenge）
    │
    ▼
SignRepository 抛出 GeetestRequiredError(HAS_PARAMS, { gt, challenge })
    ▼
ViewModel 捕获
    │ → 不调 createVerification（已有参数）
    │ → 直接用 geetestParams 构造 GeetestTrigger
    │ → 写入 @Trace geetestTrigger
    ▼
View 层弹窗，用户完成验证
    ▼
ViewModel.onGeetestResult()
    │ → is_risk 情况：不调 verifyVerification
    │ → 直接用 verifyInput.geetest_challenge 作为 challenge 重试签到
    ▼
SignRepository 带 x-rpc-challenge 重新发签到请求
```

### GeetestTrigger 通用设计

```typescript
// entry/src/main/ets/viewmodel/GeetestTrigger.ets
// GeetestCreateResult 定义在 core 模块的 ApiErrors.ets，从 core 导入
import { GeetestCreateResult } from "core";

export enum GeetestSource {
  DAILY_NOTE = "DAILY_NOTE",
  SIGN_BBS = "SIGN_BBS",
  SIGN_GAME = "SIGN_GAME",
}

export class GeetestTrigger {
  source: GeetestSource = GeetestSource.DAILY_NOTE;
  createResult: GeetestCreateResult = new GeetestCreateResult();
  cookie: string = "";
  /** is_risk=true 时为 true，跳过 verifyVerification，直接用 verifyInput.challenge */
  skipVerify: boolean = false;
  /** DAILY_NOTE 专用：游戏标识（如 "genshin"） */
  gameId: string = "";
  /** DAILY_NOTE / SIGN_GAME 专用：游戏内角色 UID */
  roleId: string = "";
  /** DAILY_NOTE / SIGN_GAME 专用：服务器代码 */
  server: string = "";
  /** SIGN_GAME 专用：游戏业务标识（如 "hk4e_cn"），决定走哪个签到接口 */
  gameBiz: string = "";
}
```

### Geetest 队列机制（策略 A：全部排队逐一处理）

**设计原则：**

- 任意 API 触发 Geetest 后，加入全局队列
- 同一时刻只弹一个 Geetest 弹窗，处理完当前的再处理下一个
- 每个 API 都需要独立走完整的 Geetest 流程（challenge 不可复用）
- 队列开始前告知用户总数，每次弹窗显示当前进度（N/Total）
- 用户可以取消当前单个，也可以取消全部剩余

**队列数据结构：**

```typescript
// ViewModel 里维护 Geetest 队列
private geetestQueue: GeetestTrigger[] = [];
private isProcessingGeetest: boolean = false;
private geetestResolve: ((result: GeetestVerifyInput | null) => void) | null = null;
private geetestTotal: number = 0;   // 本轮队列总数（用于显示进度）
private geetestCurrent: number = 0; // 当前处理到第几个

/** 将触发 Geetest 的请求加入队列，并启动处理 */
private enqueueGeetest(trigger: GeetestTrigger): void {
  // 注意：此方法不能是 async，否则调用方会被阻塞直到整个队列处理完
  // 正确做法：同步入队，异步启动 runner
  this.geetestQueue.push(trigger);
  if (!this.isProcessingGeetest) {
    // 队列空闲时启动处理，初始化总数和当前进度
    this.geetestTotal = this.geetestQueue.length;
    this.geetestCurrent = 0;
    // 不 await，让 runner 在后台异步跑
    this.processGeetestQueue();
  } else {
    // 队列处理中：更新总数（新加入的会在当前轮次处理完后继续）
    this.geetestTotal = this.geetestCurrent + this.geetestQueue.length;
  }
}

/** 串行处理队列中的所有 Geetest */
private async processGeetestQueue(): Promise<void> {
  this.isProcessingGeetest = true;
  while (this.geetestQueue.length > 0) {
    // ArkTS 严格模式：禁止 Array.shift()，改用 splice(0, 1)[0]
    const tasks = this.geetestQueue.splice(0, 1);
    const trigger = tasks[0];
    if (trigger === undefined) { break; }
    this.geetestCurrent++;
    // 通知 View 更新进度并弹窗
    this.geetestTrigger = trigger;
    this.geetestProgress = `${this.geetestCurrent}/${this.geetestTotal}`;
    // 等待用户完成验证（带 120 秒超时）
    const verifyInput = await this.waitForGeetest();
    if (verifyInput === null) {
      // 用户取消或超时：检查是否取消全部
      if (this.cancelAllGeetest) {
        this.geetestQueue = []; // 清空队列
        break;
      }
      continue; // 取消当前，继续下一个
    }
    // 验证成功，重试原请求
    try {
      const challenge = trigger.skipVerify
        ? verifyInput.geetest_challenge
        : await BBSRepository.getInstance().verifyVerification(verifyInput, trigger.cookie);
        // 新版：BBSRepository 暴露 verifyVerification() 方法，内部委托给 MihoyoAccountApiService
      await this.retryAfterGeetest(trigger, challenge, verifyInput.geetest_validate, verifyInput.geetest_seccode);
    } catch (e) {
      // ArkTS 严格模式：catch 的 e 是 Object，需要转换
      const msg = e instanceof Error ? (e as Error).message : String(e);
      Logger.error(TAG, `retryAfterGeetest failed: ${msg}`);
    }
  }
  this.isProcessingGeetest = false;
  this.cancelAllGeetest = false;
  this.geetestTrigger = null;
  this.geetestProgress = '';
}
```

**ViewModel 新增字段：**

```typescript
@Trace geetestProgress: string = '';    // 进度文字，如 "1/3"，View 层显示在弹窗标题
@Trace cancelAllGeetest: boolean = false; // 用户选择"取消全部"时设为 true
```

**View 层弹窗标题显示进度：**

```typescript
@Monitor('vm.geetestTrigger')
onGeetestTriggerChanged(_monitor: IMonitor): void {
  const trigger = this.vm.geetestTrigger;
  if (trigger === null) { return; }
  // 标题显示进度，如 "人机验证 (1/3)"
  // 注意：showGeetestDialog 需要增加可选的 title 参数（重构时更新函数签名）
  const title = this.vm.geetestProgress
    ? `人机验证 (${this.vm.geetestProgress})`
    : '人机验证';
  showGeetestDialog(ctx, trigger.createResult, title).then((result) => {
    this.vm.onGeetestResult(result);
  });
}
```

> 注意：`showGeetestDialog` 现有签名只有两个参数（`uiContext`、`createResult`），重构时需要增加可选的第三个参数 `title?: string`，用于显示 Geetest 队列进度。

**用户取消时的选项：**

用户点击弹窗关闭按钮时，如果队列里还有剩余，弹出确认框：

```
"还有 N 个验证待处理，是否取消全部？"
[取消当前]  [取消全部]
```

- 取消当前：`vm.onGeetestResult(null)`，队列继续处理下一个
- 取消全部：`vm.cancelAllGeetest = true`，`vm.onGeetestResult(null)`，队列清空

**waitForGeetest 实现（带超时）：**

```typescript
// ArkTS 严格模式注意事项：
// 1. Promise.race() 在 ArkTS 中支持，但泛型参数必须明确
// 2. 超时 Promise 和验证 Promise 的返回类型必须一致
// 3. geetestResolve 字段类型需要联合类型声明（含 null）
private waitForGeetest(): Promise<GeetestVerifyInput | null> {
  const verifyPromise = new Promise<GeetestVerifyInput | null>((resolve) => {
    this.geetestResolve = resolve;
  });
  const timeoutPromise = new Promise<GeetestVerifyInput | null>((resolve) => {
    setTimeout(() => resolve(null), 120000);
  });
  // ArkTS 严格模式：Promise.race 需要明确泛型，两个 Promise 类型必须一致
  return Promise.race<GeetestVerifyInput | null>([verifyPromise, timeoutPromise]);
}

async onGeetestResult(result: GeetestVerifyInput | null): Promise<void> {
  if (this.geetestResolve !== null) {
    this.geetestResolve(result);
    this.geetestResolve = null;
  }
}
```

> **ArkTS 严格模式注意事项：**
>
> - `geetestResolve` 字段必须声明为 `((result: GeetestVerifyInput | null) => void) | null`，不能省略 null
> - `Promise.race` 的数组元素类型必须完全一致，不能混用 `Promise<T>` 和 `Promise<T | null>`
> - `setTimeout` 在 ArkTS 中可用，但回调内不能访问 `this`（需要提前捕获或使用箭头函数）

### retryAfterGeetest 统一重试

```typescript
private async retryAfterGeetest(
  trigger: GeetestTrigger,
  challenge: string,
  validate: string,
  seccode: string
): Promise<void> {
  if (trigger.source === GeetestSource.DAILY_NOTE) {
    // ArkTS 严格模式：禁止 ! 非空断言，必须显式 null 检查
    const gameId = trigger.gameId;
    const roleId = trigger.roleId;
    const server = trigger.server;
    if (gameId === '' || roleId === '' || server === '') {
      Logger.error(TAG, 'retryAfterGeetest: DAILY_NOTE missing required fields');
      return;
    }
    // 根据 gameId 路由到对应 Repository 的带 challenge 重试方法
    // 各游戏 Repository 需要实现 fetchDailyNoteWithChallenge(roleId, server, cookie, challenge, validate, seccode)
    if (gameId === 'genshin') {
      await GenshinRepository.getInstance().fetchDailyNoteWithChallenge(
        roleId, server, trigger.cookie, challenge, validate, seccode
      );
    } else if (gameId === 'starrail') {
      await StarRailRepository.getInstance().fetchDailyNoteWithChallenge(
        roleId, server, trigger.cookie, challenge, validate, seccode
      );
    } else if (gameId === 'zzz') {
      await ZZZRepository.getInstance().fetchDailyNoteWithChallenge(
        roleId, server, trigger.cookie, challenge, validate, seccode
      );
    }
  } else if (trigger.source === GeetestSource.SIGN_BBS) {
    await SignRepository.getInstance().signBBSWithChallenge(trigger.cookie, challenge);
  } else if (trigger.source === GeetestSource.SIGN_GAME) {
    const gameBiz = trigger.gameBiz;
    const roleId = trigger.roleId;
    const server = trigger.server;
    if (gameBiz === '' || roleId === '' || server === '') {
      Logger.error(TAG, 'retryAfterGeetest: SIGN_GAME missing required fields');
      return;
    }
    await SignRepository.getInstance().signGameWithChallenge(
      gameBiz, roleId, server, trigger.cookie, challenge
    );
  }
}
```

### GeetestDialog 复用说明

`showGeetestDialog(uiContext, createResult)` 接口对所有场景通用：

- `NEED_CREATE` 情况：传入 `createVerification` 返回的 `createResult`
- `HAS_PARAMS` 情况：把 `GeetestRequiredError.geetestParams` 包装成 `GeetestCreateResult` 传入

```typescript
// ViewModel catch 块里处理 HAS_PARAMS 情况（以游戏签到为例）
// ArkTS 严格模式：禁止无类型对象字面量，必须先 new 再赋值
if (
  e instanceof GeetestRequiredError &&
  e.triggerType === GeetestTriggerType.HAS_PARAMS &&
  e.geetestParams !== null
) {
  const fakeCreateResult = new GeetestCreateResult();
  fakeCreateResult.gt = e.geetestParams.gt;
  fakeCreateResult.challenge = e.geetestParams.challenge;
  fakeCreateResult.new_captcha = true;
  // 构造 GeetestTrigger，skipVerify=true 表示不调 verifyVerification
  const trigger = new GeetestTrigger();
  trigger.source = GeetestSource.SIGN_GAME; // 大别野签到时改为 SIGN_BBS
  trigger.createResult = fakeCreateResult;
  trigger.cookie = cookie;
  trigger.skipVerify = true;
  // 填充其他字段（gameBiz/roleId/server 等）
  this.enqueueGeetest(trigger);
}
// is_risk 情况：processGeetestQueue 里 skipVerify=true，
// 直接用 verifyInput.geetest_challenge 作为 challenge，不调 verifyVerification
```

### Geetest JS SDK URL 常量

```typescript
// core/src/main/ets/network/v2/ApiConfigV2.ets
export class ApiConfigV2 {
  // ...
  /** Geetest v3 JS SDK URL */
  static readonly GEETEST_SDK_V3: string =
    "https://static.geetest.com/static/js/gt.0.4.9.js";
  /** Geetest v4 JS SDK URL */
  static readonly GEETEST_SDK_V4: string =
    "https://static.geetest.com/v4/gt4.js";
}
```

> 注意：v3 的 `onClose` 是在用户关闭弹窗后才调用 `getValidate()`；v4 的 `onSuccess` 是在验证通过后立即触发。两者行为不同，`GeetestDialog` 的 HTML 模板需要分别处理。

---

## 签到功能设计

### 签到接口分类

| 类型                           | Domain       | Path 规律                 | 特殊头                                           |
| ------------------------------ | ------------ | ------------------------- | ------------------------------------------------ |
| 大别野签到                     | `BBS_APIHUB` | `/app/api/signIn`         | `x-rpc-client_type: 2`                           |
| 游戏签到（原神/星铁/绝区零等） | `TAKUMI`     | `/event/luna/{host}/sign` | `x-rpc-client_type: 2`，`x-rpc-signgame: {host}` |

### SignApiPath 枚举

```typescript
// core/src/main/ets/network/v2/SignApiPath.ets
export enum SignApiPath {
  /** 大别野每日签到 — Domain: BBS_APIHUB */
  SIGN_BBS = "/app/api/signIn",
  /** 游戏签到基础路径（需拼接 /{host}/sign）— Domain: TAKUMI */
  SIGN_GAME_BASE = "/event/luna",
}

/** 游戏签到的 host 标识（用于拼接 URL 和注入 x-rpc-signgame） */
export enum SignGameHost {
  GENSHIN = "hk4e",
  STARRAIL = "hkrpg",
  ZZZ = "zzz",
  HONKAI3 = "bh3",
}

/** 游戏签到的 actId（米游社活动 ID，签到接口必填） */
export class SignActId {
  static readonly GENSHIN: string = "e202311201442471";
  static readonly STARRAIL: string = "e202304121516551";
  static readonly ZZZ: string = "e202406242138391";
  static readonly HONKAI3: string = "e202306201626331";

  /** 根据 gameBiz 获取对应 actId */
  static fromGameBiz(gameBiz: string): string | null {
    if (gameBiz.startsWith("hk4e")) return SignActId.GENSHIN;
    if (gameBiz.startsWith("hkrpg")) return SignActId.STARRAIL;
    if (gameBiz.startsWith("nap")) return SignActId.ZZZ;
    if (gameBiz.startsWith("bh3")) return SignActId.HONKAI3;
    return null;
  }

  /** 根据 gameBiz 获取对应 host */
  static hostFromGameBiz(gameBiz: string): string | null {
    if (gameBiz.startsWith("hk4e")) return SignGameHost.GENSHIN;
    if (gameBiz.startsWith("hkrpg")) return SignGameHost.STARRAIL;
    if (gameBiz.startsWith("nap")) return SignGameHost.ZZZ;
    if (gameBiz.startsWith("bh3")) return SignGameHost.HONKAI3;
    return null;
  }
}
```

**签到 URL 拼接规则：**

| 接口           | 完整 URL 示例                       |
| -------------- | ----------------------------------- |
| 大别野签到     | `BBS_APIHUB + "/app/api/signIn"`    |
| 原神每日签到   | `TAKUMI + "/event/luna/hk4e/sign"`  |
| 星铁每日签到   | `TAKUMI + "/event/luna/hkrpg/sign"` |
| 绝区零每日签到 | `TAKUMI + "/event/luna/zzz/sign"`   |
| 原神签到状态   | `TAKUMI + "/event/luna/hk4e/info"`  |
| 原神签到奖励   | `TAKUMI + "/event/luna/hk4e/home"`  |

> 注意：游戏签到 URL 由 `SIGN_GAME_BASE + "/" + host + "/sign"` 动态拼接，`SignApiService` 内部根据 `gameBiz` 调用 `SignActId.hostFromGameBiz()` 获取 host 后拼接，不需要为每个游戏单独定义枚举值。

### SignApiService 方法签名

```typescript
// core/src/main/ets/network/v2/SignApiService.ets
// 注意：以下为方法签名说明，实际实现时每个方法需要有完整的函数体
export class SignApiService extends MihoyoApiService {
  /** 大别野每日签到（gid=2） */
  async signBBS(cookie: string, challenge?: string): Promise<object> {
    /* 实现 */ return {};
  }

  /** 游戏每日签到（原神/星铁/绝区零等） */
  async signGame(
    gameBiz: string, // 如 "hk4e_cn"，内部通过 SignActId 映射 actId 和 host
    roleId: string,
    server: string,
    cookie: string,
    challenge?: string,
  ): Promise<object> {
    /* 实现 */ return {};
  }

  /** 获取签到状态（今日是否已签到） */
  async getSignInfo(
    gameBiz: string,
    roleId: string,
    server: string,
    cookie: string,
  ): Promise<object> {
    /* 实现 */ return {};
  }

  /** 获取今日签到奖励信息 */
  async getSignReward(gameBiz: string, cookie: string): Promise<object> {
    /* 实现 */ return {};
  }
}
```

### 签到重试流程（含 Geetest）

```typescript
// SignRepository 里的签到逻辑（以游戏签到为例）
// 注意：SignRepository 持有 SignApiService 类型（不是抽象基类），
// 因为需要调用 signGame() 等签到专属方法（类似 BBSRepository 持有 MihoyoAccountApiService）
// service 字段类型改为 SignApiService | null，setService() 内部做类型断言
async signGame(gameBiz: string, roleId: string, server: string, cookie: string): Promise<void> {
  let challenge: string | undefined = undefined;
  let done = false;

  while (!done) {
    const resp = await this.getSignService().signGame(gameBiz, roleId, server, cookie, challenge) as Record<string, Object>;
    challenge = undefined; // 用完即清

    const retcode = resp['retcode'] as number;
    // is_risk 和 gt/challenge 在 data 子对象里，不在顶层
    const data = resp['data'] as Record<string, Object> | null;
    const isRisk = data !== null ? data['is_risk'] as boolean | undefined : undefined;

    if (retcode === ApiErrorCodes.GEETEST_SIGN) {
      // retcode=1034：需要先调 createVerification
      throw new GeetestRequiredError(GeetestTriggerType.NEED_CREATE);
    }

    if (isRisk === true && data !== null) {
      // is_risk=true：响应里直接带了 gt/challenge（在 data 子对象里）
      // ArkTS 严格模式：禁止对象字面量，改为 new GeetestParams()
      const params = new GeetestParams();
      params.gt = data['gt'] as string;
      params.challenge = data['challenge'] as string;
      throw new GeetestRequiredError(GeetestTriggerType.HAS_PARAMS, params);
    }

    if (retcode !== ApiErrorCodes.SUCCESS) {
      throw new Error(`retcode=${retcode}: ${resp['message'] as string}`);
    }

    done = true;
  }
}
```

### 多账号签到串行流程

```
账号 A 签到队列：[大别野, 原神, 星铁, 绝区零]
    │
    ▼ 大别野签到
    ├── 触发 Geetest（retcode=1034）
    │   ├── 超时（120s）→ 跳过大别野，继续原神
    │   ├── 验证成功 → 带 challenge 重试大别野签到
    │   └── 用户取消 → 弹框：取消当前 or 取消全部
    │       ├── 取消当前 → 跳过大别野，继续原神
    │       └── 取消全部 → 跳过账号 A 剩余，进入账号 B
    ▼ 原神签到 → ...
    ▼ 账号 B 签到队列 → ...
```

### 签到结果存储

签到结果（成功/失败/已签到）不写入 DB，只在 ViewModel 的 `@Trace` 字段里维护，用于 UI 展示当次签到进度。签到历史记录（如果需要）可以后续单独设计。
