
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import Window from '@ohos.window';
import { CoreInitializer } from '@app/core';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { HMRouterMgr } from '@hadss/hmrouter';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    console.log('[Demo] EntryAbility onCreate');
    // 初始化核心库，传递环境配置
    const isMock = false; // BuildProfile中缺少IS_MOCK属性，暂时设为false
    CoreInitializer.initCore({ isMock });

    HMRouterMgr.openLog("DEBUG")
    HMRouterMgr.init({ context: this.context }).catch((error: Object) => {
      console.error('[Demo] HMRouter init failed: %{public}s', JSON.stringify(error));
    })
  }

  onDestroy() {
    console.log('[Demo] EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: Window.WindowStage) {
    // Main window is created, set main page for this ability
    console.log('[Demo] EntryAbility onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error('[Demo] Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      console.info('[Demo] Succeeded in loading the content. Data: %{public}s', JSON.stringify(data));
    });
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    console.log('[Demo] EntryAbility onWindowStageDestroy');
  }

  onForeground() {
    // Ability has brought to foreground
    console.log('[Demo] EntryAbility onForeground');
  }

  onBackground() {
    // Ability has back to background
    console.log('[Demo] EntryAbility onBackground');
  }
}
