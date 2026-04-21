/**
 * NotificationSettingsStore.ets — 通知设置持久化（preferences）
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger, GameId } from 'core';
import { NotificationSettings, NotificationStyle, GameNotificationSetting, GameStaminaConstants } from './NotificationModels';

const TAG: string = 'NotificationSettingsStore';
const STORE_NAME: string = 'notification_settings';
const KEY_ENABLED: string = 'enabled';
const KEY_STYLE: string = 'style';
const KEY_GAME_PREFIX: string = 'game_';

export class NotificationSettingsStore {
  private static _instance: NotificationSettingsStore | null = null;
  private pref: preferences.Preferences | null = null;

  static instance(): NotificationSettingsStore {
    if (NotificationSettingsStore._instance === null) {
      NotificationSettingsStore._instance = new NotificationSettingsStore();
    }
    return NotificationSettingsStore._instance as NotificationSettingsStore;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.pref = await preferences.getPreferences(context, STORE_NAME);
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.error(TAG, `init failed: ${msg}`);
    }
  }

  async loadGlobal(): Promise<NotificationSettings> {
    const s = new NotificationSettings();
    if (this.pref === null) {
      return s;
    }
    try {
      s.enabled = (await this.pref.get(KEY_ENABLED, false)) as boolean;
      const styleStr = (await this.pref.get(KEY_STYLE, NotificationStyle.STYLE_A)) as string;
      s.style = styleStr === NotificationStyle.STYLE_B ? NotificationStyle.STYLE_B : NotificationStyle.STYLE_A;
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `loadGlobal failed: ${msg}`);
    }
    return s;
  }

  async saveGlobal(settings: NotificationSettings): Promise<void> {
    if (this.pref === null) {
      return;
    }
    try {
      await this.pref.put(KEY_ENABLED, settings.enabled);
      await this.pref.put(KEY_STYLE, settings.style);
      await this.pref.flush();
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `saveGlobal failed: ${msg}`);
    }
  }

  /** key 格式："{accountId}_{gameId}" */
  async loadGameSetting(accountId: string, gameId: GameId, maxStamina: number = 0): Promise<GameNotificationSetting> {
    const s = new GameNotificationSetting();
    // 默认阈值：如果有实际 maxStamina 就用 80%，否则用 fallback 常量
    s.threshold = maxStamina > 0
      ? Math.floor(maxStamina * 0.8)
      : NotificationSettingsStore.defaultThreshold(gameId);
    if (this.pref === null) {
      return s;
    }
    try {
      const key = `${KEY_GAME_PREFIX}${accountId}_${gameId}`;
      const enabledKey = `${key}_enabled`;
      const thresholdKey = `${key}_threshold`;
      s.enabled = (await this.pref.get(enabledKey, true)) as boolean;
      s.threshold = (await this.pref.get(thresholdKey, s.threshold)) as number;
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `loadGameSetting failed: ${msg}`);
    }
    return s;
  }

  async saveGameSetting(accountId: string, gameId: GameId, setting: GameNotificationSetting): Promise<void> {
    if (this.pref === null) {
      return;
    }
    try {
      const key = `${KEY_GAME_PREFIX}${accountId}_${gameId}`;
      await this.pref.put(`${key}_enabled`, setting.enabled);
      await this.pref.put(`${key}_threshold`, setting.threshold);
      await this.pref.flush();
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `saveGameSetting failed: ${msg}`);
    }
  }

  private static defaultThreshold(gameId: GameId): number {
    if (gameId === GameId.GENSHIN) {
      return GameStaminaConstants.GENSHIN_DEFAULT_THRESHOLD;
    }
    if (gameId === GameId.STARRAIL) {
      return GameStaminaConstants.STARRAIL_DEFAULT_THRESHOLD;
    }
    if (gameId === GameId.ZZZ) {
      return GameStaminaConstants.ZZZ_DEFAULT_THRESHOLD;
    }
    return 0;
  }
}
