/**
 * CharDetailPortraitLayout — 角色详情 Phone 竖屏布局
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { GenshinCharacterDetailViewModel } from '../../viewmodel/GenshinCharacterDetailViewModel'
import { CharDetailHeroPanel } from './CharDetailHeroPanel'
import { CharDetailStatsPanel } from './CharDetailStatsPanel'
import { CharDetailRelicsPanel } from './CharDetailRelicsPanel'
import { HeroPanelMode } from '../../constants/HeroPanelMode'

@ComponentV2
export struct CharDetailPortraitLayout {
  @Param tm: ThemeManager = new ThemeManager()
  @Param vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel()

  build() {
    Column() {
      CharDetailHeroPanel({ vm: this.vm, mode: HeroPanelMode.PORTRAIT })
        .height(this.tm.current.charDetailHeroPanelPortraitH)
        .width(this.tm.current.widthFull)

      Scroll() {
        Column({ space: this.tm.current.value8 }) {
          CharDetailStatsPanel({ vm: this.vm, isPhone: true, phoneCols: 2 })
          Text($r('app.string.character_no_relics'))
            .fontSize(this.tm.current.body12.size)
            .fontColor(this.tm.current.textOnDarkMuted)
            .width(this.tm.current.widthFull)
            .padding({ left: this.tm.current.value10, top: this.tm.current.value4 })
            .visibility(this.vm.relics.length === 0 ? Visibility.Visible : Visibility.None)
          CharDetailRelicsPanel({ vm: this.vm, isPhone: true })
            .padding({ left: this.tm.current.value10, right: this.tm.current.value10 })
          Row().height(this.tm.current.value8)
        }
        .width(this.tm.current.widthFull)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
  }
}
