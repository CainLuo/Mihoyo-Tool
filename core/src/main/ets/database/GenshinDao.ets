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
 * 所有读取操作通过 RdbManager.queryFirst/queryAll 封装，自动管理 ResultSet 生命周期。
 */
import { relationalStore } from '@kit.ArkData';
import { RdbManager } from './RdbManager';
import { RsReader } from './RsReader';
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
} from '../models/GenshinRows';

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
        await RdbManager.upsertRow(TableName.GENSHIN_CHARACTER_LIST, columns, [
          idVal, row.accountId, row.roleUid, row.avatarId, row.name, row.element,
          row.rarity, row.level, row.fetter, row.activedConstellationNum,
          row.weaponType, row.weaponId, row.weaponName, row.weaponRarity,
          row.weaponLevel, row.weaponAffixLevel, row.weaponIconUrl, row.image, row.isChosen,
          row.icon, row.sideIcon, row.rawJson, row.updateTime
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
  async findAll(accountId: string, roleUid: string): Promise<GenshinCharacterListRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_LIST);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManager.queryAll(predicates, GENSHIN_CHARACTER_LIST_TABLE.columnNames(), (rs) => GenshinCharacterListDao.mapRow(rs));
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
  async findByAvatarId(accountId: string, roleUid: string, avatarId: string): Promise<GenshinCharacterListRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_LIST);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManager.queryFirst(predicates, GENSHIN_CHARACTER_LIST_TABLE.columnNames(), (rs) => GenshinCharacterListDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterListDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 删除指定账号和角色的所有原神角色列表记录。
   * 通常在重新同步前调用，配合 upsertAll 实现全量刷新。
   */
  async deleteAll(accountId: string, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_LIST);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GenshinCharacterListDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 将 ResultSet 当前行映射为 GenshinCharacterListRow。
   */
  private static mapRow(rs: relationalStore.ResultSet): GenshinCharacterListRow {
    try {
      const r = new RsReader(rs);
      const row = new GenshinCharacterListRow();
      row.id                      = r.num(CommonCol.ID);
      row.accountId               = r.str(CommonCol.ACCOUNT_ID);
      row.roleUid                 = r.str(CommonCol.ROLE_UID);
      row.avatarId                = r.str(CommonCol.AVATAR_ID);
      row.name                    = r.str(GenshinCharListCol.NAME);
      row.element                 = r.str(GenshinCharListCol.ELEMENT);
      row.rarity                  = r.num(GenshinCharListCol.RARITY);
      row.level                   = r.num(GenshinCharListCol.LEVEL);
      row.fetter                  = r.num(GenshinCharListCol.FETTER);
      row.activedConstellationNum = r.num(GenshinCharListCol.ACTIVED_CONSTELLATION_NUM);
      row.weaponType              = r.num(GenshinCharListCol.WEAPON_TYPE);
      row.weaponId                = r.str(GenshinCharListCol.WEAPON_ID);
      row.weaponName              = r.str(GenshinCharListCol.WEAPON_NAME);
      row.weaponRarity            = r.num(GenshinCharListCol.WEAPON_RARITY);
      row.weaponLevel             = r.num(GenshinCharListCol.WEAPON_LEVEL);
      row.weaponAffixLevel        = r.num(GenshinCharListCol.WEAPON_AFFIX_LEVEL);
      row.weaponIconUrl           = r.str(GenshinCharListCol.WEAPON_ICON_URL);
      row.image                   = r.str(GenshinCharListCol.IMAGE);
      row.isChosen                = r.num(GenshinCharListCol.IS_CHOSEN);
      row.icon                    = r.str(GenshinCharListCol.ICON);
      row.sideIcon                = r.str(GenshinCharListCol.SIDE_ICON);
      row.rawJson                 = r.str(CommonCol.RAW_JSON);
      row.updateTime              = r.num(CommonCol.UPDATE_TIME);
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
      await RdbManager.upsertRow(TableName.GENSHIN_DAILY_NOTE, GENSHIN_DAILY_NOTE_TABLE.columnNames(), [
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
  async findOne(accountId: string, roleUid: string): Promise<GenshinDailyNoteRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_DAILY_NOTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManager.queryFirst(predicates, GENSHIN_DAILY_NOTE_TABLE.columnNames(), (rs) => GenshinDailyNoteDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinDailyNoteDao.findOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定角色的原神实时便笺记录 */
  async deleteOne(accountId: string, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_DAILY_NOTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GenshinDailyNoteDao.deleteOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 GenshinDailyNoteRow */
  private static mapRow(rs: relationalStore.ResultSet): GenshinDailyNoteRow {
    try {
      const r = new RsReader(rs);
      const row = new GenshinDailyNoteRow();
      row.id                    = r.num(CommonCol.ID);
      row.accountId             = r.str(CommonCol.ACCOUNT_ID);
      row.roleUid               = r.str(CommonCol.ROLE_UID);
      row.currentResin          = r.num(GenshinDailyNoteCol.CURRENT_RESIN);
      row.maxResin              = r.num(GenshinDailyNoteCol.MAX_RESIN);
      row.resinRecoveryTime     = r.num(GenshinDailyNoteCol.RESIN_RECOVERY_TIME);
      row.finishedTaskNum       = r.num(GenshinDailyNoteCol.FINISHED_TASK_NUM);
      row.totalTaskNum          = r.num(GenshinDailyNoteCol.TOTAL_TASK_NUM);
      row.remainResinDiscountNum = r.num(GenshinDailyNoteCol.REMAIN_RESIN_DISCOUNT_NUM);
      row.currentExpeditionNum  = r.num(GenshinDailyNoteCol.CURRENT_EXPEDITION_NUM);
      row.maxExpeditionNum      = r.num(GenshinDailyNoteCol.MAX_EXPEDITION_NUM);
      row.currentHomeCoin       = r.num(GenshinDailyNoteCol.CURRENT_HOME_COIN);
      row.maxHomeCoin           = r.num(GenshinDailyNoteCol.MAX_HOME_COIN);
      row.transformerRecoveryDay = r.num(GenshinDailyNoteCol.TRANSFORMER_RECOVERY_DAY);
      row.rawJson               = r.str(CommonCol.RAW_JSON);
      row.updateTime            = r.num(CommonCol.UPDATE_TIME);
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
        await RdbManager.upsertRow(TableName.GENSHIN_CHARACTER_DETAIL, columns, [
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
  async findByAvatarId(accountId: string, roleUid: string, avatarId: string): Promise<GenshinCharacterDetailRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_DETAIL);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManager.queryFirst(predicates, GENSHIN_CHARACTER_DETAIL_TABLE.columnNames(), (rs) => GenshinCharacterDetailDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterDetailDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询指定账号和角色的所有原神角色详情。
   * @returns 角色详情行数组
   */
  async findAll(accountId: string, roleUid: string): Promise<GenshinCharacterDetailRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_DETAIL);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManager.queryAll(predicates, GENSHIN_CHARACTER_DETAIL_TABLE.columnNames(), (rs) => GenshinCharacterDetailDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterDetailDao.findAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有原神角色详情记录 */
  async deleteAll(accountId: string, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_DETAIL);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GenshinCharacterDetailDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 GenshinCharacterDetailRow */
  private static mapRow(rs: relationalStore.ResultSet): GenshinCharacterDetailRow {
    try {
      const r = new RsReader(rs);
      const row = new GenshinCharacterDetailRow();
      row.id               = r.num(CommonCol.ID);
      row.accountId        = r.str(CommonCol.ACCOUNT_ID);
      row.roleUid          = r.str(CommonCol.ROLE_UID);
      row.avatarId         = r.str(CommonCol.AVATAR_ID);
      row.weaponId         = r.str(GenshinCharDetailCol.WEAPON_ID);
      row.weaponLevel      = r.num(GenshinCharDetailCol.WEAPON_LEVEL);
      row.weaponAffixLevel = r.num(GenshinCharDetailCol.WEAPON_AFFIX_LEVEL);
      row.relicIds         = r.str(GenshinCharDetailCol.RELIC_IDS);
      row.skillLevels      = r.str(GenshinCharDetailCol.SKILL_LEVELS);
      row.rawJson          = r.str(CommonCol.RAW_JSON);
      row.updateTime       = r.num(CommonCol.UPDATE_TIME);
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
      await RdbManager.upsertRow(TableName.GENSHIN_CHARACTER_COMPUTE, GENSHIN_CHARACTER_COMPUTE_TABLE.columnNames(), [
        idVal, row.accountId, row.roleUid, row.avatarId,
        row.avatarConsumeJson, row.skillConsumeJson, row.weaponConsumeJson, row.rawJson, row.updateTime
      ]);
    } catch (e) {
      throw new Error(`GenshinCharacterComputeDao.upsert failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询指定账号和角色的所有养成计算数据。
   * @param accountId 米游社账号 ID
   * @param roleUid   游戏角色 UID
   */
  async findAll(accountId: string, roleUid: string): Promise<GenshinCharacterComputeRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_COMPUTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      return await RdbManager.queryAll(predicates, GENSHIN_CHARACTER_COMPUTE_TABLE.columnNames(), (rs) => GenshinCharacterComputeDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterComputeDao.findAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 avatarId 查询原神角色养成计算数据。
   * @returns 找到时返回计算行，否则返回 null
   */
  async findByAvatarId(accountId: string, roleUid: string, avatarId: string): Promise<GenshinCharacterComputeRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_COMPUTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.AVATAR_ID, avatarId);
    try {
      return await RdbManager.queryFirst(predicates, GENSHIN_CHARACTER_COMPUTE_TABLE.columnNames(), (rs) => GenshinCharacterComputeDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GenshinCharacterComputeDao.findByAvatarId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 删除指定账号和角色的所有原神养成计算记录 */
  async deleteAll(accountId: string, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GENSHIN_CHARACTER_COMPUTE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GenshinCharacterComputeDao.deleteAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 GenshinCharacterComputeRow */
  private static mapRow(rs: relationalStore.ResultSet): GenshinCharacterComputeRow {
    try {
      const r = new RsReader(rs);
      const row = new GenshinCharacterComputeRow();
      row.id                = r.num(CommonCol.ID);
      row.accountId         = r.str(CommonCol.ACCOUNT_ID);
      row.roleUid           = r.str(CommonCol.ROLE_UID);
      row.avatarId          = r.str(CommonCol.AVATAR_ID);
      row.avatarConsumeJson = r.str(GenshinCharComputeCol.AVATAR_CONSUME_JSON);
      row.skillConsumeJson  = r.str(GenshinCharComputeCol.SKILL_CONSUME_JSON);
      row.weaponConsumeJson = r.str(GenshinCharComputeCol.WEAPON_CONSUME_JSON);
      row.rawJson           = r.str(CommonCol.RAW_JSON);
      row.updateTime        = r.num(CommonCol.UPDATE_TIME);
      return row;
    } catch (e) {
      throw new Error(`GenshinCharacterComputeDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}
