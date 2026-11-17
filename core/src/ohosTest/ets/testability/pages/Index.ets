@Entry
@Component
struct Index {
  @State message: string = 'Test running';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(24)
      }
      .width('100%')
    }
    .height('100%')
  }
}
