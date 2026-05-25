/**
 * NotificationStyleCard — 通知样式选择卡片
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeFonts } from '../../theme/ThemeFonts'
import { NotificationStyle } from '../../notification/NotificationModels'
import { NotificationSettingsViewModel } from '../../viewmodel/NotificationSettingsViewModel'
import { NotificationStyleAPreview } from './NotificationStyleAPreview'
import { NotificationStyleBPreview } from './NotificationStyleBPreview'

@ComponentV2
export struct NotificationStyleCard {
  @Param style: NotificationStyle = NotificationStyle.STYLE_A
  @Param title: ResourceStr = ''
  @Param desc: ResourceStr = ''
  @Param vm: NotificationSettingsViewModel = new NotificationSettingsViewModel()
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value12 }) {
      Row({ space: this.tm.current.value12 }) {
        Row() {
          if (this.vm.style === this.style) {
            Circle({ width: this.tm.current.value8, height: this.tm.current.value8 })
              .fill($r('app.color.color_primary'))
          }
        }
        .width(this.tm.current.font20)
        .height(this.tm.current.font20)
        .borderRadius(this.tm.current.value10)
        .border({
          width: this.tm.current.value2,
          color: this.vm.style === this.style ? $r('app.color.color_primary') : $r('app.color.color_divider'),
        })
        .justifyContent(FlexAlign.Center)

        Column({ space: this.tm.current.value2 }) {
          Text(this.title)
            .font(ThemeFonts.fontBold14)
            .fontColor(this.tm.current.colorTextPrimary)
          Text(this.desc)
            .font(ThemeFonts.font13)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width(this.tm.current.full)

      if (this.style === NotificationStyle.STYLE_A) {
        NotificationStyleAPreview()
      } else {
        NotificationStyleBPreview()
      }
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .borderRadius(this.tm.current.radius8)
    .border({
      width: this.tm.current.value1p5,
      color: this.vm.style === this.style ? $r('app.color.color_primary') : $r('app.color.color_divider'),
    })
    .backgroundColor(this.vm.style === this.style
      ? $r('app.color.surface_active_primary')
      : $r('app.color.color_transparent'))
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.vm.onStyleChange(this.style).catch((_: Error | object) => {})
    })
  }
}
