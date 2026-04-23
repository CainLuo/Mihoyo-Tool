import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import crypto from '@ohos/crypto-js';
import { HttpClient } from './HttpClient';
import { MihoyoDomain } from './MihoyoDomain';
import { RequestOptions } from './APIs';
import { HKey, HVal } from './MihoyoHeaderKey';

const PREFS_NAME: string = 'mihoyo_device_config';
const KEY_DEVICE_FP: string = 'device_fp';

/** device-fp API 外层响应（米游社标准格式） */
interface FpApiOuterResponse {
  retcode: number;
  message: string;
  data: FpApiData;
}

/** device-fp API data 字段 */
interface FpApiData {
  device_fp: string;
  code: number;
  msg: string;
}

/** device-fp API 请求体 */
class FpRequestBody {
  seed_id: string = '';
  device_id: string = '';
  platform: string = '';
  seed_time: string = '';
  ext_fields: string = '';
  app_name: string = '';
  device_fp: string = '';
}

/**
 * DeviceFpService — 获取并缓存真实的 x-rpc-device_fp
 *
 * 接口：POST https://public-data-api.mihoyo.com/device-fp/api/getFp
 * 参考实现：HSRPizzaHelper / GenshinPizzaHelper（Swift）
 *
 * 流程：
 * 1. 首次启动：调用 getFp 接口获取真实指纹，持久化到 Preferences
 * 2. 后续启动：从 Preferences 读取缓存，直接使用
 * 3. 获取失败：回退到基于 deviceId MD5 的初始指纹（13位）
 */
export class DeviceFpService {
  private static cachedFp: string = '';

  /** 获取当前缓存的 device_fp */
  static getFp(): string {
    return DeviceFpService.cachedFp;
  }

  /**
   * 初始化 device_fp：
   * - 有缓存且不是初始指纹（MD5前13位）则直接用
   * - 否则调用接口获取真实指纹
   */
  static async init(context: common.UIAbilityContext, deviceId: string): Promise<void> {
    const initialFp = DeviceFpService.generateInitialFp(deviceId);
    try {
      const prefs = await preferences.getPreferences(context, PREFS_NAME);
      const stored = await prefs.get(KEY_DEVICE_FP, '');
      // 只有缓存存在且不是初始指纹时才直接用
      if (typeof stored === 'string' && stored.length >= 13 && stored !== initialFp) {
        DeviceFpService.cachedFp = stored;
        return;
      }
    } catch (_) {}

    // 无有效缓存，调用接口获取真实指纹
    await DeviceFpService.fetchAndCache(context, deviceId);
  }

  /**
   * 强制刷新 device_fp（登录时调用，确保指纹有效）
   */
  static async refresh(context: common.UIAbilityContext, deviceId: string): Promise<void> {
    await DeviceFpService.fetchAndCache(context, deviceId);
  }

  private static async fetchAndCache(context: common.UIAbilityContext, deviceId: string): Promise<void> {
    try {
      const fp = await DeviceFpService.fetchFromApi(deviceId);
      DeviceFpService.cachedFp = fp;
      // 持久化
      const prefs = await preferences.getPreferences(context, PREFS_NAME);
      await prefs.put(KEY_DEVICE_FP, fp);
      await prefs.flush();
    } catch (_) {
      // 获取失败，回退到初始指纹（deviceId MD5 前 13 位）
      DeviceFpService.cachedFp = DeviceFpService.generateInitialFp(deviceId);
    }
  }

  /**
   * 调用 getFp 接口获取真实 device_fp
   *
   * 请求体参考 HSRPizzaHelper：
   * - seed_id: 16位随机十六进制
   * - device_id: 设备 UUID
   * - platform: "1"（国服 iOS）
   * - seed_time: 毫秒时间戳字符串
   * - ext_fields: 固定的 iPhone 设备信息 JSON
   * - app_name: "account_cn"
   * - device_fp: deviceId MD5 前 13 位（初始指纹）
   */
  private static async fetchFromApi(deviceId: string): Promise<string> {
    const seedId = DeviceFpService.generateSeed(16);
    const seedTime = Date.now().toString();
    const initialFp = DeviceFpService.generateInitialFp(deviceId);

    const body = new FpRequestBody();
    body.seed_id = seedId;
    body.device_id = deviceId;
    body.platform = '1';
    body.seed_time = seedTime;
    body.ext_fields = DeviceFpService.buildExtFields(deviceId);
    body.app_name = 'account_cn';
    body.device_fp = initialFp;

    const opts = new RequestOptions();
    opts.extraHeaders = new Map<string, string>();
    opts.extraHeaders.set(HKey.CONTENT_TYPE, HVal.JSON);

    const resp = await HttpClient.post(
      MihoyoDomain.PUBLIC_DATA_API + '/device-fp/api/getFp',
      JSON.stringify(body),
      opts,
    ) as FpApiOuterResponse;

    if (resp.retcode !== 0 || !resp.data || !resp.data.device_fp || resp.data.device_fp.length < 13) {
      throw new Error(`getFp failed: retcode=${resp.retcode}, msg=${resp.message}`);
    }
    return resp.data.device_fp;
  }

  /**
   * 生成初始指纹：deviceId 的 MD5 取前 13 位
   * 与 HSRPizzaHelper 的 `deviceId.md5.prefix(13)` 一致
   */
  private static generateInitialFp(deviceId: string): string {
    const md5 = crypto.MD5(deviceId).toString();
    return md5.substring(0, 13);
  }

  /**
   * 生成 n 位随机十六进制字符串（seed_id 用）
   */
  private static generateSeed(n: number): string {
    const chars = '0123456789abcdef';
    let result = '';
    for (let i = 0; i < n; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  /**
   * 构建 ext_fields：固定的 iPhone 设备信息 JSON 字符串
   * 其中 IDFV 字段填入 deviceId 大写（与 HSRPizzaHelper 一致）
   */
  private static buildExtFields(deviceId: string): string {
    const idfv = deviceId.toUpperCase();
    return `{"ramCapacity":"3746","hasVpn":"0","proxyStatus":"0","screenBrightness":"0.550","packageName":"com.miHoYo.mhybbs","romRemain":"100513","deviceName":"iPhone","isJailBreak":"0","magnetometer":"-160.495300x-206.488358x58.534348","buildTime":"1706406805675","ramRemain":"97","accelerometer":"-0.419876x-0.748367x-0.508057","cpuCores":"6","cpuType":"CPU_TYPE_ARM64","packageVersion":"2.104.0","gyroscope":"0.133974x-0.051780x-0.062961","batteryStatus":"45","appUpdateTimeDiff":"1707130080397","appMemory":"57","screenSize":"414\u00d7896","vendor":"--","model":"iPhone12,5","IDFV":"${idfv}","romCapacity":"488153","isPushEnabled":"1","appInstallTimeDiff":"1696756955347","osVersion":"16.3.1","chargeStatus":"1","isSimInserted":"1","networkType":"WIFI"}`;
  }
}
