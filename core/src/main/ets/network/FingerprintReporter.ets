/**
 * FingerprintReporter — 设备指纹无效 / 账号异常（retcode=5003 / 10041）统一上报
 *
 * PizzaHelperUnited 将 5003 / 10041 归为 fingerPrintInvalidOrMissing，Miao-Yunzai 归为"米游社账号异常"，均与人机验证分开处理。
 * 具体 API 收到时显式调用 report()，由 entry 通过 ApiConfig.setFingerprintInvalidListener() 注册的监听统一提示。
 */
export type FingerprintInvalidListener = (url: string, retcode: number, roleUid: string) => void;

export class FingerprintReporter {
  private static listener: FingerprintInvalidListener | null = null;

  static setListener(listener: FingerprintInvalidListener | null): void {
    FingerprintReporter.listener = listener;
  }

  /**
   * @param url     出错的接口地址（会去掉 query）
   * @param retcode 5003 / 10041
   * @param roleUid 该请求的游戏 UID（取不到时为空字符串）
   */
  static report(url: string, retcode: number, roleUid: string): void {
    const listener = FingerprintReporter.listener;
    if (listener === null) {
      return;
    }
    const q = url.indexOf('?');
    try {
      listener(q >= 0 ? url.substring(0, q) : url, retcode, roleUid);
    } catch (_) {}
  }

  /**
   * 5003 / 10041：Miao-Yunzai mysInfo.js checkCode 归为"米游社账号异常，暂时无法查询"，
   * PizzaHelperUnited 归为 fingerPrintInvalidOrMissing；都不走人机验证
   */
  static isFingerprintRetcode(retcode: number | undefined): boolean {
    return retcode === 5003 || retcode === 10041;
  }
}
