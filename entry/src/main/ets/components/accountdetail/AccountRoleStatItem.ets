/**
 * AccountRoleStatItem — 单个统计数据格子
 *
 * 展示：数值（大字）+ 标签（小字）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeFonts } from '../../theme/ThemeFonts'

@ComponentV2
export struct AccountRoleStatItem {
  /** 统计数值，如 '365'、'12-3' */
  @Param value: string = ''
  /** 统计标签，如 '活跃天数'、'深渊' */
  @Param name: string = ''
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value2 }) {
      Text(this.value)
        .font(ThemeFonts.fontMedium17)
        .fontColor(this.tm.current.textOnDarkHigh)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.name)
        .font(ThemeFonts.font14)
        .fontColor(this.tm.current.textOnDarkSecondary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value8,
      right: this.tm.current.value8,
      top: this.tm.current.value8,
      bottom: this.tm.current.value8
    })
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.tm.current.roleCardStatBg)
    .borderRadius(this.tm.current.value8)
  }
}
