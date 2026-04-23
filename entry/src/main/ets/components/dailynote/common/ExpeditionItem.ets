/**
 * ExpeditionItem — 派遣角色条目
 *
 * 原神、星铁共用。显示角色头像 + 剩余时间。
 * 头像加载失败时显示占位圆圈。
 */

import { themeManager, ThemeManager } from '../../../theme/ThemeManager'
import { ExpeditionVM } from '../../../models/DailyNoteModels'
import { TimeFormatUtil } from '../../../utils/TimeFormatUtil'

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
  @Param expedition: ExpeditionVM = new ExpeditionVM('', 0, false)
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.value12 }) {
      // 角色头像
      if (this.expedition.avatarUrl !== '') {
        Image(this.expedition.avatarUrl)
          .width(this.tm.current.value40)
          .height(this.tm.current.value40)
          .borderRadius(this.tm.current.value20)
          .backgroundColor(this.tm.current.colorDivider)
      } else {
        // 占位圆
        Row()
          .width(this.tm.current.value40)
          .height(this.tm.current.value40)
          .borderRadius(this.tm.current.value20)
          .backgroundColor(this.tm.current.colorDivider)
      }

      // 剩余时间
      if (this.expedition.finished) {
        Text($r('app.string.daily_note_expedition_finished'))
          .font(this.tm.current.body16Medium)
          .fontColor(this.tm.current.colorPrimary)
          .layoutWeight(1)
      } else {
        Row({ space: this.tm.current.value2 }) {
          Text($r('app.string.daily_note_expedition_remain_prefix'))
            .font(this.tm.current.body16)
            .fontColor(this.tm.current.colorTextSecondary)
          Text(TimeFormatUtil.formatSeconds(this.expedition.remainSeconds, this.getUIContext()))
            .font(this.tm.current.body16)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .layoutWeight(1)
      }
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value16,
      right: this.tm.current.value16,
      top: this.tm.current.value8,
      bottom: this.tm.current.value8
    })
    .alignItems(VerticalAlign.Center)
  }
}
