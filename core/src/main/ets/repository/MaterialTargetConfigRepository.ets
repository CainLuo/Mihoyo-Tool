/**
 * MaterialTargetConfigRepository — 养成目标配置 Repository
 *
 * 提供养成目标配置数据的读写接口，供 entry 层调用。
 * 每个游戏有独立的配置表，通过对应的 DAO 访问数据库。
 *
 * 唯一键：(account_id, role_uid)
 * 同一个米游社账号下，不同游戏角色的配置是独立的。
 *
 * 使用方法：
 * ```typescript
 * const repo = new MaterialTargetConfigRepository();
 * // 原神配置
 * const genshinConfig = await repo.getConfig(accountId, roleUid, GameId.GENSHIN);
 * // 星铁配置
 * const starrailConfig = await repo.getConfig(accountId, roleUid, GameId.STARRAIL);
 * // 保存配置
 * await repo.saveConfig(accountId, roleUid, configRow, GameId.GENSHIN);
 * ```
 */

import {
  GenshinMaterialTargetConfigDao,
  StarRailMaterialTargetConfigDao,
  ZZZMaterialTargetConfigDao,
  BaseMaterialTargetConfigDao
} from '../database/MaterialTargetConfigDao';
import {
  MaterialTargetConfigRow,
  GenshinMaterialTargetConfigJson,
  StarRailMaterialTargetConfigJson,
  ZZZMaterialTargetConfigJson,
  LevelConfig,
  SkillLevelConfig
} from '../models/MaterialTargetConfigRow';
import { GameId } from '../constants/GameId';
import { Logger } from '../utils/Logger';

const TAG = 'MaterialTargetConfigRepository';

export class MaterialTargetConfigRepository {
  private genshinDao: GenshinMaterialTargetConfigDao = new GenshinMaterialTargetConfigDao();
  private starrailDao: StarRailMaterialTargetConfigDao = new StarRailMaterialTargetConfigDao();
  private zzzDao: ZZZMaterialTargetConfigDao = new ZZZMaterialTargetConfigDao();

  /**
   * 根据游戏 ID 获取对应的 DAO
   */
  private getDao(gameId: GameId): BaseMaterialTargetConfigDao {
    if (gameId === GameId.GENSHIN) {
      return this.genshinDao;
    }
    if (gameId === GameId.STARRAIL) {
      return this.starrailDao;
    }
    if (gameId === GameId.ZZZ) {
      return this.zzzDao;
    }
    throw new Error(`Unsupported gameId for material target config: ${gameId}`);
  }

  // ── 查询方法 ─────────────────────────────────────────────────────

  /**
   * 查询指定游戏角色的养成目标配置
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param gameId 游戏标识
   * @returns 配置数据，不存在时返回 null
   */
  async getConfig(accountId: string, roleUid: string, gameId: GameId): Promise<MaterialTargetConfigRow | null> {
    const dao = this.getDao(gameId);
    return dao.findOne(accountId, roleUid);
  }

  /**
   * 查询原神养成目标配置并解析为结构化对象
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @returns 解析后的配置对象，不存在时返回默认配置
   */
  async getGenshinConfig(accountId: string, roleUid: string): Promise<GenshinMaterialTargetConfigJson> {
    const row = await this.genshinDao.findOne(accountId, roleUid);
    if (!row || !row.configJson) {
      return new GenshinMaterialTargetConfigJson();
    }
    try {
      return this.parseGenshinConfig(row.configJson);
    } catch (e) {
      Logger.warn(TAG, `Failed to parse Genshin config for ${accountId}/${roleUid}, returning default: ${e}`);
      return new GenshinMaterialTargetConfigJson();
    }
  }

  /**
   * 查询星穹铁道养成目标配置并解析为结构化对象
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @returns 解析后的配置对象，不存在时返回默认配置
   */
  async getStarRailConfig(accountId: string, roleUid: string): Promise<StarRailMaterialTargetConfigJson> {
    const row = await this.starrailDao.findOne(accountId, roleUid);
    if (!row || !row.configJson) {
      return new StarRailMaterialTargetConfigJson();
    }
    try {
      return this.parseStarRailConfig(row.configJson);
    } catch (e) {
      Logger.warn(TAG, `Failed to parse StarRail config for ${accountId}/${roleUid}, returning default: ${e}`);
      return new StarRailMaterialTargetConfigJson();
    }
  }

  /**
   * 查询绝区零养成目标配置并解析为结构化对象
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @returns 解析后的配置对象，不存在时返回默认配置
   */
  async getZZZConfig(accountId: string, roleUid: string): Promise<ZZZMaterialTargetConfigJson> {
    const row = await this.zzzDao.findOne(accountId, roleUid);
    if (!row || !row.configJson) {
      return new ZZZMaterialTargetConfigJson();
    }
    try {
      return this.parseZZZConfig(row.configJson);
    } catch (e) {
      Logger.warn(TAG, `Failed to parse ZZZ config for ${accountId}/${roleUid}, returning default: ${e}`);
      return new ZZZMaterialTargetConfigJson();
    }
  }

  // ── 写入方法 ─────────────────────────────────────────────────────

  /**
   * 保存养成目标配置
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param configRow 配置数据（configJson 必须是有效的 JSON 字符串）
   * @param gameId 游戏标识
   */
  async saveConfig(accountId: string, roleUid: string, configRow: MaterialTargetConfigRow, gameId: GameId): Promise<void> {
    const dao = this.getDao(gameId);
    configRow.accountId = accountId;
    configRow.roleUid = roleUid;
    await dao.upsert(configRow);
    Logger.info(TAG, `saveConfig: config saved for account ${accountId}, role ${roleUid}, game ${gameId}`);
  }

  /**
   * 保存原神养成目标配置
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param config 配置对象（会自动序列化为 JSON）
   */
  async saveGenshinConfig(accountId: string, roleUid: string, config: GenshinMaterialTargetConfigJson): Promise<void> {
    const row = new MaterialTargetConfigRow();
    row.accountId = accountId;
    row.roleUid = roleUid;
    row.configJson = JSON.stringify(config);
    await this.genshinDao.upsert(row);
    Logger.info(TAG, `saveGenshinConfig: config saved for account ${accountId}, role ${roleUid}`);
  }

  /**
   * 保存星穹铁道养成目标配置
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param config 配置对象（会自动序列化为 JSON）
   */
  async saveStarRailConfig(accountId: string, roleUid: string, config: StarRailMaterialTargetConfigJson): Promise<void> {
    const row = new MaterialTargetConfigRow();
    row.accountId = accountId;
    row.roleUid = roleUid;
    row.configJson = JSON.stringify(config);
    await this.starrailDao.upsert(row);
    Logger.info(TAG, `saveStarRailConfig: config saved for account ${accountId}, role ${roleUid}`);
  }

  /**
   * 保存绝区零养成目标配置
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param config 配置对象（会自动序列化为 JSON）
   */
  async saveZZZConfig(accountId: string, roleUid: string, config: ZZZMaterialTargetConfigJson): Promise<void> {
    const row = new MaterialTargetConfigRow();
    row.accountId = accountId;
    row.roleUid = roleUid;
    row.configJson = JSON.stringify(config);
    await this.zzzDao.upsert(row);
    Logger.info(TAG, `saveZZZConfig: config saved for account ${accountId}, role ${roleUid}`);
  }

  // ── 删除方法 ─────────────────────────────────────────────────────

  /**
   * 删除指定账号下所有游戏的配置
   * @param accountId 米游社账号 UID
   */
  async deleteAllConfigs(accountId: string): Promise<void> {
    await this.genshinDao.deleteByAccount(accountId);
    await this.starrailDao.deleteByAccount(accountId);
    await this.zzzDao.deleteByAccount(accountId);
    Logger.info(TAG, `deleteAllConfigs: all configs deleted for account ${accountId}`);
  }

  /**
   * 删除指定游戏角色的配置
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param gameId 游戏标识
   */
  async deleteConfig(accountId: string, roleUid: string, gameId: GameId): Promise<void> {
    const dao = this.getDao(gameId);
    await dao.deleteOne(accountId, roleUid);
    Logger.info(TAG, `deleteConfig: ${gameId} config deleted for account ${accountId}, role ${roleUid}`);
  }

  // ── JSON 解析方法 ───────────────────────────────────────────────

  /**
   * 解析原神配置 JSON
   */
  private parseGenshinConfig(json: string): GenshinMaterialTargetConfigJson {
    const obj = JSON.parse(json) as Record<string, Object>;
    const config = new GenshinMaterialTargetConfigJson();

    if (obj['avatar']) {
      config.avatar = this.parseLevelConfig(obj['avatar'] as Record<string, Object>);
    }
    if (obj['skill']) {
      config.skill = this.parseLevelConfig(obj['skill'] as Record<string, Object>);
    }
    if (obj['weapon']) {
      config.weapon = this.parseLevelConfig(obj['weapon'] as Record<string, Object>);
    }

    return config;
  }

  /**
   * 解析星穹铁道配置 JSON
   */
  private parseStarRailConfig(json: string): StarRailMaterialTargetConfigJson {
    const obj = JSON.parse(json) as Record<string, Object>;
    const config = new StarRailMaterialTargetConfigJson();

    if (obj['avatar']) {
      config.avatar = this.parseLevelConfig(obj['avatar'] as Record<string, Object>);
    }
    if (obj['skill']) {
      config.skill = this.parseLevelConfig(obj['skill'] as Record<string, Object>);
    }
    if (obj['lightCone']) {
      config.lightCone = this.parseLevelConfig(obj['lightCone'] as Record<string, Object>);
    }

    return config;
  }

  /**
   * 解析绝区零配置 JSON
   */
  private parseZZZConfig(json: string): ZZZMaterialTargetConfigJson {
    const obj = JSON.parse(json) as Record<string, Object>;
    const config = new ZZZMaterialTargetConfigJson();

    if (obj['avatar']) {
      config.avatar = this.parseLevelConfig(obj['avatar'] as Record<string, Object>);
    }
    if (obj['weapon']) {
      config.weapon = this.parseLevelConfig(obj['weapon'] as Record<string, Object>);
    }
    if (obj['skills'] && Array.isArray(obj['skills'])) {
      config.skills = obj['skills'].map((item: Object) => this.parseSkillLevelConfig(item as Record<string, Object>));
    }

    return config;
  }

  /**
   * 解析等级配置
   */
  private parseLevelConfig(obj: Record<string, Object>): LevelConfig {
    const config = new LevelConfig();
    if (typeof obj['current'] === 'number') {
      config.current = obj['current'];
    }
    if (typeof obj['target'] === 'number') {
      config.target = obj['target'];
    }
    return config;
  }

  /**
   * 解析技能等级配置（绝区零专用）
   */
  private parseSkillLevelConfig(obj: Record<string, Object>): SkillLevelConfig {
    const config = new SkillLevelConfig();
    if (typeof obj['skillType'] === 'number') {
      config.skillType = obj['skillType'];
    }
    if (typeof obj['current'] === 'number') {
      config.current = obj['current'];
    }
    if (typeof obj['target'] === 'number') {
      config.target = obj['target'];
    }
    return config;
  }
}
