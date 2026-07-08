/**
 * CharDetailRelicPair — 圣遗物对（Phone 模式）
 *
 * Phone 模式下圣遗物网格的一行，包含两个圣遗物位置。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailRelic } from '../../../models/CharDetailModels';
import { CharDetailRelicCard } from './CharDetailRelicCard';
import { CharDetailRelicPlaceholder } from '../common/CharDetailRelicPlaceholder';

@ComponentV2
export struct CharDetailRelicPair {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Param pos1: number = 1;
  @Param pos2: number = 2;
  @Local private tm: ThemeManager = themeManager;

  private relicPosName(pos: number): Resource {
    if (pos === 1) { return $r('app.string.char_detail_relic_pos_flower'); }
    if (pos === 2) { return $r('app.string.char_detail_relic_pos_plume'); }
    if (pos === 3) { return $r('app.string.char_detail_relic_pos_sands'); }
    if (pos === 4) { return $r('app.string.char_detail_relic_pos_goblet'); }
    if (pos === 5) { return $r('app.string.char_detail_relic_pos_circlet'); }
    return $r('app.string.char_detail_relic_pos_flower');
  }

  private findRelicByPos(pos: number): CharDetailRelic | null {
    for (let i = 0; i < this.vm.relics.length; i++) {
      if (this.vm.relics[i].pos === pos) { return this.vm.relics[i]; }
    }
    return null;
  }

  private relicIdx(pos: number): number {
    for (let i = 0; i < this.vm.relics.length; i++) {
      if (this.vm.relics[i].pos === pos) { return i; }
    }
    return 0;
  }

  build() {
    Row({ space: this.tm.current.value8 }) {
      if (this.findRelicByPos(this.pos1) !== null) {
        Column() {
          CharDetailRelicCard({ relic: this.vm.relics[this.relicIdx(this.pos1)] })
        }
        .layoutWeight(1)
      } else {
        Column() {
          CharDetailRelicPlaceholder({ posName: this.relicPosName(this.pos1) })
        }
        .layoutWeight(1)
      }

      if (this.findRelicByPos(this.pos2) !== null) {
        Column() {
          CharDetailRelicCard({ relic: this.vm.relics[this.relicIdx(this.pos2)] })
        }
        .layoutWeight(1)
      } else {
        Column() {
          CharDetailRelicPlaceholder({ posName: this.relicPosName(this.pos2) })
        }
        .layoutWeight(1)
      }
    }
    .width(this.tm.current.full)
    .alignItems(VerticalAlign.Top)
  }
}
