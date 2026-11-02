/**
 * HomeDataLoader.ets
 *
 * 首页数据加载：本地 DB → UI ViewModel 映射。
 * 负责账号/角色读取、daily_note 快照解析、同步时间查询。
 */
import {
  AccountRow,
  CoreInitializer,
  GameId,
  GameRoleRow,
  GenshinDailyNoteParser,
  Logger,
  StarRailDailyNoteParser,
  ZZZCardSign,
  ZZZDailyNoteParser,
  ZZZVideoStoreState,
} from 'core';
import {
  GameDataRowVM,
  GameNoteSnapshotVM,
  GameRoleCardVM,
  getServerDisplayName,
  MihoyoAccountVM,
} from 'basic';
import { HomeCardPresenter } from './HomeCardPresenter';

const TAG: string = 'HomeDataLoader';

export class HomeDataLoader {
  /** 从本地 DB 读取账号 + 角色 + daily_note，组装 UI ViewModel */
  static async fetchAccounts(): Promise<MihoyoAccountVM[]> {
    const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
    const result: MihoyoAccountVM[] = [];
    for (let ai = 0; ai < accounts.length; ai++) {
      const account = accounts[ai];
      const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
      const cards = await HomeDataLoader.buildRoleCards(account, roles);
      result[result.length] = new MihoyoAccountVM(
        account.uid, account.username, cards, account.nickname, account.avatarUrl
      );
    }
    return result;
  }

  /** 将 GameRoleRow[] 转换为 GameRoleCardVM[]，每个角色查一次 daily_note */
  private static async buildRoleCards(account: AccountRow, roles: GameRoleRow[]): Promise<GameRoleCardVM[]> {
    const cards: GameRoleCardVM[] = [];
    for (let ri = 0; ri < roles.length; ri++) {
      const role = roles[ri];
      const snapshot = await HomeDataLoader.loadDailyNoteSnapshot(account.uid, role.gameId, role.roleId);
      if (snapshot === null) {
        continue;
      }
      // 从 sync_meta 读取真实的上次同步时间，计算描述
      let lastSyncTime = 0;
      try {
        lastSyncTime = await HomeDataLoader.getDailyNoteLastSyncTime(account.uid, role.roleId, role.gameId);
      } catch (_) {}
      cards[cards.length] = new GameRoleCardVM(
        role.gameId,
        role.gameId,
        HomeCardPresenter.getGameColor(role.gameId),
        role.roleId,
        role.nickname,
        getServerDisplayName(role.server, role.gameId) ?? role.server,
        snapshot,
        HomeCardPresenter.syncDescKey(lastSyncTime),
        HomeCardPresenter.getGameLogo(role.gameId)
      );
    }
    return cards;
  }

  /**
   * 从 DB 读取 daily_note，解析为 GameNoteSnapshotVM。
   */
  private static async loadDailyNoteSnapshot(
    accountId: string,
    gameId: GameId,
    roleUid: string
  ): Promise<GameNoteSnapshotVM | null> {
    try {
      if (gameId === GameId.GENSHIN) {
        const row = await CoreInitializer.genshinRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = GenshinDailyNoteParser.parse(row.rawJson);
        const isFull = data.currentResin >= data.maxResin && data.maxResin > 0;
        const recoverySeconds = isFull ? 0 : data.resinRecoveryTime;
        const snap = new GameNoteSnapshotVM(
          $r('app.string.daily_note_resin_title'), data.currentResin, data.maxResin, recoverySeconds, '', '', isFull
        );
        snap.expeditionCurrent = data.expeditions.length;
        snap.expeditionMax = data.maxExpeditionNum;
        snap.homeCoinCurrent = data.currentHomeCoin;
        snap.homeCoinMax = data.maxHomeCoin;
        snap.dailyTaskFinished = data.finishedTaskNum;
        snap.dailyTaskTotal = data.totalTaskNum;
        snap.isDailyTaskAllReceived = data.isExtraTaskRewardReceived;

        // 数据行：由 VM 决定显示哪些行及颜色，View 层直接 ForEach
        const rows: GameDataRowVM[] = [];
        if (data.expeditions.length >= 0) {
          const expeditionCurrent = data.expeditions.length;
          const expeditionMax = data.maxExpeditionNum;
          rows[rows.length] = new GameDataRowVM(
            $r('app.string.daily_note_expedition_title'),
            `${expeditionCurrent}/${expeditionMax}`,
            expeditionCurrent >= expeditionMax ? $r('app.color.color_primary')
              : expeditionCurrent === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        if (data.currentHomeCoin >= 0) {
          const homeCoinCurrent = data.currentHomeCoin;
          const homeCoinMax = data.maxHomeCoin;
          rows[rows.length] = new GameDataRowVM(
            $r('app.string.daily_note_home_coin_title'),
            `${homeCoinCurrent}/${homeCoinMax}`,
            homeCoinMax > 0 && homeCoinCurrent >= homeCoinMax ? $r('app.color.color_danger')
              : homeCoinMax > 0 && homeCoinCurrent / homeCoinMax >= 0.5 ? $r('app.color.color_warning')
              : $r('app.color.color_primary')
          );
        }
        if (data.finishedTaskNum >= 0) {
          rows[rows.length] = new GameDataRowVM(
            $r('app.string.daily_note_daily_task_title'),
            data.isExtraTaskRewardReceived
              ? $r('app.string.daily_note_task_all_received')
              : `${data.finishedTaskNum}/${data.totalTaskNum}`,
            data.isExtraTaskRewardReceived ? $r('app.color.color_primary')
              : data.finishedTaskNum === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        snap.dataRows = rows;
        snap.primaryColor = HomeCardPresenter.getPrimaryColor(gameId, data.currentResin, data.maxResin, isFull);
        return snap;
      }

      if (gameId === GameId.STARRAIL) {
        const row = await CoreInitializer.starRailRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = StarRailDailyNoteParser.parse(row.rawJson);
        const stamina = data.currentStamina > 0 ? data.currentStamina : row.currentStamina;
        const maxStamina = data.maxStamina > 0 ? data.maxStamina : row.maxStamina;
        const isFull = stamina >= maxStamina && maxStamina > 0;
        const recoverySeconds = isFull ? 0 : data.staminaRecoverTime;
        const snap = new GameNoteSnapshotVM(
          $r('app.string.starrail_stamina_title'), stamina, maxStamina, recoverySeconds, '', '', isFull
        );
        snap.reserveStamina = data.currentReserveStamina;
        snap.trainScoreCurrent = data.currentTrainScore;
        snap.trainScoreMax = data.maxTrainScore;
        snap.weeklyCocoonCnt = data.weeklyCocoonCnt;
        snap.weeklyCocoonLimit = data.weeklyCocoonLimit;
        snap.rogueScoreCurrent = data.currentRogueScore;
        snap.rogueScoreMax = data.maxRogueScore;
        snap.tournScoreCurrent = data.rogueTournWeeklyCur;
        snap.tournScoreMax = data.rogueTournWeeklyMax;

        // 数据行
        const starRailRows: GameDataRowVM[] = [];
        if (data.currentReserveStamina >= 0) {
          starRailRows[starRailRows.length] = new GameDataRowVM(
            $r('app.string.starrail_reserve_stamina_title'),
            `${data.currentReserveStamina}`,
            $r('app.color.gray_700')
          );
        }
        if (data.currentTrainScore >= 0) {
          starRailRows[starRailRows.length] = new GameDataRowVM(
            $r('app.string.starrail_train_score_title'),
            `${data.currentTrainScore}/${data.maxTrainScore}`,
            data.currentTrainScore >= data.maxTrainScore ? $r('app.color.color_primary')
              : data.currentTrainScore === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        if (data.weeklyCocoonCnt >= 0) {
          starRailRows[starRailRows.length] = new GameDataRowVM(
            $r('app.string.starrail_cocoon_title'),
            `${data.weeklyCocoonCnt}/${data.weeklyCocoonLimit}`,
            data.weeklyCocoonCnt >= data.weeklyCocoonLimit ? $r('app.color.color_primary')
              : data.weeklyCocoonCnt === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        if (data.currentRogueScore >= 0) {
          starRailRows[starRailRows.length] = new GameDataRowVM(
            $r('app.string.starrail_rogue_score_title'),
            `${data.currentRogueScore}/${data.maxRogueScore}`,
            data.currentRogueScore >= data.maxRogueScore ? $r('app.color.color_primary')
              : data.currentRogueScore === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        if (data.rogueTournWeeklyCur >= 0) {
          starRailRows[starRailRows.length] = new GameDataRowVM(
            $r('app.string.starrail_tourn_score_title'),
            `${data.rogueTournWeeklyCur}/${data.rogueTournWeeklyMax}`,
            data.rogueTournWeeklyCur >= data.rogueTournWeeklyMax ? $r('app.color.color_primary')
              : data.rogueTournWeeklyCur === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        snap.dataRows = starRailRows;
        snap.primaryColor = HomeCardPresenter.getPrimaryColor(gameId, stamina, maxStamina, isFull);
        return snap;
      }

      if (gameId === GameId.ZZZ) {
        const row = await CoreInitializer.zzzRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = ZZZDailyNoteParser.parse(row.rawJson);
        const energy = data.currentEnergy > 0 ? data.currentEnergy : row.energyCurrent;
        const maxEnergy = data.maxEnergy > 0 ? data.maxEnergy : row.energyMax;
        const isFull = energy >= maxEnergy && maxEnergy > 0;
        const recoverySeconds = isFull ? 0 : data.energyRecoverTime;
        const snap = new GameNoteSnapshotVM(
          $r('app.string.zzz_energy_title'), energy, maxEnergy, recoverySeconds, '', '', isFull
        );
        snap.vitalityCurrent = data.currentVitality;
        snap.vitalityMax = data.maxVitality;
        snap.scratchCardSign = data.cardSign === 'CardSignDone' ? ZZZCardSign.DONE : ZZZCardSign.TODO;
        if (data.videoStoreState === 'SaleStateDone') {
          snap.videoStoreState = ZZZVideoStoreState.DONE;
        } else if (data.videoStoreState === 'SaleStateDoing') {
          snap.videoStoreState = ZZZVideoStoreState.OPEN;
        } else if (data.videoStoreState === 'SaleStateNo') {
          snap.videoStoreState = ZZZVideoStoreState.CLOSED;
        } else {
          snap.videoStoreState = ZZZVideoStoreState.UNKNOWN;
        }

        // 数据行
        const zzzRows: GameDataRowVM[] = [];
        if (data.currentVitality >= 0) {
          zzzRows[zzzRows.length] = new GameDataRowVM(
            $r('app.string.zzz_vitality_title'),
            `${data.currentVitality}/${data.maxVitality}`,
            data.currentVitality >= data.maxVitality ? $r('app.color.color_primary')
              : data.currentVitality === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        const isCardSignDone = data.cardSign === 'CardSignDone';
        zzzRows[zzzRows.length] = new GameDataRowVM(
          $r('app.string.zzz_card_sign_title'),
          isCardSignDone ? $r('app.string.zzz_card_sign_done') : $r('app.string.zzz_card_sign_todo'),
          isCardSignDone ? $r('app.color.color_primary') : $r('app.color.color_danger')
        );
        if (data.videoStoreState !== '' && data.videoStoreState !== 'SaleStateUnknown') {
          let videoStoreValue: ResourceStr = $r('app.string.zzz_video_store_closed');
          let videoStoreColor: ResourceColor = $r('app.color.gray_700');
          if (data.videoStoreState === 'SaleStateDone') {
            videoStoreValue = $r('app.string.zzz_video_store_done');
            videoStoreColor = $r('app.color.color_primary');
          } else if (data.videoStoreState === 'SaleStateDoing') {
            videoStoreValue = $r('app.string.zzz_video_store_open');
            videoStoreColor = $r('app.color.color_warning');
          }
          zzzRows[zzzRows.length] = new GameDataRowVM(
            $r('app.string.zzz_video_store_title'),
            videoStoreValue,
            videoStoreColor
          );
        }
        snap.dataRows = zzzRows;
        snap.primaryColor = HomeCardPresenter.getPrimaryColor(gameId, energy, maxEnergy, isFull);
        return snap;
      }

      return null;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `loadDailyNoteSnapshot failed for ${gameId}/${roleUid}: ${msg}`);
      return null;
    }
  }

  /** 检查指定游戏角色是否需要同步 daily_note */
  static async shouldSyncDailyNote(accountId: string, roleUid: string, gameId: GameId): Promise<boolean> {
    if (gameId === GameId.GENSHIN) {
      return CoreInitializer.genshinRepository.needsDailyNoteSync(accountId, roleUid);
    }
    if (gameId === GameId.STARRAIL) {
      return CoreInitializer.starRailRepository.needsDailyNoteSync(accountId, roleUid);
    }
    if (gameId === GameId.ZZZ) {
      return CoreInitializer.zzzRepository.needsDailyNoteSync(accountId, roleUid);
    }
    return true;
  }

  /** 获取指定游戏角色的 daily_note 上次同步时间（Unix 秒级时间戳） */
  static async getDailyNoteLastSyncTime(accountId: string, roleUid: string, gameId: GameId): Promise<number> {
    if (gameId === GameId.GENSHIN) {
      return CoreInitializer.genshinRepository.getDailyNoteLastSyncTime(accountId, roleUid);
    }
    if (gameId === GameId.STARRAIL) {
      return CoreInitializer.starRailRepository.getDailyNoteLastSyncTime(accountId, roleUid);
    }
    if (gameId === GameId.ZZZ) {
      return CoreInitializer.zzzRepository.getDailyNoteLastSyncTime(accountId, roleUid);
    }
    return 0;
  }
}
