import BuildProfile from 'BuildProfile';
import { AppEnv, appEnvFromString } from 'core';

/**
 * RuntimeConfig — 运行时环境配置
 *
 * 直接从 hvigor buildProfileFields.APP_ENV 读取并转换为 AppEnv 枚举。
 * 唯一允许读取 BuildProfile.APP_ENV 的地方，其他文件禁止直接访问。
 *
 * mock buildMode    → APP_ENV = 'mock'    → AppEnv.MOCK
 * debug buildMode   → APP_ENV = 'debug'   → AppEnv.DEBUG
 * release buildMode → APP_ENV = 'release' → AppEnv.RELEASE
 */
export const APP_ENV: AppEnv = appEnvFromString(String(BuildProfile.APP_ENV));
