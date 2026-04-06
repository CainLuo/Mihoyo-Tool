import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { CoreInitializer } from 'core';
import { Logger, RuntimeEnv } from '../utils/Logger';
import { AppearanceManager } from '../utils/AppearanceManager';

const TAG: string = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam) {
    Logger.info(TAG, 'onCreate');

    // 尽早恢复用户选择的颜色模式，避免启动时闪烁
    AppearanceManager.restoreOnLaunch(this.context).catch((error: Error | object) => {
      Logger.warning(TAG, `restoreOnLaunch failed: ${JSON.stringify(error)}`);
    });

    const runtimeEnv: RuntimeEnv = Logger.getRuntimeEnv();
    const isMock: boolean = runtimeEnv === RuntimeEnv.MOCK;

    // 初始化数据库层
    CoreInitializer.initCore({ isMock, context: this.context })
      .then(() => {
        Logger.info(TAG, `CoreV2 initialized. isMock=${isMock}`);
        this.runStartupTaskByEnv(runtimeEnv);
      })
      .catch((error: Error | object) => {
        Logger.warning(TAG, `CoreInitializerV2.initCore failed: ${JSON.stringify(error)}`);
      });

    Logger.info(TAG, `Detected environment: ${Logger.getRuntimeEnvDetail()}`);
  }

  onDestroy() {
    Logger.info(TAG, 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    Logger.info(TAG, 'onWindowStageCreate');
    windowStage.getMainWindow().then((win) => {
      // 获取状态栏高度并存入 AppStorage，供各页面读取
      const topArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const topPx = topArea.topRect.height;
      AppStorage.setOrCreate('topRectHeight', topPx);
      const bottomArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const bottomPx = bottomArea.bottomRect.height;
      AppStorage.setOrCreate('bottomRectHeight', bottomPx);
      // 监听避让区域变化（折叠屏旋转等场景）
      win.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          AppStorage.setOrCreate('topRectHeight', data.area.topRect.height);
        } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          AppStorage.setOrCreate('bottomRectHeight', data.area.bottomRect.height);
        }
      });
      // 存储窗口宽度（px），供响应式布局使用
      const size = win.getWindowProperties().windowRect;
      AppStorage.setOrCreate('windowWidthPx', size.width);
      win.on('windowSizeChange', (s) => {
        AppStorage.setOrCreate('windowWidthPx', s.width);
      });
    }).catch((err: Error | object) => {
      Logger.warning(TAG, `getMainWindow failed: ${JSON.stringify(err)}`);
    });
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
