/**
 * GenshinMaterialListPage.ets — 原神材料汇总页
 *
 * 展示原神角色的材料需求汇总。
 * 支持两种视图：按角色分组 / 按材料汇总。
 */

import { AppRoutes } from 'basic'
import { GenshinMaterialListViewModel } from '../viewmodel/GenshinMaterialListViewModel'
import { MaterialListScaffold } from '../views/MaterialListScaffold'
import { MaterialTargetConfigParam } from '../model/ToolsModels'

@ComponentV2
export struct GenshinMaterialListPage {
  @Local private vm: GenshinMaterialListViewModel = new GenshinMaterialListViewModel()
  /** 路由参数：选中的账号 / 游戏 UID / 角色 / 目标等级（由角色选择页或目标配置页传入） */
  @Param param: MaterialTargetConfigParam | null = null

  aboutToAppear(): void {
    this.vm.init(this.param)
  }

  build() {
    MaterialListScaffold({
      title: $r('app.string.genshin_material_list_title'),
      configRoute: AppRoutes.GENSHIN_MATERIAL_TARGET_CONFIG,
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
export struct GenshinMaterialListPagePreview {
  build() {
    GenshinMaterialListPage()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function GenshinMaterialListPageBuilder(_name: string, param: Object) {
  GenshinMaterialListPage({ param: param as MaterialTargetConfigParam | null })
}
