/**
 * 应用运行环境枚举。
 *
 * 枚举值与 build-profile.json5 的 buildModeSet.name 一一对应（均小写）。
 * 新增环境时：
 *   1. 在此枚举添加新值
 *   2. 在 appEnvFromString() 添加对应分支
 *   3. 在 build-profile.json5 的 buildModeSet 添加对应条目
 *   4. 无需修改其他任何文件
 */
export enum AppEnv {
  /** Mock 环境：使用本地 rawfile mock 数据，不发起真实网络请求 */
  MOCK = 'mock',
  /** Debug 环境：使用真实 API，可配合 Proxyman 抓包调试 */
  DEBUG = 'debug',
  /** Release 环境：生产环境，关闭调试日志 */
  RELEASE = 'release',
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
