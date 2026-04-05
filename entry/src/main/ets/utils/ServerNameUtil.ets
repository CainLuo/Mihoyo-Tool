/**
 * ServerNameUtil — 服务器标识符 → 国际化资源映射
 *
 * 将米游社 API 返回的 region 字段转换为多语言显示名称（Resource）。
 * 所有需要展示服务器名称的地方必须通过此工具转换，禁止直接显示原始 server 字段。
 *
 * 注意：不同游戏可能共用相同的 server 标识符（如 prod_gf_cn），
 * 因此必须结合 gameId 才能正确映射。
 *
 * 重要说明：
 * 本文件所有 server 值均来自项目 mock 数据（binding_api_getUserGameRolesByCookie.json），
 * 100% 已验证，无推断值。未知 server 原样返回 null，由调用方决定兜底显示。
 *
 * 待扩展（需要真实账号数据验证后再添加）：
 * - 国服渠道服（region 含 'qd'）
 * - 国际服（region 含 'os' 或 'prod_official'）
 */
import { GenshinServer, StarRailServer, ZZZServer } from 'core';
import { GameId } from '../constants/GameId';

/**
 * 将服务器原始标识符转换为多语言显示名称。
 * 未知标识符返回 null，调用方可选择显示原始 server 字符串作为兜底。
 *
 * @param server  服务器标识符（来自 API region 字段）
 * @param gameId  游戏标识（GameId enum 值）
 */
export function serverDisplayName(server: string, gameId: string): Resource | null {
  if (gameId === GameId.GENSHIN) {
    if (server === GenshinServer.CN_OFFICIAL) {
      return $r('app.string.server_genshin_cn_official');
    }
    return null;
  }

  if (gameId === GameId.STARRAIL) {
    if (server === StarRailServer.CN_OFFICIAL) {
      return $r('app.string.server_starrail_cn_official');
    }
    return null;
  }

  if (gameId === GameId.ZZZ) {
    if (server === ZZZServer.CN_OFFICIAL) {
      return $r('app.string.server_zzz_cn_official');
    }
    return null;
  }

  return null;
}
