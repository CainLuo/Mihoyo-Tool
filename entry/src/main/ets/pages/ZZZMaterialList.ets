/**
 * ZZZMaterialList.ets — 绝区零材料汇总页
 *
 * 展示绝区零角色的材料需求汇总。
 * 支持两种视图：按角色分组 / 按材料汇总。
 */

import { SymbolGlyphModifier } from '@kit.ArkUI'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { ViewState } from '../constants/ViewStates'
import { MaterialListViewMode } from '../models/MaterialListModels'
import { ZZZMaterialListViewModel } from '../viewmodel/ZZZMaterialListViewModel'
import { MaterialListContentView } from '../components/material-list/MaterialListContentView'
import { SegmentedTabBar, SegmentedTabItem } from '../components/common/SegmentedTabBar'
import { Logger, GameId } from 'core'
import { ThemeFonts } from '../theme/ThemeFonts'
import { PrimaryButtonModifier } from '../styles/ButtonModifier'
import { AppRoutes } from '../constants/AppRoutes'
import { MaterialTargetConfigParam } from '../models/ToolsModels'

const TAG: string = 'ZZZMaterialList'

@ComponentV2
export struct ZZZMaterialList {
  @Local private vm: ZZZMaterialListViewModel = new ZZZMaterialListViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private buttonModifier: PrimaryButtonModifier = new PrimaryButtonModifier(true)
  private localStack: NavPathStack | null = null

  aboutToAppear(): void {
    Logger.info(TAG, 'aboutToAppear')
    this.vm.init()
  }

  private get menuItems(): NavigationMenuItem[] {
    const items: NavigationMenuItem[] = []

    // 有数据时显示刷新按钮
    if (this.vm.viewState === ViewState.DATA) {
      items.push({
        value: 'sync',
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        isEnabled: !this.vm.isSyncing,
        action: () => {
          Logger.info(TAG, 'Sync menu item clicked')
          this.vm.syncComputeData()
        }
      })
    }

    // 始终显示更改配置按钮
    items.push({
      value: 'config',
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.gearshape')),
      isEnabled: true,
      action: () => {
        Logger.info(TAG, 'Config menu item clicked')
        this.localStack?.pushPathByName(AppRoutes.ZZZ_MATERIAL_TARGET_CONFIG, null)
      }
    })

    return items
  }

  /**
   * 构建视图模式切换的 Tab 数据
   */
  private getViewModeTabs(): SegmentedTabItem[] {
    return [
      new SegmentedTabItem('character', $r('app.string.material_view_by_character')),
      new SegmentedTabItem('material', $r('app.string.material_view_by_material')),
    ]
  }

  /**
   * 获取当前视图模式的索引
   */
  private getViewModeIndex(): number {
    return this.vm.viewMode === MaterialListViewMode.CHARACTER ? 0 : 1
  }

  build() {
    NavDestination() {
      Column() {
        // 视图切换 Tab
        SegmentedTabBar({
          tabs: this.getViewModeTabs(),
          selectedIdx: this.getViewModeIndex(),
          onSelect: (_idx: number) => {
            this.vm.toggleViewMode()
          }
        })

        // 内容区
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
          Column({ space: this.tm.current.font20 }) {
            Text('📦')
              .fontSize(this.tm.current.value64)

            Text($r('app.string.material_list_empty_title'))
              .font(ThemeFonts.fontBold18)
              .fontColor(this.tm.current.colorTextPrimary)
              .textAlign(TextAlign.Center)

            Text($r('app.string.material_list_empty_desc'))
              .font(ThemeFonts.font17)
              .fontColor(this.tm.current.colorTextSecondary)
              .textAlign(TextAlign.Center)
              .padding({ left: this.tm.current.value40, right: this.tm.current.value40 })

            Button(
              this.vm.isSyncing 
                ? $r('app.string.material_list_syncing') 
                : $r('app.string.material_list_empty_button'),
              { type: ButtonType.Normal }
            )
              .attributeModifier(this.buttonModifier)
              .width(this.tm.current.pct90)
              .enabled(!this.vm.isSyncing)
              .onClick(() => {
                Logger.info(TAG, 'Button onClick triggered')
                this.vm.syncComputeData()
              })
          }
          .width(this.tm.current.full)
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          // 内容视图
          MaterialListContentView({
            viewMode: this.vm.viewMode,
            characterMaterials: this.vm.characterMaterials,
            materialSections: this.vm.materialSections,
            onToggleCharacterExpand: (characterId: string) => {
              this.vm.toggleCharacterExpand(characterId)
            }
          })
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .align(Alignment.Top)
      .backgroundColor(this.tm.current.colorPageBg)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .title($r('app.string.zzz_material_list_title'))
    .hideTitleBar(false)
    .menus(this.menuItems)
    .onReady((ctx: NavDestinationContext) => {
      this.localStack = ctx.pathStack
    })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct ZZZMaterialListPreview {
  build() {
    ZZZMaterialList()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function ZZZMaterialListBuilder(_name: string, _param: Object) {
  ZZZMaterialList()
}
