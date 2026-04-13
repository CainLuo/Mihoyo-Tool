import BuildProfile from 'BuildProfile';
import { AppEnv, appEnvFromString } from 'core';

/**
 * 当前运行环境。
 * 直接从 hvigor buildProfileFields.APP_ENV 读取并转换为 AppEnv 枚举。
 *
 * mock buildMode    → APP_ENV = 'mock'    → AppEnv.MOCK
 * debug buildMode   → APP_ENV = 'debug'   → AppEnv.DEBUG
 * release buildMode → APP_ENV = 'release' → AppEnv.RELEASE
 */
export const APP_ENV: AppEnv = appEnvFromString(String(BuildProfile.APP_ENV));
