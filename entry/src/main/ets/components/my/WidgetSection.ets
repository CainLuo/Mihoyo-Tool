/**
 * WidgetSection — My 页面的 Widget 卡片入口区域
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MyAccountVM } from '../../models/MyModels';
import { AccountWidgetBlock } from './AccountWidgetBlock';

@ComponentV2
export struct WidgetSection {
  @Param accounts: MyAccountVM[] = [];
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      ForEach(this.accounts, (account: MyAccountVM) => {
        AccountWidgetBlock({ account: account })
      }, (account: MyAccountVM) => account.uid)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
  }
}

@Preview
@ComponentV2
export struct WidgetSectionPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: 16 }) {
      WidgetSection({ accounts: [] })
    }
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}
