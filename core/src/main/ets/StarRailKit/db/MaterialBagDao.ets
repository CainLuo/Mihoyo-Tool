/**
 * StarRailMaterialBagDao — StarRailKit 材料背包 DAO
 */

import { BaseMaterialBagDao } from '../../common/material/db/MaterialBagDao';
import { TableName } from '../../db/TableName';
import { TableDef } from '../../db/TableSchema';
import { STARRAIL_MATERIAL_BAG_TABLE } from './schema';

/**
 * 星穹铁道材料背包 DAO
 */
export class StarRailMaterialBagDao extends BaseMaterialBagDao {
  protected tableName: TableName = TableName.STARRAIL_MATERIAL_BAG;
  protected tableDef: TableDef = STARRAIL_MATERIAL_BAG_TABLE;
}
