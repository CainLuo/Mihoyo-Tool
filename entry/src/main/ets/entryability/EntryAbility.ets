import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { CoreInitializer } from 'core';
import { HMRouterMgr } from '@hadss/hmrouter';
import { Logger, RuntimeEnv } from '../utils/Logger';

const TAG: string = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam) {
    Logger.info(TAG, 'onCreate');

    const runtimeEnv: RuntimeEnv = Logger.getRuntimeEnv();
    const isMock: boolean = runtimeEnv === RuntimeEnv.MOCK;

    // initCore 现在是 async（内部完成 RDB 初始化 + Mock 数据预填充）
    CoreInitializer.initCore({ isMock, context: this.context })
      .then(() => {
        Logger.info(TAG, `Core initialized. isMock=${isMock}`);
        this.runStartupTaskByEnv(runtimeEnv);
      })
      .catch((error: Error | object) => {
        Logger.warning(TAG, `CoreInitializer.initCore failed: ${JSON.stringify(error)}`);
      });

    Logger.info(TAG, `Detected environment: ${Logger.getRuntimeEnvDetail()}`);

    HMRouterMgr.openLog(runtimeEnv === RuntimeEnv.RELEASE ? 'INFO' : 'DEBUG');
    // 设置默认 navigationId，所有 push/replace 调用无需显式传 navigationId
    HMRouterMgr.setDefaultNavigationId('mainNavigationId');
    // HMRouterMgr.init 必须在 loadContent 之前完成，避免路由未就绪时进入页面
    HMRouterMgr.init({ context: this.context }).catch((error: Error | object) => {
      Logger.warning(TAG, `HMRouter init failed: ${JSON.stringify(error)}`);
    });
  }

  onDestroy() {
    Logger.info(TAG, 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
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
    Logger.info(TAG, 'onWindowStageDestroy');
  }

  onForeground() {
    Logger.info(TAG, 'onForeground');
  }

  onBackground() {
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
