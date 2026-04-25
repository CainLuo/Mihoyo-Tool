/**
 * NotificationGameRow — 单个游戏的体力阈值设置行
 *
 * 设计：
 *   - @Local displayThreshold 管理输入框显示值，与 game.threshold 解耦
 *   - onChange 只更新 displayThreshold（不保存），避免每次按键都触发异步保存
 *   - onBlur 失焦时保存（调用 vm.onThresholdChange）
 *   - @Monitor('game') 监听外部 game 引用变化（如 onFullValueShortcut 后），同步 displayThreshold
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { GameNotificationConfig } from '../../notification/NotificationModels';
import { NotificationSettingsViewModel } from '../../viewmodel/NotificationSettingsViewModel';
import { gameIdToColor } from '../../utils/GameIdUtil';

@ComponentV2
export struct NotificationGameRow {
  @Param accountId: string = ''
  @Param game: GameNotificationConfig = new GameNotificationConfig()
  @Param vm: NotificationSettingsViewModel = new NotificationSettingsViewModel()
  @Local private tm: ThemeManager = themeManager
  /** 输入框本地显示值，与 game.threshold 解耦 */
  @Local private displayThreshold: string = ''

  aboutToAppear(): void {
    this.displayThreshold = `${this.game.threshold}`
  }

  /**
   * 监听 game 引用变化（onFullValueShortcut 会创建新对象），同步显示值
   */
  @Monitor('game')
  onGameRefChanged(_monitor: IMonitor): void {
    this.displayThreshold = `${this.game.threshold}`
  }

  /** 失焦时保存当前输入值 */
  private commitThreshold(): void {
    const n = parseInt(this.displayThreshold)
    if (!isNaN(n) && n > 0) {
      this.vm.onThresholdChange(this.accountId, this.game.gameId, n).catch((_: Error | object) => {})
    }
  }

  build() {
    Row({ space: this.tm.current.value12 }) {
      Row()
        .width(this.tm.current.value2)
        .height(this.tm.current.value32)
        .borderRadius(this.tm.current.value2)
        .backgroundColor(gameIdToColor(this.game.gameId))

      Column({ space: this.tm.current.value4 }) {
        Text($r('app.string.notification_game_stamina_label', this.game.gameName, this.game.staminaName))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextPrimary)

        Text(this.game.maxStamina > 0
          ? $r('app.string.notification_max_from_api', this.game.maxStamina, this.game.secondsPerUnit / 60)
          : $r('app.string.notification_max_pending', this.game.secondsPerUnit / 60))
          .font(this.tm.current.body10)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      TextInput({ text: this.displayThreshold })
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
          // 只更新本地显示值，不立即保存（避免每次按键都触发异步保存）
          this.displayThreshold = val
        })
        .onBlur(() => {
          // 失焦时保存
          this.commitThreshold()
        })
        .onSubmit((_enterKey: EnterKeyType) => {
          // 键盘确认键也触发保存
          this.commitThreshold()
        })

      Text(this.game.maxStamina > 0
        ? $r('app.string.notification_stamina_max_suffix', this.game.maxStamina)
        : $r('app.string.notification_stamina_max_unknown'))
        .font(this.tm.current.body12)
        .fontColor(this.tm.current.colorTextSecondary)

      Toggle({ type: ToggleType.Switch, isOn: this.game.enabled })
        .onChange((isOn: boolean) => {
          this.vm.onGameToggle(this.accountId, this.game.gameId, isOn).catch((_: Error | object) => {})
        })
        .selectedColor($r('app.color.color_primary'))
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value56)
    .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    .opacity(this.game.enabled ? 1.0 : 0.4)
  }
}
