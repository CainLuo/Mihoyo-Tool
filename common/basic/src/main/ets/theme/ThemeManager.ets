/**
 * ============================================================
 * ThemeManager — 全局主题单例
 * ============================================================
 *
 * @ObservedV2 + @Trace 实现响应式切换。
 * @Trace 只支持实例属性，单例通过模块级变量实现。
 *
 * 组件用法（@ComponentV2）：
 *   import { themeManager } from './ThemeManager'
 *   import { ThemeFonts } from './ThemeFonts'
 *
 *   @ComponentV2
 *   struct MyComponent {
 *     @Local tm = themeManager
 *     build() {
 *       Text('hello')
 *         .font(ThemeFonts.FONT_17)
 *         .fontColor(this.tm.current.colorTextPrimary)
 *     }
 *   }
 *
 * 深色 / 浅色由资源限定词（resources/dark）+ AppearanceManager.applyColorMode() 切换，
 * 不通过替换 themeManager.current 实现；项目中目前只有 DefaultTheme 一个 Theme 实现。
 * ============================================================
 */

import { Theme } from 'widgetbase'

import { DefaultTheme } from 'widgetbase'

@ObservedV2
class ThemeManager {
  @Trace current: Theme = new DefaultTheme()
}

export const themeManager = new ThemeManager()
export { ThemeManager }
