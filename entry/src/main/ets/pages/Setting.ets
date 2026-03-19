/**
 * Setting — 设置页
 *
 * 三个 Section：
 *   1. 账号管理：已登录账号列表，可展开查看绑定角色，支持删除账号
 *   2. 外观设置：主题切换（浅色/深色/跟随系统）
 *   3. 关于：版本号、GitHub 链接
 */

import BuildProfile from 'BuildProfile'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { SettingAccountVM, SettingGameRoleVM } from '../components/setting/SettingModels'
import { AccountRepository } from 'core'
import { Logger } from '../utils/Logger'

const TAG: string = 'Setting'

// ---- 主题模式枚举 ----
const THEME_LIGHT = 0
const THEME_DARK = 1
const THEME_SYSTEM = 2

@ComponentV2
export struct Setting {
  @Local private tm: ThemeManager = themeManager
  @Local private accounts: SettingAccountVM[] = []
  /** 当前主题模式 */
  @Local private themeMode: number = THEME_LIGHT

  aboutToAppear(): void {
    this.loadAccounts()
  }

  private async loadAccounts(): Promise<void> {
    try {
      const accountRows = await AccountRepository.findAllAccounts()
      const vms: SettingAccountVM[] = []
      for (const row of accountRows) {
        const roles = await AccountRepository.findRolesByAccountId(row.id)
        const roleVMs: SettingGameRoleVM[] = []
        for (const r of roles) {
          roleVMs[roleVMs.length] = new SettingGameRoleVM(
            r.gameId,
            Setting.gameIdToName(r.gameId),
            Setting.gameIdToColor(r.gameId),
            r.roleId,
            r.nickname,
            r.server
          )
        }
        vms[vms.length] = new SettingAccountVM(row.id, row.username, roleVMs)
      }
      this.accounts = vms
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error(TAG, `loadAccounts failed: ${msg}`)
    }
  }

  private static gameIdToName(gameId: string): string {
    if (gameId === 'genshin') { return '原神' }
    if (gameId === 'starrail') { return '星穹铁道' }
    if (gameId === 'zzz') { return '绝区零' }
    if (gameId === 'honkai3') { return '崩坏3' }
    return gameId
  }

  private static gameIdToColor(gameId: string): ResourceColor {
    if (gameId === 'genshin') { return $r('app.color.game_color_genshin') }
    if (gameId === 'starrail') { return $r('app.color.game_color_starrail') }
    if (gameId === 'zzz') { return $r('app.color.game_color_zzz') }
    if (gameId === 'honkai3') { return $r('app.color.game_color_honkai3') }
    return $r('app.color.color_primary')
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text($r('app.string.setting_title'))
          .font(this.tm.current.title18Bold)
          .fontColor(this.tm.current.colorTextPrimary)
      }
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightNavBar)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.tm.current.colorCardBg)

      Divider().color(this.tm.current.colorDivider)

      Scroll() {
        Column({ space: this.tm.current.value20 }) {
          // ---- Section 1: 账号管理 ----
          this.buildSectionHeader($r('app.string.setting_section_account'))
          this.buildAccountSection()

          // ---- Section 2: 外观设置 ----
          this.buildSectionHeader($r('app.string.setting_section_appearance'))
          this.buildAppearanceSection()

          // ---- Section 3: 关于 ----
          this.buildSectionHeader($r('app.string.setting_section_about'))
          this.buildAboutSection()

          Row().height(this.tm.current.value40)
        }
        .width(this.tm.current.widthFull)
        .padding({ top: this.tm.current.value16 })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .backgroundColor(this.tm.current.colorPageBg)
  }

  @Builder
  private buildSectionHeader(title: ResourceStr) {
    Text(title)
      .font(this.tm.current.body13)
      .fontColor(this.tm.current.colorTextSecondary)
      .width(this.tm.current.widthFull)
      .padding({
        left: this.tm.current.value16,
        right: this.tm.current.value16,
        bottom: this.tm.current.value8
      })
  }

  @Builder
  private buildAccountSection() {
    Column() {
      if (this.accounts.length === 0) {
        // 空状态
        Row() {
          Text($r('app.string.setting_account_empty'))
            .font(this.tm.current.body16)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightButton)
        .justifyContent(FlexAlign.Center)
        .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
      } else {
        ForEach(this.accounts, (account: SettingAccountVM, idx: number) => {
          Column() {
            // 账号行（点击展开/折叠）
            Row({ space: this.tm.current.value12 }) {
              // 头像占位
              Row()
                .width(this.tm.current.avatarSizeMD)
                .height(this.tm.current.avatarSizeMD)
                .borderRadius(this.tm.current.avatarRadius)
                .backgroundColor(this.tm.current.colorPrimary)

              Column({ space: this.tm.current.value2 }) {
                Text(account.username)
                  .font(this.tm.current.body16Medium)
                  .fontColor(this.tm.current.colorTextPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(account.roles.length.toString() + $r('app.string.setting_account_role_count'))
                  .font(this.tm.current.body13)
                  .fontColor(this.tm.current.colorTextSecondary)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              // 展开/折叠箭头
              Text(account.expanded ? '∧' : '∨')
                .font(this.tm.current.body16)
                .fontColor(this.tm.current.colorTextSecondary)

              // 删除按钮
              Text($r('app.string.setting_account_delete'))
                .font(this.tm.current.body13)
                .fontColor(this.tm.current.colorDanger)
                .padding({
                  left: this.tm.current.value8,
                  right: this.tm.current.value8,
                  top: this.tm.current.value4,
                  bottom: this.tm.current.value4
                })
                .borderRadius(this.tm.current.radius8)
                .backgroundColor(this.tm.current.colorDangerBg)
                .onClick(() => {
                  this.accounts.splice(idx, 1)
                })
            }
            .width(this.tm.current.widthFull)
            .padding({
              left: this.tm.current.value16,
              right: this.tm.current.value16,
              top: this.tm.current.value12,
              bottom: this.tm.current.value12
            })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              account.expanded = !account.expanded
            })

            // 展开后的角色列表
            if (account.expanded && account.roles.length > 0) {
              Divider()
                .color(this.tm.current.colorDivider)
                .margin({ left: this.tm.current.value16, right: this.tm.current.value16 })

              ForEach(account.roles, (role: SettingGameRoleVM, roleIdx: number) => {
                Column() {
                  Row({ space: this.tm.current.value12 }) {
                    // 游戏色块
                    Row()
                      .width(this.tm.current.gameBarWidth)
                      .height(this.tm.current.gameBarHeightSM)
                      .borderRadius(this.tm.current.gameBarRadius)
                      .backgroundColor(role.gameColor)

                    Column({ space: this.tm.current.value2 }) {
                      Text(role.gameName)
                        .font(this.tm.current.body16Medium)
                        .fontColor(this.tm.current.colorTextPrimary)
                        .maxLines(1)

                      Row({ space: this.tm.current.value8 }) {
                        Text(role.nickname)
                          .font(this.tm.current.body13)
                          .fontColor(this.tm.current.colorTextSecondary)

                        Text($r('app.string.setting_account_uid_prefix') + role.roleUid)
                          .font(this.tm.current.body13)
                          .fontColor(this.tm.current.colorTextSecondary)

                        Text(role.server)
                          .font(this.tm.current.body13)
                          .fontColor(this.tm.current.colorTextSecondary)
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                  }
                  .width(this.tm.current.widthFull)
                  .padding({
                    left: this.tm.current.value16,
                    right: this.tm.current.value16,
                    top: this.tm.current.value8,
                    bottom: this.tm.current.value8
                  })
                  .alignItems(VerticalAlign.Center)

                  if (roleIdx < account.roles.length - 1) {
                    Divider()
                      .color(this.tm.current.colorDivider)
                      .margin({ left: this.tm.current.value16 + this.tm.current.gameBarWidth + this.tm.current.value12, right: this.tm.current.value16 })
                  }
                }
              })
            }
          }
          .width(this.tm.current.widthFull)
          .backgroundColor(this.tm.current.colorCardBg)

          if (idx < this.accounts.length - 1) {
            Divider()
              .color(this.tm.current.colorDivider)
              .margin({ left: this.tm.current.value16 })
          }
        })
      }

      // 添加账号按钮
      Divider().color(this.tm.current.colorDivider)
      Row() {
        Text($r('app.string.setting_account_add'))
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorPrimary)
      }
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightButton)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.tm.current.colorCardBg)
      .onClick(() => {
        // TODO: 跳转到登录页
      })
    }
    .width(this.tm.current.widthFull)
    .backgroundColor(this.tm.current.colorCardBg)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
    .margin({ left: this.tm.current.value16, right: this.tm.current.value16 })
  }

  @Builder
  private buildAppearanceSection() {
    Column() {
      // 主题切换行
      Row() {
        Text($r('app.string.setting_theme_label'))
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)

        Row({ space: this.tm.current.value8 }) {
          this.buildThemeChip($r('app.string.setting_theme_light'), THEME_LIGHT)
          this.buildThemeChip($r('app.string.setting_theme_dark'), THEME_DARK)
          this.buildThemeChip($r('app.string.setting_theme_system'), THEME_SYSTEM)
        }
      }
      .width(this.tm.current.widthFull)
      .padding({
        left: this.tm.current.value16,
        right: this.tm.current.value16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value12
      })
      .alignItems(VerticalAlign.Center)
    }
    .width(this.tm.current.widthFull)
    .backgroundColor(this.tm.current.colorCardBg)
    .borderRadius(this.tm.current.radius12)
    .margin({ left: this.tm.current.value16, right: this.tm.current.value16 })
  }

  @Builder
  private buildThemeChip(label: ResourceStr, mode: number) {
    Text(label)
      .font(this.tm.current.body13)
      .fontColor(this.themeMode === mode ? Color.White : this.tm.current.colorTextSecondary)
      .padding({ left: this.tm.current.value8, right: this.tm.current.value8, top: this.tm.current.value4, bottom: this.tm.current.value4 })
      .borderRadius(this.tm.current.radius8)
      .backgroundColor(this.themeMode === mode ? this.tm.current.colorPrimary : this.tm.current.colorDivider)
      .onClick(() => {
        this.themeMode = mode
        // 深色/浅色由系统 base/dark 资源目录自动处理，
        // 强制切换需要 System API（uiAppearance），普通应用无权限调用。
        // 此处仅记录用户偏好，实际颜色跟随系统深色模式。
      })
  }

  @Builder
  private buildAboutSection() {
    Column() {
      // 版本号
      this.buildAboutRow($r('app.string.setting_about_version'), BuildProfile.VERSION_NAME, false)
      Divider().color(this.tm.current.colorDivider).margin({ left: this.tm.current.value16 })
      // GitHub
      this.buildAboutRow($r('app.string.setting_about_github'), $r('app.string.setting_about_github_url'), true)
      Divider().color(this.tm.current.colorDivider).margin({ left: this.tm.current.value16 })
      // 许可证
      this.buildAboutRow($r('app.string.setting_about_license'), $r('app.string.setting_about_license_value'), false)
    }
    .width(this.tm.current.widthFull)
    .backgroundColor(this.tm.current.colorCardBg)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
    .margin({ left: this.tm.current.value16, right: this.tm.current.value16 })
  }

  @Builder
  private buildAboutRow(label: ResourceStr, value: ResourceStr | string, isLink: boolean) {
    Row() {
      Text(label)
        .font(this.tm.current.body16)
        .fontColor(this.tm.current.colorTextPrimary)
        .layoutWeight(1)

      Text(value)
        .font(this.tm.current.body16)
        .fontColor(isLink ? this.tm.current.colorPrimary : this.tm.current.colorTextSecondary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(this.tm.current.widthFull)
    .padding({
      left: this.tm.current.value16,
      right: this.tm.current.value16,
      top: this.tm.current.value12,
      bottom: this.tm.current.value12
    })
    .alignItems(VerticalAlign.Center)
  }
}
