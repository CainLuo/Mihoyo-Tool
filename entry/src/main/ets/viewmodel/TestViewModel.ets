/**
 * TestViewModel.ets — 测试工具页 ViewModel
 *
 * 测试页的调试动作（改写 Cookie / 触发过期弹框）集中在这里，
 * 页面只负责按钮与 Toast。
 */
import { CoreInitializer, FailedAccountInfo } from 'core';
import { CookieExpiredSignal } from 'basic';

export class TestViewModel {
  /** T1 / T3：把所有账号的 update_time 改为 8 天前 */
  setUpdateTimeTo8DaysAgo(): Promise<void> {
    return CoreInitializer.bbsRepository.setAllUpdateTimeTo8DaysAgo();
  }

  /** T3：清掉所有账号的 stoken */
  setAllCookieWithoutStoken(): Promise<void> {
    return CoreInitializer.bbsRepository.setAllCookieWithoutStoken();
  }

  /** T2：直接推送一条假的 Cookie 过期信号，触发主页弹框 */
  triggerCookieExpired(): void {
    const fakeInfo = new FailedAccountInfo();
    fakeInfo.nickname = '测试账号';
    fakeInfo.username = '182692936';
    fakeInfo.isNetworkError = false;
    CookieExpiredSignal.getInstance().push(fakeInfo);
  }
}
