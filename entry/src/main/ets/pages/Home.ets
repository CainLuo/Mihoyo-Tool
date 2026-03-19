/**
 * Home — 首页（View 层）
 *
 * 遵循 MVVM 架构规范（见 harmonyos-rules.md 第八节）：
 *   - 只负责渲染，不含业务逻辑
 *   - 通过 @Local 持有 HomeViewModel，@Trace 字段变更自动驱动 UI 刷新
 *
 * 状态机（由 HomeViewModel.viewState 驱动）：
 *   loading  — 冷启动加载，显示 Skeleton
 *   empty    — 无绑定账号，显示 Placeholder
 *   data     — 正常展示账号战绩列表
 *   error    — 加载失败，显示重试提示
 */

import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { HomeViewModel } from '../viewmodel/HomeViewModel'
import { MihoyoAccountVM, GameRoleCardVM } from '../components/home/HomeModels'
import { UserGameSection } from '../components/home/UserGameSection'
import { HomeSkeletonView } from '../components/home/HomeSkeletonView'
import { HomePlaceholderView } from '../components/home/HomePlaceholderView'
import { Logger } from '../utils/Logger'
import { HMRouterMgr } from '@hadss/hmrouter'
import { AppRoutes } from '../constants/AppRoutes'
import { GenshinDailyDetailParam } from './GenshinDailyDetail'

@ComponentV2
export struct Home {
  @Local private tm: ThemeManager = themeManager
  @Local private vm: HomeViewModel = new HomeViewModel()

  aboutToAppear(): void {
    this.vm.loadData()
  }

  build() {
    Column() {
      // ── 顶部导航栏 ──────────────────────────────────────────
      Row() {
        Row().width(this.tm.current.heightNavBar)

        Text($r('app.string.home_title'))
          .font(this.tm.current.title18Bold)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 刷新按钮：仅在 data 状态显示
        if (this.vm.viewState === 'data') {
          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.ic_refresh'))
              .width(this.tm.current.iconSizeMD)
              .height(this.tm.current.iconSizeMD)
              .fillColor(this.vm.isRefreshing
                ? this.tm.current.colorTextSecondary
                : this.tm.current.colorTextPrimary)
          }
          .width(this.tm.current.heightNavBar)
          .height(this.tm.current.heightNavBar)
          .backgroundColor(Color.Transparent)
          .enabled(!this.vm.isRefreshing)
          .onClick(() => {
            Logger.info('Home', 'refresh tapped')
            this.vm.refresh()
          })
        } else {
          Row().width(this.tm.current.heightNavBar)
        }
      }
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightNavBar)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.tm.current.colorCardBg)

      Divider().color(this.tm.current.colorDivider)

      // ── 内容区：根据 viewState 切换 ─────────────────────────
      if (this.vm.viewState === 'loading') {
        HomeSkeletonView()
      } else if (this.vm.viewState === 'empty') {
        HomePlaceholderView()
      } else if (this.vm.viewState === 'error') {
        this.buildErrorView()
      } else {
        Scroll() {
          Column({ space: this.tm.current.value20 }) {
            ForEach(this.vm.accounts, (account: MihoyoAccountVM) => {
              UserGameSection({
                account: account,
                onCardTap: (card: GameRoleCardVM) => {
                  Logger.info('Home', `card tapped: ${card.gameId} ${card.roleUid}`)
                  this.navigateToDetail(card)
                }
              })
            }, (account: MihoyoAccountVM) => account.accountId.toString())
            Row().height(this.tm.current.value40)
          }
          .width(this.tm.current.widthFull)
          .padding({ top: this.tm.current.value16 })
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Top)
      }
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .backgroundColor(this.tm.current.colorPageBg)
  }

  @Builder
  private buildErrorView(): void {
    Column({ space: this.tm.current.value12 }) {
      Text($r('app.string.home_error_retry'))
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.widthFull)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.vm.loadData()
    })
  }

  /** 根据 gameId 跳转到对应详情页 */
  private navigateToDetail(card: GameRoleCardVM): void {
    if (card.gameId === 'genshin') {
      const param = new GenshinDailyDetailParam()
      param.gameId = card.gameId
      param.roleUid = card.roleUid
      HMRouterMgr.push({ pageUrl: AppRoutes.GENSHIN_DAILY_DETAIL, param: param })
      return
    }
    // 其他游戏详情页待实现
    Logger.info('Home', `no detail page for gameId: ${card.gameId}`)
  }
}
