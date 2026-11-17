/**
 * LoginErrorText — 登录错误提示（手机号 / Cookie 登录共用）
 *
 * ViewModel 在参数校验失败时会写入哨兵错误码（phone_empty / code_empty / cookie_empty），
 * 其余情况写入的是可直接展示的异常文案。本组件负责把哨兵码翻译成用户可读文案，
 * 未识别的值原样展示。
 */
import { themeManager, ThemeManager, ThemeFonts } from 'basic';

/** 哨兵错误码 → 可读文案 */
function toDisplayMessage(raw: string): string {
  switch (raw) {
    case 'phone_empty':
      return '请输入手机号';
    case 'code_empty':
      return '请输入验证码';
    case 'cookie_empty':
      return '请输入 Cookie';
    default:
      return raw;
  }
}

@ComponentV2
export struct LoginErrorText {
  @Param message: string = '';
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      if (this.message.length > 0) {
        Text(toDisplayMessage(this.message))
          .font(ThemeFonts.FONT_14)
          .fontColor(this.tm.current.colorDanger)
          .width(this.tm.current.full)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.tm.current.full)
  }
}
