# 构建环境与 Configuration 统一治理 — 任务列表

## Task 1：新增 AppEnv 枚举（core 层）

- [ ] 新建 `core/src/main/ets/constants/AppEnv.ets`，定义 `AppEnv` 枚举和 `appEnvFromString()` 函数
- [ ] 验证：`getDiagnostics(['core/src/main/ets/constants/AppEnv.ets'])`

## Task 2：新增 AppEnvManager（core 层）

- [ ] 新建 `core/src/main/ets/constants/AppEnvManager.ets`，定义 `AppEnvManager` 类
- [ ] 提供 `setup(env)`、`getEnv()`、`isMock()`、`isDebug()`、`isRelease()` 静态方法
- [ ] 验证：`getDiagnostics(['core/src/main/ets/constants/AppEnvManager.ets'])`

## Task 3：迁移 Logger 到 core 层

- [ ] 新建 `core/src/main/ets/utils/Logger.ets`
- [ ] 从 `entry/src/main/ets/utils/Logger.ets` 迁移全部日志逻辑
- [ ] 删除 `RuntimeEnv` 枚举定义
- [ ] 删除 `parseRuntimeEnv()`、`getRuntimeEnv()`、`isMockEnv()`、`isReleaseEnv()`、`getRuntimeEnvDetail()` 方法
- [ ] 删除 `APP_RUNTIME_SOURCE` import
- [ ] 日志中的环境标签改为 `AppEnvManager.getEnv()`
- [ ] `canOutput()` 改为 `AppEnvManager.isRelease()` 判断
- [ ] 保留：`info/warn/error/debug/trace/ctx` 方法签名完全不变，`LogContext` interface 不变
- [ ] 验证：`getDiagnostics(['core/src/main/ets/utils/Logger.ets'])`

## Task 4：更新 core/Index.ets 导出

- [ ] 新增导出：`AppEnv`、`appEnvFromString`、`AppEnvManager`、`Logger`、`LogContext`
- [ ] 验证：`getDiagnostics(['core/Index.ets'])`

## Task 5：更新 build-profile.json5

- [ ] 删除 `buildModeSet` 中所有 `IS_MOCK` 字段
- [ ] 确认三个 buildMode（`mock`/`debug`/`release`）各自只保留 `APP_ENV` 字段

## Task 6：更新 RuntimeConfig.ets

- [ ] 改为 `import { AppEnv, appEnvFromString } from 'core'`
- [ ] 输出 `export const APP_ENV: AppEnv = appEnvFromString(String(BuildProfile.APP_ENV))`
- [ ] 删除 `APP_RUNTIME_ENV`、`APP_RUNTIME_SOURCE` 旧导出
- [ ] 验证：`getDiagnostics(['entry/src/main/ets/config/RuntimeConfig.ets'])`

## Task 7：更新 CoreInitializer.ets

- [ ] 删除 `MihoyoEnvironment` import，改为 `AppEnv`
- [ ] `CoreConfig` 接口的 `env` 字段类型改为 `AppEnv`
- [ ] `initCore` 第一步调用 `AppEnvManager.setup(config.env)`
- [ ] 删除 `CoreInitializer.isMockEnv` 私有字段
- [ ] 删除 `getIsMock()` 方法
- [ ] 删除 `AuthRepository.isMock = isMock` 赋值行
- [ ] 验证：`getDiagnostics(['core/src/main/ets/CoreInitializer.ets'])`

## Task 8：更新 MihoyoApiServiceFactory.ets

- [ ] 参数类型从 `MihoyoEnvironment` 改为 `AppEnv`
- [ ] 内部 `isMock` 判断改为 `AppEnvManager.isMock()`
- [ ] 验证：`getDiagnostics(['core/src/main/ets/network/MihoyoApiServiceFactory.ets'])`

## Task 9：更新 AuthRepository.ets

- [ ] 删除 `static isMock: boolean` 字段
- [ ] 所有 `AuthRepository.isMock` 引用改为 `AppEnvManager.isMock()`
- [ ] 验证：`getDiagnostics(['core/src/main/ets/repository/AuthRepository.ets'])`

## Task 10：删除 MihoyoEnvironment.ets

- [ ] 确认所有引用已清除：`grepSearch('MihoyoEnvironment', includePattern='**/*.ets')`
- [ ] 删除 `core/src/main/ets/network/MihoyoEnvironment.ets`
- [ ] 从 `core/Index.ets` 中移除 `MihoyoEnvironment` 导出（如有）

## Task 11：更新 EntryAbility.ets

- [ ] 删除 `RuntimeEnv` import
- [ ] 删除 `MihoyoEnvironment` import
- [ ] 删除 `mihoyoEnv` 中间变量和转换逻辑
- [ ] 删除 `runStartupTaskByEnv()` 方法
- [ ] 改为 `import { CoreInitializer, Logger } from 'core'`
- [ ] 直接传 `APP_ENV`：`CoreInitializer.initCore({ env: APP_ENV, context: this.context })`
- [ ] 验证：`getDiagnostics(['entry/src/main/ets/entryability/EntryAbility.ets'])`

## Task 12：更新 entry 层所有 Logger 引用方

- [ ] `grepSearch("from '../utils/Logger'", includePattern='entry/**/*.ets')` 找出所有引用文件
- [ ] 批量将 `import { Logger } from '../utils/Logger'` 改为 `import { Logger } from 'core'`
- [ ] 将 `import { Logger, RuntimeEnv } from '../utils/Logger'` 中的 `RuntimeEnv` 引用改为 `AppEnvManager` 或 `AppEnv`
- [ ] 验证：对所有修改文件执行 `getDiagnostics`

## Task 13：删除 entry 层旧 Logger.ets

- [ ] 确认所有引用已清除：`grepSearch("utils/Logger", includePattern='entry/**/*.ets')`
- [ ] 删除 `entry/src/main/ets/utils/Logger.ets`

## Task 14：整理 IDE Run Configuration

- [ ] 删除 `.idea/runConfigurations/Build_Mock_Entry.xml`
- [ ] 删除 `.idea/runConfigurations/Build_Release_Entry.xml`
- [ ] 新建 `.idea/runConfigurations/Run_Mock.xml`（buildMode=mock，DevEco Run 类型）
- [ ] 新建 `.idea/runConfigurations/Run_Debug.xml`（buildMode=debug，DevEco Run 类型）
- [ ] 新建 `.idea/runConfigurations/Build_Release.xml`（buildMode=release，Hvigor Build 类型）

## Task 15：新增测试 Configuration

- [ ] 新建 `.idea/runConfigurations/Test_Core_Unit.xml`
- [ ] 新建 `.idea/runConfigurations/Test_Entry_Unit.xml`
- [ ] 新建 `.idea/runConfigurations/Test_Entry_Snapshot.xml`

## Task 16：整理构建脚本

- [ ] `run.sh`：确认使用 `-p buildMode=mock`（现有，无需改动）
- [ ] 新建 `run-debug.sh`：buildMode=debug
- [ ] 更新 `run-release.sh`：改为 `-p buildMode=release`
- [ ] 新建 `test-core.sh`：运行 core ohosTest
- [ ] 新建 `test-entry.sh`：运行 entry ohosTest

## Task 17：全量验证

- [ ] `bash run.sh` 构建成功（mock 环境）
- [ ] 检查 log 中 `env=mock` 正确输出
- [ ] `grepSearch('MihoyoEnvironment', includePattern='**/*.ets')` 返回空
- [ ] `grepSearch('RuntimeEnv', includePattern='**/*.ets')` 返回空
- [ ] `grepSearch('IS_MOCK', includePattern='**/*.ets')` 返回空
- [ ] `grepSearch('APP_RUNTIME_ENV', includePattern='**/*.ets')` 返回空
- [ ] `grepSearch("utils/Logger", includePattern='entry/**/*.ets')` 返回空
