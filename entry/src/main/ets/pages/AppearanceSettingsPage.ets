/**
 * AppearanceSettingsPage — 外观设置二级页
 *
 * 展示三种主题模式（浅色/深色/跟随系统）的选项列表，
 * 选中后立即通过 AppearanceManager 应用并返回上一页。
 *
 * 路由参数：AppearanceSettingsParam（含当前 themeMode 和 onThemeChange 回调）
 */

import { ConfigurationConstant, common } from '@kit.AbilityKit';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { AppearanceManager } from '../utils/AppearanceManager';
import { AppearanceSettingsViewModel, ThemeModeItem } from '../viewmodel/AppearanceSettingsViewModel';
import { Logger } from 'core';

const TAG: string = 'AppearanceSettingsPage';

// ─── 路由参数 ─────────────────────────────────────────────────

export class AppearanceSettingsParam {
  themeMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  onThemeChange: (mode: number) => void = (_m: number) => {};
}

// ─── 页面组件 ─────────────────────────────────────────────────

@ComponentV2
export struct AppearanceSettingsPage {
  @Local private vm: AppearanceSettingsViewModel = new AppearanceSettingsViewModel();
  @Local private tm: ThemeManager = themeManager;
  private localStack: NavPathStack | null = null;
  private onThemeChange: (mode: number) => void = (_m: number) => {};
  private uiCtx: UIContext | null = null;

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext();
  }

  onReady(ctx: NavDestinationContext): void {
    this.localStack = ctx.pathStack;
    const param = ctx.pathInfo.param as AppearanceSettingsParam;
    if (param !== null && param !== undefined) {
      this.vm.init(param.themeMode);
      this.onThemeChange = param.onThemeChange;
    }
  }

  private selectTheme(mode: number): void {
    // 获取 UIAbilityContext 并应用颜色模式
    const hostCtx = this.uiCtx?.getHostContext();
    if (hostCtx !== undefined && hostCtx !== null) {
      const abilityCtx = hostCtx as common.UIAbilityContext;
      AppearanceManager.applyColorMode(abilityCtx, mode).catch((err: Error) => {
        Logger.error(TAG, `applyColorMode failed: ${err.message}`);
      });
    } else {
      Logger.error(TAG, 'selectTheme: hostContext is null');
    }

    // 更新 ViewModel 状态
    this.vm.init(mode);

    // 通知调用方
    this.onThemeChange(mode);

    // 返回上一页
    this.localStack?.pop();
  }

  @Builder
  themeModeRow(item: ThemeModeItem) {
    Row({ space: this.tm.current.value14 }) {
      Text(item.icon)
        .fontSize(this.tm.current.value20)
        .flexShrink(0)

      Column() {
        Text(item.label)
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextPrimary)

        Text(item.desc)
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
          .margin({ top: this.tm.current.value4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Stack() {
        Row()
          .width(this.tm.current.value20)
          .height(this.tm.current.value20)
          .backgroundColor(
            this.vm.themeMode === item.mode
              ? this.tm.current.colorPrimary
              : Color.Transparent
          )

        if (this.vm.themeMode === item.mode) {
          Text('✓')
            .fontColor(Color.White)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
        }
      }
      .width(this.tm.current.value20)
      .height(this.tm.current.value20)
      .borderRadius(this.tm.current.value12)
      .border(
        this.vm.themeMode === item.mode
          ? { width: 0 }
          : { width: this.tm.current.value2, color: this.tm.current.colorDivider }
      )
      .clip(true)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value56)
    .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.selectTheme(item.mode);
    })
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: this.tm.current.value0 }) {
          Column() {
            ForEach(this.vm.themeItems(), (item: ThemeModeItem, idx: number) => {
              this.themeModeRow(item)

              if (idx < 2) {
                Divider()
                  .color(this.tm.current.colorDivider)
                  .margin({ left: this.tm.current.value16 })
              }
            }, (item: ThemeModeItem) => item.mode.toString())
          }
          .backgroundColor(this.tm.current.colorSurfaceCard)
          .borderRadius(this.tm.current.radius12)
          .clip(true)

          Text($r('app.string.appearance_settings_hint'))
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)
            .padding({
              top: this.tm.current.value12,
              left: this.tm.current.value4,
              right: this.tm.current.value4
            })
        }
        .padding({
          top: this.tm.current.value16,
          left: this.tm.current.value20,
          right: this.tm.current.value20,
          bottom: this.tm.current.value40
        })
      }
      .scrollBar(BarState.Off)
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring)
    }
    .title($r('app.string.appearance_settings_title'))
    .hideTitleBar(false)
    .backgroundColor(this.tm.current.colorPageBg)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .onReady((ctx: NavDestinationContext) => {
      this.onReady(ctx);
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
