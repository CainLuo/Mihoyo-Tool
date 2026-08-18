/**
 * MaterialListContentView.ets — 材料汇总内容视图
 *
 * 根据视图模式切换显示按角色分组或按材料汇总。
 * 按材料视图分两个 section：
 * 1. 经验书与摩拉（摩拉/经验书/魔矿）
 * 2. 其他材料
 *
 * 性能优化（HarmonyOS 官方推荐）：
 * 使用 Tabs 组件（隐藏 TabBar）替代 if-else 条件渲染，
 * 利用 TabContent 的内置组件冻结机制，避免组件销毁/重建。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { MaterialListViewMode, CharacterMaterialVM, MaterialSummaryVM, MaterialSectionVM } from '../../models/MaterialListModels'
import { CharacterMaterialCard } from './CharacterMaterialCard'
import { MaterialSectionView } from './MaterialSectionView'

@ComponentV2
export struct MaterialListContentView {
  @Param viewMode: MaterialListViewMode = MaterialListViewMode.CHARACTER
  @Param characterMaterials: CharacterMaterialVM[] = []
  @Param materialSections: MaterialSectionVM[] = []
  @Param onToggleCharacterExpand: (characterId: string) => void = (_: string) => {}

  @Local private tm: ThemeManager = themeManager

  /**
   * 获取当前视图模式的索引（用于 Tabs 组件）
   */
  private getViewModeIndex(): number {
    return this.viewMode === MaterialListViewMode.CHARACTER ? 0 : 1
  }

  build() {
    // 使用 Tabs 组件替代 if-else，避免组件销毁/重建
    Tabs({ index: this.getViewModeIndex() }) {
      // Tab 0: 按角色视图
      TabContent() {
        List({ space: this.tm.current.value12 }) {
          ForEach(this.characterMaterials, (char: CharacterMaterialVM) => {
            ListItem() {
              CharacterMaterialCard({
                data: char,
                onToggleExpand: () => {
                  this.onToggleCharacterExpand(char.characterId)
                }
              })
            }
          }, (char: CharacterMaterialVM) => char.characterId)
        }
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .padding({ left: this.tm.current.value16, right: this.tm.current.value16, top: this.tm.current.value12, bottom: this.tm.current.value16 })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }

      // Tab 1: 按材料视图（分 section）
      TabContent() {
        List({ space: this.tm.current.value20 }) {
          ForEach(this.materialSections, (section: MaterialSectionVM) => {
            ListItem() {
              MaterialSectionView({
                section: section,
                onMaterialTap: (mat: MaterialSummaryVM) => {
                  // TODO: 显示关联角色详情
                }
              })
            }
          }, (section: MaterialSectionVM) => section.type)
        }
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .padding({ left: this.tm.current.value12, right: this.tm.current.value12, top: this.tm.current.value12, bottom: this.tm.current.value16 })
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .barHeight(0) // 隐藏 TabBar
    .animationDuration(0) // 禁用切换动画，实现即时切换
    .width(this.tm.current.full)
    .layoutWeight(1)
  }
}

@Preview
@ComponentV2
export struct MaterialListContentViewPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    MaterialListContentView()
      .backgroundColor(this.tm.current.colorPageBg)
  }
}
