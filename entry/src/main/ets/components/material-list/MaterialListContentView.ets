/**
 * MaterialListContentView.ets — 材料汇总内容视图
 *
 * 根据视图模式切换显示按角色分组或按材料汇总。
 * 按材料视图分两个 section：
 * 1. 经验书与摩拉（摩拉/经验书/魔矿）
 * 2. 其他材料
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { MaterialListViewMode, CharacterMaterialVM, MaterialSummaryVM, MaterialSectionVM, MaterialSectionType } from '../../models/MaterialListModels'
import { MaterialListViewModel } from '../../viewmodel/MaterialListViewModel'
import { CharacterMaterialCard } from './CharacterMaterialCard'
import { MaterialGridCard } from './MaterialGridCard'
import { ThemeFonts } from '../../theme/ThemeFonts'

@ComponentV2
export struct MaterialListContentView {
  @Param viewMode: MaterialListViewMode = MaterialListViewMode.CHARACTER
  @Param characterMaterials: CharacterMaterialVM[] = []
  @Param materialSections: MaterialSectionVM[] = []
  @Param onToggleCharacterExpand: (characterId: string) => void = (_: string) => {}

  @Local private tm: ThemeManager = themeManager

  build() {
    if (this.viewMode === MaterialListViewMode.CHARACTER) {
      // 按角色视图
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
      .layoutWeight(1)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16, top: this.tm.current.value12, bottom: this.tm.current.value16 })
    } else {
      // 按材料视图（分 section）
      Scroll() {
        Column({ space: this.tm.current.value20 }) {
          ForEach(this.materialSections, (section: MaterialSectionVM) => {
            this.MaterialSectionView(section)
          }, (section: MaterialSectionVM) => section.type)
        }
        .width(this.tm.current.full)
        .padding({ left: this.tm.current.value12, right: this.tm.current.value12, top: this.tm.current.value12, bottom: this.tm.current.value16 })
      }
      .width(this.tm.current.full)
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
    }
  }

  /**
   * 渲染单个 section。
   */
  @Builder
  MaterialSectionView(section: MaterialSectionVM) {
    Column({ space: this.tm.current.value12 }) {
      // section 标题
      Text(section.title)
        .font(ThemeFonts.font13)
        .fontColor(this.tm.current.colorTextSecondary)

      // 材料网格
      GridRow({
        columns: 5,
        gutter: { x: this.tm.current.value8, y: this.tm.current.value8 }
      }) {
        ForEach(section.materials, (mat: MaterialSummaryVM) => {
          GridCol() {
            MaterialGridCard({
              data: mat,
              isCurrency: section.type === MaterialSectionType.CURRENCY,
              onTap: () => {
                // TODO: 显示关联角色详情
              }
            })
          }
        }, (mat: MaterialSummaryVM) => mat.materialId)
      }
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
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
