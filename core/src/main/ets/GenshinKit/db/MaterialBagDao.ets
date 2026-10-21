/**
 * GenshinMaterialBagDao — GenshinKit 材料背包 DAO
 */

import { BaseMaterialBagDao } from '../../common/material/db/MaterialBagDao';
import { TableName } from '../../db/TableName';
import { TableDef } from '../../db/TableSchema';
import { GENSHIN_MATERIAL_BAG_TABLE } from './schema';

/**
 * 原神材料背包 DAO
 */
export class GenshinMaterialBagDao extends BaseMaterialBagDao {
  protected tableName: TableName = TableName.GENSHIN_MATERIAL_BAG;
  protected tableDef: TableDef = GENSHIN_MATERIAL_BAG_TABLE;
}
