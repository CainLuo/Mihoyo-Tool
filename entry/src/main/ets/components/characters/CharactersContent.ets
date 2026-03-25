/**
 * CharactersContent — 角色页内容区组件
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { CharactersViewModel } from '../../viewmodel/CharactersViewModel'
import { GameDataSummary } from 'core'
import { HomePlaceholderView } from '../home/HomePlaceholderView'
import { CharacterCard } from './CharacterCard'
import { CharactersSkeleton } from './CharactersSkeleton'
import { GameTabBar } from './GameTabBar'
import { ViewState } from '../../constants/ViewStates'
import { AppConstants } from '../../constants/AppConstants'

@ComponentV2
export struct CharactersContent {
  @Param tm: ThemeManager = new ThemeManager()
  @Param vm: CharactersViewModel = new CharactersViewModel()
  @Param currentBreakpoint: string = 'xs'
  @Param scroller: Scroller = new Scroller()

  build() {
    Column() {
      if (this.vm.gameTabs.length > 1) {
        GameTabBar({
          tabs: this.vm.gameTabs,
          selectedIdx: this.vm.selectedGameIdx,
          onSelect: (idx: number) => { this.vm.selectGame(idx) }
        })
        Divider().color(this.tm.current.colorDivider)
      }

      if (this.vm.viewState === ViewState.LOADING) {
        Scroll() {
          Column({ space: this.tm.current.value16 }) {
            CharactersSkeleton()
          }
          .width(this.tm.current.widthFull)
          .padding({ top: this.tm.current.value16 })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Top)
      } else if (this.vm.viewState === ViewState.EMPTY) {
        if (this.vm.accountOptions.length === 0) {
          HomePlaceholderView()
        } else {
          Column({ space: this.tm.current.value20 }) {
            Text('📋').fontSize(this.tm.current.iconSizeXL)
            Column({ space: this.tm.current.value8 }) {
              Text($r('app.string.characters_placeholder_title'))
                .font(this.tm.current.title18Bold)
                .fontColor(this.tm.current.colorTextPrimary)
                .textAlign(TextAlign.Center)
              Text($r('app.string.characters_placeholder_desc'))
                .font(this.tm.current.body16)
                .fontColor(this.tm.current.colorTextSecondary)
                .textAlign(TextAlign.Center)
                .padding({ left: this.tm.current.value40, right: this.tm.current.value40 })
            }
            Button($r('app.string.characters_no_data_hint'))
              .fontSize(this.tm.current.body16Medium.size)
              .fontWeight(this.tm.current.body16Medium.weight)
              .fontColor(Color.White)
              .width(this.tm.current.widthButton)
              .height(this.tm.current.heightButton)
              .borderRadius(this.tm.current.radius12)
              .backgroundColor(this.tm.current.colorPrimary)
              .onClick(() => { this.vm.refresh() })
          }
          .width(this.tm.current.widthFull)
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      } else {
        Scroll(this.scroller) {
          Column({ space: this.tm.current.value16 }) {
            GridRow({
              columns: { xs: 2, sm: 3, md: 4, lg: 5 },
              gutter: { x: this.tm.current.value12, y: this.tm.current.value12 },
              breakpoints: {
                value: AppConstants.GRID_BREAKPOINTS,
                reference: BreakpointsReference.WindowSize
              }
            }) {
              ForEach(this.vm.characters, (character: GameDataSummary) => {
                GridCol({ span: 1 }) {
                  CharacterCard({
                    character: character,
                    isPhone: this.currentBreakpoint === 'xs',
                    breakpoint: this.currentBreakpoint,
                    gameId: this.vm.gameTabs.length > 0
                      ? this.vm.gameTabs[this.vm.selectedGameIdx].gameId : 'genshin',
                    roleUid: this.vm.gameTabs.length > 0
                      ? this.vm.gameTabs[this.vm.selectedGameIdx].roleUid : ''
                  })
                }
              }, (character: GameDataSummary) => character.entityId)
            }
            .width(this.tm.current.widthFull)
            .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
            Row().height(this.tm.current.value40)
          }
          .width(this.tm.current.widthFull)
          .padding({ top: this.tm.current.value8 })
        }
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Top)
      }
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
  }
}
