/**
 * AccountRolesSection — 账号详情页角色列表区块
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { MyGameRoleVM } from '../my/MyModels'

@ComponentV2
export struct AccountRolesSection {
  @Param tm: ThemeManager = new ThemeManager()
  @Param roles: MyGameRoleVM[] = []

  build() {
    Column() {
      if (this.roles.length === 0) {
        Row() {
          Text($r('app.string.my_account_empty'))
            .font(this.tm.current.body16)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightButton)
        .justifyContent(FlexAlign.Center)
        .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
      } else {
        ForEach(this.roles, (role: MyGameRoleVM, idx: number) => {
          Column() {
            Row({ space: this.tm.current.value12 }) {
              Row()
                .width(this.tm.current.gameBarWidth)
                .height(this.tm.current.gameBarHeightSM)
                .borderRadius(this.tm.current.gameBarRadius)
                .backgroundColor(role.gameColor)
              Column({ space: this.tm.current.value2 }) {
                Text(role.gameName)
                  .font(this.tm.current.body16Medium)
                  .fontColor(this.tm.current.colorTextPrimary)
                  .maxLines(1)
                Row({ space: this.tm.current.value8 }) {
                  Text(role.nickname)
                    .font(this.tm.current.body13)
                    .fontColor(this.tm.current.colorTextSecondary)
                  Text($r('app.string.account_detail_uid_prefix') + role.roleUid)
                    .font(this.tm.current.body13)
                    .fontColor(this.tm.current.colorTextSecondary)
                  Text(role.server)
                    .font(this.tm.current.body13)
                    .fontColor(this.tm.current.colorTextSecondary)
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width(this.tm.current.widthFull)
            .padding({
              left: this.tm.current.value16,
              right: this.tm.current.value16,
              top: this.tm.current.value12,
              bottom: this.tm.current.value12
            })
            .alignItems(VerticalAlign.Center)

            if (idx < this.roles.length - 1) {
              Divider()
                .color(this.tm.current.colorDivider)
                .margin({ left: this.tm.current.value16 })
            }
          }
          .width(this.tm.current.widthFull)
        })
      }
    }
    .width(this.tm.current.widthFull)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
  }
}
