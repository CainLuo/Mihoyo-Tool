/**
 * NotificationStateStore.ets — 通知状态持久化（preferences）
 *
 * 存储两类互相独立的记录：
 *   1. 每个「accountId_roleUid_gameId」已调度的代理提醒 reminderId 与 Recovery_Time 快照；
 *   2. 同一 key 的「即时通知已发送」标记（已通知的阈值 + 时间），用于阈值跨越去重。
 *
 * 两类记录分开存放：代理提醒条目的 `reminderId < 0` 表示「无有效调度」会被丢弃，
 * 不能拿来表达「已发过即时通知」。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from 'core';
import { NotificationStateEntry, NotifyMarker } from '../NotificationModels';

const TAG: string = 'NotificationStateStore';
const STORE_NAME: string = 'notification_state';

/** 从两项持久化值还原即时通知标记；threshold < 0 表示从未通知 */
export function decodeNotifyMarker(threshold: number, notifiedAt: number): NotifyMarker | null {
  if (threshold < 0) {
    return null;
  }
  const marker = new NotifyMarker();
  marker.threshold = threshold;
  marker.notifiedAt = notifiedAt;
  return marker;
}

/** 从四项持久化值还原状态；reminderId < 0 表示没有有效调度 */
export function decodeStateEntry(
  reminderIdVal: number,
  recoveryTimeSnapshot: number,
  threshold: number,
  scheduledAt: number
): NotificationStateEntry | null {
  if (reminderIdVal < 0) {
    return null;
  }
  const entry = new NotificationStateEntry();
  entry.reminderId = reminderIdVal;
  entry.recoveryTimeSnapshot = recoveryTimeSnapshot;
  entry.threshold = threshold;
  entry.scheduledAt = scheduledAt;
  return entry;
}

export class NotificationStateStore {
  private static _instance: NotificationStateStore | null = null;
  private pref: preferences.Preferences | null = null;

  static getInstance(): NotificationStateStore {
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
      const recoveryTimeSnapshot = (await this.pref.get(`${key}_rt`, -1)) as number;
      const threshold = (await this.pref.get(`${key}_th`, 0)) as number;
      const scheduledAt = (await this.pref.get(`${key}_at`, 0)) as number;
      return decodeStateEntry(reminderId, recoveryTimeSnapshot, threshold, scheduledAt);
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
      await this.pref.delete(`${key}_nth`);
      await this.pref.delete(`${key}_nat`);
      await this.pref.flush();
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `removeEntry(${key}) failed: ${msg}`);
    }
  }

  /** 读取「即时通知已发送」标记；从未通知过返回 null */
  async getNotifyMarker(key: string): Promise<NotifyMarker | null> {
    if (this.pref === null) {
      return null;
    }
    try {
      const threshold = (await this.pref.get(`${key}_nth`, -1)) as number;
      const notifiedAt = (await this.pref.get(`${key}_nat`, 0)) as number;
      return decodeNotifyMarker(threshold, notifiedAt);
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `getNotifyMarker(${key}) failed: ${msg}`);
      return null;
    }
  }

  /** 记录「已按 threshold 发送即时通知」 */
  async setNotifyMarker(key: string, threshold: number): Promise<void> {
    if (this.pref === null) {
      return;
    }
    try {
      await this.pref.put(`${key}_nth`, threshold);
      await this.pref.put(`${key}_nat`, Math.floor(Date.now() / 1000));
      await this.pref.flush();
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `setNotifyMarker(${key}) failed: ${msg}`);
    }
  }

  /** 清除「即时通知已发送」标记（体力回落到阈值以下时调用） */
  async clearNotifyMarker(key: string): Promise<void> {
    if (this.pref === null) {
      return;
    }
    try {
      await this.pref.delete(`${key}_nth`);
      await this.pref.delete(`${key}_nat`);
      await this.pref.flush();
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `clearNotifyMarker(${key}) failed: ${msg}`);
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
