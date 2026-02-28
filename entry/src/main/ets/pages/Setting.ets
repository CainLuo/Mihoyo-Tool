import { HMRouter } from '@hadss/hmrouter'

@Preview
@HMRouter({pageUrl: 'Setting', lifecycle: 'ExitAppLifecycle'})
@Component
struct Setting {
  build() {
    NavDestination() {
      Column() {
        Text('这是设置页')
          .fontSize(24)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
  }
}

export { Setting }