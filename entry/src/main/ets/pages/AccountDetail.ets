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

  private async deleteAccount(): Promise<void> {
    try {
      await AccountRepository.deleteAccount(this.account.accountId)
      Logger.info(TAG, `account deleted: ${this.account.accountId}`)
      RouterUtil.pop()
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error(TAG, `deleteAccount failed: ${msg}`)
    }
  }

  build() {
    Scroll() {
      Column({ space: this.tm.current.value20 }) {
        Row({ space: this.tm.current.value16 }) {
          Row()
            .width(this.tm.current.avatarSizeMD + this.tm.current.value20)
            .height(this.tm.current.avatarSizeMD + this.tm.current.value20)
            .borderRadius((this.tm.current.avatarSizeMD + this.tm.current.value20) / 2)
            .backgroundColor(this.tm.current.colorPrimary)
          Column({ space: this.tm.current.value4 }) {
            Text(this.account.username)
              .font(this.tm.current.title18Bold)
              .fontColor(this.tm.current.colorTextPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text($r('app.string.my_account_role_count', this.account.roles.length))
              .font(this.tm.current.body13)
              .fontColor(this.tm.current.colorTextSecondary)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width(this.tm.current.widthFull)
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
      .width(this.tm.current.widthFull)
      .padding({
        top: this.tm.current.value12,
        left: this.tm.current.value20,
        right: this.tm.current.value20
      })
    }
    .scrollBar(BarState.Off)
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .align(Alignment.Top)
    .backgroundColor(this.tm.current.colorPageBg)
    .edgeEffect(EdgeEffect.Spring)
  }
}
