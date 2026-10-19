import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import deviceInfo from '@ohos.deviceInfo';
import { DeviceFpService, GameFpBiz } from './DeviceFpService';
import { FingerprintReporter, FingerprintInvalidListener } from './FingerprintReporter';
import { ZZZRecordRequest } from './ZZZRecordRequest';

const PREFS_NAME: string = 'mihoyo_device_config';
const KEY_DEVICE_ID: string = 'device_id';

export class ApiConfig {
  static readonly APP_VERSION: string = '2.115.0';
  /** 米游社 BBS App ID，用于登录接口的 x-rpc-app_id 请求头 */
  static readonly BBS_APP_ID: string = 'bll8iq97cem8';
  /**
   * User-Agent：iPhone iOS 16.3.1（与 GenshinPizzaHelper/HSRPizzaHelper 一致）
   * 注意：ext_fields 里的设备信息也是 iPhone，保持一致
   */
  static readonly USER_AGENT: string =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 16_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/2.104.0';
  /**
   * 版本号与 APP_VERSION 一致的 User-Agent（实时便笺接口使用）。
   * 真实抓包中 User-Agent 的 miHoYoBBS 版本与 x-rpc-app_version 一致；USER_AGENT 的 2.104.0 与 APP_VERSION 不一致。
   */
  static readonly USER_AGENT_MATCH_APP_VERSION: string =
    `Mozilla/5.0 (iPhone; CPU iPhone OS 16_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/${ApiConfig.APP_VERSION}`;
  /**
   * Widget 扩展 User-Agent（参考 HSRPizzaHelper widgetNote 实现）
   * Widget API 使用此 UA 可绕过 1034 Geetest 验证
   */
  static readonly WIDGET_USER_AGENT: string =
    'WidgetExtension/550 CFNetwork/1335.0.3 Darwin/21.6.0';
  /**
   * 安卓 App User-Agent（手机号登录接口使用）
   */
  static readonly ANDROID_USER_AGENT: string =
    `Mozilla/5.0 (Linux; Android 12) Mobile miHoYoBBS/${ApiConfig.APP_VERSION}`;
  /** x-rpc-sys_version：与 User-Agent 里的 iOS 版本一致 */
  static readonly SYS_VERSION: string = '16.3.1';

  /** 设备型号，如 "NOH-AN00"（Mate 40 Pro）、"ALN-AL00"（Mate 60 Pro） */
  static get DEVICE_MODEL(): string {
    return deviceInfo.productModel || 'HarmonyOS';
  }

  /** 设备名称（品牌 + 型号），如 "HUAWEI NOH-AN00" */
  static get DEVICE_NAME(): string {
    const brand = deviceInfo.brand || 'HUAWEI';
    const model = deviceInfo.productModel || 'HarmonyOS';
    return `${brand} ${model}`;
  }
  /**
   * x-rpc-tool_verison：原神游戏记录接口专用
   * 注意：请求头名称是 "verison"（米游社服务端拼写错误），常量名用正确拼写便于阅读
   */
  static readonly TOOL_VERSION_GENSHIN: string = 'v6.4.2-gr-cn';
  /** x-rpc-tool_verison：星穹铁道游戏记录接口专用 */
  static readonly TOOL_VERSION_STARRAIL: string = 'v4.1.1';

  // ── x-rpc-page 页面标识（各接口必须携带）────────────────────────────
  /** 原神便笺页 */
  static readonly PAGE_GENSHIN_NOTE: string = 'v6.4.2-gr-cn_#/ys';
  /** 原神角色列表页 */
  static readonly PAGE_GENSHIN_ROLES: string = 'v6.4.2-gr-cn_#/ys/role/all';
  /** 原神角色详情页前缀（需要拼接 avatarId） */
  static readonly PAGE_GENSHIN_ROLE_DETAIL_PREFIX: string = 'v6.4.2-gr-cn_#/ys/role/detail/';
  /** 星铁便笺页 */
  static readonly PAGE_STARRAIL_NOTE: string = 'v4.1.1_#/rpg';
  /** 星铁角色列表页 */
  static readonly PAGE_STARRAIL_ROLES: string = 'v4.1.1_#/rpg/roles';
  /** 星铁角色详情页 */
  static readonly PAGE_STARRAIL_ROLE: string = 'v4.1.1_#/rpg/role';
  /** 绝区零便笺页 */
  static readonly PAGE_ZZZ_NOTE: string = 'v2.7.1_#/zzz/daily-note';
  /** 绝区零代理人列表页 */
  static readonly PAGE_ZZZ_ROLES: string = 'v2.7.1_#/zzz';
  /** 绝区零代理人详情页前缀（需要拼接 avatarId） */
  static readonly PAGE_ZZZ_ROLE_DETAIL_PREFIX: string = 'v2.7.1_#/zzz/roles/';
  /** 绝区零邦布列表页 */
  static readonly PAGE_ZZZ_BANGBOO: string = 'v2.7.1_#/zzz/bangboo/all';

  private static cachedDeviceId: string = '';

  /**
   * 预加载 device_id（从 Preferences 读取，不存在则生成 UUID 并持久化）
   * 必须在 aboutToAppear 或 initCore 中调用，不能在回调中调用
   */
  static async preloadDeviceId(context: common.UIAbilityContext): Promise<void> {
    try {
      const prefs = await preferences.getPreferences(context, PREFS_NAME);
      const stored = await prefs.get(KEY_DEVICE_ID, '');
      if (typeof stored === 'string' && stored.length > 0) {
        if (stored === stored.toUpperCase()) {
          ApiConfig.cachedDeviceId = stored;
          return;
        }
        // 旧版本存的是小写 UUID：统一成与 iOS 米游社一致的大写格式，
        // 并清掉用旧 ID 申请的设备指纹缓存（通用 / 各游戏 / 绝区零各账号），之后用新 ID 重新申请
        const upper = stored.toUpperCase();
        ApiConfig.cachedDeviceId = upper;
        await prefs.put(KEY_DEVICE_ID, upper);
        const all = await prefs.getAll() as Record<string, Object>;
        const keys = Object.keys(all);
        for (let i = 0; i < keys.length; i++) {
          if (keys[i].startsWith('device_fp') || keys[i].startsWith('zzz_device_fp_')) {
            await prefs.delete(keys[i]);
          }
        }
        await prefs.flush();
        return;
      }
      // 生成新 UUID 并持久化（大写，与 iOS 米游社 x-rpc-device_id 格式一致）
      const newId = util.generateRandomUUID(false).toUpperCase();
      ApiConfig.cachedDeviceId = newId;
      await prefs.put(KEY_DEVICE_ID, newId);
      await prefs.flush();
    } catch (e) {
      // 失败时使用随机 UUID（不持久化）
      ApiConfig.cachedDeviceId = util.generateRandomUUID(false).toUpperCase();
    }
  }

  static getDeviceIdSync(): string {
    return ApiConfig.cachedDeviceId;
  }

  /**
   * 预加载 device_fp：
   * 1. 从 Preferences 读取缓存
   * 2. 无缓存则调用 getFp 接口获取真实指纹（需要 deviceId 已预加载）
   * 3. 获取失败则回退到基于 deviceId MD5 的初始指纹
   */
  static async preloadDeviceFp(context: common.UIAbilityContext): Promise<void> {
    await DeviceFpService.init(context, ApiConfig.cachedDeviceId);
    // 按游戏的指纹（PizzaHelperUnited 方式，便笺 / Widget 使用）
    await DeviceFpService.initGameFps(context, ApiConfig.cachedDeviceId);
  }

  static getDeviceFp(): string {
    return DeviceFpService.getFp();
  }

  /** 指定游戏的指纹（PizzaHelperUnited 方式） */
  static getGameFp(biz: GameFpBiz): string {
    return DeviceFpService.getGameFp(biz);
  }

  /** 重新生成设备指纹（通用 + 各游戏，PizzaHelperUnited 方式：device_id 不变），失败时抛出 */
  static async regenerateDeviceFp(context: common.UIAbilityContext): Promise<void> {
    await DeviceFpService.regenerateAll(context, ApiConfig.cachedDeviceId);
    // 绝区零：清空各账号的指纹，下次请求重新申请并登记设备（ZZZ-Plugin 方式）
    await ZZZRecordRequest.clearAll();
  }

  /** 注册设备指纹无效 / 账号异常（5003 / 10041）统一处理：任何接口返回时回调 */
  static setFingerprintInvalidListener(listener: FingerprintInvalidListener | null): void {
    FingerprintReporter.setListener(listener);
  }
}
