/**
 * CharactersContent — 角色页内容区组件
 *
 * 根据 viewState 展示骨架屏、空态占位或角色网格。
 * 不含任何业务判断，所有状态由 CharactersViewModel 驱动。
 */
import { ThemeManager, themeManager } from '../../theme/ThemeManager';
import { CharactersViewModel } from '../../viewmodel/CharactersViewModel';
import { GameDataSummary } from 'core';
import { HomePlaceholderView } from '../home/HomePlaceholderView';
import { CharacterCard } from './CharacterCard';
import { CharactersSkeleton } from './CharactersSkeleton';
import { CharactersEmptyView } from './CharactersEmptyView';
import { GameTabBar } from './GameTabBar';
import { ViewState } from '../../constants/ViewStates';
import { AppRoutes } from '../../constants/AppRoutes';

@ComponentV2
export struct CharactersContent {
  @Param vm: CharactersViewModel = new CharactersViewModel();
  @Param scroller: Scroller = new Scroller();
  @Param onCardTap: (character: GameDataSummary) => void = (_c: GameDataSummary) => {};
  @Param detailStack: NavPathStack = new NavPathStack();
  @Param isSplit: boolean = false;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      // 多游戏时显示 Tab 栏
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
          Column({ space: this.tm.current.font16 }) {
            CharactersSkeleton()
          }
          .width(this.tm.current.full)
          .padding({ top: this.tm.current.font16 })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Top)
      } else if (this.vm.viewState === ViewState.EMPTY) {
        // 无账号：显示登录占位；有账号但无数据：显示刷新提示
        if (this.vm.accountOptions.length === 0) {
          HomePlaceholderView({
            onTap: () => {
              if (this.isSplit) {
                this.detailStack.replacePath({ name: AppRoutes.LOGIN, param: null })
              } else {
                this.detailStack.pushPathByName(AppRoutes.LOGIN, null)
              }
            }
          })
        } else {
          CharactersEmptyView({ onRefresh: () => { this.vm.refresh() } })
        }
      } else {
        // DATA 状态：LazyForEach + Grid 懒加载
        Grid(this.scroller) {
          LazyForEach(this.vm.dataSource, (character: GameDataSummary) => {
            GridItem() {
              CharacterCard({
                character: character,
                gameId: this.vm.gameTabs.length > 0
                  ? this.vm.gameTabs[this.vm.selectedGameIdx].gameId
                  : this.vm.currentGameId,
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
          left: this.tm.current.font16,
          right: this.tm.current.font16,
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

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct CharactersContentPreviewEmpty {
  build() {
    CharactersContent({
      vm: new CharactersViewModel()
    })
    .height(600)
    .backgroundColor(themeManager.current.colorPageBg)
  }
}
