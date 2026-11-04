/**
 * LevelConfigRow.ets — 养成目标配置页的等级行
 *
 * 左侧「当前等级」、右侧「目标等级」，点击任意一侧由页面弹出等级选择器。
 * 三个游戏的目标配置页共用，避免同构 @Builder 各复制一份。
 */

import { themeManager, ThemeManager, ThemeFonts } from 'basic'
import { LevelConfigVM } from '../model/MaterialTargetConfigModels'

@ComponentV2
export struct LevelConfigRow {
  /** 行标题（角色 / 技能 / 武器 / 光锥） */
  @Require @Param label: ResourceStr
  @Require @Param config: LevelConfigVM
  /** 点击「当前等级」 */
  @Param onPickCurrent: () => void = () => {}
  /** 点击「目标等级」 */
  @Param onPickTarget: () => void = () => {}

  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      Text(this.label)
        .fontSize(this.tm.current.font12)
        .fontColor(this.tm.current.colorTextSecondary)
        .margin({ bottom: this.tm.current.value8 })

      Row({ space: this.tm.current.value8 }) {
        Column() {
          Text($r('app.string.material_target_config_current'))
            .font(ThemeFonts.FONT_11)
            .fontColor(this.tm.current.colorTextSecondary)
            .margin({ bottom: this.tm.current.value2 })

          Text(this.config.current.toString())
            .font(ThemeFonts.FONT_BOLD_18)
            .fontColor(this.tm.current.colorTextPrimary)
        }
        .layoutWeight(1)
        .padding(this.tm.current.value8)
        .backgroundColor(this.tm.current.colorPageBg)
        .borderRadius(this.tm.current.radius8)
        .onClick(() => {
          this.onPickCurrent()
        })

        Column() {
          Text($r('app.string.material_target_config_target'))
            .font(ThemeFonts.FONT_11)
            .fontColor(this.tm.current.colorTextSecondary)
            .margin({ bottom: this.tm.current.value2 })

          Text(this.config.target.toString())
            .font(ThemeFonts.FONT_BOLD_18)
            .fontColor(this.tm.current.colorPrimary)
        }
        .layoutWeight(1)
        .padding(this.tm.current.value8)
        .backgroundColor(this.tm.current.colorPageBg)
        .borderRadius(this.tm.current.radius8)
        .onClick(() => {
          this.onPickTarget()
        })
      }
      .width(this.tm.current.full)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value10)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({ width: 1, color: this.tm.current.colorDivider })
    .margin({ bottom: this.tm.current.value10 })
  }
}
