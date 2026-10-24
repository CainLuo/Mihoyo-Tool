import { RequestParams, RequestValue } from './APIs';
import crypto from '@ohos/crypto-js';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

/**
 * DSUtil — 米游社 DS 动态签名生成
 *
 * DS 格式：{timestamp},{random},{md5}
 * md5 内容：salt={salt}&t={timestamp}&r={random}&b={body}&q={query}
 *
 * salt 从 rawfile/release/salt_config.json 读取，禁止硬编码。
 * 使用前必须调用 preloadSalts(context) 完成预加载。
 */
export class DSUtil {
  private static saltV2: string = '';
  private static saltX4: string = '';
  private static saltX6: string = '';

  /**
   * 预加载 salt 配置（在 CoreInitializer.initCore 中调用）
   */
  static async preloadSalts(context: common.UIAbilityContext): Promise<void> {
    try {
      const rm = context.resourceManager;
      const raw = await rm.getRawFileContent('release/salt_config.json');
      const decoder = new util.TextDecoder('utf-8');
      const jsonStr = decoder.decodeToString(new Uint8Array(raw.buffer));
      const config = JSON.parse(jsonStr) as Record<string, string>;
      const v2 = config['salt_v2'];
      const x4 = config['salt_x4'];
      const x6 = config['salt_x6'];
      if (typeof v2 === 'string') { DSUtil.saltV2 = v2; }
      if (typeof x4 === 'string') { DSUtil.saltX4 = x4; }
      if (typeof x6 === 'string') { DSUtil.saltX6 = x6; }
    } catch (e) {
      // salt 加载失败时保持空字符串，DS 签名会失效但不崩溃
    }
  }

  /**
   * 生成 V2 DS（BBS Profile）
   * 历史 App 抓包变体：salt_v2 + 字母数字 random，保留与 BBS header 整套一致。
   * @param params GET 请求参数
   * @param body   POST 请求 body 字符串
   */
  static generateV2(params?: RequestParams, body?: string): string {
    return DSUtil.generate(DSUtil.saltV2, params, body);
  }

  /**
   * 生成 X4 DS（passport 接口：getLTokenBySToken / getCookieAccountInfoBySToken）
   * random 为 6 位纯数字（与米游社 App 一致）
   * @param params GET 请求参数
   * @param body   POST 请求 body 字符串
   */
  static generateX4(params?: RequestParams, body?: string): string {
    return DSUtil.generate(DSUtil.saltX4, params, body, true);
  }

  /**
   * 生成 X4 DS，q 直接使用调用方给出的 query 原文（不排序）。
   * 绝区零照 ZZZure/ZZZ-Plugin（dist/lib/mysapi.js getDs）：q 为接口自带 query，id_list[] 等追加参数不参与签名。
   */
  static generateX4RawQuery(query: string, body: string): string {
    const timestamp = Math.floor(Date.now() / 1000);
    const random = DSUtil.generateNumericRandom(6);
    const md5Hash = crypto.MD5(`salt=${DSUtil.saltX4}&t=${timestamp}&r=${random}&b=${body}&q=${query}`).toString();
    return `${timestamp},${random},${md5Hash}`;
  }

  /**
   * 生成 X6 DS（签到接口，SIGN Profile）
   * 对应 TeyvatGuide 的 X6 salt + isSign=false（含 b/q）
   * random 为 6 位纯数字
   * @param params GET 请求参数
   * @param body   POST 请求 body 字符串
   */
  static generateX6(params?: RequestParams, body?: string): string {
    return DSUtil.generate(DSUtil.saltX6, params, body, true);
  }

  /**
   * 使用固定 timestamp / random 生成 DS，供测试与内部复用。
   */
  static generateWith(
    salt: string,
    timestamp: number,
    random: string,
    params?: RequestParams,
    body?: string
  ): string {
    const b = body !== undefined ? body : '';
    const q = DSUtil.serializeParams(params);
    const signContent = `salt=${salt}&t=${timestamp}&r=${random}&b=${b}&q=${q}`;
    return `${timestamp},${random},${crypto.MD5(signContent).toString()}`;
  }

  /**
   * 核心签名逻辑
   * query 参数按字典序排列（ArkTS 严格模式：用 for 循环替代 Array.sort()）
   * @param numericRandom 是否使用纯数字 random（X4/X6 用纯数字，V2 用字母数字混合）
   */
  private static generate(salt: string, params?: RequestParams, body?: string, numericRandom: boolean = false): string {
    const timestamp = Math.floor(Date.now() / 1000);
    const random = numericRandom ? DSUtil.generateNumericRandom(6) : DSUtil.generateRandom(6);
    return DSUtil.generateWith(salt, timestamp, random, params, body);
  }

  /**
   * 将 RequestParams 序列化为 key=val&key=val 格式（按字典序排列）
   * ArkTS 严格模式：禁止 Array.sort()，用插入排序手动排序
   */
  private static serializeParams(params?: RequestParams): string {
    if (params === undefined || params.size === 0) {
      return '';
    }
    // 收集所有 key
    const keys: string[] = [];
    params.forEach((_val: RequestValue, key: string) => {
      keys[keys.length] = key;
    });
    // 插入排序（字典序）
    for (let i = 1; i < keys.length; i++) {
      const cur = keys[i];
      let j = i - 1;
      while (j >= 0 && keys[j] > cur) {
        keys[j + 1] = keys[j];
        j--;
      }
      keys[j + 1] = cur;
    }
    // 拼接
    const parts: string[] = [];
    for (let i = 0; i < keys.length; i++) {
      const k = keys[i];
      const v = params.get(k);
      parts[parts.length] = `${k}=${v !== undefined ? String(v) : ''}`;
    }
    return parts.join('&');
  }

  /** 生成 n 位随机字母数字字符串（V2 DS 使用） */
  private static generateRandom(n: number): string {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < n; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  /** 生成 n 位随机纯数字字符串（X4/X6 DS 使用），范围 100000-199999 */
  private static generateNumericRandom(_n: number): string {
    // 范围 100000-199999，与 GenshinPizzaHelper/HSRPizzaHelper 一致
    // Int.random(in: 100_000 ..< 200_000)
    return (100000 + Math.floor(Math.random() * 100000)).toString();
  }
}
