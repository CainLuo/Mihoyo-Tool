/**
 * 应用运行环境枚举。
 *
 * 枚举值与 BuildProfile.APP_ENV 对应（均小写）。
 * 只有三个环境：mock / uat / release。
 *
 * 新增环境时：
 *   1. 在此枚举添加新值
 *   2. 在 appEnvFromString() 添加对应分支
 *   3. 在 build-profile.json5 的产品 buildProfileFields.APP_ENV 添加对应值
 */
export enum AppEnv {
  /** Mock 环境：使用本机 local-service 域名 */
  MOCK = 'mock',
  /** UAT 环境：使用官方 API 域名，保留 Debug 日志 / TestPage / 抓包能力 */
  UAT = 'uat',
  /** Release 环境：生产环境，关闭调试日志 */
  RELEASE = 'release',
}

/**
 * 从 BuildProfile.APP_ENV 字符串转换为 AppEnv 枚举。
 * 未知值 fallback 到 UAT（使用官方域名，不路由到 local-service）。
 */
export function appEnvFromString(s: string): AppEnv {
  const lower: string = s.toLowerCase();
  if (lower === AppEnv.MOCK) {
    return AppEnv.MOCK;
  }
  if (lower === AppEnv.RELEASE) {
    return AppEnv.RELEASE;
  }
  return AppEnv.UAT;
}
