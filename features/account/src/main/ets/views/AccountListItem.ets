/**
 * AccountListItem — 账号列表单行
 */
import { themeManager, ThemeManager, ThemeFonts } from 'basic'
import { MyAccountVM } from '../model/MyModels'

@ComponentV2
export struct AccountListItem {
  @Param account: MyAccountVM = new MyAccountVM('', '', [], '', '')
  @Param onTap: (account: MyAccountVM) => void = (_a: MyAccountVM) => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.value12 }) {
      if (this.account.avatarUrl !== '') {
        Image(this.account.avatarUrl)
          .width(this.tm.current.value36)
          .height(this.tm.current.value36)
          .borderRadius(this.tm.current.radius12)
          .objectFit(ImageFit.Cover)
          .border({ width: this.tm.current.value2, color: this.tm.current.colorPrimary })
      } else {
        Row()
          .width(this.tm.current.value36)
          .height(this.tm.current.value36)
          .borderRadius(this.tm.current.radius12)
          .backgroundColor(this.tm.current.colorPrimary)
      }

      Column({ space: this.tm.current.value2 }) {
        Text(this.account.nickname !== '' ? this.account.nickname : this.account.username)
          .font(ThemeFonts.FONT_MEDIUM_17)
          .fontColor(this.tm.current.colorTextPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text($r('app.string.my_account_role_count', this.account.roles.length))
          .font(ThemeFonts.FONT_14)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text($r('app.string.common_arrow_right'))
        .font(ThemeFonts.FONT_17)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.font16,
      right: this.tm.current.font16,
      top: this.tm.current.value12,
      bottom: this.tm.current.value12
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .onClick(() => { this.onTap(this.account) })
  }
}
