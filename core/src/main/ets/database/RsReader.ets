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
   * 读取 INTEGER 列，类型不匹配或异常时返回 fallback（默认 0）。
   */
  num(col: string, fallback: number = 0): number {
    try {
      const v = this.rs.getValue(this.rs.getColumnIndex(col));
      return typeof v === 'number' ? v : fallback;
    } catch (_) {
      return fallback;
    }
  }

  /**
   * 读取 TEXT 列，类型不匹配或异常时返回 fallback（默认 ''）。
   */
  str(col: string, fallback: string = ''): string {
    try {
      const v = this.rs.getValue(this.rs.getColumnIndex(col));
      return typeof v === 'string' ? v : fallback;
    } catch (_) {
      return fallback;
    }
  }

  /**
   * 读取以 TEXT 存储的整数列（如 ZZZ awakenState），
   * 先读字符串再 parseInt，解析失败或异常时返回 fallback（默认 0）。
   */
  strAsInt(col: string, fallback: number = 0): number {
    try {
      const v = this.rs.getValue(this.rs.getColumnIndex(col));
      if (typeof v !== 'string') {
        return fallback;
      }
      const parsed = parseInt(v);
      return isNaN(parsed) ? fallback : parsed;
    } catch (_) {
      return fallback;
    }
  }
}
