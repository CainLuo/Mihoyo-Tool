# 设计文档：mihoyo-mock-redesign

## 命名说明（V2 后缀的由来）

同 `game-data-database-redesign/design.md` 中的说明，`network/v2/mock/` 目录为过渡期临时路径，旧代码删除后统一去掉 `v2` 层级。

---

## 概述

Mock 环境的 API 层设计，与 `mihoyo-api-redesign` 保持完全相同的架构（抽象基类、模块隔离、多态），唯一区别是：

- **不请求真实网络**，改为读取本地 `rawfile/mock/` 目录下的 JSON 文件
- **无 Domain 枚举**，因为不需要 Host
- **API Path 枚举与 release 版本一一对应**，但值是本地文件路径（用于文件名映射）
- **DB 写入、Repository、ViewModel 层完全相同**，Mock 只替换网络层

---

## 与 API Design 对比

| 维度          | mihoyo-api-redesign | mihoyo-mock-redesign      |
| ------------- | ------------------- | ------------------------- |
| Domain 枚举   | ✅ 有（7 个 Host）  | ❌ 无（不需要）           |
| API Path 枚举 | ✅ 有（URL 路径）   | ✅ 直接复用 release 枚举  |
| 抽象基类      | `MihoyoApiService`  | 同一个 `MihoyoApiService` |
| Mock 基类     | ❌ 无               | ✅ `MockServiceBase`      |
| Service 实现  | 真实 HTTP 请求      | 读本地 JSON 文件          |
| DB 写入       | ✅ 相同             | ✅ 相同                   |
| Repository 层 | ✅ 相同             | ✅ 相同                   |
| ViewModel 层  | ✅ 相同             | ✅ 相同                   |

---

## 架构

```
MihoyoApiService（抽象基类，与 release 共用）
    │
    ├── MihoyoAccountMockService   → 读 mock/accountX/ 下的账号相关 JSON
    ├── GenshinMockService         → 读 mock/accountX/ 下的原神 JSON
    ├── StarRailMockService        → 读 mock/accountX/ 下的星铁 JSON
    ├── ZZZMockService             → 读 mock/accountX/ 下的绝区零 JSON
    └── SignMockService            → 读 mock/accountX/ 下的签到 JSON
```

---

## 文件结构

```
core/src/main/ets/network/v2/mock/
├── MockServiceBase.ets            ← Mock 基类（delay()、文件读取、retcode 检查）
├── MihoyoAccountMockService.ets   ← 账号 Mock Service（含 Geetest 两个接口）
├── GenshinMockService.ets         ← 原神 Mock Service
├── StarRailMockService.ets        ← 星铁 Mock Service
├── ZZZMockService.ets             ← 绝区零 Mock Service
└── SignMockService.ets            ← 签到 Mock Service（大别野 + 各游戏）

core/src/main/resources/rawfile/mock/
├── account1/    ← account_id=1 的 mock 数据（Cookie 路由）
│   ├── binding_api_getUserGameRolesByCookie.json
│   ├── game_record_app_card_wapi_getGameRecordCard.json
│   ├── user_wapi_getUserFullInfo.json
│   ├── misc_api_createVerification.json          ← Geetest 申请验证
│   ├── misc_api_verifyVerification.json          ← Geetest 提交验证
│   ├── apihub_app_api_signIn.json                ← 大别野签到
│   ├── event_luna_hk4e_sign.json                 ← 原神每日签到
│   ├── event_luna_hkrpg_sign.json                ← 星铁每日签到
│   ├── event_luna_zzz_sign.json                  ← 绝区零每日签到
│   ├── event_luna_hk4e_info.json                 ← 原神签到状态
│   ├── event_luna_hkrpg_info.json                ← 星铁签到状态
│   ├── event_luna_zzz_info.json                  ← 绝区零签到状态
│   ├── event_luna_hk4e_home.json                 ← 原神今日签到奖励
│   ├── event_luna_hkrpg_home.json                ← 星铁今日签到奖励
│   ├── event_luna_zzz_home.json                  ← 绝区零今日签到奖励
│   ├── game_record_app_genshin_api_dailyNote.json
│   ├── game_record_app_genshin_api_character_list.json
│   ├── game_record_app_genshin_api_character_detail.json
│   ├── game_record_app_genshin_api_character_detail_all.json
│   ├── genshin_character_batch_compute.json
│   ├── game_record_app_hkrpg_api_note.json
│   ├── game_record_app_hkrpg_api_avatar_basic.json
│   ├── game_record_app_hkrpg_api_avatar_info.json
│   ├── hkrpg_character_compute.json
│   ├── event_game_record_zzz_api_zzz_note.json
│   ├── event_game_record_zzz_api_zzz_avatar_basic.json
│   ├── event_game_record_zzz_api_zzz_avatar_info.json
│   └── zzz_character_compute.json
└── account2/    ← account_id=2 的 mock 数据
    └── ...（结构同 account1）
```

---

## 数据模型

### Mock API Path 枚举

Mock Service **不需要独立的 Path 枚举**，直接复用 release 版本的枚举：

```typescript
// Mock Service 内部直接 import release 枚举
import { MihoyoAccountApiPath } from "../MihoyoAccountApiPath";
import { GenshinApiPath } from "../GenshinApiPath";
import { StarRailApiPath } from "../StarRailApiPath";
import { ZZZApiPath } from "../ZZZApiPath";
import { SignApiPath } from "../SignApiPath";
```

Mock Service 通过 URL 路径（枚举值）映射到本地文件名，无需维护两套相同的枚举。

### 文件名映射规则

URL 路径 → 本地文件名（与现有 MockService 逻辑一致）：

```
规则：去掉协议+域名，去掉查询参数，去掉首尾斜杠，斜杠替换为下划线

示例：
  /game_record/app/genshin/api/dailyNote
  → game_record_app_genshin_api_dailyNote.json

  /game_record/app/genshin/api/character/list
  → game_record_app_genshin_api_character_list.json

  /game_record/app/genshin/api/character/detail
  → game_record_app_genshin_api_character_detail.json

  /event/game_record_zzz/api/zzz/avatar/basic
  → event_game_record_zzz_api_zzz_avatar_basic.json
```

> **特殊文件名例外（养成计算接口 + 大别野签到 + 原神角色详情）：**
>
> 以下接口的 mock 文件名**不遵循**自动映射规则，Mock Service 需要对这些接口做硬编码映射：
>
> | API Path                                        | 自动映射结果（不使用）                              | 实际文件名（使用）                                      |
> | ----------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------- |
> | `/event/e20200928calculate/v3/batch_compute`    | `event_e20200928calculate_v3_batch_compute.json`    | `genshin_character_batch_compute.json`                  |
> | `/event/rpgcalc/compute`                        | `event_rpgcalc_compute.json`                        | `hkrpg_character_compute.json`                          |
> | `/event/nap_cultivate_tool/avatar_calc`         | `event_nap_cultivate_tool_avatar_calc.json`         | `zzz_character_compute.json`                            |
> | `/app/api/signIn`                               | `app_api_signIn.json`                               | `apihub_app_api_signIn.json`                            |
> | `/game_record/app/genshin/api/character/detail` | `game_record_app_genshin_api_character_detail.json` | `game_record_app_genshin_api_character_detail_all.json` |
>
> 说明：
>
> - 大别野签到使用 `BBS_APIHUB` Domain（已含 `/apihub` 前缀），API Path 是 `/app/api/signIn`，但 mock 文件按完整路径 `/apihub/app/api/signIn` 命名。
> - 原神角色详情：单角色查询和批量查询写入同一张表，Mock Service 统一使用 `character_detail_all.json`（含所有角色数据），不使用单角色文件。
>
> 实现方式：在 `pathToFileName()` 之前，先检查是否命中特殊映射表，命中则直接返回对应文件名，不走通用规则。

### Cookie → 子目录路由

```
Cookie: account_id=1 → rawfile/mock/account1/
Cookie: account_id=2 → rawfile/mock/account2/
其他                  → rawfile/mock/（根目录 fallback）
```

### 各 Mock Service 方法签名

与 release Service 完全相同，只是内部实现从网络改为读文件：

**MihoyoAccountMockService：**

| 方法                                | 对应文件                                           |
| ----------------------------------- | -------------------------------------------------- |
| `getGameRoles(cookie)`              | `binding_api_getUserGameRolesByCookie.json`        |
| `getGameRecordCard(uid, cookie)`    | `game_record_app_card_wapi_getGameRecordCard.json` |
| `getUserFullInfo(uid, cookie)`      | `user_wapi_getUserFullInfo.json`                   |
| `createVerification(cookie)`        | `misc_api_createVerification.json`                 |
| `verifyVerification(input, cookie)` | `misc_api_verifyVerification.json`                 |
| `refreshCookieToken(stoken, stuid)` | 无 mock 文件（直接返回固定 token 字符串）          |
| `refreshLToken(stoken, stuid)`      | 无 mock 文件（直接返回固定 token 字符串）          |
| `verifyLToken(ltoken, ltuid)`       | 无 mock 文件（直接返回 `{ retcode: 0 }`）          |

> 注意：Cookie 刷新接口（`refreshCookieToken`、`refreshLToken`、`verifyLToken`）在 Mock 环境下不需要真实 Passport 服务，直接返回固定值即可，无需对应 mock 文件。

**GenshinMockService：**

| 方法                                                       | 对应文件                                                |
| ---------------------------------------------------------- | ------------------------------------------------------- |
| `getDailyNote(roleId, server, cookie)`                     | `game_record_app_genshin_api_dailyNote.json`            |
| `getCharacterList(roleId, server, cookie)`                 | `game_record_app_genshin_api_character_list.json`       |
| `getCharacterDetail(roleId, server, characterIds, cookie)` | `game_record_app_genshin_api_character_detail_all.json` |
| `batchCompute(items, uid, region, cookie)`                 | `genshin_character_batch_compute.json`                  |

> 注意：`character_detail.json`（单角色）和 `character_detail_all.json`（批量）写入同一张表，Mock Service 统一使用 `character_detail_all.json` 作为返回数据。

**StarRailMockService：**

| 方法                                              | 对应文件                                      |
| ------------------------------------------------- | --------------------------------------------- |
| `getDailyNote(roleId, server, cookie)`            | `game_record_app_hkrpg_api_note.json`         |
| `getAvatarBasic(roleId, server, cookie)`          | `game_record_app_hkrpg_api_avatar_basic.json` |
| `getAvatarInfo(roleId, server, id, cookie)`       | `game_record_app_hkrpg_api_avatar_info.json`  |
| `compute(avatar, skillList, uid, region, cookie)` | `hkrpg_character_compute.json`                |

**ZZZMockService：**

| 方法                                                                                                     | 对应文件                                          |
| -------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| `getDailyNote(roleId, server, cookie)`                                                                   | `event_game_record_zzz_api_zzz_note.json`         |
| `getAvatarBasic(roleId, server, cookie)`                                                                 | `event_game_record_zzz_api_zzz_avatar_basic.json` |
| `getAvatarInfo(roleId, server, idList, cookie)`                                                          | `event_game_record_zzz_api_zzz_avatar_info.json`  |
| `compute(avatarId, avatarLevel, avatarCurrentLevel, avatarCurrentPromotes, skills, uid, region, cookie)` | `zzz_character_compute.json`                      |

**SignMockService：**

| 方法                                                    | 对应文件                                                                       |
| ------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `signBBS(cookie, challenge?)`                           | `apihub_app_api_signIn.json`                                                   |
| `signGame(gameBiz, roleId, server, cookie, challenge?)` | `event_luna_{host}_sign.json`（host 由 gameBiz 决定，如 `hk4e`/`hkrpg`/`zzz`） |
| `getSignInfo(gameBiz, roleId, server, cookie)`          | `event_luna_{host}_info.json`                                                  |
| `getSignReward(gameBiz, cookie)`                        | `event_luna_{host}_home.json`                                                  |

> 注意：`SignMockService` 根据 `gameBiz` 参数动态映射文件名，例如 `gameBiz="hk4e_cn"` 时读取 `event_luna_hk4e_sign.json`。`getSignReward` 对应的 `home` 文件（`event_luna_hk4e_home.json` 等）需要在 mock 目录下补充创建。

---

## 环境工厂

`CoreInitializerV2` 根据 build product 决定使用哪套 Service：

```typescript
// core/src/main/ets/network/v2/MihoyoEnvironment.ets
export enum MihoyoEnvironment {
  /** Mock 环境：读取本地 rawfile/mock/ 目录下的 JSON 文件 */
  MOCK = "MOCK",
  /** Release 环境：发起真实 HTTP 请求 */
  RELEASE = "RELEASE",
}

// core/src/main/ets/network/v2/MihoyoApiServiceFactory.ets
import { common } from "@kit.AbilityKit";

export class MihoyoApiServiceFactory {
  /**
   * Mock Service 需要 context 来读取 rawfile，Release Service 不需要。
   * Mock 环境下 context 必须传入，否则抛出错误。
   * ArkTS 严格模式：禁止 ! 非空断言，改为显式 null 检查。
   */
  private static requireContext(
    context?: common.UIAbilityContext,
  ): common.UIAbilityContext {
    if (context === undefined) {
      throw new Error(
        "MihoyoApiServiceFactory: context is required for Mock environment",
      );
    }
    return context;
  }

  static createAccountService(
    env: MihoyoEnvironment,
    context?: common.UIAbilityContext,
  ): MihoyoApiService {
    return env === MihoyoEnvironment.MOCK
      ? new MihoyoAccountMockService(
          MihoyoApiServiceFactory.requireContext(context),
        )
      : new MihoyoAccountApiService();
  }

  static createGenshinService(
    env: MihoyoEnvironment,
    context?: common.UIAbilityContext,
  ): MihoyoApiService {
    return env === MihoyoEnvironment.MOCK
      ? new GenshinMockService(MihoyoApiServiceFactory.requireContext(context))
      : new GenshinApiService();
  }

  static createStarRailService(
    env: MihoyoEnvironment,
    context?: common.UIAbilityContext,
  ): MihoyoApiService {
    return env === MihoyoEnvironment.MOCK
      ? new StarRailMockService(MihoyoApiServiceFactory.requireContext(context))
      : new StarRailApiService();
  }

  static createZZZService(
    env: MihoyoEnvironment,
    context?: common.UIAbilityContext,
  ): MihoyoApiService {
    return env === MihoyoEnvironment.MOCK
      ? new ZZZMockService(MihoyoApiServiceFactory.requireContext(context))
      : new ZZZApiService();
  }

  static createSignService(
    env: MihoyoEnvironment,
    context?: common.UIAbilityContext,
  ): MihoyoApiService {
    return env === MihoyoEnvironment.MOCK
      ? new SignMockService(MihoyoApiServiceFactory.requireContext(context))
      : new SignApiService();
  }
}
```

---

## 正确性属性

### Property 1：Mock 与 Release 接口一致性

对任意 Mock Service 和对应 Release Service，调用相同方法应返回相同结构的 `Promise<object>`，字段名和类型一致（值可以不同）。

### Property 2：文件名映射幂等性

对任意 URL 路径，多次调用文件名映射函数应返回相同结果。

### Property 3：Cookie 路由正确性

对任意 `account_id=N` 的 Cookie，Mock Service 应读取 `mock/accountN/` 目录下的文件；若该目录不存在对应文件，返回空成功响应（`{ retcode: 0, data: {} }`），不抛出错误。

---

## Mock 延迟模拟

### 现有行为

现有 `MockService` 对所有请求统一添加 **300ms 延迟**，模拟真实网络往返时间：

```typescript
public async get(url: string, ...): Promise<object> {
  await this.delay(300);
  return this.getMockData(url, options);
}
```

### 新版保留策略

新版 Mock Service 保留 300ms 延迟，理由：

- 模拟真实网络延迟，避免 UI 动画（骨架屏、加载态）因瞬间响应而无法验证
- 防止 ViewModel 中因"同步感"掩盖的竞态问题
- 延迟值通过常量配置，便于测试时调整

```typescript
// core/src/main/ets/network/v2/mock/MockServiceBase.ets
import { common } from "@kit.AbilityKit";
import { util } from "@kit.ArkTS";
import { MihoyoApiService } from "../MihoyoApiService";
import { RequestParams, RequestOptions } from "../../APIs";

export abstract class MockServiceBase extends MihoyoApiService {
  protected static readonly MOCK_DELAY_MS: number = 300;
  // context 在构造时注入，用于访问 resourceManager 读取 rawfile
  protected readonly context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    super();
    this.context = context;
  }

  /** 模拟网络延迟，自动化测试时可子类覆盖返回 Promise.resolve() */
  protected delay(): Promise<void> {
    return new Promise((resolve) =>
      setTimeout(resolve, MockServiceBase.MOCK_DELAY_MS),
    );
  }

  /**
   * 读取 mock 文件并检查 retcode
   * @param path    URL 路径（用于映射文件名）
   * @param cookie  登录 Cookie（用于提取 account_id 路由子目录）
   */
  protected async readMockFile(path: string, cookie: string): Promise<object> {
    await this.delay();
    const accountId = MockServiceBase.extractAccountId(cookie);
    const fileName = MockServiceBase.pathToFileName(path);
    // 使用 resourceManager 读取 rawfile（项目里没有 RawFileUtil，直接用系统 API）
    const rm = this.context.resourceManager;
    let fileContent: Uint8Array;
    try {
      fileContent = await rm.getRawFileContent(
        `mock/account${accountId}/${fileName}`,
      );
    } catch (_) {
      // 文件不存在时返回空成功响应，不抛出错误
      // 这样 Mock Service 在文件缺失时不会崩溃，便于逐步补充 mock 数据
      return { retcode: 0, message: "success", data: {} } as Record<
        string,
        Object
      >;
    }
    const decoder = new util.TextDecoder("utf-8");
    const jsonStr = decoder.decodeToString(new Uint8Array(fileContent.buffer));
    let raw: Record<string, Object>;
    try {
      raw = JSON.parse(jsonStr) as Record<string, Object>;
    } catch (_) {
      // JSON 解析失败时返回空成功响应
      return { retcode: 0, message: "success", data: {} } as Record<
        string,
        Object
      >;
    }

    // ArkTS 严格模式：通过 Record<string, Object> 访问字段
    const retcode = raw["retcode"] as number;
    if (retcode !== 0) {
      const message = raw["message"] as string;
      throw new Error(`retcode=${retcode}: ${message}`);
    }
    return raw;
  }

  /**
   * URL 路径 → 文件名
   * 通用规则：去首尾斜杠，斜杠替换为下划线，加 .json 后缀
   * 特殊映射：养成计算接口的文件名不遵循通用规则（自动映射结果过长）
   * 注意：path 可能带 query 参数（如 ?uid=...&region=...），需要先去掉
   */
  private static pathToFileName(path: string): string {
    // 先去掉 query 参数（? 之后的部分）
    const cleanPath = path.split("?")[0];

    // 特殊映射表（key: API Path，value: 实际文件名）
    // ArkTS 严格模式：Map 需要明确泛型类型
    const specialMap = new Map<string, string>();
    specialMap.set(
      "/event/e20200928calculate/v3/batch_compute",
      "genshin_character_batch_compute.json",
    );
    specialMap.set("/event/rpgcalc/compute", "hkrpg_character_compute.json");
    specialMap.set(
      "/event/nap_cultivate_tool/avatar_calc",
      "zzz_character_compute.json",
    );
    // 大别野签到：BBS_APIHUB Domain 已含 /apihub 前缀，path 是 /app/api/signIn
    // 但 mock 文件名按完整路径 /apihub/app/api/signIn 命名
    specialMap.set("/app/api/signIn", "apihub_app_api_signIn.json");
    // 原神角色详情：Mock Service 统一使用批量查询文件（含所有角色数据）
    specialMap.set(
      "/game_record/app/genshin/api/character/detail",
      "game_record_app_genshin_api_character_detail_all.json",
    );

    const special = specialMap.get(cleanPath);
    if (special !== undefined) {
      return special;
    }
    return cleanPath.replace(/^\//, "").replace(/\//g, "_") + ".json";
  }

  /**
   * 从 Cookie 字符串提取 account_id，失败时返回 1（fallback）
   * ArkTS 严格模式：String.match() 返回 RegExpMatchArray | null，必须显式判断
   * 注意：ArkTS 严格模式下正则表达式字面量可用，但 match() 返回值需要 null 检查
   */
  private static extractAccountId(cookie: string): number {
    const match = cookie.match(/account_id=(\d+)/);
    if (match === null || match.length < 2) {
      return 1;
    }
    // ArkTS 严格模式：数组元素类型为 string | undefined，需要判断
    const group = match[1];
    if (group === undefined) {
      return 1;
    }
    const parsed = parseInt(group);
    return isNaN(parsed) ? 1 : parsed;
  }

  // MihoyoApiService 抽象方法，子类实现
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

## Mock 数据的 retcode 处理

### 处理规则

`MockServiceBase.readMockFile()` 读取文件后自动检查 `retcode`，非 0 时抛出与 Release Service 相同格式的错误（详见上节 `MockServiceBase` 设计）。

### retcode 场景对照表

| retcode | 含义              | Mock 文件示例                                                 | 触发方式                          |
| ------- | ----------------- | ------------------------------------------------------------- | --------------------------------- |
| 0       | 成功              | 正常 mock 文件                                                | 默认行为                          |
| -100    | Cookie 失效       | `{ "retcode": -100, "message": "登录已过期", "data": null }`  | 将 mock 文件的 retcode 改为 -100  |
| 10035   | 需要 Geetest 验证 | `{ "retcode": 10035, "message": "需要验证", "data": null }`   | 将 mock 文件的 retcode 改为 10035 |
| 10102   | 角色战绩未公开    | `{ "retcode": 10102, "message": "战绩未公开", "data": null }` | 将 mock 文件的 retcode 改为 10102 |

### 与 Release Service 的一致性

Mock Service 抛出的错误格式与 Release Service 完全相同（`retcode=${code}: ${message}`），因此 Repository 层的错误处理代码无需区分环境：

```typescript
// Repository 层统一错误处理（Mock 和 Release 行为一致）
// 注意：实际实现时应通过 this.getService() 获取 service，而非直接访问 this.service
try {
  const data = await this.getService().getDailyNote(roleId, server, cookie);
  // 处理成功数据
} catch (e) {
  // ArkTS 严格模式：catch 的 e 是 Object，需要先 instanceof 再 as 断言
  const msg = e instanceof Error ? (e as Error).message : String(e);
  if (msg.includes(`retcode=${ApiErrorCodes.AUTH_INVALID}`)) {
    // Cookie 失效，通知 UI 重新登录
  } else if (msg.includes(`retcode=${ApiErrorCodes.GEETEST_REQUIRED}`)) {
    // 触发 Geetest 验证
  }
}
```

---

## 错误处理

| 错误场景             | 处理方式                                                         |
| -------------------- | ---------------------------------------------------------------- |
| 文件不存在           | 返回 `{ retcode: 0, message: 'success', data: {} }`，不抛出错误  |
| JSON 解析失败        | 返回 `{ retcode: 0, message: 'success', data: {} }`，不抛出错误  |
| Cookie 无 account_id | fallback 到 account1 子目录                                      |
| 根目录也无对应文件   | 返回 `{ retcode: 0, message: 'success', data: {} }`              |
| retcode 非 0         | 抛出 `Error('retcode=${code}: ${message}')`，与 Release 行为一致 |

---

## 扩展性设计

新增游戏类型（以崩坏 3 为例），只需：

1. 新建 `Honkai3MockService.ets`（继承 `MihoyoApiService`，直接 import `Honkai3ApiPath`）
2. 在 `MihoyoApiServiceFactory` 中追加 `createHonkai3Service()`
3. 在 `rawfile/mock/accountX/` 下添加对应 JSON 文件

**不需要**新建独立的 Mock Path 枚举文件（直接复用 release 的 `Honkai3ApiPath`），不修改任何现有文件。

---

## 错误码统一处理（Mock 视角）

Mock Service 与 Release Service 使用完全相同的错误码和错误格式，详见 `mihoyo-api-redesign/design.md` 中的"错误码统一处理"章节。

Mock 环境特有说明：

- 通过修改 mock JSON 文件中的 `retcode` 字段，可以模拟任意错误场景
- Mock Service 读取文件后检查 `retcode`，非 0 时抛出 `Error('retcode=${code}: ${message}')`
- Repository 层的错误处理代码在 Mock 和 Release 环境下行为完全一致，无需区分

---

## CoreInitializerV2 完整设计（Mock 视角）

详见 `game-data-database-redesign/design.md` 中的"CoreInitializerV2 初始化流程"章节。

Mock 环境特有说明：

- `CoreInitializerV2.initCore({ isMock: true, context })` 时，`MihoyoApiServiceFactory` 创建各 MockService 实例
- MockService 实例注入到 Repository 后，Repository 层代码无需感知当前是 Mock 还是 Release 环境
- `MihoyoEnvironment.MOCK` 枚举值由 `BuildProfile.ets` 中的 `APP_RUNTIME_ENV` 决定

---

## Geetest 和签到的 Mock 说明

### Geetest Mock 文件

| 文件名                             | 说明              | 模拟场景              |
| ---------------------------------- | ----------------- | --------------------- |
| `misc_api_createVerification.json` | 申请 Geetest 验证 | 正常返回 gt/challenge |
| `misc_api_verifyVerification.json` | 提交 Geetest 验证 | 正常返回新 challenge  |

通过修改 `retcode` 可以模拟验证失败场景。

### 签到 Mock 文件

| 文件名                       | 对应接口           | 正常响应                                        |
| ---------------------------- | ------------------ | ----------------------------------------------- |
| `apihub_app_api_signIn.json` | 大别野签到         | `{ retcode: 0, message: "OK" }`                 |
| `event_luna_hk4e_sign.json`  | 原神每日签到       | `{ retcode: 0, data: { success: 0 } }`          |
| `event_luna_hkrpg_sign.json` | 星铁每日签到       | `{ retcode: 0, data: { success: 0 } }`          |
| `event_luna_zzz_sign.json`   | 绝区零每日签到     | `{ retcode: 0, data: { success: 0 } }`          |
| `event_luna_hk4e_info.json`  | 原神签到状态       | `{ retcode: 0, data: { is_sign: false, ... } }` |
| `event_luna_hkrpg_info.json` | 星铁签到状态       | `{ retcode: 0, data: { is_sign: false, ... } }` |
| `event_luna_zzz_info.json`   | 绝区零签到状态     | `{ retcode: 0, data: { is_sign: false, ... } }` |
| `event_luna_hk4e_home.json`  | 原神今日签到奖励   | `{ retcode: 0, data: { awards: [...] } }`       |
| `event_luna_hkrpg_home.json` | 星铁今日签到奖励   | `{ retcode: 0, data: { awards: [...] } }`       |
| `event_luna_zzz_home.json`   | 绝区零今日签到奖励 | `{ retcode: 0, data: { awards: [...] } }`       |

**模拟 Geetest 触发（retcode=1034）：**

将签到 mock 文件的 retcode 改为 `1034`：

```json
{ "retcode": 1034, "message": "需要验证", "data": null }
```

**模拟 is_risk=true（签到响应直接带 Geetest 参数）：**

```json
{
  "retcode": 0,
  "data": {
    "success": 1,
    "is_risk": true,
    "gt": "mock_gt_value",
    "challenge": "mock_challenge_value",
    "risk_code": 375
  }
}
```

> 注意：`is_risk=true` 时 `retcode=0`，不是错误，但 `success=1` 表示需要 Geetest 验证。Mock Service 需要检查 `data.is_risk` 字段，不能只检查 `retcode`。`MockServiceBase.readMockFile()` 只处理 `retcode !== 0` 的情况，`is_risk` 的检查由 `SignMockService` 在读取文件后自行处理。
