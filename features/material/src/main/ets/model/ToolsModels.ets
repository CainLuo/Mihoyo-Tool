/**
 * ToolsModels.ets — 工具页 UI State 模型
 *
 * 工具页只展示三张游戏入口卡片，本文件仅保留入口卡片自己的数据结构。
 * 材料养成目标领域模型（技能槽位 / 计算目标 / 路由参数）已迁至
 * MaterialTargetModels.ets；此处 re-export 保持既有 import 路径与导出符号不变。
 */

import { GameId } from 'core';

export {
  ZZZSkillType,
  ZZZSkillTarget,
  GenshinTalentSlot,
  StarRailSkillSlot,
  MaterialComputeTargets,
  MaterialTargetConfigParam,
} from './MaterialTargetModels';

/**
 * 游戏入口 UI State
 *
 * 每次 loadData() 都会整体重建并替换 gameEntries，不存在字段原地修改，
 * 因此不需要 @ObservedV2 / @Trace（数组赋值由 ToolsViewModel.gameEntries 的 @Trace 通知）。
 */
export class GameEntryVM {
  /** 账号 UID（米游社 UID） */
  accountId: string = '';
  /** 游戏角色 UID（第一个角色的 UID，用于跳转配置页） */
  roleUid: string = '';
  /** 游戏标识 */
  gameId: GameId = GameId.GENSHIN;
  /** 游戏名称 */
  gameName: ResourceStr = '';
  /** 游戏图标 */
  gameIcon: Resource = $r('app.media.logo_genshin');
  /** 角色数量 */
  characterCount: number = 0;
  /** 已计算角色数量 */
  computedCount: number = 0;
  /** 是否有数据 */
  hasData: boolean = false;
}
