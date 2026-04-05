/**
 * ZZZDao — 绝区零四张专用表的 DAO 集合
 *
 * 包含四个 DAO 类，分别对应绝区零的四张数据表：
 * - ZZZAvatarBasicDao：代理人基础信息（zzz_avatar_basic）
 * - ZZZDailyNoteDao：实时便笺（zzz_daily_note）
 * - ZZZAvatarInfoDao：代理人详情（zzz_avatar_info）
 * - ZZZAvatarComputeDao：养成计算（zzz_avatar_compute）
 *
 * 所有写入操作使用 INSERT OR REPLACE（依赖 UNIQUE 索引实现 upsert 语义）。
 * 所有读取操作通过 RdbManagerV2.queryFirst/queryAll 封装，自动管理 ResultSet 生命周期。
 *
 * 特殊说明：ZZZAvatarBasicRow.awakenState 字段在数据库中以 TEXT 存储，
 * upsertAll 时调用 .toString() 转换，mapRow 时调用 parseInt() 还原。
 */
import { relationalStore } from '@kit.ArkData';
import { RdbManagerV2 } from './RdbManagerV2';
import {
  TableName, CommonCol,
  ZZZAvatarBasicCol, ZZZDailyNoteCol, ZZZAvatarInfoCol, ZZZAvatarComputeCol,
  ZZZ_AVATAR_BASIC_TABLE, ZZZ_DAILY_NOTE_TABLE,
  ZZZ_AVATAR_INFO_TABLE, ZZZ_AVATAR_COMPUTE_TABLE
} from './TableSchema';
import {
  ZZZAvatarBasicRow,
  ZZZDailyNoteRow,
  ZZZAvatarInfoRow,
  ZZZAvatarComputeRow
} from '../../models/v2/ZZZRows';

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
        await RdbManagerV2.upsertRow(TableName.ZZZ_AVATAR_BASIC, columns, [
          idVal, row.accountId, row.roleUid, row.avatarId, row.nameMi18n, row.fullNameMi18n,
          row.elementType, row.subElementType, row.avatarProfession, row.rarity, row.level,
          row.rank, row.campNameMi18n, row.groupIconPath, row.hollowIconPath,
          row.roleSquareUrl, row.awakenState.toString(), row.rawJson, row.updateTime
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
  async findAll(accountId: number, roleUid: string): Promise<ZZZAvatarBasicRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_BASIC);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManagerV2.queryAll(predicates, ZZZ_AVATAR_BASIC_TABLE.columnNames(), (rs) => ZZZAvatarBasicDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZAvatarBasicDao.findAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 avatarId 查询单条绝区零代理人基础信息。
   * @returns 找到时返回对应行，否则返回 null
   */
  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<ZZZAvatarBasicRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_BASIC);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, ZZZ_AVATAR_BASIC_TABLE.columnNames(), (rs) => ZZZAvatarBasicDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZAvatarBasicDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有绝区零代理人基础信息记录 */
  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_BASIC);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZAvatarBasicDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 将 ResultSet 当前行映射为 ZZZAvatarBasicRow。
   * 注意：awakenState 列在数据库中为 TEXT，读取后通过 parseInt() 转换为 number。
   */
  private static mapRow(rs: relationalStore.ResultSet): ZZZAvatarBasicRow {
    try {
      const row = new ZZZAvatarBasicRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex(CommonCol.AVATAR_ID));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const nameMi18nVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.NAME_MI18N));
      row.nameMi18n = typeof nameMi18nVal === 'string' ? nameMi18nVal : '';
      const fullNameMi18nVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.FULL_NAME_MI18N));
      row.fullNameMi18n = typeof fullNameMi18nVal === 'string' ? fullNameMi18nVal : '';
      const elementTypeVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.ELEMENT_TYPE));
      row.elementType = typeof elementTypeVal === 'number' ? elementTypeVal : 0;
      const subElementTypeVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.SUB_ELEMENT_TYPE));
      row.subElementType = typeof subElementTypeVal === 'number' ? subElementTypeVal : 0;
      const avatarProfessionVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.AVATAR_PROFESSION));
      row.avatarProfession = typeof avatarProfessionVal === 'number' ? avatarProfessionVal : 0;
      const rarityVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.RARITY));
      row.rarity = typeof rarityVal === 'string' ? rarityVal : '';
      const levelVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.LEVEL));
      row.level = typeof levelVal === 'number' ? levelVal : 0;
      const rankVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.RANK));
      row.rank = typeof rankVal === 'number' ? rankVal : 0;
      const campNameMi18nVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.CAMP_NAME_MI18N));
      row.campNameMi18n = typeof campNameMi18nVal === 'string' ? campNameMi18nVal : '';
      const groupIconPathVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.GROUP_ICON_PATH));
      row.groupIconPath = typeof groupIconPathVal === 'string' ? groupIconPathVal : '';
      const hollowIconPathVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.HOLLOW_ICON_PATH));
      row.hollowIconPath = typeof hollowIconPathVal === 'string' ? hollowIconPathVal : '';
      const roleSquareUrlVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.ROLE_SQUARE_URL));
      row.roleSquareUrl = typeof roleSquareUrlVal === 'string' ? roleSquareUrlVal : '';
      const awakenStateVal = rs.getValue(rs.getColumnIndex(ZZZAvatarBasicCol.AWAKEN_STATE));
      row.awakenState = typeof awakenStateVal === 'string' ? parseInt(awakenStateVal) : 0;
      const rawJsonVal = rs.getValue(rs.getColumnIndex(CommonCol.RAW_JSON));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex(CommonCol.UPDATE_TIME));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
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
      await RdbManagerV2.upsertRow(TableName.ZZZ_DAILY_NOTE, ZZZ_DAILY_NOTE_TABLE.columnNames(), [
        idVal, row.accountId, row.roleUid, row.energyCurrent, row.energyMax, row.energyRestore,
        row.vitalityCurrent, row.vitalityMax, row.vhsSaleState, row.cardSign,
        row.rawJson, row.updateTime
      ]);
    } catch (e) {
      throw new Error(`ZZZDailyNoteDao.upsert failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询指定角色的绝区零实时便笺。
   * @returns 找到时返回便笺行，否则返回 null
   */
  async findOne(accountId: number, roleUid: string): Promise<ZZZDailyNoteRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_DAILY_NOTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManagerV2.queryFirst(predicates, ZZZ_DAILY_NOTE_TABLE.columnNames(), (rs) => ZZZDailyNoteDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZDailyNoteDao.findOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定角色的绝区零实时便笺记录 */
  async deleteOne(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_DAILY_NOTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZDailyNoteDao.deleteOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 ZZZDailyNoteRow */
  private static mapRow(rs: relationalStore.ResultSet): ZZZDailyNoteRow {
    try {
      const row = new ZZZDailyNoteRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const energyCurrentVal = rs.getValue(rs.getColumnIndex(ZZZDailyNoteCol.ENERGY_CURRENT));
      row.energyCurrent = typeof energyCurrentVal === 'number' ? energyCurrentVal : 0;
      const energyMaxVal = rs.getValue(rs.getColumnIndex(ZZZDailyNoteCol.ENERGY_MAX));
      row.energyMax = typeof energyMaxVal === 'number' ? energyMaxVal : 0;
      const energyRestoreVal = rs.getValue(rs.getColumnIndex(ZZZDailyNoteCol.ENERGY_RESTORE));
      row.energyRestore = typeof energyRestoreVal === 'number' ? energyRestoreVal : 0;
      const vitalityCurrentVal = rs.getValue(rs.getColumnIndex(ZZZDailyNoteCol.VITALITY_CURRENT));
      row.vitalityCurrent = typeof vitalityCurrentVal === 'number' ? vitalityCurrentVal : 0;
      const vitalityMaxVal = rs.getValue(rs.getColumnIndex(ZZZDailyNoteCol.VITALITY_MAX));
      row.vitalityMax = typeof vitalityMaxVal === 'number' ? vitalityMaxVal : 0;
      const vhsSaleStateVal = rs.getValue(rs.getColumnIndex(ZZZDailyNoteCol.VHS_SALE_STATE));
      row.vhsSaleState = typeof vhsSaleStateVal === 'string' ? vhsSaleStateVal : '';
      const cardSignVal = rs.getValue(rs.getColumnIndex(ZZZDailyNoteCol.CARD_SIGN));
      row.cardSign = typeof cardSignVal === 'string' ? cardSignVal : '';
      const rawJsonVal = rs.getValue(rs.getColumnIndex(CommonCol.RAW_JSON));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex(CommonCol.UPDATE_TIME));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
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
        await RdbManagerV2.upsertRow(TableName.ZZZ_AVATAR_INFO, columns, [
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
  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<ZZZAvatarInfoRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_INFO);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, ZZZ_AVATAR_INFO_TABLE.columnNames(), (rs) => ZZZAvatarInfoDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZAvatarInfoDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有绝区零代理人详情记录 */
  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_INFO);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZAvatarInfoDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 ZZZAvatarInfoRow */
  private static mapRow(rs: relationalStore.ResultSet): ZZZAvatarInfoRow {
    try {
      const row = new ZZZAvatarInfoRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex(CommonCol.AVATAR_ID));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const weaponIdVal = rs.getValue(rs.getColumnIndex(ZZZAvatarInfoCol.WEAPON_ID));
      row.weaponId = typeof weaponIdVal === 'string' ? weaponIdVal : '';
      const weaponLevelVal = rs.getValue(rs.getColumnIndex(ZZZAvatarInfoCol.WEAPON_LEVEL));
      row.weaponLevel = typeof weaponLevelVal === 'number' ? weaponLevelVal : 0;
      const weaponStarVal = rs.getValue(rs.getColumnIndex(ZZZAvatarInfoCol.WEAPON_STAR));
      row.weaponStar = typeof weaponStarVal === 'number' ? weaponStarVal : 0;
      const equipIdsVal = rs.getValue(rs.getColumnIndex(ZZZAvatarInfoCol.EQUIP_IDS));
      row.equipIds = typeof equipIdsVal === 'string' ? equipIdsVal : '';
      const skillLevelsJsonVal = rs.getValue(rs.getColumnIndex(ZZZAvatarInfoCol.SKILL_LEVELS_JSON));
      row.skillLevelsJson = typeof skillLevelsJsonVal === 'string' ? skillLevelsJsonVal : '';
      const verticalPaintingUrlVal = rs.getValue(rs.getColumnIndex(ZZZAvatarInfoCol.VERTICAL_PAINTING_URL));
      row.verticalPaintingUrl = typeof verticalPaintingUrlVal === 'string' ? verticalPaintingUrlVal : '';
      const rawJsonVal = rs.getValue(rs.getColumnIndex(CommonCol.RAW_JSON));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex(CommonCol.UPDATE_TIME));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
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
      await RdbManagerV2.upsertRow(TableName.ZZZ_AVATAR_COMPUTE, ZZZ_AVATAR_COMPUTE_TABLE.columnNames(), [
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
  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<ZZZAvatarComputeRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_COMPUTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, ZZZ_AVATAR_COMPUTE_TABLE.columnNames(), (rs) => ZZZAvatarComputeDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZAvatarComputeDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有绝区零养成计算记录 */
  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_COMPUTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZAvatarComputeDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 ZZZAvatarComputeRow */
  private static mapRow(rs: relationalStore.ResultSet): ZZZAvatarComputeRow {
    try {
      const row = new ZZZAvatarComputeRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex(CommonCol.AVATAR_ID));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const avatarConsumeVal = rs.getValue(rs.getColumnIndex(ZZZAvatarComputeCol.AVATAR_CONSUME_JSON));
      row.avatarConsumeJson = typeof avatarConsumeVal === 'string' ? avatarConsumeVal : '';
      const weaponConsumeVal = rs.getValue(rs.getColumnIndex(ZZZAvatarComputeCol.WEAPON_CONSUME_JSON));
      row.weaponConsumeJson = typeof weaponConsumeVal === 'string' ? weaponConsumeVal : '';
      const skillConsumeVal = rs.getValue(rs.getColumnIndex(ZZZAvatarComputeCol.SKILL_CONSUME_JSON));
      row.skillConsumeJson = typeof skillConsumeVal === 'string' ? skillConsumeVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex(CommonCol.UPDATE_TIME));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      return row;
    } catch (e) {
      throw new Error(`ZZZAvatarComputeDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}
