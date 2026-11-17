/**
 * AccountActionsSection — 账号详情页操作区块
 *
 * 账号已过期时：重新登录、刷新 Cookie；始终显示：重新生成设备指纹、删除此账号。
 */
import { themeManager, ThemeManager } from 'basic'

@ComponentV2
export struct AccountActionsSection {
  /** 账号是否已过期（决定是否显示"重新登录 / 刷新 Cookie"） */
  @Param isExpired: boolean = false
  /** 是否正在刷新 Cookie（按钮显示"刷新中…"并禁用） */
  @Param isRefreshingCookie: boolean = false
  @Param onRelogin: () => void = () => {}
  @Param onRefreshCookie: () => void = () => {}
  /** 是否正在重新生成设备指纹（按钮显示"重新生成中…"并禁用） */
  @Param isRegeneratingFp: boolean = false
  @Param onRegenerateFp: () => void = () => {}
  @Param onDelete: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  /** 操作按钮统一样式：文案 / 前景色 / 是否可用 / 点击回调 */
  @Builder
  actionButton(label: ResourceStr, color: ResourceColor, enabled: boolean, onTap: () => void) {
    Button(label, { type: ButtonType.Normal })
      .fontSize(this.tm.current.font17)
      .fontWeight(FontWeight.Normal)
      .fontColor(color)
      .width(this.tm.current.full)
      .height(this.tm.current.value50)
      .backgroundColor(this.tm.current.colorSurfaceCard)
      .enabled(enabled)
      .onClick(() => { onTap() })
  }

  build() {
    Column() {
      if (this.isExpired) {
        this.actionButton($r('app.string.account_detail_relogin'), this.tm.current.colorPrimary, true, this.onRelogin)

        Divider().color(this.tm.current.colorDivider)

        this.actionButton(
          this.isRefreshingCookie
            ? $r('app.string.account_detail_refreshing_cookie')
            : $r('app.string.account_detail_refresh_cookie'),
          this.tm.current.colorPrimary, !this.isRefreshingCookie, this.onRefreshCookie)

        Divider().color(this.tm.current.colorDivider)
      }

      // 设备指纹全 App 共用（5003 / 10041 设备指纹无效时使用），不论账号是否过期都显示
      this.actionButton(
        this.isRegeneratingFp
          ? $r('app.string.device_fp_regenerating')
          : $r('app.string.device_fp_regenerate'),
        this.tm.current.colorPrimary, !this.isRegeneratingFp, this.onRegenerateFp)

      Divider().color(this.tm.current.colorDivider)

      this.actionButton($r('app.string.account_detail_delete'), this.tm.current.colorDanger, true, this.onDelete)
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
