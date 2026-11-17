/**
 * WidgetSyncHandlerImpl — WidgetSyncHook 的 widget 功能实现
 *
 * 由 EntryAbility.onCreate 注册（WidgetSyncHook.register）。
 * 逻辑原样迁自 StaminaNotificationService.onDailyNotesSynced 中推送卡片的部分；
 * 异常向上抛出，由调用方（StaminaNotificationService）原有的 try / catch 处理。
 */
import { common } from '@kit.AbilityKit';
import { Logger } from 'core';
import { WidgetSyncHandler } from 'basic';
import { WidgetDataStoreBuilder } from './WidgetDataStoreBuilder';

const TAG: string = 'WidgetSyncHandlerImpl';

export class WidgetSyncHandlerImpl implements WidgetSyncHandler {
  async onDailyNotesSynced(context: common.UIAbilityContext | null): Promise<void> {
    // 更新 Preferences 中的全局数据（供 EntryFormAbility 读取）并推送卡片
    Logger.info(TAG, '[WIDGET_DEBUG] onDailyNotesSynced: calling refreshAndSave');
    const refreshSuccess = await WidgetDataStoreBuilder.refreshAndSave(context !== null ? context : undefined);
    Logger.info(TAG, `[WIDGET_DEBUG] onDailyNotesSynced: refreshAndSave done, success=${refreshSuccess}`);
  }
}
