/**
 * CharDetailPortraitStatsSection — 属性区 Section
 *
 * Phone 竖屏布局的属性区块，包含标题和属性列表。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { CharDetailStatRow } from '../common/CharDetailStatRow';
import { CharDetailStat } from '../../../models/CharDetailModels';

@ComponentV2
export struct CharDetailPortraitStatsSection {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.char_detail_section_stats') })

      Column() {
        ForEach(this.vm.stats, (stat: CharDetailStat, idx: number) => {
          CharDetailStatRow({ stat: stat, charElement: this.vm.charElement })
            .padding({
              left: this.tm.current.value12,
              right: this.tm.current.value12,
              top: this.tm.current.value8,
              bottom: this.tm.current.value8
            })
            .border({
              width: { bottom: idx < this.vm.stats.length - 1 ? this.tm.current.value1 : 0 },
              color: this.tm.current.surfaceGlass
            })
        }, (stat: CharDetailStat, idx: number) => `stat_${idx}`)
      }
      .width(this.tm.current.full)
      .backgroundColor(this.tm.current.surfaceDarkLg)
      .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
      .borderRadius(this.tm.current.radius12)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
