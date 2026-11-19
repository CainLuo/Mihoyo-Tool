import { abilityDelegatorRegistry, TestRunner } from '@kit.TestKit';
import { UIAbility, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

let abilityDelegator: abilityDelegatorRegistry.AbilityDelegator;
let abilityDelegatorArguments: abilityDelegatorRegistry.AbilityDelegatorArgs;

async function onAbilityCreateCallback(data: UIAbility) {
  hilog.info(0x0000, 'testTag', 'onAbilityCreateCallback: %{public}s', JSON.stringify(data));
}

async function addAbilityMonitorCallback(err: BusinessError) {
  hilog.info(0x0000, 'testTag', 'addAbilityMonitorCallback: %{public}s', JSON.stringify(err) ?? '');
}

/**
 * 设备端测试入口（`aa test -s unittest OpenHarmonyTestRunner` 会加载本文件）。
 *
 * 职责：拿到 AbilityDelegator 后启动同模块的 TestAbility，
 * 由 TestAbility.onCreate 调用 Hypium.hypiumTest 执行 test/List.test.ets 里的用例。
 */
export default class OpenHarmonyTestRunner implements TestRunner {
  constructor() {
  }

  onPrepare() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'OpenHarmonyTestRunner onPrepare');
  }

  async onRun() {
    hilog.info(0x0000, 'testTag', '%{public}s', 'OpenHarmonyTestRunner onRun');
    abilityDelegatorArguments = abilityDelegatorRegistry.getArguments();
    abilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();

    const moduleName: string = abilityDelegatorArguments.parameters['-m'];
    const bundleName: string = abilityDelegatorArguments.bundleName;
    const testAbilityName: string = 'TestAbility';

    const monitor: abilityDelegatorRegistry.AbilityMonitor = {
      abilityName: testAbilityName,
      onAbilityCreate: onAbilityCreateCallback,
      moduleName: moduleName,
    };
    abilityDelegator.addAbilityMonitor(monitor, addAbilityMonitorCallback);

    const want: Want = {
      bundleName: bundleName,
      abilityName: testAbilityName,
      moduleName: moduleName,
    };
    abilityDelegator.startAbility(want, (err: BusinessError, data: void) => {
      hilog.info(0x0000, 'testTag', 'startAbility err: %{public}s', JSON.stringify(err) ?? '');
      hilog.info(0x0000, 'testTag', 'startAbility data: %{public}s', JSON.stringify(data) ?? '');
    });
    hilog.info(0x0000, 'testTag', '%{public}s', 'OpenHarmonyTestRunner onRun end');
  }
}
