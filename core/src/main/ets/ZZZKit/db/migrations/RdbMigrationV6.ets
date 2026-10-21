/**
 * RdbMigrationV6 — 数据库版本 6 迁移逻辑
 *
 * 版本 5 → 6：
 * - 修正 zzz_material_target_config.config_json：skill_type 5 为核心技，最高 7 级，
 *   旧版本按 12 级保存会导致 avatar_calc 返回 -400005（提交的参数错误），将 current / target 截断到 7。
 *
 * 迁移在事务外执行，失败后下次启动会整体重跑；截断操作本身幂等。
 */

import { relationalStore } from '@kit.ArkData';
import { RdbManager } from '../../../database/RdbManager';
import { RsReader } from '../../../database/RsReader';
import { TableName, CommonCol, MaterialTargetConfigCol } from '../../../database/TableSchema';

/** 绝区零核心技 skill_type 与最高等级（与 entry ZZZSkillType 一致） */
const ZZZ_CORE_SKILL_TYPE: number = 5;
const ZZZ_CORE_SKILL_MAX: number = 7;

class ConfigJsonRow {
  id: number = 0;
  configJson: string = '';
}

export class RdbMigrationV6 {
  /**
   * 执行 V5 → V6 迁移
   */
  public static async run(): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ZZZ_MATERIAL_TARGET_CONFIG);
    const rows = await RdbManager.queryAll(predicates, [CommonCol.ID, MaterialTargetConfigCol.CONFIG_JSON],
      (rs: relationalStore.ResultSet) => {
        const r = new RsReader(rs);
        const row = new ConfigJsonRow();
        row.id = r.num(CommonCol.ID);
        row.configJson = r.str(MaterialTargetConfigCol.CONFIG_JSON);
        return row;
      });

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      if (row.configJson.length === 0) {
        continue;
      }
      let obj: Record<string, Object>;
      try {
        obj = JSON.parse(row.configJson) as Record<string, Object>;
      } catch (_) {
        continue;
      }
      const skills = obj['skills'] as Record<string, Object>[] | undefined;
      if (!Array.isArray(skills)) {
        continue;
      }
      let changed = false;
      for (let j = 0; j < skills.length; j++) {
        if (skills[j]['skillType'] !== ZZZ_CORE_SKILL_TYPE) {
          continue;
        }
        const current = typeof skills[j]['current'] === 'number' ? skills[j]['current'] as number : 1;
        const target = typeof skills[j]['target'] === 'number' ? skills[j]['target'] as number : 1;
        if (current > ZZZ_CORE_SKILL_MAX || target > ZZZ_CORE_SKILL_MAX) {
          skills[j]['current'] = Math.min(current, ZZZ_CORE_SKILL_MAX);
          skills[j]['target'] = Math.min(target, ZZZ_CORE_SKILL_MAX);
          changed = true;
        }
      }
      if (changed) {
        await RdbManager.updateRows(TableName.ZZZ_MATERIAL_TARGET_CONFIG, [MaterialTargetConfigCol.CONFIG_JSON],
          [JSON.stringify(obj)], [CommonCol.ID], [row.id]);
      }
    }
  }
}
