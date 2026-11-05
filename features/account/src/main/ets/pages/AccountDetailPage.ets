/**
 * AccountDetailPage — 账号详情二级页
 */
import { themeManager, ThemeManager, AccountSignal, CookieExpiredSignal, AppRoutes, showFeedback, FeedbackType } from 'basic'
import { Logger } from 'core'
import { MyAccountVM } from '../model/MyModels'
import { SectionHeader } from '../views/SectionHeader'
import { AccountHeaderCard } from '../views/AccountHeaderCard'
import { AccountRolesSection } from '../views/AccountRolesSection'
import { AccountActionsSection } from '../views/AccountActionsSection'
import { AccountDetailViewModel, RefreshCookieResult } from '../viewmodel/AccountDetailViewModel'
import { common } from '@kit.AbilityKit'

const TAG: string = 'AccountDetail'

@ComponentV2
export struct AccountDetailPage {
  @Param account: MyAccountVM = new MyAccountVM('', '', [])
  @Local private tm: ThemeManager = themeManager
  @Local private vm: AccountDetailViewModel = new AccountDetailViewModel()
  /** 全局过期账号名单（@Trace，账号刷新 / 重新登录成功后会自动更新） */
  @Local private expiredSignal: CookieExpiredSignal = CookieExpiredSignal.getInstance()
  private localStack: NavPathStack | null = null

  @Monitor('vm.isDeleted')
  onDeleted(_monitor: IMonitor): void {
    if (!this.vm.isDeleted) { return }
    // 通知所有 Tab 账号数据已变更（HomePage / CharactersPage / MyPage 会自动重新加载）
    AccountSignal.getInstance().notify()
    if (this.localStack !== null) {
      this.localStack.pop()
    }
  }

  @Monitor('vm.refreshCookieResult')
  onRefreshCookieResult(_monitor: IMonitor): void {
    const result = this.vm.refreshCookieResult
    if (result === RefreshCookieResult.NONE) { return }
    this.vm.refreshCookieResult = RefreshCookieResult.NONE
    this.showActionResult(result,
      $r('app.string.account_detail_refresh_cookie_success'),
      $r('app.string.account_detail_refresh_cookie_failed'))
  }

  @Monitor('vm.regenerateFpResult')
  onRegenerateFpResult(_monitor: IMonitor): void {
    const result = this.vm.regenerateFpResult
    if (result === RefreshCookieResult.NONE) { return }
    this.vm.regenerateFpResult = RefreshCookieResult.NONE
    this.showActionResult(result,
      $r('app.string.device_fp_regenerate_success'),
      $r('app.string.device_fp_regenerate_failed'))
  }

  /** 统一把操作结果转成 Toast 提示（刷新 Cookie / 重新生成设备指纹共用） */
  private showActionResult(result: RefreshCookieResult, success: Resource, failed: Resource): void {
    if (result === RefreshCookieResult.SUCCESS) {
      showFeedback(this.getUIContext(), FeedbackType.SUCCESS, success)
    } else {
      showFeedback(this.getUIContext(), FeedbackType.ERROR, failed)
    }
  }

  /** 该账号是否已过期 */
  private isExpired(): boolean {
    return this.expiredSignal.expiredUsernames.includes(this.account.username)
  }

  @Monitor('vm.errorMsg')
  onError(_monitor: IMonitor): void {
    const msg = this.vm.errorMsg
    if (msg === '') { return }
    Logger.error(TAG, `deleteAccount error: ${msg}`)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: this.tm.current.font20 }) {
          AccountHeaderCard({ account: this.account })

          SectionHeader({ title: $r('app.string.account_detail_section_roles') })
          AccountRolesSection({ roles: this.account.roles })

          SectionHeader({ title: $r('app.string.account_detail_section_actions') })
          if (this.isExpired()) {
            Text($r('app.string.account_detail_expired_tip'))
              .fontSize(this.tm.current.font13)
              .fontColor(this.tm.current.colorDanger)
              .width(this.tm.current.full)
          }
          AccountActionsSection({
            isExpired: this.isExpired(),
            isRefreshingCookie: this.vm.isRefreshingCookie,
            // 重新登录：与正常登录流程一致；登录成功后 LoginViewModel 会清除过期标记
            onRelogin: () => { this.localStack?.pushPathByName(AppRoutes.LOGIN, null) },
            onRefreshCookie: () => { this.vm.refreshCookie(this.account.username) },
            isRegeneratingFp: this.vm.isRegeneratingFp,
            onRegenerateFp: () => {
              this.vm.regenerateDeviceFp(this.getUIContext().getHostContext() as common.UIAbilityContext)
            },
            onDelete: () => { this.vm.deleteAccount(this.account.accountId) }
          })

          Row().height(this.tm.current.value40)
        }
        .width(this.tm.current.full)
        .padding({
          top: this.tm.current.value12,
          left: this.tm.current.font20,
          right: this.tm.current.font20
        })
      }
      .scrollBar(BarState.Off)
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .align(Alignment.Top)
      .backgroundColor(this.tm.current.colorPageBg)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      .edgeEffect(EdgeEffect.Spring)
    }
    .title($r('app.string.account_detail_title'))
    .hideTitleBar(false)
    .onReady((ctx: NavDestinationContext) => {
      this.localStack = ctx.pathStack
    })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct AccountDetailPagePreview {
  build() {
    AccountDetailPage({
      account: new MyAccountVM('uid001', 'user001', [], '旅行者', '')
    })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function AccountDetailPageBuilder(_name: string, param: Object) {
  AccountDetailPage({ account: param as MyAccountVM })
}
