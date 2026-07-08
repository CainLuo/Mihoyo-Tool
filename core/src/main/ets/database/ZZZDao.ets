/**
 * ZZZDao — 绝区零五张专用表的 DAO 集合
 *
 * 包含五个 DAO 类，分别对应绝区零的五张数据表：
 * - ZZZAvatarBasicDao：代理人基础信息（zzz_avatar_basic）
 * - ZZZDailyNoteDao：实时便笺（zzz_daily_note）
 * - ZZZAvatarInfoDao：代理人详情（zzz_avatar_info）
 * - ZZZAvatarComputeDao：养成计算（zzz_avatar_compute）
 * - ZZZBuddyDao：邦布列表（zzz_buddy）
 *
 * 所有写入操作使用 INSERT OR REPLACE（依赖 UNIQUE 索引实现 upsert 语义）。
 * 所有读取操作通过 RdbManager.queryFirst/queryAll 封装，自动管理 ResultSet 生命周期。
 *
 * 特殊说明：ZZZAvatarBasicRow.awakenState 字段在数据库中以 TEXT 存储，
 * upsertAll 时调用 .toString() 转换，mapRow 时调用 parseInt() 还原。
 */
import { relationalStore } from '@kit.ArkData';
import { RdbManager } from './RdbManager';
import { RsReader } from './RsReader';
import {
  TableName, CommonCol,
  ZZZAvatarBasicCol, ZZZDailyNoteCol, ZZZAvatarInfoCol, ZZZAvatarComputeCol, ZZZBuddyCol,
  ZZZ_AVATAR_BASIC_TABLE, ZZZ_DAILY_NOTE_TABLE,
  ZZZ_AVATAR_INFO_TABLE, ZZZ_AVATAR_COMPUTE_TABLE, ZZZ_BUDDY_TABLE
} from './TableSchema';
import {
  ZZZAvatarBasicRow,
  ZZZDailyNoteRow,
  ZZZAvatarInfoRow,
  ZZZAvatarComputeRow,
  ZZZBuddyRow
} from '../models/ZZZRows';

// ─────────────────────────────────────────────
// ZZZAvatarBasicDao：操作 zzz_avatar_basic
// ─────────────────────────────────────────────
export class ZZZAvatarBasicDao {

  /**
   * 批量写入绝区零代理人基础信息（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid, avatar_id)，重复时覆盖旧数据。
   * 注意：awakenState 字段写入时转为字符串（数据库列类型为 TEXT）。
   * @param rows 代理人基础信息行数组，为空时直接返回
   */
  async upsertAll(rows: ZZZAvatarBasicRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    const columns = ZZZ_AVATAR_BASIC_TABLE.columnNames();
    try {
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
        await RdbManager.upsertRow(TableName.ZZZ_AVATAR_BASIC, columns, [
          idVal, row.accountId, row.roleUid, row.avatarId, row.nameMi18n, row.fullNameMi18n,
          row.elementType, row.subElementType, row.avatarProfession, row.rarity, row.level,
          row.rank, row.campNameMi18n, row.groupIconPath, row.hollowIconPath,
          row.roleSquareUrl, row.awakenState.toString(), row.isChosen, row.rawJson, row.updateTime
        ]);
      }
    } catch (e) {
      throw new Error(`ZZZAvatarBasicDao.upsertAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询指定账号和角色的所有绝区零代理人基础信息。
   * @param accountId 米游社账号 ID
   * @param roleUid   游戏角色 UID
   */
  async findAll(accountId: string, roleUid: string): Promise<ZZZAvatarBasicRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_BASIC);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManager.queryAll(predicates, ZZZ_AVATAR_BASIC_TABLE.columnNames(), (rs) => ZZZAvatarBasicDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZAvatarBasicDao.findAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 avatarId 查询单条绝区零代理人基础信息。
   * @returns 找到时返回对应行，否则返回 null
   */
  async findByAvatarId(accountId: string, roleUid: string, avatarId: string): Promise<ZZZAvatarBasicRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_BASIC);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManager.queryFirst(predicates, ZZZ_AVATAR_BASIC_TABLE.columnNames(), (rs) => ZZZAvatarBasicDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZAvatarBasicDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有绝区零代理人基础信息记录 */
  async deleteAll(accountId: string, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_BASIC);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZAvatarBasicDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 将 ResultSet 当前行映射为 ZZZAvatarBasicRow。
   * 注意：awakenState 列在数据库中为 TEXT，通过 r.strAsInt() 读取并转换为 number。
   */
  private static mapRow(rs: relationalStore.ResultSet): ZZZAvatarBasicRow {
    try {
      const r = new RsReader(rs);
      const row = new ZZZAvatarBasicRow();
      row.id               = r.num(CommonCol.ID);
      row.accountId        = r.str(CommonCol.ACCOUNT_ID);
      row.roleUid          = r.str(CommonCol.ROLE_UID);
      row.avatarId         = r.str(CommonCol.AVATAR_ID);
      row.nameMi18n        = r.str(ZZZAvatarBasicCol.NAME_MI18N);
      row.fullNameMi18n    = r.str(ZZZAvatarBasicCol.FULL_NAME_MI18N);
      row.elementType      = r.num(ZZZAvatarBasicCol.ELEMENT_TYPE);
      row.subElementType   = r.num(ZZZAvatarBasicCol.SUB_ELEMENT_TYPE);
      row.avatarProfession = r.num(ZZZAvatarBasicCol.AVATAR_PROFESSION);
      row.rarity           = r.str(ZZZAvatarBasicCol.RARITY);
      row.level            = r.num(ZZZAvatarBasicCol.LEVEL);
      row.rank             = r.num(ZZZAvatarBasicCol.RANK);
      row.campNameMi18n    = r.str(ZZZAvatarBasicCol.CAMP_NAME_MI18N);
      row.groupIconPath    = r.str(ZZZAvatarBasicCol.GROUP_ICON_PATH);
      row.hollowIconPath   = r.str(ZZZAvatarBasicCol.HOLLOW_ICON_PATH);
      row.roleSquareUrl    = r.str(ZZZAvatarBasicCol.ROLE_SQUARE_URL);
      row.awakenState      = r.strAsInt(ZZZAvatarBasicCol.AWAKEN_STATE);
      row.isChosen         = r.num(ZZZAvatarBasicCol.IS_CHOSEN);
      row.rawJson          = r.str(CommonCol.RAW_JSON);
      row.updateTime       = r.num(CommonCol.UPDATE_TIME);
      return row;
    } catch (e) {
      throw new Error(`ZZZAvatarBasicDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

// ─────────────────────────────────────────────
// ZZZDailyNoteDao：操作 zzz_daily_note
// ─────────────────────────────────────────────
export class ZZZDailyNoteDao {

  /**
   * 写入绝区零实时便笺（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid)，每个角色只保留一条最新记录。
   * @param row 便笺行数据
   */
  async upsert(row: ZZZDailyNoteRow): Promise<void> {
    const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
    try {
      await RdbManager.upsertRow(TableName.ZZZ_DAILY_NOTE, ZZZ_DAILY_NOTE_TABLE.columnNames(), [
        idVal, row.accountId, row.roleUid, row.energyCurrent, row.energyMax, row.energyRestore,
        row.vitalityCurrent, row.vitalityMax, row.vhsSaleState, row.cardSign,
        row.rawJson, row.widgetRawJson, row.updateTime
      ]);
    } catch (e) {
      throw new Error(`ZZZDailyNoteDao.upsert failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询指定角色的绝区零实时便笺。
   * @returns 找到时返回便笺行，否则返回 null
   */
  async findOne(accountId: string, roleUid: string): Promise<ZZZDailyNoteRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_DAILY_NOTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManager.queryFirst(predicates, ZZZ_DAILY_NOTE_TABLE.columnNames(), (rs) => ZZZDailyNoteDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZDailyNoteDao.findOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定角色的绝区零实时便笺记录 */
  async deleteOne(accountId: string, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_DAILY_NOTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZDailyNoteDao.deleteOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 ZZZDailyNoteRow */
  private static mapRow(rs: relationalStore.ResultSet): ZZZDailyNoteRow {
    try {
      const r = new RsReader(rs);
      const row = new ZZZDailyNoteRow();
      row.id              = r.num(CommonCol.ID);
      row.accountId       = r.str(CommonCol.ACCOUNT_ID);
      row.roleUid         = r.str(CommonCol.ROLE_UID);
      row.energyCurrent   = r.num(ZZZDailyNoteCol.ENERGY_CURRENT);
      row.energyMax       = r.num(ZZZDailyNoteCol.ENERGY_MAX);
      row.energyRestore   = r.num(ZZZDailyNoteCol.ENERGY_RESTORE);
      row.vitalityCurrent = r.num(ZZZDailyNoteCol.VITALITY_CURRENT);
      row.vitalityMax     = r.num(ZZZDailyNoteCol.VITALITY_MAX);
      row.vhsSaleState    = r.str(ZZZDailyNoteCol.VHS_SALE_STATE);
      row.cardSign        = r.str(ZZZDailyNoteCol.CARD_SIGN);
      row.rawJson         = r.str(CommonCol.RAW_JSON);
      row.widgetRawJson   = r.str('widget_raw_json');
      row.updateTime      = r.num(CommonCol.UPDATE_TIME);
      return row;
    } catch (e) {
      throw new Error(`ZZZDailyNoteDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

// ─────────────────────────────────────────────
// ZZZAvatarInfoDao：操作 zzz_avatar_info
// ─────────────────────────────────────────────
export class ZZZAvatarInfoDao {

  /**
   * 批量写入绝区零代理人详情（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid, avatar_id)，重复时覆盖旧数据。
   * @param rows 代理人详情行数组，为空时直接返回
   */
  async upsertAll(rows: ZZZAvatarInfoRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    const columns = ZZZ_AVATAR_INFO_TABLE.columnNames();
    try {
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
        await RdbManager.upsertRow(TableName.ZZZ_AVATAR_INFO, columns, [
          idVal, row.accountId, row.roleUid, row.avatarId, row.weaponId, row.weaponLevel,
          row.weaponStar, row.equipIds, row.skillLevelsJson, row.verticalPaintingUrl,
          row.rawJson, row.updateTime
        ]);
      }
    } catch (e) {
      throw new Error(`ZZZAvatarInfoDao.upsertAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 avatarId 查询绝区零代理人详情。
   * @returns 找到时返回详情行，否则返回 null
   */
  async findByAvatarId(accountId: string, roleUid: string, avatarId: string): Promise<ZZZAvatarInfoRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_INFO);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManager.queryFirst(predicates, ZZZ_AVATAR_INFO_TABLE.columnNames(), (rs) => ZZZAvatarInfoDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZAvatarInfoDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有绝区零代理人详情记录 */
  async deleteAll(accountId: string, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_INFO);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZAvatarInfoDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 ZZZAvatarInfoRow */
  private static mapRow(rs: relationalStore.ResultSet): ZZZAvatarInfoRow {
    try {
      const r = new RsReader(rs);
      const row = new ZZZAvatarInfoRow();
      row.id                  = r.num(CommonCol.ID);
      row.accountId           = r.str(CommonCol.ACCOUNT_ID);
      row.roleUid             = r.str(CommonCol.ROLE_UID);
      row.avatarId            = r.str(CommonCol.AVATAR_ID);
      row.weaponId            = r.str(ZZZAvatarInfoCol.WEAPON_ID);
      row.weaponLevel         = r.num(ZZZAvatarInfoCol.WEAPON_LEVEL);
      row.weaponStar          = r.num(ZZZAvatarInfoCol.WEAPON_STAR);
      row.equipIds            = r.str(ZZZAvatarInfoCol.EQUIP_IDS);
      row.skillLevelsJson     = r.str(ZZZAvatarInfoCol.SKILL_LEVELS_JSON);
      row.verticalPaintingUrl = r.str(ZZZAvatarInfoCol.VERTICAL_PAINTING_URL);
      row.rawJson             = r.str(CommonCol.RAW_JSON);
      row.updateTime          = r.num(CommonCol.UPDATE_TIME);
      return row;
    } catch (e) {
      throw new Error(`ZZZAvatarInfoDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

// ─────────────────────────────────────────────
// ZZZAvatarComputeDao：操作 zzz_avatar_compute
// ─────────────────────────────────────────────
export class ZZZAvatarComputeDao {

  /**
   * 写入绝区零代理人养成计算数据（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid, avatar_id)，重复时覆盖旧数据。
   * @param row 养成计算行数据
   */
  async upsert(row: ZZZAvatarComputeRow): Promise<void> {
    const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
    try {
      await RdbManager.upsertRow(TableName.ZZZ_AVATAR_COMPUTE, ZZZ_AVATAR_COMPUTE_TABLE.columnNames(), [
        idVal, row.accountId, row.roleUid, row.avatarId,
        row.avatarConsumeJson, row.weaponConsumeJson, row.skillConsumeJson, row.updateTime
      ]);
    } catch (e) {
      throw new Error(`ZZZAvatarComputeDao.upsert failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 avatarId 查询绝区零代理人养成计算数据。
   * @returns 找到时返回计算行，否则返回 null
   */
  async findByAvatarId(accountId: string, roleUid: string, avatarId: string): Promise<ZZZAvatarComputeRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_COMPUTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManager.queryFirst(predicates, ZZZ_AVATAR_COMPUTE_TABLE.columnNames(), (rs) => ZZZAvatarComputeDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZAvatarComputeDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有绝区零养成计算记录 */
  async deleteAll(accountId: string, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_COMPUTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZAvatarComputeDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 ZZZAvatarComputeRow */
  private static mapRow(rs: relationalStore.ResultSet): ZZZAvatarComputeRow {
    try {
      const r = new RsReader(rs);
      const row = new ZZZAvatarComputeRow();
      row.id                = r.num(CommonCol.ID);
      row.accountId         = r.str(CommonCol.ACCOUNT_ID);
      row.roleUid           = r.str(CommonCol.ROLE_UID);
      row.avatarId          = r.str(CommonCol.AVATAR_ID);
      row.avatarConsumeJson = r.str(ZZZAvatarComputeCol.AVATAR_CONSUME_JSON);
      row.weaponConsumeJson = r.str(ZZZAvatarComputeCol.WEAPON_CONSUME_JSON);
      row.skillConsumeJson  = r.str(ZZZAvatarComputeCol.SKILL_CONSUME_JSON);
      row.updateTime        = r.num(CommonCol.UPDATE_TIME);
      return row;
    } catch (e) {
      throw new Error(`ZZZAvatarComputeDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

// ─────────────────────────────────────────────
// ZZZBuddyDao：操作 zzz_buddy
// ─────────────────────────────────────────────
export class ZZZBuddyDao {

  /**
   * 批量写入邦布列表（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid, buddy_id)，重复时覆盖旧数据。
   * @param rows 邦布行数组，为空时直接返回
   */
  async upsertAll(rows: ZZZBuddyRow[]): Promise<void> {
    if (rows.length === 0) { return; }
    const columns = ZZZ_BUDDY_TABLE.columnNames();
    try {
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
        await RdbManager.upsertRow(TableName.ZZZ_BUDDY, columns, [
          idVal, row.accountId, row.roleUid, row.buddyId,
          row.name, row.rarity, row.level, row.star,
          row.bangbooSquareUrl, row.rawJson, row.updateTime
        ]);
      }
    } catch (e) {
      throw new Error(`ZZZBuddyDao.upsertAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询指定账号和角色的所有邦布。
   * @param accountId 米游社 UID
   * @param roleUid   游戏角色 UID
   */
  async findAll(accountId: string, roleUid: string): Promise<ZZZBuddyRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_BUDDY);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManager.queryAll(predicates, ZZZ_BUDDY_TABLE.columnNames(), (rs) => ZZZBuddyDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZBuddyDao.findAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 删除指定账号和角色的所有邦布数据。
   */
  async deleteAll(accountId: string, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_BUDDY);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZBuddyDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): ZZZBuddyRow {
    const r = new RsReader(rs);
    const row = new ZZZBuddyRow();
    row.id              = r.num(CommonCol.ID);
    row.accountId       = r.str(CommonCol.ACCOUNT_ID);
    row.roleUid         = r.str(CommonCol.ROLE_UID);
    row.buddyId         = r.str(ZZZBuddyCol.BUDDY_ID);
    row.name            = r.str(ZZZBuddyCol.NAME);
    row.rarity          = r.str(ZZZBuddyCol.RARITY);
    row.level           = r.num(ZZZBuddyCol.LEVEL);
    row.star            = r.num(ZZZBuddyCol.STAR);
    row.bangbooSquareUrl = r.str(ZZZBuddyCol.BANGBOO_SQUARE_URL);
    row.rawJson         = r.str(CommonCol.RAW_JSON);
    row.updateTime      = r.num(CommonCol.UPDATE_TIME);
    return row;
  }
}
