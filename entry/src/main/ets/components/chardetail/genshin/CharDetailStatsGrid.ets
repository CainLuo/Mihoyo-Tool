/**
 * CharDetailStatsGrid — 属性网格（Phone 模式）
 *
 * Phone 紧凑模式使用的属性网格，多列展示。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailStatRow } from '../common/CharDetailStatRow';
import { CharDetailStat } from '../../../models/CharDetailModels';

@ComponentV2
export struct CharDetailStatsGrid {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  /** Phone 属性网格列数 */
  @Param phoneCols: number = 2;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Grid() {
      ForEach(this.vm.stats, (stat: CharDetailStat) => {
        GridItem() {
          CharDetailStatRow({ stat: stat, charElement: this.vm.charElement, isCompact: true })
            .padding({
              left: this.tm.current.value8,
              right: this.tm.current.value8,
              top: this.tm.current.value5,
              bottom: this.tm.current.value5
            })
            .border({
              width: { right: this.tm.current.value1, bottom: this.tm.current.value1 },
              color: this.tm.current.surfaceGlass
            })
        }
      }, (stat: CharDetailStat, idx: number) => `pstat_${idx}`)
    }
    .columnsTemplate(this.phoneCols === 4 ? '1fr 1fr 1fr 1fr' : '1fr 1fr')
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.surfaceDarkMd)
    .border({ width: this.tm.current.value1, color: this.tm.current.surfaceGlass })
    .borderRadius(this.tm.current.radius8)
  }
}
