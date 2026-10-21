/**
 * ZZZMaterialTargetConfigDao — ZZZKit 养成目标配置 DAO
 */

import { BaseMaterialTargetConfigDao } from '../../common/material/db/MaterialTargetConfigDao';
import { TableName } from '../../db/TableName';
import { TableDef } from '../../db/TableSchema';
import { ZZZ_MATERIAL_TARGET_CONFIG_TABLE } from './schema';

/**
 * 绝区零养成目标配置 DAO
 */
export class ZZZMaterialTargetConfigDao extends BaseMaterialTargetConfigDao {
  protected tableName: TableName = TableName.ZZZ_MATERIAL_TARGET_CONFIG;
  protected tableDef: TableDef = ZZZ_MATERIAL_TARGET_CONFIG_TABLE;
}
