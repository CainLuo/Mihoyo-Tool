/**
 * MaterialCharacterSelect.ets — 角色选择页
 *
 * 显示指定游戏的角色列表，支持多选（最多 4 个）。
 * 选中的角色 ID 列表用于跳转到材料计算页。
 */

import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { UIContext, SymbolGlyphModifier, ComponentContent } from '@kit.ArkUI'
import { AccountSwitchDialog, AccountSwitchDialogParams } from '../components/characters/AccountSwitchDialog'
import { ViewState } from '../constants/ViewStates'
import { GameId, Logger } from 'core'
import {
  MaterialCharacterSelectViewModel,
  MaterialCharacterSelectParam,
  SelectableCharacterVM
} from '../viewmodel/MaterialCharacterSelectViewModel'
import { MaterialComputeResult } from '../utils/MaterialComputeService'
import { MaterialTargetConfigParam } from '../models/ToolsModels'
import { DialogDedup } from '../utils/DialogDedup'
import { materialListRoute, materialTargetConfigRoute } from '../utils/MaterialRoutes'
import { PlaceholderView, PlaceholderState } from '../components/common/PlaceholderView'
import { AppRoutes } from '../constants/AppRoutes'
import { gameIdToColor, gameIdToName } from '../utils/GameIdUtil'
import { genshinElementFromString, elementIcon } from '../constants/GenshinElement'
import { starRailElementIcon, starRailPathIcon } from '../constants/StarRailElement'
import { zzzElementIcon, zzzProfessionIcon } from '../constants/ZZZElement'

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
export struct MaterialCharacterSelect {
  @Local private vm: MaterialCharacterSelectViewModel = new MaterialCharacterSelectViewModel()
  @Local private tm: ThemeManager = themeManager
  /** Navigation stack */
  @Param detailStack: NavPathStack | null = null
  /** 路由参数（从 Builder 传入） */
  @Param param: MaterialCharacterSelectRouteParam | null = null
  private uiContext: UIContext | null = null
  /** 当前页面所在的导航栈（onReady 时获取；Builder 不会传 detailStack） */
  private localStack: NavPathStack | null = null

  aboutToAppear(): void {
    this.uiContext = this.getUIContext()
    if (this.param !== null) {
      this.vm.init(this.param.gameId)
    }
  }

  /**
   * 监听 canStart 变化，控制按钮状态
   */
  @Monitor('vm.canStart')
  onCanStartChanged(_monitor: IMonitor): void {
    // canStart 变化时自动刷新 UI
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
              buttonEnabled: true,
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
                    gameId: this.param !== null ? this.param.gameId : GameId.GENSHIN,
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
    .title(this.param !== null ? gameIdToName(this.param.gameId) : '')
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
    if (this.vm.showAccountSwitcher) {
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
    const stack = this.localStack ?? this.detailStack
    if (stack === null || this.vm.historyAvatarIds.length === 0) {
      return
    }
    const param = this.vm.buildHistoryParam()
    Logger.info('MaterialSelect', `open history, gameId=${param.gameId}, avatarIds=${param.avatarIds.join(',')}`)
    stack.pushPathByName(materialListRoute(param.gameId), param)
  }

  /**
   * 养成目标配置入口：带上当前选中的角色（可以为空）。
   * 配置页点"开始计算"会先保存到 DB；有选中角色时接着计算并进入材料页，没有选中角色时保存后返回本页。
   */
  private openTargetConfig(): void {
    const stack = this.localStack ?? this.detailStack
    if (stack === null) {
      return
    }
    const param = this.vm.buildSelectionParam()
    stack.pushPathByName(materialTargetConfigRoute(param.gameId), param)
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

    const stack = this.localStack ?? this.detailStack
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
      stack.replacePathByName(materialListRoute(selection.gameId), selection)
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
          stack.pushPathByName(materialTargetConfigRoute(selection.gameId), selection)
        }
      },
      // 按钮点击、点外部、返回键关闭都会走到这里
      onDidDisappear: () => {
        DialogDedup.release(key)
      }
    })
  }
}

/**
 * 角色选择卡片 — 网格布局专用
 */
@ComponentV2
struct CharacterSelectCard {
  @Param character: SelectableCharacterVM = new SelectableCharacterVM()
  /** 当前游戏，决定头像左上角显示哪些图标 */
  @Param gameId: GameId = GameId.GENSHIN
  @Param onTap: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  /** 头像左上角要显示的图标（复用角色页的图标映射；取不到时不显示） */
  private badgeIcons(): Resource[] {
    const icons: Resource[] = []
    if (this.gameId === GameId.GENSHIN) {
      const e = elementIcon(genshinElementFromString(this.character.element))
      if (e !== null) { icons.push(e) }
    } else if (this.gameId === GameId.STARRAIL) {
      const e = starRailElementIcon(this.character.element)
      if (e !== null) { icons.push(e) }
      const p = starRailPathIcon(this.character.pathOrProfession)
      if (p !== null) { icons.push(p) }
    } else if (this.gameId === GameId.ZZZ) {
      const e = zzzElementIcon(parseInt(this.character.element, 10))
      if (e !== null) { icons.push(e) }
      const p = zzzProfessionIcon(this.character.pathOrProfession)
      if (p !== null) { icons.push(p) }
    }
    return icons
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        // 角色头像：左上角元素图标（原神：元素；星铁：属性 + 命途；绝区零：属性 + 特性），底部渐变遮罩 + 角色等级
        Stack({ alignContent: Alignment.TopStart }) {
          Image(this.character.iconUrl)
            .width(this.tm.current.value56)
            .height(this.tm.current.value56)
            .borderRadius(this.tm.current.radius12)
            .backgroundColor(this.character.rarity === 5 ? $r('app.color.rarity_5star_bg') : $r('app.color.rarity_4star_bg'))

          // 底部渐变遮罩 + 角色等级
          Text(`Lv.${this.character.level}`)
            .fontSize(this.tm.current.font10)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.textOnDarkHigh)
            .textAlign(TextAlign.Center)
            .width(this.tm.current.value56)
            .padding({ top: this.tm.current.value8, bottom: this.tm.current.value2 })
            .linearGradient({
              angle: this.tm.current.a180,
              colors: [[Color.Transparent, 0.0], [this.tm.current.overlayGradientEnd, 1.0]]
            })
            .borderRadius({ bottomLeft: this.tm.current.radius12, bottomRight: this.tm.current.radius12 })
            .position({ x: 0, y: this.tm.current.full })
            .markAnchor({ x: 0, y: this.tm.current.full })

          // 左上角图标：加半透明深色底，避免和头像混在一起
          if (this.badgeIcons().length > 0) {
            Column({ space: this.tm.current.value2 }) {
              ForEach(this.badgeIcons(), (icon: Resource) => {
                Image(icon)
                  .width(this.tm.current.value14)
                  .height(this.tm.current.value14)
                  .objectFit(ImageFit.Contain)
              }, (icon: Resource, idx: number) => `${idx}_${icon.id}`)
            }
            .alignItems(HorizontalAlign.Center)
            .padding(this.tm.current.value2)
            .backgroundColor(this.tm.current.colorMask)
            .borderRadius(this.tm.current.radius8)
            .margin({ left: this.tm.current.value2, top: this.tm.current.value2 })
          }
        }
        .width(this.tm.current.value56)
        .height(this.tm.current.value56)
        .clip(true)
        .borderRadius(this.tm.current.radius12)

        // 武器（原神）/ 光锥（星铁）/ 音擎（绝区零）：图标 + 等级；没有装备时显示占位
        Row({ space: this.tm.current.value4 }) {
          if (this.character.weaponIconUrl.length > 0) {
            Image(this.character.weaponIconUrl)
              .width(this.tm.current.value22)
              .height(this.tm.current.value22)
              .borderRadius(this.tm.current.radius8)
              .objectFit(ImageFit.Cover)
              .backgroundColor(this.character.weaponRarity >= 5
                ? $r('app.color.rarity_5star_bg')
                : $r('app.color.rarity_4star_bg'))
            Text(`Lv.${this.character.weaponLevel}`)
              .fontSize(this.tm.current.font10)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.tm.current.colorTextSecondary)
          } else {
            Text('—')
              .fontSize(this.tm.current.font10)
              .fontColor(this.tm.current.colorTextSecondary)
          }
        }
        .height(this.tm.current.value22)
        .justifyContent(FlexAlign.Center)
        .margin({ top: this.tm.current.value8 })
      }
      .width(this.tm.current.full)
      .padding(this.tm.current.value12)
      .alignItems(HorizontalAlign.Center)

      // 选中标记（右上角）
      if (this.character.isSelected) {
        Text('✓')
          .fontSize(this.tm.current.fontBold16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.colorPrimary)
          .margin({ top: this.tm.current.value8, right: this.tm.current.value8 })
      }
    }
    .width(this.tm.current.full)
    .backgroundColor(this.character.isSelected ? this.tm.current.surfaceActivePrimary : this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .border({
      width: this.character.isSelected ? 2 : 0,
      color: this.tm.current.colorPrimary
    })
    .onClick(() => {
      this.onTap()
    })
  }
}

@Preview
@ComponentV2
export struct MaterialCharacterSelectPreview {
  build() {
    MaterialCharacterSelect()
  }
}
