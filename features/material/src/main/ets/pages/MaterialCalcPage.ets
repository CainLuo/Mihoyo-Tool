/**
 * MaterialCalcPage.ets — 材料计算页主页面
 *
 * 展示单个角色按「已保存的养成目标」计算出的材料缺口：
 * 1. 角色 / 武器 / 技能的目标等级只读展示
 * 2. 材料缺口
 * 3. 目标等级统一在养成目标配置页修改（本页不提供编辑器）
 */

import { themeManager, ThemeManager, ViewState, AppRoutes } from 'basic';
import { GameId } from 'core';
import { MaterialCalcViewModel } from '../viewmodel/MaterialCalcViewModel';
import { MaterialCalcContentView } from '../views/MaterialCalcContentView';
import { MaterialCalcEmptyView } from '../views/MaterialCalcEmptyView';
import { MaterialCalcLoadingView } from '../views/MaterialCalcLoadingView';
import { MaterialTargetConfigParam } from '../model/MaterialTargetModels';

/** 页面参数 */
export class MaterialCalcParam {
  accountId: string = '';
  roleUid: string = '';
  avatarId: string = '';
}

@ComponentV2
export struct MaterialCalcPage {
  @Param param: MaterialCalcParam = new MaterialCalcParam();
  @Local private vm: MaterialCalcViewModel = new MaterialCalcViewModel();
  @Local private tm: ThemeManager = themeManager;
  private localStack: NavPathStack | null = null;
  /** onShown 首次触发与 aboutToAppear 重叠，跳过第一次避免重复加载 */
  private hasShown: boolean = false;

  aboutToAppear(): void {
    this.vm.init(this.param.accountId, this.param.roleUid, this.param.avatarId);
  }

  /** 目标等级的唯一编辑入口：跳转到该游戏的养成目标配置页 */
  private goToTargetConfig(): void {
    if (this.localStack === null) {
      return;
    }
    const configParam: MaterialTargetConfigParam = new MaterialTargetConfigParam();
    configParam.accountId = this.param.accountId;
    configParam.roleUid = this.param.roleUid;
    configParam.gameId = this.vm.getGameId();
    configParam.avatarIds = [this.param.avatarId];
    this.localStack.pushPathByName(this.getConfigRoute(this.vm.getGameId()), configParam);
  }

  private getConfigRoute(gameId: GameId): string {
    if (gameId === GameId.STARRAIL) {
      return AppRoutes.STARRAIL_MATERIAL_TARGET_CONFIG;
    }
    if (gameId === GameId.ZZZ) {
      return AppRoutes.ZZZ_MATERIAL_TARGET_CONFIG;
    }
    return AppRoutes.GENSHIN_MATERIAL_TARGET_CONFIG;
  }

  build() {
    NavDestination() {
      Column() {
        // 内容区
        if (this.vm.viewState === ViewState.LOADING) {
          MaterialCalcLoadingView()
        } else if (this.vm.viewState === ViewState.EMPTY) {
          MaterialCalcEmptyView()
        } else {
          MaterialCalcContentView({
            character: this.vm.character,
            skills: this.vm.skills,
            avatarSection: this.vm.avatarSection,
            weaponSection: this.vm.weaponSection,
            onEditTargets: () => { this.goToTargetConfig() }
          })
        }
      }
      .id('material_calc_page')
      .width('100%')
      .height('100%')
      .backgroundColor(this.tm.current.colorPageBg)
    }
    .title($r('app.string.material_calc_title'))
    .hideTitleBar(false)
    .onReady((ctx: NavDestinationContext) => { this.localStack = ctx.pathStack })
    .onShown(() => {
      // 从养成目标配置页返回时目标等级与材料数据都可能已变化
      if (this.hasShown) {
        this.vm.refresh();
      } else {
        this.hasShown = true;
      }
    })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct MaterialCalcPagePreview {
  build() {
    MaterialCalcPage()
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function MaterialCalcPageBuilder(_name: string, param: Object) {
  MaterialCalcPage({ param: param as MaterialCalcParam })
}
