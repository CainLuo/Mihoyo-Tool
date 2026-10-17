/**
 * AccountDetail — 账号详情二级页
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { Logger } from 'core'
import { MyAccountVM } from '../models/MyModels'
import { SectionHeader } from '../components/my/SectionHeader'
import { AccountHeaderCard } from '../components/accountdetail/AccountHeaderCard'
import { AccountRolesSection } from '../components/accountdetail/AccountRolesSection'
import { AccountActionsSection } from '../components/accountdetail/AccountActionsSection'
import { AccountDetailViewModel, RefreshCookieResult } from '../viewmodel/AccountDetailViewModel'
import { AccountSignal } from '../utils/AccountSignal'
import { CookieExpiredSignal } from '../utils/CookieExpiredSignal'
import { AppRoutes } from '../constants/AppRoutes'
import { showFeedback } from '../utils/FeedbackUtil'
import { FeedbackType } from '../constants/FeedbackType'

const TAG: string = 'AccountDetail'

@ComponentV2
export struct AccountDetail {
  @Param account: MyAccountVM = new MyAccountVM('', '', [])
  @Local private tm: ThemeManager = themeManager
  @Local private vm: AccountDetailViewModel = new AccountDetailViewModel()
  /** 全局过期账号名单（@Trace，账号刷新 / 重新登录成功后会自动更新） */
  @Local private expiredSignal: CookieExpiredSignal = CookieExpiredSignal.instance()
  private localStack: NavPathStack | null = null

  @Monitor('vm.deleted')
  onDeleted(_monitor: IMonitor): void {
    if (!this.vm.deleted) { return }
    // 通知所有 Tab 账号数据已变更（Home / Characters / My 会自动重新加载）
    AccountSignal.instance().notify()
    if (this.localStack !== null) {
      this.localStack.pop()
    }
  }

  @Monitor('vm.refreshCookieResult')
  onRefreshCookieResult(_monitor: IMonitor): void {
    const result = this.vm.refreshCookieResult
    if (result === RefreshCookieResult.NONE) { return }
    this.vm.refreshCookieResult = RefreshCookieResult.NONE
    if (result === RefreshCookieResult.SUCCESS) {
      showFeedback(this.getUIContext(), FeedbackType.SUCCESS, $r('app.string.account_detail_refresh_cookie_success'))
    } else {
      // stoken 不存在或已失效，只能重新登录
      showFeedback(this.getUIContext(), FeedbackType.ERROR, $r('app.string.account_detail_refresh_cookie_failed'))
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
export struct AccountDetailPreview {
  build() {
    AccountDetail({
      account: new MyAccountVM('uid001', 'user001', [], '旅行者', '')
    })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function AccountDetailBuilder(_name: string, param: Object) {
  AccountDetail({ account: param as MyAccountVM })
}
