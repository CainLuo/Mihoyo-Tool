/**
 * GameIdUtil — 游戏 ID 工具函数
 *
 * 将 gameId 转换为多语言名称、主题色等，供各页面复用。
 * 
 * 提供两套函数：
 * - gameIdToXxx(gameId: GameId): 接受 GameId 枚举
 * - gameIdStrToXxx(gameId: string): 接受字符串（用于 Widget 数据等场景）
 */
import { GameId } from 'core'

// ── 枚举版本 ─────────────────────────────────────────────────────

export function gameIdToName(gameId: GameId): Resource {
  if (gameId === GameId.GENSHIN) { return $r('app.string.game_name_genshin') }
  if (gameId === GameId.STARRAIL) { return $r('app.string.game_name_starrail') }
  if (gameId === GameId.ZZZ) { return $r('app.string.game_name_zzz') }
  if (gameId === GameId.HONKAI3) { return $r('app.string.game_name_honkai3') }
  return $r('app.string.game_name_genshin')
}

export function gameIdToColor(gameId: GameId): ResourceColor {
  if (gameId === GameId.GENSHIN) { return $r('app.color.game_color_genshin') }
  if (gameId === GameId.STARRAIL) { return $r('app.color.game_color_starrail') }
  if (gameId === GameId.ZZZ) { return $r('app.color.game_color_zzz') }
  if (gameId === GameId.HONKAI3) { return $r('app.color.game_color_honkai3') }
  return $r('app.color.color_primary')
}

/** 将 gameId 映射为游戏 logo 资源 */
export function gameIdToLogo(gameId: GameId): Resource {
  if (gameId === GameId.GENSHIN)  { return $r('app.media.logo_genshin') }
  if (gameId === GameId.STARRAIL) { return $r('app.media.logo_starrail') }
  if (gameId === GameId.ZZZ)      { return $r('app.media.logo_zzz') }
  return $r('app.media.logo_honkai3')
}

/** 将 gameId 映射为主要资源标签（树脂/开拓力等） */
export function gameIdToPrimaryLabel(gameId: GameId): Resource {
  if (gameId === GameId.GENSHIN) { return $r('app.string.daily_note_resin_title') }
  return $r('app.string.daily_note_adventure_label')
}

// ── 字符串版本（用于 Widget 数据等场景）─────────────────────────────

/**
 * 将 gameId 字符串转换为多语言名称
 * @param gameId 游戏 ID 字符串（如 'genshin', 'starrail', 'zzz'）
 */
export function gameIdStrToName(gameId: string): Resource {
  if (gameId === GameId.GENSHIN) { return $r('app.string.game_name_genshin') }
  if (gameId === GameId.STARRAIL) { return $r('app.string.game_name_starrail') }
  if (gameId === GameId.ZZZ) { return $r('app.string.game_name_zzz') }
  if (gameId === GameId.HONKAI3) { return $r('app.string.game_name_honkai3') }
  return $r('app.string.game_name_genshin')
}

/**
 * 将 gameId 字符串转换为游戏主题色
 * @param gameId 游戏 ID 字符串（如 'genshin', 'starrail', 'zzz'）
 */
export function gameIdStrToColor(gameId: string): ResourceColor {
  if (gameId === GameId.GENSHIN) { return $r('app.color.game_color_genshin') }
  if (gameId === GameId.STARRAIL) { return $r('app.color.game_color_starrail') }
  if (gameId === GameId.ZZZ) { return $r('app.color.game_color_zzz') }
  if (gameId === GameId.HONKAI3) { return $r('app.color.game_color_honkai3') }
  return $r('app.color.color_primary')
}

/** 将 gameId 字符串映射为游戏 logo 资源 */
export function gameIdStrToLogo(gameId: string): Resource {
  if (gameId === GameId.GENSHIN)  { return $r('app.media.logo_genshin') }
  if (gameId === GameId.STARRAIL) { return $r('app.media.logo_starrail') }
  if (gameId === GameId.ZZZ)      { return $r('app.media.logo_zzz') }
  return $r('app.media.logo_honkai3')
}
