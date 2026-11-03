/**
 * ExpeditionItem — 派遣角色条目
 *
 * 原神、星铁共用。显示角色头像 + 剩余时间。
 * 头像加载失败时显示占位圆圈。
 */

import { themeManager, ThemeManager, ThemeFonts, TimeFormatUtil } from 'basic'
import { ExpeditionVM } from '../../model/DailyNoteModels'

// ── Preview：派遣进行中 ──
@Preview
@ComponentV2
export struct ExpeditionItemPreviewOngoing {
  build() {
    Column() {
      ExpeditionItem({
        expedition: new ExpeditionVM('', 29640, false)  // 8小时14分钟
      })
      ExpeditionItem({
        expedition: new ExpeditionVM('', 0, true)
      })
    }
    .backgroundColor(themeManager.current.colorSurfaceCard)
    .width(themeManager.current.value360)
  }
}

@ComponentV2
export struct ExpeditionItem {
  @Require @Param expedition: ExpeditionVM
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.value12 }) {
      // 角色头像
      if (this.expedition.avatarUrl !== '') {
        Image(this.expedition.avatarUrl)
          .width(this.tm.current.value40)
          .height(this.tm.current.value40)
          .borderRadius(this.tm.current.font20)
          .backgroundColor(this.tm.current.colorDivider)
      } else {
        // 占位圆
        Row()
          .width(this.tm.current.value40)
          .height(this.tm.current.value40)
          .borderRadius(this.tm.current.font20)
          .backgroundColor(this.tm.current.colorDivider)
      }

      // 剩余时间
      if (this.expedition.isFinished) {
        Text($r('app.string.daily_note_expedition_finished'))
          .font(ThemeFonts.FONT_MEDIUM_17)
          .fontColor(this.tm.current.colorPrimary)
          .layoutWeight(1)
      } else if (this.expedition.remainSeconds === 0) {
        // remainSeconds=0 且未完成：来自 Widget 接口，无剩余时间信息，只显示"探索中"
        Text($r('app.string.daily_note_expedition_ongoing'))
          .font(ThemeFonts.FONT_17)
          .fontColor(this.tm.current.colorDanger)
          .layoutWeight(1)
      } else {
        Row({ space: this.tm.current.value2 }) {
          Text($r('app.string.daily_note_expedition_remain_prefix'))
            .font(ThemeFonts.FONT_17)
            .fontColor(this.tm.current.colorDanger)
          Text(TimeFormatUtil.formatSeconds(this.expedition.remainSeconds, this.getUIContext()))
            .font(ThemeFonts.FONT_17)
            .fontColor(this.tm.current.colorDanger)
        }
        .layoutWeight(1)
      }
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.font16,
      right: this.tm.current.font16,
      top: this.tm.current.value8,
      bottom: this.tm.current.value8
    })
    .alignItems(VerticalAlign.Center)
  }
}
