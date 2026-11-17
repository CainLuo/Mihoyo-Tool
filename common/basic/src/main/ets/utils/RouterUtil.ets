/**
 * RouterUtil — 全局路由工具
 *
 * Index.ets 在 Navigation 创建后调用 RouterUtil.init(stack) 注入根栈。
 * 根栈只承载 LaunchPage / MainPage / PrivacyConsent；MainPage 内的二级页面走 MainPage 自己的 stack（detailStack），
 * 不要用 RouterUtil 跳二级页面。
 */
import { Logger } from 'core'

const TAG: string = 'RouterUtil'

export class RouterUtil {
  private static stack: NavPathStack | null = null

  /** 由 Index.ets 在 Navigation 创建后调用一次 */
  static init(stack: NavPathStack): void {
    RouterUtil.stack = stack
  }

  /** 根栈是否已注入 */
  static isReady(): boolean {
    return RouterUtil.stack !== null
  }

  /** push 新页面，可携带参数 */
  static push(name: string, param: Object | null = null): void {
    if (RouterUtil.stack === null) {
      Logger.error(TAG, `push(${name}) ignored: stack not initialized`)
      return
    }
    RouterUtil.stack.pushPathByName(name, param)
  }

  /** replace 当前页面（不保留返回栈） */
  static replace(name: string, param: Object | null = null): void {
    if (RouterUtil.stack === null) {
      Logger.error(TAG, `replace(${name}) ignored: stack not initialized`)
      return
    }
    RouterUtil.stack.replacePath({ name: name, param: param })
  }

  /** 返回上一页 */
  static pop(): void {
    if (RouterUtil.stack === null) {
      Logger.error(TAG, 'pop() ignored: stack not initialized')
      return
    }
    RouterUtil.stack.pop()
  }
}
