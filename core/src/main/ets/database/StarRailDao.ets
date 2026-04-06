/**
 * StarRailDao — 星穹铁道四张专用表的 DAO 集合
 *
 * 包含四个 DAO 类，分别对应星穹铁道的四张数据表：
 * - StarRailAvatarBasicDao：角色基础信息（starrail_avatar_basic）
 * - StarRailDailyNoteDao：实时便笺（starrail_daily_note）
 * - StarRailAvatarInfoDao：角色详情（starrail_avatar_info）
 * - StarRailAvatarComputeDao：养成计算（starrail_avatar_compute）
 *
 * 所有写入操作使用 INSERT OR REPLACE（依赖 UNIQUE 索引实现 upsert 语义）。
 * 所有读取操作通过 RdbManagerV2.queryFirst/queryAll 封装，自动管理 ResultSet 生命周期。
 */
import { relationalStore } from '@kit.ArkData';
import { RdbManager } from './RdbManager';
import {
  TableName, CommonCol,
  StarRailAvatarBasicCol, StarRailDailyNoteCol, StarRailAvatarInfoCol, StarRailAvatarComputeCol,
  STARRAIL_AVATAR_BASIC_TABLE, STARRAIL_DAILY_NOTE_TABLE,
  STARRAIL_AVATAR_INFO_TABLE, STARRAIL_AVATAR_COMPUTE_TABLE
} from './TableSchema';
import {
  StarRailAvatarBasicRow,
  StarRailDailyNoteRow,
  StarRailAvatarInfoRow,
  StarRailAvatarComputeRow
} from '../models/StarRailRows';

// ─────────────────────────────────────────────
// StarRailAvatarBasicDao：操作 starrail_avatar_basic
// ─────────────────────────────────────────────
export class StarRailAvatarBasicDao {

  /**
   * 批量写入星穹铁道角色基础信息（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid, avatar_id)，重复时覆盖旧数据。
   * @param rows 角色基础信息行数组，为空时直接返回
   */
  async upsertAll(rows: StarRailAvatarBasicRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    const columns = STARRAIL_AVATAR_BASIC_TABLE.columnNames();
    try {
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
        await RdbManager.upsertRow(TableName.STARRAIL_AVATAR_BASIC, columns, [
          idVal, row.accountId, row.roleUid, row.avatarId, row.name, row.element,
          row.rarity, row.level, row.rank, row.baseType, row.equipId, row.equipName,
          row.equipRarity, row.equipLevel, row.equipRank, row.icon, row.figurePath,
          row.elementId, row.rawJson, row.updateTime
        ]);
      }
    } catch (e) {
      throw new Error(`StarRailAvatarBasicDao.upsertAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询指定账号和角色的所有星穹铁道角色基础信息。
   * @param accountId 米游社账号 ID
   * @param roleUid   游戏角色 UID
   */
  async findAll(accountId: number, roleUid: string): Promise<StarRailAvatarBasicRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_BASIC);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManager.queryAll(predicates, STARRAIL_AVATAR_BASIC_TABLE.columnNames(), (rs) => StarRailAvatarBasicDao.mapRow(rs));
    } catch (e) {
      throw new Error(`StarRailAvatarBasicDao.findAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 avatarId 查询单条星穹铁道角色基础信息。
   * @returns 找到时返回对应行，否则返回 null
   */
  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<StarRailAvatarBasicRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_BASIC);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManager.queryFirst(predicates, STARRAIL_AVATAR_BASIC_TABLE.columnNames(), (rs) => StarRailAvatarBasicDao.mapRow(rs));
    } catch (e) {
      throw new Error(`StarRailAvatarBasicDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有星穹铁道角色基础信息记录 */
  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_BASIC);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`StarRailAvatarBasicDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 StarRailAvatarBasicRow */
  private static mapRow(rs: relationalStore.ResultSet): StarRailAvatarBasicRow {
    try {
      const row = new StarRailAvatarBasicRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex(CommonCol.AVATAR_ID));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const nameVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.NAME));
      row.name = typeof nameVal === 'string' ? nameVal : '';
      const elementVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.ELEMENT));
      row.element = typeof elementVal === 'string' ? elementVal : '';
      const rarityVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.RARITY));
      row.rarity = typeof rarityVal === 'number' ? rarityVal : 0;
      const levelVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.LEVEL));
      row.level = typeof levelVal === 'number' ? levelVal : 0;
      const rankVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.RANK));
      row.rank = typeof rankVal === 'number' ? rankVal : 0;
      const baseTypeVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.BASE_TYPE));
      row.baseType = typeof baseTypeVal === 'number' ? baseTypeVal : 0;
      const equipIdVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.EQUIP_ID));
      row.equipId = typeof equipIdVal === 'string' ? equipIdVal : '';
      const equipNameVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.EQUIP_NAME));
      row.equipName = typeof equipNameVal === 'string' ? equipNameVal : '';
      const equipRarityVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.EQUIP_RARITY));
      row.equipRarity = typeof equipRarityVal === 'number' ? equipRarityVal : 0;
      const equipLevelVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.EQUIP_LEVEL));
      row.equipLevel = typeof equipLevelVal === 'number' ? equipLevelVal : 0;
      const equipRankVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.EQUIP_RANK));
      row.equipRank = typeof equipRankVal === 'number' ? equipRankVal : 0;
      const iconVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.ICON));
      row.icon = typeof iconVal === 'string' ? iconVal : '';
      const figurePathVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.FIGURE_PATH));
      row.figurePath = typeof figurePathVal === 'string' ? figurePathVal : '';
      const elementIdVal = rs.getValue(rs.getColumnIndex(StarRailAvatarBasicCol.ELEMENT_ID));
      row.elementId = typeof elementIdVal === 'number' ? elementIdVal : 0;
      const rawJsonVal = rs.getValue(rs.getColumnIndex(CommonCol.RAW_JSON));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex(CommonCol.UPDATE_TIME));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      return row;
    } catch (e) {
      throw new Error(`StarRailAvatarBasicDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

// ─────────────────────────────────────────────
// StarRailDailyNoteDao：操作 starrail_daily_note
// ─────────────────────────────────────────────
export class StarRailDailyNoteDao {

  /**
   * 写入星穹铁道实时便笺（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid)，每个角色只保留一条最新记录。
   * @param row 便笺行数据
   */
  async upsert(row: StarRailDailyNoteRow): Promise<void> {
    const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
    try {
      await RdbManager.upsertRow(TableName.STARRAIL_DAILY_NOTE, STARRAIL_DAILY_NOTE_TABLE.columnNames(), [
        idVal, row.accountId, row.roleUid, row.currentStamina, row.maxStamina,
        row.staminaRecoverTime, row.staminaFullTs, row.currentReserveStamina,
        row.acceptedExpeditionNum, row.totalExpeditionNum, row.currentTrainScore,
        row.maxTrainScore, row.currentRogueScore, row.maxRogueScore,
        row.weeklyCocoonCnt, row.weeklyCocoonLimit, row.rogueTournWeeklyCur,
        row.rogueTournWeeklyMax, row.gridFightWeeklyCur, row.gridFightWeeklyMax,
        row.rawJson, row.updateTime
      ]);
    } catch (e) {
      throw new Error(`StarRailDailyNoteDao.upsert failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询指定角色的星穹铁道实时便笺。
   * @returns 找到时返回便笺行，否则返回 null
   */
  async findOne(accountId: number, roleUid: string): Promise<StarRailDailyNoteRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_DAILY_NOTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManager.queryFirst(predicates, STARRAIL_DAILY_NOTE_TABLE.columnNames(), (rs) => StarRailDailyNoteDao.mapRow(rs));
    } catch (e) {
      throw new Error(`StarRailDailyNoteDao.findOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定角色的星穹铁道实时便笺记录 */
  async deleteOne(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_DAILY_NOTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`StarRailDailyNoteDao.deleteOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 StarRailDailyNoteRow */
  private static mapRow(rs: relationalStore.ResultSet): StarRailDailyNoteRow {
    try {
      const row = new StarRailDailyNoteRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const currentStaminaVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.CURRENT_STAMINA));
      row.currentStamina = typeof currentStaminaVal === 'number' ? currentStaminaVal : 0;
      const maxStaminaVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.MAX_STAMINA));
      row.maxStamina = typeof maxStaminaVal === 'number' ? maxStaminaVal : 0;
      const staminaRecoverVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.STAMINA_RECOVER_TIME));
      row.staminaRecoverTime = typeof staminaRecoverVal === 'number' ? staminaRecoverVal : 0;
      const staminaFullTsVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.STAMINA_FULL_TS));
      row.staminaFullTs = typeof staminaFullTsVal === 'number' ? staminaFullTsVal : 0;
      const reserveStaminaVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.CURRENT_RESERVE_STAMINA));
      row.currentReserveStamina = typeof reserveStaminaVal === 'number' ? reserveStaminaVal : 0;
      const acceptedExpeditionVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.ACCEPTED_EXPEDITION_NUM));
      row.acceptedExpeditionNum = typeof acceptedExpeditionVal === 'number' ? acceptedExpeditionVal : 0;
      const totalExpeditionVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.TOTAL_EXPEDITION_NUM));
      row.totalExpeditionNum = typeof totalExpeditionVal === 'number' ? totalExpeditionVal : 0;
      const currentTrainVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.CURRENT_TRAIN_SCORE));
      row.currentTrainScore = typeof currentTrainVal === 'number' ? currentTrainVal : 0;
      const maxTrainVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.MAX_TRAIN_SCORE));
      row.maxTrainScore = typeof maxTrainVal === 'number' ? maxTrainVal : 0;
      const currentRogueVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.CURRENT_ROGUE_SCORE));
      row.currentRogueScore = typeof currentRogueVal === 'number' ? currentRogueVal : 0;
      const maxRogueVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.MAX_ROGUE_SCORE));
      row.maxRogueScore = typeof maxRogueVal === 'number' ? maxRogueVal : 0;
      const weeklyCocoonCntVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.WEEKLY_COCOON_CNT));
      row.weeklyCocoonCnt = typeof weeklyCocoonCntVal === 'number' ? weeklyCocoonCntVal : 0;
      const weeklyCocoonLimitVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.WEEKLY_COCOON_LIMIT));
      row.weeklyCocoonLimit = typeof weeklyCocoonLimitVal === 'number' ? weeklyCocoonLimitVal : 0;
      const rogueTournCurVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.ROGUE_TOURN_WEEKLY_CUR));
      row.rogueTournWeeklyCur = typeof rogueTournCurVal === 'number' ? rogueTournCurVal : 0;
      const rogueTournMaxVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.ROGUE_TOURN_WEEKLY_MAX));
      row.rogueTournWeeklyMax = typeof rogueTournMaxVal === 'number' ? rogueTournMaxVal : 0;
      const gridFightCurVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.GRID_FIGHT_WEEKLY_CUR));
      row.gridFightWeeklyCur = typeof gridFightCurVal === 'number' ? gridFightCurVal : 0;
      const gridFightMaxVal = rs.getValue(rs.getColumnIndex(StarRailDailyNoteCol.GRID_FIGHT_WEEKLY_MAX));
      row.gridFightWeeklyMax = typeof gridFightMaxVal === 'number' ? gridFightMaxVal : 0;
      const rawJsonVal = rs.getValue(rs.getColumnIndex(CommonCol.RAW_JSON));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex(CommonCol.UPDATE_TIME));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      return row;
    } catch (e) {
      throw new Error(`StarRailDailyNoteDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

// ─────────────────────────────────────────────
// StarRailAvatarInfoDao：操作 starrail_avatar_info
// ─────────────────────────────────────────────
export class StarRailAvatarInfoDao {

  /**
   * 批量写入星穹铁道角色详情（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid, avatar_id)，重复时覆盖旧数据。
   * @param rows 角色详情行数组，为空时直接返回
   */
  async upsertAll(rows: StarRailAvatarInfoRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    const columns = STARRAIL_AVATAR_INFO_TABLE.columnNames();
    try {
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
        await RdbManager.upsertRow(TableName.STARRAIL_AVATAR_INFO, columns, [
          idVal, row.accountId, row.roleUid, row.avatarId, row.equipId,
          row.equipLevel, row.equipRank, row.relicIds, row.skillTreeJson,
          row.rawJson, row.updateTime
        ]);
      }
    } catch (e) {
      throw new Error(`StarRailAvatarInfoDao.upsertAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 avatarId 查询星穹铁道角色详情。
   * @returns 找到时返回详情行，否则返回 null
   */
  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<StarRailAvatarInfoRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_INFO);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManager.queryFirst(predicates, STARRAIL_AVATAR_INFO_TABLE.columnNames(), (rs) => StarRailAvatarInfoDao.mapRow(rs));
    } catch (e) {
      throw new Error(`StarRailAvatarInfoDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有星穹铁道角色详情记录 */
  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_INFO);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`StarRailAvatarInfoDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 StarRailAvatarInfoRow */
  private static mapRow(rs: relationalStore.ResultSet): StarRailAvatarInfoRow {
    try {
      const row = new StarRailAvatarInfoRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex(CommonCol.AVATAR_ID));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const equipIdVal = rs.getValue(rs.getColumnIndex(StarRailAvatarInfoCol.EQUIP_ID));
      row.equipId = typeof equipIdVal === 'string' ? equipIdVal : '';
      const equipLevelVal = rs.getValue(rs.getColumnIndex(StarRailAvatarInfoCol.EQUIP_LEVEL));
      row.equipLevel = typeof equipLevelVal === 'number' ? equipLevelVal : 0;
      const equipRankVal = rs.getValue(rs.getColumnIndex(StarRailAvatarInfoCol.EQUIP_RANK));
      row.equipRank = typeof equipRankVal === 'number' ? equipRankVal : 0;
      const relicIdsVal = rs.getValue(rs.getColumnIndex(StarRailAvatarInfoCol.RELIC_IDS));
      row.relicIds = typeof relicIdsVal === 'string' ? relicIdsVal : '';
      const skillTreeJsonVal = rs.getValue(rs.getColumnIndex(StarRailAvatarInfoCol.SKILL_TREE_JSON));
      row.skillTreeJson = typeof skillTreeJsonVal === 'string' ? skillTreeJsonVal : '';
      const rawJsonVal = rs.getValue(rs.getColumnIndex(CommonCol.RAW_JSON));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex(CommonCol.UPDATE_TIME));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      return row;
    } catch (e) {
      throw new Error(`StarRailAvatarInfoDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

// ─────────────────────────────────────────────
// StarRailAvatarComputeDao：操作 starrail_avatar_compute
// ─────────────────────────────────────────────
export class StarRailAvatarComputeDao {

  /**
   * 写入星穹铁道角色养成计算数据（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid, avatar_id)，重复时覆盖旧数据。
   * @param row 养成计算行数据
   */
  async upsert(row: StarRailAvatarComputeRow): Promise<void> {
    const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
    try {
      await RdbManager.upsertRow(TableName.STARRAIL_AVATAR_COMPUTE, STARRAIL_AVATAR_COMPUTE_TABLE.columnNames(), [
        idVal, row.accountId, row.roleUid, row.avatarId,
        row.avatarConsumeJson, row.skillConsumeJson, row.equipmentConsumeJson, row.updateTime
      ]);
    } catch (e) {
      throw new Error(`StarRailAvatarComputeDao.upsert failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 avatarId 查询星穹铁道角色养成计算数据。
   * @returns 找到时返回计算行，否则返回 null
   */
  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<StarRailAvatarComputeRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_COMPUTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManager.queryFirst(predicates, STARRAIL_AVATAR_COMPUTE_TABLE.columnNames(), (rs) => StarRailAvatarComputeDao.mapRow(rs));
    } catch (e) {
      throw new Error(`StarRailAvatarComputeDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有星穹铁道养成计算记录 */
  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_COMPUTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`StarRailAvatarComputeDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 StarRailAvatarComputeRow */
  private static mapRow(rs: relationalStore.ResultSet): StarRailAvatarComputeRow {
    try {
      const row = new StarRailAvatarComputeRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex(CommonCol.AVATAR_ID));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const avatarConsumeVal = rs.getValue(rs.getColumnIndex(StarRailAvatarComputeCol.AVATAR_CONSUME_JSON));
      row.avatarConsumeJson = typeof avatarConsumeVal === 'string' ? avatarConsumeVal : '';
      const skillConsumeVal = rs.getValue(rs.getColumnIndex(StarRailAvatarComputeCol.SKILL_CONSUME_JSON));
      row.skillConsumeJson = typeof skillConsumeVal === 'string' ? skillConsumeVal : '';
      const equipmentConsumeVal = rs.getValue(rs.getColumnIndex(StarRailAvatarComputeCol.EQUIPMENT_CONSUME_JSON));
      row.equipmentConsumeJson = typeof equipmentConsumeVal === 'string' ? equipmentConsumeVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex(CommonCol.UPDATE_TIME));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      return row;
    } catch (e) {
      throw new Error(`StarRailAvatarComputeDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}
