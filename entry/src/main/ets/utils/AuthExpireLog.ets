/**
 * AuthExpireLog — 登录过期排查日志（entry 侧），与 core/utils/CookieDebug 输出格式一致
 * 过滤：hilog | grep 🚀🚀🚀
 */

/** 登录过期排查日志 tag */
export const AUTH_EXPIRE_TAG: string = '🚀🚀🚀 AuthExpire'

const ID_KEYS: string[] = ['account_id', 'ltuid', 'stuid', 'mid', 'account_id_v2', 'ltuid_v2', 'account_mid_v2', 'ltmid_v2']
const TOKEN_KEYS: string[] = ['cookie_token', 'ltoken', 'stoken', 'cookie_token_v2', 'ltoken_v2']

/** Cookie 摘要：字段名、ID 值、各 token 长度与前 6 位（不输出完整 token） */
export function summarizeCookie(cookie: string): string {
  if (cookie.length === 0) {
    return 'cookie=<empty>'
  }
  const fields = new Map<string, string>()
  const parts = cookie.split(';')
  for (let i = 0; i < parts.length; i++) {
    const p = parts[i].trim()
    const eq = p.indexOf('=')
    if (eq > 0) {
      fields.set(p.substring(0, eq).trim(), p.substring(eq + 1).trim())
    }
  }
  const keys: string[] = []
  fields.forEach((_v: string, k: string) => {
    keys.push(k)
  })
  const out: string[] = [`keys=[${keys.join(',')}]`]
  for (let i = 0; i < ID_KEYS.length; i++) {
    const v = fields.get(ID_KEYS[i])
    if (v !== undefined) {
      out.push(`${ID_KEYS[i]}=${v}`)
    }
  }
  for (let i = 0; i < TOKEN_KEYS.length; i++) {
    const v = fields.get(TOKEN_KEYS[i])
    out.push(v === undefined ? `${TOKEN_KEYS[i]}=<none>` : `${TOKEN_KEYS[i]}(len=${v.length}, ${v.substring(0, 6)}…)`)
  }
  return out.join(', ')
}
