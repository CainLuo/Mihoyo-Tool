/**
 * DialogDedup — 弹框 / Snackbar 全局去重
 *
 * 规则：同一个 key 的弹框正在显示时，再次触发直接忽略；弹框关闭后释放 key，下次可以再弹。
 * key 由调用方指定，或用 keyOf() 从提示文案推导：
 *   - 文案中含 retcode（如 "retcode=-3501: 二维码已过期"）→ 按错误码去重
 *   - 其他字符串 → 按文案去重
 *   - 资源引用（$r）→ 按资源 id 去重
 */
import { Logger } from 'core'

const TAG: string = 'DialogDedup'

export class DialogDedup {
  private static activeKeys: Set<string> = new Set<string>()

  /**
   * 尝试占用 key。
   * @returns true 表示可以弹出；false 表示同 key 的弹框正在显示，调用方应直接忽略本次
   */
  static tryAcquire(key: string): boolean {
    if (DialogDedup.activeKeys.has(key)) {
      Logger.info(TAG, `skip duplicate dialog, key=${key}`)
      return false
    }
    DialogDedup.activeKeys.add(key)
    return true
  }

  /** 弹框关闭后释放 key（可重复调用） */
  static release(key: string): void {
    DialogDedup.activeKeys.delete(key)
  }

  /** 从提示文案推导去重 key：优先错误码，其次文案 / 资源 id */
  static keyOf(text: ResourceStr): string {
    if (typeof text === 'string') {
      const m = text.match(/retcode[=:\s]*(-?\d+)/i)
      return m !== null ? `code:${m[1]}` : `msg:${text}`
    }
    return `res:${(text as Resource).id}`
  }
}
