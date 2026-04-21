/**
 * NotificationStateStore.ets — 通知状态持久化（preferences）
 *
 * 存储每个「accountId_roleUid_gameId」已调度的 reminderId 和 Recovery_Time 快照。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from 'core';
import { NotificationStateEntry } from './NotificationModels';

const TAG: string = 'NotificationStateStore';
const STORE_NAME: string = 'notification_state';

export class NotificationStateStore {
  private static _instance: NotificationStateStore | null = null;
  private pref: preferences.Preferences | null = null;

  static instance(): NotificationStateStore {
    if (NotificationStateStore._instance === null) {
      NotificationStateStore._instance = new NotificationStateStore();
    }
    return NotificationStateStore._instance as NotificationStateStore;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.pref = await preferences.getPreferences(context, STORE_NAME);
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.error(TAG, `init failed: ${msg}`);
    }
  }

  /** key 格式："{accountId}_{roleUid}_{gameId}" */
  async getEntry(key: string): Promise<NotificationStateEntry | null> {
    if (this.pref === null) {
      return null;
    }
    try {
      const reminderIdVal = await this.pref.get(`${key}_rid`, -1);
      const reminderId = reminderIdVal as number;
      if (reminderId < 0) {
        return null;
      }
      const entry = new NotificationStateEntry();
      entry.reminderId = reminderId;
      entry.recoveryTimeSnapshot = (await this.pref.get(`${key}_rt`, -1)) as number;
      entry.threshold = (await this.pref.get(`${key}_th`, 0)) as number;
      entry.scheduledAt = (await this.pref.get(`${key}_at`, 0)) as number;
      return entry;
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `getEntry(${key}) failed: ${msg}`);
      return null;
    }
  }

  async setEntry(key: string, entry: NotificationStateEntry): Promise<void> {
    if (this.pref === null) {
      return;
    }
    try {
      await this.pref.put(`${key}_rid`, entry.reminderId);
      await this.pref.put(`${key}_rt`, entry.recoveryTimeSnapshot);
      await this.pref.put(`${key}_th`, entry.threshold);
      await this.pref.put(`${key}_at`, entry.scheduledAt);
      await this.pref.flush();
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `setEntry(${key}) failed: ${msg}`);
    }
  }

  async removeEntry(key: string): Promise<void> {
    if (this.pref === null) {
      return;
    }
    try {
      await this.pref.delete(`${key}_rid`);
      await this.pref.delete(`${key}_rt`);
      await this.pref.delete(`${key}_th`);
      await this.pref.delete(`${key}_at`);
      await this.pref.flush();
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `removeEntry(${key}) failed: ${msg}`);
    }
  }

  async clear(): Promise<void> {
    if (this.pref === null) {
      return;
    }
    try {
      await this.pref.clear();
      await this.pref.flush();
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `clear failed: ${msg}`);
    }
  }
}
