/**
 * RsReader — ResultSet 字段读取工具
 *
 * 封装 ResultSet.getValue + getColumnIndex 的类型守卫逻辑，
 * 消除 DAO mapRow 方法中大量重复的 typeof 判断。
 *
 * 用法：
 *   const r = new RsReader(rs);
 *   row.id      = r.num(CommonCol.ID);
 *   row.name    = r.str(StarRailAvatarBasicCol.NAME);
 *   row.awaken  = r.strAsInt(ZZZAvatarBasicCol.AWAKEN_STATE);
 */
import { relationalStore } from '@kit.ArkData';

export class RsReader {
  private rs: relationalStore.ResultSet;

  constructor(rs: relationalStore.ResultSet) {
    this.rs = rs;
  }

  /**
   * 读取 INTEGER 列，类型不匹配时返回 fallback（默认 0）。
   * @param col      列名（使用 XxxCol enum 值，禁止直接写字符串）
   * @param fallback 类型不匹配时的默认值，默认为 0
   */
  num(col: string, fallback: number = 0): number {
    const v = this.rs.getValue(this.rs.getColumnIndex(col));
    return typeof v === 'number' ? v : fallback;
  }

  /**
   * 读取 TEXT 列，类型不匹配时返回 fallback（默认 ''）。
   * @param col      列名（使用 XxxCol enum 值，禁止直接写字符串）
   * @param fallback 类型不匹配时的默认值，默认为空字符串
   */
  str(col: string, fallback: string = ''): string {
    const v = this.rs.getValue(this.rs.getColumnIndex(col));
    return typeof v === 'string' ? v : fallback;
  }

  /**
   * 读取以 TEXT 存储的整数列（如 ZZZ awakenState），
   * 先读字符串再 parseInt，解析失败时返回 fallback（默认 0）。
   * @param col      列名（使用 XxxCol enum 值，禁止直接写字符串）
   * @param fallback 解析失败时的默认值，默认为 0
   */
  strAsInt(col: string, fallback: number = 0): number {
    const v = this.rs.getValue(this.rs.getColumnIndex(col));
    if (typeof v !== 'string') {
      return fallback;
    }
    const parsed = parseInt(v);
    return isNaN(parsed) ? fallback : parsed;
  }
}
