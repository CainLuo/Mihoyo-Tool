import { relationalStore } from '@kit.ArkData';
import { RdbManagerV2 } from './RdbManagerV2';
import {
  TableName,
  GENSHIN_CHARACTER_LIST_TABLE,
  GENSHIN_DAILY_NOTE_TABLE,
  GENSHIN_CHARACTER_DETAIL_TABLE,
  GENSHIN_CHARACTER_COMPUTE_TABLE
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
   * 批量 INSERT OR REPLACE
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
   * 查询指定账号和角色的所有角色列表
   */
  async findAll(accountId: number, roleUid: string): Promise<GenshinCharacterListRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_LIST);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      return await RdbManagerV2.queryAll(predicates, GENSHIN_CHARACTER_LIST_TABLE.columnNames(), (rs) => GenshinCharacterListDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterListDao.findAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 avatarId 查询单条记录
   */
  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<GenshinCharacterListRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_LIST);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    predicates.and();
    predicates.equalTo('avatar_id', avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, GENSHIN_CHARACTER_LIST_TABLE.columnNames(), (rs) => GenshinCharacterListDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterListDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 删除指定账号和角色的所有角色列表
   */
  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_LIST);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GenshinCharacterListDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): GenshinCharacterListRow {
    try {
      const row = new GenshinCharacterListRow();
      const idVal = rs.getValue(rs.getColumnIndex('id'));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex('account_id'));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex('role_uid'));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex('avatar_id'));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const nameVal = rs.getValue(rs.getColumnIndex('name'));
      row.name = typeof nameVal === 'string' ? nameVal : '';
      const elementVal = rs.getValue(rs.getColumnIndex('element'));
      row.element = typeof elementVal === 'string' ? elementVal : '';
      const rarityVal = rs.getValue(rs.getColumnIndex('rarity'));
      row.rarity = typeof rarityVal === 'number' ? rarityVal : 0;
      const levelVal = rs.getValue(rs.getColumnIndex('level'));
      row.level = typeof levelVal === 'number' ? levelVal : 0;
      const fetterVal = rs.getValue(rs.getColumnIndex('fetter'));
      row.fetter = typeof fetterVal === 'number' ? fetterVal : 0;
      const activedVal = rs.getValue(rs.getColumnIndex('actived_constellation_num'));
      row.activedConstellationNum = typeof activedVal === 'number' ? activedVal : 0;
      const weaponTypeVal = rs.getValue(rs.getColumnIndex('weapon_type'));
      row.weaponType = typeof weaponTypeVal === 'number' ? weaponTypeVal : 0;
      const weaponIdVal = rs.getValue(rs.getColumnIndex('weapon_id'));
      row.weaponId = typeof weaponIdVal === 'string' ? weaponIdVal : '';
      const weaponNameVal = rs.getValue(rs.getColumnIndex('weapon_name'));
      row.weaponName = typeof weaponNameVal === 'string' ? weaponNameVal : '';
      const weaponRarityVal = rs.getValue(rs.getColumnIndex('weapon_rarity'));
      row.weaponRarity = typeof weaponRarityVal === 'number' ? weaponRarityVal : 0;
      const weaponLevelVal = rs.getValue(rs.getColumnIndex('weapon_level'));
      row.weaponLevel = typeof weaponLevelVal === 'number' ? weaponLevelVal : 0;
      const weaponAffixVal = rs.getValue(rs.getColumnIndex('weapon_affix_level'));
      row.weaponAffixLevel = typeof weaponAffixVal === 'number' ? weaponAffixVal : 0;
      const iconVal = rs.getValue(rs.getColumnIndex('icon'));
      row.icon = typeof iconVal === 'string' ? iconVal : '';
      const sideIconVal = rs.getValue(rs.getColumnIndex('side_icon'));
      row.sideIcon = typeof sideIconVal === 'string' ? sideIconVal : '';
      const rawJsonVal = rs.getValue(rs.getColumnIndex('raw_json'));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
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
   * INSERT OR REPLACE
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
   * 查询单条便笺记录
   */
  async findOne(accountId: number, roleUid: string): Promise<GenshinDailyNoteRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_DAILY_NOTE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      return await RdbManagerV2.queryFirst(predicates, GENSHIN_DAILY_NOTE_TABLE.columnNames(), (rs) => GenshinDailyNoteDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinDailyNoteDao.findOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 删除单条便笺记录
   */
  async deleteOne(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_DAILY_NOTE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GenshinDailyNoteDao.deleteOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): GenshinDailyNoteRow {
    try {
      const row = new GenshinDailyNoteRow();
      const idVal = rs.getValue(rs.getColumnIndex('id'));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex('account_id'));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex('role_uid'));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const currentResinVal = rs.getValue(rs.getColumnIndex('current_resin'));
      row.currentResin = typeof currentResinVal === 'number' ? currentResinVal : 0;
      const maxResinVal = rs.getValue(rs.getColumnIndex('max_resin'));
      row.maxResin = typeof maxResinVal === 'number' ? maxResinVal : 0;
      const resinRecoveryVal = rs.getValue(rs.getColumnIndex('resin_recovery_time'));
      row.resinRecoveryTime = typeof resinRecoveryVal === 'number' ? resinRecoveryVal : 0;
      const finishedTaskVal = rs.getValue(rs.getColumnIndex('finished_task_num'));
      row.finishedTaskNum = typeof finishedTaskVal === 'number' ? finishedTaskVal : 0;
      const totalTaskVal = rs.getValue(rs.getColumnIndex('total_task_num'));
      row.totalTaskNum = typeof totalTaskVal === 'number' ? totalTaskVal : 0;
      const remainDiscountVal = rs.getValue(rs.getColumnIndex('remain_resin_discount_num'));
      row.remainResinDiscountNum = typeof remainDiscountVal === 'number' ? remainDiscountVal : 0;
      const currentExpeditionVal = rs.getValue(rs.getColumnIndex('current_expedition_num'));
      row.currentExpeditionNum = typeof currentExpeditionVal === 'number' ? currentExpeditionVal : 0;
      const maxExpeditionVal = rs.getValue(rs.getColumnIndex('max_expedition_num'));
      row.maxExpeditionNum = typeof maxExpeditionVal === 'number' ? maxExpeditionVal : 0;
      const currentHomeCoinVal = rs.getValue(rs.getColumnIndex('current_home_coin'));
      row.currentHomeCoin = typeof currentHomeCoinVal === 'number' ? currentHomeCoinVal : 0;
      const maxHomeCoinVal = rs.getValue(rs.getColumnIndex('max_home_coin'));
      row.maxHomeCoin = typeof maxHomeCoinVal === 'number' ? maxHomeCoinVal : 0;
      const transformerVal = rs.getValue(rs.getColumnIndex('transformer_recovery_day'));
      row.transformerRecoveryDay = typeof transformerVal === 'number' ? transformerVal : 0;
      const rawJsonVal = rs.getValue(rs.getColumnIndex('raw_json'));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
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
   * 批量 INSERT OR REPLACE
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
   * 按 avatarId 查询角色详情
   */
  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<GenshinCharacterDetailRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_DETAIL);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    predicates.and();
    predicates.equalTo('avatar_id', avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, GENSHIN_CHARACTER_DETAIL_TABLE.columnNames(), (rs) => GenshinCharacterDetailDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterDetailDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 删除指定账号和角色的所有详情记录
   */
  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_DETAIL);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GenshinCharacterDetailDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): GenshinCharacterDetailRow {
    try {
      const row = new GenshinCharacterDetailRow();
      const idVal = rs.getValue(rs.getColumnIndex('id'));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex('account_id'));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex('role_uid'));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex('avatar_id'));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const weaponIdVal = rs.getValue(rs.getColumnIndex('weapon_id'));
      row.weaponId = typeof weaponIdVal === 'string' ? weaponIdVal : '';
      const weaponLevelVal = rs.getValue(rs.getColumnIndex('weapon_level'));
      row.weaponLevel = typeof weaponLevelVal === 'number' ? weaponLevelVal : 0;
      const weaponAffixVal = rs.getValue(rs.getColumnIndex('weapon_affix_level'));
      row.weaponAffixLevel = typeof weaponAffixVal === 'number' ? weaponAffixVal : 0;
      const relicIdsVal = rs.getValue(rs.getColumnIndex('relic_ids'));
      row.relicIds = typeof relicIdsVal === 'string' ? relicIdsVal : '';
      const skillLevelsVal = rs.getValue(rs.getColumnIndex('skill_levels'));
      row.skillLevels = typeof skillLevelsVal === 'string' ? skillLevelsVal : '';
      const rawJsonVal = rs.getValue(rs.getColumnIndex('raw_json'));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
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
   * INSERT OR REPLACE
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
   * 按 avatarId 查询养成计算记录
   */
  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<GenshinCharacterComputeRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_COMPUTE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    predicates.and();
    predicates.equalTo('avatar_id', avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, GENSHIN_CHARACTER_COMPUTE_TABLE.columnNames(), (rs) => GenshinCharacterComputeDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterComputeDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 删除指定账号和角色的所有养成计算记录
   */
  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_COMPUTE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GenshinCharacterComputeDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): GenshinCharacterComputeRow {
    try {
      const row = new GenshinCharacterComputeRow();
      const idVal = rs.getValue(rs.getColumnIndex('id'));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex('account_id'));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex('role_uid'));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex('avatar_id'));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const avatarConsumeVal = rs.getValue(rs.getColumnIndex('avatar_consume_json'));
      row.avatarConsumeJson = typeof avatarConsumeVal === 'string' ? avatarConsumeVal : '';
      const skillConsumeVal = rs.getValue(rs.getColumnIndex('skill_consume_json'));
      row.skillConsumeJson = typeof skillConsumeVal === 'string' ? skillConsumeVal : '';
      const weaponConsumeVal = rs.getValue(rs.getColumnIndex('weapon_consume_json'));
      row.weaponConsumeJson = typeof weaponConsumeVal === 'string' ? weaponConsumeVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      return row;
    } catch (e) {
      throw new Error(`GenshinCharacterComputeDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}
