/**
 * TestPage — 测试工具页（仅 Mock / Debug 环境可见）
 *
 * 集中所有手动测试场景，通过 My 页右上角入口进入。
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { CoreInitializer, FailedAccountInfo } from 'core'
import { CookieExpiredSignal } from '../utils/CookieExpiredSignal'

@ComponentV2
export struct TestPage {
  @Local private tm: ThemeManager = themeManager

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: this.tm.current.value8 }) {
          // ── Cookie 刷新测试 ──────────────────────────────────────
          this.SectionHeader('Cookie 刷新 / 过期')
          this.TestRow(
            'T1：设置 update_time 为 8 天前（有 stoken）',
            '重启 App 后触发冷启动静默刷新',
            () => { this.onTestT1() }
          )
          this.TestRow(
            'T2：直接触发 Cookie 过期 Dialog',
            '立即弹出登录过期提示，验证 UI 和跳转',
            () => { this.onTestT2() }
          )
          this.TestRow(
            'T3：设置 update_time 为 8 天前（无 stoken）',
            '重启 App 后静默跳过，无任何提示',
            () => { this.onTestT3() }
          )

          Row().height(this.tm.current.value40)
        }
        .width(this.tm.current.full)
        .padding({
          top: this.tm.current.value16,
          left: this.tm.current.value20,
          right: this.tm.current.value20,
        })
      }
      .scrollBar(BarState.Off)
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor(this.tm.current.colorPageBg)
    }
    .title($r('app.string.test_page_title'))
    .hideTitleBar(false)
  }

  @Builder
  private SectionHeader(title: string) {
    Text(title)
      .font(this.tm.current.body13)
      .fontColor(this.tm.current.colorTextSecondary)
      .width(this.tm.current.full)
      .padding({
        top: this.tm.current.value8,
        bottom: this.tm.current.value4,
        left: this.tm.current.value4,
      })
  }

  @Builder
  private TestRow(title: string, desc: string, onTap: () => void) {
    Row() {
      Column({ space: this.tm.current.value4 }) {
        Text(title)
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextPrimary)
          .width(this.tm.current.full)
        Text(desc)
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.full)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text($r('app.string.common_arrow_right'))
        .font(this.tm.current.body16)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .padding({
      top: this.tm.current.value12,
      bottom: this.tm.current.value12,
      left: this.tm.current.value16,
      right: this.tm.current.value16,
    })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .onClick(onTap)
  }

  // ── 测试逻辑 ─────────────────────────────────────────────────

  private onTestT1(): void {
    CoreInitializer.bbsRepository.setAllUpdateTimeTo8DaysAgo()
      .then(() => {
        this.getUIContext().getPromptAction().showToast({ message: 'T1 已设置，请重启 App' })
      })
      .catch((_: Error | object) => {
        this.getUIContext().getPromptAction().showToast({ message: 'T1 设置失败，请查看日志' })
      })
  }

  private onTestT2(): void {
    const fakeInfo = new FailedAccountInfo()
    fakeInfo.nickname = '测试账号'
    fakeInfo.username = '182692936'
    fakeInfo.isNetworkError = false
    CookieExpiredSignal.instance().push(fakeInfo)
  }

  private onTestT3(): void {
    CoreInitializer.bbsRepository.setAllCookieWithoutStoken()
      .then(() => {
        this.getUIContext().getPromptAction().showToast({ message: 'T3 已设置，请重启 App' })
      })
      .catch((_: Error | object) => {
        this.getUIContext().getPromptAction().showToast({ message: 'T3 设置失败，请查看日志' })
      })
  }
}
