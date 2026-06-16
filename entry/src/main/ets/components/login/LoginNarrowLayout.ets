/**
 * LoginNarrowLayout — 登录页 Phone 单栏布局
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { LoginViewModel } from 'entry/ets/viewmodel/LoginViewModel';
import { LoginLogoSection } from './LoginLogoSection';
import { LoginCard } from './LoginCard';
import { LoginAgreement } from './LoginAgreement';

@ComponentV2
export struct LoginNarrowLayout {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Event onTapTerms: () => void = () => {};
  @Event onTapPrivacy: () => void = () => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Scroll() {
      Column({ space: this.tm.current.font20 }) {
        LoginLogoSection({ logoSize: this.tm.current.value52 })
        LoginCard({ vm: this.vm })
        LoginAgreement({ onTapTerms: this.onTapTerms, onTapPrivacy: this.onTapPrivacy })
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.font20,
        right: this.tm.current.font20,
        top: this.tm.current.font20,
        bottom: this.tm.current.value40
      })
    }
    .width(this.tm.current.full)
    .layoutWeight(1)
    .align(Alignment.Top)
  }
}
