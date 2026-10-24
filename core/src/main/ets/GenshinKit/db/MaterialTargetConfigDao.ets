/**
 * GenshinMaterialTargetConfigDao — GenshinKit 养成目标配置 DAO
 */

import { BaseMaterialTargetConfigDao } from '../../common/material/db/MaterialTargetConfigDao';
import { TableName } from '../../db/TableName';
import { TableDef } from '../../db/TableSchema';
import { GENSHIN_MATERIAL_TARGET_CONFIG_TABLE } from './schema';

/**
 * 原神养成目标配置 DAO
 */
export class GenshinMaterialTargetConfigDao extends BaseMaterialTargetConfigDao {
  protected tableName: TableName = TableName.GENSHIN_MATERIAL_TARGET_CONFIG;
  protected tableDef: TableDef = GENSHIN_MATERIAL_TARGET_CONFIG_TABLE;
}
