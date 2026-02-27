@Preview
@Component
export struct Home {
  build() {
    Column() {
      Text('这是首页')
        .fontSize(24)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}