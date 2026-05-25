/**
 * ThemeModeRow — 主题模式选项行组件
 *
 * 用于外观设置页面，显示单个主题模式选项。
 */
import { ThemeFonts } from '../../theme/ThemeFonts'
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeModeItem } from '../../viewmodel/AppearanceSettingsViewModel'

@ComponentV2
export struct ThemeModeRow {
  @Param item: ThemeModeItem = new ThemeModeItem()
  @Param isSelected: boolean = false
  @Param onSelect: (mode: number) => void = (_mode: number) => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.font14 }) {
      Column() {
        Text(this.item.label)
          .font(ThemeFonts.font17)
          .fontColor(this.tm.current.colorTextPrimary)

        Text(this.item.desc)
          .font(ThemeFonts.font14)
          .fontColor(this.tm.current.colorTextSecondary)
          .margin({ top: this.tm.current.value4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Stack() {
        Row()
          .width(this.tm.current.font20)
          .height(this.tm.current.font20)
          .backgroundColor(
            this.isSelected
              ? this.tm.current.colorPrimary
              : Color.Transparent
          )

        if (this.isSelected) {
          Text('\u2713')
            .fontColor(Color.White)
            .fontSize(this.tm.current.value11)
            .fontWeight(FontWeight.Bold)
        }
      }
      .width(this.tm.current.font20)
      .height(this.tm.current.font20)
      .borderRadius(this.tm.current.value12)
      .border(
        this.isSelected
          ? { width: 0 }
          : { width: this.tm.current.value2, color: this.tm.current.colorDivider }
      )
      .clip(true)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value56)
    .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.onSelect(this.item.mode)
    })
  }
}

@Preview
@ComponentV2
export struct ThemeModeRowPreview {
  build() {
    Column({ space: 8 }) {
      ThemeModeRow({
        item: new ThemeModeItem(),
        isSelected: true
      })
      ThemeModeRow({
        item: new ThemeModeItem(),
        isSelected: false
      })
    }
    .padding(16)
    .width('100%')
    .backgroundColor('#1a1a2e')
  }
}
