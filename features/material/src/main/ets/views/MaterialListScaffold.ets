/**
 * MaterialListScaffold — 三游戏材料汇总页共用骨架
 *
 * 统一 NavDestination 标题栏、菜单（同步 / 更改配置）、视图模式 Tab 与三态分支；
 * 页面只提供 ViewModel 状态与回调。
 */

import { SymbolGlyphModifier } from '@kit.ArkUI'
import {
  themeManager,
  ThemeManager,
  ThemeFonts,
  ViewState,
  SegmentedTabBar,
  SegmentedTabItem,
  PrimaryButtonModifier,
} from 'basic'
import {
  CharacterMaterialVM,
  MaterialListViewMode,
  MaterialSectionVM,
} from '../model/MaterialListModels'
import { MaterialTargetConfigParam } from '../model/ToolsModels'
import { MaterialListContentView } from './MaterialListContentView'

@ComponentV2
export struct MaterialListScaffold {
  /** 标题栏文案 */
  @Param title: ResourceStr = ''
  /** 「更改配置」菜单要跳转的目标配置页路由 */
  @Param configRoute: string = ''
  @Param viewState: ViewState = ViewState.LOADING
  @Param viewMode: MaterialListViewMode = MaterialListViewMode.CHARACTER
  @Param characterMaterials: CharacterMaterialVM[] = []
  @Param materialSections: MaterialSectionVM[] = []
  @Param isSyncing: boolean = false
  /** 当前选中信息，随「更改配置」菜单传给目标配置页 */
  @Param selection: MaterialTargetConfigParam | null = null
  @Param onSync: () => void = () => {}
  @Param onToggleViewMode: () => void = () => {}
  @Param onToggleCharacterExpand: (characterId: string) => void = (_: string) => {}

  @Local private tm: ThemeManager = themeManager
  @Local private buttonModifier: PrimaryButtonModifier = new PrimaryButtonModifier(true)
  private localStack: NavPathStack | null = null

  private get menuItems(): NavigationMenuItem[] {
    const items: NavigationMenuItem[] = []

    // 有数据时显示刷新按钮
    if (this.viewState === ViewState.DATA) {
      items.push({
        value: 'sync',
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        isEnabled: !this.isSyncing,
        action: () => {
          this.onSync()
        }
      })
    }

    // 始终显示更改配置按钮
    items.push({
      value: 'config',
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.gearshape')),
      isEnabled: true,
      action: () => {
        this.localStack?.pushPathByName(this.configRoute, this.selection)
      }
    })

    return items
  }

  private getViewModeTabs(): SegmentedTabItem[] {
    return [
      new SegmentedTabItem('character', $r('app.string.material_view_by_character')),
      new SegmentedTabItem('material', $r('app.string.material_view_by_material')),
    ]
  }

  private getViewModeIndex(): number {
    return this.viewMode === MaterialListViewMode.CHARACTER ? 0 : 1
  }

  build() {
    NavDestination() {
      Column() {
        SegmentedTabBar({
          tabs: this.getViewModeTabs(),
          selectedIdx: this.getViewModeIndex(),
          onSelect: (_idx: number) => {
            this.onToggleViewMode()
          }
        })

        if (this.viewState === ViewState.LOADING) {
          Column() {
            LoadingProgress()
              .width(this.tm.current.value32)
              .height(this.tm.current.value32)
              .color(this.tm.current.colorPrimary)
          }
          .width(this.tm.current.full)
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.viewState === ViewState.EMPTY) {
          Column({ space: this.tm.current.font20 }) {
            Text('📦')
              .fontSize(this.tm.current.value64)

            Text($r('app.string.material_list_empty_title'))
              .font(ThemeFonts.FONT_BOLD_18)
              .fontColor(this.tm.current.colorTextPrimary)
              .textAlign(TextAlign.Center)

            Text($r('app.string.material_list_empty_desc'))
              .font(ThemeFonts.FONT_17)
              .fontColor(this.tm.current.colorTextSecondary)
              .textAlign(TextAlign.Center)
              .padding({ left: this.tm.current.value40, right: this.tm.current.value40 })

            Button(
              this.isSyncing
                ? $r('app.string.material_list_syncing')
                : $r('app.string.material_list_empty_button'),
              { type: ButtonType.Normal }
            )
              .attributeModifier(this.buttonModifier)
              .width(this.tm.current.pct90)
              .enabled(!this.isSyncing)
              .onClick(() => {
                this.onSync()
              })
          }
          .width(this.tm.current.full)
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          MaterialListContentView({
            viewMode: this.viewMode,
            characterMaterials: this.characterMaterials,
            materialSections: this.materialSections,
            onToggleCharacterExpand: (characterId: string) => {
              this.onToggleCharacterExpand(characterId)
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
    .title(this.title)
    .hideTitleBar(false)
    .menus(this.menuItems)
    .onReady((ctx: NavDestinationContext) => {
      this.localStack = ctx.pathStack
    })
  }
}
