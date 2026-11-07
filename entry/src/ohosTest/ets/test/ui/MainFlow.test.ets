import { describe, it, expect, beforeAll } from '@ohos/hypium';
import { abilityDelegatorRegistry, Driver, ON } from '@kit.TestKit';
import { Want } from '@kit.AbilityKit';

/**
 * 主链路 UI 冒烟测试骨架。
 *
 * 运行条件：
 * 1. 已连接真机 / 模拟器（hdc list targets 非空）
 * 2. 设备上已登录至少一个米游社账号（首页有数据）
 * 3. 通过 `hvigorw test -p module=entry@ohosTest` 或 DevEco 运行
 *
 * 当前只验证应用能启动，并落在首页或登录页；后续按 docs/ui-test-plan.md
 * 补充「首页 → 角色详情 → 材料计算」的完整点击链路。
 */
let driver: Driver = Driver.create();

export default function mainFlowUiTest() {
  describe('MainFlowUi', () => {

    beforeAll(async () => {
      const delegator = abilityDelegatorRegistry.getAbilityDelegator();
      const args = abilityDelegatorRegistry.getArguments();
      const want: Want = {
        bundleName: args.bundleName,
        abilityName: 'EntryAbility'
      };
      await delegator.startAbility(want);
      driver = Driver.create();
      await driver.delayMs(2000);
    });

    it('应用启动后落在首页或登录页', 0, async () => {
      const hasMain = await driver.waitForComponent(ON.id('main_navigation'), 5000);
      const hasLogin = await driver.waitForComponent(ON.id('login_page'), 1000);
      expect(hasMain || hasLogin).assertTrue();
    });

  });
}
