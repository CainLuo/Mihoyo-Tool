/**
 * CharDetailPortraitRelicsSection — 圣遗物区 Section
 *
 * Phone 竖屏布局的圣遗物区块，包含标题和圣遗物面板。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { GenshinCharacterDetailViewModel } from '../../../viewmodel/GenshinCharacterDetailViewModel';
import { CharDetailSectionLabel } from '../common/CharDetailSectionLabel';
import { CharDetailRelicsPanel } from './CharDetailRelicsPanel';

@ComponentV2
export struct CharDetailPortraitRelicsSection {
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value4 }) {
      CharDetailSectionLabel({ title: $r('app.string.char_detail_section_relics') })

      CharDetailRelicsPanel({ vm: this.vm, isPhone: true })
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}
