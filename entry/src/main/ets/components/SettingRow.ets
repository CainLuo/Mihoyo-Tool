/**
 * SettingRow — 通用设置行组件
 *
 * 左侧标签 + 可选右侧值文字 + 箭头，适用于所有"点击跳转/触发操作"的设置行。
 * 不传 onTap 时不显示箭头，仅展示标签和值（用于纯展示行如版本号）。
 * 背景色和圆角由父容器负责。
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'

@ComponentV2
export struct SettingRow {
  @Param label: ResourceStr = ''
  @Param value: ResourceStr | string = ''
  @Param onTap: (() => void) | null = null
  @Local private tm: ThemeManager = themeManager

  build() {
    Row() {
      Text(this.label)
        .font(this.tm.current.body16)
        .fontColor(this.tm.current.colorTextPrimary)
        .layoutWeight(1)
      if (this.value !== '') {
        Text(this.value)
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ right: this.onTap !== null ? this.tm.current.value8 : 0 })
      }
      if (this.onTap !== null) {
        Text($r('app.string.common_arrow_right'))
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextSecondary)
      }
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value50)
    .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    .alignItems(VerticalAlign.Center)
    .onClick(this.onTap !== null ? this.onTap : () => {})
  }
}
