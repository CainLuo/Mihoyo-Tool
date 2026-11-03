/**
 * StaminaNoteReader.ets — 读取并解析三游戏 daily_note 快照
 *
 * 通知设置页只需要 maxStamina，通知调度服务还需要 recoveryTime / currentStamina。
 * 两个调用方原本各写一套「按 gameId 选 repository + parser + 行数据兜底」的 if 链，
 * 这里收敛为唯一实现。
 *
 * 注意：返回的 maxStamina 是「DB / API 原始上限」，0 表示没有可用数据；
 * 是否套用 fallback 由调用方决定（服务层需要 fallback，设置页不需要）。
 */
import {
  CoreInitializer,
  Logger,
  GameId,
  GenshinDailyNoteParser,
  StarRailDailyNoteParser,
  ZZZDailyNoteParser,
} from 'core';
import { StaminaThresholdCalculator } from './StaminaThresholdCalculator';

const TAG: string = 'StaminaNoteReader';

/** 单次 daily_note 读取结果 */
export class StaminaSnapshot {
  /** 距离满值还需秒数 */
  recoveryTime: number = 0;
  /** 体力上限（0 表示无数据） */
  maxStamina: number = 0;
  /** 当前体力 */
  currentStamina: number = 0;
}

export class StaminaNoteReader {
  /**
   * 读取指定账号 / 角色 / 游戏的 daily_note。
   * 无记录或解析异常时返回 null。
   */
  static async read(accountId: string, roleUid: string, gameId: GameId): Promise<StaminaSnapshot | null> {
    try {
      if (gameId === GameId.GENSHIN) {
        const row = await CoreInitializer.genshinRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = GenshinDailyNoteParser.parse(row.rawJson);
        const snapshot = new StaminaSnapshot();
        snapshot.recoveryTime = StaminaThresholdCalculator.parseGenshinRecoveryTime(data.resinRecoveryTime);
        snapshot.maxStamina = data.maxResin > 0 ? data.maxResin : row.maxResin;
        snapshot.currentStamina = data.currentResin;
        return snapshot;
      }
      if (gameId === GameId.STARRAIL) {
        const row = await CoreInitializer.starRailRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = StarRailDailyNoteParser.parse(row.rawJson);
        const snapshot = new StaminaSnapshot();
        snapshot.recoveryTime = data.staminaRecoverTime;
        snapshot.maxStamina = data.maxStamina > 0 ? data.maxStamina : row.maxStamina;
        snapshot.currentStamina = data.currentStamina > 0 ? data.currentStamina : row.currentStamina;
        return snapshot;
      }
      if (gameId === GameId.ZZZ) {
        const row = await CoreInitializer.zzzRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = ZZZDailyNoteParser.parse(row.rawJson);
        const snapshot = new StaminaSnapshot();
        snapshot.recoveryTime = data.energyRecoverTime;
        snapshot.maxStamina = data.maxEnergy > 0 ? data.maxEnergy : row.energyMax;
        snapshot.currentStamina = data.currentEnergy > 0 ? data.currentEnergy : row.energyCurrent;
        return snapshot;
      }
      return null;
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.warn(TAG, `read failed for ${gameId}/${roleUid}: ${msg}`);
      return null;
    }
  }
}
