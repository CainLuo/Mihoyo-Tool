/**
 * NotificationSettingsViewModel.ets — 通知设置页 ViewModel
 */
import { common } from '@kit.AbilityKit';
import { CoreInitializer, Logger, GameRoleRow, GameId, GenshinDailyNoteParser, StarRailDailyNoteParser, ZZZDailyNoteParser } from 'core';
import { StaminaNotificationService } from '../notification/StaminaNotificationService';
import { NotificationSettingsStore } from '../notification/NotificationSettingsStore';
import {
  AccountNotificationConfig,
  GameNotificationConfig,
  GameNotificationSetting,
  NotificationSettings,
  NotificationStyle,
  GameStaminaConstants,
} from '../notification/NotificationModels';
import { StaminaThresholdCalculator } from '../notification/StaminaThresholdCalculator';

const TAG: string = 'NotificationSettingsViewModel';

export class NotificationSettingsViewModelKeys {
  showLimitDialog: string = 'vm.showLimitDialog';
  permissionDenied: string = 'vm.permissionDenied';
}

@ObservedV2
export class NotificationSettingsViewModel {
  static readonly KEYS: NotificationSettingsViewModelKeys = new NotificationSettingsViewModelKeys();

  @Trace enabled: boolean = false;
  @Trace style: NotificationStyle = NotificationStyle.STYLE_A;
  @Trace permissionDenied: boolean = false;
  @Trace accounts: AccountNotificationConfig[] = [];
  @Trace reminderUsed: number = 0;
  @Trace reminderLimit: number = GameStaminaConstants.REMINDER_LIMIT;
  @Trace showLimitDialog: boolean = false;

  /** 槽位进度条颜色（根据使用比例决定） */
  slotColor(): Resource {
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
    const globalSettings = await NotificationSettingsStore.instance().loadGlobal();
    const newEnabled = globalSettings.enabled;
    const newStyle = globalSettings.style;
    const newPermDenied = newEnabled && !(await StaminaNotificationService.instance().checkPermission());
    const newReminderUsed = await StaminaNotificationService.instance().getReminderCount();
    const newAccounts = await this.fetchAccountConfigs();

    // 一次性赋值，减少重渲染次数
    this.enabled = newEnabled;
    this.style = newStyle;
    this.permissionDenied = newPermDenied;
    this.reminderUsed = newReminderUsed;
    this.accounts = newAccounts;
  }

  /**
   * @param targetOn Toggle 期望切换到的目标状态（来自 onChange 的 isOn 参数）
   */
  async onToggleEnabled(context: common.UIAbilityContext, targetOn: boolean): Promise<void> {
    if (this.isTogglingEnabled) {
      return;
    }
    // 目标状态与当前状态一致，说明是外部修改 isOn 触发的 onChange，忽略
    if (targetOn === this.enabled) {
      return;
    }
    this.isTogglingEnabled = true;
    try {
      if (targetOn) {
        // 开启：先请求权限
        const granted = await StaminaNotificationService.instance().requestPermission();
        if (!granted) {
          this.permissionDenied = true;
          return;
        }
        this.permissionDenied = false;
        this.enabled = true;
        await this.saveGlobal();
        await StaminaNotificationService.instance().onDailyNotesSynced();
      } else {
        // 关闭：取消所有提醒
        this.enabled = false;
        await this.saveGlobal();
        await StaminaNotificationService.instance().cancelAll();
      }
      this.reminderUsed = await StaminaNotificationService.instance().getReminderCount();
    } finally {
      this.isTogglingEnabled = false;
    }
  }

  async onStyleChange(style: NotificationStyle): Promise<void> {
    this.style = style;
    await this.saveGlobal();
  }

  async onGameToggle(accountId: string, gameId: GameId, targetEnabled: boolean): Promise<void> {
    const key = `${accountId}_${gameId}`;
    if (this.togglingGameKey === key) {
      return;
    }
    // 目标状态与当前一致，是外部修改触发的 onChange，忽略
    if (targetEnabled === this.getGameEnabled(accountId, gameId)) {
      return;
    }
    this.togglingGameKey = key;
    try {
      if (targetEnabled) {
        // 开启前检查槽位
        const count = await StaminaNotificationService.instance().getReminderCount();
        if (count >= GameStaminaConstants.REMINDER_LIMIT) {
          this.showLimitDialog = true;
          return;
        }
      }

      // 更新本地状态
      const acct = this.findAccount(accountId);
      if (acct !== null) {
        const game = this.findGame(acct, gameId);
        if (game !== null) {
          game.enabled = targetEnabled;
        }
      }

      // 持久化
      const setting = new GameNotificationSetting();
      setting.enabled = targetEnabled;
      setting.threshold = this.getThreshold(accountId, gameId);
      await NotificationSettingsStore.instance().saveGameSetting(accountId, gameId, setting);

      if (!targetEnabled) {
        await StaminaNotificationService.instance().cancelByAccountGame(accountId, gameId);
      } else {
        await StaminaNotificationService.instance().onDailyNotesSynced();
      }
      this.reminderUsed = await StaminaNotificationService.instance().getReminderCount();
    } finally {
      this.togglingGameKey = '';
    }
  }

  async onThresholdChange(accountId: string, gameId: GameId, threshold: number): Promise<void> {
    const maxStamina = this.getMaxStamina(accountId, gameId);
    const clamped = StaminaThresholdCalculator.clampThreshold(threshold, maxStamina > 0 ? maxStamina : 999);

    const acct = this.findAccount(accountId);
    if (acct !== null) {
      const game = this.findGame(acct, gameId);
      if (game !== null) {
        game.threshold = clamped;
      }
    }

    const setting = new GameNotificationSetting();
    setting.enabled = this.getGameEnabled(accountId, gameId);
    setting.threshold = clamped;
    await NotificationSettingsStore.instance().saveGameSetting(accountId, gameId, setting);

    // 阈值变化：取消旧提醒，下次同步时重新调度
    await StaminaNotificationService.instance().cancelByAccountGame(accountId, gameId);
  }

  async onFullValueShortcut(accountId: string): Promise<void> {
    const acct = this.findAccount(accountId);
    if (acct === null) {
      return;
    }
    // 创建新的 games 数组（新对象引用），让 @Monitor('game') 能检测到变化
    const newGames: GameNotificationConfig[] = [];
    for (let i = 0; i < acct.games.length; i++) {
      const game = acct.games[i];
      const maxVal = game.maxStamina > 0 ? game.maxStamina : GameStaminaConstants.fallbackMax(game.gameId);
      const setting = new GameNotificationSetting();
      setting.enabled = game.enabled;
      setting.threshold = maxVal;
      await NotificationSettingsStore.instance().saveGameSetting(accountId, game.gameId, setting);
      await StaminaNotificationService.instance().cancelByAccountGame(accountId, game.gameId);
      // 创建新对象，threshold 已更新
      const newGame = new GameNotificationConfig();
      newGame.gameId = game.gameId;
      newGame.gameName = game.gameName;
      newGame.staminaName = game.staminaName;
      newGame.enabled = game.enabled;
      newGame.threshold = maxVal;
      newGame.maxStamina = game.maxStamina;
      newGame.secondsPerUnit = game.secondsPerUnit;
      newGames[newGames.length] = newGame;
    }
    acct.games = newGames;
    // 重新赋值触发 @Trace 更新
    const copy: AccountNotificationConfig[] = [];
    for (let i = 0; i < this.accounts.length; i++) {
      copy[copy.length] = this.accounts[i];
    }
    this.accounts = copy;
  }

  onToggleAccountExpanded(accountId: string): void {
    const acct = this.findAccount(accountId);
    if (acct !== null) {
      acct.isExpanded = !acct.isExpanded;
      // 重新赋值触发 @Trace 更新，让 ForEach 重渲染
      const copy: AccountNotificationConfig[] = [];
      for (let i = 0; i < this.accounts.length; i++) {
        copy[copy.length] = this.accounts[i];
      }
      this.accounts = copy;
    }
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  private async saveGlobal(): Promise<void> {
    const s = new NotificationSettings();
    s.enabled = this.enabled;
    s.style = this.style;
    await NotificationSettingsStore.instance().saveGlobal(s);
  }

  private async fetchAccountConfigs(): Promise<AccountNotificationConfig[]> {
    const result: AccountNotificationConfig[] = [];
    try {
      const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
      for (let ai = 0; ai < accounts.length; ai++) {
        const account = accounts[ai];
        const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);

        // 收集该账号拥有的游戏（去重）
        const gameIds: GameId[] = [];
        for (let ri = 0; ri < roles.length; ri++) {
          const gid = roles[ri].gameId;
          if (gid !== GameId.GENSHIN && gid !== GameId.STARRAIL && gid !== GameId.ZZZ) {
            continue;
          }
          let found = false;
          for (let gi = 0; gi < gameIds.length; gi++) {
            if (gameIds[gi] === gid) {
              found = true;
              break;
            }
          }
          if (!found) {
            gameIds[gameIds.length] = gid;
          }
        }

        if (gameIds.length === 0) {
          continue;
        }

        const acctConfig = new AccountNotificationConfig();
        acctConfig.accountId = account.uid;
        acctConfig.nickname = account.nickname.length > 0 ? account.nickname : account.username;
        acctConfig.uid = account.uid;
        acctConfig.avatarUrl = account.avatarUrl;
        acctConfig.isExpanded = true;

        for (let gi = 0; gi < gameIds.length; gi++) {
          const gameId = gameIds[gi];
          const maxStamina = await this.loadMaxStamina(account.uid, gameId, roles);
          const setting = await NotificationSettingsStore.instance().loadGameSetting(account.uid, gameId, maxStamina);

          const gameConfig = new GameNotificationConfig();
          gameConfig.gameId = gameId;
          gameConfig.gameName = NotificationSettingsViewModel.gameName(gameId);
          gameConfig.staminaName = NotificationSettingsViewModel.staminaName(gameId);
          gameConfig.enabled = setting.enabled;
          gameConfig.threshold = StaminaThresholdCalculator.clampThreshold(
            setting.threshold,
            maxStamina > 0 ? maxStamina : 999,
          );
          gameConfig.maxStamina = maxStamina;
          gameConfig.secondsPerUnit = NotificationSettingsViewModel.secondsPerUnit(gameId);
          acctConfig.games[acctConfig.games.length] = gameConfig;
        }

        result[result.length] = acctConfig;
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `fetchAccountConfigs failed: ${msg}`);
    }
    return result;
  }

  private async loadMaxStamina(accountId: string, gameId: GameId, roles: GameRoleRow[]): Promise<number> {
    // 取该账号该游戏的第一个角色 UID
    let roleUid = '';
    for (let ri = 0; ri < roles.length; ri++) {
      const role = roles[ri];
      if (role.gameId === gameId) {
        roleUid = role.roleId;
        break;
      }
    }
    if (roleUid.length === 0) {
      return 0;
    }
    try {
      if (gameId === GameId.GENSHIN) {
        const row = await CoreInitializer.genshinRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return 0;
        }
        const data = GenshinDailyNoteParser.parse(row.rawJson);
        return data.maxResin > 0 ? data.maxResin : row.maxResin;
      }
      if (gameId === GameId.STARRAIL) {
        const row = await CoreInitializer.starRailRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return 0;
        }
        const data = StarRailDailyNoteParser.parse(row.rawJson);
        return data.maxStamina > 0 ? data.maxStamina : row.maxStamina;
      }
      if (gameId === GameId.ZZZ) {
        const row = await CoreInitializer.zzzRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return 0;
        }
        const data = ZZZDailyNoteParser.parse(row.rawJson);
        return data.maxEnergy > 0 ? data.maxEnergy : row.energyMax;
      }
    } catch (_) {}
    return 0;
  }

  private findAccount(accountId: string): AccountNotificationConfig | null {
    for (let i = 0; i < this.accounts.length; i++) {
      if (this.accounts[i].accountId === accountId) {
        return this.accounts[i];
      }
    }
    return null;
  }

  private findGame(acct: AccountNotificationConfig, gameId: GameId): GameNotificationConfig | null {
    for (let i = 0; i < acct.games.length; i++) {
      if (acct.games[i].gameId === gameId) {
        return acct.games[i];
      }
    }
    return null;
  }

  private getThreshold(accountId: string, gameId: GameId): number {
    const acct = this.findAccount(accountId);
    if (acct === null) {
      return 0;
    }
    const game = this.findGame(acct, gameId);
    return game !== null ? game.threshold : 0;
  }

  private getMaxStamina(accountId: string, gameId: GameId): number {
    const acct = this.findAccount(accountId);
    if (acct === null) {
      return 0;
    }
    const game = this.findGame(acct, gameId);
    return game !== null ? game.maxStamina : 0;
  }

  private getGameEnabled(accountId: string, gameId: GameId): boolean {
    const acct = this.findAccount(accountId);
    if (acct === null) {
      return false;
    }
    const game = this.findGame(acct, gameId);
    return game !== null ? game.enabled : false;
  }

  private static gameName(gameId: GameId): Resource {
    if (gameId === GameId.GENSHIN) { return $r('app.string.game_name_genshin'); }
    if (gameId === GameId.STARRAIL) { return $r('app.string.game_name_starrail'); }
    return $r('app.string.game_name_zzz');
  }

  private static staminaName(gameId: GameId): Resource {
    if (gameId === GameId.GENSHIN) { return $r('app.string.notification_stamina_genshin'); }
    if (gameId === GameId.STARRAIL) { return $r('app.string.notification_stamina_starrail'); }
    return $r('app.string.notification_stamina_zzz');
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
}
