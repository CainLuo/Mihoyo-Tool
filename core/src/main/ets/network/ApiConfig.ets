
/**
 * API 基础路径类型接口
 */
interface BaseUrlTypeMap {
  TAKUMI_RECORD: string;
  BBS_API: string;
  PUBLIC_DATA: string;
}

/**
 * API 配置类
 * 定义不同的 BaseURL 常量
 */
export class ApiConfig {
  /**
   * 米游社记录 API
   */
  public static readonly TAKUMI_RECORD = 'https://api-takumi.mihoyo.com';

  /**
   * 米游社 BBS API
   */
  public static readonly BBS_API = 'https://bbs-api.mihoyo.com';

  /**
   * 公共数据 API
   */
  public static readonly PUBLIC_DATA = 'https://api.mihoyo.com';
  /**
   * API 基础路径枚举
   */
  public static readonly BaseUrlType: BaseUrlTypeMap = {
    TAKUMI_RECORD: 'TAKUMI_RECORD',
    BBS_API: 'BBS_API',
    PUBLIC_DATA: 'PUBLIC_DATA'
  };

  /**
   * 根据类型获取 BaseURL
   * @param type BaseURL 类型
   * @returns BaseURL 字符串
   */
  public static getBaseUrl(type: string): string {
    switch (type) {
      case ApiConfig.BaseUrlType.TAKUMI_RECORD:
        return ApiConfig.TAKUMI_RECORD;
      case ApiConfig.BaseUrlType.BBS_API:
        return ApiConfig.BBS_API;
      case ApiConfig.BaseUrlType.PUBLIC_DATA:
        return ApiConfig.PUBLIC_DATA;
      default:
        return ApiConfig.PUBLIC_DATA;
    }
  }
}
