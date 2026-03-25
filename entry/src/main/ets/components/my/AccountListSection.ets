/**
 * AccountListSection — 账号列表 Section
 *
 * 展示已登录账号列表，底部附带"添加账号"按钮。
 * My 页和 Setting 页均可复用。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { MyAccountVM } from './MyModels'

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
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightButton)
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.accounts, (account: MyAccountVM, idx: number) => {
          Column() {
            Row({ space: this.tm.current.value12 }) {
              Row()
                .width(this.tm.current.avatarSizeMD)
                .height(this.tm.current.avatarSizeMD)
                .borderRadius(this.tm.current.avatarRadius)
                .backgroundColor(this.tm.current.colorPrimary)
              Column({ space: this.tm.current.value2 }) {
                Text(account.username)
                  .font(this.tm.current.body16Medium)
                  .fontColor(this.tm.current.colorTextPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text($r('app.string.my_account_role_count', account.roles.length))
                  .font(this.tm.current.body13)
                  .fontColor(this.tm.current.colorTextSecondary)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text($r('app.string.common_arrow_right'))
                .font(this.tm.current.body16)
                .fontColor(this.tm.current.colorTextSecondary)
            }
            .width(this.tm.current.widthFull)
            .padding({
              left: this.tm.current.value16,
              right: this.tm.current.value16,
              top: this.tm.current.value12,
              bottom: this.tm.current.value12
            })
            .alignItems(VerticalAlign.Center)
            .onClick(() => { this.onAccountTap(account) })
          }
          .width(this.tm.current.widthFull)
          .backgroundColor(this.tm.current.colorSurfaceCard)

          if (idx < this.accounts.length - 1) {
            Divider().color(this.tm.current.colorDivider).margin({ left: this.tm.current.value16 })
          }
        })
      }

      Divider().color(this.tm.current.colorDivider)
      Button($r('app.string.my_account_add'), { type: ButtonType.Normal })
        .fontSize(this.tm.current.body16.size)
        .fontWeight(this.tm.current.body16.weight)
        .fontColor(this.tm.current.colorPrimary)
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightButton)
        .backgroundColor(this.tm.current.colorSurfaceCard)
        .onClick(() => { this.onAddTap() })
    }
    .width(this.tm.current.widthFull)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
  }
}
