/**
 * AccountHeaderCard — 账号详情页顶部信息卡片
 *
 * 展示账号头像、昵称/username、UID 和游戏角色数量。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeFonts } from '../../theme/ThemeFonts'
import { MyAccountVM } from '../../models/MyModels'

@ComponentV2
export struct AccountHeaderCard {
  @Param account: MyAccountVM = new MyAccountVM('', '', [])
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.font16 }) {
      if (this.account.avatarUrl !== '') {
        Image(this.account.avatarUrl)
          .width(this.tm.current.value56)
          .height(this.tm.current.value56)
          .borderRadius(this.tm.current.radius16)
          .objectFit(ImageFit.Cover)
          .border({ width: this.tm.current.value2, color: this.tm.current.colorPrimary })
      } else {
        Row()
          .width(this.tm.current.value56)
          .height(this.tm.current.value56)
          .borderRadius(this.tm.current.radius16)
          .backgroundColor(this.tm.current.colorPrimary)
      }
      Column({ space: this.tm.current.value4 }) {
        Text(this.account.nickname !== '' ? this.account.nickname : this.account.username)
          .font(ThemeFonts.fontBold18)
          .fontColor(this.tm.current.colorTextPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text($r('app.string.my_account_role_count', this.account.roles.length))
          .font(ThemeFonts.font14)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.font16,
      right: this.tm.current.font16,
      top: this.tm.current.font16,
      bottom: this.tm.current.font16
    })
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct AccountHeaderCardPreview {
  build() {
    Column() {
      AccountHeaderCard({
        account: new MyAccountVM('uid001', 'user001', [], '旅行者', '')
      })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
