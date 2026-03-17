import crypto from '@ohos/crypto-js';
import { AxiosRequestConfig } from '@ohos/axios';

/**
 * DS 工具类
 * 生成米游社 API 请求的 Dynamic Secret 签名
 *
 * DS 格式：{timestamp},{random},{md5}
 * 其中 md5 = MD5("{salt}{timestamp}{random}{body}{query}")
 * timestamp 和 random 在一次签名中只生成一次，保证签名内容与返回值一致。
 */
export class DSUtil {
  // TODO: 不同 API 使用不同 salt，请从安全配置中注入，勿硬编码
  private static readonly SALT: string = 'your_salt_here';

  /**
   * 生成随机字符串
   */
  private static generateRandomString(length: number): string {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
  }

  /**
   * 获取当前时间戳（秒）
   */
  private static getTimestamp(): number {
    return Math.floor(Date.now() / 1000);
  }

  /**
   * 生成 DS 签名
   * timestamp 和 random 只生成一次，同时用于签名内容和返回值，保证一致性。
   */
  public static generateDS(config: AxiosRequestConfig): string {
    const timestamp: number = DSUtil.getTimestamp();
    const random: string = DSUtil.generateRandomString(6);

    let body = '';
    if (config.data) {
      body = typeof config.data === 'string' ? config.data : JSON.stringify(config.data);
    }

    let query = '';
    if (config.params) {
      const params: string[] = [];
      Object.entries<string>(config.params).forEach((entry: [string, string]) => {
        params.push(`${entry[0]}=${String(entry[1])}`);
      });
      query = params.join('&');
    }

    const signContent: string = `${DSUtil.SALT}${timestamp}${random}${body}${query}`;
    const md5Hash: string = crypto.MD5(signContent).toString();

    return `${timestamp},${random},${md5Hash}`;
  }
}

export const generateDS = (config: AxiosRequestConfig): string => DSUtil.generateDS(config);
