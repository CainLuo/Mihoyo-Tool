/**
 * GameIdUtil — 游戏 ID 工具函数
 *
 * 将 gameId 转换为多语言名称、主题色、logo，供各页面复用。
 * 每个映射只有一份实现，对外保留枚举版（getXxx）与字符串版（getXxxByStr）两个入口：
 * 后者给拿到 string 的调用方（小组件配置、DB 读回值）用，实现相同。
 */
import { GameId } from 'core'

/** gameId → 多语言名称（唯一实现，入参用枚举；字符串版在其上包一层） */
function nameOf(gameId: GameId): Resource {
  if (gameId === GameId.GENSHIN) { return $r('app.string.game_name_genshin') }
  if (gameId === GameId.STARRAIL) { return $r('app.string.game_name_starrail') }
  if (gameId === GameId.ZZZ) { return $r('app.string.game_name_zzz') }
  if (gameId === GameId.HONKAI3) { return $r('app.string.game_name_honkai3') }
  return $r('app.string.game_name_genshin')
}

/** gameId → 游戏主题色 */
function colorOf(gameId: GameId): ResourceColor {
  if (gameId === GameId.GENSHIN) { return $r('app.color.game_color_genshin') }
  if (gameId === GameId.STARRAIL) { return $r('app.color.game_color_starrail') }
  if (gameId === GameId.ZZZ) { return $r('app.color.game_color_zzz') }
  if (gameId === GameId.HONKAI3) { return $r('app.color.game_color_honkai3') }
  return $r('app.color.color_primary')
}

/** gameId → 游戏 logo 资源 */
function logoOf(gameId: GameId): Resource {
  if (gameId === GameId.GENSHIN)  { return $r('app.media.logo_genshin') }
  if (gameId === GameId.STARRAIL) { return $r('app.media.logo_starrail') }
  if (gameId === GameId.ZZZ)      { return $r('app.media.logo_zzz') }
  return $r('app.media.logo_honkai3')
}

// ── 枚举版本 ─────────────────────────────────────────────────────

export function getGameName(gameId: GameId): Resource {
  return nameOf(gameId)
}

export function getGameColor(gameId: GameId): ResourceColor {
  return colorOf(gameId)
}

export function getGameLogo(gameId: GameId): Resource {
  return logoOf(gameId)
}

// ── 字符串版本（用于 Widget 数据等场景）─────────────────────────────

/**
 * 将 gameId 字符串转换为多语言名称
 * @param gameId 游戏 ID 字符串（如 'genshin', 'starrail', 'zzz'）
 */
export function getGameNameByStr(gameId: string): Resource {
  return nameOf(gameId as GameId)
}

/**
 * 将 gameId 字符串转换为游戏主题色
 * @param gameId 游戏 ID 字符串（如 'genshin', 'starrail', 'zzz'）
 */
export function getGameColorByStr(gameId: string): ResourceColor {
  return colorOf(gameId as GameId)
}

/** 将 gameId 字符串映射为游戏 logo 资源 */
export function getGameLogoByStr(gameId: string): Resource {
  return logoOf(gameId as GameId)
}

/** 由米游社接口地址判断游戏（hkrpg → 星铁，zzz / nap_ → 绝区零），无法判断时按原神处理 */
export function parseGameIdFromApiUrl(url: string): GameId {
  if (url.indexOf('hkrpg') !== -1) { return GameId.STARRAIL }
  if (url.indexOf('zzz') !== -1 || url.indexOf('nap_') !== -1) { return GameId.ZZZ }
  return GameId.GENSHIN
}
