/**
 * GenshinDao — 原神四张专用表的 DAO 集合
 *
 * 包含四个 DAO 类，分别对应原神的四张数据表：
 * - GenshinCharacterListDao：角色列表（genshin_character_list）
 * - GenshinDailyNoteDao：实时便笺（genshin_daily_note）
 * - GenshinCharacterDetailDao：角色详情（genshin_character_detail）
 * - GenshinCharacterComputeDao：养成计算（genshin_character_compute）
 *
 * 所有写入操作使用 INSERT OR REPLACE（依赖 UNIQUE 索引实现 upsert 语义）。
 * 所有读取操作通过 RdbManagerV2.queryFirst/queryAll 封装，自动管理 ResultSet 生命周期。
 */
import { relationalStore } from '@kit.ArkData';
import { RdbManagerV2 } from './RdbManagerV2';
import {
  TableName, CommonCol,
  GenshinCharListCol, GenshinDailyNoteCol, GenshinCharDetailCol, GenshinCharComputeCol,
  GENSHIN_CHARACTER_LIST_TABLE, GENSHIN_DAILY_NOTE_TABLE,
  GENSHIN_CHARACTER_DETAIL_TABLE, GENSHIN_CHARACTER_COMPUTE_TABLE
} from './TableSchema';
import {
  GenshinCharacterListRow,
  GenshinDailyNoteRow,
  GenshinCharacterDetailRow,
  GenshinCharacterComputeRow
} from '../../models/v2/GenshinRows';

// ─────────────────────────────────────────────
// GenshinCharacterListDao：操作 genshin_character_list
// ─────────────────────────────────────────────
export class GenshinCharacterListDao {

  /**
   * 批量写入原神角色列表（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid, avatar_id)，重复时覆盖旧数据。
   * @param rows 角色列表行数组，为空时直接返回
   */
  async upsertAll(rows: GenshinCharacterListRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    const columns = GENSHIN_CHARACTER_LIST_TABLE.columnNames();
    try {
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
        await RdbManagerV2.upsertRow(TableName.GENSHIN_CHARACTER_LIST, columns, [
          idVal, row.accountId, row.roleUid, row.avatarId, row.name, row.element,
          row.rarity, row.level, row.fetter, row.activedConstellationNum,
          row.weaponType, row.weaponId, row.weaponName, row.weaponRarity,
          row.weaponLevel, row.weaponAffixLevel, row.icon, row.sideIcon,
          row.rawJson, row.updateTime
        ]);
      }
    } catch (e) {
      throw new Error(`GenshinCharacterListDao.upsertAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询指定账号和角色的所有原神角色列表。
   * @param accountId 米游社账号 ID
   * @param roleUid   游戏角色 UID
   */
  async findAll(accountId: number, roleUid: string): Promise<GenshinCharacterListRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_LIST);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManagerV2.queryAll(predicates, GENSHIN_CHARACTER_LIST_TABLE.columnNames(), (rs) => GenshinCharacterListDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterListDao.findAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 avatarId 查询单条原神角色记录。
   * @param accountId 米游社账号 ID
   * @param roleUid   游戏角色 UID
   * @param avatarId  角色 ID
   * @returns 找到时返回对应行，否则返回 null
   */
  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<GenshinCharacterListRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_LIST);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, GENSHIN_CHARACTER_LIST_TABLE.columnNames(), (rs) => GenshinCharacterListDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterListDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 删除指定账号和角色的所有原神角色列表记录。
   * 通常在重新同步前调用，配合 upsertAll 实现全量刷新。
   */
  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_LIST);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GenshinCharacterListDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 将 ResultSet 当前行映射为 GenshinCharacterListRow。
   * 对每个字段做类型守卫，确保类型不匹配时使用安全默认值而非抛出异常。
   */
  private static mapRow(rs: relationalStore.ResultSet): GenshinCharacterListRow {
    try {
      const row = new GenshinCharacterListRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex(CommonCol.AVATAR_ID));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const nameVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.NAME));
      row.name = typeof nameVal === 'string' ? nameVal : '';
      const elementVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.ELEMENT));
      row.element = typeof elementVal === 'string' ? elementVal : '';
      const rarityVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.RARITY));
      row.rarity = typeof rarityVal === 'number' ? rarityVal : 0;
      const levelVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.LEVEL));
      row.level = typeof levelVal === 'number' ? levelVal : 0;
      const fetterVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.FETTER));
      row.fetter = typeof fetterVal === 'number' ? fetterVal : 0;
      const activedVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.ACTIVED_CONSTELLATION_NUM));
      row.activedConstellationNum = typeof activedVal === 'number' ? activedVal : 0;
      const weaponTypeVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.WEAPON_TYPE));
      row.weaponType = typeof weaponTypeVal === 'number' ? weaponTypeVal : 0;
      const weaponIdVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.WEAPON_ID));
      row.weaponId = typeof weaponIdVal === 'string' ? weaponIdVal : '';
      const weaponNameVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.WEAPON_NAME));
      row.weaponName = typeof weaponNameVal === 'string' ? weaponNameVal : '';
      const weaponRarityVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.WEAPON_RARITY));
      row.weaponRarity = typeof weaponRarityVal === 'number' ? weaponRarityVal : 0;
      const weaponLevelVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.WEAPON_LEVEL));
      row.weaponLevel = typeof weaponLevelVal === 'number' ? weaponLevelVal : 0;
      const weaponAffixVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.WEAPON_AFFIX_LEVEL));
      row.weaponAffixLevel = typeof weaponAffixVal === 'number' ? weaponAffixVal : 0;
      const iconVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.ICON));
      row.icon = typeof iconVal === 'string' ? iconVal : '';
      const sideIconVal = rs.getValue(rs.getColumnIndex(GenshinCharListCol.SIDE_ICON));
      row.sideIcon = typeof sideIconVal === 'string' ? sideIconVal : '';
      const rawJsonVal = rs.getValue(rs.getColumnIndex(CommonCol.RAW_JSON));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex(CommonCol.UPDATE_TIME));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      return row;
    } catch (e) {
      throw new Error(`GenshinCharacterListDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

// ─────────────────────────────────────────────
// GenshinDailyNoteDao：操作 genshin_daily_note
// ─────────────────────────────────────────────
export class GenshinDailyNoteDao {

  /**
   * 写入原神实时便笺（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid)，每个角色只保留一条最新记录。
   * @param row 便笺行数据
   */
  async upsert(row: GenshinDailyNoteRow): Promise<void> {
    const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
    try {
      await RdbManagerV2.upsertRow(TableName.GENSHIN_DAILY_NOTE, GENSHIN_DAILY_NOTE_TABLE.columnNames(), [
        idVal, row.accountId, row.roleUid, row.currentResin, row.maxResin,
        row.resinRecoveryTime, row.finishedTaskNum, row.totalTaskNum,
        row.remainResinDiscountNum, row.currentExpeditionNum, row.maxExpeditionNum,
        row.currentHomeCoin, row.maxHomeCoin, row.transformerRecoveryDay,
        row.rawJson, row.updateTime
      ]);
    } catch (e) {
      throw new Error(`GenshinDailyNoteDao.upsert failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询指定角色的原神实时便笺。
   * @returns 找到时返回便笺行，否则返回 null（表示从未同步）
   */
  async findOne(accountId: number, roleUid: string): Promise<GenshinDailyNoteRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_DAILY_NOTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManagerV2.queryFirst(predicates, GENSHIN_DAILY_NOTE_TABLE.columnNames(), (rs) => GenshinDailyNoteDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinDailyNoteDao.findOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定角色的原神实时便笺记录 */
  async deleteOne(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_DAILY_NOTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GenshinDailyNoteDao.deleteOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 GenshinDailyNoteRow */
  private static mapRow(rs: relationalStore.ResultSet): GenshinDailyNoteRow {
    try {
      const row = new GenshinDailyNoteRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const currentResinVal = rs.getValue(rs.getColumnIndex(GenshinDailyNoteCol.CURRENT_RESIN));
      row.currentResin = typeof currentResinVal === 'number' ? currentResinVal : 0;
      const maxResinVal = rs.getValue(rs.getColumnIndex(GenshinDailyNoteCol.MAX_RESIN));
      row.maxResin = typeof maxResinVal === 'number' ? maxResinVal : 0;
      const resinRecoveryVal = rs.getValue(rs.getColumnIndex(GenshinDailyNoteCol.RESIN_RECOVERY_TIME));
      row.resinRecoveryTime = typeof resinRecoveryVal === 'number' ? resinRecoveryVal : 0;
      const finishedTaskVal = rs.getValue(rs.getColumnIndex(GenshinDailyNoteCol.FINISHED_TASK_NUM));
      row.finishedTaskNum = typeof finishedTaskVal === 'number' ? finishedTaskVal : 0;
      const totalTaskVal = rs.getValue(rs.getColumnIndex(GenshinDailyNoteCol.TOTAL_TASK_NUM));
      row.totalTaskNum = typeof totalTaskVal === 'number' ? totalTaskVal : 0;
      const remainDiscountVal = rs.getValue(rs.getColumnIndex(GenshinDailyNoteCol.REMAIN_RESIN_DISCOUNT_NUM));
      row.remainResinDiscountNum = typeof remainDiscountVal === 'number' ? remainDiscountVal : 0;
      const currentExpeditionVal = rs.getValue(rs.getColumnIndex(GenshinDailyNoteCol.CURRENT_EXPEDITION_NUM));
      row.currentExpeditionNum = typeof currentExpeditionVal === 'number' ? currentExpeditionVal : 0;
      const maxExpeditionVal = rs.getValue(rs.getColumnIndex(GenshinDailyNoteCol.MAX_EXPEDITION_NUM));
      row.maxExpeditionNum = typeof maxExpeditionVal === 'number' ? maxExpeditionVal : 0;
      const currentHomeCoinVal = rs.getValue(rs.getColumnIndex(GenshinDailyNoteCol.CURRENT_HOME_COIN));
      row.currentHomeCoin = typeof currentHomeCoinVal === 'number' ? currentHomeCoinVal : 0;
      const maxHomeCoinVal = rs.getValue(rs.getColumnIndex(GenshinDailyNoteCol.MAX_HOME_COIN));
      row.maxHomeCoin = typeof maxHomeCoinVal === 'number' ? maxHomeCoinVal : 0;
      const transformerVal = rs.getValue(rs.getColumnIndex(GenshinDailyNoteCol.TRANSFORMER_RECOVERY_DAY));
      row.transformerRecoveryDay = typeof transformerVal === 'number' ? transformerVal : 0;
      const rawJsonVal = rs.getValue(rs.getColumnIndex(CommonCol.RAW_JSON));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex(CommonCol.UPDATE_TIME));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      return row;
    } catch (e) {
      throw new Error(`GenshinDailyNoteDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

// ─────────────────────────────────────────────
// GenshinCharacterDetailDao：操作 genshin_character_detail
// ─────────────────────────────────────────────
export class GenshinCharacterDetailDao {

  /**
   * 批量写入原神角色详情（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid, avatar_id)，重复时覆盖旧数据。
   * @param rows 角色详情行数组，为空时直接返回
   */
  async upsertAll(rows: GenshinCharacterDetailRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    const columns = GENSHIN_CHARACTER_DETAIL_TABLE.columnNames();
    try {
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
        await RdbManagerV2.upsertRow(TableName.GENSHIN_CHARACTER_DETAIL, columns, [
          idVal, row.accountId, row.roleUid, row.avatarId, row.weaponId,
          row.weaponLevel, row.weaponAffixLevel, row.relicIds, row.skillLevels,
          row.rawJson, row.updateTime
        ]);
      }
    } catch (e) {
      throw new Error(`GenshinCharacterDetailDao.upsertAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 avatarId 查询原神角色详情。
   * @returns 找到时返回详情行，否则返回 null
   */
  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<GenshinCharacterDetailRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_DETAIL);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, GENSHIN_CHARACTER_DETAIL_TABLE.columnNames(), (rs) => GenshinCharacterDetailDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterDetailDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有原神角色详情记录 */
  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_DETAIL);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GenshinCharacterDetailDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 GenshinCharacterDetailRow */
  private static mapRow(rs: relationalStore.ResultSet): GenshinCharacterDetailRow {
    try {
      const row = new GenshinCharacterDetailRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex(CommonCol.AVATAR_ID));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const weaponIdVal = rs.getValue(rs.getColumnIndex(GenshinCharDetailCol.WEAPON_ID));
      row.weaponId = typeof weaponIdVal === 'string' ? weaponIdVal : '';
      const weaponLevelVal = rs.getValue(rs.getColumnIndex(GenshinCharDetailCol.WEAPON_LEVEL));
      row.weaponLevel = typeof weaponLevelVal === 'number' ? weaponLevelVal : 0;
      const weaponAffixVal = rs.getValue(rs.getColumnIndex(GenshinCharDetailCol.WEAPON_AFFIX_LEVEL));
      row.weaponAffixLevel = typeof weaponAffixVal === 'number' ? weaponAffixVal : 0;
      const relicIdsVal = rs.getValue(rs.getColumnIndex(GenshinCharDetailCol.RELIC_IDS));
      row.relicIds = typeof relicIdsVal === 'string' ? relicIdsVal : '';
      const skillLevelsVal = rs.getValue(rs.getColumnIndex(GenshinCharDetailCol.SKILL_LEVELS));
      row.skillLevels = typeof skillLevelsVal === 'string' ? skillLevelsVal : '';
      const rawJsonVal = rs.getValue(rs.getColumnIndex(CommonCol.RAW_JSON));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex(CommonCol.UPDATE_TIME));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      return row;
    } catch (e) {
      throw new Error(`GenshinCharacterDetailDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

// ─────────────────────────────────────────────
// GenshinCharacterComputeDao：操作 genshin_character_compute
// ─────────────────────────────────────────────
export class GenshinCharacterComputeDao {

  /**
   * 写入原神角色养成计算数据（INSERT OR REPLACE）。
   * 唯一键为 (account_id, role_uid, avatar_id)，重复时覆盖旧数据。
   * @param row 养成计算行数据
   */
  async upsert(row: GenshinCharacterComputeRow): Promise<void> {
    const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
    try {
      await RdbManagerV2.upsertRow(TableName.GENSHIN_CHARACTER_COMPUTE, GENSHIN_CHARACTER_COMPUTE_TABLE.columnNames(), [
        idVal, row.accountId, row.roleUid, row.avatarId,
        row.avatarConsumeJson, row.skillConsumeJson, row.weaponConsumeJson, row.updateTime
      ]);
    } catch (e) {
      throw new Error(`GenshinCharacterComputeDao.upsert failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 avatarId 查询原神角色养成计算数据。
   * @returns 找到时返回计算行，否则返回 null
   */
  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<GenshinCharacterComputeRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_COMPUTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, GENSHIN_CHARACTER_COMPUTE_TABLE.columnNames(), (rs) => GenshinCharacterComputeDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterComputeDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有原神养成计算记录 */
  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_COMPUTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GenshinCharacterComputeDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 GenshinCharacterComputeRow */
  private static mapRow(rs: relationalStore.ResultSet): GenshinCharacterComputeRow {
    try {
      const row = new GenshinCharacterComputeRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex(CommonCol.AVATAR_ID));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const avatarConsumeVal = rs.getValue(rs.getColumnIndex(GenshinCharComputeCol.AVATAR_CONSUME_JSON));
      row.avatarConsumeJson = typeof avatarConsumeVal === 'string' ? avatarConsumeVal : '';
      const skillConsumeVal = rs.getValue(rs.getColumnIndex(GenshinCharComputeCol.SKILL_CONSUME_JSON));
      row.skillConsumeJson = typeof skillConsumeVal === 'string' ? skillConsumeVal : '';
      const weaponConsumeVal = rs.getValue(rs.getColumnIndex(GenshinCharComputeCol.WEAPON_CONSUME_JSON));
      row.weaponConsumeJson = typeof weaponConsumeVal === 'string' ? weaponConsumeVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex(CommonCol.UPDATE_TIME));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      return row;
    } catch (e) {
      throw new Error(`GenshinCharacterComputeDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}
