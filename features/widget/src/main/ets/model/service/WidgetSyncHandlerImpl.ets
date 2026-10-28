/**
 * WidgetSyncHandlerImpl — WidgetSyncHook 的 widget 功能实现
 *
 * 由 EntryAbility.onCreate 注册（WidgetSyncHook.register）。
 * 逻辑原样迁自 StaminaNotificationService.init / onDailyNotesSynced 中推送卡片的部分；
 * 异常向上抛出，由调用方（StaminaNotificationService）原有的 try / catch 处理。
 */
import { common } from '@kit.AbilityKit';
import { CoreInitializer, Logger } from 'core';
import { WidgetSyncHandler } from 'basic';
import { WidgetDataBuilder } from './WidgetDataBuilder';
import { WidgetFormIdStore } from './WidgetFormIdStore';
import { WidgetDataStoreBuilder } from './WidgetDataStoreBuilder';

const TAG: string = 'WidgetSyncHandlerImpl';

export class WidgetSyncHandlerImpl implements WidgetSyncHandler {
  async init(context: common.UIAbilityContext): Promise<void> {
    // 初始化 WidgetFormIdStore，使主进程能够读取 formId 并推送卡片更新
    await WidgetFormIdStore.init(context);
  }

  async onDailyNotesSynced(context: common.UIAbilityContext | null): Promise<void> {
    // 先更新 Preferences 中的全局数据（供 EntryFormAbility 读取）
    Logger.info(TAG, '[WIDGET_DEBUG] onDailyNotesSynced: calling refreshAndSave');
    const refreshSuccess = await WidgetDataStoreBuilder.refreshAndSave(context !== null ? context : undefined);
    Logger.info(TAG, `[WIDGET_DEBUG] onDailyNotesSynced: refreshAndSave done, success=${refreshSuccess}`);

    const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
    Logger.info(TAG, `[WIDGET_DEBUG] onDailyNotesSynced: found ${accounts.length} accounts for push`);
    for (let ai = 0; ai < accounts.length; ai++) {
      const account = accounts[ai];
      // 推送 Widget 数据（先重新加载 formId 列表，确保读到最新数据）
      WidgetFormIdStore.init(context!, true).then(() => {
        WidgetDataBuilder.buildAndPushForAccount(account.uid).catch((e: Error | object) => {
          const msg = e instanceof Error ? e.message : `${e}`;
          Logger.warn(TAG, `widget push failed for ${account.uid}: ${msg}`);
        });
      }).catch((e: Error | object) => {
        const msg = e instanceof Error ? e.message : `${e}`;
        Logger.warn(TAG, `widget formId reload failed: ${msg}`);
      });
    }
  }
}
