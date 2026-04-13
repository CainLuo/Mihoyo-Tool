# 构建环境与 Configuration 统一治理 — 需求文档

## 背景

当前项目存在以下问题，需要从架构层面统一治理：

### 问题一：环境枚举分裂

| 位置                                 | 枚举/类型                | 值                                             |
| ------------------------------------ | ------------------------ | ---------------------------------------------- |
| `entry/config/RuntimeConfig.ets`     | `string`                 | `'Mock'` / `'Debug'` / `'Release'` / `'Other'` |
| `entry/utils/Logger.ets`             | `RuntimeEnv` enum        | `MOCK` / `DEBUG` / `RELEASE` / `OTHER`         |
| `core/network/MihoyoEnvironment.ets` | `MihoyoEnvironment` enum | `MOCK` / `DEBUG` / `RELEASE`                   |

三套并行的环境表示，`EntryAbility` 需要做两次转换（字符串 → `RuntimeEnv` → `MihoyoEnvironment`），新增环境时需要同步修改三处。

### 问题二：BuildProfile 字段冗余

`buildModeSet` 里用了两个字段（`IS_MOCK` + `APP_ENV`）来表达同一件事，逻辑分散：

```json5
// mock buildMode
{ IS_MOCK: "true", APP_ENV: "mock" }

// debug buildMode
{ IS_MOCK: "false", APP_ENV: "debug" }
```

`IS_MOCK` 是 `APP_ENV === 'mock'` 的冗余派生，应该只保留一个字段。

### 问题三：IDE Run Configuration 混乱

截图中可见 9 个 Configuration，其中：

- `Build Mock (entry)` 使用旧的 `-p product=mock` 参数（已废弃的 product 方案）
- `Build Release (entry)` 使用旧的 `-p product=release` 参数（已废弃）
- 多个 `Mihoyo-Tool [...]` 是 IDE 自动生成的临时配置，没有语义
- 缺少 `debug` 模式的 Run/Debug Configuration
- 缺少测试相关的 Configuration（unit test、snapshot test）

### 问题四：测试 Configuration 缺失

根据测试策略文档，项目需要支持：

- `core` 本地单元测试（`core/src/test/`）
- `core` 设备端测试（`core/src/ohosTest/`）
- `entry` 本地单元测试（`entry/src/test/`）
- `entry` 设备端 UI/Snapshot 测试（`entry/src/ohosTest/`）

目前 IDE 中没有任何测试相关的 Configuration。

---

## 目标

1. **统一环境枚举**：全项目只有一个环境枚举 `AppEnv`，放在 `core` 层，`entry` 直接 import 使用，消除所有中间转换
2. **简化 BuildProfile 字段**：只保留 `APP_ENV` 一个字段，`buildModeSet` 与 `AppEnv` 枚举值一一对应
3. **整理 IDE Run Configuration**：清理废弃配置，建立语义清晰的标准配置集
4. **补全测试 Configuration**：支持单独/全部运行 core 单元测试、entry 单元测试、entry Snapshot 测试
5. **可扩展性**：新增环境（如 `staging`、`beta`）只需在 `AppEnv` 枚举加一个值 + `buildModeSet` 加一条记录

---

## 需求列表

### R1 — 统一环境枚举 `AppEnv`

- R1.1 在 `core/src/main/ets/constants/AppEnv.ets` 定义唯一的环境枚举
- R1.2 枚举值与 `buildModeSet` 的 `name` 字段一一对应（小写）
- R1.3 提供 `appEnvFromString(s: string): AppEnv` 工厂函数，用于从 `BuildProfile.APP_ENV` 字符串转换
- R1.4 通过 `core/Index.ets` 导出，供 `entry` 直接 import
- R1.5 删除 `core/network/MihoyoEnvironment.ets`，所有引用改为 `AppEnv`
- R1.6 删除 `entry/utils/Logger.ets` 中的 `RuntimeEnv` 枚举，改用 `AppEnv`
- R1.7 删除 `entry/config/RuntimeConfig.ets` 中的字符串输出，改为直接输出 `AppEnv`

### R1-A — 新增 `AppEnvManager`（环境判断职责分离）

当前 `Logger` 承担了两个职责：日志输出 + 环境判断（`isMockEnv()`、`isReleaseEnv()`、`getRuntimeEnv()`）。这违反了单一职责原则，且 core 层内部（Repository、Service）需要判断环境时不应该依赖 Logger。

- R1-A.1 在 `core/src/main/ets/constants/AppEnvManager.ets` 新建环境管理类
- R1-A.2 `AppEnvManager` 持有当前 `AppEnv`，由 `CoreInitializer.initCore()` 在启动时注入，全局单例
- R1-A.3 提供静态方法：`getEnv(): AppEnv`、`isMock(): boolean`、`isRelease(): boolean`、`isDebug(): boolean`
- R1-A.4 `Logger` 只接收 `AppEnv` 用于在日志中输出当前环境，不再持有任何环境判断逻辑
- R1-A.5 core 层内部（Repository、Service、DAO）需要判断环境时，统一调用 `AppEnvManager`，不得调用 `Logger`
- R1-A.6 通过 `core/Index.ets` 导出 `AppEnvManager`，供 `entry` 使用

### R1-B — Logger 迁移到 core 层

- R1-B.1 将 `Logger` 从 `entry/src/main/ets/utils/Logger.ets` 迁移到 `core/src/main/ets/utils/Logger.ets`
- R1-B.2 `Logger` 通过 `AppEnvManager.getEnv()` 获取当前环境，用于日志格式中的环境标签
- R1-B.3 `Logger` 不再 import `RuntimeConfig`，不再持有任何 `APP_ENV` 字段
- R1-B.4 通过 `core/Index.ets` 导出，`entry` 改为 `import { Logger } from 'core'`
- R1-B.5 删除 `entry/src/main/ets/utils/Logger.ets`（迁移完成后）
- R1-B.6 `entry` 中所有 `import { Logger } from '../utils/Logger'` 改为 `import { Logger } from 'core'`

### R2 — 简化 BuildProfile 字段

- R2.1 `buildModeSet` 每个 buildMode 只保留 `APP_ENV` 一个字段
- R2.2 删除 `IS_MOCK` 字段，`isMock` 逻辑改为 `AppEnv === AppEnv.MOCK`
- R2.3 `buildModeSet` 包含三个标准 buildMode：`mock`、`debug`、`release`
- R2.4 `RuntimeConfig.ets` 直接读取 `BuildProfile.APP_ENV` 并转换为 `AppEnv`

### R3 — 整理 IDE Run Configuration

清理后的标准 Configuration 集合：

| Configuration 名称 | 类型        | 用途                    | buildMode |
| ------------------ | ----------- | ----------------------- | --------- |
| `Run Mock`         | Run (HAP)   | 日常开发，Mock 数据     | `mock`    |
| `Run Debug`        | Run (HAP)   | 联调真实 API + Proxyman | `debug`   |
| `Build Release`    | Build (HAP) | 打包发布                | `release` |

- R3.1 删除旧的 `Build Mock (entry)`（使用废弃的 `-p product=mock`）
- R3.2 删除旧的 `Build Release (entry)`（使用废弃的 `-p product=release`）
- R3.3 新增 `Run Mock` — 使用 `-p buildMode=mock`，支持 Run + Debug
- R3.4 新增 `Run Debug` — 使用 `-p buildMode=debug`，支持 Run + Debug
- R3.5 新增 `Build Release` — 使用 `-p buildMode=release`，仅 Build
- R3.6 `project.cache.json` 的 `current.select.buildMode` 默认为 `mock`

### R4 — 测试 Configuration

| Configuration 名称    | 类型        | 测试目标                   | 运行位置    |
| --------------------- | ----------- | -------------------------- | ----------- |
| `Test core (unit)`    | Hvigor Test | `core/src/test/` 全部      | 本地 JVM    |
| `Test entry (unit)`   | Hvigor Test | `entry/src/test/` 全部     | 本地 JVM    |
| `Test core (device)`  | Hvigor Test | `core/src/ohosTest/` 全部  | 设备/模拟器 |
| `Test entry (device)` | Hvigor Test | `entry/src/ohosTest/` 全部 | 设备/模拟器 |

- R4.1 所有测试 Configuration 使用 `buildMode=mock`（测试环境固定 mock）
- R4.2 设备端测试 Configuration 依赖模拟器已连接
- R4.3 支持从 IDE 直接点击运行，无需命令行

### R5 — 脚本整理

- R5.1 `run.sh` 保持现有逻辑，buildMode 固定 `mock`
- R5.2 新增 `run-debug.sh`，buildMode 为 `debug`
- R5.3 `run-release.sh` 使用 `buildMode=release`，HAP 路径对应更新
- R5.4 新增 `test-core.sh`，运行 core 本地单元测试
- R5.5 新增 `test-entry.sh`，运行 entry 本地单元测试

---

## 约束

- 不修改 `project.cache.json`（由 IDE 管理）
- 不引入新的第三方依赖
- `core` 层不得 import `entry` 层任何内容
- `AppEnv` 枚举值必须与 `buildModeSet` 的 `name` 字段保持一致（均小写）
- 新增环境时，只需修改两处：`AppEnv.ets` + `build-profile.json5`
