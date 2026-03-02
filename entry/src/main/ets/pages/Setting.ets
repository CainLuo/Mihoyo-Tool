@Component
export struct Setting {
  build() {
    Column() {
      Text('这是设置页')
        .fontSize(24)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
