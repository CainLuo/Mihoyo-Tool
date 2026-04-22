/**
 * ZZZEquipSection — 绝区零驱动盘区（套装摘要 + 6件网格）
 *
 * 仅在 ZZZCharDetailContent 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZCharacterDetailViewModel } from '../../../viewmodel/ZZZCharacterDetailViewModel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { CharDetailRelicPlaceholder } from '../common/CharDetailRelicPlaceholder';
import { ZZZEquipCard } from './ZZZEquipCard';
import { ZZZSuitSummaryRow } from './ZZZSuitSummaryRow';
import { ZZZSuitSummary } from '../../../models/CharDetailModels';

@ComponentV2
export struct ZZZEquipSection {
  @Param vm: ZZZCharacterDetailViewModel = new ZZZCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.zzz_char_detail_equip_title') })

      if (this.vm.suitSummaries.length > 0) {
        Column() {
          ForEach(this.vm.suitSummaries, (suit: ZZZSuitSummary, idx: number) => {
            ZZZSuitSummaryRow({ suit: suit })
              .border({ width: { bottom: idx < this.vm.suitSummaries.length - 1 ? this.tm.current.value1 : 0 }, color: this.tm.current.surfaceGlass })
          }, (suit: ZZZSuitSummary, idx: number) => `suit_${suit.suitId}`)
        }
        .width(this.tm.current.full)
        .backgroundColor(this.tm.current.surfaceDarkLg)
        .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
        .borderRadius(this.tm.current.radius12)
        .alignItems(HorizontalAlign.Start)
      }

      Column({ space: this.tm.current.value8 }) {
        ForEach([0, 2, 4], (startIdx: number) => {
          Row({ space: this.tm.current.value8 }) {
            if (startIdx < this.vm.equips.length) {
              ZZZEquipCard({ equip: this.vm.equips[startIdx] })
            } else {
              CharDetailRelicPlaceholder({ posName: `${startIdx + 1}` })
            }

            if (startIdx + 1 < this.vm.equips.length) {
              ZZZEquipCard({ equip: this.vm.equips[startIdx + 1] })
            } else {
              CharDetailRelicPlaceholder({ posName: `${startIdx + 2}` })
            }
          }
          .width(this.tm.current.full)
          .alignItems(VerticalAlign.Top)
        }, (startIdx: number) => `row_${startIdx}`)
      }
      .width(this.tm.current.full)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
