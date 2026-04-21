/**
 * NotificationSection.ets — 通知设置二级页内容
 *
 * 包含：
 *   - 总开关 + 权限提示
 *   - 代理提醒槽位进度条
 *   - 通知样式选择（纵向，附系统通知气泡预览）
 *   - 各账号游戏阈值（可折叠）
 *   - 超限 Dialog
 */
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GameId } from 'core';
import { NotificationSettingsViewModel } from '../../viewmodel/NotificationSettingsViewModel';
import {
  AccountNotificationConfig,
  GameNotificationConfig,
  NotificationStyle,
  GameStaminaConstants,
} from '../../notification/NotificationModels';

@ComponentV2
export struct NotificationSection {
  @Param context: common.UIAbilityContext | null = null;
  @Local private tm: ThemeManager = themeManager;
  @Local private vm: NotificationSettingsViewModel = new NotificationSettingsViewModel();

  aboutToAppear(): void {
    this.vm.loadSettings().catch((_: Error | object) => {});
  }

  @Monitor(NotificationSettingsViewModel.KEYS.showLimitDialog)
  onLimitDialogChanged(_monitor: IMonitor): void {
    if (this.vm.showLimitDialog) {
      this.showLimitDialog();
      this.vm.showLimitDialog = false;
    }
  }

  private showLimitDialog(): void {
    promptAction.showDialog({
      title: $r('app.string.notification_limit_dialog_title'),
      message: `当前提醒数量已达上限（${GameStaminaConstants.REMINDER_LIMIT} 个），请先关闭部分游戏的通知开关，再开启新的通知。`,
      buttons: [{ text: $r('app.string.notification_limit_dialog_confirm'), color: $r('app.color.color_primary') }],
    }).catch((_: Error | object) => {});
  }

  build() {
    Scroll() {
      Column({ space: this.tm.current.value12 }) {
        // ── 总开关 ────────────────────────────────────────────
        this.MasterToggleRow()

        // ── 权限被拒绝提示 ────────────────────────────────────
        if (this.vm.enabled && this.vm.permissionDenied) {
          this.PermissionWarning()
        }

        // ── 代理提醒槽位 ──────────────────────────────────────
        if (this.vm.enabled && !this.vm.permissionDenied) {
          this.SlotUsageRow()
        }

        // ── 通知样式选择 ──────────────────────────────────────
        if (this.vm.enabled && !this.vm.permissionDenied) {
          this.StyleSection()
        }

        // ── 各账号游戏阈值 ────────────────────────────────────
        if (this.vm.enabled && !this.vm.permissionDenied) {
          ForEach(this.vm.accounts, (acct: AccountNotificationConfig) => {
            this.AccountBlock(acct)
          })
        }

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

  // ── 总开关 ──────────────────────────────────────────────────
  @Builder
  private MasterToggleRow() {
    Row() {
      Column({ space: this.tm.current.value4 }) {
        Text($r('app.string.notification_master_switch'))
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextPrimary)
        Text($r('app.string.notification_master_switch_desc'))
          .font(this.tm.current.body12)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.vm.enabled })
        .onChange((isOn: boolean) => {
          if (this.context === null) { return; }
          this.vm.onToggleEnabled(this.context, isOn).catch((_: Error | object) => {});
        })
        .selectedColor($r('app.color.color_primary'))
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value16,
      right: this.tm.current.value16,
      top: this.tm.current.value14,
      bottom: this.tm.current.value14,
    })
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }

  // ── 权限警告 ────────────────────────────────────────────────
  @Builder
  private PermissionWarning() {
    Row({ space: this.tm.current.value8 }) {
      Text('⚠️').fontSize(this.tm.current.value16)
      Column({ space: this.tm.current.value4 }) {
        Text($r('app.string.notification_permission_denied_title'))
          .font(this.tm.current.body13Bold)
          .fontColor(this.tm.current.colorWarning)
        Text($r('app.string.notification_permission_denied_desc'))
          .font(this.tm.current.body12)
          .fontColor(this.tm.current.colorWarning)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .backgroundColor(this.tm.current.colorDangerBg)
    .borderRadius(this.tm.current.radius12)
  }

  // ── 槽位进度条 ──────────────────────────────────────────────
  @Builder
  private SlotUsageRow() {
    Column({ space: this.tm.current.value8 }) {
      Row() {
        Text($r('app.string.notification_slot_usage'))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)
        Text(`${this.vm.reminderUsed} / ${this.vm.reminderLimit}`)
          .font(this.tm.current.body13Bold)
          .fontColor(this.slotColor())
      }
      .width(this.tm.current.full)

      Progress({
        value: this.vm.reminderUsed,
        total: this.vm.reminderLimit,
        type: ProgressType.Linear,
      })
        .color(this.slotColor())
        .backgroundColor(this.tm.current.colorDivider)
        .width(this.tm.current.full)
        .height(this.tm.current.value4)

      Text($r('app.string.notification_slot_usage_desc'))
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value16)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .alignItems(HorizontalAlign.Start)
  }

  private slotColor(): Resource {
    const ratio = this.vm.reminderUsed / this.vm.reminderLimit;
    if (ratio >= 1) { return $r('app.color.color_danger'); }
    if (ratio >= 0.8) { return $r('app.color.color_warning'); }
    return $r('app.color.color_primary');
  }

  // ── 通知样式选择 ────────────────────────────────────────────
  @Builder
  private StyleSection() {
    Column({ space: this.tm.current.value8 }) {
      this.StyleCard(
        NotificationStyle.STYLE_A,
        $r('app.string.notification_style_a_title'),
        $r('app.string.notification_style_a_desc'),
      )
      this.StyleCard(
        NotificationStyle.STYLE_B,
        $r('app.string.notification_style_b_title'),
        $r('app.string.notification_style_b_desc'),
      )
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private StyleCard(style: NotificationStyle, title: ResourceStr, desc: ResourceStr) {
    Column({ space: this.tm.current.value12 }) {
      // 标题行（单选圆点 + 标题 + 描述）
      Row({ space: this.tm.current.value12 }) {
        Row() {
          if (this.vm.style === style) {
            Circle({ width: this.tm.current.value8, height: this.tm.current.value8 })
              .fill($r('app.color.color_primary'))
          }
        }
        .width(this.tm.current.value20)
        .height(this.tm.current.value20)
        .borderRadius(this.tm.current.value10)
        .border({
          width: this.tm.current.value2,
          color: this.vm.style === style ? $r('app.color.color_primary') : $r('app.color.color_divider'),
        })
        .justifyContent(FlexAlign.Center)

        Column({ space: this.tm.current.value2 }) {
          Text(title)
            .font(this.tm.current.body13Bold)
            .fontColor(this.tm.current.colorTextPrimary)
          Text(desc)
            .font(this.tm.current.body12)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width(this.tm.current.full)

      // 通知气泡预览
      if (style === NotificationStyle.STYLE_A) {
        this.StyleAPreview()
      } else {
        this.StyleBPreview()
      }
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .borderRadius(this.tm.current.radius8)
    .border({
      width: this.tm.current.value1p5,
      color: this.vm.style === style ? $r('app.color.color_primary') : $r('app.color.color_divider'),
    })
    .backgroundColor(this.vm.style === style ? $r('app.color.surface_active_primary') : $r('app.color.color_transparent'))
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.vm.onStyleChange(style).catch((_: Error | object) => {});
    })
  }

  // 样式 A 通知气泡预览
  @Builder
  private StyleAPreview() {
    Column({ space: this.tm.current.value8 }) {
      // 气泡
      Column({ space: this.tm.current.value4 }) {
        // 气泡头部
        Row({ space: this.tm.current.value5 }) {
          Row()
            .width(this.tm.current.value12)
            .height(this.tm.current.value12)
            .borderRadius(this.tm.current.value4)
            .linearGradient({ angle: this.tm.current.a135, colors: [[$r('app.color.color_primary'), 0], [$r('app.color.accent_refine'), 1]] })
          Text('米悠悠')
            .font(this.tm.current.body10)
            .fontColor(this.tm.current.colorTextSecondary)
          Text('刚刚')
            .font(this.tm.current.body10)
            .fontColor(this.tm.current.colorTextSecondary)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width(this.tm.current.full)

        Text('原神 · CainLuo')
          .font(this.tm.current.body13Bold)
          .fontColor(this.tm.current.colorTextPrimary)
        Text('原粹树脂已达 200/200，请及时消耗')
          .font(this.tm.current.body12)
          .fontColor(this.tm.current.colorTextSecondary)
        Text('天空岛 · UID 100000001')
          .font(this.tm.current.body10)
          .fontColor(this.tm.current.colorTextSecondary)
          .opacity(0.7)
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.value12)
      .backgroundColor(this.tm.current.colorSurfaceSubtle)
      .borderRadius(this.tm.current.radius8)
      .alignItems(HorizontalAlign.Start)

      Text('每个「账号 × 游戏」独立一条通知')
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
        .opacity(0.7)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  // 样式 B 通知气泡预览（折叠 + 展开）
  @Builder
  private StyleBPreview() {
    Column({ space: this.tm.current.value8 }) {
      // 折叠状态
      Text('折叠状态')
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
        .opacity(0.7)

      Column({ space: this.tm.current.value4 }) {
        Row({ space: this.tm.current.value5 }) {
          Row()
            .width(this.tm.current.value12)
            .height(this.tm.current.value12)
            .borderRadius(this.tm.current.value4)
            .linearGradient({ angle: this.tm.current.a135, colors: [[$r('app.color.color_primary'), 0], [$r('app.color.accent_refine'), 1]] })
          Text('米悠悠')
            .font(this.tm.current.body10)
            .fontColor(this.tm.current.colorTextSecondary)
          Text('刚刚')
            .font(this.tm.current.body10)
            .fontColor(this.tm.current.colorTextSecondary)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width(this.tm.current.full)

        Text('米悠悠 · 3 项体力提醒')
          .font(this.tm.current.body13Bold)
          .fontColor(this.tm.current.colorTextPrimary)
        Text('原神、星穹铁道、绝区零体力已达阈值')
          .font(this.tm.current.body12)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.value12)
      .backgroundColor(this.tm.current.colorSurfaceSubtle)
      .borderRadius(this.tm.current.radius8)
      .alignItems(HorizontalAlign.Start)

      // 展开状态
      Text('展开状态（最多 3 行）')
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
        .opacity(0.7)
        .margin({ top: this.tm.current.value4 })

      Column({ space: this.tm.current.value4 }) {
        Row({ space: this.tm.current.value5 }) {
          Row()
            .width(this.tm.current.value12)
            .height(this.tm.current.value12)
            .borderRadius(this.tm.current.value4)
            .linearGradient({ angle: this.tm.current.a135, colors: [[$r('app.color.color_primary'), 0], [$r('app.color.accent_refine'), 1]] })
          Text('米悠悠')
            .font(this.tm.current.body10)
            .fontColor(this.tm.current.colorTextSecondary)
          Text('刚刚')
            .font(this.tm.current.body10)
            .fontColor(this.tm.current.colorTextSecondary)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width(this.tm.current.full)

        Text('游戏体力提醒')
          .font(this.tm.current.body13Bold)
          .fontColor(this.tm.current.colorTextPrimary)

        Divider().color(this.tm.current.colorDivider).margin({ top: this.tm.current.value2, bottom: this.tm.current.value2 })

        Row({ space: this.tm.current.value5 }) {
          Circle({ width: this.tm.current.value5, height: this.tm.current.value5 })
            .fill($r('app.color.game_color_genshin'))
          Text('原神：树脂 200/200 已满')
            .font(this.tm.current.body12)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        Row({ space: this.tm.current.value5 }) {
          Circle({ width: this.tm.current.value5, height: this.tm.current.value5 })
            .fill($r('app.color.game_color_starrail'))
          Text('星铁：开拓力 300/300 已满')
            .font(this.tm.current.body12)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        Row({ space: this.tm.current.value5 }) {
          Circle({ width: this.tm.current.value5, height: this.tm.current.value5 })
            .fill($r('app.color.game_color_zzz'))
          Text('绝区零：电量 240/240 已满')
            .font(this.tm.current.body12)
            .fontColor(this.tm.current.colorTextSecondary)
        }
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.value12)
      .backgroundColor(this.tm.current.colorSurfaceSubtle)
      .borderRadius(this.tm.current.radius8)
      .alignItems(HorizontalAlign.Start)

      Text('所有游戏合并为一条通知，展开后最多显示 3 行')
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
        .opacity(0.7)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }

  // ── 账号区块（可折叠） ──────────────────────────────────────
  @Builder
  private AccountBlock(acct: AccountNotificationConfig) {
    NotificationAccountBlock({
      acct: acct,
      vm: this.vm,
      tm: this.tm,
    })
  }

  // ── 游戏行 ──────────────────────────────────────────────────
  @Builder
  private GameRow(accountId: string, game: GameNotificationConfig) {
    Row({ space: this.tm.current.value12 }) {
      Row()
        .width(this.tm.current.value2)
        .height(this.tm.current.value32)
        .borderRadius(this.tm.current.value2)
        .backgroundColor(this.gameColor(game.gameId))

      Column({ space: this.tm.current.value4 }) {
        Text(`${game.gameName} · ${game.staminaName}`)
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextPrimary)
        Text(game.maxStamina > 0
          ? `上限 ${game.maxStamina}（来自 API），每点 ${game.secondsPerUnit / 60} 分钟恢复`
          : `上限待同步，每点 ${game.secondsPerUnit / 60} 分钟恢复`)
          .font(this.tm.current.body10)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      TextInput({ text: `${game.threshold}` })
        .type(InputType.Number)
        .fontSize(this.tm.current.body13.size)
        .fontWeight(this.tm.current.body13.weight)
        .fontColor(this.tm.current.colorTextPrimary)
        .textAlign(TextAlign.Center)
        .width(this.tm.current.value52)
        .height(this.tm.current.value32)
        .backgroundColor(this.tm.current.colorSurfaceSubtle)
        .borderRadius(this.tm.current.radius8)
        .border({ width: this.tm.current.value1, color: this.tm.current.colorDivider })
        .padding({ left: this.tm.current.value4, right: this.tm.current.value4 })
        .onChange((val: string) => {
          const n = parseInt(val);
          if (!isNaN(n)) {
            this.vm.onThresholdChange(accountId, game.gameId, n).catch((_: Error | object) => {});
          }
        })

      Text(`/ ${game.maxStamina > 0 ? game.maxStamina : '—'}`)
        .font(this.tm.current.body12)
        .fontColor(this.tm.current.colorTextSecondary)

      Toggle({ type: ToggleType.Switch, isOn: game.enabled })
        .onChange((isOn: boolean) => {
          this.vm.onGameToggle(accountId, game.gameId, isOn).catch((_: Error | object) => {});
        })
        .selectedColor($r('app.color.color_primary'))
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value56)
    .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    .opacity(game.enabled ? 1.0 : 0.4)
  }

  private gameColor(gameId: GameId): Resource {
    if (gameId === GameId.GENSHIN) { return $r('app.color.game_color_genshin'); }
    if (gameId === GameId.STARRAIL) { return $r('app.color.game_color_starrail'); }
    return $r('app.color.game_color_zzz');
  }
}

// ── 独立账号折叠组件（和 UserGameSection 完全相同的折叠动画模式） ──────
@ComponentV2
struct NotificationAccountBlock {
  @Param acct: AccountNotificationConfig = new AccountNotificationConfig();
  @Param vm: NotificationSettingsViewModel = new NotificationSettingsViewModel();
  @Param tm: ThemeManager = themeManager;
  /** 折叠状态在组件内部管理，和 UserGameSection 一样 */
  @Local private collapsed: boolean = false;

  build() {
    Column() {
      // 账号头部
      Row({ space: this.tm.current.value12 }) {
        if (this.acct.avatarUrl.length > 0) {
          Image(this.acct.avatarUrl)
            .width(this.tm.current.value32)
            .height(this.tm.current.value32)
            .borderRadius(this.tm.current.value8)
            .objectFit(ImageFit.Cover)
            .border({ width: this.tm.current.value1p5, color: this.tm.current.colorPrimary })
        } else {
          Row()
            .width(this.tm.current.value32)
            .height(this.tm.current.value32)
            .borderRadius(this.tm.current.value8)
            .backgroundColor($r('app.color.color_primary'))
            .opacity(0.5)
        }

        Column({ space: this.tm.current.value2 }) {
          Text(this.acct.nickname)
            .font(this.tm.current.body13Bold)
            .fontColor(this.tm.current.colorTextPrimary)
          Text(`UID ${this.acct.uid} · ${this.acct.games.length} 个游戏`)
            .font(this.tm.current.body10)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(this.tm.current.value16)
          .fontColor([this.tm.current.colorTextSecondary])
          .rotate({ angle: this.collapsed ? -90 : 0 })
          .animation({ duration: 250, curve: Curve.EaseInOut })
      }
      .width(this.tm.current.full)
      .height(this.tm.current.value56)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
      .onClick(() => { this.collapsed = !this.collapsed; })

      // 展开内容（折叠时隐藏），和 UserGameSection 完全一样的 TransitionEffect
      if (!this.collapsed) {
        Column() {
          Divider()
            .color(this.tm.current.colorDivider)
            .margin({ left: this.tm.current.value16, right: this.tm.current.value16 })

          ForEach(this.acct.games, (game: GameNotificationConfig) => {
            this.GameRow(this.acct.accountId, game)
            Divider()
              .color(this.tm.current.colorDivider)
              .margin({ left: this.tm.current.value16, right: this.tm.current.value16 })
          }, (game: GameNotificationConfig) => game.gameId)

          Row() {
            Column({ space: this.tm.current.value4 }) {
              Text($r('app.string.notification_full_value_shortcut'))
                .font(this.tm.current.body13)
                .fontColor(this.tm.current.colorTextPrimary)
              Text($r('app.string.notification_full_value_shortcut_desc'))
                .font(this.tm.current.body10)
                .fontColor(this.tm.current.colorTextSecondary)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Row() {
              Text($r('app.string.notification_full_value_set'))
                .fontSize(this.tm.current.body12.size)
                .fontWeight(this.tm.current.body12.weight)
                .fontColor($r('app.color.color_primary'))
            }
            .height(this.tm.current.value32)
            .padding({ left: this.tm.current.value12, right: this.tm.current.value12 })
            .borderRadius(this.tm.current.radius8)
            .border({ width: this.tm.current.value1, color: $r('app.color.color_primary') })
            .onClick(() => {
              this.vm.onFullValueShortcut(this.acct.accountId).catch((_: Error | object) => {});
            })
          }
          .width(this.tm.current.full)
          .height(this.tm.current.value50)
          .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
        }
        .width(this.tm.current.full)
        .transition(
          TransitionEffect.OPACITY.animation({ duration: 200, curve: Curve.EaseInOut })
            .combine(TransitionEffect.translate({ y: -8 }))
        )
      }
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
  }

  @Builder
  private GameRow(accountId: string, game: GameNotificationConfig) {
    Row({ space: this.tm.current.value12 }) {
      Row()
        .width(this.tm.current.value2)
        .height(this.tm.current.value32)
        .borderRadius(this.tm.current.value2)
        .backgroundColor(this.gameColor(game.gameId))

      Column({ space: this.tm.current.value4 }) {
        Text(`${game.gameName} · ${game.staminaName}`)
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextPrimary)
        Text(game.maxStamina > 0
          ? `上限 ${game.maxStamina}，每点 ${game.secondsPerUnit / 60} 分钟恢复`
          : `上限待同步，每点 ${game.secondsPerUnit / 60} 分钟恢复`)
          .font(this.tm.current.body10)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      TextInput({ text: `${game.threshold}` })
        .type(InputType.Number)
        .fontSize(this.tm.current.body13.size)
        .fontWeight(this.tm.current.body13.weight)
        .fontColor(this.tm.current.colorTextPrimary)
        .textAlign(TextAlign.Center)
        .width(this.tm.current.value52)
        .height(this.tm.current.value32)
        .backgroundColor(this.tm.current.colorSurfaceSubtle)
        .borderRadius(this.tm.current.radius8)
        .border({ width: this.tm.current.value1, color: this.tm.current.colorDivider })
        .padding({ left: this.tm.current.value4, right: this.tm.current.value4 })
        .onChange((val: string) => {
          const n = parseInt(val);
          if (!isNaN(n)) {
            this.vm.onThresholdChange(accountId, game.gameId, n).catch((_: Error | object) => {});
          }
        })

      Text(`/ ${game.maxStamina > 0 ? game.maxStamina : '—'}`)
        .font(this.tm.current.body12)
        .fontColor(this.tm.current.colorTextSecondary)

      Toggle({ type: ToggleType.Switch, isOn: game.enabled })
        .onChange((isOn: boolean) => {
          this.vm.onGameToggle(accountId, game.gameId, isOn).catch((_: Error | object) => {});
        })
        .selectedColor($r('app.color.color_primary'))
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value56)
    .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    .opacity(game.enabled ? 1.0 : 0.4)
  }

  private gameColor(gameId: GameId): Resource {
    if (gameId === GameId.GENSHIN) { return $r('app.color.game_color_genshin'); }
    if (gameId === GameId.STARRAIL) { return $r('app.color.game_color_starrail'); }
    return $r('app.color.game_color_zzz');
  }
}
