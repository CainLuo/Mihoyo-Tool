/**
 * Home — 首页（View 层）
 *
 * 遵循 MVVM 架构规范（见 harmonyos-rules.md 第八节）：
 *   - 只负责渲染，不含业务逻辑
 *   - 通过 @Local 持有 HomeViewModel，@Trace 字段变更自动驱动 UI 刷新
 *
 * 状态机（由 HomeViewModel.viewState 驱动）：
 *   loading  — 冷启动加载，显示 Skeleton
 *   empty    — 无绑定账号或无战绩数据，显示 Placeholder
 *   data     — 正常展示账号战绩列表（右上角显示刷新按钮）
 *
 * 副作用监听：
 *   vm.networkErrorMsg  — 非空时弹系统 Alert 提示网络失败，弹完后清空
 *   vm.geetestTrigger   — 非 null 时弹 GeetestDialog，完成后调用 vm.onGeetestResult()
 */

import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { HomeViewModel } from '../viewmodel/HomeViewModel'
import { MihoyoAccountVM, GameRoleCardVM } from '../components/home/HomeModels'
import { UserGameSection } from '../components/home/UserGameSection'
import { HomeSkeletonView } from '../components/home/HomeSkeletonView'
import { HomePlaceholderView } from '../components/home/HomePlaceholderView'
import { showGeetestDialog } from '../components/GeetestDialog'
import { Logger } from '../utils/Logger'
import { HMRouterMgr } from '@hadss/hmrouter'
import { AppRoutes } from '../constants/AppRoutes'
import { GenshinDailyDetailParam } from './GenshinDailyDetail'
import { ViewState } from '../constants/ViewStates'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct Home {
  @Local private tm: ThemeManager = themeManager
  @Local private vm: HomeViewModel = new HomeViewModel()
  private uiCtx: UIContext | null = null

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.vm.loadData()
  }

  aboutToDisappear(): void {
    this.vm.dispose()
  }

  @Monitor(HomeViewModel.KEYS.networkErrorMsg)
  onNetworkErrorChanged(_monitor: IMonitor): void {
    const msg = this.vm.networkErrorMsg
    if (msg === '') {
      return
    }
    this.vm.networkErrorMsg = ''
    const ctx = this.uiCtx
    if (ctx === null) {
      return
    }
    ctx.getPromptAction().showDialog({
      title: $r('app.string.home_network_error_title'),
      message: msg,
      buttons: [{ text: $r('app.string.dialog_confirm'), color: $r('app.color.color_accent') }]
    }).catch((e: BusinessError) => {
      Logger.warn('Home', 'showDialog failed: ' + e.message)
    })
  }

  @Monitor(HomeViewModel.KEYS.geetestTrigger)
  onGeetestTriggerChanged(_monitor: IMonitor): void {
    const trigger = this.vm.geetestTrigger
    if (trigger === null) {
      return
    }
    const ctx = this.uiCtx
    if (ctx === null) {
      return
    }
    showGeetestDialog(ctx, trigger.createResult).then((result) => {
      this.vm.onGeetestResult(result)
    }).catch((e: BusinessError) => {
      Logger.error('Home', 'showGeetestDialog failed: ' + e.message)
      this.vm.onGeetestResult(null)
    })
  }

  build() {
    Column() {
      // ── 顶部导航栏 ──────────────────────────────────────────
      Row() {
        Text($r('app.string.home_title'))
          .font(this.tm.current.title24Bold)
          .fontColor(this.tm.current.colorTextPrimary)
          .padding({ left: this.tm.current.value16 })
          .layoutWeight(1)

        // 刷新按钮：仅在 data 状态显示
        if (this.vm.viewState === ViewState.DATA) {
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
      if (this.vm.viewState === ViewState.LOADING) {
        HomeSkeletonView()
      } else if (this.vm.viewState === ViewState.EMPTY) {
        HomePlaceholderView()
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
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .align(Alignment.Top)
      }
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .backgroundColor(this.tm.current.colorPageBg)
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
    Logger.info('Home', `no detail page for gameId: ${card.gameId}`)
  }
}
