/**
 * StarRailMaterialTargetConfigDao — StarRailKit 养成目标配置 DAO
 */

import { BaseMaterialTargetConfigDao } from '../../common/material/db/MaterialTargetConfigDao';
import { TableName, TableDef, STARRAIL_MATERIAL_TARGET_CONFIG_TABLE } from '../../database/TableSchema';

/**
 * 星穹铁道养成目标配置 DAO
 */
export class StarRailMaterialTargetConfigDao extends BaseMaterialTargetConfigDao {
  protected tableName: TableName = TableName.STARRAIL_MATERIAL_TARGET_CONFIG;
  protected tableDef: TableDef = STARRAIL_MATERIAL_TARGET_CONFIG_TABLE;
}
