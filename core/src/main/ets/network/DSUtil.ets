import crypto from '@ohos/crypto-js';
import { AxiosRequestConfig } from '@ohos/axios';

/**
 * DS 工具类
 * 生成米游社 API 请求的 Dynamic Secret 签名
 */
export class DSUtil {
  /**
   * 生成随机字符串
   * @param length 字符串长度
   * @returns 随机字符串
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
   * 获取当前时间戳
   * @returns 时间戳（秒）
   */
  private static getTimestamp(): number {
    return Math.floor(Date.now() / 1000);
  }

  /**
   * 构建签名字符串
   * @param config Axios 请求配置
   * @returns 签名字符串
   */
  private static buildSignString(config: AxiosRequestConfig): string {
    const timestamp = DSUtil.getTimestamp();
    const random = DSUtil.generateRandomString(6);
    
    let body = '';
    if (config.data) {
      body = typeof config.data === 'string' ? config.data : JSON.stringify(config.data);
    }
    let query = '';
    if (config.params) {
      const params: string[] = [];
      Object.entries<string>(config.params).forEach((entry: [string, string]) => {
        const key = entry[0];
        const value = entry[1];
        params.push(`${key}=${String(value)}`);
      });
      query = params.join('&');
    }

    // 这里的 salt 值需要根据实际情况填写
    // 不同的 API 可能使用不同的 salt
    const salt = 'your_salt_here'; // 后续需要替换为实际的 salt

    return `${salt}${timestamp}${random}${body}${query}`;
  }

  /**
   * 生成 DS 签名
   * @param config Axios 请求配置
   * @returns DS 签名
   */
  public static generateDS(config: AxiosRequestConfig): string {
    const signString = DSUtil.buildSignString(config);
    const md5Hash = crypto.MD5(signString).toString();
    const timestamp = DSUtil.getTimestamp();
    const random = DSUtil.generateRandomString(6);
    
    return `${timestamp},${random},${md5Hash}`;
  }
}

// 导出默认实例
export const generateDS = DSUtil.generateDS;
