/**
 * GameIdUtil — 游戏 ID 工具函数
 *
 * 将 gameId 转换为多语言名称、主题色等，供各页面复用。
 */
import { GameId } from '../constants/GameId'

export function gameIdToName(gameId: string): Resource {
  if (gameId === GameId.GENSHIN) { return $r('app.string.game_name_genshin') }
  if (gameId === GameId.STARRAIL) { return $r('app.string.game_name_starrail') }
  if (gameId === GameId.ZZZ) { return $r('app.string.game_name_zzz') }
  if (gameId === GameId.HONKAI3) { return $r('app.string.game_name_honkai3') }
  return $r('app.string.game_name_genshin')
}

export function gameIdToColor(gameId: string): ResourceColor {
  if (gameId === GameId.GENSHIN) { return $r('app.color.game_color_genshin') }
  if (gameId === GameId.STARRAIL) { return $r('app.color.game_color_starrail') }
  if (gameId === GameId.ZZZ) { return $r('app.color.game_color_zzz') }
  if (gameId === GameId.HONKAI3) { return $r('app.color.game_color_honkai3') }
  return $r('app.color.color_primary')
}

/** 将 gameId 映射为主要资源标签（树脂/开拓力等） */
export function gameIdToPrimaryLabel(gameId: string): Resource {
  if (gameId === GameId.GENSHIN) { return $r('app.string.daily_note_resin_title') }
  return $r('app.string.daily_note_adventure_label')
}
