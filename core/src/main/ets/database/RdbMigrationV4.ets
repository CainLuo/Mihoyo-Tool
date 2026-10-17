/**
 * RdbMigrationV4 — 数据库版本 4 迁移逻辑
 *
 * 版本 3 → 4（原神养成计算改造）：
 * 1. 重建 genshin_character_compute，列名与 batch_compute API 字段对齐：
 *    skill_consume_json → avatar_skill_consume_json，新增 skills_consume_json / overall_consume_json。
 *    旧数据不迁移：旧版本写入的 avatar_id 为空、lack_num 字段名错误，无法正确读取；
 *    养成计算结果属于可重新计算的缓存，用户重新计算即可。同时清除对应的 sync_meta 记录。
 * 2. 新建 genshin_calc_avatar（计算器 sync/avatar/list 角色数据，字段与 API 一致）。
 * 3. 养成目标配置 config_json：原神 / 星铁 的统一 "skill" 拆分为按技能区分的 "skills"。
 *
 * 迁移在事务外逐条执行，失败后下次启动会整体重跑，因此每一步都必须可重复执行（幂等）。
 */

import { relationalStore } from '@kit.ArkData';
import { RdbManager } from './RdbManager';
import { RsReader } from './RsReader';
import {
  TableName,
  CommonCol,
  MaterialTargetConfigCol,
  GENSHIN_CHARACTER_COMPUTE_TABLE,
  GENSHIN_CALC_AVATAR_TABLE,
  ALL_INDEXES,
} from './TableSchema';

/** config_json 迁移用的行 */
class ConfigJsonRow {
  id: number = 0;
  configJson: string = '';
}

/** 新的按技能配置项（与 SkillLevelConfig 字段一致） */
class SkillConfigItem {
  skillType: number = 0;
  current: number = 1;
  target: number = 1;
}

export class RdbMigrationV4 {
  /**
   * 执行 V3 → V4 迁移
   */
  public static async run(): Promise<void> {
    // 1. 重建 genshin_character_compute（DROP + CREATE 本身幂等）
    await RdbManager.executeSql(`DROP TABLE IF EXISTS ${TableName.GENSHIN_CHARACTER_COMPUTE}`, []);
    await RdbManager.executeSql(GENSHIN_CHARACTER_COMPUTE_TABLE.buildCreateSql(), []);
    await RdbManager.executeSql(
      `DELETE FROM ${TableName.SYNC_META} WHERE ${CommonCol.DATA_TYPE} = ?`,
      [TableName.GENSHIN_CHARACTER_COMPUTE]
    );

    // 2. 新建 genshin_calc_avatar（IF NOT EXISTS 幂等）
    await RdbManager.executeSql(GENSHIN_CALC_AVATAR_TABLE.buildCreateSql(), []);

    // 1 / 2 涉及的索引（IF NOT EXISTS 幂等）
    for (let i = 0; i < ALL_INDEXES.length; i++) {
      const index = ALL_INDEXES[i];
      if (index.tableName === TableName.GENSHIN_CHARACTER_COMPUTE || index.tableName === TableName.GENSHIN_CALC_AVATAR) {
        await RdbManager.executeSql(index.buildCreateSql(), []);
      }
    }

    // 3. config_json：skill → skills（已有 skills 的行跳过，幂等）
    // 原神：skillType 0 普通攻击 / 1 元素战技 / 2 元素爆发，上限 10
    await RdbMigrationV4.splitSkillConfig(TableName.GENSHIN_MATERIAL_TARGET_CONFIG, [0, 1, 2], [10, 10, 10]);
    // 星铁：skillType 1 普攻 / 2 战技 / 3 终结技 / 4 天赋，普攻上限 6，其余 10
    await RdbMigrationV4.splitSkillConfig(TableName.STARRAIL_MATERIAL_TARGET_CONFIG, [1, 2, 3, 4], [6, 10, 10, 10]);
  }

  /**
   * 把旧的统一 "skill": { current, target } 拆成 "skills": [{ skillType, current, target }]，并删除 "skill"。
   * 解析失败的行保持原样（读取时会回落到默认配置）。
   */
  private static async splitSkillConfig(table: TableName, skillTypes: number[], maxLevels: number[]): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(table);
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
      if (obj['skills'] !== undefined || obj['skill'] === undefined) {
        continue;
      }
      const old = obj['skill'] as Record<string, Object>;
      const current = typeof old['current'] === 'number' ? old['current'] as number : 1;
      const target = typeof old['target'] === 'number' ? old['target'] as number : 1;
      const skills: SkillConfigItem[] = [];
      for (let j = 0; j < skillTypes.length; j++) {
        const item = new SkillConfigItem();
        item.skillType = skillTypes[j];
        item.current = Math.min(current, maxLevels[j]);
        item.target = Math.min(target, maxLevels[j]);
        skills[skills.length] = item;
      }
      // 复制其余字段（avatar / weapon / lightCone），去掉旧的 skill（ArkTS 不支持 delete）
      const migrated: Record<string, Object> = {};
      const keys = Object.keys(obj);
      for (let k = 0; k < keys.length; k++) {
        if (keys[k] !== 'skill') {
          migrated[keys[k]] = obj[keys[k]];
        }
      }
      migrated['skills'] = skills;
      await RdbManager.updateRows(table, [MaterialTargetConfigCol.CONFIG_JSON], [JSON.stringify(migrated)],
        [CommonCol.ID], [row.id]);
    }
  }
}
