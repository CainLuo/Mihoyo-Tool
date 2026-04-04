import { relationalStore } from '@kit.ArkData';
import { RdbManagerV2 } from './RdbManagerV2';
import {
  TableName,
  ZZZ_AVATAR_BASIC_TABLE,
  ZZZ_DAILY_NOTE_TABLE,
  ZZZ_AVATAR_INFO_TABLE,
  ZZZ_AVATAR_COMPUTE_TABLE
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

  async findAll(accountId: number, roleUid: string): Promise<ZZZAvatarBasicRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_BASIC);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      return await RdbManagerV2.queryAll(predicates, ZZZ_AVATAR_BASIC_TABLE.columnNames(), (rs) => ZZZAvatarBasicDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZAvatarBasicDao.findAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<ZZZAvatarBasicRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_BASIC);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    predicates.and();
    predicates.equalTo('avatar_id', avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, ZZZ_AVATAR_BASIC_TABLE.columnNames(), (rs) => ZZZAvatarBasicDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZAvatarBasicDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_BASIC);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZAvatarBasicDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): ZZZAvatarBasicRow {
    try {
      const row = new ZZZAvatarBasicRow();
      const idVal = rs.getValue(rs.getColumnIndex('id'));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex('account_id'));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex('role_uid'));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex('avatar_id'));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const nameMi18nVal = rs.getValue(rs.getColumnIndex('name_mi18n'));
      row.nameMi18n = typeof nameMi18nVal === 'string' ? nameMi18nVal : '';
      const fullNameMi18nVal = rs.getValue(rs.getColumnIndex('full_name_mi18n'));
      row.fullNameMi18n = typeof fullNameMi18nVal === 'string' ? fullNameMi18nVal : '';
      const elementTypeVal = rs.getValue(rs.getColumnIndex('element_type'));
      row.elementType = typeof elementTypeVal === 'number' ? elementTypeVal : 0;
      const subElementTypeVal = rs.getValue(rs.getColumnIndex('sub_element_type'));
      row.subElementType = typeof subElementTypeVal === 'number' ? subElementTypeVal : 0;
      const avatarProfessionVal = rs.getValue(rs.getColumnIndex('avatar_profession'));
      row.avatarProfession = typeof avatarProfessionVal === 'number' ? avatarProfessionVal : 0;
      const rarityVal = rs.getValue(rs.getColumnIndex('rarity'));
      row.rarity = typeof rarityVal === 'string' ? rarityVal : '';
      const levelVal = rs.getValue(rs.getColumnIndex('level'));
      row.level = typeof levelVal === 'number' ? levelVal : 0;
      const rankVal = rs.getValue(rs.getColumnIndex('rank'));
      row.rank = typeof rankVal === 'number' ? rankVal : 0;
      const campNameMi18nVal = rs.getValue(rs.getColumnIndex('camp_name_mi18n'));
      row.campNameMi18n = typeof campNameMi18nVal === 'string' ? campNameMi18nVal : '';
      const groupIconPathVal = rs.getValue(rs.getColumnIndex('group_icon_path'));
      row.groupIconPath = typeof groupIconPathVal === 'string' ? groupIconPathVal : '';
      const hollowIconPathVal = rs.getValue(rs.getColumnIndex('hollow_icon_path'));
      row.hollowIconPath = typeof hollowIconPathVal === 'string' ? hollowIconPathVal : '';
      const roleSquareUrlVal = rs.getValue(rs.getColumnIndex('role_square_url'));
      row.roleSquareUrl = typeof roleSquareUrlVal === 'string' ? roleSquareUrlVal : '';
      const awakenStateVal = rs.getValue(rs.getColumnIndex('awaken_state'));
      row.awakenState = typeof awakenStateVal === 'string' ? parseInt(awakenStateVal) : 0;
      const rawJsonVal = rs.getValue(rs.getColumnIndex('raw_json'));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
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

  async findOne(accountId: number, roleUid: string): Promise<ZZZDailyNoteRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_DAILY_NOTE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      return await RdbManagerV2.queryFirst(predicates, ZZZ_DAILY_NOTE_TABLE.columnNames(), (rs) => ZZZDailyNoteDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZDailyNoteDao.findOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  async deleteOne(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_DAILY_NOTE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZDailyNoteDao.deleteOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): ZZZDailyNoteRow {
    try {
      const row = new ZZZDailyNoteRow();
      const idVal = rs.getValue(rs.getColumnIndex('id'));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex('account_id'));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex('role_uid'));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const energyCurrentVal = rs.getValue(rs.getColumnIndex('energy_current'));
      row.energyCurrent = typeof energyCurrentVal === 'number' ? energyCurrentVal : 0;
      const energyMaxVal = rs.getValue(rs.getColumnIndex('energy_max'));
      row.energyMax = typeof energyMaxVal === 'number' ? energyMaxVal : 0;
      const energyRestoreVal = rs.getValue(rs.getColumnIndex('energy_restore'));
      row.energyRestore = typeof energyRestoreVal === 'number' ? energyRestoreVal : 0;
      const vitalityCurrentVal = rs.getValue(rs.getColumnIndex('vitality_current'));
      row.vitalityCurrent = typeof vitalityCurrentVal === 'number' ? vitalityCurrentVal : 0;
      const vitalityMaxVal = rs.getValue(rs.getColumnIndex('vitality_max'));
      row.vitalityMax = typeof vitalityMaxVal === 'number' ? vitalityMaxVal : 0;
      const vhsSaleStateVal = rs.getValue(rs.getColumnIndex('vhs_sale_state'));
      row.vhsSaleState = typeof vhsSaleStateVal === 'string' ? vhsSaleStateVal : '';
      const cardSignVal = rs.getValue(rs.getColumnIndex('card_sign'));
      row.cardSign = typeof cardSignVal === 'string' ? cardSignVal : '';
      const rawJsonVal = rs.getValue(rs.getColumnIndex('raw_json'));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
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

  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<ZZZAvatarInfoRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_INFO);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    predicates.and();
    predicates.equalTo('avatar_id', avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, ZZZ_AVATAR_INFO_TABLE.columnNames(), (rs) => ZZZAvatarInfoDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZAvatarInfoDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_INFO);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZAvatarInfoDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): ZZZAvatarInfoRow {
    try {
      const row = new ZZZAvatarInfoRow();
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
      const weaponStarVal = rs.getValue(rs.getColumnIndex('weapon_star'));
      row.weaponStar = typeof weaponStarVal === 'number' ? weaponStarVal : 0;
      const equipIdsVal = rs.getValue(rs.getColumnIndex('equip_ids'));
      row.equipIds = typeof equipIdsVal === 'string' ? equipIdsVal : '';
      const skillLevelsJsonVal = rs.getValue(rs.getColumnIndex('skill_levels_json'));
      row.skillLevelsJson = typeof skillLevelsJsonVal === 'string' ? skillLevelsJsonVal : '';
      const verticalPaintingUrlVal = rs.getValue(rs.getColumnIndex('vertical_painting_url'));
      row.verticalPaintingUrl = typeof verticalPaintingUrlVal === 'string' ? verticalPaintingUrlVal : '';
      const rawJsonVal = rs.getValue(rs.getColumnIndex('raw_json'));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
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

  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<ZZZAvatarComputeRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_COMPUTE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    predicates.and();
    predicates.equalTo('avatar_id', avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, ZZZ_AVATAR_COMPUTE_TABLE.columnNames(), (rs) => ZZZAvatarComputeDao.mapRow(rs));
    } catch (e) {
      throw new Error(`ZZZAvatarComputeDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_AVATAR_COMPUTE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`ZZZAvatarComputeDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): ZZZAvatarComputeRow {
    try {
      const row = new ZZZAvatarComputeRow();
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
      const weaponConsumeVal = rs.getValue(rs.getColumnIndex('weapon_consume_json'));
      row.weaponConsumeJson = typeof weaponConsumeVal === 'string' ? weaponConsumeVal : '';
      const skillConsumeVal = rs.getValue(rs.getColumnIndex('skill_consume_json'));
      row.skillConsumeJson = typeof skillConsumeVal === 'string' ? skillConsumeVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      return row;
    } catch (e) {
      throw new Error(`ZZZAvatarComputeDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}
