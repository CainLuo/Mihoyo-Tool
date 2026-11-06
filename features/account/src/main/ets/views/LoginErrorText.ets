/**
 * LoginErrorText — 登录错误提示（手机号 / Cookie 登录共用）
 */
import { themeManager, ThemeManager, ThemeFonts } from 'basic';

@ComponentV2
export struct LoginErrorText {
  @Param message: string = '';
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      if (this.message.length > 0) {
        Text(this.message)
          .font(ThemeFonts.FONT_14)
          .fontColor(this.tm.current.colorDanger)
          .width(this.tm.current.full)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.tm.current.full)
  }
}
