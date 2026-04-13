/**
 * AccountDetail — 账号详情二级页
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { Logger } from 'core'
import { MyAccountVM } from '../components/my/MyModels'
import { SectionHeader } from '../components/my/SectionHeader'
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
          Row({ space: this.tm.current.value16 }) {
            if (this.account.avatarUrl !== '') {
              Image(this.account.avatarUrl)
                .width(this.tm.current.value36 + this.tm.current.value20)
                .height(this.tm.current.value36 + this.tm.current.value20)
                .borderRadius(this.tm.current.radius16)
                .objectFit(ImageFit.Cover)
                .border({ width: 2, color: this.tm.current.colorPrimary })
            } else {
              Row()
                .width(this.tm.current.value36 + this.tm.current.value20)
                .height(this.tm.current.value36 + this.tm.current.value20)
                .borderRadius(this.tm.current.radius16)
                .backgroundColor(this.tm.current.colorPrimary)
            }
            Column({ space: this.tm.current.value4 }) {
              Text(this.account.nickname !== '' ? this.account.nickname : this.account.username)
                .font(this.tm.current.title18Bold)
                .fontColor(this.tm.current.colorTextPrimary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text('UID ' + (this.account.uid !== '' ? this.account.uid : this.account.username) + ' · ' + this.account.roles.length.toString() + ' 个游戏角色')
                .font(this.tm.current.body13)
                .fontColor(this.tm.current.colorTextSecondary)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width(this.tm.current.full)
          .padding({
            left: this.tm.current.value16,
            right: this.tm.current.value16,
            top: this.tm.current.value16,
            bottom: this.tm.current.value16
          })
          .backgroundColor(this.tm.current.colorSurfaceCard)
          .borderRadius(this.tm.current.radius12)

          SectionHeader({ title: $r('app.string.account_detail_section_roles') })
          AccountRolesSection({ tm: this.tm, roles: this.account.roles })

          SectionHeader({ title: $r('app.string.account_detail_section_actions') })
          AccountActionsSection({
            tm: this.tm,
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
      .edgeEffect(EdgeEffect.Spring)
    }
    .title($r('app.string.account_detail_title'))
    .hideTitleBar(false)
    .onReady((ctx: NavDestinationContext) => {
      this.localStack = ctx.pathStack
    })
  }
}
