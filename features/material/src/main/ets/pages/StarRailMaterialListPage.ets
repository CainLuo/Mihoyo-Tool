/**
 * StarRailMaterialListPage.ets — 星穹铁道材料汇总页
 *
 * 展示星穹铁道角色的材料需求汇总。
 * 支持两种视图：按角色分组 / 按材料汇总。
 */

import { AppRoutes } from 'basic'
import { StarRailMaterialListViewModel } from '../viewmodel/StarRailMaterialListViewModel'
import { MaterialListScaffold } from '../views/MaterialListScaffold'
import { MaterialTargetConfigParam } from '../model/ToolsModels'

@ComponentV2
export struct StarRailMaterialListPage {
  @Local private vm: StarRailMaterialListViewModel = new StarRailMaterialListViewModel()
  /** 路由参数：选中的账号 / 游戏 UID / 角色 / 目标等级（由角色选择页或目标配置页传入） */
  @Param param: MaterialTargetConfigParam | null = null

  aboutToAppear(): void {
    this.vm.init(this.param)
  }

  build() {
    MaterialListScaffold({
      title: $r('app.string.starrail_material_list_title'),
      configRoute: AppRoutes.STARRAIL_MATERIAL_TARGET_CONFIG,
      viewState: this.vm.viewState,
      viewMode: this.vm.viewMode,
      characterMaterials: this.vm.characterMaterials,
      materialSections: this.vm.materialSections,
      isSyncing: this.vm.isSyncing,
      selection: this.vm.getSelection(),
      onSync: () => { this.vm.syncComputeData() },
      onToggleViewMode: () => { this.vm.toggleViewMode() },
      onToggleCharacterExpand: (characterId: string) => { this.vm.toggleCharacterExpand(characterId) }
    })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct StarRailMaterialListPagePreview {
  build() {
    StarRailMaterialListPage()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function StarRailMaterialListPageBuilder(_name: string, param: Object) {
  StarRailMaterialListPage({ param: param as MaterialTargetConfigParam | null })
}
