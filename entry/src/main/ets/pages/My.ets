/**
 * My — 我的页面（Tab 内嵌页）
 */
import { ConfigurationConstant, common } from '@kit.AbilityKit'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { AccountRepository } from 'core'
import { Logger } from '../utils/Logger'
import { AppRoutes } from '../constants/AppRoutes'
import { RouterUtil } from '../utils/RouterUtil'
import { MyAccountVM, MyGameRoleVM } from '../components/my/MyModels'
import { AccountListSection } from '../components/my/AccountListSection'
import { AppearanceSection } from '../components/my/AppearanceSection'
import { AboutSection } from '../components/my/AboutSection'
import { SectionHeader } from '../components/my/SectionHeader'
import { serverDisplayName } from '../utils/ServerNameUtil'
import { AppearanceManager } from '../utils/AppearanceManager'
import { gameIdToName, gameIdToColor } from '../utils/GameIdUtil'

const TAG: string = 'My'

@ComponentV2
export struct My {
  @Local private tm: ThemeManager = themeManager
  @Local private accounts: MyAccountVM[] = []
  @Local private themeMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  private uiCtx: UIContext | null = null

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.loadAccounts()
    this.loadSavedColorMode()
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

  private async loadAccounts(): Promise<void> {
    try {
      const accountRows = await AccountRepository.findAllAccounts()
      const vms: MyAccountVM[] = []
      for (const row of accountRows) {
        const roles = await AccountRepository.findRolesByAccountId(row.id)
        const roleVMs: MyGameRoleVM[] = []
        for (const r of roles) {
          roleVMs[roleVMs.length] = new MyGameRoleVM(
            r.gameId,
            gameIdToName(r.gameId),
            gameIdToColor(r.gameId),
            r.roleId,
            r.nickname,
            serverDisplayName(r.server)
          )
        }
        vms[vms.length] = new MyAccountVM(row.id, row.username, roleVMs)
      }
      this.accounts = vms
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error(TAG, `loadAccounts failed: ${msg}`)
    }
  }

  build() {
    Scroll() {
      Column({ space: this.tm.current.value20 }) {
        SectionHeader({ title: $r('app.string.my_section_account') })
        AccountListSection({
          accounts: this.accounts,
          onAccountTap: (account: MyAccountVM) => {
            RouterUtil.push(AppRoutes.ACCOUNT_DETAIL, account)
          },
          onAddTap: () => { RouterUtil.push(AppRoutes.LOGIN) }
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

        SectionHeader({ title: $r('app.string.my_section_about') })
        AboutSection()

        Row().height(this.tm.current.value40)
      }
      .width(this.tm.current.widthFull)
      .padding({
        top: this.tm.current.value16,
        left: this.tm.current.value20,
        right: this.tm.current.value20
      })
    }
    .scrollBar(BarState.Off)
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .align(Alignment.Top)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}
