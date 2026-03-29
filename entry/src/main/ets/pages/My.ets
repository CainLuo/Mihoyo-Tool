/**
 * My — 我的页面（Tab 内嵌页）
 */
import { ConfigurationConstant, common } from '@kit.AbilityKit'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { AccountRepository, AuthRepository } from 'core'
import { Logger } from '../utils/Logger'
import { AppRoutes } from '../constants/AppRoutes'
import { RouterUtil } from '../utils/RouterUtil'
import { MyAccountVM, MyGameRoleVM, GameStatItem } from '../components/my/MyModels'
import { AccountListSection } from '../components/my/AccountListSection'
import { AppearanceSection } from '../components/my/AppearanceSection'
import { AboutSection } from '../components/my/AboutSection'
import { SectionHeader } from '../components/my/SectionHeader'
import { serverDisplayName } from '../utils/ServerNameUtil'
import { AppearanceManager } from '../utils/AppearanceManager'
import { gameIdToName, gameIdToColor } from '../utils/GameIdUtil'
import { ComponentContent } from '@kit.ArkUI'
import { BottomTabItem } from '../components/main/BottomTabItem'

const TAG: string = 'My'

@Builder
function splitPlaceholderBuilder() {
  Column() {}
  .width('100%')
  .height('100%')
  .backgroundColor($r('app.color.color_page_bg'))
}

@ComponentV2
export struct My {
  @Param detailStack: NavPathStack = new NavPathStack()
  @Param isSplit: boolean = false
  @Local private tm: ThemeManager = themeManager
  @Local private accounts: MyAccountVM[] = []
  @Local private themeMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  private placeholder: ComponentContent<object> | null = null
  private uiCtx: UIContext | null = null

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.placeholder = new ComponentContent(this.uiCtx, wrapBuilder(splitPlaceholderBuilder))
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
        let roles = await AccountRepository.findRolesByAccountId(row.id)

        // 每次加载时调用 BBS 接口补充/更新 nickname 和 avatarUrl
        if (row.cookie) {
          try {
            const bbsDetail = await AuthRepository.getBbsAccountDetail(row.cookie)
            if (bbsDetail.nickname || bbsDetail.avatarUrl) {
              await AccountRepository.updateNicknameAndAvatar(row.id, bbsDetail.nickname, bbsDetail.avatarUrl)
              row.nickname = bbsDetail.nickname
              row.avatarUrl = bbsDetail.avatarUrl
            }
          } catch (_) {}
        }

        // 如果角色数据缺少 bgImageUrl/statsJson，调用账号详情接口补充
        let needsRefresh = false
        for (let i = 0; i < roles.length; i++) {
          if (!roles[i].statsJson || roles[i].statsJson === '') {
            needsRefresh = true
            break
          }
        }
        if (needsRefresh && row.cookie) {
          try {
            const uid = row.username
            const detailRoles = await AuthRepository.getGameRecordCard(row.cookie, uid)
            for (let i = 0; i < roles.length; i++) {
              for (let j = 0; j < detailRoles.length; j++) {
                if (detailRoles[j].gameId === roles[i].gameId) {
                  roles[i].bgImageUrl = detailRoles[j].bgImageUrl
                  roles[i].statsJson = detailRoles[j].statsJson
                  break
                }
              }
            }
            // 写回数据库
            await AccountRepository.replaceRoles(row.id, roles)
            // 重新读取（确保数据一致）
            roles = await AccountRepository.findRolesByAccountId(row.id)
          } catch (_) {}
        }

        const roleVMs: MyGameRoleVM[] = []
        for (const r of roles) {
          // 解析 statsJson
          const stats: GameStatItem[] = []
          if (r.statsJson) {
            try {
              interface RawStat { name: string; value: string }
              const parsed = JSON.parse(r.statsJson) as RawStat[]
              for (let i = 0; i < parsed.length; i++) {
                stats[stats.length] = new GameStatItem(parsed[i].name, parsed[i].value)
              }
            } catch (_) {}
          }
          roleVMs[roleVMs.length] = new MyGameRoleVM(
            r.gameId,
            gameIdToName(r.gameId),
            gameIdToColor(r.gameId),
            r.roleId,
            r.nickname,
            serverDisplayName(r.server, r.gameId),
            r.level,
            r.bgImageUrl,
            stats
          )
        }
        vms[vms.length] = new MyAccountVM(row.id, row.username, roleVMs, row.nickname, row.avatarUrl)
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
