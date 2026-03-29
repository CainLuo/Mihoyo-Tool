/**
 * ServerNameUtil — 服务器标识符 → 用户友好名称映射
 *
 * 米游社各游戏服务器 ID 与显示名称的对应关系。
 * 所有需要展示服务器名称的地方必须通过此工具转换，禁止直接显示原始 server 字段。
 *
 * 注意：不同游戏可能共用相同的 server 标识符（如 prod_gf_cn），
 * 因此必须结合 gameId 才能正确映射。
 */

/**
 * 将服务器原始标识符转换为用户友好的显示名称。
 * 未知标识符原样返回。
 *
 * @param server  服务器标识符（来自 API region 字段）
 * @param gameId  游戏标识（'genshin' / 'starrail' / 'zzz' / 'honkai3'），默认空字符串
 */
export function serverDisplayName(server: string, gameId: string = ''): string {
  // ── 原神 ──────────────────────────────────────────────────────
  if (gameId === 'genshin' || gameId === '') {
    if (server === 'cn_gf01') { return '天空岛' }
    if (server === 'cn_qd01') { return '世界树' }
    if (server === 'os_usa') { return '美服' }
    if (server === 'os_euro') { return '欧服' }
    if (server === 'os_asia') { return '亚服' }
    if (server === 'os_cht') { return '港澳台服' }
    if (gameId === 'genshin') { return server }
  }

  // ── 崩坏：星穹铁道 ────────────────────────────────────────────
  if (gameId === 'starrail') {
    if (server === 'prod_gf_cn') { return '星穹列车' }
    if (server === 'prod_qd_cn') { return '星穹列车（渠道）' }
    if (server === 'prod_official_usa') { return '美服' }
    if (server === 'prod_official_euro') { return '欧服' }
    if (server === 'prod_official_asia') { return '亚服' }
    if (server === 'prod_official_cht') { return '港澳台服' }
    return server
  }

  // ── 绝区零 ────────────────────────────────────────────────────
  if (gameId === 'zzz') {
    if (server === 'prod_gf_cn') { return '新艾利都' }
    if (server === 'prod_qd_cn') { return '新艾利都（渠道）' }
    if (server === 'prod_gf_jp') { return '日服' }
    if (server === 'prod_gf_us') { return '美服' }
    if (server === 'prod_gf_eu') { return '欧服' }
    if (server === 'prod_gf_sg') { return '亚服' }
    return server
  }

  // ── 崩坏3 ─────────────────────────────────────────────────────
  if (gameId === 'honkai3') {
    if (server === 'android01') { return '官服' }
    if (server === 'ios01') { return '官服' }
    if (server === 'pc01') { return '全平台（桌面）服' }
    return server
  }

  // ── 兜底（gameId 为空时按 server 原样返回）────────────────────
  return server
}
