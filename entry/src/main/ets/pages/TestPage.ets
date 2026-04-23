/**
 * TestPage — 测试工具页（仅 Mock / Debug 环境可见）
 *
 * 集中所有手动测试场景，通过 My 页右上角入口进入。
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { CoreInitializer, FailedAccountInfo } from 'core'
import { CookieExpiredSignal } from '../utils/CookieExpiredSignal'
import { TestSectionHeader } from '../components/TestSectionHeader'
import { TestRow } from '../components/TestRow'

@ComponentV2
export struct TestPage {
  @Local private tm: ThemeManager = themeManager

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: this.tm.current.value8 }) {
          TestSectionHeader({ title: 'Cookie 刷新 / 过期' })

          TestRow({
            title: 'T1：设置 update_time 为 8 天前（有 stoken）',
            desc: '重启 App 后触发冷启动静默刷新',
            onTap: () => { this.onTestT1() }
          })

          TestRow({
            title: 'T2：直接触发 Cookie 过期 Dialog',
            desc: '立即弹出登录过期提示，验证 UI 和跳转',
            onTap: () => { this.onTestT2() }
          })

          TestRow({
            title: 'T3：设置 update_time 为 8 天前（无 stoken）',
            desc: '重启 App 后静默跳过，无任何提示',
            onTap: () => { this.onTestT3() }
          })

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

  // ── 测试逻辑 ─────────────────────────────────────────────────

  private onTestT1(): void {
    CoreInitializer.bbsRepository.setAllUpdateTimeTo8DaysAgo()
      .then(() => {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.test_t1_done') })
      })
      .catch((_: Error | object) => {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.test_failed') })
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
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.test_t3_done') })
      })
      .catch((_: Error | object) => {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.test_failed') })
      })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct TestPagePreview {
  build() {
    TestPage()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function TestPageBuilder(_name: string, _param: Object) {
  TestPage()
}
