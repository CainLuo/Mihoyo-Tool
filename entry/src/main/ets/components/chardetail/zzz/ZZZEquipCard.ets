/**
 * ZZZEquipCard — 绝区零驱动盘卡片
 *
 * 卡片头部 + 主词条行 + 副词条列表。
 * 仅在 ZZZEquipSection 的驱动盘网格中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZCharDetailEquip, ZZZSubStat } from '../../../models/CharDetailModels';
import { ZZZEquipCardHeader } from './ZZZEquipCardHeader';

@ComponentV2
export struct ZZZEquipCard {
  @Param equip: ZZZCharDetailEquip = new ZZZCharDetailEquip();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      ZZZEquipCardHeader({ equip: this.equip })

      Row() {
        Text(this.equip.mainStatName)
          .fontSize(this.tm.current.font11)
          .fontColor(this.tm.current.accentPrimaryStrong)
          .layoutWeight(1)

        Text(this.equip.mainStatValue)
          .fontSize(this.tm.current.fontBold14)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
      }
      .width(this.tm.current.full)
      .padding({ top: this.tm.current.value2, bottom: this.tm.current.value2 })
      .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })

      Column() {
        ForEach(this.equip.subStats, (sub: ZZZSubStat) => {
          Row() {
            Text(sub.name)
              .fontSize(this.tm.current.font11)
              .fontColor(sub.valid ? this.tm.current.accentRefine : this.tm.current.textOnDarkGhost)
              .layoutWeight(1)

            Text(sub.value)
              .fontSize(this.tm.current.font11)
              .fontColor(sub.valid ? this.tm.current.accentRefine : this.tm.current.textOnDarkHigh)
          }
          .width(this.tm.current.full)
          .padding({ top: this.tm.current.value1, bottom: this.tm.current.value1 })
        }, (_sub: ZZZSubStat, idx: number) => `sub_${idx}`)
      }
      .width(this.tm.current.full)
    }
    .layoutWeight(1)
    .padding(this.tm.current.value8)
    .backgroundColor(this.tm.current.surfaceGlass)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
    .borderRadius(this.tm.current.radius8)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct ZZZEquipCardPreview {
  build() {
    ZZZEquipCard({ equip: new ZZZCharDetailEquip() })
      .width(160)
      .backgroundColor('#1a1a2e')
  }
}
