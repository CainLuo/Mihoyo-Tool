/**
 * ServerNameUtil — 服务器标识符 → 用户友好名称映射
 *
 * 米游社各游戏服务器 ID 与显示名称的对应关系。
 * 所有需要展示服务器名称的地方必须通过此工具转换，禁止直接显示原始 server 字段。
 */

/**
 * 将服务器原始标识符转换为用户友好的显示名称。
 * 未知标识符原样返回。
 */
export function serverDisplayName(server: string): string {
  // 原神
  if (server === 'cn_gf01') { return '天空岛' }
  if (server === 'cn_qd01') { return '世界树' }
  // 原神国际服
  if (server === 'os_usa') { return '美服' }
  if (server === 'os_euro') { return '欧服' }
  if (server === 'os_asia') { return '亚服' }
  if (server === 'os_cht') { return '港澳台服' }
  // 崩坏：星穹铁道
  if (server === 'prod_gf_cn') { return '天空岛' }
  if (server === 'prod_qd_cn') { return '世界树' }
  if (server === 'prod_official_usa') { return '美服' }
  if (server === 'prod_official_euro') { return '欧服' }
  if (server === 'prod_official_asia') { return '亚服' }
  if (server === 'prod_official_cht') { return '港澳台服' }
  // 绝区零
  if (server === 'prod_gf_jp') { return '日服' }
  if (server === 'prod_gf_us') { return '美服' }
  if (server === 'prod_gf_eu') { return '欧服' }
  if (server === 'prod_gf_sg') { return '亚服' }
  // 崩坏3（国服）
  if (server === 'android01') { return '官服' }
  if (server === 'ios01') { return '官服' }
  // 兜底：原样返回
  return server
}
