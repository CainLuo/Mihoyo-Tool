import { AppRoute } from '../constants/AppRoute';

@Component
struct My {
  @Consume('pathStack') pathStack: NavPathStack;

  build() {
    Column() {
      Row() {
        Blank()
        Text('设置')
          .fontSize(18)
          .margin({ right: 20 })
          .onClick(() => {
            this.pathStack.pushPathByName(AppRoute.Setting, null)
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

export { My };
