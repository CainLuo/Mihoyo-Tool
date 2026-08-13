/**
 * MaterialTargetConfigDao — 养成目标配置数据访问对象
 *
 * 提供对三个游戏养成目标配置表的 CRUD 操作。
 * 每个游戏有独立的表，通过继承 BaseMaterialTargetConfigDao 实现。
 *
 * 唯一键：(account_id, role_uid)
 * 同一个米游社账号下，不同游戏角色的配置是独立的。
 *
 * 使用方法：
 * ```typescript
 * // 原神养成目标配置
 * const genshinDao = new GenshinMaterialTargetConfigDao();
 * await genshinDao.upsert(accountId, roleUid, configRow);
 * const config = await genshinDao.findOne(accountId, roleUid);
 *
 * // 星铁养成目标配置
 * const starrailDao = new StarRailMaterialTargetConfigDao();
 *
 * // 绝区零养成目标配置
 * const zzzDao = new ZZZMaterialTargetConfigDao();
 * ```
 */

import { relationalStore } from '@kit.ArkData';
import { RdbManager } from './RdbManager';
import { TableName, CommonCol, MaterialTargetConfigCol, TableDef, GENSHIN_MATERIAL_TARGET_CONFIG_TABLE, STARRAIL_MATERIAL_TARGET_CONFIG_TABLE, ZZZ_MATERIAL_TARGET_CONFIG_TABLE } from './TableSchema';
import { RsReader } from './RsReader';
import { MaterialTargetConfigRow } from '../models/MaterialTargetConfigRow';

/**
 * 养成目标配置 DAO 基类
 * 子类只需提供表名和表定义
 */
export abstract class BaseMaterialTargetConfigDao {
  protected abstract tableName: TableName;
  protected abstract tableDef: TableDef;

  /**
   * 写入或更新配置数据
   * 使用 INSERT OR REPLACE 语义，唯一键冲突时更新
   *
   * @param row 配置数据（accountId 和 roleUid 必须设置）
   */
  async upsert(row: MaterialTargetConfigRow): Promise<void> {
    const now = Math.floor(Date.now() / 1000);
    row.updateTime = now;

    const columns = this.tableDef.columnNames();
    const values: Array<relationalStore.ValueType> = [
      row.id > 0 ? row.id : null,  // id: INTEGER PRIMARY KEY AUTOINCREMENT
      row.accountId,
      row.roleUid,
      row.configJson,
      row.updateTime
    ];

    await RdbManager.upsertRow(this.tableName, columns, values);
  }

  /**
   * 查询指定游戏角色的配置
   *
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @returns 配置数据，不存在时返回 null
   */
  async findOne(accountId: string, roleUid: string): Promise<MaterialTargetConfigRow | null> {
    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);

    try {
      return await RdbManager.queryFirst<MaterialTargetConfigRow>(
        predicates,
        this.tableDef.columnNames(),
        (rs: relationalStore.ResultSet): MaterialTargetConfigRow => this.mapRow(rs)
      );
    } catch (e) {
      throw new Error(`MaterialTargetConfigDao.findOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 删除指定游戏角色的配置
   *
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   */
  async deleteOne(accountId: string, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    await RdbManager.deleteRows(predicates);
  }

  /**
   * 删除指定账号下所有配置（所有游戏角色）
   *
   * @param accountId 米游社账号 UID
   */
  async deleteByAccount(accountId: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    await RdbManager.deleteRows(predicates);
  }

  /** 将 ResultSet 当前行映射为 MaterialTargetConfigRow */
  protected mapRow(rs: relationalStore.ResultSet): MaterialTargetConfigRow {
    try {
      const r = new RsReader(rs);
      const row = new MaterialTargetConfigRow();
      row.id         = r.num(CommonCol.ID);
      row.accountId  = r.str(CommonCol.ACCOUNT_ID);
      row.roleUid    = r.str(CommonCol.ROLE_UID);
      row.configJson = r.str(MaterialTargetConfigCol.CONFIG_JSON);
      row.updateTime = r.num(CommonCol.UPDATE_TIME);
      return row;
    } catch (e) {
      throw new Error(`MaterialTargetConfigDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

/**
 * 原神养成目标配置 DAO
 */
export class GenshinMaterialTargetConfigDao extends BaseMaterialTargetConfigDao {
  protected tableName: TableName = TableName.GENSHIN_MATERIAL_TARGET_CONFIG;
  protected tableDef: TableDef = GENSHIN_MATERIAL_TARGET_CONFIG_TABLE;
}

/**
 * 星穹铁道养成目标配置 DAO
 */
export class StarRailMaterialTargetConfigDao extends BaseMaterialTargetConfigDao {
  protected tableName: TableName = TableName.STARRAIL_MATERIAL_TARGET_CONFIG;
  protected tableDef: TableDef = STARRAIL_MATERIAL_TARGET_CONFIG_TABLE;
}

/**
 * 绝区零养成目标配置 DAO
 */
export class ZZZMaterialTargetConfigDao extends BaseMaterialTargetConfigDao {
  protected tableName: TableName = TableName.ZZZ_MATERIAL_TARGET_CONFIG;
  protected tableDef: TableDef = ZZZ_MATERIAL_TARGET_CONFIG_TABLE;
}
