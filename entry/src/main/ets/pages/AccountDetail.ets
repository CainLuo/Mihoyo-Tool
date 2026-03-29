/**
 * AccountDetail — 账号详情二级页
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { AccountRepository } from 'core'
import { Logger } from '../utils/Logger'
import { MyAccountVM } from '../components/my/MyModels'
import { RouterUtil } from '../utils/RouterUtil'
import { SectionHeader } from '../components/my/SectionHeader'
import { AccountRolesSection } from '../components/accountdetail/AccountRolesSection'
import { AccountActionsSection } from '../components/accountdetail/AccountActionsSection'

const TAG: string = 'AccountDetail'

@ComponentV2
export struct AccountDetail {
  @Param account: MyAccountVM = new MyAccountVM(0, '', [])
  @Local private tm: ThemeManager = themeManager
  private localStack: NavPathStack | null = null

  private async deleteAccount(): Promise<void> {
    try {
      await AccountRepository.deleteAccount(this.account.accountId)
      Logger.info(TAG, `account deleted: ${this.account.accountId}`)
      if (this.localStack !== null) {
        this.localStack.pop()
      } else {
        RouterUtil.pop()
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error(TAG, `deleteAccount failed: ${msg}`)
    }
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
              Text('UID ' + this.account.username + ' · ' + this.account.roles.length.toString() + ' 个游戏角色')
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
            onDelete: () => { this.deleteAccount() }
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
