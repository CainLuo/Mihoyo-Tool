import { HMRouterMgr } from '@hadss/hmrouter'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { AppRoutes } from '../constants/AppRoutes'
import { Logger } from '../utils/Logger'

@ComponentV2
export struct My {
  @Local tm: ThemeManager = themeManager

  build() {
    Column() {
      // ── 顶部导航栏 ──────────────────────────────────────────
      Row() {
        Text($r('app.string.main_tab_my'))
          .font(this.tm.current.title24Bold)
          .fontColor(this.tm.current.colorTextPrimary)
          .padding({ left: this.tm.current.value16 })
          .layoutWeight(1)

        Button({ type: ButtonType.Normal }) {
          Text($r('app.string.my_setting_button'))
            .font(this.tm.current.body16)
            .fontColor(this.tm.current.colorPrimary)
        }
        .width(this.tm.current.heightNavBar)
        .height(this.tm.current.heightNavBar)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          Logger.info('My', 'navigate to Setting')
          HMRouterMgr.push({ pageUrl: AppRoutes.SETTING })
        })
      }
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightNavBar)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.tm.current.colorCardBg)

      Divider().color(this.tm.current.colorDivider)

      // ── 内容区 ──────────────────────────────────────────────
      Column() {
        Text($r('app.string.my_page_title'))
          .font(this.tm.current.title24Bold)
          .fontColor(this.tm.current.colorTextPrimary)
      }
      .width(this.tm.current.widthFull)
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}
