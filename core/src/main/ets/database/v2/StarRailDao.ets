import { relationalStore } from '@kit.ArkData';
import { RdbManagerV2 } from './RdbManagerV2';
import {
  TableName,
  STARRAIL_AVATAR_BASIC_TABLE,
  STARRAIL_DAILY_NOTE_TABLE,
  STARRAIL_AVATAR_INFO_TABLE,
  STARRAIL_AVATAR_COMPUTE_TABLE
} from './TableSchema';
import {
  StarRailAvatarBasicRow,
  StarRailDailyNoteRow,
  StarRailAvatarInfoRow,
  StarRailAvatarComputeRow
} from '../../models/v2/StarRailRows';

// ─────────────────────────────────────────────
// StarRailAvatarBasicDao：操作 starrail_avatar_basic
// ─────────────────────────────────────────────
export class StarRailAvatarBasicDao {

  async upsertAll(rows: StarRailAvatarBasicRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    const columns = STARRAIL_AVATAR_BASIC_TABLE.columnNames();
    try {
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
        await RdbManagerV2.upsertRow(TableName.STARRAIL_AVATAR_BASIC, columns, [
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

  async findAll(accountId: number, roleUid: string): Promise<StarRailAvatarBasicRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_BASIC);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      return await RdbManagerV2.queryAll(predicates, STARRAIL_AVATAR_BASIC_TABLE.columnNames(), (rs) => StarRailAvatarBasicDao.mapRow(rs));
    } catch (e) {
      throw new Error(`StarRailAvatarBasicDao.findAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<StarRailAvatarBasicRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_BASIC);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    predicates.and();
    predicates.equalTo('avatar_id', avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, STARRAIL_AVATAR_BASIC_TABLE.columnNames(), (rs) => StarRailAvatarBasicDao.mapRow(rs));
    } catch (e) {
      throw new Error(`StarRailAvatarBasicDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_BASIC);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`StarRailAvatarBasicDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): StarRailAvatarBasicRow {
    try {
      const row = new StarRailAvatarBasicRow();
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
      const rankVal = rs.getValue(rs.getColumnIndex('rank'));
      row.rank = typeof rankVal === 'number' ? rankVal : 0;
      const baseTypeVal = rs.getValue(rs.getColumnIndex('base_type'));
      row.baseType = typeof baseTypeVal === 'number' ? baseTypeVal : 0;
      const equipIdVal = rs.getValue(rs.getColumnIndex('equip_id'));
      row.equipId = typeof equipIdVal === 'string' ? equipIdVal : '';
      const equipNameVal = rs.getValue(rs.getColumnIndex('equip_name'));
      row.equipName = typeof equipNameVal === 'string' ? equipNameVal : '';
      const equipRarityVal = rs.getValue(rs.getColumnIndex('equip_rarity'));
      row.equipRarity = typeof equipRarityVal === 'number' ? equipRarityVal : 0;
      const equipLevelVal = rs.getValue(rs.getColumnIndex('equip_level'));
      row.equipLevel = typeof equipLevelVal === 'number' ? equipLevelVal : 0;
      const equipRankVal = rs.getValue(rs.getColumnIndex('equip_rank'));
      row.equipRank = typeof equipRankVal === 'number' ? equipRankVal : 0;
      const iconVal = rs.getValue(rs.getColumnIndex('icon'));
      row.icon = typeof iconVal === 'string' ? iconVal : '';
      const figurePathVal = rs.getValue(rs.getColumnIndex('figure_path'));
      row.figurePath = typeof figurePathVal === 'string' ? figurePathVal : '';
      const elementIdVal = rs.getValue(rs.getColumnIndex('element_id'));
      row.elementId = typeof elementIdVal === 'number' ? elementIdVal : 0;
      const rawJsonVal = rs.getValue(rs.getColumnIndex('raw_json'));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
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

  async upsert(row: StarRailDailyNoteRow): Promise<void> {
    const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
    try {
      await RdbManagerV2.upsertRow(TableName.STARRAIL_DAILY_NOTE, STARRAIL_DAILY_NOTE_TABLE.columnNames(), [
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

  async findOne(accountId: number, roleUid: string): Promise<StarRailDailyNoteRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_DAILY_NOTE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      return await RdbManagerV2.queryFirst(predicates, STARRAIL_DAILY_NOTE_TABLE.columnNames(), (rs) => StarRailDailyNoteDao.mapRow(rs));
    } catch (e) {
      throw new Error(`StarRailDailyNoteDao.findOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  async deleteOne(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_DAILY_NOTE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`StarRailDailyNoteDao.deleteOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): StarRailDailyNoteRow {
    try {
      const row = new StarRailDailyNoteRow();
      const idVal = rs.getValue(rs.getColumnIndex('id'));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex('account_id'));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex('role_uid'));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const currentStaminaVal = rs.getValue(rs.getColumnIndex('current_stamina'));
      row.currentStamina = typeof currentStaminaVal === 'number' ? currentStaminaVal : 0;
      const maxStaminaVal = rs.getValue(rs.getColumnIndex('max_stamina'));
      row.maxStamina = typeof maxStaminaVal === 'number' ? maxStaminaVal : 0;
      const staminaRecoverVal = rs.getValue(rs.getColumnIndex('stamina_recover_time'));
      row.staminaRecoverTime = typeof staminaRecoverVal === 'number' ? staminaRecoverVal : 0;
      const staminaFullTsVal = rs.getValue(rs.getColumnIndex('stamina_full_ts'));
      row.staminaFullTs = typeof staminaFullTsVal === 'number' ? staminaFullTsVal : 0;
      const reserveStaminaVal = rs.getValue(rs.getColumnIndex('current_reserve_stamina'));
      row.currentReserveStamina = typeof reserveStaminaVal === 'number' ? reserveStaminaVal : 0;
      const acceptedExpeditionVal = rs.getValue(rs.getColumnIndex('accepted_expedition_num'));
      row.acceptedExpeditionNum = typeof acceptedExpeditionVal === 'number' ? acceptedExpeditionVal : 0;
      const totalExpeditionVal = rs.getValue(rs.getColumnIndex('total_expedition_num'));
      row.totalExpeditionNum = typeof totalExpeditionVal === 'number' ? totalExpeditionVal : 0;
      const currentTrainVal = rs.getValue(rs.getColumnIndex('current_train_score'));
      row.currentTrainScore = typeof currentTrainVal === 'number' ? currentTrainVal : 0;
      const maxTrainVal = rs.getValue(rs.getColumnIndex('max_train_score'));
      row.maxTrainScore = typeof maxTrainVal === 'number' ? maxTrainVal : 0;
      const currentRogueVal = rs.getValue(rs.getColumnIndex('current_rogue_score'));
      row.currentRogueScore = typeof currentRogueVal === 'number' ? currentRogueVal : 0;
      const maxRogueVal = rs.getValue(rs.getColumnIndex('max_rogue_score'));
      row.maxRogueScore = typeof maxRogueVal === 'number' ? maxRogueVal : 0;
      const weeklyCocoonCntVal = rs.getValue(rs.getColumnIndex('weekly_cocoon_cnt'));
      row.weeklyCocoonCnt = typeof weeklyCocoonCntVal === 'number' ? weeklyCocoonCntVal : 0;
      const weeklyCocoonLimitVal = rs.getValue(rs.getColumnIndex('weekly_cocoon_limit'));
      row.weeklyCocoonLimit = typeof weeklyCocoonLimitVal === 'number' ? weeklyCocoonLimitVal : 0;
      const rogueTournCurVal = rs.getValue(rs.getColumnIndex('rogue_tourn_weekly_cur'));
      row.rogueTournWeeklyCur = typeof rogueTournCurVal === 'number' ? rogueTournCurVal : 0;
      const rogueTournMaxVal = rs.getValue(rs.getColumnIndex('rogue_tourn_weekly_max'));
      row.rogueTournWeeklyMax = typeof rogueTournMaxVal === 'number' ? rogueTournMaxVal : 0;
      const gridFightCurVal = rs.getValue(rs.getColumnIndex('grid_fight_weekly_cur'));
      row.gridFightWeeklyCur = typeof gridFightCurVal === 'number' ? gridFightCurVal : 0;
      const gridFightMaxVal = rs.getValue(rs.getColumnIndex('grid_fight_weekly_max'));
      row.gridFightWeeklyMax = typeof gridFightMaxVal === 'number' ? gridFightMaxVal : 0;
      const rawJsonVal = rs.getValue(rs.getColumnIndex('raw_json'));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
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

  async upsertAll(rows: StarRailAvatarInfoRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    const columns = STARRAIL_AVATAR_INFO_TABLE.columnNames();
    try {
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
        await RdbManagerV2.upsertRow(TableName.STARRAIL_AVATAR_INFO, columns, [
          idVal, row.accountId, row.roleUid, row.avatarId, row.equipId,
          row.equipLevel, row.equipRank, row.relicIds, row.skillTreeJson,
          row.rawJson, row.updateTime
        ]);
      }
    } catch (e) {
      throw new Error(`StarRailAvatarInfoDao.upsertAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<StarRailAvatarInfoRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_INFO);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    predicates.and();
    predicates.equalTo('avatar_id', avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, STARRAIL_AVATAR_INFO_TABLE.columnNames(), (rs) => StarRailAvatarInfoDao.mapRow(rs));
    } catch (e) {
      throw new Error(`StarRailAvatarInfoDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_INFO);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`StarRailAvatarInfoDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): StarRailAvatarInfoRow {
    try {
      const row = new StarRailAvatarInfoRow();
      const idVal = rs.getValue(rs.getColumnIndex('id'));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex('account_id'));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex('role_uid'));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const avatarIdVal = rs.getValue(rs.getColumnIndex('avatar_id'));
      row.avatarId = typeof avatarIdVal === 'string' ? avatarIdVal : '';
      const equipIdVal = rs.getValue(rs.getColumnIndex('equip_id'));
      row.equipId = typeof equipIdVal === 'string' ? equipIdVal : '';
      const equipLevelVal = rs.getValue(rs.getColumnIndex('equip_level'));
      row.equipLevel = typeof equipLevelVal === 'number' ? equipLevelVal : 0;
      const equipRankVal = rs.getValue(rs.getColumnIndex('equip_rank'));
      row.equipRank = typeof equipRankVal === 'number' ? equipRankVal : 0;
      const relicIdsVal = rs.getValue(rs.getColumnIndex('relic_ids'));
      row.relicIds = typeof relicIdsVal === 'string' ? relicIdsVal : '';
      const skillTreeJsonVal = rs.getValue(rs.getColumnIndex('skill_tree_json'));
      row.skillTreeJson = typeof skillTreeJsonVal === 'string' ? skillTreeJsonVal : '';
      const rawJsonVal = rs.getValue(rs.getColumnIndex('raw_json'));
      row.rawJson = typeof rawJsonVal === 'string' ? rawJsonVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
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

  async upsert(row: StarRailAvatarComputeRow): Promise<void> {
    const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
    try {
      await RdbManagerV2.upsertRow(TableName.STARRAIL_AVATAR_COMPUTE, STARRAIL_AVATAR_COMPUTE_TABLE.columnNames(), [
        idVal, row.accountId, row.roleUid, row.avatarId,
        row.avatarConsumeJson, row.skillConsumeJson, row.equipmentConsumeJson, row.updateTime
      ]);
    } catch (e) {
      throw new Error(`StarRailAvatarComputeDao.upsert failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  async findByAvatarId(accountId: number, roleUid: string, avatarId: string): Promise<StarRailAvatarComputeRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_COMPUTE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    predicates.and();
    predicates.equalTo('avatar_id', avatarId);
    try {
      return await RdbManagerV2.queryFirst(predicates, STARRAIL_AVATAR_COMPUTE_TABLE.columnNames(), (rs) => StarRailAvatarComputeDao.mapRow(rs));
    } catch (e) {
      throw new Error(`StarRailAvatarComputeDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  async deleteAll(accountId: number, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.STARRAIL_AVATAR_COMPUTE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('role_uid', roleUid);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`StarRailAvatarComputeDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  private static mapRow(rs: relationalStore.ResultSet): StarRailAvatarComputeRow {
    try {
      const row = new StarRailAvatarComputeRow();
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
      const equipmentConsumeVal = rs.getValue(rs.getColumnIndex('equipment_consume_json'));
      row.equipmentConsumeJson = typeof equipmentConsumeVal === 'string' ? equipmentConsumeVal : '';
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      return row;
    } catch (e) {
      throw new Error(`StarRailAvatarComputeDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}
