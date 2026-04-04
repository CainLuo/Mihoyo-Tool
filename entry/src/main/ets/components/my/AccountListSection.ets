/**
 * AccountListSection — 账号列表 Section
 *
 * 展示已登录账号列表，底部附带"添加账号"按钮。
 * My 页和 Setting 页均可复用。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { MyAccountVM, MyGameRoleVM } from './MyModels'

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
          Column() {
            Row({ space: this.tm.current.value12 }) {
              if (account.avatarUrl !== '') {
                Image(account.avatarUrl)
                  .width(this.tm.current.value36)
                  .height(this.tm.current.value36)
                  .borderRadius(this.tm.current.radius12)
                  .objectFit(ImageFit.Cover)
                  .border({ width: 2, color: this.tm.current.colorPrimary })
              } else {
                Row()
                  .width(this.tm.current.value36)
                  .height(this.tm.current.value36)
                  .borderRadius(this.tm.current.radius12)
                  .backgroundColor(this.tm.current.colorPrimary)
              }
              Column({ space: this.tm.current.value2 }) {
                Text(account.nickname !== '' ? account.nickname : account.username)
                  .font(this.tm.current.body16Medium)
                  .fontColor(this.tm.current.colorTextPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text('UID ' + account.username + ' · ' + account.roles.length.toString() + ' 个游戏角色')
                  .font(this.tm.current.body13)
                  .fontColor(this.tm.current.colorTextSecondary)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text($r('app.string.common_arrow_right'))
                .font(this.tm.current.body16)
                .fontColor(this.tm.current.colorTextSecondary)
            }
            .width(this.tm.current.full)
            .padding({
              left: this.tm.current.value16,
              right: this.tm.current.value16,
              top: this.tm.current.value12,
              bottom: this.tm.current.value12
            })
            .alignItems(VerticalAlign.Center)
            .onClick(() => { this.onAccountTap(account) })
          }
          .width(this.tm.current.full)
          .backgroundColor(this.tm.current.colorSurfaceCard)

          if (idx < this.accounts.length - 1) {
            Divider().color(this.tm.current.colorDivider).margin({ left: this.tm.current.value16 })
          }
        }, (account: MyAccountVM) => `${account.accountId}_${account.roles.length}`)
      }

      Divider().color(this.tm.current.colorDivider)
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
struct AccountListSectionPreview {
  build() {
    Column({ space: 16 }) {
      // 有账号
      AccountListSection({
        accounts: [
          new MyAccountVM(1, 'user001', [
            new MyGameRoleVM('genshin', $r('app.string.game_name_genshin'), $r('app.color.game_color_genshin'), '123456789', '旅行者', '天空岛', 60, '', [])
          ], '旅行者', ''),
          new MyAccountVM(2, 'user002', [], '开拓者', '')
        ]
      })
      // 空账号
      AccountListSection({ accounts: [] })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
