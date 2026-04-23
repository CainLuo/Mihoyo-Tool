/**
 * StarRailRelicsSection — 星铁遗器/饰品区（2列网格 + 占位）
 *
 * 仅在 StarRailCharDetailContent 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailCharacterDetailViewModel } from '../../../viewmodel/StarRailCharacterDetailViewModel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { CharDetailRelicPlaceholder } from '../common/CharDetailRelicPlaceholder';
import { StarRailRelicCard } from './StarRailRelicCard';

@ComponentV2
export struct StarRailRelicsSection {
  @Param vm: StarRailCharacterDetailViewModel = new StarRailCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  private relicPosName(pos: number): Resource {
    if (pos === 1) { return $r('app.string.starrail_relic_pos_head'); }
    if (pos === 2) { return $r('app.string.starrail_relic_pos_hand'); }
    if (pos === 3) { return $r('app.string.starrail_relic_pos_body'); }
    if (pos === 4) { return $r('app.string.starrail_relic_pos_feet'); }
    if (pos === 5) { return $r('app.string.starrail_relic_pos_sphere'); }
    if (pos === 6) { return $r('app.string.starrail_relic_pos_rope'); }
    return $r('app.string.starrail_relic_pos_head');
  }

  build() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.starrail_char_detail_relics_title') })
      Column({ space: this.tm.current.value8 }) {
        ForEach([0, 2], (startIdx: number) => {
          Row({ space: this.tm.current.value8 }) {
            if (startIdx < this.vm.relics.length) {
              StarRailRelicCard({ relic: this.vm.relics[startIdx] })
            } else {
              CharDetailRelicPlaceholder({ posName: this.relicPosName(startIdx + 1) })
            }
            if (startIdx + 1 < this.vm.relics.length) {
              StarRailRelicCard({ relic: this.vm.relics[startIdx + 1] })
            } else {
              CharDetailRelicPlaceholder({ posName: this.relicPosName(startIdx + 2) })
            }
          }
          .width(this.tm.current.full)
          .alignItems(VerticalAlign.Top)
        }, (startIdx: number) => `relicrow_${startIdx}`)
        Row({ space: this.tm.current.value8 }) {
          if (this.vm.ornaments.length > 0) {
            StarRailRelicCard({ relic: this.vm.ornaments[0] })
          } else {
            CharDetailRelicPlaceholder({ posName: this.relicPosName(5) })
          }
          if (this.vm.ornaments.length > 1) {
            StarRailRelicCard({ relic: this.vm.ornaments[1] })
          } else {
            CharDetailRelicPlaceholder({ posName: this.relicPosName(6) })
          }
        }
        .width(this.tm.current.full)
        .alignItems(VerticalAlign.Top)
      }
      .width(this.tm.current.full)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
