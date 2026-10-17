/**
 * AccountActionsSection — 账号详情页操作区块
 *
 * 账号已过期时：重新登录、刷新 Cookie、删除此账号；未过期时只有删除此账号。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct AccountActionsSection {
  /** 账号是否已过期（决定是否显示"重新登录 / 刷新 Cookie"） */
  @Param isExpired: boolean = false
  /** 是否正在刷新 Cookie（按钮显示"刷新中…"并禁用） */
  @Param isRefreshingCookie: boolean = false
  @Param onRelogin: () => void = () => {}
  @Param onRefreshCookie: () => void = () => {}
  @Param onDelete: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      if (this.isExpired) {
        Button($r('app.string.account_detail_relogin'), { type: ButtonType.Normal })
          .fontSize(this.tm.current.font17)
          .fontWeight(FontWeight.Normal)
          .fontColor(this.tm.current.colorPrimary)
          .width(this.tm.current.full)
          .height(this.tm.current.value50)
          .backgroundColor(this.tm.current.colorSurfaceCard)
          .onClick(() => { this.onRelogin() })

        Divider().color(this.tm.current.colorDivider)

        Button(this.isRefreshingCookie
          ? $r('app.string.account_detail_refreshing_cookie')
          : $r('app.string.account_detail_refresh_cookie'), { type: ButtonType.Normal })
          .fontSize(this.tm.current.font17)
          .fontWeight(FontWeight.Normal)
          .fontColor(this.tm.current.colorPrimary)
          .width(this.tm.current.full)
          .height(this.tm.current.value50)
          .backgroundColor(this.tm.current.colorSurfaceCard)
          .enabled(!this.isRefreshingCookie)
          .onClick(() => { this.onRefreshCookie() })

        Divider().color(this.tm.current.colorDivider)
      }

      Button($r('app.string.account_detail_delete'), { type: ButtonType.Normal })
        .fontSize(this.tm.current.font17)
        .fontWeight(FontWeight.Normal)
        .fontColor(this.tm.current.colorDanger)
        .width(this.tm.current.full)
        .height(this.tm.current.value50)
        .backgroundColor(this.tm.current.colorSurfaceCard)
        .onClick(() => { this.onDelete() })
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
export struct AccountActionsSectionPreview {
  build() {
    Column() {
      AccountActionsSection()
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
