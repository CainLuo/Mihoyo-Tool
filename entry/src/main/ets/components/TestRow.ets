/**
 * TestRow — 测试页操作行（仅 Mock/Debug 环境使用）
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'

@ComponentV2
export struct TestRow {
  @Param title: string = ''
  @Param desc: string = ''
  @Param onTap: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Row() {
      Column({ space: this.tm.current.value4 }) {
        Text(this.title)
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextPrimary)
          .width(this.tm.current.full)

        Text(this.desc)
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.full)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text($r('app.string.common_arrow_right'))
        .font(this.tm.current.body16)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .padding({
      top: this.tm.current.value12,
      bottom: this.tm.current.value12,
      left: this.tm.current.value16,
      right: this.tm.current.value16,
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .onClick(this.onTap)
  }
}
