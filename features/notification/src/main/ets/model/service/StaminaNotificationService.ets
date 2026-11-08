/**
 * StaminaNotificationService.ets — 通知调度核心服务（单例）
 *
 * 使用 reminderAgentManager（@kit.BackgroundTasksKit）注册系统级代理提醒，
 * App 被杀后时间到了系统仍会自动弹出通知。
 *
 * STYLE_A（单角色通知）与 STYLE_B（合并通知）共用同一套调度数据：
 *   读 daily_note → 读游戏设置 → clamp 阈值 → 取消旧提醒 → 计算延迟 → 发布。
 * 两种样式的差异只在最终通知的呈现方式。
 */
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { wantAgent, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CoreInitializer, Logger, GameId } from 'core';
import { StaminaThresholdCalculator } from './StaminaThresholdCalculator';
import { NotificationSettingsStore } from './NotificationSettingsStore';
import { NotificationStateStore } from './NotificationStateStore';
import { StaminaNoteReader } from './StaminaNoteReader';
import {
  NotificationStateEntry,
  NotificationStyle,
  GameStaminaConstants,
  GameStaminaResources,
} from '../NotificationModels';
import { WidgetSyncHook } from 'basic';

const TAG: string = 'StaminaNotificationService';
const ABILITY_NAME: string = 'EntryAbility';

/** 单个角色的提醒调度数据（STYLE_A / STYLE_B 共用） */
class StaminaSchedule {
  /** 状态存储 key：{accountId}_{roleUid}_{gameId} */
  key: string = '';
  gameId: GameId = GameId.GENSHIN;
  gameName: string = '';
  /** 优先角色昵称，没有则用账号昵称 */
  displayName: string = '';
  staminaName: string = '';
  server: string = '';
  roleUid: string = '';
  currentStamina: number = 0;
  maxStamina: number = 0;
  /** 调度时的 Recovery_Time 快照（秒） */
  recoveryTimeSnapshot: number = 0;
  threshold: number = 0;
  /** ≤ 0 表示当前已达到阈值，应立即通知 */
  delaySeconds: number = 0;
}

export class StaminaNotificationService {
  private static _instance: StaminaNotificationService | null = null;
  private context: common.UIAbilityContext | null = null;

  /**
   * 当前应用包名。
   * 从 ability context 读取，避免 uat / mock 包的通知点击后跳到正式包。
   */
  private get bundleName(): string {
    const ctx = this.context;
    return ctx !== null ? ctx.abilityInfo.bundleName : '';
  }

  static getInstance(): StaminaNotificationService {
    if (StaminaNotificationService._instance === null) {
      StaminaNotificationService._instance = new StaminaNotificationService();
    }
    return StaminaNotificationService._instance as StaminaNotificationService;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    await NotificationSettingsStore.getInstance().init(context);
    await NotificationStateStore.getInstance().init(context);
    // 初始化卡片推送（WidgetFormIdStore 等），实现由 widget 功能在 EntryAbility 中注册
    await WidgetSyncHook.init(context);
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
      // 刷新卡片数据并推送（实现见 features/widget/utils/WidgetSyncHandlerImpl）
      await WidgetSyncHook.onDailyNotesSynced(this.context);
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `[WIDGET_DEBUG] onDailyNotesSynced failed: ${msg}`);
    }

    // 通知调度依赖通知设置，检查后执行
    const globalSettings = await NotificationSettingsStore.getInstance().loadGlobal();
    if (!globalSettings.isEnabled) {
      return;
    }
    const hasPermission = await this.checkPermission();
    if (!hasPermission) {
      return;
    }

    const isMergedStyle = globalSettings.style === NotificationStyle.STYLE_B;
    const mergedSchedules: StaminaSchedule[] = [];

    try {
      const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
      for (const account of accounts) {
        const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
        const accountNickname = account.nickname.length > 0 ? account.nickname : account.username;

        for (const role of roles) {
          const schedule = await this.resolveSchedule(
            account.uid, accountNickname, role.roleId, role.gameId,
            role.nickname, role.server,
          );
          if (schedule === null) {
            continue;
          }

          if (isMergedStyle) {
            if (schedule.delaySeconds <= 0) {
              // 已到达阈值：收集到合并列表
              mergedSchedules.push(schedule);
            } else {
              // 未到达阈值：发布代理提醒，到期后触发合并通知
              await this.publishTimerReminder(
                schedule,
                `${schedule.staminaName}已达阈值 ${schedule.threshold}/${schedule.maxStamina}`,
              );
            }
          } else {
            await this.dispatchImmediateOrTimer(schedule);
          }
        }
      }

      // STYLE_B：发布合并通知
      if (isMergedStyle && mergedSchedules.length > 0) {
        await this.publishMergedNotification(mergedSchedules);
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
      await NotificationStateStore.getInstance().clear();
      Logger.info(TAG, 'cancelAll done');
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `cancelAll failed: ${msg}`);
    }
  }

  async cancelByAccountGame(accountId: string, gameId: GameId): Promise<void> {
    try {
      const roles = await CoreInitializer.bbsRepository.getGameRoles(accountId);
      for (const role of roles) {
        if (role.gameId !== gameId) {
          continue;
        }
        const key = `${accountId}_${role.roleId}_${gameId}`;
        await this.cancelExistingReminder(key);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `cancelByAccountGame failed: ${msg}`);
    }
  }

  // ─── 调度数据 ────────────────────────────────────────────────

  /**
   * 组装单个角色的调度数据（两种样式共用）。
   * 返回 null 表示无需通知（无 daily_note、游戏开关关闭）。
   */
  private async resolveSchedule(
    accountId: string,
    accountNickname: string,
    roleUid: string,
    gameId: GameId,
    roleNickname: string,
    server: string,
  ): Promise<StaminaSchedule | null> {
    const snapshot = await StaminaNoteReader.read(accountId, roleUid, gameId);
    if (snapshot === null) {
      return null;
    }

    // 服务层需要 fallback 上限，避免 DB 无数据时无法计算阈值
    const maxStamina = snapshot.maxStamina > 0
      ? snapshot.maxStamina
      : GameStaminaConstants.getFallbackMax(gameId);

    // 传入 maxStamina，首次使用时默认阈值 = maxStamina × 80%
    const gameSetting = await NotificationSettingsStore.getInstance().loadGameSetting(accountId, gameId, maxStamina);
    if (!gameSetting.isEnabled) {
      return null;
    }
    const threshold = StaminaThresholdCalculator.clampThreshold(gameSetting.threshold, maxStamina);

    const key = `${accountId}_${roleUid}_${gameId}`;
    await this.cancelExistingReminder(key);

    const delaySeconds = StaminaThresholdCalculator.calcDelaySeconds(
      snapshot.recoveryTime, threshold, maxStamina, GameStaminaConstants.getSecondsPerUnit(gameId),
    );

    const schedule = new StaminaSchedule();
    schedule.key = key;
    schedule.gameId = gameId;
    schedule.gameName = this.getGameName(gameId);
    schedule.displayName = roleNickname.length > 0 ? roleNickname : accountNickname;
    schedule.staminaName = this.getStaminaName(gameId);
    schedule.server = server;
    schedule.roleUid = roleUid;
    schedule.currentStamina = snapshot.currentStamina;
    schedule.maxStamina = maxStamina;
    schedule.recoveryTimeSnapshot = snapshot.recoveryTime;
    schedule.threshold = threshold;
    schedule.delaySeconds = delaySeconds;
    return schedule;
  }

  /** 取消该 key 已注册的旧提醒并清除状态 */
  private async cancelExistingReminder(key: string): Promise<void> {
    const existingEntry = await NotificationStateStore.getInstance().getEntry(key);
    if (existingEntry !== null && existingEntry.reminderId >= 0) {
      try {
        await reminderAgentManager.cancelReminder(existingEntry.reminderId);
      } catch (e) {
        const msg = e instanceof Error ? e.message : `${e}`;
        Logger.warn(TAG, `cancelReminder failed for ${key}: ${msg}`);
      }
      await NotificationStateStore.getInstance().removeEntry(key);
    }
  }

  /** STYLE_A：已达标立即通知，否则注册代理提醒 */
  private async dispatchImmediateOrTimer(schedule: StaminaSchedule): Promise<void> {
    Logger.info(
      TAG,
      `checkAndSchedule: ${schedule.gameId}/${schedule.roleUid} ` +
      `recoveryTime=${schedule.recoveryTimeSnapshot} threshold=${schedule.threshold} ` +
      `maxStamina=${schedule.maxStamina} delaySeconds=${schedule.delaySeconds}`,
    );

    if (schedule.delaySeconds <= 0) {
      const title = `${schedule.gameName} · ${schedule.displayName}`;
      const body = `${schedule.staminaName}已达 ${schedule.currentStamina}/${schedule.maxStamina}，请及时消耗`;
      const sub = `${schedule.server} · UID ${schedule.roleUid}`;
      await this.publishImmediateNotification(schedule, title, body, sub);
    } else {
      await this.publishTimerReminder(
        schedule,
        `${schedule.staminaName}已达 ${schedule.currentStamina}/${schedule.maxStamina}，请及时消耗`,
      );
    }
  }

  // ─── 通知发布 ────────────────────────────────────────────────

  /**
   * STYLE_B：发布合并的多行文本通知
   *
   * 收集所有角色的通知数据，合并为一条多行文本通知。
   * 每个角色一行，格式："游戏名 · 昵称：体力名 120/200"
   */
  private async publishMergedNotification(schedules: StaminaSchedule[]): Promise<void> {
    if (schedules.length === 0) {
      return;
    }

    try {
      const lines: string[] = [];
      for (const schedule of schedules) {
        lines.push(
          `${schedule.gameName} · ${schedule.displayName}：` +
          `${schedule.staminaName} ${schedule.currentStamina}/${schedule.maxStamina}`,
        );
      }
      // 使用固定 ID 发布合并通知
      const notifId = StaminaNotificationService.hashNotificationId('merged_stamina_notification');
      const wa = await wantAgent.getWantAgent(this.createNotificationWantAgentInfo(notifId));

      const multiLineContent: notificationManager.NotificationMultiLineContent = {
        title: '体力提醒',
        text: `共 ${schedules.length} 个角色体力已达标`,
        briefText: `${schedules.length} 个角色`,
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

      const now = Math.floor(Date.now() / 1000);
      for (const schedule of schedules) {
        await this.saveState(
          schedule.key, -1, schedule.recoveryTimeSnapshot, schedule.threshold, now,
        );
      }
      Logger.info(TAG, `merged notification sent for ${schedules.length} roles`);
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `publishMergedNotification failed: ${msg}`);
    }
  }

  private async publishImmediateNotification(
    schedule: StaminaSchedule,
    title: string,
    body: string,
    sub: string,
  ): Promise<void> {
    try {
      const notifId = StaminaNotificationService.hashNotificationId(schedule.key);
      const wa = await wantAgent.getWantAgent(this.createNotificationWantAgentInfo(notifId));

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

      await this.saveState(schedule.key, -1, schedule.recoveryTimeSnapshot, schedule.threshold);
      Logger.info(TAG, `immediate notification sent: ${schedule.key}`);
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `publishImmediateNotification failed: ${msg}`);
    }
  }

  /**
   * 注册系统级代理提醒（STYLE_A / STYLE_B 共用）。
   * 到期后系统会唤醒 App，App 启动时调用 onDailyNotesSynced() 重新检查。
   */
  private async publishTimerReminder(schedule: StaminaSchedule, body: string): Promise<void> {
    try {
      const count = await this.getReminderCount();
      if (count >= GameStaminaConstants.REMINDER_LIMIT) {
        Logger.warn(
          TAG,
          `reminder limit reached (${count}/${GameStaminaConstants.REMINDER_LIMIT}), skip: ${schedule.key}`,
        );
        return;
      }

      const notifId = StaminaNotificationService.hashNotificationId(schedule.key);
      const reminderWantAgent: reminderAgentManager.WantAgent = {
        pkgName: this.bundleName,
        abilityName: ABILITY_NAME,
      };
      const closeBtn: reminderAgentManager.ActionButton = {
        title: '关闭',
        type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE,
      };

      const reminder: reminderAgentManager.ReminderRequestTimer = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
        triggerTimeInSeconds: schedule.delaySeconds,
        title: `${schedule.gameName} · ${schedule.displayName}`,
        content: body,
        expiredContent: body,
        notificationId: notifId,
        slotType: notificationManager.SlotType.SERVICE_INFORMATION,
        wantAgent: reminderWantAgent,
        actionButton: [closeBtn],
      };

      Logger.info(
        TAG,
        `publishTimerReminder: publishing reminder for ${schedule.key}, ` +
        `delay=${schedule.delaySeconds}s, current count=${count}`,
      );
      const reminderId = await reminderAgentManager.publishReminder(reminder);
      Logger.info(TAG, `publishTimerReminder: SUCCESS, reminderId=${reminderId} for ${schedule.key}`);

      await this.saveState(schedule.key, reminderId, schedule.recoveryTimeSnapshot, schedule.threshold);
    } catch (e) {
      const err = e as BusinessError;
      const code: number = err.code !== undefined ? err.code : -1;
      const msg: string = err.message !== undefined ? err.message : `${e}`;
      Logger.error(TAG, `publishTimerReminder FAILED for ${schedule.key}: code=${code} msg=${msg}`);
    }
  }

  /** 构建点击通知后启动 App 的 WantAgentInfo */
  private createNotificationWantAgentInfo(notifId: number): wantAgent.WantAgentInfo {
    return {
      wants: [{
        bundleName: this.bundleName,
        abilityName: ABILITY_NAME,
      }],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: notifId,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
    };
  }

  /** 写入提醒状态（三处发布路径共用） */
  private async saveState(
    key: string,
    reminderId: number,
    recoveryTimeSnapshot: number,
    threshold: number,
    scheduledAt: number = Math.floor(Date.now() / 1000),
  ): Promise<void> {
    const stateEntry = new NotificationStateEntry();
    stateEntry.reminderId = reminderId;
    stateEntry.recoveryTimeSnapshot = recoveryTimeSnapshot;
    stateEntry.threshold = threshold;
    stateEntry.scheduledAt = scheduledAt;
    await NotificationStateStore.getInstance().setEntry(key, stateEntry);
  }

  // ─── 文案 ────────────────────────────────────────────────────

  private getStaminaName(gameId: GameId): string {
    return this.getResourceString(
      GameStaminaResources.getStaminaNameKey(gameId),
      GameStaminaResources.getStaminaNameFallback(gameId),
    );
  }

  private getGameName(gameId: GameId): string {
    return this.getResourceString(
      GameStaminaResources.getGameNameKey(gameId),
      GameStaminaResources.getGameNameFallback(gameId),
    );
  }

  /** 取当前语言字符串；context 未初始化或资源缺失时返回 fallback */
  private getResourceString(key: string, fallback: string): string {
    try {
      return this.context?.resourceManager.getStringByNameSync(key) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  private static hashNotificationId(key: string): number {
    let hash = 0;
    for (let i = 0; i < key.length; i++) {
      hash = (hash * 31 + key.charCodeAt(i)) & 0x7fffffff;
    }
    return (hash % 100000) + 10000;
  }
}
