# 构建环境与 Configuration 统一治理 — 设计文档

## 一、架构总览

### 当前架构（问题状态）

```
BuildProfile
  ├── IS_MOCK: "true"/"false"        ← 冗余字段
  └── APP_ENV: "mock"/"debug"/"release"
        ↓
entry/config/RuntimeConfig.ets
  └── APP_RUNTIME_ENV: string        ← 字符串，不类型安全
        ↓
entry/utils/Logger.ets
  ├── RuntimeEnv enum                ← 第二套枚举，需要 parseRuntimeEnv() 转换
  ├── isMockEnv()                    ← 环境判断混入 Logger（职责污染）
  └── isReleaseEnv()                 ← 同上
        ↓
EntryAbility.ets
  └── 手动映射 RuntimeEnv → MihoyoEnvironment  ← 第三套枚举，两次转换
        ↓
CoreInitializer.initCore({ env: MihoyoEnvironment })
```

**问题汇总：**

- 三套并行的环境枚举，新增环境需改三处
- `Logger` 承担了日志输出 + 环境判断两个职责（违反 SRP）
- `Logger` 在 `entry` 层，`core` 层无法使用，导致 core 内部日志缺失或重复实现
- `BuildProfile` 有冗余字段 `IS_MOCK`

### 目标架构（治理后）

```
BuildProfile
  └── APP_ENV: "mock"/"debug"/"release"   ← 唯一字段
        ↓
entry/config/RuntimeConfig.ets
  └── APP_ENV: AppEnv                     ← 直接输出枚举，类型安全，3 行代码
        ↓
CoreInitializer.initCore({ env: AppEnv })
  └── AppEnvManager.setup(env)            ← 注入全局环境，一次设置
        ↓
AppEnvManager（core 层，全局单例）
  ├── getEnv(): AppEnv
  ├── isMock(): boolean
  ├── isDebug(): boolean
  └── isRelease(): boolean
        ↓
Logger（core 层，entry/core 共用）
  └── 通过 AppEnvManager.getEnv() 获取环境标签，不持有判断逻辑
```

**改进点：**

- 全项目只有一个环境枚举 `AppEnv`（core 层）
- 环境判断职责集中在 `AppEnvManager`，Logger 只负责日志
- `Logger` 迁移到 core 层，entry 和 core 共用同一个 Logger
- `EntryAbility` 零转换，直接传 `APP_ENV`

---

## 二、AppEnv 枚举设计

### 文件位置

`core/src/main/ets/constants/AppEnv.ets`

### 枚举定义

```typescript
/**
 * 应用运行环境枚举。
 *
 * 枚举值与 build-profile.json5 的 buildModeSet.name 一一对应（均小写）。
 * 新增环境时：
 *   1. 在此枚举添加新值
 *   2. 在 build-profile.json5 的 buildModeSet 添加对应条目
 *   3. 在 appEnvFromString() 添加对应分支
 *   4. 无需修改其他任何文件
 */
export enum AppEnv {
  /** Mock 环境：使用本地 rawfile mock 数据，不发起真实网络请求 */
  MOCK = "mock",
  /** Debug 环境：使用真实 API，可配合 Proxyman 抓包调试 */
  DEBUG = "debug",
  /** Release 环境：生产环境，关闭调试日志 */
  RELEASE = "release",
}

/**
 * 从 BuildProfile.APP_ENV 字符串转换为 AppEnv 枚举。
 * 未知值 fallback 到 DEBUG（安全默认值：不误用 mock 数据，不关闭日志）。
 */
export function appEnvFromString(s: string): AppEnv {
  const lower: string = s.toLowerCase();
  if (lower === AppEnv.MOCK) {
    return AppEnv.MOCK;
  }
  if (lower === AppEnv.RELEASE) {
    return AppEnv.RELEASE;
  }
  return AppEnv.DEBUG;
}
```

### 设计决策

- **枚举值用小写字符串**：与 `buildModeSet.name` 保持一致，`appEnvFromString` 只需 `toLowerCase()` 比较
- **fallback 到 DEBUG**：未知环境不会误用 mock 数据，也不会关闭日志，是最安全的默认值
- **放在 core 层**：`entry` 依赖 `core`，反向不成立；环境枚举是基础设施，属于 core 职责范围

---

## 三、AppEnvManager 设计

### 文件位置

`core/src/main/ets/constants/AppEnvManager.ets`

### 职责

全项目唯一的环境判断入口，承担原来分散在 `Logger`、`CoreInitializer`、`AuthRepository` 中的环境判断逻辑。

### 类定义

```typescript
import { AppEnv } from "./AppEnv";

/**
 * 应用环境管理器（全局单例）。
 *
 * 职责：持有当前运行环境，提供环境判断方法。
 * 初始化：由 CoreInitializer.initCore() 在启动时调用 AppEnvManager.setup(env)。
 *
 * 使用方：
 *   - core 层：Repository、Service、DAO 直接 import 使用
 *   - entry 层：通过 'core' 导出 import 使用
 *   - Logger：通过 AppEnvManager.getEnv() 获取环境标签，不持有判断逻辑
 */
export class AppEnvManager {
  private static currentEnv: AppEnv = AppEnv.DEBUG;

  /**
   * 由 CoreInitializer 在启动时调用，设置当前环境。
   * 重复调用会覆盖（CoreInitializer 自身有 initialized 保护，实际只调用一次）。
   */
  static setup(env: AppEnv): void {
    AppEnvManager.currentEnv = env;
  }

  /** 获取当前运行环境 */
  static getEnv(): AppEnv {
    return AppEnvManager.currentEnv;
  }

  /** 是否为 Mock 环境 */
  static isMock(): boolean {
    return AppEnvManager.currentEnv === AppEnv.MOCK;
  }

  /** 是否为 Debug 环境 */
  static isDebug(): boolean {
    return AppEnvManager.currentEnv === AppEnv.DEBUG;
  }

  /** 是否为 Release 环境 */
  static isRelease(): boolean {
    return AppEnvManager.currentEnv === AppEnv.RELEASE;
  }
}
```

### 设计决策

- **默认值为 `DEBUG`**：未初始化时 fallback 到 debug，不会误用 mock 数据，也不会关闭日志
- **不抛异常**：`getEnv()` 永远有返回值，避免启动时序问题导致崩溃
- **core 层内部使用**：Repository、Service 判断 `isMock` 时直接调用 `AppEnvManager.isMock()`，不再通过 `CoreInitializer.getIsMock()` 或 `AuthRepository.isMock` 静态字段

---

## 四、Logger 迁移到 core 层

### 文件位置（迁移后）

`core/src/main/ets/utils/Logger.ets`（从 `entry/src/main/ets/utils/Logger.ets` 迁移）

### 职责边界

| 职责                                     | 归属                                                 |
| ---------------------------------------- | ---------------------------------------------------- |
| 日志格式化、输出                         | `Logger`                                             |
| 当前环境标签（用于日志）                 | `Logger` 通过 `AppEnvManager.getEnv()` 读取          |
| 环境判断（isMock/isRelease/isDebug）     | `AppEnvManager`，Logger 不再提供                     |
| 日志级别过滤（release 只输出 info/warn） | `Logger` 内部，通过 `AppEnvManager.isRelease()` 判断 |

### 关键变更

```typescript
// core/src/main/ets/utils/Logger.ets
import { AppEnvManager } from "../constants/AppEnvManager";

export class Logger {
  // ✅ 保留：info/warn/error/debug/trace/ctx 方法，签名完全不变
  // ✅ 保留：LogContext interface
  // ✅ 保留：日志格式（时间戳、序号、tag、message）

  // ❌ 删除：RuntimeEnv 枚举（整个删除）
  // ❌ 删除：getRuntimeEnv()
  // ❌ 删除：isMockEnv()
  // ❌ 删除：isReleaseEnv()
  // ❌ 删除：parseRuntimeEnv()
  // ❌ 删除：getRuntimeEnvDetail()（改为 getEnvDetail()，由调用方自行拼接）
  // ❌ 删除：APP_RUNTIME_SOURCE import

  // 日志中的环境标签改为从 AppEnvManager 读取
  private static getEnvLabel(): string {
    return AppEnvManager.getEnv(); // AppEnv 枚举值即为标签字符串（'mock'/'debug'/'release'）
  }

  // 级别过滤改为通过 AppEnvManager 判断
  private static canOutput(level: LogLevel): boolean {
    if (!AppEnvManager.isRelease()) {
      return true;
    }
    return level === LogLevel.INFO || level === LogLevel.WARNING;
  }
}
```

### entry 层的 import 变更

```typescript
// 修改前（entry 层各文件）
import { Logger } from "../utils/Logger";
import { Logger, RuntimeEnv } from "../utils/Logger";

// 修改后
import { Logger } from "core";
```

所有 `RuntimeEnv.MOCK` 等引用改为通过 `AppEnvManager` 判断，或直接比较 `AppEnv` 枚举值。

---

## 五、BuildProfile 字段设计

### build-profile.json5（根目录）

```json5
buildModeSet: [
  {
    name: "mock",
    buildOption: {
      arkOptions: {
        buildProfileFields: {
          APP_ENV: "mock",
        },
      },
    },
  },
  {
    name: "debug",
    buildOption: {
      arkOptions: {
        buildProfileFields: {
          APP_ENV: "debug",
        },
      },
    },
  },
  {
    name: "release",
    buildOption: {
      arkOptions: {
        buildProfileFields: {
          APP_ENV: "release",
        },
      },
    },
  },
],
```

**删除 `IS_MOCK` 字段**，`isMock` 判断统一改为 `AppEnvManager.isMock()`。

---

## 六、RuntimeConfig.ets 设计

```typescript
// entry/src/main/ets/config/RuntimeConfig.ets
import BuildProfile from "BuildProfile";
import { AppEnv, appEnvFromString } from "core";

/**
 * 当前运行环境。
 * 直接从 hvigor buildProfileFields.APP_ENV 读取并转换为 AppEnv 枚举。
 */
export const APP_ENV: AppEnv = appEnvFromString(String(BuildProfile.APP_ENV));
```

只有 3 行有效代码，无任何条件分支。

---

## 七、CoreInitializer.ets 设计

```typescript
import { AppEnv } from "./constants/AppEnv";
import { AppEnvManager } from "./constants/AppEnvManager";

interface CoreConfig {
  env: AppEnv;
  context: common.UIAbilityContext;
}

export class CoreInitializer {
  static async initCore(config: CoreConfig): Promise<void> {
    if (CoreInitializer.initialized) {
      return;
    }

    // 第一步：注入全局环境（后续所有 AppEnvManager.isMock() 调用均依赖此）
    AppEnvManager.setup(config.env);

    // 删除：CoreInitializer.isMockEnv 字段
    // 删除：AuthRepository.isMock = isMock 赋值
    // 所有 isMock 判断改为 AppEnvManager.isMock()

    // ... 其余逻辑不变
  }
}
```

**删除** `MihoyoEnvironment` import，`MihoyoEnvironment.ets` 文件整体删除。
**删除** `CoreInitializer.isMockEnv` 私有字段和 `getIsMock()` 方法。

---

## 八、EntryAbility.ets 设计

```typescript
import { CoreInitializer, Logger } from "core";
import { APP_ENV } from "../config/RuntimeConfig";

export default class EntryAbility extends UIAbility {
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam) {
    Logger.info(TAG, "onCreate");

    // 直接传递 AppEnv，无需任何转换
    CoreInitializer.initCore({ env: APP_ENV, context: this.context }).then(
      () => {
        Logger.info(TAG, `CoreV2 initialized. env=${APP_ENV}`);
      },
    );

    Logger.info(TAG, `env=${APP_ENV}`);
  }
}
```

**删除**：`RuntimeEnv` import、`MihoyoEnvironment` import、`mihoyoEnv` 中间变量、`runStartupTaskByEnv()` 方法。

---

## 九、IDE Run Configuration 设计

### 标准 Configuration 集合

| Configuration 名称      | 类型         | 用途                              | buildMode |
| ----------------------- | ------------ | --------------------------------- | --------- |
| `Run Mock`              | DevEco Run   | 日常开发，Mock 数据，支持断点     | `mock`    |
| `Run Debug`             | DevEco Run   | 联调真实 API + Proxyman，支持断点 | `debug`   |
| `Build Release`         | Hvigor Build | 打包发布                          | `release` |
| `Test core (unit)`      | Hvigor Test  | core 本地单元测试                 | `mock`    |
| `Test entry (unit)`     | Hvigor Test  | entry 本地单元测试                | `mock`    |
| `Test entry (snapshot)` | Hvigor Test  | entry 设备端 UI/Snapshot 测试     | `mock`    |

### 删除的旧 Configuration

| 文件                      | 原因                                 |
| ------------------------- | ------------------------------------ |
| `Build_Mock_Entry.xml`    | 使用废弃的 `-p product=mock` 参数    |
| `Build_Release_Entry.xml` | 使用废弃的 `-p product=release` 参数 |

---

## 十、脚本设计

| 脚本             | buildMode | 用途                 |
| ---------------- | --------- | -------------------- |
| `run.sh`         | `mock`    | 现有，保持不变       |
| `run-debug.sh`   | `debug`   | 新增，联调真实 API   |
| `run-release.sh` | `release` | 更新参数             |
| `test-core.sh`   | `mock`    | 新增，core ohosTest  |
| `test-entry.sh`  | `mock`    | 新增，entry ohosTest |

---

## 十一、文件变更清单

### 新增文件

| 文件                                              | 说明                    |
| ------------------------------------------------- | ----------------------- |
| `core/src/main/ets/constants/AppEnv.ets`          | 统一环境枚举 + 工厂函数 |
| `core/src/main/ets/constants/AppEnvManager.ets`   | 环境管理器（单例）      |
| `core/src/main/ets/utils/Logger.ets`              | Logger 迁移到 core      |
| `.idea/runConfigurations/Run_Mock.xml`            | IDE Run Mock 配置       |
| `.idea/runConfigurations/Run_Debug.xml`           | IDE Run Debug 配置      |
| `.idea/runConfigurations/Build_Release.xml`       | IDE Build Release 配置  |
| `.idea/runConfigurations/Test_Core_Unit.xml`      | core 单元测试配置       |
| `.idea/runConfigurations/Test_Entry_Unit.xml`     | entry 单元测试配置      |
| `.idea/runConfigurations/Test_Entry_Snapshot.xml` | entry Snapshot 测试配置 |
| `run-debug.sh`                                    | debug 模式构建脚本      |
| `test-core.sh`                                    | core 测试脚本           |
| `test-entry.sh`                                   | entry 测试脚本          |

### 修改文件

| 文件                                                    | 变更内容                                                                            |
| ------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `build-profile.json5`                                   | 删除 `IS_MOCK`，每个 buildMode 只保留 `APP_ENV`                                     |
| `core/Index.ets`                                        | 新增导出：`AppEnv`、`appEnvFromString`、`AppEnvManager`、`Logger`（迁移后）         |
| `core/src/main/ets/CoreInitializer.ets`                 | `MihoyoEnvironment` → `AppEnv`，新增 `AppEnvManager.setup()`，删除 `isMockEnv` 字段 |
| `core/src/main/ets/network/MihoyoApiServiceFactory.ets` | `MihoyoEnvironment` → `AppEnv`，`isMock` 改为 `AppEnvManager.isMock()`              |
| `core/src/main/ets/repository/AuthRepository.ets`       | 删除 `static isMock` 字段，改为 `AppEnvManager.isMock()`                            |
| `entry/src/main/ets/config/RuntimeConfig.ets`           | 改为直接输出 `AppEnv` 枚举                                                          |
| `entry/src/main/ets/entryability/EntryAbility.ets`      | 删除中间转换，直接传 `APP_ENV`，Logger 改从 core import                             |
| `entry/src/main/ets/**/*.ets`（所有 Logger 引用方）     | `import { Logger } from '../utils/Logger'` → `import { Logger } from 'core'`        |
| `run-release.sh`                                        | 更新 buildMode 参数                                                                 |

### 删除文件

| 文件                                              | 原因             |
| ------------------------------------------------- | ---------------- |
| `core/src/main/ets/network/MihoyoEnvironment.ets` | 被 `AppEnv` 替代 |
| `entry/src/main/ets/utils/Logger.ets`             | 迁移到 core 层   |
| `.idea/runConfigurations/Build_Mock_Entry.xml`    | 使用废弃参数     |
| `.idea/runConfigurations/Build_Release_Entry.xml` | 使用废弃参数     |

---

## 十二、扩展性说明

### 新增环境（如 `staging`）

只需三步：

**步骤 1**：在 `AppEnv.ets` 添加枚举值和 `appEnvFromString` 分支

```typescript
export enum AppEnv {
  MOCK = "mock",
  DEBUG = "debug",
  STAGING = "staging", // 新增
  RELEASE = "release",
}

export function appEnvFromString(s: string): AppEnv {
  const lower: string = s.toLowerCase();
  if (lower === AppEnv.MOCK) {
    return AppEnv.MOCK;
  }
  if (lower === AppEnv.STAGING) {
    return AppEnv.STAGING;
  } // 新增
  if (lower === AppEnv.RELEASE) {
    return AppEnv.RELEASE;
  }
  return AppEnv.DEBUG;
}
```

**步骤 2**：在 `build-profile.json5` 添加 buildMode

```json5
{
  name: "staging",
  buildOption: {
    arkOptions: {
      buildProfileFields: { APP_ENV: "staging" },
    },
  },
},
```

**步骤 3**（可选）：在 `AppEnvManager` 添加 `isStaging()` 便捷方法

无需修改其他任何文件。
