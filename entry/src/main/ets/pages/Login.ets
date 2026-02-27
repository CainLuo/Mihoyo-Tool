@Preview
@Component
struct Login {
  @State username: string = ''
  @State password: string = ''

  build() {
    Column() {
      // 标题区域
      Text('欢迎登录')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 40 })

      Blank()
        .height(20)

      TextArea({ placeholder: 'qweqwe' })
        .width('90%')
        .height(150)
        .placeholderColor(Color.Gray)
        .borderRadius(8)
        .borderWidth(1)
        .borderColor(Color.Gray)
        .onChange((value: string) => {
          this.username = value
        })

      Blank()
        .height(40)

      // 操作按钮
      Button('登录', { type: ButtonType.Capsule })
        .width('90%')
        .height(50)
        .backgroundColor('#007DFF')
        .onClick(() => {
          // TODO: 处理登录逻辑
        })

      Blank()
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}

export { Login }