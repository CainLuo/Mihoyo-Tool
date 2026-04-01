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

@ComponentV2
export struct CharactersContent {
  @Param tm: ThemeManager = new ThemeManager()
  @Param vm: CharactersViewModel = new CharactersViewModel()
  @Param scroller: Scroller = new Scroller()
  @Param onCardTap: (character: GameDataSummary) => void = (_c: GameDataSummary) => {}

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
          .width(this.tm.current.full)
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
            Text('📋').fontSize(this.tm.current.value64)
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
              .fontColor(this.tm.current.textOnDarkHigh)
              .width(this.tm.current.pct90)
              .height(this.tm.current.value50)
              .borderRadius(this.tm.current.radius12)
              .backgroundColor(this.tm.current.colorPrimary)
              .onClick(() => { this.vm.refresh() })
          }
          .width(this.tm.current.full)
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      } else {
        // LazyForEach + Grid 实现懒加载，只渲染可见区域内的卡片
        Grid(this.scroller) {
          LazyForEach(this.vm.dataSource, (character: GameDataSummary) => {
            GridItem() {
              CharacterCard({
                character: character,
                gameId: this.vm.gameTabs.length > 0
                  ? this.vm.gameTabs[this.vm.selectedGameIdx].gameId : 'genshin',
                roleUid: this.vm.gameTabs.length > 0
                  ? this.vm.gameTabs[this.vm.selectedGameIdx].roleUid : '',
                onTap: (c: GameDataSummary) => { this.onCardTap(c) }
              })
            }
          }, (character: GameDataSummary) => `${character.gameId}_${character.entityId}`)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(this.tm.current.value12)
        .rowsGap(this.tm.current.value12)
        .padding({
          top: this.tm.current.value8,
          left: this.tm.current.value16,
          right: this.tm.current.value16,
          bottom: this.tm.current.value40
        })
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
  }
}
