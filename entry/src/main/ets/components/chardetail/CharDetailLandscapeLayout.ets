/**
 * CharDetailLandscapeLayout — 角色详情 Phone 横屏布局
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { GenshinCharacterDetailViewModel } from '../../viewmodel/GenshinCharacterDetailViewModel'
import { CharDetailHeroPanel } from './CharDetailHeroPanel'
import { CharDetailStatsPanel } from './CharDetailStatsPanel'
import { CharDetailRelicsPanel } from './CharDetailRelicsPanel'
import { HeroPanelMode } from '../../constants/HeroPanelMode'

@ComponentV2
export struct CharDetailLandscapeLayout {
  @Param tm: ThemeManager = new ThemeManager()
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel()

  build() {
    Row() {
      CharDetailHeroPanel({ vm: this.vm, mode: HeroPanelMode.LANDSCAPE })
        .width(this.tm.current.charDetailHeroPanelLandscapeW)
        .height(this.tm.current.heightFull)

      Scroll() {
        Column({ space: this.tm.current.value8 }) {
          CharDetailStatsPanel({ vm: this.vm, isPhone: true, phoneCols: 4 })
          CharDetailRelicsPanel({ vm: this.vm, isPhone: true })
            .padding({ left: this.tm.current.value8, right: this.tm.current.value8 })
          Row().height(this.tm.current.value20)
        }
        .width(this.tm.current.widthFull)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .height(this.tm.current.heightFull)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
  }
}
