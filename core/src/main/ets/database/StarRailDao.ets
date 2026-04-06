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
 * 所有读取操作通过 RdbManager.queryFirst/queryAll 封装，自动管理 ResultSet 生命周期。
 */
import { relationalStore } from '@kit.ArkData';
import { RdbManager } from './RdbManager';
import { RsReader } from './RsReader';
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
      const r = new RsReader(rs);
      const row = new StarRailAvatarBasicRow();
      row.id          = r.num(CommonCol.ID);
      row.accountId   = r.num(CommonCol.ACCOUNT_ID);
      row.roleUid     = r.str(CommonCol.ROLE_UID);
      row.avatarId    = r.str(CommonCol.AVATAR_ID);
      row.name        = r.str(StarRailAvatarBasicCol.NAME);
      row.element     = r.str(StarRailAvatarBasicCol.ELEMENT);
      row.rarity      = r.num(StarRailAvatarBasicCol.RARITY);
      row.level       = r.num(StarRailAvatarBasicCol.LEVEL);
      row.rank        = r.num(StarRailAvatarBasicCol.RANK);
      row.baseType    = r.num(StarRailAvatarBasicCol.BASE_TYPE);
      row.equipId     = r.str(StarRailAvatarBasicCol.EQUIP_ID);
      row.equipName   = r.str(StarRailAvatarBasicCol.EQUIP_NAME);
      row.equipRarity = r.num(StarRailAvatarBasicCol.EQUIP_RARITY);
      row.equipLevel  = r.num(StarRailAvatarBasicCol.EQUIP_LEVEL);
      row.equipRank   = r.num(StarRailAvatarBasicCol.EQUIP_RANK);
      row.icon        = r.str(StarRailAvatarBasicCol.ICON);
      row.figurePath  = r.str(StarRailAvatarBasicCol.FIGURE_PATH);
      row.elementId   = r.num(StarRailAvatarBasicCol.ELEMENT_ID);
      row.rawJson     = r.str(CommonCol.RAW_JSON);
      row.updateTime  = r.num(CommonCol.UPDATE_TIME);
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
      const r = new RsReader(rs);
      const row = new StarRailDailyNoteRow();
      row.id                    = r.num(CommonCol.ID);
      row.accountId             = r.num(CommonCol.ACCOUNT_ID);
      row.roleUid               = r.str(CommonCol.ROLE_UID);
      row.currentStamina        = r.num(StarRailDailyNoteCol.CURRENT_STAMINA);
      row.maxStamina            = r.num(StarRailDailyNoteCol.MAX_STAMINA);
      row.staminaRecoverTime    = r.num(StarRailDailyNoteCol.STAMINA_RECOVER_TIME);
      row.staminaFullTs         = r.num(StarRailDailyNoteCol.STAMINA_FULL_TS);
      row.currentReserveStamina = r.num(StarRailDailyNoteCol.CURRENT_RESERVE_STAMINA);
      row.acceptedExpeditionNum = r.num(StarRailDailyNoteCol.ACCEPTED_EXPEDITION_NUM);
      row.totalExpeditionNum    = r.num(StarRailDailyNoteCol.TOTAL_EXPEDITION_NUM);
      row.currentTrainScore     = r.num(StarRailDailyNoteCol.CURRENT_TRAIN_SCORE);
      row.maxTrainScore         = r.num(StarRailDailyNoteCol.MAX_TRAIN_SCORE);
      row.currentRogueScore     = r.num(StarRailDailyNoteCol.CURRENT_ROGUE_SCORE);
      row.maxRogueScore         = r.num(StarRailDailyNoteCol.MAX_ROGUE_SCORE);
      row.weeklyCocoonCnt       = r.num(StarRailDailyNoteCol.WEEKLY_COCOON_CNT);
      row.weeklyCocoonLimit     = r.num(StarRailDailyNoteCol.WEEKLY_COCOON_LIMIT);
      row.rogueTournWeeklyCur   = r.num(StarRailDailyNoteCol.ROGUE_TOURN_WEEKLY_CUR);
      row.rogueTournWeeklyMax   = r.num(StarRailDailyNoteCol.ROGUE_TOURN_WEEKLY_MAX);
      row.gridFightWeeklyCur    = r.num(StarRailDailyNoteCol.GRID_FIGHT_WEEKLY_CUR);
      row.gridFightWeeklyMax    = r.num(StarRailDailyNoteCol.GRID_FIGHT_WEEKLY_MAX);
      row.rawJson               = r.str(CommonCol.RAW_JSON);
      row.updateTime            = r.num(CommonCol.UPDATE_TIME);
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
      const r = new RsReader(rs);
      const row = new StarRailAvatarInfoRow();
      row.id           = r.num(CommonCol.ID);
      row.accountId    = r.num(CommonCol.ACCOUNT_ID);
      row.roleUid      = r.str(CommonCol.ROLE_UID);
      row.avatarId     = r.str(CommonCol.AVATAR_ID);
      row.equipId      = r.str(StarRailAvatarInfoCol.EQUIP_ID);
      row.equipLevel   = r.num(StarRailAvatarInfoCol.EQUIP_LEVEL);
      row.equipRank    = r.num(StarRailAvatarInfoCol.EQUIP_RANK);
      row.relicIds     = r.str(StarRailAvatarInfoCol.RELIC_IDS);
      row.skillTreeJson = r.str(StarRailAvatarInfoCol.SKILL_TREE_JSON);
      row.rawJson      = r.str(CommonCol.RAW_JSON);
      row.updateTime   = r.num(CommonCol.UPDATE_TIME);
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
      const r = new RsReader(rs);
      const row = new StarRailAvatarComputeRow();
      row.id                   = r.num(CommonCol.ID);
      row.accountId            = r.num(CommonCol.ACCOUNT_ID);
      row.roleUid              = r.str(CommonCol.ROLE_UID);
      row.avatarId             = r.str(CommonCol.AVATAR_ID);
      row.avatarConsumeJson    = r.str(StarRailAvatarComputeCol.AVATAR_CONSUME_JSON);
      row.skillConsumeJson     = r.str(StarRailAvatarComputeCol.SKILL_CONSUME_JSON);
      row.equipmentConsumeJson = r.str(StarRailAvatarComputeCol.EQUIPMENT_CONSUME_JSON);
      row.updateTime           = r.num(CommonCol.UPDATE_TIME);
      return row;
    } catch (e) {
      throw new Error(`StarRailAvatarComputeDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}
