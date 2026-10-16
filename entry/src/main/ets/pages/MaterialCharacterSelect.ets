/**
 * MaterialCharacterSelect.ets — 角色选择页
 *
 * 显示指定游戏的角色列表，支持多选（最多 4 个）。
 * 选中的角色 ID 列表用于跳转到材料计算页。
 */

import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { UIContext } from '@kit.ArkUI'
import { ViewState } from '../constants/ViewStates'
import { GameId, Logger } from 'core'
import {
  MaterialCharacterSelectViewModel,
  MaterialCharacterSelectParam,
  SelectableCharacterVM
} from '../viewmodel/MaterialCharacterSelectViewModel'
import { MaterialComputeResult } from '../utils/MaterialComputeService'
import { MaterialTargetConfigParam } from '../models/ToolsModels'
import { materialListRoute, materialTargetConfigRoute } from '../utils/MaterialRoutes'
import { PlaceholderView, PlaceholderState } from '../components/common/PlaceholderView'
import { AppRoutes } from '../constants/AppRoutes'
import { gameIdToColor, gameIdToName } from '../utils/GameIdUtil'

/** 路由参数类型（从 Builder 传入） */
interface MaterialCharacterSelectRouteParam {
  accountId: string
  roleUid: string
  gameId: GameId
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
    .menus(this.vm.showAccountSwitcher ? this.buildAccountMenu() : [])
    .onReady((ctx: NavDestinationContext) => {
      this.localStack = ctx.pathStack
    })
  }

  /**
   * 构建账号切换菜单
   */
  private buildAccountMenu(): MenuElement[] {
    const items: MenuElement[] = []
    for (let i = 0; i < this.vm.accountOptions.length; i++) {
      const option = this.vm.accountOptions[i]
      const isSelected = i === this.vm.selectedAccountIdx
      items.push({
        value: isSelected ? `✓ ${option.username}` : option.username,
        action: () => {
          this.vm.selectAccount(i)
        }
      })
    }
    return items
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
      Logger.error('🚀🚀🚀 MaterialSelect', `no NavPathStack or param, cannot navigate`)
      return
    }

    // 选中信息作为路由参数传给后续页面；目标等级不传，每次计算都从 DB 读取
    const selection = this.vm.buildSelectionParam()
    Logger.info('🚀🚀🚀 MaterialSelect', `start tap, gameId=${selection.gameId}, selected=${selection.avatarIds.join(',')}`)

    // DB 中没有养成目标配置：提示用户先去配置，不用默认值计算
    if (!(await this.vm.hasSavedConfig())) {
      Logger.info('🚀🚀🚀 MaterialSelect', `no saved target config, ask user to configure`)
      this.showConfigRequiredDialog(stack, selection)
      return
    }

    // 计算选中角色 → 替换当前页为对应游戏的材料汇总页（返回时直接回到工具页）
    const result = await this.vm.startCompute(selection)
    Logger.info('🚀🚀🚀 MaterialSelect', `compute result=${result}`)
    if (result === MaterialComputeResult.SUCCESS) {
      stack.replacePathByName(materialListRoute(selection.gameId), selection)
    } else if (result === MaterialComputeResult.NO_NEEDS) {
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.material_character_select_no_needs') })
    } else if (result === MaterialComputeResult.NO_CONFIG) {
      this.showConfigRequiredDialog(stack, selection)
    } else if (result === MaterialComputeResult.FAILED) {
      this.getUIContext().getPromptAction().showToast({ message: $r('app.string.material_character_select_failed') })
    }
  }

  /**
   * 提示用户先设置养成目标。
   * 选择"去设置"后带着选中信息进入该游戏的养成目标配置页；配置页点"开始计算"会保存到 DB 并计算，
   * 完成后替换为材料汇总页（同时移除本页，返回时直接回到工具页）。
   */
  private showConfigRequiredDialog(stack: NavPathStack, selection: MaterialTargetConfigParam): void {
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
  @Param onTap: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        // 角色图标
        Image(this.character.iconUrl)
          .width(this.tm.current.value56)
          .height(this.tm.current.value56)
          .borderRadius(this.tm.current.radius12)
          .backgroundColor(this.character.rarity === 5 ? $r('app.color.rarity_5star_bg') : $r('app.color.rarity_4star_bg'))

        // 角色名称
        Text(this.character.name)
          .fontSize(this.tm.current.font12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.tm.current.colorTextPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: this.tm.current.value8 })

        // 等级
        Text(`Lv.${this.character.level}`)
          .fontSize(this.tm.current.font10)
          .fontWeight(FontWeight.Normal)
          .fontColor(this.tm.current.colorTextSecondary)
          .margin({ top: this.tm.current.value2 })
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
