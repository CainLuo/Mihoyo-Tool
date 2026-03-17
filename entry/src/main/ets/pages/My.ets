import { HMRouterMgr } from "@hadss/hmrouter"

@Component
export struct My {
  build() {
    Column() {
      Row() {
        Blank()
        Text('设置')
          .fontSize(18)
          .margin({ right: 20 })
          .onClick(() => {
            HMRouterMgr.push({pageUrl: 'Setting', skipAllInterceptor: true})
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)

      Text('这是我的页面')
        .fontSize(24)
        .margin({ top: 40 })
    }
    .width('100%')
    .height('100%')
  }
}
