import { RequestParams, RequestValue } from '../APIs';
import crypto from '@ohos/crypto-js';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

/**
 * DSUtilV2 — 米游社 DS 动态签名生成
 *
 * DS 格式：{timestamp},{random},{md5}
 * md5 内容：salt={salt}&t={timestamp}&r={random}&b={body}&q={query}
 *
 * salt 从 rawfile/release/salt_config.json 读取，禁止硬编码。
 * 使用前必须调用 preloadSalts(context) 完成预加载。
 */
export class DSUtilV2 {
  private static saltV1: string = '';
  private static saltV2: string = '';
  private static saltX6: string = '';

  /**
   * 预加载 salt 配置（在 CoreInitializerV2.initCore 中调用）
   */
  static async preloadSalts(context: common.UIAbilityContext): Promise<void> {
    try {
      const rm = context.resourceManager;
      const raw = await rm.getRawFileContent('release/salt_config.json');
      const decoder = new util.TextDecoder('utf-8');
      const jsonStr = decoder.decodeToString(new Uint8Array(raw.buffer));
      const config = JSON.parse(jsonStr) as Record<string, string>;
      const v1 = config['salt_v1'];
      const v2 = config['salt_v2'];
      const x6 = config['salt_x6'];
      if (typeof v1 === 'string') {
        DSUtilV2.saltV1 = v1;
      }
      if (typeof v2 === 'string') {
        DSUtilV2.saltV2 = v2;
      }
      if (typeof x6 === 'string') {
        DSUtilV2.saltX6 = x6;
      }
    } catch (e) {
      // salt 加载失败时保持空字符串，DS 签名会失效但不崩溃
    }
  }

  /**
   * 生成 V1 DS（游戏记录接口，GAME_RECORD Profile）
   * @param params GET 请求参数（用于 query 部分）
   * @param body   POST 请求 body 字符串（GET 请求传 undefined）
   */
  static generateV1(params?: RequestParams, body?: string): string {
    return DSUtilV2.generate(DSUtilV2.saltV1, params, body);
  }

  /**
   * 生成 V2 DS（BBS 接口，BBS Profile）
   * @param params GET 请求参数
   * @param body   POST 请求 body 字符串
   */
  static generateV2(params?: RequestParams, body?: string): string {
    return DSUtilV2.generate(DSUtilV2.saltV2, params, body);
  }

  /**
   * 生成 X6 DS（签到接口，SIGN Profile）
   * @param params GET 请求参数
   * @param body   POST 请求 body 字符串
   */
  static generateX6(params?: RequestParams, body?: string): string {
    return DSUtilV2.generate(DSUtilV2.saltX6, params, body);
  }

  /**
   * 核心签名逻辑
   * query 参数按字典序排列（ArkTS 严格模式：用 for 循环替代 Array.sort()）
   */
  private static generate(salt: string, params?: RequestParams, body?: string): string {
    const timestamp = Math.floor(Date.now() / 1000);
    const random = DSUtilV2.generateRandom(6);
    const b = body !== undefined ? body : '';
    const q = DSUtilV2.serializeParams(params);
    const signContent = `salt=${salt}&t=${timestamp}&r=${random}&b=${b}&q=${q}`;
    const md5Hash = crypto.MD5(signContent).toString();
    return `${timestamp},${random},${md5Hash}`;
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

  /** 生成 n 位随机字母数字字符串 */
  private static generateRandom(n: number): string {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < n; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }
}
