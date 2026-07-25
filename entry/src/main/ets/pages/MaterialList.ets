/**
 * MaterialList.ets — 材料汇总页主页面
 *
 * 支持两种视图：按角色分组 / 按材料汇总。
 * 刷新按钮通过 NavDestination.menus() 显示在标题栏右侧。
 */

import { SymbolGlyphModifier } from '@kit.ArkUI'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { ViewState } from '../constants/ViewStates'
import { MaterialListViewMode } from '../models/MaterialListModels'
import { MaterialListViewModel } from '../viewmodel/MaterialListViewModel'
import { MaterialListContentView } from '../components/material-list/MaterialListContentView'
import { SegmentedTabBar, SegmentedTabItem } from '../components/common/SegmentedTabBar'
import { GameId, Logger } from 'core'
import { ThemeFonts } from '../theme/ThemeFonts'
import { PrimaryButtonModifier } from '../styles/ButtonModifier'

/** 页面参数 */
export class MaterialListParam {
  gameId: GameId = GameId.GENSHIN
}

@ComponentV2
export struct MaterialList {
  @Param param: MaterialListParam = new MaterialListParam()
  @Local private vm: MaterialListViewModel = new MaterialListViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private buttonModifier: PrimaryButtonModifier = new PrimaryButtonModifier(true)

  aboutToAppear(): void {
    this.vm.init(this.param.gameId)
  }

  private get menuItems(): NavigationMenuItem[] {
    // 只有有数据时才显示刷新按钮
    if (this.vm.viewState !== ViewState.DATA) {
      return []
    }
    return [{
      value: 'sync',
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      isEnabled: !this.vm.isSyncing,
      action: () => {
        Logger.info('MaterialList', 'Sync menu item clicked')
        this.vm.syncComputeData()
      }
    }]
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
        // 视图切换 Tab（与 Characters 页面的游戏切换样式一致）
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
          // 空态视图 — 提示用户去同步材料计算
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
                Logger.info('MaterialList', 'Button onClick triggered')
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
    .title($r('app.string.material_list_title'))
    .hideTitleBar(false)
    .menus(this.menuItems)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct MaterialListPreview {
  build() {
    MaterialList()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function MaterialListBuilder(_name: string, param: Object) {
  MaterialList({ param: param as MaterialListParam })
}
