/**
 * 应用运行环境枚举。
 *
 * 枚举值与 BuildProfile.APP_ENV 对应（均小写）。
 * MOCK 仅保留枚举值与解析分支；独立 mock/ 源码目录已删除，
 * 当前没有任何逻辑分支使用 AppEnv.MOCK。
 *
 * 新增环境时：
 *   1. 在此枚举添加新值
 *   2. 在 appEnvFromString() 添加对应分支
 *   3. 在 build-profile.json5 的产品 buildProfileFields.APP_ENV 添加对应值
 */
export enum AppEnv {
  /** Mock 环境：仅保留枚举值，当前无逻辑使用；由 mock product 构建 .mock 包 */
  MOCK = 'mock',
  /** Debug 环境：使用真实 API，可配合 Proxyman 抓包调试 */
  DEBUG = 'debug',
  /** Release 环境：生产环境，关闭调试日志 */
  RELEASE = 'release',
}

/**
 * 从 BuildProfile.APP_ENV 字符串转换为 AppEnv 枚举。
 * 未知值 fallback 到 DEBUG（安全默认值：不关闭日志）。
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
