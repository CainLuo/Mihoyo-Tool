/**
 * HomeContent — 首页内容区组件
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { HomeViewModel } from '../../viewmodel/HomeViewModel'
import { MihoyoAccountVM, GameRoleCardVM } from '../../models/HomeModels'
import { UserGameSection } from './UserGameSection'
import { HomeSkeletonView } from './HomeSkeletonView'
import { HomePlaceholderView } from './HomePlaceholderView'
import { ViewState } from '../../constants/ViewStates'

@ComponentV2
export struct HomeContent {
  @Param tm: ThemeManager = new ThemeManager()
  @Param vm: HomeViewModel = new HomeViewModel()
  @Param scroller: Scroller = new Scroller()
  @Param onCardTap: (card: GameRoleCardVM) => void = (_card: GameRoleCardVM) => {}

  build() {
    if (this.vm.viewState === ViewState.LOADING) {
      HomeSkeletonView()
    } else if (this.vm.viewState === ViewState.EMPTY) {
      HomePlaceholderView()
    } else {
      Scroll(this.scroller) {
        Column({ space: this.tm.current.value20 }) {
          ForEach(this.vm.accounts, (account: MihoyoAccountVM) => {
            UserGameSection({
              account: account,
              onCardTap: (card: GameRoleCardVM) => { this.onCardTap(card) }
            })
          }, (account: MihoyoAccountVM) => account.accountId.toString())
          Row().height(this.tm.current.value40)
        }
        .width(this.tm.current.full)
        .padding({ top: this.tm.current.value8 })
      }
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .align(Alignment.Top)
    }
  }
}
