/**
 * CookieDebug — 登录过期排查用的 Cookie 摘要（不输出完整 token）
 *
 * 输出：字段名列表、account_id / ltuid / stuid / mid 的值、各 token 的长度与前 6 位。
 * 过滤：hilog | grep 🚀🚀🚀
 */

/** 登录过期排查日志 tag */
export const AUTH_EXPIRE_TAG: string = '🚀🚀🚀 AuthExpire';

const ID_KEYS: string[] = ['account_id', 'ltuid', 'stuid', 'mid', 'account_id_v2', 'ltuid_v2', 'account_mid_v2', 'ltmid_v2'];
const TOKEN_KEYS: string[] = ['cookie_token', 'ltoken', 'stoken', 'cookie_token_v2', 'ltoken_v2'];

export class CookieDebug {
  /** Cookie 摘要，例如 keys=[...], account_id=123, stoken(len=88, v2_abc…) */
  static summarize(cookie: string | undefined): string {
    if (cookie === undefined || cookie.length === 0) {
      return 'cookie=<empty>';
    }
    const fields = new Map<string, string>();
    const parts = cookie.split(';');
    for (let i = 0; i < parts.length; i++) {
      const p = parts[i].trim();
      const eq = p.indexOf('=');
      if (eq > 0) {
        fields.set(p.substring(0, eq).trim(), p.substring(eq + 1).trim());
      }
    }
    const out: string[] = [];
    const keys: string[] = [];
    fields.forEach((_v: string, k: string) => {
      keys.push(k);
    });
    out.push(`keys=[${keys.join(',')}]`);
    for (let i = 0; i < ID_KEYS.length; i++) {
      const v = fields.get(ID_KEYS[i]);
      if (v !== undefined) {
        out.push(`${ID_KEYS[i]}=${v}`);
      }
    }
    for (let i = 0; i < TOKEN_KEYS.length; i++) {
      const v = fields.get(TOKEN_KEYS[i]);
      out.push(v === undefined ? `${TOKEN_KEYS[i]}=<none>` : `${TOKEN_KEYS[i]}(len=${v.length}, ${v.substring(0, 6)}…)`);
    }
    return out.join(', ');
  }

  /** 从请求头中取 Cookie（大小写不敏感） */
  static cookieFromHeaders(headers: Record<string, string>): string {
    const keys = Object.keys(headers);
    for (let i = 0; i < keys.length; i++) {
      if (keys[i].toLowerCase() === 'cookie') {
        return headers[keys[i]];
      }
    }
    return '';
  }

  /** 是否为登录过期类返回码（-100 / 10001） */
  static isAuthExpiredCode(retcode: number | undefined): boolean {
    return retcode === -100 || retcode === 10001;
  }

  /** 是否为"请求无效"（-10001 invalid request：DS / 请求头 / 参数不对） */
  static isInvalidRequestCode(retcode: number | undefined): boolean {
    return retcode === -10001;
  }

  /** 请求头摘要：除 Cookie 外全部输出（Cookie 只输出摘要） */
  static summarizeHeaders(headers: Record<string, string>): string {
    const out: string[] = [];
    const keys = Object.keys(headers);
    for (let i = 0; i < keys.length; i++) {
      if (keys[i].toLowerCase() === 'cookie') {
        continue;
      }
      out.push(`${keys[i]}=${headers[keys[i]]}`);
    }
    return out.join(' | ');
  }
}
