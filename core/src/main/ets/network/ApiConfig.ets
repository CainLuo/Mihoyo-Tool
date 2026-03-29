/**
 * API 配置类
 * 基于 mihoyo_apis.md 中的真实 API 域名
 */
export class ApiConfig {
  /** 战绩/便笺/角色列表 API（主要域名） */
  public static readonly TAKUMI_RECORD = 'https://api-takumi-record.mihoyo.com';

  /** 养成计算 API（原神/崩铁） */
  public static readonly TAKUMI = 'https://api-takumi.mihoyo.com';

  /** 养成计算 API（绝区零） */
  public static readonly ACT_TAKUMI = 'https://act-api-takumi.mihoyo.com';

  /** 根据类型获取 BaseURL */
  public static getBaseUrl(type: string): string {
    if (type === 'TAKUMI') { return ApiConfig.TAKUMI; }
    if (type === 'ACT_TAKUMI') { return ApiConfig.ACT_TAKUMI; }
    return ApiConfig.TAKUMI_RECORD;
  }
}
