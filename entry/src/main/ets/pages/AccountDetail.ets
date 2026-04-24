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
import { AccountDetailViewModel } from '../viewmodel/AccountDetailViewModel'
import { AccountSignal } from '../utils/AccountSignal'

const TAG: string = 'AccountDetail'

@ComponentV2
export struct AccountDetail {
  @Param account: MyAccountVM = new MyAccountVM('', '', [])
  @Local private tm: ThemeManager = themeManager
  @Local private vm: AccountDetailViewModel = new AccountDetailViewModel()
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

  @Monitor('vm.errorMsg')
  onError(_monitor: IMonitor): void {
    const msg = this.vm.errorMsg
    if (msg === '') { return }
    Logger.error(TAG, `deleteAccount error: ${msg}`)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: this.tm.current.value20 }) {
          AccountHeaderCard({ account: this.account })

          SectionHeader({ title: $r('app.string.account_detail_section_roles') })
          AccountRolesSection({ roles: this.account.roles })

          SectionHeader({ title: $r('app.string.account_detail_section_actions') })
          AccountActionsSection({
            onDelete: () => { this.vm.deleteAccount(this.account.accountId) }
          })

          Row().height(this.tm.current.value40)
        }
        .width(this.tm.current.full)
        .padding({
          top: this.tm.current.value12,
          left: this.tm.current.value20,
          right: this.tm.current.value20
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
