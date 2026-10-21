/**
 * ZZZMaterialBagDao — ZZZKit 材料背包 DAO
 */

import { BaseMaterialBagDao } from '../../common/material/db/MaterialBagDao';
import { TableName } from '../../db/TableName';
import { TableDef } from '../../db/TableSchema';
import { ZZZ_MATERIAL_BAG_TABLE } from './schema';

/**
 * 绝区零材料背包 DAO
 */
export class ZZZMaterialBagDao extends BaseMaterialBagDao {
  protected tableName: TableName = TableName.ZZZ_MATERIAL_BAG;
  protected tableDef: TableDef = ZZZ_MATERIAL_BAG_TABLE;
}
