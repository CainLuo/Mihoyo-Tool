# BaseApiService 抽离方案（Axios 封装层）

> 状态：**Stage 0-3 已完成（代码迁移 + 旧链路删除 + 四产品 / 两个测试脚本构建通过）；header / retcode 基线未采集，按用户决定延后**
> 归属：Core Kits 重构 / Phase 1.1
> 更新时间：2026-10-21
>
> **执行决定（2026-10-21）**：用户明确要求先完成整个 BaseApiService 迁移，header / retcode 基线采集推迟到整个任务完成后；本文中原先所有“Stage 1 / Stage 2 前必须完成基线”的 Gate 均被该决定覆盖，不再阻塞代码迁移。基线清单仍保留在 [`API-Baseline.md`](API-Baseline.md)，状态仍为 **未采集（NOT DONE）**。
>
> 后续的「`MihoyoApiService` 公共 Header 合并」已记录在第 10 节；本次 BaseApiService 迁移**不实施**，等所有 API Service 整理完后再做。
>
> `suppressGeetestReport`、`baseUrlType`、BBS 三个接口是否显式上报 Geetest / 指纹：**本轮保持原样，不做改名 / 删除 / 行为调整**，统一记录在 §8.7，后续再改。
>
> 本次补充的重点：非 2xx 的 axios 错误路径、`HttpResponse` 漏拆包无法靠类型检查、直接 `return this.get/post` 的上报漏点、逐接口上报审计、BBS / Auth 的行为差异、`HttpService` 非 debug 覆盖显式 Cookie、旧错误形态差异、日志脱敏与基线、测试脚本只是构建、`baseUrlType` 的去留。
>
> 已确认的决定：
> - `BaseApiService` 只做 axios 封装和 HTTP 状态码处理；
> - Base 返回项目自己的 `HttpResponse { status, data }`，具体 API 自己取 `response.data`，不依赖 axios 类型；
> - `response.data` 由具体 API 拆包，Base 不拆；
> - Geetest / 设备指纹上报由具体 API 自己显式调用，Base 和 `MihoyoApiService` 都不自动上报；
> - 保留现有 `MihoyoApiService` 继承层；
> - 只实现当前需要的 `get / post`，不补 `put / delete`；
> - 迁移完成后删除 `HttpClient` / `HttpService` / `NetworkFactory` 等旧链路。

---

## 1. 目标

抽一个公共的 `BaseApiService`，作为构建链路内唯一的 axios 封装层：

```text
@ohos/axios
    ↑
BaseApiService          ← 唯一 import axios、唯一调用 axios 的类
    ↑
MihoyoApiService        ← 保留现有抽象层，作为米游社 API 的公共类型
    ↑
MihoyoAccountApiService
GenshinApiService
StarRailApiService
ZZZApiService
SignApiService
```

约束：

1. `BaseApiService` 内部完成 `axios.create()`、`get()`、`post()`；
2. 5 个具体 Service 继续 `extends MihoyoApiService`，不直接改成 `extends BaseApiService`；
3. `MihoyoApiService` 改为 `extends BaseApiService`，不再重复声明抽象的 `get / post`；
4. 具体 Service 不再直接 import axios，也不再直接操作 axios 实例、方法、响应类型；
5. 以后 axios 升级导致方法名、属性名、类型变化，只改 `BaseApiService`；
6. `BaseApiService` 不负责业务 URL、米游社 header、DS 签名、Cookie 内容、`retcode`、Geetest/指纹上报。

最终验收时应该能做到：

```bash
grep -R "from '@ohos/axios'" core/src entry/src
# 只允许出现 BaseApiService.ets 一个文件
```

> 注意：`entry` 的 `WidgetImageDownloader` 使用 `@ohos.net.http` 下载 Widget 图片，不是米游社 API 请求；它不使用 axios，也不纳入 BaseApiService 或 header / retcode 基线。这里只收口 axios 链路。
>
> 注意：这是**最终验收**。Stage 0-2 期间 `HttpClient` / `HttpService` 曾暂时保留；当前旧 transport 已删除，不能再按旧链路回退。

---

## 2. 继承关系调研（先看清楚，不先删）

### 2.1 当前真实继承关系

```text
MihoyoApiService（抽象，只有 get/post 声明）
├── MihoyoAccountApiService（main）
├── MihoyoAccountApiService（internal overlay）
├── GenshinApiService
├── StarRailApiService
├── ZZZApiService
└── SignApiService

APIs.ets / BaseApiService（旧抽象，只有方法声明）
└── HttpService（旧 transport，只被 NetworkFactory 使用）

HttpClient（独立静态类，不继承任何基类）
```

关键事实：

- 5 个业务 Service 和 internal overlay 都继承 `MihoyoApiService`；
- `MihoyoApiService` 目前只有抽象 `get / post`，没有实现；
- `HttpService` 继承的是 `APIs.ets` 里旧的抽象 `BaseApiService`，和业务 Service 不是同一条继承链；
- `HttpClient` 是独立静态类，业务 Service 现在直接调用它；
- `NetworkFactory` 返回旧 `BaseApiService`，实际创建 `HttpService`。

### 2.2 因此不能直接删掉 MihoyoApiService

正确层级是：

```text
BaseApiService（新，具体实现）
    ↑
MihoyoApiService（保留，抽象/公共类型）
    ↑
5 个具体 Service
```

这样：

- 业务 Service 的 `extends MihoyoApiService` 不用改；
- `MihoyoApiServiceFactory`、`GameRepository`、`SignRepository` 等现有类型不用大改；
- `BaseApiService` 只负责 HTTP；
- `MihoyoApiService` 继续作为米游社 API 的稳定抽象边界，后续可以放米游社公共逻辑，但本次不塞业务逻辑。

`MihoyoApiService` 需要改的只有：

```ts
export abstract class MihoyoApiService extends BaseApiService {
  // 不再声明 abstract get/post
  // 具体实现由 BaseApiService 继承下来
}
```

如果保留 `abstract get/post`，具体 Service 就仍然必须实现，等于白抽。

---

## 3. BaseApiService 的职责边界

### 3.1 放进 Base 的内容

- `import axios` / `AxiosInstance` / axios 响应类型
- `axios.create()` 单例
- timeout
- debug 环境信任所有证书
- `RequestParams` / header `Map` → axios `Record` 的转换
- `get / post` 的 axios 调用
- HTTP 状态码判断：**只接受 200**
- HTTP 层日志：方法、脱敏后的 URL、状态码、耗时、错误类型；不打印 Cookie / 完整 header / 响应 body
- axios 异常 / 网络异常统一转成项目错误类型；**非 2xx 必须从 `error.response` 提取 status / body**
- 日志调用自身 try/catch，`ApiLogSystem` 未初始化时不能影响请求

### 3.2 不放进 Base 的内容

- `response.data` 拆包
- 业务 `retcode` 判断
- 1034 / 10035 Geetest 上报
- 5003 / 10041 设备指纹上报
- 业务错误日志（`retcode` / `message`）
- 米游社 URL 拼接
- `MihoyoHeaderBuilder` 的 profile 选择
- DS 签名
- Cookie 内容
- 游戏业务字段解析
- Repository 的缓存 / DB / 同步逻辑

### 3.3 响应与错误形态

#### 为什么不直接返回 `AxiosResponse` 或 `object`

这里有三个选择：

| 做法 | 问题 |
| --- | --- |
| Base 直接 `return response.data as object` | Base 已经拆包，违反“`response.data` 由具体 API 拆”的要求 |
| Base 直接 `return response` | Base 没拆包，但具体 API 要写 `response.data`，就必须 import `AxiosResponse`；axios 升级仍然会影响具体 API |
| Base 返回项目自己的 `HttpResponse { status, data }` | Base 不返回业务 body，具体 API 自己取 `response.data`，且不依赖 axios 类型 |

**已确认选择第三种。** 这里的 `HttpResponse.data` 只是 **HTTP 响应体**，不是米游社业务里的 `data` 字段；具体 API 仍然要自己处理 `retcode` 和业务 `data`。

Base 不把 `response.data` 直接作为返回值，也不把 axios 的 `AxiosResponse` 直接暴露给具体 Service；它只把整个 HTTP 响应转成下面的项目包装，`data` 字段仍是原始 HTTP body，业务拆包仍由具体 API 做。项目自己的响应包装定义如下：

```ts
// HttpTypes.ets（不 import axios）
export class HttpResponse {
  status: number = 0;
  data: object = new Object();
}

export class HttpError extends Error {
  statusCode: number = 0;
  body: object = new Object();

  constructor(statusCode: number, message: string, body: object = new Object()) {
    super(message);
    this.statusCode = statusCode;
    this.body = body;
  }
}
```

Base 返回：

```ts
async get(url: string, params?: RequestParams, options?: RequestOptions): Promise<HttpResponse>
async post(url: string, data?: string | RequestParams, options?: RequestOptions): Promise<HttpResponse>
```

具体 API 自己拆包：

```ts
const response = await this.get(url, params, opts);
return response.data;
```

这样：

- 具体 API 仍然自己处理 `response.data`；
- 不会把 axios 的 `AxiosResponse` 类型泄漏到业务层；
- Base 只负责 HTTP 状态，不碰业务 `retcode`。

HTTP 状态处理：

- `status === 200`：返回 `HttpResponse`；
- `status !== 200`：抛 `HttpError`，带上状态码和响应体；
- 网络错误 / 无响应：抛 `HttpError(0, message)`；
- 不把非 200 的响应体当正常结果返回。

> 这里说的“HTTP Error code”按 **HTTP status** 理解，不是米游社业务 `retcode`。如果业务 `retcode` 也要在 Base 拦截，就和“具体 API 拆包”冲突，需要单独确认。

#### 3.3.1 两个实现陷阱（必须写进实现）

**（1）axios 默认对非 2xx 直接 reject**

`axios.get/post` 默认只把 2xx 当成功，4xx / 5xx 会进入 `catch`。如果 Base 在 `catch` 里一律抛 `HttpError(0, ...)`，就会把真实的 HTTP 401 / 500 误判成“网络错误”，也拿不到响应体。实现必须二选一：

- 给 axios 配 `validateStatus` 接受所有状态，再在正常响应里判断 `status`；
- 或在 `catch` 里读取 `error.response.status` / `error.response.data`，再抛 `HttpError(status, message, body)`。

只有 `error.response` 不存在（超时、断网、DNS 失败等）才使用 `HttpError(0, message)`。同时要确认现有接口没有 201 / 204 / 206 等非 200 成功状态；如果有，需要单独决定是否放宽到 2xx，不能默默改。

**（2）`HttpResponse` 仍然是 `object`，类型检查兜不住漏拆包**

`HttpResponse` 是类实例，`Promise<HttpResponse>` 可以赋给 `Promise<object>`。把 `return HttpClient.get(...)` 机械改成 `return this.get(...)`，**编译不会报错**，但运行时会拿到整个 `HttpResponse`，`retcode` / `data` 全部错位。因此不能把“类型检查”当验收手段，必须：

- 每个具体 API 方法显式写 `const response = await this.get(...); return response.data;`；
- 在 Stage 1 用 grep 审计直接 return：
  ```bash
  grep -RIn "return this\.\(get\|post\)(" core/src/main/ets/network core/src/internal/ets/network
  grep -RIn "return HttpClient\.\(get\|post\)(" core/src/main/ets/network
  ```
- 对 `await this.get(...)` 后直接读 `retcode` / `data` 的地方逐个确认已经取 `.data`；
- 真机 / Mock 只做最终确认，不能替代代码审计。

#### 3.3.2 错误形态与敏感信息

当前两套旧 transport 的错误形态并不一致：

- `HttpClient` 在 `catch` 里把所有 axios 异常都包装成普通 `Error`，**HTTP status / response body 丢失**；
- `HttpService` 不捕获，axios 原始错误直接向上抛；
- 新 Base 统一抛 `HttpError extends Error`，业务层现有 `error instanceof Error` 仍能捕获，但错误消息、类型和可读取字段会变化，必须回归错误提示。

实现时还要注意：

- `HttpError.message` 不要包含完整 URL query / Cookie / token；需要保留定位信息时只放方法 + 脱敏 URL + 状态码；
- 错误日志同样要脱敏，不能因为“出错”就把完整 URL 或 `error.response` 原样打印；
- `HttpError.body` 只用于调用方需要时读取，Base 日志最多记录 body 大小 / 类型，不打印内容。

### 3.4 get / post 之外的方法

当前 `HttpClient` 只有 `get / post`，实际业务也只用这两个。`HttpService` 的 `put / delete` 没有调用方。

因此本次只实现：

```ts
get()
post()
```

不补 `put / delete`。

---

## 4. 迁移前调用点盘点（历史）

> 以下内容记录迁移前的代码状态，用于审计差异；当前 Stage 0-3 已完成，旧 transport 已删除。

### 4.1 5 个业务 Service 的重复

以下类目前都重复实现了同样的 `get / post`：

- `GenshinApiService`
- `StarRailApiService`
- `ZZZApiService`
- `MihoyoAccountApiService`（main）
- `MihoyoAccountApiService`（internal overlay，路径是 `core/src/internal/ets/network/MihoyoAccountApiService.ets`）
- `SignApiService`

合计 6 个类、12 个重复方法（internal overlay 也要同步改）。

### 4.2 直接调用 `HttpClient` 的位置

| 文件 | 直接调用数 | 说明 |
| --- | ---: | --- |
| `GenshinApiService` | 6 | 便笺、角色、养成计算 |
| `StarRailApiService` | 5 | 便笺、角色、养成计算 |
| `ZZZApiService` | 6 | 便笺、角色、邦布、养成计算 |
| `SignApiService` | 4 | 签到状态 / 签到 / 奖励 |
| `MihoyoAccountApiService`（main） | 14 | 登录、token、账号、二维码 |
| `MihoyoAccountApiService`（internal） | 14 | overlay 版本，同样需要改 |
| `AuthRepository`（main/internal） | 4 + 3 `NetworkFactory` | 登录 fallback |
| `BBSRepository` | 3 `NetworkFactory` | 只有账号详情是 service / fallback 二选一；角色 / 卡片当前始终走旧 transport |
| `DeviceFpService` | 2 | 设备指纹申请 |
| `GeetestService` | 2 | 人机验证申请 / 提交 |
| `ZZZRecordRequest` | 4 | 绝区零设备 / 验证 / 登记 |

> 表中 Service 的“直接调用数”只统计业务方法，不含每个 Service 自己重复的 `get / post` 包装方法。

BBS 三个方法需要拆开看：

- `getBbsAccountDetail`：当前 `service !== null` 时走 `MihoyoAccountApiService.getUserFullInfo`，否则走 `NetworkFactory`，是真正的 fallback；
- `getUserGameRoles`：当前始终走 `NetworkFactory`，没有 service 分支；
- `getGameRecordCard`：当前始终走 `NetworkFactory`，没有 service 分支。

所以后两个不是“删 fallback”，而是“把一直使用的旧 transport 换成 account service”。切换后请求头会从 `HttpService` 的默认 `Content-Type` / `User-Agent`（非 debug 还有自动 Cookie）变成 `MihoyoAccountApiService` 的 BBS profile + DS，属于行为变更，必须单独回归登录、账号详情、角色列表、战绩卡片。

另外，`getUserFullInfo(uid, cookie)` 现在无论 `uid` 是否为空都会 `params.set('uid', uid)`；旧 fallback 只在 `uid.length > 0` 时设置。cookie 缺少 `account_id` 时要确认空 `uid` 不会让接口返回异常。

`AuthRepository.getLTokenBySTokenLegacy` 没有调用方，且内部仍走 `NetworkFactory`。迁移时直接删除这个方法（main / internal 两份），否则会为了一个死方法保留旧 transport。

### 4.3 旧 transport 的真实使用情况

- `HttpService` 只被 `NetworkFactory` 创建；
- `NetworkFactory` 被 `AuthRepository` 的 fallback，以及 `BBSRepository` 的 1 个 fallback + 2 个始终走旧 transport 的方法使用；
- `HttpService.put / delete` 没有业务调用方；
- `GeetestService` 顶部 import 了 `NetworkFactory`，但文件内没有实际使用；
- `HttpService` 在所有环境都设置默认 `Content-Type: application/json` / `User-Agent`；自动 Cookie 注入只在**非 debug** 分支的请求拦截器里（debug 分支直接 return，不装拦截器）。删除 `HttpService` 前必须确认调用方都显式设置了 Cookie 和必要 header；
- 非 debug 的 Cookie 拦截器是**无条件覆盖** `headers['Cookie']`，不是“缺失时才补”。因此 Auth / BBS 的旧 fallback 在 debug 与 release 下可能使用不同 Cookie；切到 Service 后以 Service 显式传入的 Cookie 为准，必须按环境回归；
- `HttpService.post` 只接受 `RequestParams`，而 `HttpClient.post` 接受 `string | RequestParams`；新 Base 要保留 `string | RequestParams`，不能收窄成 `HttpService` 的签名；
- `RequestOptions.baseUrlType` 目前只被 `HttpService.buildUrl` 读取，而且 `buildUrl` 直接返回原 URL、不生效；`HttpClient` 完全不读。字段注释说“对应 ApiConfig 中的枚举值，不传时默认 PUBLIC_DATA”，但 `ApiConfig` 里没有这个枚举，实际默认值是空字符串。它是历史遗留的 no-op 字段，`HttpService` 删除后会变成没有读取方的字段；
- 已核对初始化时序：`LoginViewModel` / `HomeViewModel` 在 `CoreInitializer.waitForReady()` 之后调用 `AuthRepository` / 触发冷启动 Cookie 检查；`WidgetSyncAbility` 在 `initCore().then(...)` 内执行同步；`ColdStartCookieChecker` 由 `HomeViewModel` 首屏加载后触发。因此删除 fallback 后，正常调用路径上 `accountService` 已注入。

> 额外发现：仓库根目录还有一份 `internal/core/ets/network/HttpClient.ets`、`APIs.ets`、`MihoyoApiService.ets`、`MihoyoAccountApiService.ets`，是旧登录隔离方案的 overlay 副本。`core/build-profile.json5` 当前使用的是 `./src/internal`，不是 `internal/core`，所以这份目录不参与构建。本次主迁移只改构建链路内的 `core/src/main`、`core/src/internal`、`entry/src`；`internal/core` 作为历史副本单独处理，避免误改或扩大范围。

### 4.4 自动上报逻辑的现状

`HttpClient` / `HttpService` 现在会对每个响应做：

- `retcode === 1034 / 10035` → `GeetestReporter.report(...)`
- `retcode === 5003 / 10041` → `FingerprintReporter.report(...)`
- `options.suppressGeetestReport === true` 时**同时跳过 Geetest 和指纹上报**（不是只跳过 Geetest）；它不改变请求、不改变 `retcode` 判断，也不抑制 `HttpClient` 自己的业务错误日志
- `retcode !== 0` 时写业务错误日志
- `retcode === 0` 时写成功响应日志

便笺 / Widget 还会在 Repository 层显式上报一次（两边都失败时），但当前 Repository 只调用 `GeetestService.reportRequired`，没有指纹上报分支；因此便笺 / Widget 的 5003 / 10041 目前实际上被完全抑制，不会触发指纹弹框。

其他容易忽略的点：

- `GeetestReporter.roleUidOf()` 的 GET 分支只查 `role_id`，不查 `uid`；BBS / 账号类接口如果以后需要上报，`roleUid` 会是空字符串。helper 必须允许显式传 `roleUid`，不能完全依赖 URL / params 自动提取。
- `DeviceFpService` / `GeetestService` / `ZZZRecordRequest` 目前也会被 `HttpClient` 自动上报；改成 `BaseApiService.shared` 后要明确它们是否完全不上报，尤其 `GeetestService.createVerification` 不能再触发上报递归。
- `suppressGeetestReport` 的名字只表达 Geetest，但当前语义是“跳过所有业务上报”。是改名（如 `suppressBusinessReporting`）还是拆分两个标志，需要明确，不能只改注释。

这意味着：

- 把这些逻辑从 `HttpClient` / `HttpService` 两套 transport 拿走，不是“纯搬家”，会影响现有弹框行为；
- Base 按要求不做这些；
- **已确认：选择 B，由具体 API 自己显式调用上报 helper。**
- `MihoyoApiService` 不做自动上报，避免“每个 API 都被默认上报”；
- 迁移时逐个 API 确认：哪些接口需要 Geetest、哪些需要指纹上报、哪些完全不需要。

### 4.5 上报归属审计表（迁移前逐项确认）

> 下表是迁移前的审计起点，不是最终实现。除 §8.7 明确“本轮保持原样”的三项外，其余项在迁移对应 Service 前逐项确认。

| 调用方 / 接口 | 当前行为 | 迁移后建议 | 备注 |
| --- | --- | --- | --- |
| 原神 / 星铁 / 绝区零 便笺、Widget | `suppressGeetestReport = true`，Repository 两路失败后只上报 Geetest | 保持 Repository 现有逻辑 | 指纹当前也被 suppress；本轮保持原样，见 §8.7 |
| 原神 / 星铁 角色列表、角色详情、养成计算 | 自动上报 | 具体 API 显式 helper | helper 需要 params / body |
| 绝区零 代理人 / 邦布 / 养成计算 | 自动上报 | `ZZZApiService` 显式 helper | `ZZZRecordRequest` 只发请求、不再上报；raw header 不要被 Header 合并破坏 |
| 签到状态 / 签到 / 奖励 | 自动上报 | 具体 API 显式 helper | `getSignInfo` 参数是 `uid` 不是 `role_id`，显式传 `roleUid`；注意 `is_risk` 等非 retcode 分支 |
| BBS 账号详情、角色列表、战绩卡片 | account service 路径自动上报；旧 transport 也自动 | 保留现状，迁移时显式复刻；待实测后决定 | `mihoyo-api-sdk` 未说明这三个接口需要 Geetest / 指纹；当前只是 transport 统一策略。迁移时保留现状以免行为回退，`roleUid` 不要拿 BBS `uid` 冒充游戏角色 UID；本轮保持原样，见 §8.7 |
| 米游社 passport / 登录 / 二维码 / token | 自动上报 | 建议不调用 | 登录失败不应弹 Geetest / 指纹 |
| 账号 `createVerification` / `verifyVerification` | 自动上报 | 建议不调用 | 验证接口自身不应再触发验证/指纹上报 |
| `DeviceFpService` | 自动上报 | 建议不调用 | 设备指纹申请失败不应递归上报 |
| `GeetestService` | 自动上报 | 建议不调用 | 已有人工显式 `reportRequired` |
| `ZZZRecordRequest` | 大部分自动上报 | 建议不调用 | 由上层业务接口决定是否上报 |
| `AuthRepository` fallback | 自动上报 | 随 account service 路径统一 | fallback 删除后不再单独考虑 |

这张表没有列全所有方法；Stage 1 修改每个 Service 时必须对照 `HttpClient` / `HttpService` 的调用点补全，不能只看 Service 名称。

> **已发现的现状差异**：`GeetestService.createVerification` / `verifyVerification` 当前没有设置 `suppressGeetestReport`，旧 `HttpClient` 在验证接口自身返回 1034 / 5003 时仍可能自动上报。迁移后这两个自调用不应添加 helper，避免验证递归；基线按实际行为记录，不要把“应该 suppressed”写成现状。

### 4.6 `suppressGeetestReport` / `baseUrlType` 的准确定义

**`RequestOptions.suppressGeetestReport`**

- 默认 `false`；迁移后由具体 API 在调用 `MihoyoApiService.reportBusinessError()` 时传入，`BaseApiService` 不读取。
- 为 `true` 时同时跳过 **Geetest 上报和指纹上报**，名称只写了 Geetest，语义比名称大。
- 它不改变请求内容，不改变业务 `retcode` 判断，也不阻止业务错误日志；只影响“是否调用两个 Reporter”。
- 当前调用点：
  - 原神 / 星铁 / 绝区零的便笺和 Widget：避免便笺失败时立刻弹框，由 Repository 在便笺 + Widget 都失败后自行 `GeetestService.reportRequired()`；
  - `ZZZRecordRequest.geetestOptions()`：验证接口自身不再触发上报，避免递归。
- 迁移后 Base 不再读取它；它只作为具体 API 显式上报时的判断条件。**本轮保持现有“同时抑制 Geetest + 指纹”的语义，不改名、不拆分**；改名（如 `suppressBusinessReporting`）或拆分留到后续，见 §8.7。

**`RequestOptions.baseUrlType`**

- 声明为 `string`，默认 `''`，注释声称对应 `ApiConfig` 枚举且默认 `PUBLIC_DATA`。
- 实际 `ApiConfig` 没有这个枚举；`HttpService.buildUrl(url, _baseUrlType)` 直接 `return url`，`HttpClient` 完全不读。
- 因此它现在是 **no-op 字段**，不会切换任何 base URL。
- `HttpService` 删除后没有读取方。**本轮保持字段原样，不删除、不改造**；等 Phase 4 的 Mock base URL 方案确定后，再决定删除或另建明确配置，见 §8.7。

### 4.7 `mihoyo-api-sdk` 对 BBS 三个接口的核对结果

核对范围：`mihoyo-api-sdk/src/*.tsp`、`generated/openapi/*.yaml`、生成的客户端源码。

- SDK 只把 `retcode` 描述为“Vendor result code. `0` normally represents success”，**没有定义 1034 / 10035 / 5003 / 10041**，也没有任何 BBS 接口的 Geetest / 指纹说明。
- 与当前 BBS 三个方法相关的契约只有 Cookie / DS：
  - `GET /user/wapi/getUserFullInfo`：Cookie、DS 均标为可选（项目当前走 `/user/wapi`，但使用 BBS profile + DS v2）；
  - `GET /binding/api/getUserGameRolesByCookie`：Cookie 必填，DS 可选；
  - `GET /game_record/app/card/wapi/getGameRecordCard`：Cookie、DS 均必填，DS 为 v2。
- 结论：**不能从 SDK 推导出 BBS 账号详情 / 角色列表 / 战绩卡片需要 Geetest 或指纹上报**。当前“所有响应都自动上报”是旧 transport 的统一策略，不是接口契约。
- 迁移动作：迁移这三个方法时（Stage 2）先保留现状（显式调用 helper），避免弹框行为静默回退；同时记录“SDK 未说明、待真机 retcode 基线确认”。`GeetestReporter.roleUidOf()` 只从 query / body 的 `role_id` 或 body 的 `uid` 取值，GET 的 BBS `uid` 不会被识别；而且 BBS `uid` 是账号 UID，不是游戏角色 UID，必须显式传 `roleUid`（没有游戏角色 UID 时传空字符串），不能拿账号 UID 冒充。
- 额外发现：`BBSRepository.getGameRecordCard()` 旧路径只设置 Cookie、没有 DS，而 SDK 标注该接口 DS 必填；切到 account service 后会补上 BBS profile + DS v2。这是行为变化，需重点回归。
- 静态参考补充（2026-10-21）：`mihoyo_apis.md` 历史 App 抓包对 BBS 账号详情 / 战绩卡片使用 `client_type=1` + DS + `Referer: app.mihoyo.com`；TeyvatGuide / PizzaHelperUnited 则使用 `client_type=5` + X4 + `Referer: webstatic`。两种变体都保留在当前代码之外，当前继续使用历史 App 的 BBS profile；P0-07 / P0-08 / P0-09 必须运行时确认，不能仅凭 SDK 的“DS 必填”推断 salt 代际。

---

## 5. 推荐迁移方式（分阶段，不一次性大改）

### Stage 0：建立类型和 Base，保持旧代码可运行（已完成，2026-10-20）

- 新增 `HttpTypes.ets`：`HttpResponse` / `HttpError`，不 import axios；
- 新增 `BaseApiService.ets`：只 import axios，实现 `get / post`、HTTP 状态处理、HTTP 日志；已导出到 `core/Index.ets`；
- Base 的 axios 实例保持懒加载，不能在模块加载/构造时决定 debug 证书策略，避免早于 `AppEnvManager.setup()`；
- Base 的非 200 处理使用 `validateStatus` 接受所有状态，再显式判断 `status === 200`；非 200 抛带真实 `statusCode` / `body` 的 `HttpError`，网络错误 `statusCode = 0`；
- Base 的日志 URL 已脱敏（`stoken` / `ltoken` / `cookie_token` / `ticket` / `token` / `device_fp` / `device_id` / `mid` / `stuid` / `ltuid` / `authkey` 等敏感 query），日志调用自身 try/catch，且不打印 header / body；
- 把 `APIs.ets` 里旧的抽象 `BaseApiService` 临时改名 `LegacyBaseApiService`；
- `HttpService` / `NetworkFactory` 暂时改引用 `LegacyBaseApiService`；
- 未改业务 Service、未改调用方、未删除旧 transport；
- 原计划在删除 `HttpClient` 前记录关键接口基线：完整 URL（脱敏后）、最终 header 名称/关键值、retcode、当前是否上报；不要把 Cookie / token 原文写进文档或提交；具体 API 清单和填写位置见 [`API-Baseline.md`](API-Baseline.md)。**该采集已按用户决定延后到整个任务完成后；旧 transport 已删除，旧路径只能标记为未覆盖。**
- 四个 product 构建 + `test-core.sh` / `test-entry.sh` 已通过（脚本目前只构建 HAP，见 §8.5）。

这一步的目的：先让新 Base 独立存在，不打断旧链路，并原计划把后续无法再获得的 header / 上报基线留存下来；实际基线采集已按用户决定延后，旧 transport 随后删除，因此旧路径基线现已无法补采。

### Stage 1：接入 MihoyoApiService，改 5 个业务 Service（已完成，2026-10-21）

> 状态：5 个主 Service + internal overlay 已完成迁移；`debug` 及随后四产品构建通过；真实接口 header / retcode 对比按用户决定延后。

- `MihoyoApiService extends BaseApiService`，删除抽象 `get / post`；
- 5 个业务 Service 和 internal overlay 删除重复的 `get / post`；
- Service 内部所有 `HttpClient.get/post` 改成 `this.get/post`；
- 每个具体 API 自己 `response.data` 拆包；**不能依赖类型检查**（见 §3.3.1），逐个方法审计直接 `return this.get/post`；
- 业务 `retcode` 判断继续留在具体 API / Repository；
- 按 §4.5 逐接口补显式上报 helper；`suppressGeetestReport` **本轮保持现有“同时抑制 Geetest + 指纹”的语义，不改名、不拆分**，只记录为后续项；具体 API 的 helper 仍读取该字段；
- 保留业务 `retcode` / `message` 日志，Base 只写 HTTP 层日志；
- 先不动 `HttpClient`，保证未迁移的调用方还能跑；
- 构建 + 测试；真实接口 header / retcode 基线对比已按用户决定延后，不作为本轮 Gate。

### Stage 2：收口非 Service 调用方（已完成，2026-10-21）

> 状态：`DeviceFpService` / `GeetestService` / `ZZZRecordRequest`、`AuthRepository` / `BBSRepository` 已完成迁移；四产品构建通过。原先“进入 Stage 2 前先完成 P1-01 ~ P1-14”的 Gate 已被用户的“基线延后”决定覆盖；BBS 新路径的真实 header / DS 回归待任务完成后补做。

按顺序处理，不先删除：

1. `DeviceFpService` / `GeetestService` / `ZZZRecordRequest`
   - 统一通过 `BaseApiService.shared` 发请求；
   - 不再 import `HttpClient`；
   - 自己取 `response.data`；
   - `GeetestService` 删除未使用的 `NetworkFactory` import；
   - 默认不再自动上报；如果某个调用确实需要，由调用方在业务层显式处理。
2. `AuthRepository` / `BBSRepository`
   - 删除 `HttpClient` / `NetworkFactory` old path；
   - 必须使用 `CoreInitializer` 注入的 `MihoyoAccountApiService`；
   - 未初始化时抛出明确错误，不静默走旧 transport；
   - `BBSRepository` 注意：`getBbsAccountDetail` 是 fallback；`getUserGameRoles` / `getGameRecordCard` 是**原本一直走旧 transport**，切换到 account service 后要对比 BBS profile / DS / header；
   - BBS 三个接口是否显式上报 Geetest / 指纹：**本轮保持现状**（迁移时用显式 helper 复刻旧行为），不根据 SDK 未说明就擅自改成“不上报”；最终决定记录在 §8.7；
   - `AuthRepository` 注意：fallback 和 service 的 header 并不完全等价（例如 `loginByMobileCaptcha` 的 `text/plain` vs `application/json`、`createLoginCaptcha` 的 device / UA 字段差异）；删除后以 service 为 canonical，必须验证 service 路径，不要把它当成纯删 transport。
3. 删除 `HttpService` / `NetworkFactory` / `LegacyBaseApiService`（已完成）；
   - 删除前确认 `HttpService` 的默认 `Content-Type` / `User-Agent` 和非 debug 自动 Cookie 不再被任何调用方依赖（代码引用已清零；真实环境回归延后）；
   - `RequestOptions.baseUrlType` **本轮保持原样，不删除、不改造**；`HttpService` 删除后它已没有读取方，记录为后续 Mock base URL 方案确定后再处理。
4. 删除 `HttpClient`（已完成）；
   - 按用户决定，header / retcode 基线采集延后到整个任务完成后；本轮不以此阻塞删除，基线仍未采集，后续必须补做。
5. `core/Index.ets` 清理旧导出，新增 `HttpTypes` / `BaseApiService` 导出（已完成）；旧抽象 `LegacyBaseApiService` 已删除。

### Stage 3：最终验收（代码验收完成；网络 / 真机延后）

> 状态（2026-10-21）：axios 唯一封装、旧 transport 删除、继承关系、`.data` 拆包 grep、四产品构建、两个测试脚本均已通过。真实设备 / Mock 回归、HTTP 401/500/超时验证、header / retcode 基线按用户决定延后。

```bash
grep -R "from '@ohos/axios'" core/src entry/src
# 只命中 BaseApiService.ets
```

- 5 个 Service 都通过 `MihoyoApiService` 间接继承 Base；
- 具体 Service 没有重复 `get / post`；
- 具体 Service 中没有 axios 类型；
- 四个 product 构建；
- `test-core.sh` / `test-entry.sh` 通过（注意：这两个脚本当前是**构建 ohosTest HAP**，不是运行测试；见 §8.5）；
- 真机 / 模拟器验证登录、账号、便笺、角色、养成计算、签到；当前 `hdc list targets` 有可用 target 时不要跳过；
- 对 Base 做 HTTP 401/500/超时/无网络的最小验证，确认 `HttpError.statusCode` 和 `body` 符合预期；
- 确认没有 `return this.get/post` 漏拆包（§3.3.1 的 grep 审计）。

---

## 6. 文件与命名调整

新增：

```text
core/src/main/ets/network/HttpTypes.ets       # HttpResponse / HttpError，不 import axios
core/src/main/ets/network/BaseApiService.ets  # 唯一 import axios
```

`BaseApiService` 额外提供：

```ts
static readonly shared: BaseApiService = new BaseApiService();
```

给 `DeviceFpService` / `GeetestService` / `ZZZRecordRequest` 这些静态工具类使用，不要求它们继承 Base。

`shared` 只负责暴露实例；底层 axios 实例仍要懒加载，不能在模块初始化时根据 `AppEnvManager` 决定 debug 证书策略，否则可能早于 `CoreInitializer.initCore()` 的 `AppEnvManager.setup()`。

axios 实例建议用 `private static` 懒加载，让 `BaseApiService.shared` 和所有 `MihoyoApiService` 子类共用同一个连接池 / 超时 / 证书配置；不要让每个 Service 实例各建一个 axios 实例。

调整：

```text
APIs.ets                 # 只保留 RequestValue / RequestParams / RequestOptions；旧抽象先改名 LegacyBaseApiService，最终删除
MihoyoApiService.ets     # extends BaseApiService，删除 abstract get/post
HttpService.ets          # 过渡期 extends LegacyBaseApiService，最终删除
NetworkFactory.ets       # 过渡期引用 LegacyBaseApiService，最终删除
HttpClient.ets           # 最终删除，不再保留兼容别名
core/Index.ets           # 最终删除 NetworkFactory 导出，新增 BaseApiService / HttpTypes 导出
```

命名冲突的处理是临时方案：旧抽象改名 `LegacyBaseApiService`，等 `HttpService` / `NetworkFactory` 删除后一起删掉。这样不会在 Stage 0 就打断 fallback；最终仓库里不再保留这个名字。

---

## 7. 风险

| 风险 | 影响 | 对策 |
| --- | --- | --- |
| Base 返回 `HttpResponse`，所有 Service 调用点都要多一层 `.data` | 编译不报错，但运行时 `retcode` / `data` 错位 | **类型检查不能兜底**（`HttpResponse` 是 `object` 子类型）；逐方法审计 + grep 直接 `return this.get/post`；Stage 1 每个 Service 单独对比基线 |
| axios 默认对非 2xx reject | 真实的 401 / 500 被误判成 `statusCode = 0`，`HttpError.body` 丢失 | 在 `catch` 里读 `error.response`，或用 `validateStatus` + 显式 status 判断；只有无 response 才用 0 |
| Base 只接受 200，但现有 axios 默认接受 2xx | 201 / 204 / 206 接口回归 | 迁移前确认接口状态码；如有非 200 成功状态，单独决定是否放宽到 2xx |
| 自动 Geetest / 指纹上报被移除 | 弹框行为变化，且可能漏报 1034 / 5003 | 按 §4.5 逐接口审计；直接 `return this.get/post` 的方法要在 return 前显式调用 helper；便笺 / Widget 保持 Repository 逻辑 |
| `suppressGeetestReport` 当前同时抑制指纹 | 名称与行为不一致，迁移后可能误改 | 本轮保持原样；后续改名 / 拆分时再改语义，迁移时只复刻现状（§8.7） |
| `GeetestReporter.roleUidOf` GET 不识别 `uid` | BBS / 账号接口上报时 `roleUid` 为空 | helper 显式接收 `roleUid`；不要只依赖 URL / params 自动提取 |
| `BBSRepository` 有两个方法始终走旧 transport | 误以为只是删 fallback，实际 header / DS 改变 | `getUserGameRoles` / `getGameRecordCard` 切换到 account service 后单独回归登录、账号、角色、卡片 |
| `AuthRepository` fallback 与 service header 不等价 | 删 fallback 后 service 路径暴露差异（如 `text/plain` vs `application/json`） | 以 service 为 canonical；先验证 service 路径；不要把它当成纯 transport 删除 |
| 删除 `HttpService` 后默认 header / Cookie 行为变化 | 账号 / BBS 请求失败 | 对比默认 `Content-Type` / `User-Agent`；non-debug 拦截器会**覆盖**显式 Cookie，不能按“缺失才补”理解；所有调用方显式设置并按环境回归 |
| `RequestOptions.baseUrlType` 变成死字段 | 清理不彻底，或未来 Mock 接入时重复造字段 | 本轮保留原样；Phase 4 Mock base URL 方案确定后再决定删除或改造（§8.7） |
| Base 日志泄露 Cookie / token / URL query | 安全 / 隐私问题 | URL 脱敏（`stoken` / `ltoken` / `cookie_token`），不打印完整 header / body；日志 try/catch |
| Base 在 `ApiLogSystem` 初始化前写日志 | 启动阶段请求被日志异常打断 | 日志调用 try/catch；axios 懒加载，避免早于 `AppEnvManager.setup()` |
| `AuthRepository` 在 Core 初始化前被调用 | 删除 fallback 后直接报错 | 先检查调用时序，确保 Core 初始化先完成；未初始化时抛明确错误，不静默兜底 |
| `test-core.sh` / `test-entry.sh` 只是构建 HAP | 误以为网络行为已经测试过 | 明确标记“编译验证”；另做 Mock / 真机接口回归；当前 `hdc` 有可用 target 时执行安装验证 |
| `core/src/internal` overlay 漏改 | debug/internal 包编译过但功能异常 | main 与 `core/src/internal` 两个 `MihoyoAccountApiService`、`AuthRepository` 同步改；构建 internal |
| 误改根目录 `internal/core` 历史副本 | 改了不参与构建的文件，浪费或引入混淆 | 本次只改构建链路；`internal/core` 单独确认后清理 |
| 一次性删除 `HttpClient` / `HttpService` / `NetworkFactory` | 大面积回归，且丢失基线 | 已按 Stage 分步实施；基线采集按用户决定延后，旧路径已删除，后续补采新路径并做真机回归 |

---

## 8. 已确认方案与实施清单

### 8.1 已确认

1. **Base 响应包装**：使用项目自己的 `HttpResponse { status, data }`；具体 API 自己取 `response.data` 解包，不依赖 axios 类型。
2. **Geetest / 指纹上报**：选择 B，具体 API 自己显式调用上报 helper；Base 和 `MihoyoApiService` 都不自动上报。
3. **迁移范围**：迁移并删除构建链路内的多余网络实现，最终 `core/src` + `entry/src` 只有 `BaseApiService` import axios；根目录 `internal/core` 历史副本单独确认。
4. **非 Service 调用方**：`DeviceFpService` / `GeetestService` / `ZZZRecordRequest` 使用 `BaseApiService.shared`，不要求继承。
5. **HTTP 错误**：非 200 统一抛 `HttpError`，带 `statusCode` / `body`；网络错误 `statusCode = 0`，保留可读的 `message`。
6. **公共 Header 合并**：本次不做；Header 抽象类负责管理，`MihoyoApiService` 负责合并，等所有 ApiService 整理完后作为后续项实施，详见第 10 节。

### 8.1.1 实现约束（不改变上面的决定）

1. **非 2xx 提取**：不能把所有 axios `catch` 都当网络错误；必须从 `error.response` 取 status / body，或使用 `validateStatus` + 显式判断。只有无 response 才是 `statusCode = 0`。
2. **拆包审计**：`HttpResponse` 是 `object` 子类型，类型检查不会拦住漏拆包；必须逐方法审计并 grep 直接 `return this.get/post`。
3. **上报语义**：`suppressGeetestReport` 目前同时抑制 Geetest + 指纹；**本轮保持原样**，不改名、不拆分（见 §8.7）。上报 helper 要显式接收 `cookie` / `roleUid`，不能完全依赖 `roleUidOf` 自动提取。
4. **BBS / Auth 行为**：`BBSRepository` 的两个方法不是 fallback；`AuthRepository` fallback 与 service header 不等价。两者都要按“切换实现”而不是“纯删旧代码”验证。
5. **日志与基线**：Base 不打印完整 header / Cookie / body；URL query 要脱敏。原计划删除 `HttpClient` 前记录关键接口的 header / retcode 基线；该采集已按用户决定延后，旧路径已删除，只能补采新路径。
6. **测试口径**：`test-core.sh` / `test-entry.sh` 只构建 HAP，不代表网络行为已测试；真实回归需要 Mock 服务或设备。
7. **死字段**：`RequestOptions.baseUrlType` 在 `HttpService` 删除后无读取方；**本轮保留原样**，后续随 Mock base URL 方案决定删除或改造（见 §8.7）。
8. **直接返回包装**：`return this.get/post` 不能只加 `.data`；原本依赖 transport 自动上报的方法，必须在 return 前调用 helper。
9. **Cookie 覆盖**：`HttpService` 非 debug 拦截器会覆盖调用方显式 Cookie；删除 fallback 后以 Service 显式 Cookie 为准，并按 debug / release 分别回归。
10. **错误形态**：`HttpClient` 当前把非 2xx 包装成普通 `Error`，`HttpService` 直接抛 axios error；新 Base 统一 `HttpError`，错误消息 / 日志要脱敏，且保持 `instanceof Error`。

### 8.2 文件级变更

新增：

```text
core/src/main/ets/network/HttpTypes.ets
core/src/main/ets/network/BaseApiService.ets
```

修改：

```text
core/src/main/ets/network/APIs.ets
  - 只保留 RequestValue / RequestParams / RequestOptions
  - 删除旧抽象 BaseApiService（过渡期可临时改名 LegacyBaseApiService）
  - 更新 suppressGeetestReport 注释：Base 不读取，由具体 API 显式上报时判断；注明当前语义是同时抑制 Geetest + 指纹
  - 更新 extraHeaders 注释：Base 没有默认 header，只透传；默认头 / Cookie 由具体 Service 显式设置
  - baseUrlType：本轮保持字段原样，不删除、不改造；后续 Mock base URL 方案确定后再处理（见 §8.7）

core/src/main/ets/network/MihoyoApiService.ets
  - extends BaseApiService
  - 删除 abstract get/post
  - 删除因此不再使用的 RequestParams / RequestOptions import
  - 更新类注释：HTTP 方法由 Base 继承，MihoyoApiService 只保留米游社业务公共能力 / 后续 header 合并入口

core/src/main/ets/network/GenshinApiService.ets
core/src/main/ets/network/StarRailApiService.ets
core/src/main/ets/network/ZZZApiService.ets
core/src/main/ets/network/SignApiService.ets
core/src/main/ets/network/MihoyoAccountApiService.ets
core/src/internal/ets/network/MihoyoAccountApiService.ets
  - 删除重复的 get/post
  - HttpClient.get/post → this.get/post
  - 具体 API 自己取 response.data
  - 直接 return 的方法也要在 return 前显式上报（原本由 transport 自动上报的不能漏）
  - 具体 API 自己判断 retcode
  - 需要 Geetest / 指纹上报的 API 显式调用 helper

core/src/main/ets/repository/AuthRepository.ets
core/src/internal/ets/repository/AuthRepository.ets
  - 删除 HttpClient / NetworkFactory old path
  - 必须使用已注入的 MihoyoAccountApiService
  - 未初始化时抛明确错误
  - 删除无调用方的 getLTokenBySTokenLegacy（main / internal 两份）
  - 清理 fallback 删除后不再使用的 import
  - 注意 fallback 与 service 的 header 差异：loginByMobileCaptcha 的 text/plain vs application/json、createLoginCaptcha 的 device / UA 字段；以 service 为 canonical 并验证

core/src/main/ets/repository/BBSRepository.ets
  - 删除 NetworkFactory old path
  - getBbsAccountDetail → MihoyoAccountApiService.getUserFullInfo（原 fallback）
  - getUserGameRoles → MihoyoAccountApiService.getGameRoles（原始终走旧 transport）
  - getGameRecordCard → MihoyoAccountApiService.getGameRecordCard（原始终走旧 transport）
  - 增加 getAccountService() 之类的检查：service 为 null 或不是 MihoyoAccountApiService 时抛明确错误；不要直接强转
  - 对比 BBS profile / DS / header；getUserFullInfo 空 uid 行为单独确认
  - 删除 HttpClient / NetworkFactory / RequestParams / RequestOptions 等不再需要的 import

core/src/main/ets/network/DeviceFpService.ets
core/src/main/ets/network/GeetestService.ets
core/src/main/ets/network/ZZZRecordRequest.ets
  - HttpClient.get/post → BaseApiService.shared.get/post
  - 自己取 response.data
  - 默认不再自动上报；需要上报时由上层显式处理
  - GeetestService 删除未使用的 NetworkFactory import

core/Index.ets
  - 删除 NetworkFactory 导出
  - 新增 BaseApiService / HttpTypes 导出
  - APIs 仍导出 RequestValue / RequestParams / RequestOptions
```

删除：

```text
core/src/main/ets/network/HttpClient.ets
core/src/main/ets/network/HttpService.ets
core/src/main/ets/network/NetworkFactory.ets
APIs.ets 里的 LegacyBaseApiService（如果过渡期使用了）
```

不在本次构建链路内、但需要单独确认：

```text
internal/core/ets/network/HttpClient.ets
internal/core/ets/network/APIs.ets
internal/core/ets/network/MihoyoApiService.ets
internal/core/ets/network/MihoyoAccountApiService.ets
internal/core/ets/network/mock/MihoyoAccountMockService.ets
```

这些是旧登录 overlay 的历史副本，当前 `core/build-profile.json5` 没有引用 `internal/core`，不参与四个 product 的构建。建议在本次迁移完成后单独删除整个 `internal/core`（以及同样过期的 `internal/entry`），但不要和主迁移混在一起；如果希望本次一起删，需要在确认时明确授权。

同时更新注释：

```text
core/src/main/ets/repository/SyncQueueRunner.ets
core/src/main/ets/repository/GenshinRepository.ets
core/src/main/ets/repository/StarRailRepository.ets
core/src/main/ets/repository/ZZZRepository.ets
core/src/main/ets/network/GeetestReporter.ets
core/src/main/ets/network/FingerprintReporter.ets
core/src/main/ets/network/GenshinApiService.ets
core/src/main/ets/network/StarRailApiService.ets
core/src/main/ets/network/ZZZApiService.ets
entry/src/main/ets/utils/GeetestCenter.ets
entry/src/main/ets/utils/DeviceFpCenter.ets
```

这些注释大多写“HttpClient 统一上报”或“便笺请求不自动上报”；迁移后 Base 完全不自动上报，必须改成“具体 API 显式上报 / 该类请求不上报”，否则会误导后续维护。

这些文件里的注释还写着 `HttpClient / HttpService 自动上报`，改成“具体 API 显式上报”或 `BaseApiService`，避免迁移后文档和行为对不上。

### 8.3 实施顺序

1. **Stage 0**：新增 `HttpTypes` / `BaseApiService`；旧抽象临时改名，保证旧链路能编译；四个 product 构建。
   - **原 Gate 已被用户决定覆盖**：原本要求 Stage 1 前完成 [`API-Baseline.md`](API-Baseline.md) 的 P0、Stage 2 删除旧 transport 前补采 BBS 新路径；现改为整个任务完成后统一补采，不阻塞代码迁移。
2. **Stage 1**：改 `MihoyoApiService` + 5 个业务 Service + internal overlay；删除重复 `get/post`；每个 API 自己 `response.data` 拆包；构建。
3. **Stage 2**：迁移 `DeviceFpService` / `GeetestService` / `ZZZRecordRequest`；再处理 `AuthRepository` / `BBSRepository` 的旧 transport（BBS 两个方法是切换实现，不是删 fallback）；构建。
4. **Stage 3**：删除 `HttpClient` / `HttpService` / `NetworkFactory` / `LegacyBaseApiService`；清理导出和注释；跑完整验收。
5. 每一步单独提交；任何一步构建失败，只回滚该步，不跨阶段混改。

### 8.4 具体 API 上报方式

已确认 B，不在 Base / `MihoyoApiService` 做自动上报。实现时：

- 需要上报的 API 在拿到 `response.data` 并读取 `retcode` 后，显式调用 `GeetestReporter` / `FingerprintReporter`，或调用 `MihoyoApiService` 提供的受保护 helper；
- helper 只能由具体 API 主动调用，不能挂在 `get/post` 里自动执行；
- **直接 `return this.get/post` 的包装方法不能只加 `.data`**。必须改成类似：
  ```ts
  const response = await this.get(url, params, opts);
  this.reportBusinessError(url, response.data, opts, params, undefined, cookie, roleId);
  return response.data;
  ```
  否则自动上报会静默丢失；Genshin / StarRail / ZZZ / Sign / Account 的多数方法都属于这种形态。
- helper 建议签名：`reportBusinessError(url, data, options?, params?, requestBody?, cookie?, roleUid?)`；`cookie` / `roleUid` 允许显式传入，不能完全依赖 `headers` / `roleUidOf` 自动提取；
- helper 内部读取 `retcode`，判断 `suppressGeetestReport`，再调用两个 Reporter；`retcode !== 0` 时可以顺带写业务错误日志，Base 只写 HTTP 层日志，不写 Cookie / body；
- 不需要上报的登录、passport、二维码、token 等接口不调用；
- 便笺 / Widget 继续保留 Repository 现有的“两路都失败后上报”逻辑；当前 Repository 只上报 Geetest，**本轮保持现状，不补指纹上报**；
- `RequestOptions.suppressGeetestReport` 不再由 Base 使用，保留给具体 API 判断是否需要上报；`APIs.ets` 里的注释也要同步改成“具体 API 显式上报时使用”，并注明当前同时抑制 Geetest + 指纹；
- `GeetestReporter.roleUidOf` 的 GET 分支只识别 `role_id`，BBS / 账号接口的 `uid` 需要显式传入 `roleUid`；
- `DeviceFpService` / `GeetestService` / `ZZZRecordRequest` 默认不调用 helper；尤其是 `GeetestService.createVerification` 不能触发递归上报。

哪些接口需要上报，按 §4.5 的表逐项确认；游戏数据、角色、养成计算、签到等业务接口需要覆盖；passport / 登录 / 二维码 / token 不覆盖；BBS / 账号类接口不要按“Service 名称”一刀切。不能在 Base 或 `MihoyoApiService` 里图省事统一上报。

### 8.5 验收标准

> 状态（2026-10-21）：代码级验收项已通过；网络 / 真机 / 基线项按用户决定延后，未勾选项不代表已通过。
>
> - [x] `grep -R "from '@ohos/axios'" core/src entry/src` 只命中 `BaseApiService.ets`
> - [x] `grep -R "HttpClient\|HttpService\|NetworkFactory" core/src entry/src` 没有代码引用
> - [x] 5 个业务 Service + `core/src/internal` overlay 都仍然 `extends MihoyoApiService`
> - [x] 只有 `MihoyoApiService` 直接 `extends BaseApiService`；没有其他业务类直接继承 Base
> - [x] 5 个主 Service 和 `core/src/internal` overlay 都没有重复的 `get/post`
> - [x] `AuthRepository` / `BBSRepository` 没有 `NetworkFactory` / `HttpClient` 引用
> - [ ] `BBSRepository.getUserGameRoles` / `getGameRecordCard` 已切到 account service，并对比旧 header / DS 行为（已切换；真实对比待补）
> - [ ] `AuthRepository` 的 service 路径已验证；fallback 与 service 的 header 差异（`text/plain` vs `application/json` 等）已确认（真实请求待补）
> - [x] 具体 Service 没有 import axios / `AxiosResponse`
> - [x] `HttpResponse` / `HttpError` 不 import axios
> - [x] 没有 `return this.get/post` 直接返回 `HttpResponse` 的漏拆包；§3.3.1 的 grep 审计通过
> - [x] 所有原本由 transport 自动上报、迁移后仍需上报的包装方法，都在 return 前显式调用 helper；没有只加 `.data` 就结束（代码审计）
> - [ ] Base 对 HTTP 401 / 500 抛出带真实 `statusCode` / `body` 的 `HttpError`；超时 / 无网络为 `statusCode = 0`（代码已实现；运行时验证待补）
> - [x] `HttpError` 仍是 `Error` 子类，现有 `instanceof Error` / `message` 处理不会失效；错误消息和日志不含 Cookie / token / 完整 query（代码审计）
> - [ ] 已确认没有 201 / 204 / 206 等非 200 成功状态，或已明确放宽到 2xx
> - [x] `suppressGeetestReport` 本轮保持“同时抑制 Geetest + 指纹”，未改名 / 未拆分；该保持项已记录在 §8.7
> - [ ] §4.5 的上报归属表已逐项确认；便笺 / Widget、BBS 账号、passport、DeviceFp、Geetest、ZZZRecord 的行为与基线一致（真实基线待补）
> - [x] BBS 三个接口已按 §4.7 记录“SDK 未说明 Geetest / 指纹”，并明确保留现状、迁移时显式复刻；`roleUid` 未拿 BBS `uid` 冒充
> - [x] `baseUrlType` 本轮保持原样，未删除 / 未改造；已记录为后续 Mock base URL 方案的处理项
> - [ ] 基线已按 [`API-Baseline.md`](API-Baseline.md) 完成（未采集；按用户决定延后；旧路径已删除，后续补采新路径）
> - [x] 四个 product（`default` / `mock` / `debug` / `internal`）构建通过
> - [x] `test-core.sh` / `test-entry.sh` 通过；注意它们只构建 ohosTest HAP，不代表网络测试通过
> - [ ] `hdc` 有可用 target 时，安装并验证登录、账号、便笺、角色、养成计算、签到；当前环境曾检测到 `127.0.0.1:5555`
> - [ ] Mock 服务 / fixtures 能用于至少一个关键接口的联调；当前 mock product 仍走真实 API，不能替代网络回归
> - [x] 不涉及 DB 变更，不需要数据迁移
> - [x] 根目录 `internal/core` 历史副本未被误改；如确认删除，单独提交

### 8.6 迁移前后的 header / retcode 基线采集（当前延后；旧路径已删除）

> 逐接口清单、优先级和填写位置见 [`API-Baseline.md`](API-Baseline.md)。该文件当前状态为 **运行时未采集（NOT DONE）**；按用户决定，采集推迟到整个任务完成后，本节不再阻塞当前代码迁移。
>
> **2026-10-21 静态参考**：已用 `mihoyo-api-sdk`、TeyvatGuide、PizzaHelperUnited 和本项目历史抓包完成 header / DS / retcode 的代码级对照，结论和分歧见 `API-Baseline.md` §2.2。静态对照不等于本机抓包；`参考有分歧` 的链路仍需运行时确认。
>
> **2026-10-21 现状**：旧 `HttpClient` / `HttpService` / `NetworkFactory` 已删除。下表中“迁移前 transport”只用于历史对照；P1-01 / P1-02 / P1-03 / P1-11 / P1-12 / P1-13 的旧路径已无法补采，后续只能标记“未覆盖（旧路径已删除）”。新路径仍可通过 `BaseApiService` 记录。

目标不是保存一份“完整抓包”，而是保存**迁移前后可对比的最小事实**：请求走了哪套 header profile、最终 header 键集合和关键值、Cookie 字段集合、DS 是否存在/哪一代、HTTP 状态、业务 `retcode`、是否触发上报。完整 Cookie、token、`device_fp`、请求体和响应体不进入基线。

#### 8.6.1 采集矩阵

| 链路 | 代表接口 | 迁移前 transport / profile（历史） | 重点 |
| --- | --- | --- | --- |
| 登录 / Passport | `createLoginCaptcha`、`loginByMobileCaptcha`、`getLTokenBySToken`、`getCookieTokenBySToken`、二维码 fetch/query | `MihoyoAccountApiService` 手写 header + `HttpClient` | `Content-Type`、`x-rpc-app_id`、`client_type`、设备字段、Cookie 字段、body 顶层键、retcode |
| BBS 账号 | `getUserFullInfo` | account service 的 BBS profile；`getBbsAccountDetail` 还有 `NetworkFactory` fallback（已删） | BBS profile + DS v2 vs `HttpService` 默认 header；空 `uid` 行为 |
| BBS 角色 / 卡片 | `getUserGameRolesByCookie`、`getGameRecordCard` | 迁移前始终走 `NetworkFactory`（`HttpService`，已删） | 旧路径无 DS；切到 account service 后 DS v2 / UA / Cookie 的差异 |
| 便笺 / Widget | 原神、星铁、绝区零的 `getDailyNote` / `getDailyNoteWidget` | `HttpClient` + Pizza header；ZZZ 走 `ZZZRecordRequest` raw header | `x-rpc-device_fp`（按游戏）、DS X4 / 无 DS、`suppressGeetestReport`、Repository 二次上报 |
| 角色 | 原神 `getCharacterList` / `getCharacterDetail`、星铁 `getAvatarBasic` / `getAvatarInfo`、绝区零 `getAvatarBasic` / `getAvatarInfo` / `getBuddyList` | `HttpClient` + GAME_RECORD / ZZZ raw | `x-rpc-tool_verison`、`x-rpc-page`、`x-rpc-platform`、DS X4 / raw header |
| 养成计算 | 原神 / 星铁 / 绝区零的 `batchCompute` / `compute` | `HttpClient` + CALCULATE / ZZZ profile | 完整 Cookie、`x-rpc-cal_type`、DS X4、body 序列化 |
| 签到 | `getSignInfo`、`sign`、奖励领取 | `SignApiService` + `HttpClient` | SIGN profile、DS X6、`x-rpc-signgame`、`uid` vs `role_id` |

每个仍可触发的 profile 至少采集一条成功请求；BBS 新路径（P0-07 / P0-08 / P0-09）要单独采集。旧路径（P1-01 / P1-02 / P1-03 / P1-11 / P1-12 / P1-13）已无法采集，不能把新路径结果当成旧路径结果。

#### 8.6.2 方式 A：Proxyman 抓包（推荐先做）

1. 启动 Proxyman，开启 HTTPS 解密，确认监听端口（示例 `9090`）。
2. 用现有脚本给模拟器设置代理并安装 debug 包：
   ```bash
   ipconfig getifaddr en0
   bash run.sh debug --proxy "$(ipconfig getifaddr en0):9090"
   ```
   `run.sh` 会执行 `param set persist.netmanager.http_proxy`；debug 包的 `BaseApiService` 在 `AppEnvManager.isDebug()` 下使用 TrustAllManager，可直接接受 Proxyman 证书。若某台设备仍不信任代理证书，改用方式 B。
3. 清空 App 日志后，按 8.6.1 的矩阵走一遍可触发的路径：登录（手机号 / 二维码 / Cookie）、首页便笺与 Widget、账号详情、角色列表/详情、养成计算、签到。旧 transport 路径已删除，不再尝试复现。
4. 导出 HAR，用本地一次性脚本只保留：method、host、path、query **键名**、header **键名 + 白名单值**、Cookie 字段名、DS 是否存在/长度、HTTP status、响应 `retcode`/`message`。原始 HAR 不提交、不贴 issue。
5. 结束抓包：
   ```bash
   bash run.sh --clear-proxy
   ```

#### 8.6.3 方式 B：临时 `ApiBaseline` 记录器（release / internal 对齐）

Proxyman 只能覆盖 debug 的证书信任；`core/src/internal` overlay 和 release 行为需要在 App 内记录。做法：

- 临时新增 `ApiBaseline.ets`，在 `BaseApiService` 的响应 / 异常路径调用；新 Base 没有拦截器，最终 header 就是调用方传入 `RequestOptions.extraHeaders` 的那一份。旧 `HttpService` 的非 debug Cookie 覆盖行为已不存在，不能再靠记录器复现。
- 记录到 `ApiLogSystem`，tag 固定 `ApiBaseline`，走现有日志文件；采集完用 `bash pull-logs.sh debug` 拉取；internal 与 release 共用 bundle，用 `bash pull-logs.sh release` 拉取（注意先确认当前安装的是哪一个）。
- 记录器必须自己脱敏；新 Base 日志本身已不打印完整 header / body，但记录器也不能把 Cookie / token 写进日志。采集前先清空日志，采集后删除记录器。
- 记录器只在临时分支 / 临时构建存在，合并前删除；不要留在产品代码里。旧路径（P1-01/02/03/11/12/13）已删除，无法用这个记录器补采，只能标记未覆盖。

建议记录格式（下面只是字段结构示例，不是已采结果，实际不写 token）：

```json
{
  "transport": "BaseApiService",
  "method": "GET",
  "host": "api-takumi.mihoyo.com",
  "path": "/binding/api/getUserGameRolesByCookie",
  "queryKeys": [],
  "headers": {
    "Content-Type": "application/json",
    "User-Agent": "miHoYoBBS/2.104.0",
    "x-rpc-client_type": "1",
    "Referer": "https://app.mihoyo.com",
    "Cookie": "fields=account_id,cookie_token,ltoken,ltuid",
    "DS": "present(v2)"
  },
  "status": 200,
  "retcode": 0,
  "message": "OK",
  "responseKeys": ["list"],
  "suppress": false,
  "reportDecision": "none"
}
```

> 该接口迁移后走 `BBS` profile，预期是 `client_type=1` + DS v2；旧 `NetworkFactory` 路径只有 Cookie、没有 DS。上面的 `present(v2)` 是记录格式示例，真实结果仍以抓包为准。

`reportDecision` 取 `none` / `geetest` / `fingerprint` / `suppressed`；它来自具体 API 显式调用 `reportBusinessError` 的实际分支，不是按接口名猜的。

#### 8.6.4 错误分支与对比规则

- 正常路径先采 `retcode = 0`；错误分支至少覆盖“Cookie 失效”和“角色不存在/未公开”各一次，优先用无效测试账号或无效 UID，不要为了采 1034 / 5003 对主账号刷请求。
- 另至少覆盖一次 HTTP 非 200（401/403/500）和一次网络断开 / 超时；记录新 Base 的 `HttpError` 形态（真实 status/body；无响应时 `statusCode = 0`），见 [`API-Baseline.md`](API-Baseline.md) 第 2.1 节。旧 transport 的错误形态只作历史对照。
- 如果某条错误分支无法安全触发，基线里明确写“未覆盖”，不要用推测值填表。
- 对比时只允许解释得通的差异：
  - header 键集合 / profile 变化；
  - Cookie 字段集合变化（尤其是 `HttpService` 非 debug 覆盖）；
  - DS 从 absent 变为 v2 / v1；
  - `Content-Type` / UA / `client_type` 变化；
  - retcode 变化；
  - 上报决策变化。
- `DS` 的完整值、`device_fp`、`device_id`、时间戳每次都会变，不能做字符串相等比较；只比较“是否存在、哪一代、长度范围、是否带对应 header”。UA 里的版本号要按实际值比较。
- 基线结果只提交脱敏后的汇总表 / 差异说明，不提交 HAR、原始日志、Cookie 或 token。

### 8.7 本轮保持原样、后续再改的事项

以下三项已经记录，但**不在本次 BaseApiService 迁移中修改**；迁移时只允许复刻当前行为，不允许顺手改名、删除或改变弹框逻辑。

| 项目 | 当前行为 | 本轮处理 | 后续 |
| --- | --- | --- | --- |
| `RequestOptions.suppressGeetestReport` | 同时抑制 Geetest + 指纹上报；不影响请求、retcode 和业务日志 | 保持字段名和语义不变；具体 API 的 helper 继续读取它 | 基线完成后决定改名 / 拆分；见 §4.6 |
| `RequestOptions.baseUrlType` | no-op；`HttpService` 删除后已没有读取方 | 保留字段和现有调用，不删除、不改造 | Mock base URL 方案确定后再处理；见 §4.6、Plan Phase 4 |
| BBS 账号详情 / 角色列表 / 战绩卡片是否显式上报 Geetest / 指纹 | 迁移后用 account service + 显式 helper 复刻；旧 transport 已删除 | `roleUid` 显式传空字符串，不用 BBS `uid` 冒充 | 真机 retcode / 基线完成后决定是否只保留必要上报；见 §4.7 |

> 这三项不阻塞本轮代码迁移。header / retcode 基线按用户决定延后到整个任务完成后补采；旧 transport 已删除，旧路径相关基线只能记录为“旧路径已删除 / 未覆盖”，新路径仍可在后续补采。

---

## 9. 非目标

- 不抽每日便笺 / 角色列表 / 养成计算的通用业务模板；
- 不重新设计业务 Service 的 URL / header / DS / Cookie；但 `AuthRepository` / `BBSRepository` 从旧 transport 切到注入的 Service 后，实际发送的 header / DS 会变成 Service 现有的那套，必须按 §4.2 回归；
- 不做 `MihoyoApiService` 公共 Header 合并（见第 10 节，后续单独实施）；
- 不移动文件到 Kit 目录；
- 不改数据库、Repository 业务逻辑；
- 不处理 release/internal 手机号登录隔离；
- 不接入 Mock base URL；`baseUrlType` 本轮保持原样，后续随 Mock 方案单独决定删除或改造（见 §8.7）；
- 不改 entry 页面、ViewModel、路由；
- 不更新根目录 `README.md`。

---

## 10. 后续工作（本次不做）：MihoyoApiService 公共 Header 合并

> 已记录，待所有 API Service 整理完成后实施。当前 Stage 0-3 不实现，避免和 BaseApiService 迁移、API 整理混在一起。

### 10.1 目标

把「公共请求头」的构造和「请求头合并」拆开：

```text
Header 抽象类                 具体 API Service
（管理公共 header）           （只提交接口专属 header）
        │                              │
        └──────────┬───────────────────┘
                   ↓
           MihoyoApiService
        （合并公共 + 专属 header）
                   ↓
            BaseApiService
          （只负责发送，不管理 header）
```

- **Header 抽象类**（名称待定）：管理公共 header 的常量、profile、构造规则和 DS 等请求级 header；不负责发请求。
- **`MihoyoApiService`**：作为唯一合并点，向 Header 抽象类取公共 header，与具体 Service 提交的 header 合并，再调用 Base。
- **具体 API Service**：只提交接口专属 header / 覆盖项，不再重复拼整套公共 header。
- **`BaseApiService`**：继续只接收最终 header，不 import Header 抽象类，不判断 header 内容。

实现形态上，未来由 `MihoyoApiService` 重写 `get/post`（或提供一个统一的 `request` 方法），在调用 `super.get/post` 前完成 header 合并；具体 API 仍然调用 `this.get/post`，不直接碰 Base。

### 10.2 边界

- Header 抽象类负责：
  - 公共 header 常量与 profile（UA、`x-rpc-app_version`、`device_id` / `device_fp`、`Referer` / `Origin`、`Cookie` 输入、`DS` 等）；
  - 根据请求上下文（profile、cookie、params、body）生成 header；
  - 提供覆盖 / 删除单个公共 header 的能力，供特殊接口使用。
- `MihoyoApiService` 负责：
  - 调用 Header 抽象类；
  - 与具体 Service 传入的 `RequestOptions.extraHeaders` 合并；
  - 保留 `RequestOptions` 的其他字段（`baseUrlType`、`suppressGeetestReport` 等）；
  - 调 `BaseApiService.get/post`。
- 具体 API Service 负责：
  - 选择 / 提供本次请求的 header profile 或上下文；
  - 传 Cookie；
  - 提交接口专属 header（Geetest challenge、`x-rpc-signgame`、特殊 UA 等）；
  - 传与 Base 相同的 params / body，确保 DS 签名一致。
- 非 `MihoyoApiService` 子类（`DeviceFpService` / `GeetestService` / `ZZZRecordRequest`）暂不纳入本次 Header 合并；它们当前直接使用 `BaseApiService.shared`，后续是否收口另行决定。

### 10.3 合并规则

- 公共 header 按 **profile / 请求上下文** 生成，不是给所有接口强塞同一套 header。
- 合并顺序：**公共 header → 具体 Service header**；同一个 key 以具体 Service 显式提交的值为准。
- 具体 Service 必须能够覆盖或删除某个公共 header，例如：
  - 二维码 / passport 使用特殊 `User-Agent`，不使用默认公共 UA；
  - 某些 passport 请求不使用账号 Cookie；
  - 养成计算删除 `x-rpc-cal_type`；
  - ZZZ 的特殊 header 集合。
- 合并时创建新的 `Map` / `RequestOptions`，不要原地修改调用方传入的 `extraHeaders`。
- Header 抽象类拿到的 `params` / `body` 必须与 Base 实际发送的一致，否则 DS 会算错。

### 10.4 当前现状与整理前提

- 当前 header 由 `MihoyoHeaderBuilder.build()` / `buildPizza()` 加上各 Service 手动 `set()` 组成，公共 header 和接口专属 header 混在一起。
- `HeaderProfile` 目前只覆盖 `GAME_RECORD` / `ZZZ_GAME_RECORD` / `CALCULATE` / `BBS` / `SIGN`；passport / 二维码等仍是手写 header。
- `MihoyoHeaderBuilder` 可以作为 Header 抽象类的基础，但需要补齐 profile 和覆盖能力；本次不重构它。
- `MihoyoHeaderBuilder` 目前为了 `GameFpBiz` 反向 import `DeviceFpService`，而 `DeviceFpService` 自己会发 HTTP 请求；Header 抽象类落地前应把 `GameFpBiz` 移到中立的 model / constants，避免 header 层依赖 service。
- 先完成所有 ApiService 的 Base 迁移和接口整理，再统一做 Header 合并；否则会一边改迁移、一边改 header 规则，难以定位回归。

### 10.5 落地前必须先定的机制

1. **profile 从哪里来**：header profile 是按方法变化的（便笺、角色、养成、签到、BBS、passport、QR），不是按 Service 固定的。`MihoyoApiService` 只重写 `get/post` 无法知道本次该用哪个 profile；需要：
   - `RequestOptions` 增加 header profile / context；或
   - `MihoyoApiService` 提供受保护的 `getWithProfile` / `postWithProfile`；或
   - 具体 Service 在调用前设置一个明确的 profile 字段。

   不能靠 URL 猜 profile。

2. **raw header escape hatch**：`ZZZRecordRequest` 已经生成整套 raw header（含自己的 DS / device_fp），`ZZZApiService` 的便笺 / 角色 / 邦布都走它。Header 合并必须支持“本次跳过公共 header”或“使用 raw headers 原样发送”，否则以后会把公共 header 又塞回去，破坏 ZZZ 签名。

3. **Cookie 策略不能统一**：
   - `buildPizza()` 会重建 PizzaHelper 格式 Cookie；
   - BBS profile 使用原始 Cookie；
   - passport 使用 `mid=...;stoken=...`；
   - QR / refresh token 可能完全不带账号 Cookie。

   Header 抽象类只能接收“本次使用的 Cookie”，不能自己从全局 Cookie 管理器统一取。

4. **DS 规则按 profile 不同**：GAME_RECORD 用 X4，BBS 用 V2，SIGN 用 X6，CALCULATE 用 X4 + `x-rpc-cal_type`，ZZZ raw 用 X4 raw query。合并层必须拿到与 Base 完全一致的 params / body；具体 Service 不能再手写一套 DS 覆盖公共 DS。

5. **profile 缺口**：`HeaderProfile` 目前没有 passport / QR / device / geetest；账号 Service 里有大量手写 header。落地时要补 profile，或允许这些接口显式声明的“无公共 header / 全量覆盖”。

6. **测试与基线**：Header 合并完成后不能只靠“能编译”。需要对比关键接口的最终 header（脱敏）、DS、Cookie、UA、profile 差异。原计划在删除 `HttpClient` 前记录基线；该采集已按用户决定延后，旧路径已删除。Header 合并前应先补采新路径基线，或在临时构建中记录合并前后差异。

### 10.6 实施时机与验收

- **时机**：Phase 2 所有 ApiService 整理完成后，作为 Phase 5 收尾项实施；不阻塞当前 Phase 1.1。
- 验收：
  - 具体 Service 不再构造整套公共 header，只保留接口专属 header / 覆盖项；
  - `MihoyoApiService` 是唯一 header 合并点；
  - Header 抽象类是唯一公共 header 管理点；
  - `BaseApiService` 仍不 import Header 抽象类；
  - `ZZZRecordRequest` 等 raw header 路径有明确 escape hatch；
  - 四个 product 构建通过；
  - 抓包 / 日志对比关键接口的最终 header 与基线一致，重点验证 DS、Cookie、UA、profile 差异；基线尚未采集时先补采新路径，不能把“未采集”当成通过。
