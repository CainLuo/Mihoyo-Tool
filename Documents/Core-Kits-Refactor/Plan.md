# Core 模块重构方案：Kits 化 + Mock 本地服务

> 状态：**进行中；Mock 清理已完成，local service 接入未完成；Kit 重构待开始**
> 范围：`core/` HAR 内部目录重组、Mock 服务化、DB 归类；不改表结构、不改 entry 的 MVVM 结构、不拆多 HAR。
> 原则：先移文件（`git mv`，保留历史）→ 再改代码；每个阶段可独立构建、可回滚。
>
> 任务总览：[`README.md`](README.md)；BaseApiService 方案：[`APIService.md`](APIService.md)；API 基线清单：[`API-Baseline.md`](API-Baseline.md)；Mock 专题与缺口：[`Mock.md`](Mock.md)。
> 后续公共 Header 合并已记录在 [`APIService.md`](APIService.md) 第 10 节，Phase 5 实施，不阻塞当前 BaseApiService 迁移。
>
> **2026-10-20 更新**：独立 `mock/` ArkTS 适配器目录已删除；`mock` product 保留，生成独立 `.mock` 包（`APP_ENV=mock`）。`mock-service/` 与 fixtures 保留，后续用 Swift-Vapor local service 复用。以下涉及 `mock/` 的内容为历史记录。
>
> **2026-10-21 更新**：Phase 1.1 BaseApiService 的 Stage 0-3 已完成；`HttpClient` / `HttpService` / `NetworkFactory` / `LegacyBaseApiService` 已删除。Phase 1.2 第一批已将 32 个共享文件迁到 `base/` / `common/constants/`；Phase 2 GenshinKit 已将 13 个 Genshin 专属文件迁入 `GenshinKit/`，只改路径与 import。`default` / `debug` / `mock` 构建和两个测试脚本通过，`internal` 编译通过但 `SignHap` 因开发证书过期失败。已用 `mihoyo-api-sdk`、TeyvatGuide、PizzaHelperUnited 和本项目历史抓包完成 header / retcode 静态参考对照；运行时基线按用户决定延后到整个任务完成后，不阻塞后续 Kit。旧路径基线已无法补采，详见 [`API-Baseline.md`](API-Baseline.md) §2.2。

---

## 1. 目标

把 `core` 从「按文件类型平铺」重组为「按业务域分 Kit」：

1. **四个 Kit**：`MihoyoKit`（米游社自身：账号/登录/BBS/绑定/签到）、`GenshinKit`、`StarRailKit`、`ZZZKit`。
2. **统一网络封装**：`BaseApiService` 作为构建链路内唯一 axios 封装层，`MihoyoApiService` 继承它，四个 Kit 的 ApiService 继续继承 `MihoyoApiService`，只负责拼 URL / header / body。
3. **DB 归类**：与具体游戏相关的 DB 资产全部下沉——DAO、DBManager、**该游戏的表结构片段与列枚举、只改该游戏的迁移**都进对应 Kit 的 `db/`；公共 `db/` 只留库基础设施（连接/事务/查询封装）与跨 Kit 迁移，`sync_meta` 归 `sync/`。
4. **Mock 服务化**：把 224 个 JSON 从 HAR 资源里挪出去，搭一个本机 mock service（HTTP），Mock 适配器已删除；服务端保留 `mock-service/`，供未来 local service 复用；Core 不再包含 Mock 代码。

**非目标**（本次不做）：

- 不把 `core` 拆成多个 HAR（保持单 `core`，`entry → core` 依赖不变）；不新增独立 `mock` HAR，仅保留 `mock-service/` 作为独立服务。
- 不改任何数据库表名、不写数据迁移（对已安装用户零影响）。
- 不改 entry 的页面/组件/ViewModel 结构（`core/Index.ets` 保持导出符号不变）。
- 不改业务 Service 现有请求的 URL / header / DS / 路由逻辑；但 **`AuthRepository` / `BBSRepository` 从旧 transport 切到注入的 Service** 会改变 header / DS（尤其是 BBS 的两个非 fallback 方法），自动上报的归属也会从 transport 改为具体 API，按 [`APIService.md`](APIService.md) 第 4.2 / 4.5 节审计。不能当成“零行为变化”。

---

## 2. 现状盘点

### 2.1 core 现状

```
core/src/main/ets/           （约 115 个 .ets）
├── network/      36 个：4 套域混在一起
│   ├── 共享：APIs、BaseApiService、HttpTypes、ApiConfig、DSUtil、
│   │        MihoyoDomain、MihoyoHeaderKey/Builder、CookieManager、DeviceFpService、
│   │        GeetestService/Reporter、FingerprintReporter、MihoyoApiService、Factory
│   ├── 米游社：MihoyoAccountApiPath/Service、PassportApiPath、QRCodeApiPath、
│   │        SignApiPath/Service
│   ├── 原神：GenshinApiPath/Service        ├── 星铁：StarRailApiPath/Service
│   └── 绝区零：ZZZApiPath/Service、ZZZRecordRequest
├── database/     17 个：RdbManager、TableSchema(1220 行、20+ 表)、迁移 V2~V7、
│                 BBSDao、GenshinDao、StarRailDao、ZZZDao、StarRailDBManager、
│                 SyncMetaDao、MaterialBagDao、MaterialTargetConfigDao、RsReader
├── repository/   10 个：Auth/BBS/Genshin/StarRail/ZZZ/Sign/MaterialBag/
│                 MaterialTargetConfig/GameRepository/SyncQueueRunner
├── models/       19 个：按游戏混排（AccountRow/GenshinRows/StarRailRows/ZZZRows…）
├── parsers/       6 个：已按游戏分（genshin/starrail/zzz 各 2）
├── constants/    14 个：GameId/GameServer/AppEnv/各游戏元素与属性枚举…
├── log/ + errors/ + utils/ + cookie/：共 11 个共享设施
└── CoreInitializer.ets
```

### 2.2 Mock 现状（清理已完成，接入未完成）

- 数据：`mock-service/fixtures/`，**224 个 JSON**，按 `{accountId}/{roleId}/` 分层。
- 服务端：`mock-service/`（零依赖 Node HTTP 服务）负责 fixture 路由、手机号登录、验证码、二维码与签到行为。
- 客户端：Mock 适配器已删除，不再有独立 `mock/` 目录；`mock-service/` 仅作为独立数据服务保留。
- Core 不再包含 Mock 适配器或 Mock 逻辑分支；`AppEnv.MOCK` 与 `AppEnvManager.isMock()` 保留枚举/API，但无任何使用。
- entry 不做任何 Service 注入；`CoreInitializer.initCore` 只接收 env/context，Service 全部由 `MihoyoApiServiceFactory` 创建。

### 2.3 构建与 overlay（重构最大雷区）

- `core/build-profile.json5` 的 target：`default / debug / internal / ohosTest`（不再有 mock target）。
- `src/internal/ets/` 是 **overlay 目录**，按「相对路径相同则覆盖 `src/main`」参与 debug/internal 构建，现有 3 个文件：
  - `network/MihoyoAccountApiService.ets`
  - `repository/AuthRepository.ets`
  - `models/PhoneLoginModels.ets`
- `mock` product 保留，生成独立 `.mock` 包；独立 `mock/` 源码目录已删除，产品 HAP 中不含 Mock 类。
- mock env 用 `product=mock` 构建（`APP_ENV=mock`），与 debug 的 `.debug` 包分开。
- `MihoyoAccountApiService` 自己完成手机号 RSA 加密，`AuthRepository` 不再判断环境。
- **任何目录移动都必须同步 overlay 的相对路径**，否则 debug/internal 包可能静默缺少手机号登录功能（能编译过、功能消失）。

### 2.4 现存问题

1. `network/` 是四套业务域 + 新旧网络实现 + 共享设施的混合体，新人无法判断边界。
2. Mock 适配器已全部移出 Core 并删除；服务端路由保留在 `mock-service/router.mjs`，供未来 local service 复用。
3. mock 数据已移出产品包（27MB → `mock-service/fixtures/`），改测试数据不再重新编译。
4. DAO/模型/解析器按类型平铺，跨游戏定位成本高；游戏间存在隐式交叉引用（`GenshinRepository → BBSRepository / MaterialBagRepository`），无编译期约束。
5. overlay 相对路径与主源码强耦合，重构风险高且无校验手段。
6. README 与实现漂移（mock 路径与脚本用法已修正，仍需持续检查）。

---

## 3. 目标结构

### 3.1 目录树

```
core/src/main/ets/
├── base/                             # ① 与业务域无关的基础设施
│   ├── network/
│   │   ├── BaseApiService.ets        # 构建链路内唯一 axios 封装层（原 HttpClient 升级而来）
│   │   ├── HttpTypes.ets             # HttpResponse / HttpError，不 import axios
│   │   ├── APIs.ets                  # RequestValue / RequestParams / RequestOptions
│   │   ├── MihoyoApiService.ets      # Kit ApiService 抽象基类， extends BaseApiService
│   │   ├── ApiConfig.ets             # UA/版本/设备字段
│   │   ├── MihoyoDomain.ets          # 域名枚举
│   │   ├── MihoyoHeaderKey.ets       # 请求头常量
│   │   ├── MihoyoHeaderBuilder.ets   # Header Profile 构建；Phase 5 再升级/收口为 Header 抽象类
│   │   ├── DSUtil.ets                # DS 签名（salt 从 rawfile 加载，保留）
│   │   ├── CookieManager.ets
│   │   ├── DeviceFpService.ets
│   │   ├── GeetestService.ets / GeetestReporter.ets / FingerprintReporter.ets
│   ├── cookie/                       # ColdStartCookieChecker / CookieRefreshCoordinator
│   ├── log/                          # ApiLogSystem / LogFileManager / LogExporter…
│   ├── errors/                       # ApiErrors
│   └── utils/                        # Logger / ApiErrorHandler / RsaUtil / CookieDebug
│
├── common/                           # ② 跨 Kit 的共享定义
│   ├── constants/                    # GameId / GameServer / AppEnv(Manager) /
│   │                                 # ApiConstants / ApiErrorCodes / SyncDataType
│   └── material/                     # 跨三游戏的「材料」门面（唯一允许下沉引用 Kit 的例外）
│       ├── model/                    # MaterialBagRow / MaterialTargetConfigRow
│       ├── db/                       # BaseMaterialBagDao / BaseMaterialTargetConfigDao
│       └── repository/               # MaterialBagRepository / MaterialTargetConfigRepository
│
├── db/                               # ③ 库基础设施（跨 Kit）
│   ├── RdbManager.ets                # 连接 / 事务 / 查询封装 / 迁移执行
│   ├── TableName.ets                 # 表名字符串枚举（唯一集中，全项目引用不变）
│   ├── RsReader.ets
│   └── migrations/                   # 仅跨 Kit 迁移（V3 / V7）+ 迁移注册表
│
├── sync/                             # ④ 跨 Kit 的同步框架
│   ├── GameRepository.ets            # 抽象基类
│   ├── SyncQueueRunner.ets
│   ├── model/                        # SyncMetaRow / SyncTask / GameDataSummary
│   └── db/                           # SyncMetaDao.ets + schema（sync_meta 表）
│
├── MihoyoKit/                        # ⑤ 米游社自身（账号/登录/签到/绑定）
│   ├── api/                          # MihoyoAccountApiService、SignApiService + 4 个 Path 枚举
│   ├── model/                        # AccountRow / GameRoleRow / Bbs* / Token* / PhoneLogin* / QRCode*
│   ├── db/
│   │   ├── BBSDao.ets                # AccountDao / GameRoleDao
│   │   └── schema.ets                # account_table / game_role_table + 列枚举
│   ├── repository/                   # AuthRepository / BBSRepository / SignRepository
│   └── (无专属 constants，路径枚举在 api/)
│
├── GenshinKit/                       # ⑥ 原神
│   ├── api/ model/ parser/ repository/ constants/
│   └── db/
│       ├── GenshinDao.ets            # 6 个 DAO
│       ├── MaterialBagDao.ets        # GenshinMaterialBagDao（从公共文件拆出）
│       ├── MaterialTargetConfigDao.ets
│       ├── schema.ets                # genshin_* 8 张表 + 列枚举
│       └── migrations/               # RdbMigrationV4 / V5（仅原神）
│
├── StarRailKit/                      # ⑦ 星铁
│   └── db/                           # StarRailDao + StarRailDBManager + 材料 DAO + schema
├── ZZZKit/                           # ⑧ 绝区零（含 ZZZRecordRequest 专有签名/指纹）
│   └── db/                           # ZZZDao + 材料 DAO + schema + migrations（V2 / V6）
│
├── SchemaRegistry.ets                # 表结构/迁移组装点（聚合各 Kit 片段）
├── ApiServiceFactory.ets             # 组装点（原 MihoyoApiServiceFactory，位于根）
├── CoreInitializer.ets
└── Index.ets                         # 唯一对外出口，符号名保持不变
```

根目录另新增（脱离 HAR）：

```
（原 `mock/` ArkTS 适配器目录已删除）

mock-service/                         # 本机 Mock HTTP 服务（零依赖 Node）
├── server.mjs
├── router.mjs                        # 路径 → fixture 映射（含特殊映射表）
├── fixtures/                         # 原 224 个 JSON 全量迁入
│   ├── 182692936/…
│   └── 348366494/…
├── tests/router.test.mjs             # node --test
└── README.md
```

### 3.2 依赖方向（DAG，单向）

```
entry
  └─→ Index.ets（导出聚合）
        ├─→ GenshinKit / StarRailKit / ZZZKit ──→ MihoyoKit ──→ base
        │        └─→ sync / db / common ──→ base
        ├─→ MihoyoKit ──→ sync / db / common ──→ base
        └─→ common/material（门面）──(例外)──→ 三个游戏 Kit 的 db
```

硬性规则：

- Kit **不得**互相 import，唯一例外是游戏 Kit → `MihoyoKit`（现状 `GenshinRepository` 需要 `BBSRepository`，保留单向）。
- `base/` 不 import 任何 Kit / common；`db/` 只被依赖，不反向依赖。
- 表结构与迁移的**组装在根 `SchemaRegistry.ets` 完成**（它 import 各 Kit 片段）；唯一例外：`db/migrations/cross/` 的跨 Kit 迁移可 import 多个 Kit 的列枚举。
- 用脚本检查：`grep -rn "kits/../.*Kit"` 之类的禁止性扫描，加入提交前检查。

### 3.3 文件搬迁总表（现路径 → 新路径）

> 阶段 1~2 以移动为主、尽量不改文件名；schema/迁移拆分与命名统一分别放在 Phase 3 / Phase 5。
>
> **Phase 1.2 进度（2026-10-21）**：`network/` 共享部分 14 个、`log/` 4 个、`errors/` 1 个、`utils/` 4 个、`cookie/` 2 个、公共 `constants/` 7 个已完成 `git mv`；`database/`、`repository/`、`models/`、`parsers/`、游戏专属 `network/`、`MihoyoApiServiceFactory` 尚未移动。`db/` / `sync/` / `common/material` 随 Phase 2/3 文件迁移落位，不单独提交空目录。
>
> **Phase 2 GenshinKit 进度（2026-10-21）**：Genshin 专属的 `api`（2）、`model`（3）、`parser`（2）、`constants`（2）、`db`（GenshinDao + V4/V5 migrations，3）、`repository`（1）共 13 个文件已迁入 `GenshinKit/`。Genshin 的 `TableSchema` 片段、material DAO 子类、material model/repository 仍留在原目录，按 Phase 3 拆分。`base/network/GeetestService` 暂时 import `GenshinKit/api/GenshinApiPath`，`database/RdbManager` 暂时 import GenshinKit migrations，属于 S-01 临时反向依赖。

**network/ 36 个**

| 现路径 | 新路径 |
|---|---|
| `network/APIs.ets` | `base/network/APIs.ets` |
| `network/HttpClient.ets` | 已拆为 `base/network/BaseApiService.ets` + `HttpTypes.ets`（Phase 1.1 完成） |
| `network/MihoyoApiService.ets` | `base/network/MihoyoApiService.ets` |
| `network/ApiConfig.ets / MihoyoDomain.ets / MihoyoHeaderKey.ets / MihoyoHeaderBuilder.ets / DSUtil.ets / CookieManager.ets / DeviceFpService.ets` | `base/network/` 同名 |
| `network/GeetestService.ets / GeetestReporter.ets / FingerprintReporter.ets` | `base/network/` 同名 |
| `network/MihoyoAccountApiPath.ets / MihoyoAccountApiService.ets / PassportApiPath.ets / QRCodeApiPath.ets / SignApiPath.ets / SignApiService.ets` | `MihoyoKit/api/` 同名 |
| `network/GenshinApiPath.ets / GenshinApiService.ets` | `GenshinKit/api/` 同名 |
| `network/StarRailApiPath.ets / StarRailApiService.ets` | `StarRailKit/api/` 同名 |
| `network/ZZZApiPath.ets / ZZZApiService.ets / ZZZRecordRequest.ets` | `ZZZKit/api/` 同名 |
| `network/MihoyoApiServiceFactory.ets` | 根 `ApiServiceFactory.ets` |
| `network/HttpService.ets` | **已删除**（旧 axios 封装，由 BaseApiService 取代） |
| `network/MockService.ets` | 已删除（原 `mock/` 目录已删除） |
| `network/NetworkFactory.ets` | **已删除**（由 ApiServiceFactory 取代） |
| `network/mock/`（7 个） | 已删除；服务端路由保留在 `mock-service/router.mjs` |

**repository/ 10 个**

| 现路径 | 新路径 |
|---|---|
| `repository/AuthRepository.ets` | `MihoyoKit/repository/`（overlay 同步改路径） |
| `repository/BBSRepository.ets / SignRepository.ets` | `MihoyoKit/repository/` |
| `repository/GenshinRepository.ets` | `GenshinKit/repository/` |
| `repository/StarRailRepository.ets` | `StarRailKit/repository/` |
| `repository/ZZZRepository.ets` | `ZZZKit/repository/` |
| `repository/GameRepository.ets / SyncQueueRunner.ets` | `sync/` |
| `repository/MaterialBagRepository.ets / MaterialTargetConfigRepository.ets` | `common/material/repository/` |

**database/ 17 个**（DB 资产按 Kit 下沉，规则见 §6）

| 现路径 | 新路径 |
|---|---|
| `database/RdbManager.ets / RsReader.ets` | `db/` |
| `database/TableSchema.ets` | 拆：`db/TableName.ets`（枚举）+ 各 Kit `db/schema.ets` + `sync/db/schema.ets`（sync_meta） |
| `database/RdbMigrationV2 / V6.ets` | `ZZZKit/db/migrations/` |
| `database/RdbMigrationV4 / V5.ets` | `GenshinKit/db/migrations/` |
| `database/RdbMigrationV3 / V7.ets` | `db/migrations/cross/`（跨 Kit，受控例外） |
| `database/BBSDao.ets` | `MihoyoKit/db/` |
| `database/GenshinDao.ets` | `GenshinKit/db/` |
| `database/StarRailDao.ets / StarRailDBManager.ets` | `StarRailKit/db/` |
| `database/ZZZDao.ets` | `ZZZKit/db/` |
| `database/SyncMetaDao.ets` | `sync/db/` |
| `database/MaterialBagDao.ets` | 拆：Base 类 → `common/material/db/`；三个子类 → 各自 Kit 的 `db/MaterialBagDao.ets` |
| `database/MaterialTargetConfigDao.ets` | 同上 |
| 新增（根目录） | `SchemaRegistry.ets`：聚合全部 schema 片段与迁移，供 `RdbManager` 建表/迁移 |

**models / parsers / constants**

| 类别 | 新路径 |
|---|---|
| AccountRow / GameRoleRow / BbsAccountModels / GameRoleModels / TokenModels / PhoneLoginModels / QRCodeLoginModels | `MihoyoKit/model/`（PhoneLoginModels overlay 同步） |
| GenshinRows / GenshinCharacterDetailRaw / GenshinCalcModels | `GenshinKit/model/` |
| StarRailRows / StarRailAvatarDetailRaw | `StarRailKit/model/` |
| ZZZRows / ZZZAvatarDetailRaw | `ZZZKit/model/` |
| MaterialBagRow / MaterialTargetConfigRow | `common/material/model/` |
| SyncMetaRow / SyncTask / GameDataSummary | `sync/model/` |
| parsers/genshin/* | `GenshinKit/parser/` |
| parsers/starrail/* | `StarRailKit/parser/` |
| parsers/zzz/* | `ZZZKit/parser/` |
| AppEnv / AppEnvManager / GameId / GameServer / ApiConstants / ApiErrorCodes / SyncDataType | `common/constants/` |
| GenshinElement / GenshinPropertyType | `GenshinKit/constants/` |
| StarRailElement / StarRailPropertyType | `StarRailKit/constants/` |
| ZZZElement / ZZZEnums / ZZZPropertyId | `ZZZKit/constants/` |
| ApiErrors | `base/errors/` |
| log/ 4 个 | `base/log/` |
| Logger / ApiErrorHandler / RsaUtil / CookieDebug | `base/utils/` |
| cookie/ 2 个 | `base/cookie/` |

**overlay（`core/src/internal/ets/`）**

| 现路径 | 新路径 |
|---|---|
| `network/MihoyoAccountApiService.ets` | `MihoyoKit/api/MihoyoAccountApiService.ets` |
| `network/mock/MihoyoAccountMockService.ets` | 已删除（行为进 mock service） |
| `repository/AuthRepository.ets` | `MihoyoKit/repository/AuthRepository.ets` |
| `models/PhoneLoginModels.ets` | `MihoyoKit/model/PhoneLoginModels.ets` |

### 3.4 整合前后目录树对比

#### 整合前（Phase 1.1 完成后的现状）

```
core/src/main/ets/                         # 约 115 个 .ets，按「文件类型」平铺
├── network/                               # Phase 1.1 已删除旧 transport
│   ├── 共享网络实现（旧 transport 已清理）
│   │   ├── APIs / BaseApiService / HttpTypes
│   │   ├── MihoyoApiService / MihoyoApiServiceFactory
│   │   ├── ApiConfig / MihoyoDomain / MihoyoHeaderKey / MihoyoHeaderBuilder / DSUtil
│   │   └── CookieManager / DeviceFpService / GeetestService
│   │       / GeetestReporter / FingerprintReporter
│   ├── 米游社（6）
│   │   └── MihoyoAccountApiPath / MihoyoAccountApiService / PassportApiPath
│   │       / QRCodeApiPath / SignApiPath / SignApiService
│   ├── 原神（2）：GenshinApiPath / GenshinApiService
│   ├── 星铁（2）：StarRailApiPath / StarRailApiService
│   ├── 绝区零（3）：ZZZApiPath / ZZZApiService / ZZZRecordRequest
│   └── （原 mock/ 6 个已删除）
├── database/                              # 17
│   ├── 基础设施：RdbManager / TableSchema（1220 行，24 张表）/ RsReader
│   ├── 迁移：RdbMigrationV2 ~ V7
│   ├── DAO：BBSDao / GenshinDao / StarRailDao / ZZZDao / StarRailDBManager
│   ├── 同步：SyncMetaDao
│   └── 材料：MaterialBagDao / MaterialTargetConfigDao（一个文件含 3 个游戏子类）
├── repository/                            # 10
│   ├── 米游社：AuthRepository / BBSRepository / SignRepository
│   ├── 游戏：GenshinRepository / StarRailRepository / ZZZRepository
│   ├── 同步：GameRepository / SyncQueueRunner
│   └── 材料：MaterialBagRepository / MaterialTargetConfigRepository
├── models/                                # 19（按游戏混排）
│   ├── 米游社：AccountRow / GameRoleRow / BbsAccountModels / GameRoleModels
│   │          / TokenModels / PhoneLoginModels / QRCodeLoginModels
│   ├── 原神：GenshinRows / GenshinCharacterDetailRaw / GenshinCalcModels
│   ├── 星铁：StarRailRows / StarRailAvatarDetailRaw
│   ├── 绝区零：ZZZRows / ZZZAvatarDetailRaw
│   ├── 材料：MaterialBagRow / MaterialTargetConfigRow
│   └── 同步：SyncMetaRow / SyncTask / GameDataSummary
├── parsers/                               # 6（唯一已按游戏分目录的部分）
│   ├── genshin/（2）  starrail/（2）  zzz/（2）
├── constants/                             # 14
│   ├── 公共：AppEnv / AppEnvManager / GameId / GameServer
│   │        / ApiConstants / ApiErrorCodes / SyncDataType
│   ├── 原神：GenshinElement / GenshinPropertyType
│   ├── 星铁：StarRailElement / StarRailPropertyType
│   └── 绝区零：ZZZElement / ZZZEnums / ZZZPropertyId
├── log/（4） errors/（1） utils/（4） cookie/（2）
├── CoreInitializer.ets
└── Index.ets
```

#### 整合后（目标）

```
core/src/main/ets/                         # 按「业务域」垂直切分
├── base/                                  # 共享底座（原 network 共享部分 + log/errors/utils/cookie）
│   ├── network/                           # BaseApiService、APIs、MihoyoApiService、ApiConfig、DSUtil、
│   │                                      # Header、Cookie、DeviceFp、Geetest
│   ├── cookie/（2）  log/（4）  errors/（1）  utils/（4）
├── common/                                # 跨 Kit 共享
│   ├── constants/（7 个公共枚举/环境）
│   └── material/                          # model + db 基类 + 跨游戏门面 repository
├── db/                                    # 库基础设施（无业务表）
│   ├── RdbManager / TableName / RsReader
│   └── migrations/cross/                  # V3、V7（跨多个 Kit）
├── sync/                                  # 同步框架
│   ├── GameRepository / SyncQueueRunner
│   ├── model/                             # SyncMetaRow / SyncTask / GameDataSummary
│   └── db/                                # SyncMetaDao + sync_meta schema
├── MihoyoKit/                             # 米游社：账号 / 登录 / BBS / 签到 / 绑定
│   ├── api/（6）
│   ├── model/（7）
│   ├── db/                                # BBSDao（AccountDao / GameRoleDao）+ schema
│   └── repository/（3）
├── GenshinKit/                            # 原神
│   ├── api/（2）  model/（3）  parser/（2）  constants/（2）
│   ├── db/                                # GenshinDao + 材料 DAO + schema + migrations（V4/V5）
│   └── repository/（1）
├── StarRailKit/                           # 星铁
│   ├── api/（2）  model/（2）  parser/（2）  constants/（2）
│   ├── db/                                # StarRailDao + StarRailDBManager + 材料 DAO + schema
│   └── repository/（1）
├── ZZZKit/                                # 绝区零
│   ├── api/（3）  model/（2）  parser/（2）  constants/（3）
│   ├── db/                                # ZZZDao + 材料 DAO + schema + migrations（V2/V6）
│   └── repository/（1）
├── SchemaRegistry.ets                     # 聚合 schema/迁移（新增）
├── ApiServiceFactory.ets                  # 原 MihoyoApiServiceFactory
├── CoreInitializer.ets
└── Index.ets

mock-service/                              # 新增：HAR 之外
├── server.mjs / router.mjs
├── fixtures/                              # 原 core/src/mock/ 的 224 个 JSON
├── tests/                                 # node --test
└── README.md
```

> overlay 目录 `core/src/internal/ets/` 保留，按新路径镜像：`MihoyoKit/api/`、`MihoyoKit/model/`、`MihoyoKit/repository/`（详见 §3.3 的 overlay 表）。

#### 目录级变化总览

| 整合前 | 文件数 | 整合后 | 说明 |
|---|---|---|---|
| `network/` | 30 + mock 6 | `base/network/` + 4 个 `Kit/api/` + 根 `ApiServiceFactory` | 拆散；mock 目录删除 |
| `database/` | 17 | `db/` + 4 个 `Kit/db/` + `sync/db/` | DAO 与表结构按 Kit 下沉 |
| `repository/` | 10 | 4 个 `Kit/repository/` + `sync/` + `common/material/repository/` | 按 Kit 下沉 |
| `models/` | 19 | 4 个 `Kit/model/` + `sync/model/` + `common/material/model/` | 按 Kit 下沉 |
| `parsers/` | 6 | `GenshinKit/parser/`、`StarRailKit/parser/`、`ZZZKit/parser/` | 直接搬 |
| `constants/` | 14 | `common/constants/` + 3 个 `Kit/constants/` | 按 Kit 下沉 |
| `log/ errors/ utils/ cookie/` | 11 | `base/` | 直接搬 |
| `core/src/mock/` | 224 JSON | `mock-service/fixtures/` | 移出 HAR |
| — | — | 根 `SchemaRegistry.ets` | 新增组装点 |

**消失的顶层目录**：`network/ database/ repository/ models/ parsers/ constants/ log/ errors/ utils/ cookie/`。
**新增的顶层目录**：`base/ common/ db/ sync/ MihoyoKit/ GenshinKit/ StarRailKit/ ZZZKit/`（另有 HAR 外的 `mock-service/`）。

---

## 4. BaseApiService 设计

> 命名已确定：统一用 `BaseApiService`；旧 `APIs.ets` 里的同名抽象类会被替换/改名，详见 [`APIService.md`](APIService.md)。

- **定位**：构建链路内唯一的 axios 封装层；`core/src` + `entry/src` 只有这个文件 import axios。
- **继承关系**：`MihoyoApiService extends BaseApiService`，所有 `XxxApiService`（含 `core/src/internal` overlay）继续 `extends MihoyoApiService`，不直接继承 Base。
- **职责边界**：Base 只做 axios 实例、超时、`get / post`、HTTP 非 200 拦截、HTTP 层日志；不做 `response.data` 拆包、业务 `retcode`、Geetest/指纹上报。
- **响应契约**：Base 返回项目自己的 `HttpResponse { status, data }`；具体 API 自己取 `response.data`，不依赖 axios 类型。
- **具体 Service**：只负责「拼 URL + 拼 header + 调 `this.get / this.post` + 拆 `response.data` + 业务 `retcode` + 按需显式上报」。
- **非 Service 调用方**：`DeviceFpService` / `GeetestService` / `ZZZRecordRequest` 使用 `BaseApiService.shared`。
- **公共 Header（后续）**：Header 的构造/管理放在独立 Header 抽象类；`MihoyoApiService` 负责把公共 header 与具体 Service 提交的 header 合并后交给 Base。本阶段不做，等所有 ApiService 整理完后作为 Phase 5 收尾项实施，详见 [`APIService.md`](APIService.md) 第 10 节。
- **实现**：由现有 `HttpClient` 升级而来，但只保留 HTTP 层能力：axios 单例、debug 信任证书、`get / post`、HTTP 非 200 拦截、HTTP 层日志。**不保留** `retcode` 错误日志和 Geetest/指纹上报，这些属于具体 API 或后续业务层。
- **HTTP 错误实现**：axios 默认对非 2xx reject，Base 必须从 `error.response` 提取真实 status / body，或用 `validateStatus` + 显式判断；只有无 response 才是 `statusCode = 0`。不能把所有 `catch` 都当网络错误。旧 `HttpClient` 会把非 2xx 包装成普通 `Error`，新 Base 统一 `HttpError`，错误消息和日志必须脱敏。
- **拆包审计**：`HttpResponse` 是 `object` 子类型，类型检查不会拦住漏拆包；Stage 1 必须逐方法审计直接 `return this.get/post`。
- **上报审计**：`suppressGeetestReport` 当前同时抑制 Geetest + 指纹；按 [`APIService.md`](APIService.md) 第 4.5 节逐接口确认，不能只按 Service 名称分类。直接 `return this.get/post` 的方法不能只加 `.data`，还要在 return 前显式调用 helper。
- **BBS / Auth 差异**：`BBSRepository.getUserGameRoles` / `getGameRecordCard` 原本始终走旧 transport；`AuthRepository` fallback 与 service header 不等价；`HttpService` 非 debug 拦截器会覆盖显式 Cookie。两者要按“切换实现”并分环境验证。
- **日志与基线**：Base 不打印 Cookie / 完整 header / body；URL query 要脱敏。原计划删除 `HttpClient` 前记录关键接口 header / retcode 基线；该采集已按用户决定延后，旧路径已删除，后续补采新路径。
- **测试口径**：`test-core.sh` / `test-entry.sh` 只构建 HAP，不是网络测试；Mock / 真机回归另做。
- **兼容（已完成）**：Stage 0-3 已按“先新增 Base，再逐步迁移，最后删除旧链路”执行；`HttpClient` / `HttpService` / `NetworkFactory` / `LegacyBaseApiService` 已删除。`entry` 没有直接使用旧类。
- **删除清单（已完成）**：`HttpClient.ets`、`HttpService.ets`、`NetworkFactory.ets`、`APIs.ets` 里的 `LegacyBaseApiService`，以及 `AuthRepository.getLTokenBySTokenLegacy`。`AuthRepository` 的 fallback 和 `BBSRepository` 的旧 transport 已改为走注入的 Service 实例；`BBSRepository.getBbsAccountDetail` 的 fallback、`getUserGameRoles` / `getGameRecordCard` 的旧 transport 都已移除。`BBSRepository` 增加了 `MihoyoAccountApiService` 类型检查，不再直接强转。根目录 `internal/core` 未改，仍是未参与构建的历史副本。
- 不在 Base 里做重试/缓存/拦截器体系——只做 axios 收口。

---

## 5. Mock 本地服务设计

### 5.1 服务端（mock-service/）

- 技术：Node.js（≥18），**零第三方依赖**，只读 JSON、无构建步骤；开发机没有 Node 时用 DevEco 自带或 brew 安装，README 写清。
- 路由逻辑 = 现 `MockServiceBase` 行为 1:1 移植：
  - 路径→文件名：`/` 换 `_`；特殊映射表（character/detail_all、avatar list/detail_all、buddy_list、widget、signIn 等）原样保留；
  - 账号提取：Cookie 里优先 `account_id`，其次 `stuid`，兜底 `1`；
  - 角色路由：query/body 取 `role_id` / `uid`；绝区零详情取 `id_list[]` 第一个；
  - 优先级：`{accountId}/{roleId}/{file}` → `{accountId}/{file}` → 返回空 data。
- 账号级行为进服务：手机号白名单（13800138000 → 182692936、13800138001 → 348366494）、验证码固定 111111、二维码 fetch/query 假数据。
- 额外能力（顺手获得）：`--port`（默认 8787）、`--delay`（默认 300ms，可调 0）、`GET /__health`、请求日志。
- fixture 迁移：`core/src/mock/resources/rawfile/mock/*` 全量 `git mv` 到 `mock-service/fixtures/`。

### 5.2 App 侧（当前）

- 独立 `mock/` 目录与 ArkTS Mock 适配器已删除，不再有 `MockTransport` / `MockServiceBase` / 游戏 MockService。
- mock env 构建：`hvigorw assembleHap -p product=mock`（或 `bash run.sh mock`），产物是独立 `.mock` 包。
- 产品 HAP 中不含 Mock 类；`MihoyoApiServiceFactory` 只创建真实 Service，不再有 MOCK 分支；`CoreInitializer.initCore` 只接收 env/context。
- 旧 `NetworkFactory` / `HttpService` / `HttpClient` 已删除；非 Service 调用方改走 `BaseApiService.shared`。
- Core 保留 `AppEnv.MOCK` / `AppEnvManager.isMock()` 枚举与 API，但没有任何逻辑分支使用。
- Core 的 mock target 已删除；`src/internal` 仅用于 debug/internal overlay。
- `MihoyoAccountApiService` 自己完成手机号/区号 RSA 加密，`AuthRepository` 不再判断环境。
- 地址配置：`mock-service` 默认 `http://127.0.0.1:8787`；App 当前未接入，客户端接入方案待定（计划 Swift-Vapor local service）。
- 原独立 `mock/` 模块已删除；后续客户端接入方案确定前，不要在 core/entry 中恢复 Mock 代码。
- 连接方式（客户端接入后）：
  ```
  hdc rport tcp:8787 tcp:8787   # 设备/模拟器 localhost:8787 → 开发机
  node mock-service/server.mjs
  ```
- 明文 HTTP：暂未添加 `network_config.json`。SDK 文档中 `2300997` 只说明「应用显式禁止明文」时会触发；真机首次运行确认，如果被拦截再补配置。`INTERNET` 权限已在 entry module.json5 中。

### 5.3 收益

- 产品包减少 ~27MB；改 mock 数据不再重编译。
- fixture 数据、路由与账号/签到行为集中到服务端；客户端不保留 Mock 适配器。
- 原 ArkTS MockService 已删除；fixtures/路由集中在 `mock-service/`，后续可迁移到 Swift-Vapor local service。
- 未来新游戏/新接口只改 `router.mjs` + 放 fixture，不需要碰 ArkTS。

> 当前二维码 `queryQRCode` 返回 `init`（不自动确认），与旧 internal overlay 的 `Confirmed` 行为不同；如需要自动登录测试，改 `mock-service/router.mjs` 与对应测试即可。

---

## 6. DB 归类设计

原则：**与具体游戏相关的一切 DB 资产（表结构片段、列枚举、DAO、DBManager、只改该游戏的迁移）全部下沉到对应 Kit**；公共 `db/` 只留「库本身」的设施。

1. **单库不变**：数据库文件名、表名、DDL、迁移顺序全部不动，用户数据零迁移；这次只是文件搬家 + 拆文件。

2. **表 → Kit 归属**：

| 归属 | 表 |
|---|---|
| MihoyoKit | `account_table`、`game_role_table` |
| GenshinKit | `genshin_character_list`、`genshin_daily_note`、`genshin_character_detail`、`genshin_character_compute`、`genshin_calc_avatar`、`genshin_compute_summary`、`genshin_material_bag`、`genshin_material_target_config` |
| StarRailKit | `starrail_avatar_basic`、`starrail_daily_note`、`starrail_avatar_info`、`starrail_avatar_compute`、`starrail_material_bag`、`starrail_material_target_config` |
| ZZZKit | `zzz_avatar_basic`、`zzz_daily_note`、`zzz_avatar_info`、`zzz_avatar_compute`、`zzz_buddy`、`zzz_material_bag`、`zzz_material_target_config` |
| sync/ | `sync_meta` |
| db/ | 无业务表，只留表名枚举与基础设施 |

3. **TableSchema 拆分方式**：
   - `TableName` 字符串枚举单独成 `db/TableName.ets`——全项目（DAO、SyncDataType、迁移）都引用它，保持一处、引用不变；
   - `TableDef`、各 Column 枚举按 Kit 拆到 `<Kit>/db/schema.ets`；`sync_meta` 的放 `sync/db/schema.ets`；
   - 根目录新增 `SchemaRegistry.ets` 聚合所有片段（`ALL_TABLES / ALL_INDEXES` 在这里拼装）；`RdbManager.init(context, SchemaRegistry)` 改为接收注册表，`db/` 不反向 import Kit。

4. **迁移归属**：
   - 只改单 Kit 表的迁移 → 该 Kit 的 `db/migrations/`（V2/V6 → ZZZKit；V4/V5 → GenshinKit）；
   - 同时改多个 Kit 的迁移（V3、V7）→ `db/migrations/cross/`，是唯一允许 import 多个 Kit 列枚举的受控例外；
   - 迁移注册表按 version **全局升序合并执行**，`user_version` 单一时序语义不变；禁止把一个版本的迁移拆成多步。

5. **material 拆表**：`MaterialBagDao` / `MaterialTargetConfigDao` 的子类按游戏拆进各 Kit `db/`；抽象基类留 `common/material/db/`；`MaterialBagRepository` / `MaterialTargetConfigRepository` 作为跨游戏门面留 `common/material/repository/`（entry 按 `gameId` 调它们，签名必须保持不变）。

6. **DBManager**：`StarRailDBManager` 进 StarRailKit/db；GenshinKit / ZZZKit 目前 Repository 直接调 DAO，本次不做行为改动（不新造 DBManager），后续按 Kit 各自决定。

---

## 7. 兼容与构建影响

| 项 | 处理 |
|---|---|
| entry 对 core 的 import（全部 `from 'core'`） | `Index.ets` 保持全量重导出，**符号名不变**；entry 零改动 |
| entry 目前没有直接 import `HttpClient`，只有注释提到旧类 | 不需要过渡别名；直接迁移 core 内部调用方 |
| core 单测（`core/src/test`、`core/src/ohosTest`） | 更新 import 相对路径；`MockServiceBase.test` 的纯函数用例已迁到 `mock-service/tests/router.test.mjs`（Node），ArkTS 旧测试已删除 |
| entry ohosTest 的 `MockServiceBase.test.ets` | 已删除（路由测试改由 Node 覆盖） |
| `core/build-profile.json5` | 无 mock 专属 target；`mock` product 保留（独立 `.mock` 包）；`src/internal` overlay 仅用于 debug/internal |
| `core/src/mock/` | 已整体删除（fixtures 迁移到 `mock-service/fixtures/`） |
| `core/src/main/ets/network/mock/`、`MockService.ets` | 已删除；Core `Index.ets` 不再导出 Mock 符号 |
| CI（`.github/workflows/release.yml`） | 若涉及 core 路径的 grep/构建参数，检查一遍；新增 `mock-service` 的 `node --test` 可选 |
| README / Documents | Phase 5 更新项目结构、mock 使用说明、连接方式（README 现有内容已漂移） |

---

## 8. 分阶段实施计划

> 每一步单独提交；每步跑完「验证」才进入下一步。改动期间不并行开发同一目录。

**Phase 0 — 基线（构建基线完成；业务基线延后）**
- 记录当前四个 product（`default` / `mock` / `debug` / `internal`）构建结果 + `test-core.sh`、`test-entry.sh` 基线；注意这两个脚本只构建 ohosTest HAP，不是运行测试。**已完成。**
- 记录关键接口基线（原计划删除 `HttpClient` 前）：脱敏 URL、最终 header 名称/关键值、retcode、当前是否触发 Geetest / 指纹上报。不要把 Cookie / token 原文写进文档或提交。逐接口清单和填写位置见 [`API-Baseline.md`](API-Baseline.md)；当前 **未采集，按用户决定延后**。
- 确认 `hdc` target；当前环境曾检测到 `127.0.0.1:5555`，可用时做安装/启动验证；**本轮未执行真机回归**。
- 验证：四个 product 构建通过；业务基线未采集，不再作为 Stage 1 / Stage 2 的 Gate；旧路径基线已无法补采，新路径待任务完成后补采。网络测试另做，不能把“脚本通过”当成完整验证。

**Phase 1 — 底盘（Phase 1.1 完成；Phase 1.2 第一批完成）**
- Phase 1.1 BaseApiService 的 **Stage 0-3 已完成**：抽构建链路内唯一的 axios 封装层，`MihoyoApiService extends BaseApiService`，所有 Service 继续 `extends MihoyoApiService`，重复 `get / post` 已清理；文件级迁移/删除清单见 [`APIService.md`](APIService.md) 第 8 节。原“Stage 1 前完成 P0 / Stage 2 前完成 P1”的 Gate 已被用户的“基线延后”决定覆盖。
- Base 实现必须处理：axios 非 2xx 的 `error.response`、懒加载 axios、日志脱敏 + try/catch、`HttpResponse` 漏拆包审计、按 §4.5 的上报归属、`BBSRepository` 两个“非 fallback”方法、`AuthRepository` fallback/service header 差异。`suppressGeetestReport`、`baseUrlType`、BBS 三个接口的上报行为本轮保持原样（`APIService.md` §8.7）。
- Phase 1.2 第一批已完成（2026-10-21）：`base/network` 14 个、`base/log` 4 个、`base/errors` 1 个、`base/utils` 4 个、`base/cookie` 2 个、`common/constants` 7 个，共 32 个共享文件用 `git mv` 迁移；169 处相对 import 和 `Index.ets` 导出已更新，internal overlay import 同步更新；旧顶层 `log/ errors/ utils/ cookie/` 空目录已移除，`network/` 仅余游戏 / 账号专属 Service、Path 和 `MihoyoApiServiceFactory`。
- `Index.ets` 已改为从新路径重导出；旧 `HttpClient` / `HttpService` / `NetworkFactory` 已删除。
- 验证：`default` / `debug` / `mock` 构建通过；`test-core.sh` / `test-entry.sh` 通过；`internal` 的 `CompileArkTS` 通过，但 `SignHap` 因开发证书过期失败（见 `Known-Issues.md` E-01）；524 个相对 import 解析检查 0 缺失；关键接口基线对比和 `hdc` 安装验证按用户决定延后。`test-core.sh` / `test-entry.sh` 只构建 HAP，不能单独作为网络回归结论。

**Phase 2 — 拆 Kit（GenshinKit 完成；StarRail / ZZZ / Mihoyo 待做）**
- 顺序：GenshinKit → StarRailKit → ZZZKit → MihoyoKit（先外围后中心，MihoyoKit 被其它 Kit 依赖，最后搬）。
- GenshinKit 已完成（2026-10-21）：api / model / parser / constants / db DAO + V4/V5 migrations / repository 共 13 个文件；53 处 import、Index、工厂、CoreInitializer 和测试路径已更新；`default` / `debug` / `mock` 与两个测试脚本通过；`base/network/GeetestService` 和 `database/RdbManager` 暂时反向依赖 GenshinKit，记录为 S-01。
- 每 Kit：api / model / parser / **db（DAO + 该 Kit 的 schema 片段 + 专属迁移 + material 子类 DAO）** / repository / constants + overlay 同步。Genshin 的 `TableSchema` 拆分、material DAO 子类和 material model/repository 按 Phase 3 处理。
- 验证：每搬一个 Kit，`default` / `debug` / `mock` 构建 + 两个测试脚本 + 相对 import 解析检查；`internal` 只验证到 `CompileArkTS`（E-01）。

**Phase 3 — DB 收尾（0.5~1 天）**
- `db/TableName.ets` 抽离；跨 Kit 迁移（V3/V7）归入 `db/migrations/cross/`；根 `SchemaRegistry.ets` 聚合并让 `RdbManager.init` 接收注册表（schema 片段若未随 Phase 2 一起搬，在这里补齐）。
- 验证：`RdbManager.test`、三个 Dao test、升级路径手测（旧版本 DB 文件 → 新包首启）。

**Phase 4 — Mock 服务（部分完成）**
- 清理完成：fixtures 迁移、Node router/账号/签到行为、独立 `mock` product、脚本与文档。
- 未完成：Swift-Vapor local service、App 接入、真机联调、parity 测试。
- App 接入前再决定 `RequestOptions.baseUrlType`：本轮 Phase 1.1 **保持字段原样，不删除、不改造**；等 Phase 4 明确 Mock base URL 方案后，再决定删除或改造。
- 验证：Node 测试 12/12；mock-service 的 curl 路由抽样；客户端接入后另做全功能手测。当前 mock product 仍走真实 API，不能把 mock 包启动当成 Mock 数据链路可用。

**Phase 5 — 收尾（0.5 天）**
- 命名统一（如 `APIs.ets`），删除兼容别名，更新 README / Documents / 脚本，CI 加路径检查。
- `MihoyoApiService` 公共 Header 合并：Header 抽象类负责构造/管理；`MihoyoApiService` 合并具体 Service 提交的 header 后交给 Base。等 Phase 2 所有 ApiService 整理完再实施，详见 [`APIService.md`](APIService.md) 第 10 节。
- Header 合并前必须先解决：profile 来源（按方法而非按 Service）、raw header escape hatch（ZZZRecordRequest）、Cookie 策略（pizza / BBS / passport / QR）、DS 规则、`GameFpBiz` 从 `DeviceFpService` 移出、passport/QR profile 缺口。
- README 按约定等全部整合完成后统一更新。
- 验证：全量构建 + 全量测试 + `git grep` 无死引用；Header 合并后对关键接口抓包/日志比对，并使用 Phase 0 的基线。

**预估总工时：6~9 天**（不含真实设备联调缓冲）。

---

## 9. 风险与回滚

| 风险 | 影响 | 对策 |
|---|---|---|
| Base 返回 `HttpResponse` 后漏拆包 | 编译不报错，运行时 `retcode` / `data` 错位 | `HttpResponse` 是 `object` 子类型，类型检查不兜底；逐方法审计 + grep 直接 `return this.get/post` |
| axios 非 2xx 被当网络错误 | 401 / 500 丢失真实状态和 body | 从 `error.response` 提取，或 `validateStatus` + 显式判断；无 response 才 `statusCode = 0` |
| 自动上报归属变化 | Geetest / 指纹弹框漏报或误报 | 按 `APIService.md` 第 4.5 节逐接口审计；直接 `return this.get/post` 的方法要在 return 前调用 helper；`suppressGeetestReport` 本轮保持原样（§8.7） |
| `BBSRepository` 两个方法原本走旧 transport | 切换后 header / DS 变化；`getGameRecordCard` 旧路径还没有 DS | `getUserGameRoles` / `getGameRecordCard` 单独回归；不要当删 fallback；BBS 三个接口的上报按 `APIService.md` §4.7 暂按现状保留 |
| `AuthRepository` fallback 与 service header 不等价 | service 路径暴露差异 | 以 service 为 canonical；验证 `text/plain` vs `json`、device/UA 字段差异 |
| Base 日志泄露 Cookie / token | 安全 / 隐私问题 | URL 脱敏，不打印完整 header / body；日志 try/catch |
| `test-core.sh` / `test-entry.sh` 只构建 HAP | 误以为网络已验证 | 明确“编译验证”；Mock / 真机接口回归另做 |
| `baseUrlType` 失去读取方 | 死字段或 Mock 接入重复造轮子 | 本轮保留原样；Phase 4 确定 Mock 方案后再删除或改造（`APIService.md` §8.7） |
| overlay 路径漏改 | internal 包静默缺手机号登录 | 建 overlay 对照表；新增 `scripts/check-overlay.sh`（比对两棵树的相对路径）；internal 包手测登录 |
| 按 Kit 拆 schema/迁移后版本时序错乱 | `user_version` 错位、老用户升级失败 | 迁移注册表按 version 全局升序合并；禁止把一个版本的迁移拆成多步；跨 Kit 迁移留 `cross/`；升级手测（旧库文件 → 新包首启） |
| 循环依赖（Kit ↔ common/base） | ArkTS 编译报错或运行时未定义 | DAG 规则 + 提交前 grep 扫描；先移底层再移上层 |
| Index.ets 导出重名冲突 | 编译失败 | 迁移中保持符号名；冲突时显式 `as` 重命名并记录 |
| 测试/文档引用旧路径 | 编译失败/文档误导 | 全仓 `git grep` 批量替换 + CI 检查 |
| Mock 切 HTTP 后行为漂移（retcode 异常分支、widget 映射） | 页面异常但难定位 | `mock-service` 路由复刻原 retcode 抛错逻辑；路由对照测试（server 单测 + 手测清单） |
| 明文 HTTP 被系统拦截 | mock 环境全挂 | 先做网络配置验证（hello world 请求）再接业务 |
| 大范围移动期间多人冲突 | 合并地狱 | 每 Kit 一次提交；`git mv` 保留 blame；冻结期沟通 |

**回滚**：每阶段独立提交，`git revert` 单提交即可；DB 与 API 行为不改，回滚无数据风险。

---

## 10. 待确认的问题

1. **Mock 服务技术栈**：现状为 Node `mock-service/`；后续计划 Swift-Vapor local service，是否保留 Node 版本作为 fixtures/路由参考？
2. **连接方式**：`hdc rport` + `127.0.0.1:8787`（推荐，USB/模拟器通用）还是局域网 IP + App 内配置界面？
3. **Kit 依赖**：是否同意「游戏 Kit → MihoyoKit」单向依赖（现状 GenshinRepository 引用 BBSRepository；若要彻底解耦需要额外抽象，建议本次不做）？
4. **旧测试**：`core/src/test/MockServiceBase.test.ets` 与 entry 同名测试——已删除；路由测试迁移到 `mock-service/tests/router.test.mjs`。
5. **执行顺序**：先 Kit 拆分（推荐，纯移动风险低）还是先 Mock 服务化？两者仅通过 factory/overlay 相交，可调整。
6. **schema/迁移的搬迁节奏**：随各 Kit 在 Phase 2 一起搬（推荐，少一轮二次搬运）还是集中放 Phase 3？
7. **Base 非 2xx 实现**：用 `validateStatus` 接受全部状态再判断，还是保留 axios 默认 reject 并在 `catch` 读 `error.response`？两者都可，但必须覆盖 401 / 500 / 超时测试。
8. **`suppressGeetestReport` 语义**：本轮保持“同时抑制 Geetest + 指纹”，不改名 / 不拆分；后续基线完成后再决定。
9. **`BBSRepository` 两个方法**：`getUserGameRoles` / `getGameRecordCard` 直接切到 `MihoyoAccountApiService`，还是先保留旧 transport 单独验证？推荐切换并单独回归。
10. **`baseUrlType`**：本轮保持字段原样，不删除 / 不改造；Phase 4 Mock base URL 方案确定后再决定。

---

## 附录 A：本次不动的部分（明确边界）

- `core/Index.ets` 导出符号集（只改内部来源路径）。
- 业务 Service 现有 API 请求的 URL / header / DS / 轮询行为。例外有两类：`AuthRepository` / `BBSRepository` 从旧 transport 切到注入的 Service（header / DS 会变，按 [`APIService.md`](APIService.md) 第 4.2 节回归），以及自动上报归属从 transport 改为具体 API 显式上报（按第 4.5 节对齐）。除此之外请求头不得因迁移改变。
- 数据库文件名、表结构内容、迁移顺序（只拆文件与搬位置，DDL 与 `user_version` 时序不变）。
- entry 的页面、组件、ViewModel、路由。
- `src/internal` overlay 机制本身（只改路径，不取消）。
- `core/src/main/resources/rawfile/release/salt_config.json`（非 mock 数据，保留在 HAR）。

## 附录 B：建议先做的两件小事（不动代码也能做）

1. `scripts/check-overlay.sh`：列出 `src/main` 与 `src/internal` 的路径差集，重构期间每次提交前跑。
2. 一份 mock 路由回归清单（curl 命令 × 关键接口），Phase 4 前后各跑一遍对比响应。
