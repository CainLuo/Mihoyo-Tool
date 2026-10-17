/**
 * MaterialBagDao — 材料背包数据访问对象
 *
 * 提供对三个游戏材料背包表的 CRUD 操作。
 * 每个游戏有独立的表，通过继承 BaseMaterialBagDao 实现。
 *
 * 唯一键：(account_id, role_uid, material_id)
 * 同一个米游社账号下，不同游戏角色的背包是独立的。
 *
 * 使用方法：
 * ```typescript
 * // 原神材料
 * const genshinDao = new GenshinMaterialBagDao();
 * await genshinDao.upsertAll(accountId, roleUid, materials);
 * const materials = await genshinDao.findByRole(accountId, roleUid);
 *
 * // 星铁材料
 * const starrailDao = new StarRailMaterialBagDao();
 *
 * // 绝区零材料
 * const zzzDao = new ZZZMaterialBagDao();
 * ```
 */

import { relationalStore } from '@kit.ArkData';
import { RdbManager } from './RdbManager';
import { TableName, CommonCol, MaterialBagCol, TableDef, GENSHIN_MATERIAL_BAG_TABLE, STARRAIL_MATERIAL_BAG_TABLE, ZZZ_MATERIAL_BAG_TABLE } from './TableSchema';
import { RsReader } from './RsReader';
import { MaterialBagRow } from '../models/MaterialBagRow';

/**
 * 材料背包 DAO 基类
 * 子类只需提供表名和表定义
 */
export abstract class BaseMaterialBagDao {
  protected abstract tableName: TableName;
  protected abstract tableDef: TableDef;

  /**
   * 批量写入或更新材料数据
   * 使用 INSERT OR REPLACE 语义，唯一键冲突时更新
   *
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param rows 材料数据数组
   */
  async upsertAll(accountId: string, roleUid: string, rows: MaterialBagRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }

    const now = Math.floor(Date.now() / 1000);
    const columns = this.tableDef.columnNames();

    await RdbManager.runInTransaction(async () => {
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        row.accountId = accountId;
        row.roleUid = roleUid;
        row.updateTime = now;

        const values: Array<relationalStore.ValueType> = [
          row.id > 0 ? row.id : null,  // id: INTEGER PRIMARY KEY AUTOINCREMENT
          row.accountId,
          row.roleUid,
          row.materialId,    // TEXT
          row.materialName,
          row.materialIcon,
          row.rarity,        // TEXT
          row.count,
          row.source,        // TEXT
          row.updateTime
        ];

        await RdbManager.upsertRow(this.tableName, columns, values);
      }
    });
  }

  /**
   * 查询指定游戏角色下所有材料
   *
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @returns 材料数据数组
   */
  async findByRole(accountId: string, roleUid: string): Promise<MaterialBagRow[]> {
    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.orderByDesc(MaterialBagCol.RARITY);
    predicates.orderByAsc(MaterialBagCol.MATERIAL_NAME);

    try {
      return await RdbManager.queryAll<MaterialBagRow>(
        predicates,
        this.tableDef.columnNames(),
        (rs: relationalStore.ResultSet): MaterialBagRow => this.mapRow(rs)
      );
    } catch (e) {
      throw new Error(`MaterialBagDao.findByRole failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询单个材料
   *
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param materialId 材料 ID（字符串）
   * @returns 材料数据，不存在时返回 null
   */
  async findOne(accountId: string, roleUid: string, materialId: string): Promise<MaterialBagRow | null> {
    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.equalTo(MaterialBagCol.MATERIAL_ID, materialId);

    try {
      return await RdbManager.queryFirst<MaterialBagRow>(
        predicates,
        this.tableDef.columnNames(),
        (rs: relationalStore.ResultSet): MaterialBagRow => this.mapRow(rs)
      );
    } catch (e) {
      throw new Error(`MaterialBagDao.findOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 删除指定游戏角色下所有材料
   *
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   */
  async deleteByRole(accountId: string, roleUid: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    await RdbManager.deleteRows(predicates);
  }

  /**
   * 删除指定账号下所有材料（所有游戏角色）
   *
   * @param accountId 米游社账号 UID
   */
  async deleteByAccount(accountId: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    await RdbManager.deleteRows(predicates);
  }

  /**
   * 更新单个材料的数量
   *
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param materialId 材料 ID（字符串）
   * @param count 新数量
   */
  async updateCount(accountId: string, roleUid: string, materialId: string, count: number): Promise<void> {
    const now = Math.floor(Date.now() / 1000);
    await RdbManager.updateRows(
      this.tableName,
      [MaterialBagCol.COUNT, CommonCol.UPDATE_TIME],
      [count, now],
      [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, MaterialBagCol.MATERIAL_ID],
      [accountId, roleUid, materialId]
    );
  }

  /** 将 ResultSet 当前行映射为 MaterialBagRow */
  protected mapRow(rs: relationalStore.ResultSet): MaterialBagRow {
    try {
      const r = new RsReader(rs);
      const row = new MaterialBagRow();
      row.id           = r.num(CommonCol.ID);
      row.accountId    = r.str(CommonCol.ACCOUNT_ID);
      row.roleUid      = r.str(CommonCol.ROLE_UID);
      row.materialId   = r.str(MaterialBagCol.MATERIAL_ID);
      row.materialName = r.str(MaterialBagCol.MATERIAL_NAME);
      row.materialIcon = r.str(MaterialBagCol.MATERIAL_ICON);
      row.rarity       = r.str(MaterialBagCol.RARITY);
      row.count        = r.num(MaterialBagCol.COUNT);
      row.source       = r.str(MaterialBagCol.SOURCE);
      row.updateTime   = r.num(CommonCol.UPDATE_TIME);
      return row;
    } catch (e) {
      throw new Error(`MaterialBagDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

/**
 * 原神材料背包 DAO
 */
export class GenshinMaterialBagDao extends BaseMaterialBagDao {
  protected tableName: TableName = TableName.GENSHIN_MATERIAL_BAG;
  protected tableDef: TableDef = GENSHIN_MATERIAL_BAG_TABLE;
}

/**
 * 星穹铁道材料背包 DAO
 */
export class StarRailMaterialBagDao extends BaseMaterialBagDao {
  protected tableName: TableName = TableName.STARRAIL_MATERIAL_BAG;
  protected tableDef: TableDef = STARRAIL_MATERIAL_BAG_TABLE;
}

/**
 * 绝区零材料背包 DAO
 */
export class ZZZMaterialBagDao extends BaseMaterialBagDao {
  protected tableName: TableName = TableName.ZZZ_MATERIAL_BAG;
  protected tableDef: TableDef = ZZZ_MATERIAL_BAG_TABLE;
}
