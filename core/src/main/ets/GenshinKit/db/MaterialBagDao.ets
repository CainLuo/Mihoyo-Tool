/**
 * GenshinMaterialBagDao — GenshinKit 材料背包 DAO
 */

import { BaseMaterialBagDao } from '../../common/material/db/MaterialBagDao';
import { TableName, TableDef, GENSHIN_MATERIAL_BAG_TABLE } from '../../database/TableSchema';

/**
 * 原神材料背包 DAO
 */
export class GenshinMaterialBagDao extends BaseMaterialBagDao {
  protected tableName: TableName = TableName.GENSHIN_MATERIAL_BAG;
  protected tableDef: TableDef = GENSHIN_MATERIAL_BAG_TABLE;
}
