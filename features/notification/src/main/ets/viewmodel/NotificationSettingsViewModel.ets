/**
 * NotificationSettingsViewModel.ets — 通知设置页 ViewModel
 */
import { common } from '@kit.AbilityKit';
import { CoreInitializer, Logger, GameRoleRow, GameId } from 'core';
import { getGameName } from 'basic';
import { StaminaNotificationService } from '../model/service/StaminaNotificationService';
import { NotificationSettingsStore } from '../model/service/NotificationSettingsStore';
import {
  AccountNotificationConfig,
  GameNotificationConfig,
  GameNotificationSetting,
  NotificationSettings,
  NotificationStyle,
  GameStaminaConstants,
  GameStaminaResources,
} from '../model/NotificationModels';
import { StaminaThresholdCalculator } from '../model/service/StaminaThresholdCalculator';
import { StaminaNoteReader } from '../model/service/StaminaNoteReader';

const TAG: string = 'NotificationSettingsViewModel';

@ObservedV2
export class NotificationSettingsViewModel {

  @Trace isEnabled: boolean = false;
  @Trace style: NotificationStyle = NotificationStyle.STYLE_A;
  @Trace isPermissionDenied: boolean = false;
  @Trace accounts: AccountNotificationConfig[] = [];
  @Trace reminderUsed: number = 0;
  @Trace reminderLimit: number = GameStaminaConstants.REMINDER_LIMIT;
  @Trace shouldShowLimitDialog: boolean = false;

  /** 槽位进度条颜色（根据使用比例决定） */
  getSlotColor(): Resource {
    const ratio = this.reminderUsed / this.reminderLimit;
    if (ratio >= 1) { return $r('app.color.color_danger'); }
    if (ratio >= 0.8) { return $r('app.color.color_warning'); }
    return $r('app.color.color_primary');
  }
  /** 防止 Toggle.onChange 因外部修改 isOn 而重复触发 */
  private isTogglingEnabled: boolean = false;
  /** 防止游戏开关 Toggle 循环触发，key = accountId_gameId */
  private togglingGameKey: string = '';

  async loadSettings(): Promise<void> {
    // 先收集所有数据，最后批量赋值，避免多次 @Trace 更新导致闪烁
    const globalSettings = await NotificationSettingsStore.getInstance().loadGlobal();
    const newEnabled = globalSettings.isEnabled;
    const newStyle = globalSettings.style;
    const newPermDenied = newEnabled && !(await StaminaNotificationService.getInstance().checkPermission());
    const newReminderUsed = await StaminaNotificationService.getInstance().getReminderCount();
    const newAccounts = await this.fetchAccountConfigs();

    // 一次性赋值，减少重渲染次数
    this.isEnabled = newEnabled;
    this.style = newStyle;
    this.isPermissionDenied = newPermDenied;
    this.reminderUsed = newReminderUsed;
    this.accounts = newAccounts;
  }

  /**
   * @param isTargetOn Toggle 期望切换到的目标状态（来自 onChange 的 isOn 参数）
   */
  async onToggleEnabled(context: common.UIAbilityContext, isTargetOn: boolean): Promise<void> {
    if (this.isTogglingEnabled) {
      return;
    }
    // 目标状态与当前状态一致，说明是外部修改 isOn 触发的 onChange，忽略
    if (isTargetOn === this.isEnabled) {
      return;
    }
    this.isTogglingEnabled = true;
    try {
      if (isTargetOn) {
        // 开启：先请求权限
        const granted = await StaminaNotificationService.getInstance().requestPermission();
        if (!granted) {
          this.isPermissionDenied = true;
          return;
        }
        this.isPermissionDenied = false;
        this.isEnabled = true;
        await this.saveGlobal();
        await StaminaNotificationService.getInstance().onDailyNotesSynced();
      } else {
        // 关闭：取消所有提醒
        this.isEnabled = false;
        await this.saveGlobal();
        await StaminaNotificationService.getInstance().cancelAll();
      }
      this.reminderUsed = await StaminaNotificationService.getInstance().getReminderCount();
    } finally {
      this.isTogglingEnabled = false;
    }
  }

  async onStyleChange(style: NotificationStyle): Promise<void> {
    this.style = style;
    await this.saveGlobal();
  }

  async onGameToggle(accountId: string, gameId: GameId, isTargetEnabled: boolean): Promise<void> {
    const key = `${accountId}_${gameId}`;
    if (this.togglingGameKey === key) {
      return;
    }
    // 目标状态与当前一致，是外部修改触发的 onChange，忽略
    if (isTargetEnabled === this.getGameEnabled(accountId, gameId)) {
      return;
    }
    this.togglingGameKey = key;
    try {
      if (isTargetEnabled) {
        // 开启前检查槽位
        const count = await StaminaNotificationService.getInstance().getReminderCount();
        if (count >= GameStaminaConstants.REMINDER_LIMIT) {
          this.shouldShowLimitDialog = true;
          return;
        }
      }

      // 更新本地状态
      const game = this.findGameConfig(accountId, gameId);
      const threshold = game !== null ? game.threshold : 0;
      if (game !== null) {
        game.isEnabled = isTargetEnabled;
      }

      // 持久化
      await this.saveGameSetting(accountId, gameId, isTargetEnabled, threshold);

      if (!isTargetEnabled) {
        await StaminaNotificationService.getInstance().cancelByAccountGame(accountId, gameId);
      } else {
        await StaminaNotificationService.getInstance().onDailyNotesSynced();
      }
      this.reminderUsed = await StaminaNotificationService.getInstance().getReminderCount();
    } finally {
      this.togglingGameKey = '';
    }
  }

  async onThresholdChange(accountId: string, gameId: GameId, threshold: number): Promise<void> {
    const maxStamina = this.getMaxStamina(accountId, gameId);
    const clamped = StaminaThresholdCalculator.clampThreshold(threshold, maxStamina > 0 ? maxStamina : 999);

    const game = this.findGameConfig(accountId, gameId);
    const isEnabled = game !== null ? game.isEnabled : false;
    if (game !== null) {
      game.threshold = clamped;
    }

    await this.saveGameSetting(accountId, gameId, isEnabled, clamped);

    // 阈值变化：取消旧提醒，下次同步时重新调度
    await StaminaNotificationService.getInstance().cancelByAccountGame(accountId, gameId);
  }

  async onFullValueShortcut(accountId: string): Promise<void> {
    const acct = this.findAccount(accountId);
    if (acct === null) {
      return;
    }
    // 创建新的 games 数组（新对象引用），让 @Monitor('game') 能检测到变化
    const newGames: GameNotificationConfig[] = [];
    for (const game of acct.games) {
      const maxVal = game.maxStamina > 0 ? game.maxStamina : GameStaminaConstants.getFallbackMax(game.gameId);
      await this.saveGameSetting(accountId, game.gameId, game.isEnabled, maxVal);
      await StaminaNotificationService.getInstance().cancelByAccountGame(accountId, game.gameId);
      newGames.push(this.cloneGameConfig(game, maxVal));
    }
    acct.games = newGames;
    this.notifyAccountsChanged();
  }

  onToggleAccountExpanded(accountId: string): void {
    const acct = this.findAccount(accountId);
    if (acct !== null) {
      acct.isExpanded = !acct.isExpanded;
      // 重新赋值触发 @Trace 更新，让 ForEach 重渲染
      this.notifyAccountsChanged();
    }
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  private async saveGlobal(): Promise<void> {
    const s = new NotificationSettings();
    s.isEnabled = this.isEnabled;
    s.style = this.style;
    await NotificationSettingsStore.getInstance().saveGlobal(s);
  }

  private async saveGameSetting(
    accountId: string,
    gameId: GameId,
    isEnabled: boolean,
    threshold: number,
  ): Promise<void> {
    const setting = new GameNotificationSetting();
    setting.isEnabled = isEnabled;
    setting.threshold = threshold;
    await NotificationSettingsStore.getInstance().saveGameSetting(accountId, gameId, setting);
  }

  private async fetchAccountConfigs(): Promise<AccountNotificationConfig[]> {
    const result: AccountNotificationConfig[] = [];
    try {
      const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
      for (const account of accounts) {
        const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
        const gameIds = this.collectGameIds(roles);
        if (gameIds.length === 0) {
          continue;
        }

        const acctConfig = new AccountNotificationConfig();
        acctConfig.accountId = account.uid;
        acctConfig.nickname = account.nickname.length > 0 ? account.nickname : account.username;
        acctConfig.uid = account.uid;
        acctConfig.avatarUrl = account.avatarUrl;
        acctConfig.isExpanded = true;

        for (const gameId of gameIds) {
          const maxStamina = await this.loadMaxStamina(account.uid, gameId, roles);
          const setting = await NotificationSettingsStore.getInstance().loadGameSetting(account.uid, gameId, maxStamina);

          const gameConfig = new GameNotificationConfig();
          gameConfig.gameId = gameId;
          gameConfig.gameName = getGameName(gameId);
          gameConfig.staminaName = GameStaminaResources.getStaminaName(gameId);
          gameConfig.isEnabled = setting.isEnabled;
          gameConfig.threshold = StaminaThresholdCalculator.clampThreshold(
            setting.threshold,
            maxStamina > 0 ? maxStamina : 999,
          );
          gameConfig.maxStamina = maxStamina;
          gameConfig.secondsPerUnit = GameStaminaConstants.getSecondsPerUnit(gameId);
          acctConfig.games.push(gameConfig);
        }

        result.push(acctConfig);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `fetchAccountConfigs failed: ${msg}`);
    }
    return result;
  }

  /** 收集账号拥有的游戏（保持 roles 中的首次出现顺序，去重） */
  private collectGameIds(roles: GameRoleRow[]): GameId[] {
    const seen = new Set<GameId>();
    for (const role of roles) {
      if (role.gameId === GameId.GENSHIN || role.gameId === GameId.STARRAIL || role.gameId === GameId.ZZZ) {
        seen.add(role.gameId);
      }
    }
    const gameIds: GameId[] = [];
    seen.forEach((gameId: GameId) => {
      gameIds.push(gameId);
    });
    return gameIds;
  }

  private async loadMaxStamina(accountId: string, gameId: GameId, roles: GameRoleRow[]): Promise<number> {
    // 取该账号该游戏的第一个角色 UID
    const role = roles.find((candidate: GameRoleRow) => candidate.gameId === gameId);
    if (role === undefined) {
      return 0;
    }
    const snapshot = await StaminaNoteReader.read(accountId, role.roleId, gameId);
    return snapshot !== null ? snapshot.maxStamina : 0;
  }

  private findAccount(accountId: string): AccountNotificationConfig | null {
    return this.accounts.find((acct: AccountNotificationConfig) => acct.accountId === accountId) ?? null;
  }

  private findGame(acct: AccountNotificationConfig, gameId: GameId): GameNotificationConfig | null {
    return acct.games.find((game: GameNotificationConfig) => game.gameId === gameId) ?? null;
  }

  private findGameConfig(accountId: string, gameId: GameId): GameNotificationConfig | null {
    const acct = this.findAccount(accountId);
    return acct !== null ? this.findGame(acct, gameId) : null;
  }

  private getMaxStamina(accountId: string, gameId: GameId): number {
    const game = this.findGameConfig(accountId, gameId);
    return game !== null ? game.maxStamina : 0;
  }

  private getGameEnabled(accountId: string, gameId: GameId): boolean {
    const game = this.findGameConfig(accountId, gameId);
    return game !== null ? game.isEnabled : false;
  }

  /** 复制游戏配置并替换阈值（用于一键满值后触发响应式更新） */
  private cloneGameConfig(game: GameNotificationConfig, threshold: number): GameNotificationConfig {
    const copy = new GameNotificationConfig();
    copy.gameId = game.gameId;
    copy.gameName = game.gameName;
    copy.staminaName = game.staminaName;
    copy.isEnabled = game.isEnabled;
    copy.threshold = threshold;
    copy.maxStamina = game.maxStamina;
    copy.secondsPerUnit = game.secondsPerUnit;
    return copy;
  }

  /** 重新赋值数组引用，触发 @Trace 更新 */
  private notifyAccountsChanged(): void {
    this.accounts = this.accounts.slice();
  }
}
