/**
 * StarRailMaterialBagDao — StarRailKit 材料背包 DAO
 */

import { BaseMaterialBagDao } from '../../common/material/db/MaterialBagDao';
import { TableName, TableDef, STARRAIL_MATERIAL_BAG_TABLE } from '../../database/TableSchema';

/**
 * 星穹铁道材料背包 DAO
 */
export class StarRailMaterialBagDao extends BaseMaterialBagDao {
  protected tableName: TableName = TableName.STARRAIL_MATERIAL_BAG;
  protected tableDef: TableDef = STARRAIL_MATERIAL_BAG_TABLE;
}
