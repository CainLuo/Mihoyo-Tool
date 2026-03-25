/**
 * CharDetailWideLayout — 角色详情宽屏三栏布局
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { GenshinCharacterDetailViewModel } from '../../viewmodel/GenshinCharacterDetailViewModel'
import { CharDetailHeroPanel } from './CharDetailHeroPanel'
import { CharDetailStatsPanel } from './CharDetailStatsPanel'
import { CharDetailRelicsPanel } from './CharDetailRelicsPanel'
import { HeroPanelMode } from '../../constants/HeroPanelMode'

@ComponentV2
export struct CharDetailWideLayout {
  @Param tm: ThemeManager = new ThemeManager()
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel()

  build() {
    Row({ space: this.tm.current.value8 }) {
      CharDetailHeroPanel({ vm: this.vm, mode: HeroPanelMode.WIDE })
        .layoutWeight(1)
        .height(this.tm.current.heightFull)
        .borderRadius(this.tm.current.radius8)
        .clip(true)

      CharDetailStatsPanel({ vm: this.vm, isPhone: false })
        .layoutWeight(1)
        .height(this.tm.current.heightFull)

      CharDetailRelicsPanel({ vm: this.vm, isPhone: false })
        .layoutWeight(1)
        .height(this.tm.current.heightFull)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .padding(this.tm.current.value8)
  }
}
