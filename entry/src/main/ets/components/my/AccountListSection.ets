/**
 * AccountListSection — 账号列表 Section
 *
 * 展示已登录账号列表，底部附带"添加账号"按钮。
 * My 页和 Setting 页均可复用。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { MyAccountVM, MyGameRoleVM } from '../../models/MyModels'
import { GameId } from 'core'
import { AccountListItem } from './AccountListItem'

@ComponentV2
export struct AccountListSection {
  @Param accounts: MyAccountVM[] = []
  @Param onAccountTap: (account: MyAccountVM) => void = (_a: MyAccountVM) => {}
  @Param onAddTap: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      if (this.accounts.length === 0) {
        Row() {
          Text($r('app.string.my_account_empty'))
            .font(this.tm.current.body16)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .width(this.tm.current.full)
        .height(this.tm.current.value50)
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.accounts, (account: MyAccountVM, idx: number) => {
          AccountListItem({
            account: account,
            onTap: (a: MyAccountVM) => { this.onAccountTap(a) }
          })

          if (idx < this.accounts.length - 1) {
            Divider()
              .color(this.tm.current.colorDivider)
              .margin({ left: this.tm.current.value16 })
          }
        }, (account: MyAccountVM) => account.accountId)
      }

      Divider()
        .color(this.tm.current.colorDivider)

      Button($r('app.string.my_account_add'), { type: ButtonType.Normal })
        .fontSize(this.tm.current.body16.size)
        .fontWeight(this.tm.current.body16.weight)
        .fontColor(this.tm.current.colorPrimary)
        .width(this.tm.current.full)
        .height(this.tm.current.value50)
        .backgroundColor(this.tm.current.colorSurfaceCard)
        .onClick(() => { this.onAddTap() })
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct AccountListSectionPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value16 }) {
      AccountListSection({
        accounts: [
          new MyAccountVM('user001', 'user001', [
            new MyGameRoleVM(GameId.GENSHIN, $r('app.string.game_name_genshin'), $r('app.color.game_color_genshin'), '123456789', '旅行者', '天空岛', 60, '', [])
          ], '旅行者', ''),
          new MyAccountVM('user002', 'user002', [], '开拓者', '')
        ]
      })

      AccountListSection({ accounts: [] })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
