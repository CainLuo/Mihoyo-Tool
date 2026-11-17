/**
 * MaterialComputeResult.ets — 材料计算服务的返回结果
 *
 * 单独成文件，避免拆分后的各游戏计算模块与 facade 互相 import 造成循环依赖。
 */

/** 计算结果 */
export enum MaterialComputeResult {
  /** 计算完成，可跳转 / 刷新材料页 */
  SUCCESS = 'SUCCESS',
  /** 选中角色都已达到目标，没有需要计算的内容 */
  NO_NEEDS = 'NO_NEEDS',
  /** 请求或写库失败 */
  FAILED = 'FAILED',
  /** 正在计算中，忽略重复点击 */
  BUSY = 'BUSY',
  /** DB 中没有该游戏 UID 的养成目标配置，需要先去配置页设置 */
  NO_CONFIG = 'NO_CONFIG',
}
