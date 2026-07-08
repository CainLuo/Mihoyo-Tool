/**
 * StaminaNotificationService.ets — 通知调度核心服务（单例）
 *
 * 使用 reminderAgentManager（@kit.BackgroundTasksKit）注册系统级代理提醒，
 * App 被杀后时间到了系统仍会自动弹出通知。
 */
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { wantAgent } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CoreInitializer, Logger, GameId, GenshinDailyNoteParser, StarRailDailyNoteParser, ZZZDailyNoteParser } from 'core';
import { StaminaThresholdCalculator } from './StaminaThresholdCalculator';
import { NotificationSettingsStore } from './NotificationSettingsStore';
import { NotificationStateStore } from './NotificationStateStore';
import { NotificationStateEntry, NotificationStyle, GameStaminaConstants } from './NotificationModels';
import { WidgetDataBuilder } from '../widget/utils/WidgetDataBuilder';
import { WidgetFormIdStore } from '../widget/utils/WidgetFormIdStore';
import { WidgetDataStoreBuilder } from '../widget/utils/WidgetDataStoreBuilder';

const TAG: string = 'StaminaNotificationService';
const BUNDLE_NAME: string = 'com.cainluo.miyoyo.tools';
const ABILITY_NAME: string = 'EntryAbility';

/** 内部用于传递 Recovery_Time 数据的类（替代匿名对象类型） */
class RecoveryData {
  recoveryTime: number = 0;
  maxStamina: number = 0;
  currentStamina: number = 0;
}

/** STYLE_B 合并通知用的条目数据 */
class MergedNotificationEntry {
  key: string = '';
  gameName: string = '';
  displayName: string = '';
  staminaName: string = '';
  currentStamina: number = 0;
  maxStamina: number = 0;
  recoveryTimeSnapshot: number = 0;
  threshold: number = 0;
  delaySeconds: number = 0;
}

export class StaminaNotificationService {
  private static _instance: StaminaNotificationService | null = null;
  private context: common.UIAbilityContext | null = null;

  static instance(): StaminaNotificationService {
    if (StaminaNotificationService._instance === null) {
      StaminaNotificationService._instance = new StaminaNotificationService();
    }
    return StaminaNotificationService._instance as StaminaNotificationService;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    await NotificationSettingsStore.instance().init(context);
    await NotificationStateStore.instance().init(context);
    // 初始化 WidgetFormIdStore，使主进程能够读取 formId 并推送卡片更新
    await WidgetFormIdStore.init(context);
    Logger.info(TAG, 'init done');
  }

  async requestPermission(): Promise<boolean> {
    try {
      await notificationManager.requestEnableNotification(this.context!);
      return await this.checkPermission();
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `requestPermission failed: ${msg}`);
      return false;
    }
  }

  async checkPermission(): Promise<boolean> {
    try {
      return await notificationManager.isNotificationEnabled();
    } catch (_) {
      return false;
    }
  }

  /** 获取当前已注册的代理提醒数量 */
  async getReminderCount(): Promise<number> {
    try {
      const reminders = await reminderAgentManager.getValidReminders();
      return reminders.length;
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `getReminderCount failed: ${msg}`);
      return 0;
    }
  }

  async onDailyNotesSynced(): Promise<void> {
    Logger.info(TAG, '[WIDGET_DEBUG] onDailyNotesSynced: start');
    // Widget 数据推送不依赖通知设置，始终执行
    try {
      // 先更新 Preferences 中的全局数据（供 EntryFormAbility 读取）
      Logger.info(TAG, '[WIDGET_DEBUG] onDailyNotesSynced: calling refreshAndSave');
      const ctx = this.context;
      const refreshSuccess = await WidgetDataStoreBuilder.refreshAndSave(ctx !== null ? ctx : undefined);
      Logger.info(TAG, `[WIDGET_DEBUG] onDailyNotesSynced: refreshAndSave done, success=${refreshSuccess}`);

      const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
      Logger.info(TAG, `[WIDGET_DEBUG] onDailyNotesSynced: found ${accounts.length} accounts for push`);
      for (let ai = 0; ai < accounts.length; ai++) {
        const account = accounts[ai];
        // 推送 Widget 数据（先重新加载 formId 列表，确保读到最新数据）
        WidgetFormIdStore.init(this.context!, true).then(() => {
          WidgetDataBuilder.buildAndPushForAccount(account.uid).catch((e: Error | object) => {
            const msg = e instanceof Error ? e.message : `${e}`;
            Logger.warn(TAG, `widget push failed for ${account.uid}: ${msg}`);
          });
        }).catch((e: Error | object) => {
          const msg = e instanceof Error ? e.message : `${e}`;
          Logger.warn(TAG, `widget formId reload failed: ${msg}`);
        });
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `[WIDGET_DEBUG] onDailyNotesSynced failed: ${msg}`);
    }

    // 通知调度依赖通知设置，检查后执行
    const globalSettings = await NotificationSettingsStore.instance().loadGlobal();
    if (!globalSettings.enabled) {
      return;
    }
    const hasPermission = await this.checkPermission();
    if (!hasPermission) {
      return;
    }

    // STYLE_B：收集所有需要即时通知的条目
    const mergedEntries: MergedNotificationEntry[] = [];

    try {
      const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
      for (let ai = 0; ai < accounts.length; ai++) {
        const account = accounts[ai];
        const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
        for (let ri = 0; ri < roles.length; ri++) {
          const role = roles[ri];
          const nickname = account.nickname.length > 0 ? account.nickname : account.username;

          if (globalSettings.style === NotificationStyle.STYLE_B) {
            // STYLE_B：收集条目
            const entry = await this.buildMergedEntry(
              account.uid, nickname, role.roleId, role.gameId,
              role.nickname, role.server,
            );
            if (entry === null) {
              continue;
            }
            if (entry.delaySeconds <= 0) {
              // 已到达阈值：收集到合并列表
              mergedEntries.push(entry);
            } else {
              // 未到达阈值：发布代理提醒，到期后触发合并通知
              await this.scheduleMergedReminder(entry);
            }
          } else {
            // STYLE_A：独立发布
            await this.checkAndSchedule(
              account.uid, nickname, role.roleId, role.gameId,
              role.nickname, role.server,
            );
          }
        }
      }

      // STYLE_B：发布合并通知
      if (globalSettings.style === NotificationStyle.STYLE_B && mergedEntries.length > 0) {
        await this.publishMergedNotification(mergedEntries, globalSettings.style);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `onDailyNotesSynced failed: ${msg}`);
    }
  }

  async cancelAll(): Promise<void> {
    try {
      // 取消系统中注册的所有代理提醒
      await reminderAgentManager.cancelAllReminders();
      // 清除本地状态
      await NotificationStateStore.instance().clear();
      Logger.info(TAG, 'cancelAll done');
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `cancelAll failed: ${msg}`);
    }
  }

  async cancelByAccountGame(accountId: string, gameId: GameId): Promise<void> {
    try {
      const roles = await CoreInitializer.bbsRepository.getGameRoles(accountId);
      for (let ri = 0; ri < roles.length; ri++) {
        const role = roles[ri];
        if (role.gameId !== gameId) {
          continue;
        }
        const key = `${accountId}_${role.roleId}_${gameId}`;
        const entry = await NotificationStateStore.instance().getEntry(key);
        if (entry !== null && entry.reminderId >= 0) {
          try {
            await reminderAgentManager.cancelReminder(entry.reminderId);
          } catch (_) {}
          await NotificationStateStore.instance().removeEntry(key);
        }
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `cancelByAccountGame failed: ${msg}`);
    }
  }

  /**
   * STYLE_B：构建合并通知用的条目数据
   * 
   * 返回 null 表示不需要通知（数据不足或已禁用）
   */
  private async buildMergedEntry(
    accountId: string,
    accountNickname: string,
    roleUid: string,
    gameId: GameId,
    roleNickname: string,
    _server: string,
  ): Promise<MergedNotificationEntry | null> {
    const noteData = await this.loadRecoveryData(accountId, roleUid, gameId);
    if (noteData === null) {
      return null;
    }
    const recoveryTime = noteData.recoveryTime;
    const maxStamina = noteData.maxStamina;
    const currentStamina = noteData.currentStamina;

    // 传入 maxStamina，首次使用时默认阈值 = maxStamina × 80%
    const gameSetting = await NotificationSettingsStore.instance().loadGameSetting(accountId, gameId, maxStamina);
    if (!gameSetting.enabled) {
      return null;
    }
    const threshold = StaminaThresholdCalculator.clampThreshold(gameSetting.threshold, maxStamina);
    const secondsPerUnit = StaminaNotificationService.secondsPerUnit(gameId);

    const key = `${accountId}_${roleUid}_${gameId}`;
    const existingEntry = await NotificationStateStore.instance().getEntry(key);

    // 如果已有调度且未过期，跳过
    if (existingEntry !== null && existingEntry.reminderId >= 0) {
      try {
        await reminderAgentManager.cancelReminder(existingEntry.reminderId);
      } catch (_) {}
      await NotificationStateStore.instance().removeEntry(key);
    }

    const delaySeconds = StaminaThresholdCalculator.calcDelaySeconds(
      recoveryTime, threshold, maxStamina, secondsPerUnit
    );

    const staminaName = this.staminaName(gameId);
    const gameName = this.gameName(gameId);
    const displayName = roleNickname.length > 0 ? roleNickname : accountNickname;

    const entry = new MergedNotificationEntry();
    entry.key = key;
    entry.gameName = gameName;
    entry.displayName = displayName;
    entry.staminaName = staminaName;
    entry.currentStamina = currentStamina;
    entry.maxStamina = maxStamina;
    entry.recoveryTimeSnapshot = recoveryTime;
    entry.threshold = threshold;
    entry.delaySeconds = delaySeconds;

    return entry;
  }

  /**
   * STYLE_B：发布合并的多行文本通知
   * 
   * 收集所有角色的通知数据，合并为一条多行文本通知。
   * 每个角色一行，格式："游戏名 · 昵称：体力名 120/200"
   */
  private async publishMergedNotification(
    entries: MergedNotificationEntry[],
    _style: NotificationStyle,
  ): Promise<void> {
    if (entries.length === 0) {
      return;
    }

    try {
      // 构建多行文本内容
      const lines: string[] = [];
      for (let i = 0; i < entries.length; i++) {
        const entry = entries[i];
        lines.push(`${entry.gameName} · ${entry.displayName}：${entry.staminaName} ${entry.currentStamina}/${entry.maxStamina}`);
      }

      // 使用固定 ID 发布合并通知
      const notifId = StaminaNotificationService.hashNotifId('merged_stamina_notification');

      // 构建点击通知后启动 App 的 WantAgent
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [{
          bundleName: BUNDLE_NAME,
          abilityName: ABILITY_NAME,
        }],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: notifId,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      };
      const wa = await wantAgent.getWantAgent(wantAgentInfo);

      // 多行文本通知内容
      const multiLineContent: notificationManager.NotificationMultiLineContent = {
        title: '体力提醒',
        text: `共 ${entries.length} 个角色体力已达标`,
        briefText: `${entries.length} 个角色`,
        longTitle: '体力提醒',
        lines: lines,
      };
      const content: notificationManager.NotificationContent = {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_MULTILINE,
        multiLine: multiLineContent,
      };
      const request: notificationManager.NotificationRequest = {
        id: notifId,
        content: content,
        wantAgent: wa,
      };
      await notificationManager.publish(request);

      // 更新所有条目的状态
      const now = Math.floor(Date.now() / 1000);
      for (let i = 0; i < entries.length; i++) {
        const entry = entries[i];
        const stateEntry = new NotificationStateEntry();
        stateEntry.reminderId = -1;
        stateEntry.recoveryTimeSnapshot = entry.recoveryTimeSnapshot;
        stateEntry.threshold = entry.threshold;
        stateEntry.scheduledAt = now;
        await NotificationStateStore.instance().setEntry(entry.key, stateEntry);
      }
      Logger.info(TAG, `merged notification sent for ${entries.length} roles`);
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `publishMergedNotification failed: ${msg}`);
    }
  }

  /**
   * STYLE_B：为单个角色发布代理提醒
   * 
   * 代理提醒到期后，系统会唤醒 App，App 启动时会调用 onDailyNotesSynced()
   * 重新检查所有角色状态并发布合并通知。
   */
  private async scheduleMergedReminder(entry: MergedNotificationEntry): Promise<void> {
    try {
      const count = await this.getReminderCount();
      if (count >= GameStaminaConstants.REMINDER_LIMIT) {
        Logger.warn(TAG, `reminder limit reached (${count}/${GameStaminaConstants.REMINDER_LIMIT}), skip: ${entry.key}`);
        return;
      }

      const notifId = StaminaNotificationService.hashNotifId(entry.key);
      const wa: reminderAgentManager.WantAgent = {
        pkgName: BUNDLE_NAME,
        abilityName: ABILITY_NAME,
      };
      const closeBtn: reminderAgentManager.ActionButton = {
        title: '关闭',
        type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
      };

      // 提醒标题和内容使用单角色格式
      const title = `${entry.gameName} · ${entry.displayName}`;
      const body = `${entry.staminaName}已达阈值 ${entry.threshold}/${entry.maxStamina}`;

      const reminder: reminderAgentManager.ReminderRequestTimer = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
        triggerTimeInSeconds: entry.delaySeconds,
        title: title,
        content: body,
        expiredContent: body,
        notificationId: notifId,
        slotType: notificationManager.SlotType.SERVICE_INFORMATION,
        wantAgent: wa,
        actionButton: [closeBtn],
      };

      Logger.info(TAG, `scheduleMergedReminder: publishing reminder for ${entry.key}, delay=${entry.delaySeconds}s, current count=${count}`);
      const reminderId = await reminderAgentManager.publishReminder(reminder);
      Logger.info(TAG, `scheduleMergedReminder: SUCCESS, reminderId=${reminderId} for ${entry.key}`);

      const stateEntry = new NotificationStateEntry();
      stateEntry.reminderId = reminderId;
      stateEntry.recoveryTimeSnapshot = entry.recoveryTimeSnapshot;
      stateEntry.threshold = entry.threshold;
      stateEntry.scheduledAt = Math.floor(Date.now() / 1000);
      await NotificationStateStore.instance().setEntry(entry.key, stateEntry);
    } catch (e) {
      const err = e as BusinessError;
      const code: number = err.code !== undefined ? err.code : -1;
      const msg: string = err.message !== undefined ? err.message : `${e}`;
      Logger.error(TAG, `scheduleMergedReminder FAILED for ${entry.key}: code=${code} msg=${msg}`);
    }
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  /** STYLE_A：独立发布每个角色的通知 */
  private async checkAndSchedule(
    accountId: string,
    accountNickname: string,
    roleUid: string,
    gameId: GameId,
    roleNickname: string,
    server: string,
  ): Promise<void> {
    const noteData = await this.loadRecoveryData(accountId, roleUid, gameId);
    if (noteData === null) {
      return;
    }
    const recoveryTime = noteData.recoveryTime;
    const maxStamina = noteData.maxStamina;
    const currentStamina = noteData.currentStamina;

    // 传入 maxStamina，首次使用时默认阈值 = maxStamina × 80%
    const gameSetting = await NotificationSettingsStore.instance().loadGameSetting(accountId, gameId, maxStamina);
    if (!gameSetting.enabled) {
      return;
    }
    const threshold = StaminaThresholdCalculator.clampThreshold(gameSetting.threshold, maxStamina);
    const secondsPerUnit = StaminaNotificationService.secondsPerUnit(gameId);

    const key = `${accountId}_${roleUid}_${gameId}`;
    const existingEntry = await NotificationStateStore.instance().getEntry(key);

    // if (existingEntry !== null &&
    //     !StaminaThresholdCalculator.shouldReschedule(existingEntry.recoveryTimeSnapshot, recoveryTime)) {
    //   return;
    // }
    if (existingEntry !== null && existingEntry.reminderId >= 0) {
      try {
        await reminderAgentManager.cancelReminder(existingEntry.reminderId);
      } catch (_) {}
      await NotificationStateStore.instance().removeEntry(key);
    }

    const delaySeconds = StaminaThresholdCalculator.calcDelaySeconds(
      recoveryTime, threshold, maxStamina, secondsPerUnit
    );

    Logger.info(TAG, `checkAndSchedule: ${gameId}/${roleUid} recoveryTime=${recoveryTime} threshold=${threshold} maxStamina=${maxStamina} delaySeconds=${delaySeconds}`);

    const staminaName = this.staminaName(gameId);
    const gameName = this.gameName(gameId);
    const displayName = roleNickname.length > 0 ? roleNickname : accountNickname;
    const notifTitle = `${gameName} · ${displayName}`;
    const notifBody = `${staminaName}已达 ${currentStamina}/${maxStamina}，请及时消耗`;
    const notifSub = `${server} · UID ${roleUid}`;

    if (delaySeconds <= 0) {
      await this.publishImmediateNotification(notifTitle, notifBody, notifSub, key, recoveryTime, threshold);
    } else {
      await this.scheduleReminder(notifTitle, notifBody, delaySeconds, key, recoveryTime, threshold);
    }
  }

  private async publishImmediateNotification(
    title: string,
    body: string,
    sub: string,
    key: string,
    recoveryTimeSnapshot: number,
    threshold: number,
  ): Promise<void> {
    try {
      const notifId = StaminaNotificationService.hashNotifId(key);

      // 构建点击通知后启动 App 的 WantAgent
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [{
          bundleName: BUNDLE_NAME,
          abilityName: ABILITY_NAME,
        }],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: notifId,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      };
      const wa = await wantAgent.getWantAgent(wantAgentInfo);

      const basicContent: notificationManager.NotificationBasicContent = {
        title: title,
        text: body,
        additionalText: sub,
      };
      const content: notificationManager.NotificationContent = {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: basicContent,
      };
      const request: notificationManager.NotificationRequest = {
        id: notifId,
        content: content,
        wantAgent: wa,
      };
      await notificationManager.publish(request);

      const entry = new NotificationStateEntry();
      entry.reminderId = -1;
      entry.recoveryTimeSnapshot = recoveryTimeSnapshot;
      entry.threshold = threshold;
      entry.scheduledAt = Math.floor(Date.now() / 1000);
      await NotificationStateStore.instance().setEntry(key, entry);
      Logger.info(TAG, `immediate notification sent: ${key}`);
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `publishImmediateNotification failed: ${msg}`);
    }
  }

  private async scheduleReminder(
    title: string,
    body: string,
    delaySeconds: number,
    key: string,
    recoveryTimeSnapshot: number,
    threshold: number,
  ): Promise<void> {
    try {
      const count = await this.getReminderCount();
      if (count >= GameStaminaConstants.REMINDER_LIMIT) {
        Logger.warn(TAG, `reminder limit reached (${count}/${GameStaminaConstants.REMINDER_LIMIT}), skip: ${key}`);
        return;
      }

      const notifId = StaminaNotificationService.hashNotifId(key);
      const wa: reminderAgentManager.WantAgent = {
        pkgName: BUNDLE_NAME,
        abilityName: ABILITY_NAME,
      };
      const closeBtn: reminderAgentManager.ActionButton = {
        title: '关闭',
        type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
      };
      const reminder: reminderAgentManager.ReminderRequestTimer = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
        triggerTimeInSeconds: delaySeconds,
        title: title,
        content: body,
        expiredContent: body,
        notificationId: notifId,
        slotType: notificationManager.SlotType.SERVICE_INFORMATION,
        wantAgent: wa,
        actionButton: [closeBtn],
      };

      Logger.info(TAG, `scheduleReminder: publishing reminder for ${key}, delay=${delaySeconds}s, current count=${count}`);
      const reminderId = await reminderAgentManager.publishReminder(reminder);
      Logger.info(TAG, `scheduleReminder: SUCCESS, reminderId=${reminderId} for ${key}`);

      const entry = new NotificationStateEntry();
      entry.reminderId = reminderId;
      entry.recoveryTimeSnapshot = recoveryTimeSnapshot;
      entry.threshold = threshold;
      entry.scheduledAt = Math.floor(Date.now() / 1000);
      await NotificationStateStore.instance().setEntry(key, entry);
    } catch (e) {
      const err = e as BusinessError;
      const code: number = err.code !== undefined ? err.code : -1;
      const msg: string = err.message !== undefined ? err.message : `${e}`;
      Logger.error(TAG, `scheduleReminder FAILED for ${key}: code=${code} msg=${msg}`);
    }
  }

  private async loadRecoveryData(
    accountId: string,
    roleUid: string,
    gameId: GameId,
  ): Promise<RecoveryData | null> {
    try {
      if (gameId === GameId.GENSHIN) {
        const row = await CoreInitializer.genshinRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = GenshinDailyNoteParser.parse(row.rawJson);
        const maxResin = data.maxResin > 0 ? data.maxResin : row.maxResin;
        const result = new RecoveryData();
        result.recoveryTime = StaminaThresholdCalculator.parseGenshinRecoveryTime(data.resinRecoveryTime);
        result.maxStamina = maxResin > 0 ? maxResin : GameStaminaConstants.GENSHIN_MAX_FALLBACK;
        result.currentStamina = data.currentResin;
        return result;
      }
      if (gameId === GameId.STARRAIL) {
        const row = await CoreInitializer.starRailRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = StarRailDailyNoteParser.parse(row.rawJson);
        const maxStamina = data.maxStamina > 0 ? data.maxStamina : row.maxStamina;
        const result = new RecoveryData();
        result.recoveryTime = data.staminaRecoverTime;
        result.maxStamina = maxStamina > 0 ? maxStamina : GameStaminaConstants.STARRAIL_MAX_FALLBACK;
        result.currentStamina = data.currentStamina > 0 ? data.currentStamina : row.currentStamina;
        return result;
      }
      if (gameId === GameId.ZZZ) {
        const row = await CoreInitializer.zzzRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = ZZZDailyNoteParser.parse(row.rawJson);
        const maxEnergy = data.maxEnergy > 0 ? data.maxEnergy : row.energyMax;
        const result = new RecoveryData();
        result.recoveryTime = data.energyRecoverTime;
        result.maxStamina = maxEnergy > 0 ? maxEnergy : GameStaminaConstants.ZZZ_MAX_FALLBACK;
        result.currentStamina = data.currentEnergy > 0 ? data.currentEnergy : row.energyCurrent;
        return result;
      }
      return null;
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `loadRecoveryData failed for ${gameId}/${roleUid}: ${msg}`);
      return null;
    }
  }

  private static secondsPerUnit(gameId: GameId): number {
    if (gameId === GameId.GENSHIN) {
      return GameStaminaConstants.GENSHIN_SECONDS_PER_UNIT;
    }
    if (gameId === GameId.STARRAIL) {
      return GameStaminaConstants.STARRAIL_SECONDS_PER_UNIT;
    }
    return GameStaminaConstants.ZZZ_SECONDS_PER_UNIT;
  }

  private staminaName(gameId: GameId): string {
    const fallbackName = (gId: GameId): string => {
      if (gId === GameId.GENSHIN) return 'Resin';
      if (gId === GameId.STARRAIL) return 'Trailblaze Power';
      return 'Battery';
    };
    
    try {
      if (gameId === GameId.GENSHIN) {
        return this.context?.resourceManager.getStringByNameSync('notification_stamina_genshin') ?? fallbackName(gameId);
      }
      if (gameId === GameId.STARRAIL) {
        return this.context?.resourceManager.getStringByNameSync('notification_stamina_starrail') ?? fallbackName(gameId);
      }
      return this.context?.resourceManager.getStringByNameSync('notification_stamina_zzz') ?? fallbackName(gameId);
    } catch (e) {
      return fallbackName(gameId);
    }
  }

  private gameName(gameId: GameId): string {
    const fallbackName = (gId: GameId): string => {
      if (gId === GameId.GENSHIN) return 'Genshin Impact';
      if (gId === GameId.STARRAIL) return 'Honkai: Star Rail';
      return 'Zenless Zone Zero';
    };
    
    try {
      if (gameId === GameId.GENSHIN) {
        return this.context?.resourceManager.getStringByNameSync('game_name_genshin') ?? fallbackName(gameId);
      }
      if (gameId === GameId.STARRAIL) {
        return this.context?.resourceManager.getStringByNameSync('game_name_starrail') ?? fallbackName(gameId);
      }
      return this.context?.resourceManager.getStringByNameSync('game_name_zzz') ?? fallbackName(gameId);
    } catch (e) {
      return fallbackName(gameId);
    }
  }

  private static hashNotifId(key: string): number {
    let hash = 0;
    for (let i = 0; i < key.length; i++) {
      hash = (hash * 31 + key.charCodeAt(i)) & 0x7fffffff;
    }
    return (hash % 100000) + 10000;
  }
}
