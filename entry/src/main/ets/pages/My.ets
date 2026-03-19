import { HMRouterMgr } from '@hadss/hmrouter'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { AppRoutes } from '../constants/AppRoutes'
import { Logger } from '../utils/Logger'

@ComponentV2
export struct My {
  @Local tm: ThemeManager = themeManager

  build() {
    Column() {
      Row() {
        Blank()
        Text($r('app.string.my_setting_button'))
          .font(this.tm.current.title18Bold)
          .margin({ right: this.tm.current.value20 })
          .onClick(() => {
            Logger.info('My', 'navigate to Setting')
            HMRouterMgr.push({ pageUrl: AppRoutes.SETTING, skipAllInterceptor: true })
          })
      }
      .width(this.tm.current.widthFull)
      .justifyContent(FlexAlign.End)

      Text($r('app.string.my_page_title'))
        .font(this.tm.current.title24Bold)
        .margin({ top: this.tm.current.value40 })
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
  }
}
