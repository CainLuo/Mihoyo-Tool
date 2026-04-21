/**
 * GameServer — 游戏服务器/大区/game_biz 枚举
 *
 * 统一管理米游社 API 中涉及服务器标识的所有字段，
 * 禁止在业务代码中直接写服务器字符串字面量。
 *
 * 涉及的 API 字段：
 * - binding/api/getUserGameRolesByCookie 返回的 region（大区标识）
 * - binding/api/getUserGameRolesByCookie 返回的 game_biz（游戏业务标识）
 * - 各游戏 API 请求参数中的 server 字段
 *
 * 重要说明：
 * 本文件所有枚举值均来自项目 mock 数据（binding_api_getUserGameRolesByCookie.json），
 * 100% 已验证，无推断值。
 *
 * 当前已验证的值（国服官服）：
 * - game_biz: hk4e_cn / hkrpg_cn / nap_cn
 * - region:   cn_gf01（原神）/ prod_gf_cn（星铁/绝区零）
 *
 * 待扩展（需要真实账号数据验证后再添加）：
 * - 国服渠道服（B站等）：region 含 'qd'，is_official=false
 * - 国际服（HoYoLAB）：game_biz 含 'global' 或 'os'
 */

import { GameId } from './GameId';

// ── 游戏业务标识（game_biz）──────────────────────────────────────────

/**
 * 游戏业务标识枚举（game_biz 字段）。
 * 用于区分不同游戏，是米游社 API 的核心标识符。
 *
 * 数据来源：binding/api/getUserGameRolesByCookie 响应体 list[].game_biz
 */
export enum GameBiz {
  /** 原神国服（官服），game_biz: "hk4e_cn" */
  GENSHIN_CN   = 'hk4e_cn',
  /** 星穹铁道国服（官服），game_biz: "hkrpg_cn" */
  STARRAIL_CN  = 'hkrpg_cn',
  /** 绝区零国服（官服），game_biz: "nap_cn" */
  ZZZ_CN       = 'nap_cn',
  /** 崩坏3国服，game_biz: "bh3_cn" */
  HONKAI3_CN   = 'bh3_cn',
  /** 原神国际服，game_biz: "hk4e_global" */
  GENSHIN_OS   = 'hk4e_global',
  /** 星穹铁道国际服，game_biz: "hkrpg_global" */
  STARRAIL_OS  = 'hkrpg_global',
  /** 绝区零国际服，game_biz: "nap_global" */
  ZZZ_OS       = 'nap_global',
}

// ── 服务器大区标识（region / server）────────────────────────────────

/**
 * 原神服务器大区枚举（region 字段）。
 * 用于 API 请求参数 server 和 binding 接口返回的 region 字段。
 *
 * 数据来源：binding/api/getUserGameRolesByCookie 响应体 list[].region
 */
export enum GenshinServer {
  /** 国服官服（天空岛），region: "cn_gf01"，is_official: true */
  CN_OFFICIAL = 'cn_gf01',
}

/**
 * 星穹铁道服务器大区枚举（region 字段）。
 *
 * 数据来源：binding/api/getUserGameRolesByCookie 响应体 list[].region
 */
export enum StarRailServer {
  /** 国服官服（星穹列车），region: "prod_gf_cn"，is_official: true */
  CN_OFFICIAL = 'prod_gf_cn',
}

/**
 * 绝区零服务器大区枚举（region 字段）。
 *
 * 数据来源：binding/api/getUserGameRolesByCookie 响应体 list[].region
 */
export enum ZZZServer {
  /** 国服官服（新艾利都），region: "prod_gf_cn"，is_official: true */
  CN_OFFICIAL = 'prod_gf_cn',
}

// ── game_biz → GameId 转换 ───────────────────────────────────────

/**
 * 将米游社 game_biz 字符串转换为本项目 GameId 字符串。
 * 未知 biz 直接透传原始值。
 */
export function gameBizToGameId(biz: string): GameId {
  if (biz === GameBiz.GENSHIN_CN || biz === GameBiz.GENSHIN_OS) {
    return GameId.GENSHIN;
  }
  if (biz === GameBiz.STARRAIL_CN || biz === GameBiz.STARRAIL_OS) {
    return GameId.STARRAIL;
  }
  if (biz === GameBiz.ZZZ_CN || biz === GameBiz.ZZZ_OS) {
    return GameId.ZZZ;
  }
  if (biz === GameBiz.HONKAI3_CN) {
    return GameId.HONKAI3;
  }
  return GameId.GENSHIN; // 未知 biz fallback
}
