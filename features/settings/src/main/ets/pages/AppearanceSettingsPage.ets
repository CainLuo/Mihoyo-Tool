/**
 * AppearanceSettingsPage — 外观设置二级页
 *
 * 展示三种主题模式（浅色/深色/跟随系统）的选项列表，
 * 选中后立即通过 AppearanceManager 应用；应用成功才回上一页，失败则提示并留在当前页。
 *
 * 路由参数：AppearanceSettingsParam（含当前 themeMode 和 onThemeChange 回调）
 */

import { common } from '@kit.AbilityKit'
import { ThemeFonts, themeManager, ThemeManager, showFeedback, FeedbackType } from 'basic'
import { AppearanceManager } from '../model/service/AppearanceManager'
import { AppearanceSettingsParam, ThemeModeItem } from '../model/AppearanceSettingsModels'
import { AppearanceSettingsViewModel } from '../viewmodel/AppearanceSettingsViewModel'
import { ThemeModeRow } from '../views/ThemeModeRow'
import { Logger } from 'core'

const TAG: string = 'AppearanceSettingsPage'

@ComponentV2
export struct AppearanceSettingsPage {
  @Local private vm: AppearanceSettingsViewModel = new AppearanceSettingsViewModel()
  @Local private tm: ThemeManager = themeManager
  private localStack: NavPathStack | null = null
  private onThemeChange: (mode: number) => void = (_m: number) => {}
  private uiCtx: UIContext | null = null
  /** 切换进行中：避免连点后多次 pop（每次成功都会退一页） */
  private isApplying: boolean = false

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
    if (this.isApplying) {
      return
    }
    // 获取 UIAbilityContext 并应用颜色模式
    const hostCtx = this.uiCtx?.getHostContext()
    if (hostCtx === undefined || hostCtx === null) {
      Logger.error(TAG, 'selectTheme: hostContext is null')
      this.notifyApplyFailed()
      return
    }

    this.isApplying = true
    AppearanceManager.applyColorMode(hostCtx as common.UIAbilityContext, mode)
      .then((applied: boolean) => {
        this.isApplying = false
        if (!applied) {
          // 系统拒绝切换：保持当前模式与当前页面，让用户能重试
          this.notifyApplyFailed()
          return
        }
        // 更新 ViewModel 状态
        this.vm.init(mode)
        // 通知调用方
        this.onThemeChange(mode)
        // 返回上一页
        this.localStack?.pop()
      })
      .catch((err: Error) => {
        this.isApplying = false
        Logger.error(TAG, `applyColorMode threw: ${err.message}`)
        this.notifyApplyFailed()
      })
  }

  /** 切换失败的用户提示（不返回上一页，避免「没反应却退出了」） */
  private notifyApplyFailed(): void {
    const ctx = this.uiCtx
    if (ctx === null) {
      return
    }
    showFeedback(ctx, FeedbackType.ERROR, $r('app.string.appearance_apply_failed'))
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: this.tm.current.value0 }) {
          Column() {
            ForEach(this.vm.getThemeItems(), (item: ThemeModeItem, idx: number) => {
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
            .font(ThemeFonts.FONT_14)
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
export function AppearanceSettingsPageBuilder(_name: string, _param: Object) {
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
