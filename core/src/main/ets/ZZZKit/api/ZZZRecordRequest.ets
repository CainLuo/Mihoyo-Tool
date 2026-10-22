/**
 * ZZZRecordRequest — 绝区零战绩接口（event/game_record_zzz）请求
 *
 * 完整照 ZZZure/ZZZ-Plugin 实现（https://github.com/ZZZure/ZZZ-Plugin）：
 * - 请求头：dist/lib/mysapi.js getHeaders / getUrl（国服 cn 分支）
 *     Android WebView UA（miHoYoBBS/2.73.1）、x-rpc-app_version=2.73.1、x-rpc-client_type=2、x-rpc-sys_version=12、
 *     x-rpc-channel=mihoyo、Referer / Origin = act.mihoyo.com、DS（X4，q 为接口自带 query 原文）、Cookie、
 *     x-rpc-device_id、x-rpc-device_fp、x-rpc-device_name / x-rpc-device_model / x-rpc-csm_source=myself
 * - 设备：dist/lib/mysapi/tool.js getFp / deviceLogin / saveDevice，dist/lib/plugin.js getAPI
 *     每个米游社账号申请一份指纹（app_name=bbs_cn、platform=2、Android 设备信息），缓存 7 天；
 *     申请后调用 deviceLogin + saveDevice 把设备登记到米游社账号
 * - 默认设备信息：defSet/device.yaml（Sony XQ-BC52）
 * - 人机验证：照 AxiuCN/Axiu-Plugin（model/loveMys.js geetest / getvali、model/mys/apiTool.js、model/mys/mysApi.js getHeaders）
 *     10035 → api-takumi event/toolcomsrv/risk/createGeetest + verifyGeetest（app_key=game_record_zzz）
 *     1034  → api-takumi-record game_record/app/card/wapi/createVerification + verifyVerification
 *     均带 x-rpc-challenge_game=8 与该账号的 x-rpc-device_fp，验证通过后带 x-rpc-challenge 重放原请求
 */
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import { RequestOptions } from '../../base/network/APIs';
import { BaseApiService } from '../../base/network/BaseApiService';
import { DSUtil } from '../../base/network/DSUtil';
import { MihoyoDomain } from '../../base/network/MihoyoDomain';
import { GeetestRecordHandler } from '../../base/network/GeetestService';
import { GeetestCreateResult, GeetestVerifyInput } from '../../base/errors/ApiErrors';


const PREFS_NAME: string = 'mihoyo_device_config';
const KEY_ZZZ_FP_PREFIX: string = 'zzz_device_fp_';
/** Axiu-Plugin loveMys.js：绝区零 app_key */
const GEETEST_APP_KEY: string = 'game_record_zzz';
/** 指纹缓存 7 天（plugin.js：redis EX 86400 * 7） */
const FP_CACHE_MS: number = 7 * 24 * 3600 * 1000;

const APP_VERSION: string = '2.73.1';
// defSet/device.yaml 默认设备
const PRODUCT_NAME: string = 'XQ-BC52_EEA';
const PRODUCT_TYPE: string = 'XQ-BC52';
const MODEL_NAME: string = 'XQ-BC52';
const OS_VERSION: string = '13';
const DEVICE_INFO: string = 'Sony/XQ-BC52_EEA/XQ-BC52:13/61.2.A.0.472A/061002A0000472A0046651803:user/release-keys';
const BOARD: string = 'lahaina';
const DEVICE_BRAND: string = DEVICE_INFO.split('/')[0];
const DEVICE_DISPLAY: string = DEVICE_INFO.split('/')[3];
const USER_AGENT: string = `Mozilla/5.0 (Linux; Android ${OS_VERSION}; ${MODEL_NAME} Build/${DEVICE_DISPLAY}; wv) ` +
  `AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/111.0.5563.116 Mobile Safari/537.36 miHoYoBBS/${APP_VERSION}`;

/** getFp 请求体（tool.js getFp，字段顺序一致） */
class FpBody {
  app_name: string = 'bbs_cn';
  bbs_device_id: string = '';
  device_fp: string = '38d805c20d53d';
  device_id: string = '';
  ext_fields: string = '';
  platform: string = '2';
  seed_id: string = '';
  seed_time: string = '';
}

/** deviceLogin / saveDevice 请求体（tool.js，字段顺序一致） */
class DeviceLoginBody {
  app_version: string = APP_VERSION;
  device_id: string = '';
  device_name: string = `${DEVICE_BRAND}${MODEL_NAME}`;
  os_version: string = '33';
  platform: string = 'Android';
  registration_id: string = '';
}

export class ZZZRecordRequest {
  private static context: common.UIAbilityContext | null = null;
  /** x-rpc-device_id（与 ApiConfig 的设备 ID 一致，启动时传入，避免与 ApiConfig 循环引用） */
  private static deviceId: string = '';
  /** 账号 → 指纹（内存缓存） */
  private static fps: Map<string, string> = new Map<string, string>();
  /** 账号 → 申请中的 Promise，避免并发请求重复申请 */
  private static pending: Map<string, Promise<string>> = new Map<string, Promise<string>>();
  /** 「账号|接口路径」→ 验证通过后得到的 challenge，下一次请求该接口时作为 x-rpc-challenge 带上（loveMys.js getvali） */
  private static challenges: Map<string, string> = new Map<string, string>();

  /** App 启动时由 CoreInitializer 调用（设备 ID 预加载之后），用于读写指纹缓存 */
  static init(context: common.UIAbilityContext, deviceId: string): void {
    ZZZRecordRequest.context = context;
    ZZZRecordRequest.deviceId = deviceId;
  }

  /**
   * 构建绝区零战绩接口请求（mysapi.js getUrl）。
   * @param path   接口路径（ZZZApiPath）
   * @param query  接口自带 query 原文，参与 DS 签名
   * @param extraQuery 追加 query（如 id_list[]=1171），不参与 DS 签名
   */
  static async build(cookie: string, path: string, query: string, extraQuery: string = ''): Promise<ZZZRequest> {
    const fp = await ZZZRecordRequest.ensureDevice(cookie);
    const headers = ZZZRecordRequest.baseHeaders(cookie, fp);
    headers.set('DS', DSUtil.generateX4RawQuery(query, ''));
    // 人机验证通过后重放：带上 x-rpc-challenge（只用一次）
    const challengeKey = `${ZZZRecordRequest.accountIdOf(cookie)}|${MihoyoDomain.TAKUMI_RECORD + path}`;
    const challenge = ZZZRecordRequest.challenges.get(challengeKey);
    if (challenge !== undefined) {
      headers.set('x-rpc-challenge', challenge);
      ZZZRecordRequest.challenges.delete(challengeKey);
    }
    let url = MihoyoDomain.TAKUMI_RECORD + path;
    if (query.length > 0) {
      url += `?${query}`;
    }
    if (extraQuery.length > 0) {
      url += (url.indexOf('?') >= 0 ? '&' : '?') + extraQuery;
    }
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const request = new ZZZRequest();
    request.url = url;
    request.options = opts;
    request.deviceFp = fp;
    return request;
  }

  /** 是否为绝区零战绩接口（人机验证走 createGeetest / verifyGeetest） */
  static isZZZRecordUrl(url: string): boolean {
    return url.indexOf('/event/game_record_zzz/') !== -1;
  }

  /**
   * 申请人机验证（loveMys.js geetest：retcode === 10035 ? createGeetest : createVerification）
   * - 10035：GET api-takumi/event/toolcomsrv/risk/createGeetest?is_high=true&app_key=game_record_zzz
   * - 1034 ：GET api-takumi-record/game_record/app/card/wapi/createVerification?is_high=true
   */
  static async createGeetest(cookie: string, retcode: number): Promise<GeetestCreateResult> {
    const useGeetest = retcode === 10035;
    const query = useGeetest ? `is_high=true&app_key=${GEETEST_APP_KEY}` : 'is_high=true';
    const url = useGeetest
      ? `${MihoyoDomain.TAKUMI}/event/toolcomsrv/risk/createGeetest?${query}`
      : `${MihoyoDomain.TAKUMI_RECORD}/game_record/app/card/wapi/createVerification?${query}`;
    const opts = await ZZZRecordRequest.geetestOptions(cookie, query, '');
    const response = await BaseApiService.shared.get(url, undefined, opts);
    const resp = response.data;
    const r = resp as Record<string, Object>;
    const data = r['data'] as Record<string, Object> | null | undefined;
    if (Number(r['retcode']) !== 0 || data === null || data === undefined) {
      throw new Error(`createGeetest failed: retcode=${r['retcode']}, message=${r['message']}`);
    }
    const result = new GeetestCreateResult();
    result.gt = `${data['gt'] ?? ''}`;
    result.challenge = `${data['challenge'] ?? ''}`;
    result.new_captcha = Number(data['new_captcha'] ?? 0);
    result.risk_type = `${data['risk_type'] ?? ''}`;
    return result;
  }

  /**
   * 提交人机验证（retcode === 10035 ? verifyGeetest : verifyVerification），成功后记下返回的 challenge，
   * 下一次请求 challengePath 对应接口时带上 x-rpc-challenge 重放（loveMys.js getvali）
   */
  static async verifyGeetest(cookie: string, input: GeetestVerifyInput, challengePath: string, retcode: number): Promise<string> {
    const useGeetest = retcode === 10035;
    let bodyStr: string;
    if (useGeetest) {
      const body = new VerifyGeetestBody();
      body.geetest_challenge = input.geetest_challenge;
      body.geetest_validate = input.geetest_validate;
      body.geetest_seccode = `${input.geetest_validate}|jordan`;
      bodyStr = JSON.stringify(body);
    } else {
      const body = new VerifyVerificationBody();
      body.geetest_challenge = input.geetest_challenge;
      body.geetest_validate = input.geetest_validate;
      body.geetest_seccode = `${input.geetest_validate}|jordan`;
      bodyStr = JSON.stringify(body);
    }
    const url = useGeetest
      ? `${MihoyoDomain.TAKUMI}/event/toolcomsrv/risk/verifyGeetest`
      : `${MihoyoDomain.TAKUMI_RECORD}/game_record/app/card/wapi/verifyVerification`;
    const opts = await ZZZRecordRequest.geetestOptions(cookie, '', bodyStr);
    opts.extraHeaders.set('content-type', 'application/json');
    const response = await BaseApiService.shared.post(url, bodyStr, opts);
    const resp = response.data;
    const r = resp as Record<string, Object>;
    const data = r['data'] as Record<string, Object> | null | undefined;
    const challenge = data !== null && data !== undefined ? `${data['challenge'] ?? ''}` : '';
    if (Number(r['retcode']) !== 0 || challenge.length === 0) {
      throw new Error(`verifyGeetest failed: retcode=${r['retcode']}, message=${r['message']}`);
    }
    const q = challengePath.indexOf('?');
    const path = q >= 0 ? challengePath.substring(0, q) : challengePath;
    ZZZRecordRequest.challenges.set(`${ZZZRecordRequest.accountIdOf(cookie)}|${path}`, challenge);
    return challenge;
  }

  /**
   * 验证接口的请求头（mysApi.js getHeaders 国服 cn：x-rpc-client_type=5）+ 该账号的设备指纹 / 设备信息 + x-rpc-challenge_game=8
   */
  private static async geetestOptions(cookie: string, query: string, body: string): Promise<RequestOptions> {
    const fp = await ZZZRecordRequest.ensureDevice(cookie);
    const h = new Map<string, string>();
    h.set('x-rpc-app_version', APP_VERSION);
    h.set('x-rpc-client_type', '5');
    h.set('User-Agent', USER_AGENT);
    h.set('Referer', 'https://act.mihoyo.com/');
    h.set('Cookie', cookie);
    h.set('DS', DSUtil.generateX4RawQuery(query, body));
    h.set('x-rpc-device_fp', fp);
    h.set('x-rpc-device_id', ZZZRecordRequest.deviceId);
    h.set('x-rpc-device_name', `${DEVICE_BRAND} ${MODEL_NAME}`);
    h.set('x-rpc-device_model', MODEL_NAME);
    h.set('x-rpc-csm_source', 'myself');
    h.set('x-rpc-challenge_game', '8');
    const opts = new RequestOptions();
    opts.extraHeaders = h;
    // 验证接口本身不再触发统一人机验证上报
    opts.suppressGeetestReport = true;
    return opts;
  }

  /** 重新生成设备指纹时清空，下次请求重新申请并登记设备 */
  static async clearAll(): Promise<void> {
    const keys: string[] = [];
    ZZZRecordRequest.fps.forEach((_v: string, k: string) => {
      keys[keys.length] = k;
    });
    ZZZRecordRequest.fps.clear();
    const ctx = ZZZRecordRequest.context;
    if (ctx === null) {
      return;
    }
    try {
      const prefs = await preferences.getPreferences(ctx, PREFS_NAME);
      for (let i = 0; i < keys.length; i++) {
        await prefs.delete(KEY_ZZZ_FP_PREFIX + keys[i]);
      }
      await prefs.flush();
    } catch (_) {}
  }

  /** mysapi.js getHeaders + getUrl 中追加的 Cookie / 设备字段（不含 DS） */
  private static baseHeaders(cookie: string, fp: string): Map<string, string> {
    const h = new Map<string, string>();
    h.set('x-rpc-app_version', APP_VERSION);
    h.set('User-Agent', USER_AGENT);
    h.set('x-rpc-sys_version', '12');
    h.set('x-rpc-client_type', '2');
    h.set('x-rpc-channel', 'mihoyo');
    h.set('Referer', 'https://act.mihoyo.com/');
    h.set('Origin', 'https://act.mihoyo.com');
    if (fp.length > 0) {
      h.set('x-rpc-device_fp', fp);
    }
    h.set('Cookie', cookie);
    h.set('x-rpc-device_id', ZZZRecordRequest.deviceId);
    h.set('x-rpc-device_name', `${DEVICE_BRAND} ${MODEL_NAME}`);
    h.set('x-rpc-device_model', MODEL_NAME);
    h.set('x-rpc-csm_source', 'myself');
    return h;
  }

  /** 该账号的指纹：内存 → 本地缓存（7 天）→ 申请并登记设备（plugin.js getAPI） */
  private static async ensureDevice(cookie: string): Promise<string> {
    const accountId = ZZZRecordRequest.accountIdOf(cookie);
    const cached = ZZZRecordRequest.fps.get(accountId);
    if (cached !== undefined) {
      return cached;
    }
    const inFlight = ZZZRecordRequest.pending.get(accountId);
    if (inFlight !== undefined) {
      return inFlight;
    }
    const task = ZZZRecordRequest.loadOrRegister(accountId, cookie);
    ZZZRecordRequest.pending.set(accountId, task);
    try {
      return await task;
    } finally {
      ZZZRecordRequest.pending.delete(accountId);
    }
  }

  private static async loadOrRegister(accountId: string, cookie: string): Promise<string> {
    const ctx = ZZZRecordRequest.context;
    let prefs: preferences.Preferences | null = null;
    if (ctx !== null) {
      try {
        prefs = await preferences.getPreferences(ctx, PREFS_NAME);
        const stored = await prefs.get(KEY_ZZZ_FP_PREFIX + accountId, '');
        if (typeof stored === 'string' && stored.length > 0) {
          const parts = stored.split('|');
          if (parts.length === 2 && Date.now() - Number(parts[1]) < FP_CACHE_MS) {
            ZZZRecordRequest.fps.set(accountId, parts[0]);
            return parts[0];
          }
        }
      } catch (_) {}
    }
    let fp = '';
    try {
      fp = await ZZZRecordRequest.fetchFp(cookie);
    } catch (e) {
      // plugin.js：申请失败时使用默认指纹 38d805c20d53d，且不登记设备、不缓存
      return '38d805c20d53d';
    }
    ZZZRecordRequest.fps.set(accountId, fp);
    if (prefs !== null) {
      try {
        await prefs.put(KEY_ZZZ_FP_PREFIX + accountId, `${fp}|${Date.now()}`);
        await prefs.flush();
      } catch (_) {}
    }
    await ZZZRecordRequest.registerDevice(cookie, fp);
    return fp;
  }

  /** tool.js getFp（国服）：noDs，请求体 device_id 替换为当前设备 ID */
  private static async fetchFp(cookie: string): Promise<string> {
    const uuid = util.generateRandomUUID(false);
    const body = new FpBody();
    body.bbs_device_id = uuid;
    body.device_id = ZZZRecordRequest.deviceId;
    body.ext_fields = ZZZRecordRequest.extFields(uuid);
    body.seed_id = uuid;
    body.seed_time = `${Date.now()}`;
    const bodyStr = JSON.stringify(body);
    const opts = new RequestOptions();
    opts.extraHeaders = ZZZRecordRequest.baseHeaders(cookie, '');
    opts.extraHeaders.set('content-type', 'application/json');
    const response = await BaseApiService.shared.post(MihoyoDomain.PUBLIC_DATA_API + '/device-fp/api/getFp', bodyStr, opts);
    const resp = response.data;
    const r = resp as Record<string, Object>;
    const data = r['data'] as Record<string, Object> | null | undefined;
    const fp = data !== null && data !== undefined ? `${data['device_fp'] ?? ''}` : '';
    if (fp.length === 0) {
      throw new Error(`getFp failed: retcode=${r['retcode']}, message=${r['message']}`);
    }
    return fp;
  }

  /** tool.js deviceLogin + saveDevice（国服）：把设备登记到米游社账号，失败只记日志（与 plugin.js 一致） */
  private static async registerDevice(cookie: string, fp: string): Promise<void> {
    const paths: string[] = ['/apihub/api/deviceLogin', '/apihub/api/saveDevice'];
    for (let i = 0; i < paths.length; i++) {
      try {
        const body = new DeviceLoginBody();
        body.device_id = ZZZRecordRequest.deviceId;
        body.registration_id = ZZZRecordRequest.generateSeed(19);
        const bodyStr = JSON.stringify(body);
        const opts = new RequestOptions();
        opts.extraHeaders = ZZZRecordRequest.baseHeaders(cookie, fp);
        opts.extraHeaders.set('DS', DSUtil.generateX4RawQuery('', bodyStr));
        opts.extraHeaders.set('content-type', 'application/json');
        await BaseApiService.shared.post(MihoyoDomain.BBS + paths[i], bodyStr, opts);
      } catch (_) {
        // 登记失败不影响后续请求（与 plugin.js 一致，只记录不中断）
      }
    }
  }

  /** tool.js getFp 的 ext_fields（国服），设备信息取 defSet/device.yaml 默认值 */
  private static extFields(uuid: string): string {
    return `{"proxyStatus":1,"isRoot":0,"romCapacity":"768","deviceName":"${MODEL_NAME}","productName":"${PRODUCT_NAME}",` +
      `"romRemain":"727","hostname":"BuildHost","screenSize":"1096x2434","isTablet":0,"aaid":"${uuid}","model":"${MODEL_NAME}",` +
      `"brand":"${DEVICE_BRAND}","hardware":"qcom","deviceType":"${PRODUCT_TYPE}","devId":"REL","serialNumber":"unknown",` +
      `"sdCapacity":224845,"buildTime":"1692775759000","buildUser":"BuildUser","simState":1,"ramRemain":"218344",` +
      `"appUpdateTimeDiff":1740498108042,"deviceInfo":"${DEVICE_INFO}","vaid":"${uuid}","buildType":"user","sdkVersion":"33",` +
      `"ui_mode":"UI_MODE_TYPE_NORMAL","isMockLocation":0,"cpuType":"arm64-v8a","isAirMode":0,"ringMode":2,"chargeStatus":1,` +
      `"manufacturer":"${DEVICE_BRAND}","emulatorStatus":0,"appMemory":"768","osVersion":"${OS_VERSION}","vendor":"unknown",` +
      `"accelerometer":"-1.588236x6.8404818x6.999604","sdRemain":218214,"buildTags":"release-keys",` +
      `"packageName":"com.mihoyo.hyperion","networkType":"WiFi","oaid":"${uuid}","debugStatus":1,"ramCapacity":"224845",` +
      `"magnetometer":"-47.04375x51.3375x137.96251","display":"${DEVICE_DISPLAY}","appInstallTimeDiff":1740498108042,` +
      `"packageVersion":"2.35.0","gyroscope":"-0.22601996x-0.09453133x0.09040799","batteryStatus":88,"hasKeyboard":0,` +
      `"board":"${BOARD}"}`;
  }

  /** utils/data.js generateSeed */
  private static generateSeed(length: number): string {
    const chars = '0123456789abcdef';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  /** Cookie 中的米游社 UID（ltuid / account_id / stuid），取不到时用整个 Cookie */
  private static accountIdOf(cookie: string): string {
    const keys: string[] = ['ltuid', 'account_id', 'stuid'];
    for (let i = 0; i < keys.length; i++) {
      const m = cookie.match(new RegExp(`(?:^|;\\s*)${keys[i]}=([^;]+)`));
      if (m !== null) {
        return m[1].trim();
      }
    }
    return cookie;
  }
}

/** verifyGeetest 请求体（apiTool.js verifyGeetest，字段顺序一致） */
class VerifyGeetestBody {
  geetest_challenge: string = '';
  geetest_validate: string = '';
  geetest_seccode: string = '';
  app_key: string = GEETEST_APP_KEY;
}

/** verifyVerification 请求体（apiTool.js verifyVerification，字段顺序一致，无 app_key） */
class VerifyVerificationBody {
  geetest_challenge: string = '';
  geetest_validate: string = '';
  geetest_seccode: string = '';
}

/** ZZZRecordRequest.build 的结果 */
export class ZZZRequest {
  url: string = '';
  options: RequestOptions = new RequestOptions();
  /** 本次使用的设备指纹（排查日志用） */
  deviceFp: string = '';
}

/** 把绝区零战绩接口的 Geetest 实现注入 base/network/GeetestService */
export class ZZZGeetestRecordHandler implements GeetestRecordHandler {
  isRecordUrl(url: string): boolean {
    return ZZZRecordRequest.isZZZRecordUrl(url);
  }

  create(cookie: string, retcode: number): Promise<GeetestCreateResult> {
    return ZZZRecordRequest.createGeetest(cookie, retcode);
  }

  verify(cookie: string, input: GeetestVerifyInput, challengePath: string, retcode: number): Promise<string> {
    return ZZZRecordRequest.verifyGeetest(cookie, input, challengePath, retcode);
  }
}
