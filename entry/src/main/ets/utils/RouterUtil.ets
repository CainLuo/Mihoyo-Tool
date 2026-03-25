/**
 * RouterUtil — 全局路由工具
 *
 * Index.ets 在 Navigation 创建后调用 RouterUtil.init(stack) 注入栈，
 * 各页面通过静态方法跳转，无需直接持有 pathStack 引用。
 */

export class RouterUtil {
  private static stack: NavPathStack | null = null

  /** 由 Index.ets 在 Navigation 创建后调用一次 */
  static init(stack: NavPathStack): void {
    RouterUtil.stack = stack
  }

  /** push 新页面，可携带参数 */
  static push(name: string, param: Object | null = null): void {
    RouterUtil.stack?.pushPathByName(name, param)
  }

  /** replace 当前页面（不保留返回栈） */
  static replace(name: string, param: Object | null = null): void {
    RouterUtil.stack?.replacePath({ name: name, param: param })
  }

  /** 返回上一页 */
  static pop(): void {
    RouterUtil.stack?.pop()
  }
}
