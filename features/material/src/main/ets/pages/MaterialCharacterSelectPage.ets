/**
 * MaterialCharacterSelectPage.ets — 角色选择页
 *
 * 显示指定游戏的角色列表，支持多选（最多 4 个）。
 * 选中的角色 ID 列表用于跳转到材料计算页。
 */

import { themeManager, ThemeManager, AccountSwitchDialog, AccountSwitchDialogParams, ViewState, DialogDedup, PlaceholderView, PlaceholderState, getGameName } from 'basic'
import { SymbolGlyphModifier, ComponentContent } from '@kit.ArkUI'
import { GameId, Logger } from 'core'
import {
  MaterialCharacterSelectViewModel,
  SelectableCharacterVM
} from '../viewmodel/MaterialCharacterSelectViewModel'
import { MaterialComputeResult } from '../model/MaterialComputeResult'
import { MaterialTargetConfigParam } from '../model/ToolsModels'
import { getMaterialListRoute, getMaterialTargetConfigRoute } from '../utils/MaterialRouteUtil'
import { CharacterSelectCard } from '../views/CharacterSelectCard'

/** 路由参数类型（从 Builder 传入） */
interface MaterialCharacterSelectRouteParam {
  accountId: string
  roleUid: string
  gameId: GameId
}

@Builder
function accountSwitchDialogBuilder(params: AccountSwitchDialogParams) {
  AccountSwitchDialog({ params: params })
}

@ComponentV2
export struct MaterialCharacterSelectPage {
  @Local private vm: MaterialCharacterSelectViewModel = new MaterialCharacterSelectViewModel()
  @Local private tm: ThemeManager = themeManager
  /** 路由参数（从 Builder 传入） */
  @Param param: MaterialCharacterSelectRouteParam | null = null
  /** 当前页面所在的导航栈（onReady 时获取） */
  private localStack: NavPathStack | null = null

  private get gameId(): GameId {
    return this.param !== null ? this.param.gameId : GameId.GENSHIN
  }

  aboutToAppear(): void {
    if (this.param !== null) {
      this.vm.init(this.param.gameId)
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (this.vm.viewState === ViewState.LOADING) {
          // 加载中视图
          Column() {
            LoadingProgress()
              .width(this.tm.current.value32)
              .height(this.tm.current.value32)
              .color(this.tm.current.colorPrimary)
          }
          .width(this.tm.current.full)
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.vm.viewState === ViewState.EMPTY) {
          // 空态视图
          PlaceholderView({
            state: {
              icon: '👤',
              title: $r('app.string.material_character_select_empty_title'),
              description: $r('app.string.material_character_select_empty_desc'),
              buttonText: '',
              isButtonEnabled: true,
              onButtonTap: () => {}
            } as PlaceholderState
          })
        } else {
          // 角色列表
          Scroll() {
            GridRow({
              columns: { xs: 4, sm: 4, md: 6, lg: 8 },
              gutter: { x: this.tm.current.value12, y: this.tm.current.value12 }
            }) {
              ForEach(this.vm.characters, (char: SelectableCharacterVM) => {
                GridCol({ span: 1 }) {
                  CharacterSelectCard({
                    character: char,
                    gameId: this.gameId,
                    onTap: () => {
                      this.vm.toggleSelect(char.avatarId)
                    }
                  })
                }
              }, (char: SelectableCharacterVM) => char.avatarId)
            }
            .width(this.tm.current.full)
            .padding({
              top: this.tm.current.value16,
              left: this.tm.current.value16,
              right: this.tm.current.value16,
              bottom: this.tm.current.value80
            })
          }
          .edgeEffect(EdgeEffect.Spring)
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .align(Alignment.Top)

          // 底部按钮区
          this.buildBottomBar()
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.colorPageBg)
    }
    .title(getGameName(this.gameId))
    .hideTitleBar(false)
    .menus(this.buildMenuItems())
    .onReady((ctx: NavDestinationContext) => {
      this.localStack = ctx.pathStack
    })
    .onShown(() => {
      // 从配置页 / 材料页返回时刷新历史记录入口（DB 中的计算结果可能已变化）
      this.vm.loadHistory()
    })
  }

  /**
   * 右上角按钮：历史记录（DB 中有该游戏的计算结果时才显示）、养成目标配置、切换账号（多账号时才显示）
   */
  private buildMenuItems(): NavigationMenuItem[] {
    const items: NavigationMenuItem[] = []
    if (this.vm.historyAvatarIds.length > 0) {
      items.push({
        value: $r('app.string.material_history'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.clock')),
        action: () => {
          this.openHistory()
        }
      })
    }
    items.push({
      value: $r('app.string.material_target_config_title'),
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.gearshape')),
      action: () => {
        this.openTargetConfig()
      }
    })
    if (this.vm.shouldShowAccountSwitcher) {
      items.push({
        value: $r('app.string.characters_switch_account_title'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.person_2')),
        action: () => {
          this.showAccountMenu()
        }
      })
    }
    return items
  }

  /** 历史记录：用材料汇总页展示 DB 中已有计算结果的全部角色 */
  private openHistory(): void {
    const stack = this.localStack
    if (stack === null || this.vm.historyAvatarIds.length === 0) {
      return
    }
    const param = this.vm.buildHistoryParam()
    Logger.info('MaterialSelect', `open history, gameId=${param.gameId}, avatarIds=${param.avatarIds.join(',')}`)
    stack.pushPathByName(getMaterialListRoute(param.gameId), param)
  }

  /**
   * 养成目标配置入口：带上当前选中的角色（可以为空）。
   * 配置页点"开始计算"会先保存到 DB；有选中角色时接着计算并进入材料页，没有选中角色时保存后返回本页。
   */
  private openTargetConfig(): void {
    const stack = this.localStack
    if (stack === null) {
      return
    }
    const param = this.vm.buildSelectionParam()
    stack.pushPathByName(getMaterialTargetConfigRoute(param.gameId), param)
  }

  /** 切换账号（复用角色页的 AccountSwitchDialog 底部弹窗） */
  private showAccountMenu(): void {
    const ctx = this.getUIContext()
    if (this.vm.accountOptions.length === 0) {
      return
    }
    const params = new AccountSwitchDialogParams()
    params.options = this.vm.accountOptions
    params.selectedIdx = this.vm.selectedAccountIdx
    params.onSelect = (idx: number) => {
      this.vm.selectAccount(idx)
    }
    const content = new ComponentContent(ctx, wrapBuilder(accountSwitchDialogBuilder), params)
    params.onClose = () => {
      ctx.getPromptAction().closeCustomDialog(content)
    }
    ctx.getPromptAction().openCustomDialog(content, {
      alignment: DialogAlignment.Bottom,
      offset: { dx: 0, dy: 0 },
      maskColor: '#80000000',
      isModal: true,
      autoCancel: true
    }).catch((_: Error | object) => {})
  }

  /**
   * 底部按钮栏
   */
  @Builder
  buildBottomBar() {
    Column() {
      Row() {
        // 已选数量
        Text($r('app.string.material_character_select_count', this.vm.selectedCount, 4))
          .fontSize(this.tm.current.font13)
          .fontWeight(FontWeight.Normal)
          .fontColor(this.tm.current.colorTextSecondary)

        Blank()

        // 开始计算按钮
        Button(this.vm.isSyncing
          ? $r('app.string.material_target_config_syncing')
          : $r('app.string.material_character_select_start'))
          .fontSize(this.tm.current.fontBold16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.vm.canStart ? Color.White : this.tm.current.colorTextSecondary)
          .backgroundColor(this.vm.canStart ? this.tm.current.colorPrimary : this.tm.current.colorSurfaceCard)
          .borderRadius(this.tm.current.radius12)
          .height(this.tm.current.value44)
          .padding({ left: this.tm.current.value24, right: this.tm.current.value24 })
          .enabled(this.vm.canStart && !this.vm.isSyncing)
          .onClick(() => {
            this.onStartTap()
          })
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value16,
        right: this.tm.current.value16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value12
      })
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .shadow({
      radius: this.tm.current.shadowRadius,
      offsetY: -this.tm.current.shadowOffsetY,
      color: this.tm.current.shadowColor
    })
  }

  /**
   * 开始计算按钮点击
   */
  private async onStartTap(): Promise<void> {
    const selectedIds = this.vm.getSelectedAvatarIds()
    if (selectedIds.length === 0) {
      return
    }

    const stack = this.localStack
    if (stack === null || this.param === null) {
      Logger.error('MaterialSelect', `no NavPathStack or param, cannot navigate`)
      return
    }

    // 选中信息作为路由参数传给后续页面；目标等级不传，每次计算都从 DB 读取
    const selection = this.vm.buildSelectionParam()
    Logger.info('MaterialSelect', `start tap, gameId=${selection.gameId}, selected=${selection.avatarIds.join(',')}`)

    // DB 中没有养成目标配置：提示用户先去配置，不用默认值计算
    if (!(await this.vm.hasSavedConfig())) {
      Logger.info('MaterialSelect', `no saved target config, ask user to configure`)
      this.showConfigRequiredDialog(stack, selection)
      return
    }

    // 计算选中角色 → 替换当前页为对应游戏的材料汇总页（返回时直接回到工具页）
    const result = await this.vm.startCompute(selection)
    Logger.info('MaterialSelect', `compute result=${result}`)
    if (result === MaterialComputeResult.SUCCESS) {
      stack.replacePathByName(getMaterialListRoute(selection.gameId), selection)
    } else if (result === MaterialComputeResult.NO_NEEDS) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.material_character_select_no_needs') })
      } catch (_) {
        // 提示失败不影响后续流程
      }
    } else if (result === MaterialComputeResult.NO_CONFIG) {
      this.showConfigRequiredDialog(stack, selection)
    } else if (result === MaterialComputeResult.FAILED) {
      try {
        this.getUIContext().getPromptAction().showToast({ message: $r('app.string.material_character_select_failed') })
      } catch (_) {
        // 提示失败不影响后续流程
      }
    }
  }

  /**
   * 提示用户先设置养成目标。
   * 选择"去设置"后带着选中信息进入该游戏的养成目标配置页；配置页点"开始计算"会保存到 DB 并计算，
   * 完成后替换为材料汇总页（同时移除本页，返回时直接回到工具页）。
   */
  private showConfigRequiredDialog(stack: NavPathStack, selection: MaterialTargetConfigParam): void {
    // 弹框正在显示时忽略重复点击
    const key = 'material_target_config_required'
    if (!DialogDedup.tryAcquire(key)) {
      return
    }
    try {
      this.getUIContext().showAlertDialog({
        title: $r('app.string.material_target_config_required_title'),
        message: $r('app.string.material_target_config_required_message'),
        primaryButton: {
          value: $r('app.string.dialog_cancel'),
          action: () => {}
        },
        secondaryButton: {
          value: $r('app.string.material_target_config_required_go'),
          action: () => {
            stack.pushPathByName(getMaterialTargetConfigRoute(selection.gameId), selection)
          }
        },
        // 按钮点击、点外部、返回键关闭都会走到这里
        onDidDisappear: () => {
          DialogDedup.release(key)
        }
      })
    } catch (e) {
      // 弹框没打开就不会触发 onDidDisappear，这里释放 key，否则该提示本次运行内再也弹不出来
      DialogDedup.release(key)
      Logger.error('MaterialSelect', `showConfigRequiredDialog failed: ${(e as Error).message}`)
    }
  }
}

@Preview
@ComponentV2
export struct MaterialCharacterSelectPagePreview {
  build() {
    MaterialCharacterSelectPage()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function MaterialCharacterSelectPageBuilder(_name: string, param: Object) {
  MaterialCharacterSelectPage({
    param: param as MaterialCharacterSelectRouteParam
  })
}
