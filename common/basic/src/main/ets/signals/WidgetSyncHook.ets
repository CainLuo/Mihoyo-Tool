/**
 * WidgetSyncHook — 便笺同步完成后推送服务卡片的回调登记点
 *
 * notification 功能需要在便笺同步后刷新服务卡片，但不能直接依赖 widget 功能（会形成循环依赖）。
 * 由 widget 功能实现 WidgetSyncHandler，应用启动时在 EntryAbility.onCreate 中注册；
 * notification 只调用本类，不 import widget。
 */
import { common } from '@kit.AbilityKit';
import { Logger } from 'core';

const TAG: string = 'WidgetSyncHook';

export interface WidgetSyncHandler {
  /** 便笺同步完成后刷新卡片数据并推送 */
  onDailyNotesSynced(context: common.UIAbilityContext | null): Promise<void>;
}

export class WidgetSyncHook {
  private static handler: WidgetSyncHandler | null = null;

  /** 由 EntryAbility.onCreate 注册 widget 功能的实现 */
  static register(handler: WidgetSyncHandler): void {
    WidgetSyncHook.handler = handler;
  }

  static async onDailyNotesSynced(context: common.UIAbilityContext | null): Promise<void> {
    if (WidgetSyncHook.handler === null) {
      Logger.warn(TAG, 'onDailyNotesSynced skipped: no handler registered');
      return;
    }
    await WidgetSyncHook.handler.onDailyNotesSynced(context);
  }
}
