/**
 * ZZZMaterialBagDao — ZZZKit 材料背包 DAO
 */

import { BaseMaterialBagDao } from '../../common/material/db/MaterialBagDao';
import { TableName, TableDef, ZZZ_MATERIAL_BAG_TABLE } from '../../database/TableSchema';

/**
 * 绝区零材料背包 DAO
 */
export class ZZZMaterialBagDao extends BaseMaterialBagDao {
  protected tableName: TableName = TableName.ZZZ_MATERIAL_BAG;
  protected tableDef: TableDef = ZZZ_MATERIAL_BAG_TABLE;
}
