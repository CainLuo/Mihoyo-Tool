/**
 * My — 我的页面（View 层，普通内容组件）
 */
import { ConfigurationConstant, common } from '@kit.AbilityKit'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { AppRoutes } from '../constants/AppRoutes'
import { MyAccountVM } from '../models/MyModels'
import { AccountListSection } from '../components/my/AccountListSection'
import { AppearanceSection } from '../components/my/AppearanceSection'
import { AboutSection } from '../components/my/AboutSection'
import { SectionHeader } from '../components/my/SectionHeader'
import { AppearanceManager } from '../utils/AppearanceManager'
import { AccountSignal } from '../utils/AccountSignal'
import { MyViewModel } from '../viewmodel/MyViewModel'
import { SettingRow } from '../components/SettingRow'
import { AppearanceSettingsParam } from '../pages/AppearanceSettingsPage'

@ComponentV2
export struct My {
  @Param detailStack: NavPathStack = new NavPathStack()
  @Param isSplit: boolean = false
  @Local private tm: ThemeManager = themeManager
  @Local private vm: MyViewModel = new MyViewModel()
  @Local private themeMode: number = AppearanceManager.getCachedColorMode()
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
          onTap: () => {
            const param = new AppearanceSettingsParam()
            param.themeMode = this.themeMode
            param.onThemeChange = (mode: number) => { this.themeMode = mode }
            if (this.isSplit) {
              this.detailStack.replacePath({ name: AppRoutes.APPEARANCE_SETTINGS, param: param })
            } else {
              this.detailStack.pushPathByName(AppRoutes.APPEARANCE_SETTINGS, param)
            }
          }
        })

        SectionHeader({ title: $r('app.string.my_section_widget') })
        Column() {
          SettingRow({
            label: $r('app.string.my_section_widget'),
            onTap: () => {
              const accounts = this.vm.accounts;
              if (this.isSplit) {
                this.detailStack.replacePath({ name: AppRoutes.WIDGET_SETTINGS, param: accounts })
              } else {
                this.detailStack.pushPathByName(AppRoutes.WIDGET_SETTINGS, accounts)
              }
            }
          })
        }
        .width(this.tm.current.full)
        .backgroundColor(this.tm.current.colorSurfaceCard)
        .borderRadius(this.tm.current.radius12)
        .clip(true)

        SectionHeader({ title: $r('app.string.my_section_notification') })
        Column() {
          SettingRow({
            label: $r('app.string.my_section_notification'),
            onTap: () => {
              if (this.isSplit) {
                this.detailStack.replacePath({ name: AppRoutes.NOTIFICATION_SETTINGS, param: null })
              } else {
                this.detailStack.pushPathByName(AppRoutes.NOTIFICATION_SETTINGS, null)
              }
            }
          })
        }
        .width(this.tm.current.full)
        .backgroundColor(this.tm.current.colorSurfaceCard)
        .borderRadius(this.tm.current.radius12)
        .clip(true)

        SectionHeader({ title: $r('app.string.my_section_about') })
        AboutSection({ vm: this.vm })

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
