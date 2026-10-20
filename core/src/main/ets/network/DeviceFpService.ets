import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import crypto from '@ohos/crypto-js';
import { HttpClient } from './HttpClient';
import { MihoyoDomain } from './MihoyoDomain';
import { RequestOptions } from './APIs';
import { HKey, HVal } from './MihoyoHeaderKey';
import { Logger } from '../utils/Logger';

const PREFS_NAME: string = 'mihoyo_device_config';
const KEY_DEVICE_FP: string = 'device_fp';
/**
 * 通用指纹的来源版本：曾短暂改为 bbs_cn / Android 申请，已恢复为原来的 account_cn / iOS；
 * 版本不一致的缓存（包括 bbs_cn 指纹）会被丢弃并重新申请。
 */
const KEY_DEVICE_FP_SOURCE: string = 'device_fp_source';
const DEVICE_FP_SOURCE: string = 'account_cn_ios_v1';

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
/** 按游戏申请的指纹（PizzaHelperUnited 每个游戏账号单独申请）：app_name 与缓存 key */
export enum GameFpBiz {
  GENSHIN = 'hk4e_cn',
  STARRAIL = 'hkrpg_cn',
  ZZZ = 'nap_cn',
}
const KEY_GAME_FP_PREFIX: string = 'device_fp_game_';
const ALL_GAME_FP_BIZ: GameFpBiz[] = [GameFpBiz.GENSHIN, GameFpBiz.STARRAIL, GameFpBiz.ZZZ];

export class DeviceFpService {
  private static cachedFp: string = '';
  private static gameFps: Map<string, string> = new Map<string, string>();

  /** 获取当前缓存的 device_fp */
  static getFp(): string {
    return DeviceFpService.cachedFp;
  }

  /** 指定游戏的指纹（PizzaHelperUnited 方式）；尚未申请到时退回通用指纹 */
  static getGameFp(biz: GameFpBiz): string {
    const fp = DeviceFpService.gameFps.get(biz);
    return fp !== undefined && fp.length > 0 ? fp : DeviceFpService.cachedFp;
  }

  /**
   * 初始化各游戏指纹：有缓存直接用，否则按 PizzaHelperUnited getDeviceFingerPrint 申请
   * （app_name = hk4e_cn / hkrpg_cn / nap_cn，platform = 1，iOS 设备信息）。失败不缓存，下次启动重试。
   */
  static async initGameFps(context: common.UIAbilityContext, deviceId: string): Promise<void> {
    let prefs: preferences.Preferences | null = null;
    try {
      prefs = await preferences.getPreferences(context, PREFS_NAME);
    } catch (_) {}
    for (let i = 0; i < ALL_GAME_FP_BIZ.length; i++) {
      const biz = ALL_GAME_FP_BIZ[i];
      const key = KEY_GAME_FP_PREFIX + biz;
      try {
        const stored = prefs !== null ? await prefs.get(key, '') : '';
        if (typeof stored === 'string' && stored.length >= 13) {
          DeviceFpService.gameFps.set(biz, stored);
          continue;
        }
        const fp = await DeviceFpService.fetchGameFpFromApi(deviceId, biz);
        DeviceFpService.gameFps.set(biz, fp);
        if (prefs !== null) {
          await prefs.put(key, fp);
          await prefs.flush();
        }
      } catch (e) {
        Logger.error('DeviceFpService', `[DeviceFp] ${biz} getFp failed: ${(e as Error).message}`);
      }
    }
  }

  /**
   * 按 PizzaHelperUnited HoYo.getDeviceFingerPrint（miyoushe 区域）申请游戏指纹：
   * body.device_id = md5(deviceId)，platform = "1"，app_name = 游戏 biz，ext_fields 为 iPhone 设备信息；不带额外请求头
   */
  private static async fetchGameFpFromApi(deviceId: string, biz: GameFpBiz): Promise<string> {
    const bodyDeviceId = crypto.MD5(deviceId).toString();
    const body = new FpRequestBody();
    body.seed_id = DeviceFpService.generateSeed(16);
    body.device_id = bodyDeviceId;
    body.platform = '1';
    body.seed_time = `${Math.floor(Date.now() / 1000)}000`;
    body.ext_fields = DeviceFpService.buildIosExtFields(bodyDeviceId);
    body.app_name = biz;
    body.device_fp = crypto.MD5(bodyDeviceId).toString().substring(0, 13);

    const opts = new RequestOptions();
    opts.extraHeaders = new Map<string, string>();
    opts.extraHeaders.set(HKey.CONTENT_TYPE, HVal.JSON);
    const resp = await HttpClient.post(
      MihoyoDomain.PUBLIC_DATA_API + '/device-fp/api/getFp',
      JSON.stringify(body),
      opts,
    ) as FpApiOuterResponse;
    if (resp.retcode !== 0 || !resp.data || !resp.data.device_fp || resp.data.device_fp.length < 13) {
      throw new Error(`getFp(${biz}) failed: retcode=${resp.retcode}, msg=${resp.message}, code=${resp.data?.code}, data.msg=${resp.data?.msg}`);
    }
    return resp.data.device_fp;
  }

  /** PizzaHelperUnited getFpExtFields(miyoushe)：iPhone 设备信息，IDFV 为 device_id 大写 */
  private static buildIosExtFields(deviceId: string): string {
    const idfv = deviceId.toUpperCase();
    return `{"ramCapacity":"3746","hasVpn":"0","proxyStatus":"0","screenBrightness":"0.550","packageName":"com.miHoYo.mhybbs","romRemain":"100513","deviceName":"iPhone","isJailBreak":"0","magnetometer":"-160.495300x-206.488358x58.534348","buildTime":"1706406805675","ramRemain":"97","accelerometer":"-0.419876x-0.748367x-0.508057","cpuCores":"6","cpuType":"CPU_TYPE_ARM64","packageVersion":"2.20.1","gyroscope":"0.133974x-0.051780x-0.062961","batteryStatus":"45","appUpdateTimeDiff":"1707130080397","appMemory":"57","screenSize":"414\u00d7896","vendor":"--","model":"iPhone12,5","IDFV":"${idfv}","romCapacity":"488153","isPushEnabled":"1","appInstallTimeDiff":"1696756955347","osVersion":"17.2.1","chargeStatus":"1","isSimInserted":"1","networkType":"WIFI"}`;
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
      const source = await prefs.get(KEY_DEVICE_FP_SOURCE, '');
      // 只有缓存存在、不是初始指纹、且来源版本一致时才直接用
      if (typeof stored === 'string' && stored.length >= 13 && stored !== initialFp && source === DEVICE_FP_SOURCE) {
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

  /**
   * 重新生成全部指纹（通用 + 各游戏，并清空绝区零各账号的指纹），用于 5003 / 10041（设备指纹无效 / 账号异常）。
   * 与 PizzaHelperUnited「重新生成设备指纹」一致：申请时的 device_id 混入当前时间，确保拿到新指纹；
   * 请求头 x-rpc-device_id 不变。任一申请失败时抛出，已成功的部分保留。
   * @throws { Error } 任一指纹申请或写入失败时
   */
  static async regenerateAll(context: common.UIAbilityContext, deviceId: string): Promise<void> {
    const seedDeviceId = crypto.MD5(`${deviceId}|${Date.now()}`).toString();
    const prefs = await preferences.getPreferences(context, PREFS_NAME);
    const fp = await DeviceFpService.fetchFromApi(seedDeviceId);
    DeviceFpService.cachedFp = fp;
    await prefs.put(KEY_DEVICE_FP, fp);
    await prefs.put(KEY_DEVICE_FP_SOURCE, DEVICE_FP_SOURCE);
    for (let i = 0; i < ALL_GAME_FP_BIZ.length; i++) {
      const biz = ALL_GAME_FP_BIZ[i];
      const gameFp = await DeviceFpService.fetchGameFpFromApi(seedDeviceId, biz);
      DeviceFpService.gameFps.set(biz, gameFp);
      await prefs.put(KEY_GAME_FP_PREFIX + biz, gameFp);
    }
    await prefs.flush();
  }

  private static async fetchAndCache(context: common.UIAbilityContext, deviceId: string): Promise<void> {
    try {
      const fp = await DeviceFpService.fetchFromApi(deviceId);
      DeviceFpService.cachedFp = fp;
      // 持久化
      const prefs = await preferences.getPreferences(context, PREFS_NAME);
      await prefs.put(KEY_DEVICE_FP, fp);
      await prefs.put(KEY_DEVICE_FP_SOURCE, DEVICE_FP_SOURCE);
      await prefs.flush();
    } catch (e) {
      // 获取失败，回退到初始指纹（deviceId MD5 前 13 位），不写缓存，下次启动重试
      DeviceFpService.cachedFp = DeviceFpService.generateInitialFp(deviceId);
      Logger.error('DeviceFpService', `[DeviceFp] getFp failed, fallback to initial fp=${DeviceFpService.cachedFp}: ${(e as Error).message}`);
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
