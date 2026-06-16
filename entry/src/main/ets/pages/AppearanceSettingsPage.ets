/**
 * AppearanceSettingsPage — 外观设置二级页
 *
 * 展示三种主题模式（浅色/深色/跟随系统）的选项列表，
 * 选中后立即通过 AppearanceManager 应用并返回上一页。
 *
 * 路由参数：AppearanceSettingsParam（含当前 themeMode 和 onThemeChange 回调）
 */

import { ConfigurationConstant, common } from '@kit.AbilityKit'
import { ThemeFonts } from '../theme/ThemeFonts'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { AppearanceManager } from '../utils/AppearanceManager'
import { AppearanceSettingsViewModel, ThemeModeItem } from '../viewmodel/AppearanceSettingsViewModel'
import { ThemeModeRow } from '../components/appearancesettings/ThemeModeRow'
import { Logger } from 'core'

const TAG: string = 'AppearanceSettingsPage'

/** 路由参数 */
export class AppearanceSettingsParam {
  themeMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  onThemeChange: (mode: number) => void = (_m: number) => {}
}

@ComponentV2
export struct AppearanceSettingsPage {
  @Local private vm: AppearanceSettingsViewModel = new AppearanceSettingsViewModel()
  @Local private tm: ThemeManager = themeManager
  private localStack: NavPathStack | null = null
  private onThemeChange: (mode: number) => void = (_m: number) => {}
  private uiCtx: UIContext | null = null

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
  }

  onReady(ctx: NavDestinationContext): void {
    this.localStack = ctx.pathStack
    const param = ctx.pathInfo.param as AppearanceSettingsParam
    if (param !== null && param !== undefined) {
      this.vm.init(param.themeMode)
      this.onThemeChange = param.onThemeChange
    }
  }

  private selectTheme(mode: number): void {
    // 获取 UIAbilityContext 并应用颜色模式
    const hostCtx = this.uiCtx?.getHostContext()
    if (hostCtx !== undefined && hostCtx !== null) {
      const abilityCtx = hostCtx as common.UIAbilityContext
      AppearanceManager.applyColorMode(abilityCtx, mode).catch((err: Error) => {
        Logger.error(TAG, `applyColorMode failed: ${err.message}`)
      })
    } else {
      Logger.error(TAG, 'selectTheme: hostContext is null')
    }

    // 更新 ViewModel 状态
    this.vm.init(mode)

    // 通知调用方
    this.onThemeChange(mode)

    // 返回上一页
    this.localStack?.pop()
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: this.tm.current.value0 }) {
          Column() {
            ForEach(this.vm.themeItems(), (item: ThemeModeItem, idx: number) => {
              Column() {
                ThemeModeRow({
                  item: item,
                  isSelected: this.vm.themeMode === item.mode,
                  onSelect: (mode: number) => { this.selectTheme(mode) }
                })

                if (idx < 2) {
                  Divider()
                    .color(this.tm.current.colorDivider)
                    .margin({ left: this.tm.current.font16 })
                }
              }
            }, (item: ThemeModeItem) => item.mode.toString())
          }
          .backgroundColor(this.tm.current.colorSurfaceCard)
          .borderRadius(this.tm.current.radius12)
          .clip(true)

          Text($r('app.string.appearance_settings_hint'))
            .font(ThemeFonts.font14)
            .fontColor(this.tm.current.colorTextSecondary)
            .padding({
              top: this.tm.current.value12,
              left: this.tm.current.value4,
              right: this.tm.current.value4
            })
        }
        .padding({
          top: this.tm.current.font16,
          left: this.tm.current.font20,
          right: this.tm.current.font20,
          bottom: this.tm.current.value40
        })
      }
      .scrollBar(BarState.Off)
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
      .backgroundColor(this.tm.current.colorPageBg)
    }
    .title($r('app.string.appearance_settings_title'))
    .hideTitleBar(false)
    .onReady((ctx: NavDestinationContext) => {
      this.onReady(ctx)
    })
  }
}

// ─── Router Builder ───────────────────────────────────────────

@Builder
export function AppearanceSettingsBuilder(_name: string, _param: Object) {
  AppearanceSettingsPage()
}

// ─── Preview ──────────────────────────────────────────────────

@Preview
@ComponentV2
export struct AppearanceSettingsPagePreview {
  build() {
    Column() {
      AppearanceSettingsPage()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1a1a2e')
  }
}
