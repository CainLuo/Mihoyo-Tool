import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { util } from '@kit.ArkTS';

const PREFS_NAME: string = 'mihoyo_device_config';
const KEY_DEVICE_ID: string = 'device_id';
const KEY_DEVICE_FP: string = 'device_fp';

export class ApiConfig {
  static readonly APP_VERSION: string = '2.102.0';
  static readonly USER_AGENT: string =
    'Mozilla/5.0 (iPad; CPU OS 15_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.102.0 WebCacheKit2';
  /**
   * x-rpc-tool_verison：原神游戏记录接口专用
   * 注意：请求头名称是 "verison"（米游社服务端拼写错误），常量名用正确拼写便于阅读
   */
  static readonly TOOL_VERSION_GENSHIN: string = 'v6.4.2-gr-cn';
  /** x-rpc-tool_verison：星穹铁道游戏记录接口专用 */
  static readonly TOOL_VERSION_STARRAIL: string = 'v4.1.1';

  private static cachedDeviceId: string = '';
  private static cachedDeviceFp: string = '';

  /**
   * 预加载 device_id（从 Preferences 读取，不存在则生成 UUID 并持久化）
   * 必须在 aboutToAppear 或 initCore 中调用，不能在回调中调用
   */
  static async preloadDeviceId(context: common.UIAbilityContext): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, PREFS_NAME);
      const stored = await prefs.get(KEY_DEVICE_ID, '');
      if (typeof stored === 'string' && stored.length > 0) {
        ApiConfig.cachedDeviceId = stored;
        return;
      }
      // 生成新 UUID 并持久化
      const newId = util.generateRandomUUID(false);
      ApiConfig.cachedDeviceId = newId;
      await prefs.put(KEY_DEVICE_ID, newId);
      await prefs.flush();
    } catch (e) {
      // 失败时使用随机 UUID（不持久化）
      ApiConfig.cachedDeviceId = util.generateRandomUUID(false);
    }
  }

  static getDeviceIdSync(): string {
    return ApiConfig.cachedDeviceId;
  }

  /**
   * 预加载 device_fp（从 Preferences 读取，不存在则随机生成 38d8xxxxxxxx 格式并持久化）
   */
  static async preloadDeviceFp(context: common.UIAbilityContext): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, PREFS_NAME);
      const stored = await prefs.get(KEY_DEVICE_FP, '');
      if (typeof stored === 'string' && stored.length > 0) {
        ApiConfig.cachedDeviceFp = stored;
        return;
      }
      const newFp = ApiConfig.generateDeviceFp();
      ApiConfig.cachedDeviceFp = newFp;
      await prefs.put(KEY_DEVICE_FP, newFp);
      await prefs.flush();
    } catch (e) {
      ApiConfig.cachedDeviceFp = ApiConfig.generateDeviceFp();
    }
  }

  static getDeviceFp(): string {
    return ApiConfig.cachedDeviceFp;
  }

  /** 生成 device_fp，格式：38d8 + 8 位随机十六进制 */
  private static generateDeviceFp(): string {
    const chars = '0123456789abcdef';
    let suffix = '';
    for (let i = 0; i < 8; i++) {
      suffix += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return '38d8' + suffix;
  }
}
