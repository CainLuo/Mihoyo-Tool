/**
 * MaterialBagRepository — 材料背包 Repository
 *
 * 提供材料背包数据的读写接口，供 entry 层调用。
 * 每个游戏有独立的材料背包表，通过对应的 DAO 访问数据库。
 *
 * 唯一键：(account_id, role_uid, material_id)
 * 同一个米游社账号下，不同游戏角色的背包是独立的。
 *
 * 使用方法：
 * ```typescript
 * const repo = new MaterialBagRepository();
 * // 原神材料
 * const genshinMaterials = await repo.getMaterials(accountId, roleUid, GameId.GENSHIN);
 * // 星铁材料
 * const starrailMaterials = await repo.getMaterials(accountId, roleUid, GameId.STARRAIL);
 * ```
 */

import {
  GenshinMaterialBagDao,
  StarRailMaterialBagDao,
  ZZZMaterialBagDao,
  BaseMaterialBagDao
} from '../database/MaterialBagDao';
import { MaterialBagRow } from '../models/MaterialBagRow';
import { GameId } from '../constants/GameId';
import { Logger } from '../utils/Logger';

const TAG = 'MaterialBagRepository';

export class MaterialBagRepository {
  private genshinDao: GenshinMaterialBagDao = new GenshinMaterialBagDao();
  private starrailDao: StarRailMaterialBagDao = new StarRailMaterialBagDao();
  private zzzDao: ZZZMaterialBagDao = new ZZZMaterialBagDao();

  /**
   * 根据游戏 ID 获取对应的 DAO
   */
  private getDao(gameId: GameId): BaseMaterialBagDao {
    if (gameId === GameId.GENSHIN) {
      return this.genshinDao;
    }
    if (gameId === GameId.STARRAIL) {
      return this.starrailDao;
    }
    if (gameId === GameId.ZZZ) {
      return this.zzzDao;
    }
    throw new Error(`Unsupported gameId for material bag: ${gameId}`);
  }

  // ── 查询方法 ─────────────────────────────────────────────────────

  /**
   * 查询指定游戏角色的材料
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param gameId 游戏标识
   * @returns 材料数据数组
   */
  async getMaterials(accountId: string, roleUid: string, gameId: GameId): Promise<MaterialBagRow[]> {
    const dao = this.getDao(gameId);
    return dao.findByRole(accountId, roleUid);
  }

  /**
   * 查询单个材料
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param materialId 材料 ID（字符串）
   * @param gameId 游戏标识
   * @returns 材料数据，不存在时返回 null
   */
  async getMaterial(accountId: string, roleUid: string, materialId: string, gameId: GameId): Promise<MaterialBagRow | null> {
    const dao = this.getDao(gameId);
    return dao.findOne(accountId, roleUid, materialId);
  }

  // ── 写入方法 ─────────────────────────────────────────────────────

  /**
   * 批量写入材料数据（覆盖式更新）
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param rows 材料数据数组
   * @param gameId 游戏标识
   */
  async upsertMaterials(accountId: string, roleUid: string, rows: MaterialBagRow[], gameId: GameId): Promise<void> {
    const dao = this.getDao(gameId);
    await dao.upsertAll(accountId, roleUid, rows);
    Logger.info(TAG, `upsertMaterials: ${rows.length} materials for account ${accountId}, role ${roleUid}, game ${gameId}`);
  }

  /**
   * 更新单个材料的数量
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param materialId 材料 ID（字符串）
   * @param gameId 游戏标识
   * @param count 新数量
   */
  async updateMaterialCount(accountId: string, roleUid: string, materialId: string, gameId: GameId, count: number): Promise<void> {
    const dao = this.getDao(gameId);
    await dao.updateCount(accountId, roleUid, materialId, count);
  }

  // ── 删除方法 ─────────────────────────────────────────────────────

  /**
   * 删除指定账号下所有游戏的材料
   * @param accountId 米游社账号 UID
   */
  async deleteAllMaterials(accountId: string): Promise<void> {
    await this.genshinDao.deleteByAccount(accountId);
    await this.starrailDao.deleteByAccount(accountId);
    await this.zzzDao.deleteByAccount(accountId);
    Logger.info(TAG, `deleteAllMaterials: all materials deleted for account ${accountId}`);
  }

  /**
   * 删除指定游戏角色的材料
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param gameId 游戏标识
   */
  async deleteMaterialsByRole(accountId: string, roleUid: string, gameId: GameId): Promise<void> {
    const dao = this.getDao(gameId);
    await dao.deleteByRole(accountId, roleUid);
    Logger.info(TAG, `deleteMaterialsByRole: ${gameId} materials deleted for account ${accountId}, role ${roleUid}`);
  }

  // ── 同步状态检查 ─────────────────────────────────────────────────

  /**
   * 检查材料背包是否需要同步
   * 材料背包不使用 sync_meta，每次打开页面都从 API 拉取最新数据
   * @returns 始终返回 true（材料数据需要实时拉取）
   */
  async needsMaterialSync(_accountId: string, _roleUid: string, _gameId: GameId): Promise<boolean> {
    return true;
  }
}
