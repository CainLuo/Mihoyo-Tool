/**
 * MaterialRoutes.ets — 材料计算相关页面的路由名（按游戏）
 */

import { GameId } from 'core'
import { AppRoutes } from '../constants/AppRoutes'

/** 各游戏的材料汇总页路由 */
export function materialListRoute(gameId: GameId): string {
  if (gameId === GameId.STARRAIL) {
    return AppRoutes.STARRAIL_MATERIAL_LIST
  } else if (gameId === GameId.ZZZ) {
    return AppRoutes.ZZZ_MATERIAL_LIST
  }
  return AppRoutes.GENSHIN_MATERIAL_LIST
}

/** 各游戏的养成目标配置页路由 */
export function materialTargetConfigRoute(gameId: GameId): string {
  if (gameId === GameId.STARRAIL) {
    return AppRoutes.STARRAIL_MATERIAL_TARGET_CONFIG
  } else if (gameId === GameId.ZZZ) {
    return AppRoutes.ZZZ_MATERIAL_TARGET_CONFIG
  }
  return AppRoutes.GENSHIN_MATERIAL_TARGET_CONFIG
}
