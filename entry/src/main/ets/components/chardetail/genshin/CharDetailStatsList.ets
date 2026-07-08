/**
 * CharDetailStatsList — 属性列表（宽屏模式）
 *
 * 宽屏中栏使用的属性列表，每行一条属性。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailStatRow } from '../common/CharDetailStatRow';
import { CharDetailStat } from '../../../models/CharDetailModels';

@ComponentV2
export struct CharDetailStatsList {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      ForEach(this.vm.stats, (stat: CharDetailStat) => {
        CharDetailStatRow({ stat: stat, charElement: this.vm.charElement })
          .padding({
            left: this.tm.current.font16,
            right: this.tm.current.font16,
            top: this.tm.current.value8,
            bottom: this.tm.current.value8
          })
          .border({ width: { bottom: this.tm.current.value1 }, color: this.tm.current.surfaceGlass })
      }, (stat: CharDetailStat, idx: number) => `stat_${idx}`)
    }
    .width(this.tm.current.full)
  }
}
