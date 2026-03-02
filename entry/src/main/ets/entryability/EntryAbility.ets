import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import Window from '@ohos.window';
import common from '@ohos.app.ability.common';
import { CoreInitializer } from 'core';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { HMRouterMgr } from '@hadss/hmrouter';
import { Logger, RuntimeEnv } from '../utils/Logger';

const TAG: string = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam) {
    Logger.info(TAG, 'onCreate');

    const runtimeEnv: RuntimeEnv = Logger.getRuntimeEnv();
    const isMock: boolean = runtimeEnv === RuntimeEnv.MOCK;
    CoreInitializer.initCore({
      isMock,
      context: this.context as common.UIAbilityContext
    });
    Logger.info(TAG, `Detected environment: ${Logger.getRuntimeEnvDetail()}`);
    this.runStartupTaskByEnv(runtimeEnv);

    HMRouterMgr.openLog(runtimeEnv === RuntimeEnv.RELEASE ? 'INFO' : 'DEBUG');
    HMRouterMgr.init({ context: this.context }).catch((error: object) => {
      Logger.warning(TAG, `HMRouter init failed: ${JSON.stringify(error)}`);
    });
  }

  onDestroy() {
    Logger.info(TAG, 'onDestroy');
  }

  onWindowStageCreate(windowStage: Window.WindowStage) {
    // Main window is created, set main page for this ability
    Logger.info(TAG, 'onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        Logger.warning(TAG, `Failed to load content: ${JSON.stringify(err)}`);
        return;
      }
      Logger.info(TAG, `Succeeded in loading content: ${JSON.stringify(data)}`);
    });
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    Logger.info(TAG, 'onWindowStageDestroy');
  }

  onForeground() {
    // Ability has brought to foreground
    Logger.info(TAG, 'onForeground');
  }

  onBackground() {
    // Ability has back to background
    Logger.info(TAG, 'onBackground');
  }

  private runStartupTaskByEnv(runtimeEnv: RuntimeEnv): void {
    if (runtimeEnv === RuntimeEnv.MOCK) {
      Logger.debug(TAG, 'Run startup task for Mock environment');
      return;
    }

    if (runtimeEnv === RuntimeEnv.RELEASE) {
      Logger.info(TAG, 'Run startup task for Release environment');
      return;
    }

    Logger.debug(TAG, 'Run startup task for non-Mock/Release environment');
  }
}
