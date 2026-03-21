import BuildProfile from 'BuildProfile';

/**
 * 运行时环境配置。
 * APP_RUNTIME_ENV 直接从 hvigor 自动生成的 BuildProfile 读取，
 * 不再依赖 source set 替换机制。
 *
 * mock target    → BuildProfile.IS_MOCK = 'true'  → APP_RUNTIME_ENV = 'Mock'
 * release target → BuildProfile.APP_ENV = 'release' → APP_RUNTIME_ENV = 'Release'
 * default target → APP_RUNTIME_ENV = 'Other'
 */
const isMockFlag: string = String(BuildProfile.IS_MOCK);
const appEnvFlag: string = String(BuildProfile.APP_ENV);

export const APP_RUNTIME_ENV: string =
  isMockFlag === 'true' ? 'Mock' :
  appEnvFlag === 'release' ? 'Release' : 'Other';

export const APP_RUNTIME_SOURCE: string = appEnvFlag;
