/**
 * ============================================================
 * ThemeManager — 全局主题单例
 * ============================================================
 *
 * @ObservedV2 + @Trace 实现响应式切换。
 * @Trace 只支持实例属性，单例通过模块级变量实现。
 *
 * 组件用法（@ComponentV2）：
 *   import { themeManager } from '../theme/ThemeManager'
 *   import { ThemeFonts } from '../theme/ThemeFonts'
 *
 *   @ComponentV2
 *   struct MyComponent {
 *     @Local tm = themeManager
 *     build() {
 *       Text('hello')
 *         .font(ThemeFonts.font17)
 *         .fontColor(this.tm.current.colorTextPrimary)
 *     }
 *   }
 *
 * 切换主题：
 *   themeManager.current = new DarkTheme()
 * ============================================================
 */

import { Theme } from './AppTheme'

import { DefaultTheme } from './DefaultTheme'

@ObservedV2
class ThemeManager {
  @Trace current: Theme = new DefaultTheme()
}

export const themeManager = new ThemeManager()
export { ThemeManager }
