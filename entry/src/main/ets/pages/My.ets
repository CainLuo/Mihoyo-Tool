/**
 * My — 我的页面（View 层，普通内容组件）
 */
import { ConfigurationConstant, common } from '@kit.AbilityKit'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { Logger } from 'core'
import { AppRoutes } from '../constants/AppRoutes'
import { MyAccountVM } from '../components/my/MyModels'
import { AccountListSection } from '../components/my/AccountListSection'
import { AppearanceSection } from '../components/my/AppearanceSection'
import { AboutSection } from '../components/my/AboutSection'
import { SectionHeader } from '../components/my/SectionHeader'
import { AppearanceManager } from '../utils/AppearanceManager'
import { AccountSignal } from '../utils/AccountSignal'
import { MyViewModel } from '../viewmodel/MyViewModel'

const TAG: string = 'My'

@ComponentV2
export struct My {
  @Param detailStack: NavPathStack = new NavPathStack()
  @Param isSplit: boolean = false
  @Local private tm: ThemeManager = themeManager
  @Local private vm: MyViewModel = new MyViewModel()
  @Local private themeMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  @Local private signal: AccountSignal = AccountSignal.instance()
  private uiCtx: UIContext | null = null

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.vm.loadAccounts()
    this.loadSavedColorMode()
  }

  @Monitor('signal.version')
  onAccountDataChanged(_monitor: IMonitor): void {
    this.vm.loadAccounts()
  }

  private getAbilityContext(): common.UIAbilityContext | null {
    const ctx = this.uiCtx
    if (ctx === null) { return null }
    const hostCtx = ctx.getHostContext()
    if (hostCtx === undefined) { return null }
    return hostCtx as common.UIAbilityContext
  }

  private loadSavedColorMode(): void {
    const abilityCtx = this.getAbilityContext()
    if (abilityCtx === null) { return }
    AppearanceManager.getSavedColorMode(abilityCtx).then((mode: number) => {
      this.themeMode = mode
    }).catch((_e: Error | object) => {
      this.themeMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
    })
  }

  build() {
    Scroll() {
      Column({ space: this.tm.current.value20 }) {
        SectionHeader({ title: $r('app.string.my_section_account') })
        AccountListSection({
          accounts: this.vm.accounts,
          onAccountTap: (account: MyAccountVM) => {
            if (this.isSplit) {
              this.detailStack.replacePath({ name: AppRoutes.ACCOUNT_DETAIL, param: account })
            } else {
              this.detailStack.pushPathByName(AppRoutes.ACCOUNT_DETAIL, account)
            }
          },
          onAddTap: () => {
            if (this.isSplit) {
              this.detailStack.replacePath({ name: AppRoutes.LOGIN, param: null })
            } else {
              this.detailStack.pushPathByName(AppRoutes.LOGIN, null)
            }
          }
        })

        SectionHeader({ title: $r('app.string.my_section_appearance') })
        AppearanceSection({
          themeMode: this.themeMode,
          onThemeChange: (mode: number) => {
            this.themeMode = mode
            const abilityCtx = this.getAbilityContext()
            if (abilityCtx === null) { return }
            AppearanceManager.applyColorMode(abilityCtx, mode).catch((_e: Error | object) => {
              Logger.error(TAG, 'applyColorMode failed')
            })
          }
        })

        SectionHeader({ title: $r('app.string.my_section_notification') })
        // 通知设置入口行（点击跳转二级页）
        Row() {
          Text($r('app.string.my_section_notification'))
            .font(this.tm.current.body16)
            .fontColor(this.tm.current.colorTextPrimary)
            .layoutWeight(1)
          Text($r('app.string.common_arrow_right'))
            .font(this.tm.current.body16)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .width(this.tm.current.full)
        .height(this.tm.current.value50)
        .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
        .backgroundColor(this.tm.current.colorSurfaceCard)
        .borderRadius(this.tm.current.radius12)
        .onClick(() => {
          if (this.isSplit) {
            this.detailStack.replacePath({ name: AppRoutes.NOTIFICATION_SETTINGS, param: null })
          } else {
            this.detailStack.pushPathByName(AppRoutes.NOTIFICATION_SETTINGS, null)
          }
        })

        SectionHeader({ title: $r('app.string.my_section_about') })
        AboutSection()

        Row().height(this.tm.current.value40)
      }
      .width(this.tm.current.full)
      .padding({
        top: this.tm.current.value16,
        left: this.tm.current.value20,
        right: this.tm.current.value20
      })
    }
    .scrollBar(BarState.Off)
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .align(Alignment.Top)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}
