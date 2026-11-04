/**
 * TargetConfigTipCard.ets — 养成目标配置页顶部的提示卡片
 *
 * 三个游戏的目标配置页共用。
 */

import { themeManager, ThemeManager, ThemeFonts } from 'basic'

@ComponentV2
export struct TargetConfigTipCard {
  @Require @Param tip: ResourceStr

  @Local private tm: ThemeManager = themeManager

  build() {
    Row() {
      Text('💡')
        .fontSize(this.tm.current.value16)
        .margin({ right: this.tm.current.value8 })

      Text(this.tip)
        .font(ThemeFonts.FONT_13)
        .fontColor(this.tm.current.colorTextPrimary)
        .layoutWeight(1)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: 1, color: this.tm.current.colorDivider })
  }
}
