/**
 * ZZZMaterialTargetConfigDao — ZZZKit 养成目标配置 DAO
 */

import { BaseMaterialTargetConfigDao } from '../../common/material/db/MaterialTargetConfigDao';
import { TableName, TableDef, ZZZ_MATERIAL_TARGET_CONFIG_TABLE } from '../../database/TableSchema';

/**
 * 绝区零养成目标配置 DAO
 */
export class ZZZMaterialTargetConfigDao extends BaseMaterialTargetConfigDao {
  protected tableName: TableName = TableName.ZZZ_MATERIAL_TARGET_CONFIG;
  protected tableDef: TableDef = ZZZ_MATERIAL_TARGET_CONFIG_TABLE;
}
